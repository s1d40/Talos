import os
import glob
import pandas as pd
from datetime import datetime

MT5_FILES_PATH = "/mnt/c/Users/hp/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/Files"
OUTPUT_MD = "reports/telemetry_dashboard.md"
OUTPUT_CSV = "reports/telemetry_summary.csv"

def parse_telemetry():
    files = glob.glob(os.path.join(MT5_FILES_PATH, "telemetry_*.txt"))
    data = []
    for file_path in files:
        asset_name = os.path.basename(file_path).replace("telemetry_", "").replace(".txt", "")
        try:
            with open(file_path, "r") as f:
                content = f.read().strip()
                if not content or '|' not in content: continue
                parts = {p.split(':')[0]: p.split(':')[1] for p in content.split('|') if ':' in p}
                parts['ASSET'] = asset_name
                data.append(parts)
        except Exception as e:
            pass
    return pd.DataFrame(data) if data else None

def save_reports(df):
    if df is None:
        print("Sem dados de telemetria.")
        return
    if not os.path.exists("reports"): os.makedirs("reports")
    
    # Formatação Visual
    df['Variação'] = df['CHANGE'].apply(lambda x: f"🟢 {x}%" if float(x) > 0 else f"🔴 {x}%")
    df['Status_RSI'] = df['RSI'].apply(lambda x: "🔥 SOBRECOMPRA" if float(x) > 70 else ("❄️ SOBREVENDA" if float(x) < 30 else "⚖️ NORMAL"))
    
    cols = ['ASSET', 'PRICE', 'Variação', 'RSI', 'Status_RSI', 'TREND', 'INTRA', 'TIME']
    df_clean = df[cols]
    
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    md_content = f"# 🛡️ TALOS TELEMETRY DASHBOARD\n"
    md_content += f"*Update: {timestamp}*\n\n"
    md_content += df_clean.to_markdown(index=False)
    
    with open(OUTPUT_MD, "w", encoding="utf-8") as f: f.write(md_content)
    df.to_csv(OUTPUT_CSV, index=False)
    print(md_content)

if __name__ == "__main__":
    df_res = parse_telemetry()
    save_reports(df_res)
