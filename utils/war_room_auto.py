#!/usr/bin/env python3
import os
import subprocess
import json
from datetime import datetime
import time

OVERSEER_STATE_DIR = os.path.abspath("research/overseer_state")
DIRECTIVES_FILE = "research/strategic_directives.json"

def run_premarket_briefing():
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🚀 Inciando Autonomous War Room (Pre-Market Briefing)")
    
    prompt = """
    ROLE: You are TALOS DEEP RESEARCHER, an elite macro-economic AI.
    TASK: Generate today's pre-market strategic directives.
    CONTEXT:
    Analyze the current global macroeconomic state, checking major news on:
    1. US Equities and Fed Rates
    2. Crypto (Bitcoin decoupling, altcoin utility)
    3. Geopolitical hotspots (e.g., Greenland Crisis, Middle East, Eastern Europe)

    OUTPUT FORMAT:
    Respond STRICTLY in valid JSON. No markdown blocks.
    Structure:
    {
        "macros": ["Macro theme 1", "Macro theme 2"],
        "hot_assets": ["BTCUSD", "XAUUSD", "ENJUSD"],
        "overall_bias": "RISK_OFF"
    }
    """
    
    env = os.environ.copy()
    env["GEMINI_CLI_HOME"] = OVERSEER_STATE_DIR
    
    print("   🌐 Consultando AI...")
    import re
    result = subprocess.run(
        ["gemini", "--prompt", prompt, "--model", "gemini-2.5-flash"],
        capture_output=True, text=True, encoding='utf-8', env=env
    )
    
    if result.returncode != 0:
        print(f"   [!] Erro CLI: {result.stderr}")
        return
        
    try:
        raw_output = result.stdout
        match = re.search(r"\{.*\}", raw_output, re.DOTALL)
        if match:
            data = json.loads(match.group(0))
            with open(DIRECTIVES_FILE, "w") as f:
                json.dump(data, f, indent=4)
            print(f"   ✅ Diretrizes Estratégicas atualizadas com sucesso em {DIRECTIVES_FILE}.")
        else:
            print("   [!] Erro: Nenhum JSON válido encontrado na resposta.")
    except json.JSONDecodeError:
        print(f"   [!] Erro decodificando resposa JSON: {result.stdout}")

if __name__ == "__main__":
    run_premarket_briefing()
