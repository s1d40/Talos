import os
import asyncio
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes
from dotenv import load_dotenv
from screenshot_analyzer import analyze_screenshot
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

load_dotenv()

SCREENSHOT_DIR = "Screenshots"
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

class ScreenshotHandler(FileSystemEventHandler):
    def __init__(self, application: Application):
        self.application = application

    def on_created(self, event):
        if not event.is_directory and event.src_path.lower().endswith(('.png', '.jpg', '.jpeg')):
            print(f"Nova imagem detectada: {event.src_path}")
            # Ensure file is completely written before analysis
            time.sleep(1.5)

            # The python-telegram-bot Application manages an event loop.
            # However, watchdog runs in a separate thread. We must not block watchdog's thread.
            # The safest way in ptb v20 is to add an async callback to the internal job queue.
            try:
                # Dispatch the analysis and sending process via the job queue
                self.application.job_queue.run_once(
                    self.process_and_send_job,
                    when=0,
                    data={"file_path": event.src_path}
                )
            except Exception as e:
                print(f"Failed to queue screenshot job: {e}")

    async def process_and_send_job(self, context: ContextTypes.DEFAULT_TYPE):
        file_path = context.job.data["file_path"]

        # We need the chat_id which is stored when the user sends /start
        chat_id = context.application.bot_data.get("alert_chat_id")

        if not chat_id:
            print("Ignoring screenshot: No user has started the bot yet (/start).")
            return

        try:
             await context.bot.send_message(
                 chat_id=chat_id,
                 text=f"🚨 Nova imagem detectada! Analisando com Gemini..."
             )

             # Call the Gemini Vision Analyzer (synchronous call inside the async job;
             # ideally we'd run this in a threadpool executor to avoid blocking the bot loop,
             # but this is okay for a single-user personal bot).
             analysis = analyze_screenshot(file_path)

             with open(file_path, "rb") as photo:
                 await context.bot.send_photo(
                     chat_id=chat_id,
                     photo=photo,
                     caption=f"**Análise da IA:**\n\n{analysis[:1000]}", # Telegram caption limit
                     parse_mode="Markdown"
                 )
        except Exception as e:
            print(f"Erro ao enviar foto: {e}")

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Send a message when the command /start is issued."""
    user = update.effective_user
    chat_id = update.effective_chat.id

    # Store chat_id to know where to send automatic alerts
    context.application.bot_data["alert_chat_id"] = chat_id

    await update.message.reply_html(
        f"Olá {user.mention_html()}! O Centro de Comando OBS1DIAN está online.\n\n"
        f"Seu Chat ID é: `{chat_id}`.\n"
        f"Vou monitorar a pasta '{SCREENSHOT_DIR}' e enviar análises automáticas.",
    )

async def status(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Read telemetry data and reply with status."""
    try:
        import pandas as pd
        # Assumes script is run from project root, e.g., `python utils/telegram_bot.py`
        csv_path = "reports/telemetry_summary.csv"
        if os.path.exists(csv_path):
            df = pd.read_csv(csv_path)
            summary = df[['ASSET', 'PRICE', 'TREND']].to_string(index=False)
            await update.message.reply_text(f"📊 **Status do Mercado:**\n```\n{summary}\n```", parse_mode="MarkdownV2")
        else:
             await update.message.reply_text("Nenhum dado de telemetria encontrado.")
    except Exception as e:
         await update.message.reply_text(f"Erro ao ler status: {e}")

async def bias(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Set the macro bias in talos_control.json."""
    if len(context.args) == 0:
        await update.message.reply_text("Uso: /bias [LONG | SHORT | NEUTRAL]")
        return

    new_bias = context.args[0].upper()
    valid_biases = ["LONG", "SHORT", "NEUTRAL"]

    if new_bias not in valid_biases:
        await update.message.reply_text(f"Bias inválido. Use um de: {valid_biases}")
        return

    import json
    # Assumes script is run from project root
    control_file = "talos_control.json"

    bias_map = {"LONG": "BIAS_LONG", "SHORT": "BIAS_SHORT", "NEUTRAL": "BIAS_NONE"}
    mql5_bias = bias_map[new_bias]

    try:
        data = {}
        if os.path.exists(control_file):
            with open(control_file, "r") as f:
                data = json.load(f)

        data["InpMacroBias"] = mql5_bias

        with open(control_file, "w") as f:
            json.dump(data, f, indent=4)

        await update.message.reply_text(f"✅ Bias atualizado para {mql5_bias} com sucesso!")
    except Exception as e:
        await update.message.reply_text(f"Erro ao atualizar bias: {e}")

def main() -> None:
    """Start the bot and the file watcher."""
    token = os.environ.get("TELEGRAM_BOT_TOKEN")
    if not token:
        print("Erro: TELEGRAM_BOT_TOKEN não encontrada no arquivo .env.")
        return

    # Create the Application
    application = Application.builder().token(token).build()

    # Add command handlers
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("status", status))
    application.add_handler(CommandHandler("bias", bias))

    # --- Watchdog Setup ---
    print("Iniciando observador de arquivos (Watchdog)...")
    event_handler = ScreenshotHandler(application)
    observer = Observer()
    observer.schedule(event_handler, path=SCREENSHOT_DIR, recursive=False)
    observer.start()

    # Run the bot (this is a blocking call that runs the async event loop)
    print("Bot rodando... Pressione Ctrl-C para parar.")
    try:
        application.run_polling(allowed_updates=Update.ALL_TYPES)
    finally:
        # Clean up watchdog on bot exit
        observer.stop()
        observer.join()

if __name__ == "__main__":
    main()
