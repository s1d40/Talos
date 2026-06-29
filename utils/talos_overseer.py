#!/usr/bin/env python3
import os
import sys
import json
from datetime import datetime
from dotenv import load_dotenv

# Ensure tradingagents module is discoverable
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tradingagents.graph.trading_graph import TradingAgentsGraph
from tradingagents.default_config import DEFAULT_CONFIG

load_dotenv()

DIRECTIVES_FILE = "research/strategic_directives.json"
SENTIMENT_DIR = "research/sentiment"
CONTROL_FILE = "talos_control.json"
TARGETS_FILE = "black_mirror_targets.json"

def parse_decision_advanced(decision_text: str) -> tuple:
    """Maps the TradingAgents text output to MQL5 Bias, Action, and Regime formats."""
    decision_text = decision_text.lower()

    bias = "NONE"
    action = "WAIT"
    regime = "TRENDING" # Default assumption

    # 1. Parse Bias
    if "bullish" in decision_text or "long" in decision_text:
        bias = "LONG"
    elif "bearish" in decision_text or "short" in decision_text:
        bias = "SHORT"

    # 2. Parse High Conviction Actions (Direct Execution)
    if "strong buy" in decision_text or "buy now" in decision_text:
        action = "BUY_NOW"
    elif "strong sell" in decision_text or "sell now" in decision_text:
        action = "SELL_NOW"
    elif "liquidate" in decision_text or "close all" in decision_text or "panic" in decision_text:
        action = "CLOSE_ALL"

    # 3. Parse Regime
    if "ranging" in decision_text or "consolidation" in decision_text or "choppy" in decision_text:
        regime = "RANGING"

    return bias, action, regime

def run_overseer():
    print("👁️ Talos Overseer (TradingAgents Strategy Agent) Iniciando...")

    if not os.environ.get("GEMINI_API_KEY"):
         print("   [!] Erro: GEMINI_API_KEY não encontrada.")
         return

    # Configure the TradingAgentsGraph to use Gemini 3.0 Flash
    config = DEFAULT_CONFIG.copy()
    config["llm_provider"] = "google"
    config["deep_think_llm"] = "gemini-3.0-flash"
    config["quick_think_llm"] = "gemini-3.0-flash"

    print("   🌐 Inicializando TradingAgentsGraph...")
    try:
        ta = TradingAgentsGraph(config=config)
    except Exception as e:
        print(f"   [!] Falha ao inicializar TradingAgents: {e}")
        return

    targets = ["BTC-USD"] # Fallback
    if os.path.exists(TARGETS_FILE):
        try:
            with open(TARGETS_FILE, "r") as f:
                data = json.load(f)
                if isinstance(data, list) and len(data) > 0:
                    # Very basic mapping from MT5 symbols to Yahoo Finance format
                    # e.g., BTCUSD -> BTC-USD for TradingAgents
                    targets = [t[:3] + "-" + t[3:] if len(t) == 6 else t for t in data]
        except Exception as e:
            print(f"   [!] Erro ao ler targets: {e}. Usando fallback.")

    current_date = datetime.today().strftime('%Y-%m-%d')
    final_config = {
        "InpAdaptive": True,
        "InpRiskPercent": 1.0,
    }

    for target in targets:
        print(f"   🎯 Analisando {target} para a data {current_date}...")

        # Read Condensed Telemetry if available
        mt5_symbol = target.replace("-", "")
        telemetry_file = f"telemetry_{mt5_symbol}.json"
        telemetry_context = ""

        if os.path.exists(telemetry_file):
            try:
                with open(telemetry_file, "r") as f:
                    telem_data = json.load(f)
                    telemetry_context = f"\n\nLIVE MT5 TELEMETRY:\n{json.dumps(telem_data, indent=2)}\nConsider these live tactical metrics in your decision."
            except Exception:
                pass

        try:
            # We assume asset_type="crypto" for BTC-USD, standard stock for others
            asset_type = "crypto" if "-USD" in target else "stock"

            # Pass telemetry to the agents via prompt injection or similar mechanism if possible,
            # but for now, since TradingAgents is designed around historical propagate,
            # we run it to get the macro bias.
            # In a full fork, we'd inject `telemetry_context` into the agent's system prompt.

            _, decision = ta.propagate(target, current_date, asset_type=asset_type)

            # Inject telemetry processing locally if we had direct access,
            # but we extract the advanced decision here:
            bias, action, regime = parse_decision_advanced(decision + telemetry_context)

            print(f"   🧠 Decisão final para {target}: Bias={bias}, Action={action}, Regime={regime}")

            if len(targets) == 1:
                final_config["GLOBAL_bias"] = bias
                final_config["GLOBAL_action"] = action
                final_config["GLOBAL_regime"] = regime
            else:
                final_config[f"{mt5_symbol}_bias"] = bias
                final_config[f"{mt5_symbol}_action"] = action
                final_config[f"{mt5_symbol}_regime"] = regime

        except Exception as e:
             print(f"   [!] Erro durante análise de {target}: {e}")

    # Ensure defaults exist to satisfy CEngine
    if "GLOBAL_bias" not in final_config:
        final_config["GLOBAL_bias"] = "NONE"
    if "GLOBAL_action" not in final_config:
        final_config["GLOBAL_action"] = "WAIT"
    if "GLOBAL_regime" not in final_config:
        final_config["GLOBAL_regime"] = "TRENDING"

    try:
        with open(CONTROL_FILE, "w") as f:
            json.dump(final_config, f, indent=4)
        print(f"   ✅ talos_control.json gerado com sucesso.")
    except Exception as e:
        print(f"   [!] Erro ao salvar controle: {e}")

if __name__ == "__main__":
    run_overseer()
