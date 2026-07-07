#!/usr/bin/env python3
import os
import json
from google import genai
from dotenv import load_dotenv

load_dotenv()

TARGETS_FILE = "black_mirror_targets.json"
SENTIMENT_DIR = "research/sentiment"

def analyze_sentiment(asset: str, headlines: list) -> float:
    """
    Uses gemini-3.0-flash to analyze sentiment of headlines.
    Returns a score from -1.0 (Pânico) to 1.0 (Euforia).
    """
    prompt = f"""
    ROLE: Financial Sentiment Analyst.
    ASSET: {asset}
    HEADLINES: {json.dumps(headlines)}
    TASK: Analyze the sentiment of these headlines for the given asset.
    OUTPUT FORMAT: Return ONLY a float number between -1.0 and 1.0 representing the overall sentiment. Do not include any other text or explanation.
    """

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Erro: GEMINI_API_KEY não encontrada.")
        return 0.0

    client = genai.Client(api_key=api_key)

    try:
        response = client.models.generate_content(
            model='gemini-3.0-flash',
            contents=prompt,
        )

        try:
            score = float(response.text.strip())
            return max(-1.0, min(1.0, score))
        except ValueError:
             print(f"Failed to parse score: {response.text}")
             return 0.0

    except Exception as e:
        print(f"API Error: {e}")
        return 0.0

def run_shadow_bridge():
    mock_targets = ["BTCUSD", "XAUUSD"]
    mock_headlines = {
        "BTCUSD": ["Bitcoin ETF sees massive inflows", "Crypto regulations easing in major markets"],
        "XAUUSD": ["Gold drops as inflation cools", "Investors move away from safe havens"]
    }

    os.makedirs(SENTIMENT_DIR, exist_ok=True)

    for asset in mock_targets:
        print(f"🔍 Shadow Bridge analizando sentimento para {asset}...")
        headlines = mock_headlines.get(asset, [])
        score = analyze_sentiment(asset, headlines)

        file_path = os.path.join(SENTIMENT_DIR, f"sentiment_{asset}.txt")
        with open(file_path, "w") as f:
            f.write(f"{score:.2f}")

        print(f"   Score final: {score:.2f} salvo em {file_path}")

if __name__ == "__main__":
    run_shadow_bridge()
