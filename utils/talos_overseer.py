import json
import os
import time
import subprocess
import pandas as pd
import re
from datetime import datetime

# --- CONFIGURAÇÃO (WSL) ---
MT5_BASE_PATH = "/mnt/c/Users/hp/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/Files"
SCANNER_FILE = os.path.join(MT5_BASE_PATH, "black_mirror_targets.json")
CONTROL_FILE = os.path.join(MT5_BASE_PATH, "talos_control.json")
NEWS_FEED_FILE = "research/live_market_feed.csv"
DIRECTIVES_FILE = "research/strategic_directives.json"
OVERSEER_STATE_DIR = os.path.abspath("research/overseer_state")

# Intervalo da IA (5 Minutos)
AI_INTERVAL = 300 
last_ai_update = 0

def load_json(filepath):
    try:
        if os.path.exists(filepath):
            with open(filepath, "r") as f:
                return json.load(f)
    except: return {}

def get_latest_sentiment():
    """Resume o sentimento recente para o prompt."""
    summary = []
    try:
        if os.path.exists(NEWS_FEED_FILE):
            df = pd.read_csv(NEWS_FEED_FILE, sep=";")
            # Pega as ultimas 10 noticias
            last_rows = df.tail(10)
            for _, row in last_rows.iterrows():
                summary.append(f"{row['asset']}: {row['headline']} (Sent: {row['raw_pct']})")
    except: pass
    return "\n".join(summary)

def query_gemini_brain(scanner_data, sentiment_txt, directives):
    """Invoca o Gemini CLI para decidir a estratégia."""
    
    # 1. Montar o Contexto
    prompt = f"""
    ROLE: You are TALOS OVERSEER, an elite HFT Strategy Engine.
    
    CONTEXT:
    - Strategic Directives: {json.dumps(directives)}
    - Market Sentiment (Last News):
    {sentiment_txt}
    - Live Market Scanner (Price/Vol):
    {json.dumps(scanner_data)}
    
    TASK:
    Analyze the data and generate the JSON configuration for the trading robot (OBS1DIAN).
    
    RULES:
    1. Determine 'Bias' (LONG, SHORT, NEUTRAL) for each active asset.
    2. Determine 'Strategy' (Warrior=Trend, MeanRev=Range, Breakout=Vol).
    3. Adjust 'Risk' (fixed_lot, cooldown) based on volatility.
    4. If Sentiment is negative and Price is dropping -> SHORT.
    5. If Price dropped heavily (>5%) but Sentiment is good -> LONG (Deep Value).
    6. Default to NEUTRAL if unsure.
    
    OUTPUT FORMAT:
    Return ONLY a valid JSON object. No markdown, no text.
    Example Structure:
    {{
      "GLOBAL_bias": "RISK_OFF",
      "XAUUSD_bias": "NEUTRAL",
      "IBM_bias": "LONG",
      "strategy_warrior": "ON",
      "strategy_mean_rev": "OFF",
      "fixed_lot": 0.02,
      "tp_multiplier": 1.5,
      "cooldown_seconds": 600,
      "use_sentiment": "ON",
      "risk_percent": 1.0,
      "rationale": "Brief 1-sentence reason for decisions"
    }}
    """
    
    try:
        print("   🧠 Pensando (Gemini 2.0)...")
        env = os.environ.copy()
        env["GEMINI_CLI_HOME"] = OVERSEER_STATE_DIR
        
        result = subprocess.run(
            ["gemini", "--prompt", prompt, "--model", "gemini-3-flash-preview"],
            capture_output=True, text=True, encoding='utf-8', env=env
        )
        
        if result.returncode != 0:
            print(f"   [!] Erro CLI: {result.stderr}")
            return None
            
        # Extrair JSON do output
        raw_output = result.stdout
        # Tenta achar o bloco JSON (mesmo se vier com markdown ```json ... ```)
        match = re.search(r"\{.*\}", raw_output, re.DOTALL)
        if match:
            json_str = match.group(0)
            return json.loads(json_str)
        else:
            print("   [!] Falha no parse JSON da IA.")
            return None
            
    except Exception as e:
        print(f"   [!] Erro de execução: {e}")
        return None

def main():
    global last_ai_update
    print(f"--- TALOS OVERSEER v7.0 (AI DRIVEN) ---")
    print(f"Intervalo de Reavaliação: {AI_INTERVAL}s")
    
    while True:
        current_time = time.time()
        
        # Só aciona a IA a cada 5 minutos
        if current_time - last_ai_update > AI_INTERVAL:
            try:
                # 1. Coleta Dados
                scanner = load_json(SCANNER_FILE)
                sentiment = get_latest_sentiment()
                directives = load_json(DIRECTIVES_FILE)
                
                # 2. Pergunta para a IA
                print(f"\n📡 [{datetime.now().strftime('%H:%M:%S')}] Coletando Intel & Consultando IA...")
                ai_decision = query_gemini_brain(scanner, sentiment, directives)
                
                if ai_decision:
                    # 3. Aplica Decisão
                    with open(CONTROL_FILE, "w") as f:
                        json.dump(ai_decision, f, separators=(',', ':'))
                    
                    rationale = ai_decision.get("rationale", "N/A")
                    print(f"   ✅ Estratégia Atualizada.")
                    print(f"   📝 Rationale: {rationale}")
                    
                    last_ai_update = current_time
                else:
                    print("   ⚠️ Mantendo configuração anterior (Falha IA).")
                    
            except Exception as e:
                print(f"   ❌ Erro Crítico no Loop: {e}")
        
        # Loop de espera visual
        time.sleep(10)

if __name__ == "__main__":
    main()
