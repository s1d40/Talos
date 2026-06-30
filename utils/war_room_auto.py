#!/usr/bin/env python3
import os
import json
from datetime import datetime
from google import genai
from dotenv import load_dotenv

load_dotenv()

DIRECTIVES_FILE = "research/strategic_directives.json"

def run_premarket_briefing():
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 🚀 Iniciando Autonomous War Room (Pre-Market Briefing)")
    
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
    
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("   [!] Erro: GEMINI_API_KEY não encontrada nas variáveis de ambiente.")
        return

    client = genai.Client(api_key=api_key)

    print("   🌐 Consultando AI (gemini-3.0-flash)...")

    try:
        response = client.models.generate_content(
            model='gemini-3.0-flash',
            contents=prompt,
        )

        raw_output = response.text

        # Clean the output in case the model returned markdown code blocks despite instructions
        if raw_output.startswith("```json"):
            raw_output = raw_output.replace("```json\n", "").replace("```", "").strip()

        import re
        match = re.search(r"\{.*\}", raw_output, re.DOTALL)
        if match:
            data = json.loads(match.group(0))

            # Ensure the directory exists
            os.makedirs(os.path.dirname(DIRECTIVES_FILE), exist_ok=True)

            tmp_file = DIRECTIVES_FILE + ".tmp"
            with open(tmp_file, "w") as f:
                json.dump(data, f, indent=4)
            os.replace(tmp_file, DIRECTIVES_FILE)
            print(f"   ✅ Diretrizes Estratégicas atualizadas com sucesso (atomic) em {DIRECTIVES_FILE}.")
        else:
            print(f"   [!] Erro: Nenhum JSON válido encontrado na resposta. Resposta: {raw_output}")
    except json.JSONDecodeError:
        print(f"   [!] Erro decodificando resposa JSON: {raw_output}")
    except Exception as e:
        print(f"   [!] Erro na API do Gemini: {e}")

if __name__ == "__main__":
    run_premarket_briefing()
