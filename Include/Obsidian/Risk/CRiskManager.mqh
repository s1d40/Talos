//+------------------------------------------------------------------+
//|                                                 CRiskManager.mqh |
//|                                  Copyright 2026, Hydra Project.  |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
   string m_symbol;
   double m_risk_percent;
   double m_atr_multiplier;
   int    m_atr_handle;
   int    m_atr_period;
   double m_max_sl_points; // Segurança: Máximo de pontos permitidos para um SL

public:
   CRiskManager() : m_symbol(""), m_risk_percent(1.0), m_atr_multiplier(1.5), m_atr_period(14), m_atr_handle(INVALID_HANDLE), m_max_sl_points(2000) {}
   
   bool Init(string symbol, double risk_pct, double atr_mult, int atr_per)
   {
      m_symbol = symbol;
      m_risk_percent = risk_pct;
      m_atr_multiplier = atr_mult;
      m_atr_period = atr_per;
      
      // Ajuste automático de Max SL baseado no ativo
      if(StringFind(m_symbol, "BTC") >= 0) m_max_sl_points = 50000; // BTC precisa de mais espaço
      else if(StringFind(m_symbol, "XAU") >= 0) m_max_sl_points = 3000; // Ouro: 30 pips max
      else m_max_sl_points = 500; // Forex: 50 pips max
      
      m_atr_handle = iATR(m_symbol, PERIOD_CURRENT, m_atr_period);
      return (m_atr_handle != INVALID_HANDLE);
   }

   double GetStopLossDistance()
   {
      double atr[1];
      if(CopyBuffer(m_atr_handle, 0, 1, 1, atr) < 1) return 0;
      
      double dist = atr[0] * m_atr_multiplier;
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      
      // Travamento de Segurança: Stop Loss não pode ser maior que o teto definido
      if(dist > m_max_sl_points * point)
      {
         // Print("RISK: ATR Distance (", dist/point, ") exceeds Max SL (", m_max_sl_points, "). Capping.");
         dist = m_max_sl_points * point;
      }
      
      // Normaliza para o Step do preço
      double tick_size = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      if(tick_size > 0) dist = MathRound(dist / tick_size) * tick_size;
      
      return dist;
   }

   double CalculateLotSize(double sl_distance_points)
   {
      if(sl_distance_points <= 0) return 0.0;
      
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double risk_money = balance * (m_risk_percent / 100.0);
      
      double tick_value = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      double tick_size = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      
      if(tick_value == 0 || tick_size == 0) return 0.0;
      
      double loss_per_lot = (sl_distance_points / tick_size) * tick_value;
      if(loss_per_lot == 0) return 0.0;
      
      double raw_lots = risk_money / loss_per_lot;
      
      // Normalização de Lote
      double min_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double max_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      double step_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      
      double lots = MathFloor(raw_lots / step_lot) * step_lot;
      
      // CRÍTICO: Se o capital de risco for insuficiente para o lote mínimo, REJEITA O TRADE.
      // Isso impede que o robô opere com 10x mais risco por causa do arredondamento para o lote mínimo.
      if(lots < min_lot) 
      {
         Print("RISK: Account too small for this volatility. Required lot: ", DoubleToString(raw_lots, 3), " | Min Lot: ", min_lot);
         return 0.0; 
      }
      
      if(lots > max_lot) lots = max_lot;
      
      return lots;
   }
};
