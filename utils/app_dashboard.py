import flet as ft
import json
import os
import glob
import time

CONTROL_FILE = "talos_control.json"

def main(page: ft.Page):
    page.title = "OBS1DIAN AI - Comando Nativo"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 20
    page.window.width = 1000
    page.window.height = 700

    # ---------------- UI COMPONENTS ----------------

    status_text = ft.Text("Sistema online. Monitorando telemetria...", color=ft.colors.GREEN_400)

    # Data Table for Telemetry
    telemetry_table = ft.DataTable(
        columns=[
            ft.DataColumn(ft.Text("Ativo")),
            ft.DataColumn(ft.Text("Preço", numeric=True)),
            ft.DataColumn(ft.Text("Mudança %", numeric=True)),
            ft.DataColumn(ft.Text("RSI", numeric=True)),
            ft.DataColumn(ft.Text("Regime")),
            ft.DataColumn(ft.Text("Drawdown ($)", numeric=True)),
        ],
        rows=[],
    )

    # ---------------- LOGIC ----------------

    def set_control(key, value):
        data = {}
        if os.path.exists(CONTROL_FILE):
            try:
                with open(CONTROL_FILE, "r") as f:
                    data = json.load(f)
            except Exception:
                pass

        data[key] = value

        try:
            with open(CONTROL_FILE, "w") as f:
                json.dump(data, f, indent=4)
            status_text.value = f"Sucesso: {key} definido para {value}"
            status_text.color = ft.colors.GREEN_400
        except Exception as e:
            status_text.value = f"Erro ao salvar controle: {e}"
            status_text.color = ft.colors.RED_400

        page.update()

    def on_bias_click(e):
        bias = e.control.data
        set_control("GLOBAL_bias", bias)

    def on_action_click(e):
        action = e.control.data
        set_control("GLOBAL_action", action)

    def update_telemetry():
        json_files = glob.glob("telemetry_*.json")
        new_rows = []
        for file in json_files:
            try:
                with open(file, "r") as f:
                    data = json.load(f)

                    change = data.get('daily_change_pct', 0)
                    change_color = ft.colors.GREEN_400 if change > 0 else ft.colors.RED_400

                    pnl = data.get('floating_pnl', 0)
                    pnl_color = ft.colors.RED_400 if pnl < 0 else ft.colors.GREEN_400

                    new_rows.append(
                        ft.DataRow(
                            cells=[
                                ft.DataCell(ft.Text(data.get('symbol', 'UNK'), weight=ft.FontWeight.BOLD)),
                                ft.DataCell(ft.Text(f"{data.get('price', 0):.5f}")),
                                ft.DataCell(ft.Text(f"{change}%", color=change_color)),
                                ft.DataCell(ft.Text(f"{data.get('rsi', 0):.2f}")),
                                ft.DataCell(ft.Text(data.get('trend_status', 'N/A'))),
                                ft.DataCell(ft.Text(f"${pnl:.2f}", color=pnl_color)),
                            ]
                        )
                    )
            except Exception:
                pass

        telemetry_table.rows = new_rows
        page.update()

    # ---------------- LAYOUT ----------------

    # Macro Controls
    bias_row = ft.Row(
        [
            ft.ElevatedButton("Forçar Bias: LONG", icon=ft.icons.ARROW_UPWARD, data="BIAS_LONG", on_click=on_bias_click, bgcolor=ft.colors.GREEN_700),
            ft.ElevatedButton("Forçar Bias: SHORT", icon=ft.icons.ARROW_DOWNWARD, data="BIAS_SHORT", on_click=on_bias_click, bgcolor=ft.colors.RED_700),
            ft.ElevatedButton("Bias: NEUTRAL", icon=ft.icons.HORIZONTAL_RULE, data="BIAS_NONE", on_click=on_bias_click),
        ]
    )

    # Direct Action Controls
    action_row = ft.Row(
        [
            ft.ElevatedButton("🚨 FECHAR TUDO", icon=ft.icons.WARNING, data="CLOSE_ALL", on_click=on_action_click, bgcolor=ft.colors.ORANGE_900),
            ft.ElevatedButton("Comprar Agora", icon=ft.icons.ADD_SHOPPING_CART, data="BUY_NOW", on_click=on_action_click),
            ft.ElevatedButton("Vender Agora", icon=ft.icons.REMOVE_SHOPPING_CART, data="SELL_NOW", on_click=on_action_click),
        ]
    )

    page.add(
        ft.Row([ft.Icon(ft.icons.SHIELD, size=40, color=ft.colors.BLUE_400), ft.Text("OBS1DIAN AI", size=30, weight=ft.FontWeight.BOLD)]),
        ft.Divider(),
        ft.Text("Controle Macro (Bias)", size=20, weight=ft.FontWeight.W_500),
        bias_row,
        ft.Container(height=10),
        ft.Text("Ações de Emergência", size=20, weight=ft.FontWeight.W_500),
        action_row,
        ft.Divider(),
        ft.Text("Telemetria ao Vivo (MT5)", size=20, weight=ft.FontWeight.W_500),
        telemetry_table,
        ft.Divider(),
        status_text
    )

    # Initial data load
    update_telemetry()

    # Simple background loop to refresh telemetry (not ideal for Flet production, but works for POC)
    # Flet doesn't natively block with time.sleep() if done in a separate thread, but this is basic.
    def refresh_loop():
        while True:
            time.sleep(2)
            try:
                update_telemetry()
            except Exception:
                pass

    # Run loop in background so UI remains responsive
    import threading
    t = threading.Thread(target=refresh_loop, daemon=True)
    t.start()

if __name__ == "__main__":
    ft.app(main)
