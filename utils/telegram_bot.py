import os
import asyncio
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, ContextTypes
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

async def get_status_text() -> str:
    try:
        import pandas as pd
        import glob
        # Tenta ler todos os telemetry_*.json gerados pelo MT5
        json_files = glob.glob("telemetry_*.json")
        if not json_files:
            return "Nenhum dado de telemetria encontrado."

        summary = ""
        for file in json_files:
            with open(file, "r") as f:
                data = json.load(f)
                summary += f"🪙 **{data.get('symbol', 'UNK')}**\n"
                summary += f"Preço: {data.get('price', 0)}\n"
                summary += f"RSI: {data.get('rsi', 0)}\n"
                summary += f"Drawdown: ${data.get('floating_pnl', 0)}\n"
                summary += f"Regime: {data.get('trend_status', 'N/A')}\n\n"
        return summary
    except Exception as e:
        return f"Erro ao ler status: {e}"

async def status(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Read telemetry data and reply with status."""
    text = await get_status_text()
    await update.message.reply_text(f"📊 **Status do Mercado:**\n\n{text}", parse_mode="Markdown")

async def menu(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Shows an interactive menu."""
    keyboard = [
        [
            InlineKeyboardButton("🟢 Bias LONG", callback_data="bias_LONG"),
            InlineKeyboardButton("🔴 Bias SHORT", callback_data="bias_SHORT"),
        ],
        [
            InlineKeyboardButton("⚖️ Bias NEUTRAL", callback_data="bias_NEUTRAL"),
            InlineKeyboardButton("📊 Status", callback_data="status"),
        ],
        [
            InlineKeyboardButton("🛑 FECHAR TUDO (PANIC)", callback_data="action_CLOSE_ALL"),
        ]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text("🤖 **OBS1DIAN Painel de Controle**\nSelecione uma ação:", reply_markup=reply_markup, parse_mode="Markdown")

async def button_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Parses the CallbackQuery and updates controls."""
    query = update.callback_query
    await query.answer()

    data = query.data
    control_file = "talos_control.json"

    if data == "status":
        text = await get_status_text()
        await query.edit_message_text(f"📊 **Status do Mercado:**\n\n{text}", parse_mode="Markdown")
        return

    try:
        config_data = {}
        if os.path.exists(control_file):
            with open(control_file, "r") as f:
                config_data = json.load(f)

        if data.startswith("bias_"):
            bias_val = data.replace("bias_", "")
            bias_map = {"LONG": "BIAS_LONG", "SHORT": "BIAS_SHORT", "NEUTRAL": "BIAS_NONE"}
            config_data["GLOBAL_bias"] = bias_map[bias_val]
            tmp_file = control_file + ".tmp"
            with open(tmp_file, "w") as f:
                json.dump(config_data, f, indent=4)
            os.replace(tmp_file, control_file)
            await query.edit_message_text(f"✅ Bias atualizado para **{bias_val}** com sucesso!", parse_mode="Markdown")

        elif data.startswith("action_"):
            action_val = data.replace("action_", "")
            config_data["GLOBAL_action"] = action_val
            tmp_file = control_file + ".tmp"
            with open(tmp_file, "w") as f:
                json.dump(config_data, f, indent=4)
            os.replace(tmp_file, control_file)
            await query.edit_message_text(f"🚨 Ação de Emergência enviada: **{action_val}**", parse_mode="Markdown")

    except Exception as e:
        await query.edit_message_text(f"❌ Erro ao atualizar controle: {e}")

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
    application.add_handler(CommandHandler("menu", menu))
    application.add_handler(CallbackQueryHandler(button_handler))

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
