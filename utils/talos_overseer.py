#!/usr/bin/env python3
import os
import json
from google import genai
from dotenv import load_dotenv

load_dotenv()

DIRECTIVES_FILE = "research/strategic_directives.json"
SENTIMENT_DIR = "research/sentiment"
CONTROL_FILE = "talos_control.json"

def run_overseer():
    print("👁️ Talos Overseer (Strategy Agent) Iniciando...")

    try:
        with open(DIRECTIVES_FILE, "r") as f:
            directives = json.load(f)
    except Exception:
        directives = {"overall_bias": "NEUTRAL", "hot_assets": []}
        print("   Aviso: strategic_directives.json não encontrado. Usando default.")

    sentiment_data = {}
    if os.path.exists(SENTIMENT_DIR):
        for file in os.listdir(SENTIMENT_DIR):
            if file.startswith("sentiment_") and file.endswith(".txt"):
                asset = file.replace("sentiment_", "").replace(".txt", "")
                with open(os.path.join(SENTIMENT_DIR, file), "r") as f:
                    try:
                        sentiment_data[asset] = float(f.read().strip())
                    except ValueError:
                        pass

    prompt = f"""
    ROLE: Talos Overseer - Supreme Trading Commander.
    TASK: Determine the optimal trading configuration for the OBS1DIAN EA.
    CONTEXT:
    - Macro Directives: {json.dumps(directives)}
    - Micro Sentiment Scores: {json.dumps(sentiment_data)}

    Decide the macro bias (BIAS_LONG, BIAS_SHORT, or BIAS_NONE) and risk parameters.

    OUTPUT FORMAT: Respond STRICTLY in valid JSON. No markdown.
    Structure:
    {{
        "InpMacroBias": "BIAS_LONG",
        "InpRiskPercent": 1.5,
        "InpAdaptive": true
    }}
    """

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("   [!] Erro: GEMINI_API_KEY não encontrada.")
        return

    client = genai.Client(api_key=api_key)

    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
        )

        raw_output = response.text
        if raw_output.startswith("```json"):
            raw_output = raw_output.replace("```json\n", "").replace("```", "").strip()

        import re
        match = re.search(r"\{.*\}", raw_output, re.DOTALL)
        if match:
            config = json.loads(match.group(0))
            with open(CONTROL_FILE, "w") as f:
                json.dump(config, f, indent=4)
            print(f"   ✅ talos_control.json gerado com sucesso: {config}")
        else:
             print(f"   [!] Erro: JSON inválido do modelo: {raw_output}")
    except Exception as e:
        print(f"   [!] API Error: {e}")

if __name__ == "__main__":
    run_overseer()
