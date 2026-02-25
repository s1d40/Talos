import subprocess
import time
import os
import feedparser
import re
import json
from datetime import datetime

# --- CONFIGURAÇÃO (WSL MODE) ---
MT5_FILES_PATH = "/mnt/c/Users/hp/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/Files"
PROJECT_FEED_CSV = "research/live_market_feed.csv"
BRIDGE_STATE_DIR = os.path.abspath("research/bridge_state")
SCANNER_JSON = os.path.join(MT5_FILES_PATH, "black_mirror_targets.json")
MANUAL_FOCUS_JSON = "research/daily_focus.json"

# Feeds de Notícias Financeiras (Real-Time)
RSS_URLS = [
    "https://finance.yahoo.com/news/rssindex",
    "http://feeds.marketwatch.com/marketwatch/topstories/",
    "https://www.investing.com/rss/news.rss",
    "https://www.forexlive.com/feed/news",
    "https://cointelegraph.com/rss"
]

PROCESSED_TITLES = set()

def query_gemini_cli(headline):
    """Analisa sentimento via Gemini."""
    try:
        system_instruction = (
            "Analyze the financial market sentiment of this headline. "
            "Output ONLY a single float number between -1.0 (bearish) and 1.0 (bullish). "
            "Neutral is 0.0."
        )
        full_prompt = f"{system_instruction} HEADLINE: {headline}"
        env = os.environ.copy()
        env["GEMINI_CLI_HOME"] = BRIDGE_STATE_DIR
        
        result = subprocess.run(
            ["gemini", "--prompt", full_prompt, "--model", "gemini-2.0-flash"],
            capture_output=True, text=True, encoding='utf-8', env=env
        )
        
        if result.returncode != 0: return 0.0
        numbers = re.findall(r"(-?\d+\.\d+|-?\d+)", result.stdout.strip())
        return max(min(float(numbers[-1]), 1.0), -1.0) if numbers else 0.0
    except: return 0.0

def update_local_feed(asset_key, sentiment_raw, sentiment_ema, topic):
    try:
        file_exists = os.path.isfile(PROJECT_FEED_CSV)
        with open(PROJECT_FEED_CSV, "a", encoding="utf-8") as f:
            if not file_exists: f.write("timestamp;asset;raw_pct;ema_pct;headline\n")
            raw_p = f"{sentiment_raw * 100:.1f}%"
            ema_p = f"{sentiment_ema * 100:.1f}%"
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            clean_topic = topic.replace(";", "-").replace("\n", " ").strip()
            f.write(f"{timestamp};{asset_key};{raw_p};{ema_p};{clean_topic}\n")
            print(f"   📝 Log gravado: {asset_key} ({raw_p})")
    except: pass

def update_mt5_file(asset_key, sentiment, topic):
    try:
        filename = f"sentiment_{asset_key}.txt"
        filepath = os.path.join(MT5_FILES_PATH, filename)
        current_val = 0.0
        if os.path.exists(filepath):
            with open(filepath, "r") as f:
                try: current_val = float(f.read().split('|')[0])
                except: pass
        
        new_val = (current_val * 0.7) + (sentiment * 0.3)
        update_local_feed(asset_key, sentiment, new_val, topic)
        with open(filepath, "w") as f:
            f.write(f"{new_val:.4f}|{topic}|{int(time.time())}")
    except: pass

def generate_keywords(symbol):
    """Gera keywords inteligentes para um ativo."""
    clean = symbol.rstrip('m').rstrip('c').upper()
    keywords = [rf"\b{clean}\b"] # Ticker Base
    
    # Dicionário de Sinônimos
    aliases = {
        "CSCO": ["cisco"], "TMUS": ["t-mobile"], "EQIX": ["equinix"],
        "IBM": ["ibm", "intl business machines"], "NVDA": ["nvidia"],
        "XAUUSD": ["gold", "xau"], "XAGUSD": ["silver", "xag"],
        "BTCUSD": ["bitcoin", "btc", "crypto"], "ETHUSD": ["ethereum", "eth"],
        "TSM": ["tsmc", "taiwan semi"], "AMZN": ["amazon", "aws"]
    }
    
    if clean in aliases:
        keywords.extend([rf"\b{a}\b" for a in aliases[clean]])
        
    return clean, keywords

def get_combined_targets():
    """Mescla Scanner (Dinâmico) + Manual Focus (Estratégico)."""
    combined_targets = {}
    
    # 1. Ler Scanner (Dinâmico)
    try:
        if os.path.exists(SCANNER_JSON):
            with open(SCANNER_JSON, "r") as f:
                data = json.load(f)
            for s, m in data.items():
                if m.get('rvol', 0) > 1.5 or abs(m.get('change', 0)) > 3.0:
                    clean, kws = generate_keywords(s)
                    combined_targets[clean] = kws
    except: pass
    
    # 2. Ler Foco Manual (Estratégico)
    try:
        if os.path.exists(MANUAL_FOCUS_JSON):
            with open(MANUAL_FOCUS_JSON, "r") as f:
                manual_list = json.load(f)
            for s in manual_list:
                clean, kws = generate_keywords(s)
                # Adiciona ou Atualiza (Manual tem prioridade se quisermos, mas aqui só une)
                if clean not in combined_targets:
                    combined_targets[clean] = kws
    except: pass
    
    return combined_targets

def maintain_feed_hygiene():
    """Mantém o CSV leve, arquivando dados antigos."""
    MAX_ROWS = 100
    KEEP_ROWS = 20
    ARCHIVE_DIR = "research/Archive"
    
    try:
        if not os.path.exists(PROJECT_FEED_CSV): return
        
        # Leitura rápida
        with open(PROJECT_FEED_CSV, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        if len(lines) > MAX_ROWS:
            print(f"   🧹 Faxina: Arquivando {len(lines) - KEEP_ROWS} entradas antigas...")
            
            # Criar diretório de arquivo se não existir
            if not os.path.exists(ARCHIVE_DIR): os.makedirs(ARCHIVE_DIR)
            
            # Nome do Arquivo de Backup
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            archive_path = os.path.join(ARCHIVE_DIR, f"feed_history_{timestamp}.csv")
            
            # Salvar Backup
            with open(archive_path, "w", encoding="utf-8") as f:
                f.writelines(lines[:-KEEP_ROWS]) # Tudo exceto as últimas
                
            # Reescrever Arquivo Vivo (Header + Últimas)
            header = lines[0]
            recent_data = lines[-KEEP_ROWS:]
            
            # Garantir que não duplicamos o header se ele já estiver nos dados recentes (caso raro)
            if recent_data[0].startswith("timestamp"):
                final_content = recent_data
            else:
                final_content = [header] + recent_data
                
            with open(PROJECT_FEED_CSV, "w", encoding="utf-8") as f:
                f.writelines(final_content)
                
            print(f"   ✨ Feed limpo. Backup salvo em {archive_path}")
            
    except Exception as e:
        print(f"   [!] Erro na limpeza do feed: {e}")

def main():
    print("--- SHADOW BRIDGE v8.2.1 (AUTO-CLEAN FIXED) ---")
    print(f"Auth Home: {BRIDGE_STATE_DIR}")
    
    # Limpeza inicial
    maintain_feed_hygiene()
    
    while True:
        # Limpeza Periódica (a cada ciclo)
        maintain_feed_hygiene()
        
        # 1. Atualizar Alvos (Híbrido)
        targets = get_combined_targets() # FIX: Nome correto da função
        
        if not targets:
            print("   💤 Sem alvos. Dormindo...")
            time.sleep(300); continue
            
        print(f"\n🌍 [{datetime.now().strftime('%H:%M:%S')}] Monitorando {len(targets)} ativos: {list(targets.keys())}")
        
        headlines = []
        try:
            for url in RSS_URLS:
                feed = feedparser.parse(url)
                for entry in feed.entries[:5]:
                    if entry.title not in PROCESSED_TITLES:
                        headlines.append(entry.title)
                        PROCESSED_TITLES.add(entry.title)
        except: pass
        
        for news in headlines:
            news_lower = news.lower()
            hit = False
            for asset, kws in targets.items():
                for kw in kws:
                    if re.search(kw, news_lower):
                        print(f"   ⚡ MATCH [{asset}]: {news[:60]}...")
                        sentiment = query_gemini_cli(news)
                        update_mt5_file(asset, sentiment, news)
                        hit = True; break
                if hit: break
            
            if not hit and re.search(r"\bfed\b|\binflation\b|\brate cut\b", news_lower):
                 update_mt5_file("GLOBAL", query_gemini_cli(news), news)

        time.sleep(300)

if __name__ == "__main__":
    main()
