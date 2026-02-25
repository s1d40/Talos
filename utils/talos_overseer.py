import json
import os
import time
import subprocess
import pandas as pd
import re
import glob
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

def get_live_telemetry():
    """Lê os arquivos de telemetria gerados pelo robô (RSI, Trend, etc)."""
    telemetry = {}
    print(f"   [DEBUG] Buscando telemetria em: {MT5_BASE_PATH}")
    
    try:
        if os.path.exists(MT5_BASE_PATH):
            files = os.listdir(MT5_BASE_PATH)
            target_files = [f for f in files if f.startswith("telemetry_") and f.endswith(".txt")]
            
            print(f"   [DEBUG] Arquivos encontrados ({len(target_files)}): {target_files}")
            
            for filename in target_files:
                try:
                    filepath = os.path.join(MT5_BASE_PATH, filename)
                    # Extrair simbolo: telemetry_IBM.txt -> IBM
                    symbol = filename.replace("telemetry_", "").replace(".txt", "")
                    
                    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read().strip()
                        # Parse: PRICE:258.94|CHANGE:-3.19|RSI:42.29...
                        data = {}
                        parts = content.split('|')
                        for p in parts:
                            if ':' in p:
                                k, v = p.split(':', 1) # Limit split to 1 to handle TIME:2026..
                                data[k] = v.strip()
                        
                        telemetry[symbol] = data
                except Exception as e: 
                    print(f"   [!] Erro lendo {filename}: {e}")
                    continue
        else:
            print(f"   [!] ALERTA: Diretório não encontrado: {MT5_BASE_PATH}")
    except Exception as e:
        print(f"   [!] Erro fatal listar dir: {e}")
        
    return telemetry

def query_gemini_brain(scanner_data, sentiment_txt, directives, telemetry_data):
    """Invoca o Gemini CLI para decidir a estratégia com CONTEXTO TOTAL."""
    
    # 1. Montar o Contexto
    prompt = f"""
    ROLE: You are TALOS OVERSEER, an elite HFT Strategy Engine.
    
    CONTEXT:
    1. Strategic Directives (Macro Plan): 
    {json.dumps(directives)}
    
    2. Market Sentiment (News Feed):
    {sentiment_txt}
    
    3. Live Market Scanner (Price Action/Vol):
    {json.dumps(scanner_data)}
    
    4. ROBOT TELEMETRY (Technical Indicators - CRITICAL):
    {json.dumps(telemetry_data)}
    * RSI < 30 = Oversold (Good for MeanRev Long)
    * RSI > 70 = Overbought (Good for MeanRev Short)
    * TREND = BULLISH_MACRO/BEARISH_MACRO
    
    TASK:
    Analyze ALL data streams and generate the JSON configuration for OBS1DIAN.
    
    LOGIC RULES:
    - IF Directives say LONG but Telemetry RSI is > 60 -> WAIT (Neutral) or Reduced Risk.
    - IF Directives say LONG and Telemetry RSI is < 30 -> AGGRESSIVE LONG (Deep Value).
    - IF Scanner shows extreme crash (> -5%) and Sentiment is bad -> SHORT (Follow crash) OR WAIT.
    - IF Telemetry shows "BEARISH_MACRO", do not force "WARRIOR LONG" unless RSI is oversold (Reversal).
    
    OUTPUT FORMAT:
    Return ONLY a valid JSON object. No markdown.
    Structure:
    {{
      "GLOBAL_bias": "RISK_OFF",
      "IBM_bias": "LONG",
      "strategy_warrior": "ON",
      "strategy_mean_rev": "ON",
      "fixed_lot": 0.02,
      "tp_multiplier": 1.5,
      "cooldown_seconds": 900,
      "use_sentiment": "ON",
      "risk_percent": 1.0,
      "disable_safety": "OFF",
      "rationale": "Explanation based on Telemetry+Sentiment"
    }}
    """
    
    try:
        print("   🧠 Pensando (Gemini 2.0) [Com Telemetria]...")
        env = os.environ.copy()
        env["GEMINI_CLI_HOME"] = OVERSEER_STATE_DIR
        
        result = subprocess.run(
            ["gemini", "--prompt", prompt, "--model", "gemini-2.0-flash"],
            capture_output=True, text=True, encoding='utf-8', env=env
        )
        
        if result.returncode != 0:
            print(f"   [!] Erro CLI: {result.stderr}")
            return None
            
        raw_output = result.stdout
        match = re.search(r"\{.*\}", raw_output, re.DOTALL)
        if match:
            return json.loads(match.group(0))
        else:
            return None
            
    except Exception as e:
        print(f"   [!] Erro de execução: {e}")
        return None

def main():
    global last_ai_update
    print(f"--- TALOS OVERSEER v7.1 (FULL TELEMETRY LINK) ---")
    print(f"Intervalo de Reavaliação: {AI_INTERVAL}s")
    
    while True:
        current_time = time.time()
        
        if current_time - last_ai_update > AI_INTERVAL:
            try:
                # 1. Coleta TUDO
                scanner = load_json(SCANNER_FILE)
                sentiment = get_latest_sentiment()
                directives = load_json(DIRECTIVES_FILE)
                telemetry = get_live_telemetry() # Nova Fonte de Dados
                
                print(f"\n📡 [{datetime.now().strftime('%H:%M:%S')}] Coletando Telemetria ({len(telemetry)} ativos)...")
                
                # 2. Pergunta para a IA
                ai_decision = query_gemini_brain(scanner, sentiment, directives, telemetry)
                
                if ai_decision:
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
        
        time.sleep(10)

if __name__ == "__main__":
    main()
