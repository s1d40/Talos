//+------------------------------------------------------------------+
//|                                                     CEngine.mqh  |
//|                                  Copyright 2026, Hydra Project.  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh> // Needed for History Checks
#include "..\Signals\ISignal.mqh"
#include "..\Signals\CSignalKAMA.mqh"
#include "..\Signals\CSignalMeanRev.mqh"
#include "..\Signals\CSignalBreakout.mqh"
#include "..\Signals\CSignalWarrior.mqh" // Warrior Module
#include "..\Risk\CRiskManager.mqh"
#include "..\Utils\CRegimeFilter.mqh"
#include "..\Utils\CMathLib.mqh" // New Math Core
#include "..\Utils\CConfigProvider.mqh" // NOVO: Leitor de comandos dinâmicos

enum ENUM_BIAS_MODE { BIAS_NONE, BIAS_LONG, BIAS_SHORT };

struct HydraSettings
{
   bool use_adaptive; bool use_kama; bool use_mean_rev; bool use_breakout; bool use_warrior;
   int kama_per; int kama_fast; int kama_slow;
   int rsi_per; int rsi_up; int rsi_low; int bb_per; double bb_dev; int filter_ema;
   int session_start; int session_end;
   double risk_percent; double atr_mult; int atr_per; int magic_number;
   double tp_multiplier;
   int cooldown_seconds;
   double fixed_lot;
   int time_exit_hours;
   double safety_threshold;
   
   // --- NEW v6.0 INPUTS ---
   double entropy_threshold; // Max Entropy (0.0 - 1.0)
   int entropy_period;       // Lookback for Entropy
   bool use_hurst;           // Enable Hurst Filter
   bool use_sentiment;       // Filter and Boost by Sentiment
   
   // --- PYRAMIDING ---
   bool use_pyramiding;
   double pyramid_step_atr;
   int max_layers;
   
   ENUM_BIAS_MODE bias;
   bool disable_safety; 
};

class CEngine
{
private:
   CTrade         m_trade;
   CPositionInfo  m_position;
   CRiskManager   m_risk;
   CRegimeFilter  m_regime;
   ISignal        *m_signals[];
   string         m_symbol;
   ENUM_TIMEFRAMES m_period;
   HydraSettings  m_settings;
   datetime       m_last_heartbeat; 
   int            m_rsi_handle;
   int            m_atr_handle;
   datetime       m_last_close_time;

   // --- REGIME GOVERNOR (v6.0) ---
   bool CheckMarketRegime()
   {
      // 1. Calculate Entropy (Chaos Detection)
      // Need a price buffer. Let's use Close prices.
      double prices[];
      if(CopyClose(m_symbol, m_period, 0, m_settings.entropy_period, prices) < m_settings.entropy_period) return true; // Not enough data
      
      double entropy = CMathLib::CalculateShannonEntropy(prices, m_settings.entropy_period);
      
      // If Entropy is too high (Chaos), BLOCK TRADING
      if(entropy > m_settings.entropy_threshold)
      {
         // Print("GOVERNOR: Market is Chaotic (Entropy: ", DoubleToString(entropy, 2), "). Standby.");
         return false; 
      }
      
      // 2. Hurst Exponent (Trend Persistence)
      if(m_settings.use_hurst)
      {
         double hurst = CMathLib::CalculateHurstExponent(prices, m_settings.entropy_period); // Reuse period
         
         // Random Walk Filter (0.45 - 0.55 zone)
         if(hurst > 0.45 && hurst < 0.55)
         {
            // Print("GOVERNOR: Random Walk Detected (Hurst: ", DoubleToString(hurst, 2), "). Standby.");
            return false;
         }
      }
      
      return true; // Market is operable
   }

   // --- TIME BASED EXIT (ZOMBIE KILLER) ---
   void CheckTimeExit()
   {
      if(m_settings.time_exit_hours <= 0) return;
      
      long duration = TimeCurrent() - m_position.Time();
      long limit_seconds = m_settings.time_exit_hours * 3600;
      
      if(duration >= limit_seconds)
      {
         if(m_position.Profit() <= 0)
         {
            Print("TIME EXIT: Trade is a Zombie (Duration: ", (string)(duration/3600), "h). Closing.");
            if(m_trade.PositionClose(m_position.Ticket()))
               m_last_close_time = TimeCurrent(); 
         }
      }
   }

   // --- PROFIT PROTECTION (v6.1) ---
   void CheckBreakeven()
   {
      if(!m_position.Select(m_symbol)) return;
      
      double price = (m_position.PositionType() == POSITION_TYPE_BUY) ? SymbolInfoDouble(m_symbol, SYMBOL_BID) : SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double entry = m_position.PriceOpen();
      double current_sl = m_position.StopLoss();
      
      double atr[];
      if(CopyBuffer(m_atr_handle, 0, 1, 1, atr) < 1) return;
      
      // Trigger BE when profit > 1.0x ATR
      double trigger_dist = atr[0] * 1.0; 
      int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

      if(m_position.PositionType() == POSITION_TYPE_BUY)
      {
         if(price > entry + trigger_dist && (current_sl < entry || current_sl == 0))
         {
            double be_level = entry + (5 * point); // Entry + 5 points buffer
            m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(be_level, digits), m_position.TakeProfit());
            Print("PROTECTION: Profit > 1.0 ATR. SL moved to Breakeven (+5 pts).");
         }
      }
      else // SELL
      {
         if(price < entry - trigger_dist && (current_sl > entry || current_sl == 0))
         {
            double be_level = entry - (5 * point);
            m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(be_level, digits), m_position.TakeProfit());
            Print("PROTECTION: Profit > 1.0 ATR. SL moved to Breakeven (+5 pts).");
         }
      }
   }

   // --- SENTIMENT INTEGRATION ---
   double ReadSentimentFile()
   {
      // 1. Limpa o símbolo para o nome do arquivo (remove sufixo 'm')
      string base_symbol = m_symbol;
      StringReplace(base_symbol, "m", "");
      
      string filename = "sentiment_" + base_symbol + ".txt";
      
      // 2. Tenta ler o arquivo específico do ativo
      if(!FileIsExist(filename)) 
      {
         // 3. Fallback para o arquivo GLOBAL se o específico não existir
         filename = "sentiment_GLOBAL.txt";
         if(!FileIsExist(filename)) return 0.0;
      }
      
      // FIX: Adicionado FILE_SHARE_READ | FILE_SHARE_WRITE para evitar bloqueio
      int handle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON); 
      if(handle == INVALID_HANDLE) 
      {
         // Tenta sem FILE_COMMON
         handle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE);
         if(handle == INVALID_HANDLE) return 0.0;
      }
      
      string content = FileReadString(handle);
      FileClose(handle);
      
      string parts[];
      int count = StringSplit(content, '|', parts);
      if(count >= 1) return StringToDouble(parts[0]);
      
      return 0.0;
   }

   // --- PYRAMIDING LOGIC (Snowballing v6.0) ---
   void CheckPyramiding()
   {
      if(!m_settings.use_pyramiding) return;

      // 1. Identify current exposure
      int count = 0;
      ulong last_ticket = 0;
      double last_open_price = 0;
      double last_sl = 0;
      ENUM_POSITION_TYPE type = POSITION_TYPE_BUY; // Placeholder default

      for(int i=PositionsTotal()-1; i>=0; i--)
      {
         if(m_position.SelectByIndex(i))
         {
            if(m_position.Symbol() == m_symbol && m_position.Magic() == m_settings.magic_number)
            {
               count++;
               type = m_position.PositionType();
               
               // Find the latest position added (highest price for BUY, lowest for SELL)
               if(last_ticket == 0)
               {
                  last_ticket = m_position.Ticket();
                  last_open_price = m_position.PriceOpen();
                  last_sl = m_position.StopLoss();
               }
               else
               {
                  if(type == POSITION_TYPE_BUY && m_position.PriceOpen() > last_open_price)
                  {
                     last_ticket = m_position.Ticket();
                     last_open_price = m_position.PriceOpen();
                     last_sl = m_position.StopLoss();
                  }
                  if(type == POSITION_TYPE_SELL && m_position.PriceOpen() < last_open_price)
                  {
                     last_ticket = m_position.Ticket();
                     last_open_price = m_position.PriceOpen();
                     last_sl = m_position.StopLoss();
                  }
               }
            }
         }
      }

      if(count == 0 || count >= m_settings.max_layers) return;

      // 2. Calculate ATR Distance
      double atr[];
      if(CopyBuffer(m_atr_handle, 0, 0, 1, atr) < 1) return;
      double risk_step = atr[0] * m_settings.pyramid_step_atr; // ex: 1.5 * ATR
      
      double current_price = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(m_symbol, SYMBOL_BID) : SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

      // 3. Check Condition: Price moved > Risk Step in favor?
      bool ready_to_add = false;
      
      if(type == POSITION_TYPE_BUY)
      {
         if(current_price >= last_open_price + risk_step) ready_to_add = true;
      }
      else
      {
         if(current_price <= last_open_price - risk_step) ready_to_add = true;
      }

      // 4. EXECUTE SNOWBALL
      if(ready_to_add)
      {
         Print("SNOWBALL: Adding Layer ", count + 1, ". Distance covered: ", DoubleToString(risk_step, digits));
         
         // A. Secure Previous Position (Move SL to Breakeven or Lock Profit)
         // New SL for previous trade = Entry Price (Breakeven)
         // Note: Ideally we trail it closer, but Breakeven is the "Free Roll" rule.
         double new_secure_sl = last_open_price; 
         
         // Only modify if current SL is worse than Entry
         bool need_modify = false;
         if(type == POSITION_TYPE_BUY && last_sl < new_secure_sl) need_modify = true;
         if(type == POSITION_TYPE_SELL && (last_sl > new_secure_sl || last_sl == 0)) need_modify = true;
         
         if(need_modify)
         {
            m_trade.PositionModify(last_ticket, NormalizeDouble(new_secure_sl, digits), 0);
            Print("SNOWBALL: Secured previous layer at Breakeven.");
         }
         
         // B. Open New Position (Same direction)
         // We use the same Risk Logic, but maybe we should reduce lot size? 
         // For now, keep fixed risk to compound fast.
         ExecuteTrade((type == POSITION_TYPE_BUY ? SIGNAL_BUY : SIGNAL_SELL), "Snowball Layer");
      }
   }

   // Limpeza de Objetos Gráficos
   void ClearVisuals()
   {
      ObjectDelete(0, "Talos_TP_Line");
      ObjectDelete(0, "Talos_Status");
   }

   void DrawTPLine(double tp)
   {
      string name = "Talos_TP_Line";
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, tp);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetString(0, name, OBJPROP_TEXT, "TALOS TARGET");
   }

   // Handles extras para Telemetria
   int            m_ema200_handle;
   // VWAP handle se disponível, senão calculamos manualmente

   // --- TELEMETRY SYSTEM (v3.0) ---
   void ReportStatus()
   {
      // 1. Coleta Dados Básicos
      double rsi[];
      double ema200[];
      double close[];
      
      if(CopyBuffer(m_rsi_handle, 0, 0, 1, rsi) < 1) return;
      if(CopyBuffer(m_ema200_handle, 0, 0, 1, ema200) < 1) return;
      if(CopyClose(m_symbol, m_period, 0, 1, close) < 1) return;
      
      double current_price = close[0];
      
      // 2. Calcula Variação Diária
      double open_today = iOpen(m_symbol, PERIOD_D1, 0);
      double daily_change = 0.0;
      if(open_today > 0) daily_change = ((current_price - open_today) / open_today) * 100.0;
      
      // 3. Calcula VWAP (Estimativa Simples M15 se não houver buffer)
      // Para telemetria macro, usaremos a relação Preço vs EMA200 como proxy de tendência longa
      // e Preço vs Abertura como proxy de força intraday se VWAP for complexo de extrair aqui.
      // Mas vamos tentar calcular uma VWAP simples baseada no dia.
      string vwap_status = "N/A";
      // Simplificação: Se preço > Abertura + 0.1%, consideramos zona de compra forte (simulando acima da VWAP)
      if(current_price > open_today) vwap_status = "ABOVE_OPEN";
      else vwap_status = "BELOW_OPEN";
      
      string trend_status = (current_price > ema200[0]) ? "BULLISH_MACRO" : "BEARISH_MACRO";
      
      // 4. Escreve no CSV (Sobrescreve ou Adiciona? Vamos usar um arquivo por ativo para evitar conflito de I/O)
      // Nome: telemetry_XAUUSD.txt
      string clean_symbol = m_symbol;
      StringReplace(clean_symbol, "m", "");
      
      string filename = "telemetry_" + clean_symbol + ".txt";
      
      // FIX: Adicionado FILE_SHARE_READ para permitir leitura externa enquanto escreve
      int handle = FileOpen(filename, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ); 
      
      if(handle != INVALID_HANDLE)
      {
         string data = StringFormat("PRICE:%.2f|CHANGE:%.2f|RSI:%.2f|TREND:%s|INTRA:%s|TIME:%s", 
                                    current_price, daily_change, rsi[0], trend_status, vwap_status, TimeToString(TimeCurrent()));
         FileWrite(handle, data);
         FileClose(handle);
      }
   }

public:
   CEngine() : m_symbol(_Symbol), m_period(_Period), m_last_heartbeat(0), m_rsi_handle(INVALID_HANDLE), m_atr_handle(INVALID_HANDLE), m_ema200_handle(INVALID_HANDLE), m_last_close_time(0) {}
   
   // --- TRANSACTION MONITOR (Public for EA Entry Point) ---
   void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result)
   {
      // If a position was closed (any reason), update cooldown
      if(trans.type == TRADE_TRANSACTION_HISTORY_ADD)
      {
         if(trans.symbol == m_symbol)
         {
            // Reset cooldown on any close event
            m_last_close_time = TimeCurrent();
            // Print("COOLDOWN: Position close detected. Timer reset.");
         }
      }
   }
   
   // CORREÇÃO DE MEMORY LEAK: Destrutor robusto
   ~CEngine() 
   { 
      for(int i=0; i<ArraySize(m_signals); i++) 
      {
         if(CheckPointer(m_signals[i]) == POINTER_DYNAMIC)
         {
            delete m_signals[i];
         }
      }
      ArrayFree(m_signals);
      if(m_rsi_handle != INVALID_HANDLE) IndicatorRelease(m_rsi_handle);
      if(m_atr_handle != INVALID_HANDLE) IndicatorRelease(m_atr_handle);
      if(m_ema200_handle != INVALID_HANDLE) IndicatorRelease(m_ema200_handle);
      ClearVisuals();
   }

   bool Init(const HydraSettings &settings)
   {
      m_settings = settings;
      m_trade.SetExpertMagicNumber(m_settings.magic_number);
      m_trade.SetTypeFillingBySymbol(m_symbol);
      if(!m_risk.Init(m_symbol, m_settings.risk_percent, m_settings.atr_mult, m_settings.atr_per)) return false;
      if(m_settings.use_adaptive) m_regime.Init(m_symbol, m_period, 25.0);

      // Setup Handles
      m_rsi_handle = iRSI(m_symbol, m_period, m_settings.rsi_per, PRICE_CLOSE);
      m_atr_handle = iATR(m_symbol, m_period, m_settings.atr_per);
      m_ema200_handle = iMA(m_symbol, m_period, 200, 0, MODE_EMA, PRICE_CLOSE); // Handle Telemetria

      ArrayResize(m_signals, 4); // Increased to 4
      m_signals[0] = new CSignalKAMA(m_settings.kama_per, 2, 30);
      m_signals[1] = new CSignalMeanRev(m_settings.rsi_per, 70, 30, m_settings.bb_per, 2.0, 200);
      m_signals[2] = new CSignalBreakout(0, 8);
      m_signals[3] = new CSignalWarrior(); // New Warrior Signal

      for(int i=0; i<4; i++) m_signals[i].Init(m_symbol, m_period);
      
      // VISUALS: Add Indicators to Chart
      AddIndicatorsToChart();
      
      // SAFETY CHECK ON INIT
      PrintSafetyStatus();
      
      return true;
   }

   // VISUALS: Add Indicators for Tactical HUD
   void AddIndicatorsToChart()
   {
      long chart_id = ChartID();
      int sub_window = 0; // Main Window

      // 1. KAMA Trend
      if(m_settings.use_kama || m_settings.use_adaptive)
      {
         int kama_handle = iAMA(m_symbol, m_period, 9, 2, 30, 0, PRICE_CLOSE);
         if(kama_handle != INVALID_HANDLE) ChartIndicatorAdd(chart_id, sub_window, kama_handle);
      }

      // 2. Mean Reversion (Bollinger + RSI)
      if(m_settings.use_mean_rev || m_settings.use_adaptive)
      {
         int bb_handle = iBands(m_symbol, m_period, m_settings.bb_per, 0, m_settings.bb_dev, PRICE_CLOSE);
         if(bb_handle != INVALID_HANDLE) ChartIndicatorAdd(chart_id, sub_window, bb_handle);
         
         // RSI in Subwindow 1
         int rsi_handle = iRSI(m_symbol, m_period, m_settings.rsi_per, PRICE_CLOSE);
         if(rsi_handle != INVALID_HANDLE) ChartIndicatorAdd(chart_id, 1, rsi_handle); 
      }

      // 3. Warrior Mode (EMA 9 + EMA 20 + VWAP)
      if(m_settings.use_warrior)
      {
         int ema9 = iMA(m_symbol, m_period, 9, 0, MODE_EMA, PRICE_CLOSE);
         int ema20 = iMA(m_symbol, m_period, 20, 0, MODE_EMA, PRICE_CLOSE);
         if(ema9 != INVALID_HANDLE) ChartIndicatorAdd(chart_id, sub_window, ema9);
         if(ema20 != INVALID_HANDLE) ChartIndicatorAdd(chart_id, sub_window, ema20);
      }
   }

   // Helper to show safety status on load
   void PrintSafetyStatus()
   {
      if(m_settings.disable_safety)
      {
         Print("--- OBS1DIAN SAFETY CHECK ---");
         Print("WARNING: SAFETY CIRCUIT BREAKER IS DISABLED (MANUAL OVERRIDE).");
         Print("The EA will trade even in crash conditions.");
         Print("-----------------------------");
         return;
      }

      double open_today = iOpen(m_symbol, PERIOD_D1, 0);
      double close_yest = iClose(m_symbol, PERIOD_D1, 1);
      double current = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      
      if(open_today > 0 && close_yest > 0)
      {
         double chg_today = ((current - open_today) / open_today) * 100.0;
         double chg_yest  = ((current - close_yest) / close_yest) * 100.0;
         
         string status = "NORMAL";
         double threshold = m_settings.safety_threshold > 0 ? m_settings.safety_threshold : 1.5;
         if(chg_today < -threshold || chg_yest < -threshold) status = "CRASH DETECTED (Longs Blocked)";
         if(chg_today > threshold || chg_yest > threshold)   status = "ROCKET DETECTED (Shorts Blocked)";
         
         Print("--- OBS1DIAN SAFETY CHECK ---");
         Print("Asset: ", m_symbol, " | Limit: ", threshold, "% | Chg Today: ", DoubleToString(chg_today, 2), "% | Chg Yest: ", DoubleToString(chg_yest, 2), "%");
         Print("Safety Status: ", status);
         Print("-----------------------------");
      }
   }

   // --- HEARTBEAT MONITOR ---
   void Heartbeat()
   {
      if(TimeCurrent() - m_last_heartbeat < 60) return; // Only run every 60 seconds
      m_last_heartbeat = TimeCurrent();
      
      // EXPORT TELEMETRY (Os olhos do Overseer)
      ReportStatus();

      // --- DYNAMIC OVERRIDE (v7.5 - TOTAL CONTROL) ---
      string json = CConfigProvider::ReadFile("talos_control.json");
      if(json != "")
      {
         // 1. Determine Asset Key
         string asset_key = m_symbol;
         if(StringFind(asset_key, "m") == StringLen(asset_key) - 1)
            asset_key = StringSubstr(asset_key, 0, StringLen(asset_key) - 1);
            
         // 2. Check if this asset has specific config
         string bias_cmd = CConfigProvider::ParseString(json, asset_key + "_bias");
         bool is_global = false;
         if(bias_cmd == "") 
         {
            bias_cmd = CConfigProvider::ParseString(json, "GLOBAL_bias");
            is_global = true;
         }
         
         if(bias_cmd != "")
         {
            Print("TALOS: Active configuration detected for [", m_symbol, "] (Source: ", (is_global ? "GLOBAL" : "ASSET_SPECIFIC"), "). Updating strategy...");
         }

         // 3. Bias Override
         if(bias_cmd == "LONG")  m_settings.bias = BIAS_LONG;
         if(bias_cmd == "SHORT") m_settings.bias = BIAS_SHORT;
         if(bias_cmd == "NONE")  m_settings.bias = BIAS_NONE;
         if(bias_cmd == "NEUTRAL") m_settings.bias = BIAS_NONE;
         
         // 3. Risk & Money Management Override (FULL CONTROL)
         double fixed_lot = CConfigProvider::ParseDouble(json, "fixed_lot");
         if(fixed_lot > 0) m_settings.fixed_lot = fixed_lot;
         
         double tp_mult = CConfigProvider::ParseDouble(json, "tp_multiplier");
         if(tp_mult > 0) m_settings.tp_multiplier = tp_mult;

         double risk_pct = CConfigProvider::ParseDouble(json, "risk_percent");
         if(risk_pct > 0) m_settings.risk_percent = risk_pct;

         double atr_m = CConfigProvider::ParseDouble(json, "atr_mult");
         if(atr_m > 0) m_settings.atr_mult = atr_m;

         double atr_p = CConfigProvider::ParseDouble(json, "atr_per");
         if(atr_p > 0) m_settings.atr_per = (int)atr_p;

         double cooldown = CConfigProvider::ParseDouble(json, "cooldown_seconds");
         if(cooldown >= 0) m_settings.cooldown_seconds = (int)cooldown;

         double time_exit = CConfigProvider::ParseDouble(json, "time_exit_hours");
         if(time_exit > 0) m_settings.time_exit_hours = (int)time_exit;

         // 4. STRATEGY SWITCHING (Active Regime Control)
         string strat_warrior  = CConfigProvider::ParseString(json, "strategy_warrior");
         string strat_meanrev  = CConfigProvider::ParseString(json, "strategy_mean_rev");
         string strat_breakout = CConfigProvider::ParseString(json, "strategy_breakout");
         string strat_kama     = CConfigProvider::ParseString(json, "strategy_kama");

         if(strat_warrior == "ON") m_settings.use_warrior = true;
         if(strat_warrior == "OFF") m_settings.use_warrior = false;

         if(strat_meanrev == "ON") m_settings.use_mean_rev = true;
         if(strat_meanrev == "OFF") m_settings.use_mean_rev = false;

         if(strat_breakout == "ON") m_settings.use_breakout = true;
         if(strat_breakout == "OFF") m_settings.use_breakout = false;
         
         if(strat_kama == "ON") m_settings.use_kama = true;
         if(strat_kama == "OFF") m_settings.use_kama = false;

         // 5. Switches Gerais & Segurança
         string use_sent = CConfigProvider::ParseString(json, "use_sentiment");
         if(use_sent == "ON") m_settings.use_sentiment = true;
         if(use_sent == "OFF") m_settings.use_sentiment = false;

         string dis_safe = CConfigProvider::ParseString(json, "disable_safety");
         if(dis_safe == "ON") m_settings.disable_safety = true;
         if(dis_safe == "OFF") m_settings.disable_safety = false;

         // 6. INDICADORES & ADAPTIVE (Deep Control)
         string use_adapt = CConfigProvider::ParseString(json, "use_adaptive");
         if(use_adapt == "ON") m_settings.use_adaptive = true;
         if(use_adapt == "OFF") m_settings.use_adaptive = false;

         double rsi_p = CConfigProvider::ParseDouble(json, "rsi_per");
         if(rsi_p > 0) m_settings.rsi_per = (int)rsi_p;

         double rsi_u = CConfigProvider::ParseDouble(json, "rsi_up");
         if(rsi_u > 0) m_settings.rsi_up = (int)rsi_u;

         double rsi_l = CConfigProvider::ParseDouble(json, "rsi_low");
         if(rsi_l > 0) m_settings.rsi_low = (int)rsi_l;

         double bb_p = CConfigProvider::ParseDouble(json, "bb_per");
         if(bb_p > 0) m_settings.bb_per = (int)bb_p;

         double bb_d = CConfigProvider::ParseDouble(json, "bb_dev");
         if(bb_d > 0) m_settings.bb_dev = bb_d;

         double kama_p = CConfigProvider::ParseDouble(json, "kama_per");
         if(kama_p > 0) m_settings.kama_per = (int)kama_p;

         double kama_f = CConfigProvider::ParseDouble(json, "kama_fast");
         if(kama_f > 0) m_settings.kama_fast = (int)kama_f;

         double kama_s = CConfigProvider::ParseDouble(json, "kama_slow");
         if(kama_s > 0) m_settings.kama_slow = (int)kama_s;

         // 7. GOVERNOR & PYRAMIDING
         double ent_th = CConfigProvider::ParseDouble(json, "entropy_threshold");
         if(ent_th > 0) m_settings.entropy_threshold = ent_th;

         double ent_per = CConfigProvider::ParseDouble(json, "entropy_period");
         if(ent_per > 0) m_settings.entropy_period = (int)ent_per;

         string use_h = CConfigProvider::ParseString(json, "use_hurst");
         if(use_h == "ON") m_settings.use_hurst = true;
         if(use_h == "OFF") m_settings.use_hurst = false;

         string use_pyr = CConfigProvider::ParseString(json, "use_pyramiding");
         if(use_pyr == "ON") m_settings.use_pyramiding = true;
         if(use_pyr == "OFF") m_settings.use_pyramiding = false;

         double pyr_step = CConfigProvider::ParseDouble(json, "pyramid_step_atr");
         if(pyr_step > 0) m_settings.pyramid_step_atr = pyr_step;

         double max_l = CConfigProvider::ParseDouble(json, "max_layers");
         if(max_l > 0) m_settings.max_layers = (int)max_l;
      }

      double open_today = iOpen(m_symbol, PERIOD_D1, 0);
      double current = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      if(open_today == 0) return;

      double change = ((current - open_today) / open_today) * 100.0;
      
      string bias_str = "NONE";
      if(m_settings.bias == BIAS_LONG) bias_str = "LONG";
      if(m_settings.bias == BIAS_SHORT) bias_str = "SHORT";

      string status = "Running";
      if(m_settings.disable_safety)
      {
         status = "WARNING: SAFETY DISABLED";
      }
      else
      {
         if(m_settings.bias == BIAS_LONG && change < -1.5) status = "SAFE MODE (Buying Paused)";
         if(m_settings.bias == BIAS_SHORT && change > 1.5) status = "SAFE MODE (Selling Paused)";
      }

      // Check Daily Loss status
      if(CheckDailyLossLimit()) status = "STOPPED (Daily Loss Reached)";

      Print("OBS1DIAN [", m_symbol, "] | Bias: ", bias_str, " | Daily Var: ", DoubleToString(change, 2), "% | Status: ", status);
   }

   void OnTick()
   {
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return;
      
      // Run Heartbeat
      Heartbeat();
      
      // 1. Check Daily Max Loss (Kill Switch)
      if(CheckDailyLossLimit()) return;
      
      // 2. CHECK REGIME (GOVERNOR v6.0)
      if(!CheckMarketRegime()) return; // Blocks execution if Entropy or Hurst are bad

      // 3. PYRAMIDING CHECK (Check on every tick if we should add)
      CheckPyramiding();

      // Lógica de Trailing Stop / Monitoramento
      if(m_position.Select(m_symbol)) 
      {
         // 2. NEW: Check Time Exit (Zombie Killer)
         CheckTimeExit();
         
         // 3. NEW v6.1: Check Breakeven Protection
         CheckBreakeven();
         
         UpdateTrailingStop();
         DrawTPLine(m_position.TakeProfit());
         return; // If position exists, don't look for new entry
      }
      else 
      {
         // 2. Check Cooldown (Anti-Churning)
         // Wait X seconds after last close before re-entering (Default 900s = 15min)
         if(m_settings.cooldown_seconds > 0 && TimeCurrent() - m_last_close_time < m_settings.cooldown_seconds) 
         {
            ClearVisuals();
            return;
         }
         ClearVisuals();
      }

      ENUM_MARKET_REGIME current_regime = m_settings.use_adaptive ? m_regime.GetRegime() : REGIME_UNKNOWN;

      for(int i=0; i<ArraySize(m_signals); i++)
      {
         if(m_settings.use_adaptive)
         {
            if(i == 0 && current_regime != REGIME_TRENDING) continue;
            if(i == 1 && current_regime != REGIME_RANGING) continue;
            if(i == 2) continue;
            if(i == 3) continue; // Warrior is Manual Only for now, or could be Adaptive Trend
         }
         else
         {
            if(i == 0 && !m_settings.use_kama) continue;
            if(i == 1 && !m_settings.use_mean_rev) continue;
            if(i == 2 && !m_settings.use_breakout) continue;
            if(i == 3 && !m_settings.use_warrior) continue;
         }

         ENUM_SIGNAL_TYPE sig = m_signals[i].CheckSignal();
         
         // --- SAFETY BIAS LOGIC (CIRCUIT BREAKER) ---
         // Prevent Buying into a Crash or Selling into a Rocket even if Bias is set.
         if(m_settings.bias == BIAS_LONG)
         {
            if(sig == SIGNAL_SELL) sig = SIGNAL_NONE; // Standard Bias Filter
            
            // Safety: Check if Market Crashed > 1.5% today OR from Yesterday.
            if(IsMarketCrashing(SIGNAL_BUY)) sig = SIGNAL_NONE;
         }
         
         if(m_settings.bias == BIAS_SHORT)
         {
            if(sig == SIGNAL_BUY) sig = SIGNAL_NONE; // Standard Bias Filter
            
            // Safety: Check if Market Rocketed > 1.5% today OR from Yesterday.
            if(IsMarketCrashing(SIGNAL_SELL)) sig = SIGNAL_NONE;
         }

         if(sig != SIGNAL_NONE)
         {
            // WARRIOR SPECIFIC: Log the specific signal
            string strat_name = m_signals[i].GetName();
            if(m_settings.use_adaptive) strat_name += " [Adaptive]";
            else strat_name += " [Manual]";
            
            ExecuteTrade(sig, strat_name);
            return;
         }
      }
   }

   // SAFETY: Check Daily Loss Limit (2% of Account Balance)
   bool CheckDailyLossLimit()
   {
      double daily_profit = 0;
      datetime start_day = iTime(m_symbol, PERIOD_D1, 0);
      
      if(!HistorySelect(start_day, TimeCurrent())) return false; // Fail safe
      
      int total = HistoryDealsTotal();
      
      for(int i=0; i<total; i++)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket > 0)
         {
            // Filter by Symbol and Magic Number to be precise
            if(HistoryDealGetString(ticket, DEAL_SYMBOL) == m_symbol && HistoryDealGetInteger(ticket, DEAL_MAGIC) == m_settings.magic_number)
            {
               daily_profit += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_COMMISSION) + HistoryDealGetDouble(ticket, DEAL_SWAP);
            }
         }
      }
      
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double limit = balance * -0.02; // -2% limit
      
      if(daily_profit < limit)
      {
         // Print("SAFETY: Daily Loss Limit Reached! Trading Stopped for ", m_symbol);
         return true; // Stop Trading
      }
      return false; // OK to Trade
   }

   // SAFETY: Check for Extreme Moves (Circuit Breaker)
   bool IsMarketCrashing(ENUM_SIGNAL_TYPE attempt)
   {
      // OVERRIDE: If safety is disabled, let it pass (DANGER!)
      if(m_settings.disable_safety) return false;

      double open_today = iOpen(m_symbol, PERIOD_D1, 0);
      double close_yest = iClose(m_symbol, PERIOD_D1, 1);
      double current = (attempt == SIGNAL_BUY) ? SymbolInfoDouble(m_symbol, SYMBOL_BID) : SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      
      if(open_today == 0 || close_yest == 0) return false;

      double chg_today = ((current - open_today) / open_today) * 100.0;
      double chg_yest  = ((current - close_yest) / close_yest) * 100.0;
      double threshold = m_settings.safety_threshold > 0 ? m_settings.safety_threshold : 3.0;

      // If trying to BUY, but market is down > threshold (Today or vs Yesterday) -> BLOCKED
      if(attempt == SIGNAL_BUY)
      {
         if(chg_today < -threshold || chg_yest < -threshold)
         {
            return true;
         }
      }
      
      // If trying to SELL, but market is up > threshold (Today or vs Yesterday) -> BLOCKED
      if(attempt == SIGNAL_SELL)
      {
         if(chg_today > threshold || chg_yest > threshold)
         {
            return true;
         }
      }

      return false;
   }

   // NOVO: Verificação de Exaustão (RSI)
   bool CheckExhaustionExit()
   {
      double rsi[];
      if(CopyBuffer(m_rsi_handle, 0, 0, 1, rsi) < 1) return false;
      
      if(m_position.PositionType() == POSITION_TYPE_BUY && rsi[0] >= 80) 
      {
         Print("EXHAUSTION: Closing Long. RSI: ", DoubleToString(rsi[0], 2));
         if(m_trade.PositionClose(m_position.Ticket()))
         {
            m_last_close_time = TimeCurrent(); // Reset Cooldown
            return true;
         }
      }
      
      if(m_position.PositionType() == POSITION_TYPE_SELL && rsi[0] <= 20) 
      {
         Print("EXHAUSTION: Closing Short. RSI: ", DoubleToString(rsi[0], 2));
         if(m_trade.PositionClose(m_position.Ticket()))
         {
            m_last_close_time = TimeCurrent(); // Reset Cooldown
            return true;
         }
      }
      
      return false;
   }

   // NOVO: Trailing Stop Dinâmico (ATR Based)
   void UpdateTrailingStop()
   {
      // 1. Verificamos Exaustão primeiro
      if(CheckExhaustionExit()) return;

      double price = (m_position.PositionType() == POSITION_TYPE_BUY) ? SymbolInfoDouble(m_symbol, SYMBOL_BID) : SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double entry = m_position.PriceOpen();
      double current_sl = m_position.StopLoss();
      
      double atr[];
      if(CopyBuffer(m_atr_handle, 0, 0, 1, atr) < 1) return;
      
      double atr_dist = atr[0] * m_settings.atr_mult;
      int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

      // Trailing Logic
      if(m_position.PositionType() == POSITION_TYPE_BUY)
      {
         // Trail apenas se estiver no lucro
         if(price > entry)
         {
            double new_sl = NormalizeDouble(price - atr_dist, digits);
            // Move SL apenas para cima e se a distância for significativa
            if(new_sl > current_sl + (10 * SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE)))
            {
               m_trade.PositionModify(m_position.Ticket(), new_sl, m_position.TakeProfit());
            }
         }
      }
      else // SHORT
      {
         if(price < entry)
         {
            double new_sl = NormalizeDouble(price + atr_dist, digits);
            // Move SL apenas para baixo
            if(new_sl < current_sl - (10 * SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE)) || current_sl == 0)
            {
               m_trade.PositionModify(m_position.Ticket(), new_sl, m_position.TakeProfit());
            }
         }
      }
      
      // We rely on OnTick -> ClearVisuals or PositionClose to update timer if needed.
      // But critical logic is in CheckExhaustionExit or manual interference.
   }

   void ExecuteTrade(ENUM_SIGNAL_TYPE type, string comment)
   {
      double sl_dist = m_risk.GetStopLossDistance();
      if(sl_dist == 0) return;
      
      double lots;
      if(m_settings.fixed_lot > 0.0) lots = m_settings.fixed_lot;
      else lots = m_risk.CalculateLotSize(sl_dist);

      // --- SENTIMENT INTEGRATION (v6.0) ---
      if(m_settings.use_sentiment)
      {
         double sentiment = ReadSentimentFile();
         
         // Se Sentimento > 0.5 e Sinal de Compra -> Aumenta Lote (1.2x)
         if(sentiment > 0.5 && type == SIGNAL_BUY)
         {
            lots = NormalizeDouble(lots * 1.2, 2);
            comment += " [Sentiment Boost]";
         }
         
         // Se Sentimento < -0.5 -> Bloqueia Compra
         if(sentiment < -0.5 && type == SIGNAL_BUY)
         {
            Print("SENTIMENT BLOCK: Buy Signal rejected due to negative sentiment (", DoubleToString(sentiment, 2), ")");
            return;
         }
      }
      
      double price = (type == SIGNAL_BUY) ? SymbolInfoDouble(m_symbol, SYMBOL_ASK) : SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double sl = (type == SIGNAL_BUY) ? price - sl_dist : price + sl_dist;
      
      // TP Realista: Usa o multiplicador das configurações (ex: 1.5x)
      double tp_mult = (m_settings.tp_multiplier > 0) ? m_settings.tp_multiplier : 1.8;
      double tp = (type == SIGNAL_BUY) ? price + (sl_dist * tp_mult) : price - (sl_dist * tp_mult);

      int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      if(m_trade.PositionOpen(m_symbol, (type == SIGNAL_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL), lots, NormalizeDouble(price, digits), NormalizeDouble(sl, digits), NormalizeDouble(tp, digits), comment))
      {
         uint retcode = m_trade.ResultRetcode();
         if(retcode != 10009 && retcode != 10008) // Not 'Done' or 'Placed'
         {
            Print("TRADE REJECTED: Code ", retcode, ". Anti-spam cooldown active.");
            m_last_close_time = TimeCurrent(); 
         }
      }
      else 
      {
         Print("EXECUTION FAILED: Entering anti-spam cooldown.");
         m_last_close_time = TimeCurrent();
      }
   }
};