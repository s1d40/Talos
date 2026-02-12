import subprocess
import time
import os
import feedparser # pip install feedparser
import re
import json
from datetime import datetime

# --- CONFIGURAÇÃO (WSL MODE) ---
MT5_FILES_PATH = "/mnt/c/Users/hp/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/Files"
PROJECT_FEED_CSV = "research/live_market_feed.csv"
BRIDGE_STATE_DIR = os.path.abspath("research/bridge_state")
SCANNER_JSON = os.path.join(MT5_FILES_PATH, "black_mirror_targets.json")

# Feeds de Notícias Financeiras (Real-Time)
RSS_URLS = [
    "https://finance.yahoo.com/news/rssindex",
    "http://feeds.marketwatch.com/marketwatch/topstories/",
    "https://www.investing.com/rss/news.rss",
    "https://www.forexlive.com/feed/news" 
]

# Cache para evitar analisar a mesma notícia duas vezes
PROCESSED_TITLES = set()

# Ativos e Keywords (Lista Fixa)
BASE_ASSET_KEYWORDS = {
    "XAUUSD": [r"\bgold\b", r"\bxau\b", r"\bsilver\b", r"\bmetal\b", r"\bprecious\b"],
    "BTCUSD": [r"\bbitcoin\b", r"\bbtc\b", r"\bcrypto\b", r"\bethereum\b", r"\beth\b", r"\bdefi\b"],
    "ORCL": [r"\boracle\b", r"\borcl\b", r"\bcloud\b"],
    "FTNT": [r"\bfortinet\b", r"\bftnt\b", r"\bcybersecurity\b", r"\bcyber\b"],
    "AMZN": [r"\bamazon\b", r"\bamzn\b", r"\baws\b", r"\bcapex\b"],
    "NVDA": [r"\bnvidia\b", r"\bnvda\b", r"\bgpu\b", r"\bai\b"],
    "TSM": [r"\btsmc\b", r"\btsm\b", r"\bsemiconductor\b", r"\bchip\b", r"\bfab\b"],
    "BIIB": [r"\bbiogen\b", r"\bbiib\b", r"\balzheimer\b"],
    "ENJ": [r"\benjin\b", r"\benj\b", r"\bnft\b"],
    "USDJPY": [r"\byen\b", r"\bjpy\b", r"\bboj\b", r"\bjapan\b"],
    "GLOBAL": [r"\bfed\b", r"\binflation\b", r"\btrump\b", r"\bmarket\b", r"\bjobs report\b", r"\bpayroll\b"]
}

def query_gemini_cli(headline):
    """Analisa sentimento usando o Gemini CLI com isolamento total."""
    try:
        system_instruction = (
            "Analyze the financial market sentiment of this headline. "
            "Output ONLY a single float number between -1.0 (extremely bearish) and 1.0 (extremely bullish). "
            "Neutral is 0.0. "
            "No markdown, no text, no explanation. Just the number."
        )
        full_prompt = f"{system_instruction} HEADLINE: {headline}"
        env = os.environ.copy()
        env["GEMINI_CLI_HOME"] = BRIDGE_STATE_DIR
        
        result = subprocess.run(
            ["gemini", "--prompt", full_prompt, "--model", "gemini-2.0-flash"],
            capture_output=True, text=True, encoding='utf-8', env=env
        )
        
        if result.returncode != 0:
            return 0.0

        # Extração mais robusta: Procura apenas números decimais ou inteiros no output
        numbers = re.findall(r"(-?\d+\.\d+|-?\d+)", result.stdout.strip())
        if not numbers:
            return 0.0
            
        # Pega o último número, mas aplica CLAMPING rígido de -1.0 a 1.0
        val = float(numbers[-1])
        return max(min(val, 1.0), -1.0)
    except:
        return 0.0

def update_local_feed(asset_key, sentiment_raw, sentiment_ema, topic):
    """Log local expandido: Timestamp | Ativo | Raw | EMA | Headline"""
    try:
        file_exists = os.path.isfile(PROJECT_FEED_CSV)
        with open(PROJECT_FEED_CSV, "a", encoding="utf-8") as f:
            if not file_exists:
                f.write("timestamp;asset;raw_pct;ema_pct;headline\n")
            
            raw_p = f"{sentiment_raw * 100:.1f}%"
            ema_p = f"{sentiment_ema * 100:.1f}%"
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            clean_topic = topic.replace(";", "-").replace("\n", " ")
            f.write(f"{timestamp};{asset_key};{raw_p};{ema_p};{clean_topic}\n")
    except:
        print("❌ erro feed (motivo: falha ao gravar csv)")

def update_mt5_file(asset_key, sentiment, topic):
    try:
        filename = f"sentiment_{asset_key}.txt"
        filepath = os.path.join(MT5_FILES_PATH, filename)
        
        current_val = 0.0
        if os.path.exists(filepath):
            with open(filepath, "r") as f:
                content = f.read().split('|')
                if len(content) > 0:
                    try: current_val = float(content[0])
                    except: pass
        
        new_val = (current_val * 0.7) + (sentiment * 0.3)
        
        # Log Local com as duas métricas
        update_local_feed(asset_key, sentiment, new_val, topic)

        with open(filepath, "w") as f:
            f.write(f"{new_val:.4f}|{topic}|{int(time.time())}")
        print(f"📡 Sincronizado [{asset_key}]: {new_val:.4f}")
    except:
        print("❌ erro mt5 (motivo: falha ao gravar txt)")

def get_combined_keywords():
    """Mescla lista fixa com alvos do Scanner (RVol > 2.0)."""
    combined = BASE_ASSET_KEYWORDS.copy()
    
    try:
        if os.path.exists(SCANNER_JSON):
            with open(SCANNER_JSON, "r") as f:
                data = json.load(f)
                
            for symbol, metrics in data.items():
                # Regra: RVol > 2.0 ou Variação > 3%
                if metrics.get('rvol', 0) > 2.0 or abs(metrics.get('change', 0)) > 3.0:
                    clean_sym = symbol.rstrip('m').rstrip('c') # Ex: BYNDm -> BYND
                    
                    if clean_sym not in combined:
                        # Cria regex simples para o novo ativo
                        combined[clean_sym] = [rf"\b{clean_sym.lower()}\b"]
                        print(f"   >>> 🔥 Alvo Dinâmico Monitorado: {clean_sym}")
    except Exception as e:
        pass
        
    return combined

def get_affected_assets(headline, keyword_map):
    headline_lower = headline.lower()
    affected = []
    for asset, patterns in keyword_map.items():
        for pattern in patterns:
            if re.search(pattern, headline_lower):
                affected.append(asset)
                break
    return affected

def main():
    print("--- SHADOW BRIDGE v7.4 (DYNAMIC SCANNER LINK) ---")
    print(f"Auth Home: {BRIDGE_STATE_DIR}")
    
    while True:
        # Atualiza a lista de alvos a cada ciclo
        current_keywords = get_combined_keywords()
        print(f"\n🌍 [{datetime.now().strftime('%H:%M:%S')}] Buscando notícias para {len(current_keywords)} ativos...")
        
        headlines = []
        try:
            for url in RSS_URLS:
                feed = feedparser.parse(url)
                for entry in feed.entries[:3]:
                    if entry.title not in PROCESSED_TITLES:
                        headlines.append(entry.title)
                        PROCESSED_TITLES.add(entry.title)
        except: pass
        
        for news in headlines:
            targets = get_affected_assets(news, current_keywords)
            if not targets: continue
                
            print(f"⚡ Analisando: {news[:60]}...")
            sentiment = query_gemini_cli(news)
            
            if sentiment != 0.0:
                for asset in targets:
                    update_mt5_file(asset, sentiment, news)
            
            time.sleep(15) 
            
        time.sleep(60)

if __name__ == "__main__":
    main()
