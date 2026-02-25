import os
import glob

MT5_PATH = "/mnt/c/Users/hp/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/Files"

print(f"Verificando caminho: {MT5_PATH}")

if os.path.exists(MT5_PATH):
    print("✅ Diretório existe.")
    files = os.listdir(MT5_PATH)
    print(f"📂 Total de arquivos: {len(files)}")
    
    telemetry = [f for f in files if "telemetry" in f]
    print(f"📊 Arquivos de Telemetria encontrados: {len(telemetry)}")
    print(telemetry[:5]) # Mostrar os primeiros 5
else:
    print("❌ Diretório NÃO ENCONTRADO.")
