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

public:
   CRiskManager() : m_symbol(""), m_risk_percent(1.0), m_atr_multiplier(1.5), m_atr_period(14), m_atr_handle(INVALID_HANDLE) {}
   
   bool Init(string symbol, double risk_pct, double atr_mult, int atr_per)
   {
      m_symbol = symbol;
      m_risk_percent = risk_pct;
      m_atr_multiplier = atr_mult;
      m_atr_period = atr_per;
      
      m_atr_handle = iATR(m_symbol, PERIOD_CURRENT, m_atr_period);
      return (m_atr_handle != INVALID_HANDLE);
   }

   double GetStopLossDistance()
   {
      double atr[1];
      // Pega ATR da vela fechada [1] para estabilidade
      if(CopyBuffer(m_atr_handle, 0, 1, 1, atr) < 1) return 0;
      
      double dist = atr[0] * m_atr_multiplier;
      
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
      
      // Fórmula: Lotes = Risco / (Perda por Lote)
      // Perda por Lote = (Distancia / TickSize) * TickValue
      double loss_per_lot = (sl_distance_points / tick_size) * tick_value;
      
      if(loss_per_lot == 0) return 0.0;
      
      double raw_lots = risk_money / loss_per_lot;
      
      // Normalização de Lote
      double min_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double max_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      double step_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      
      double lots = MathFloor(raw_lots / step_lot) * step_lot;
      
      if(lots < min_lot) lots = min_lot; // Ou 0 se for muito rígido
      if(lots > max_lot) lots = max_lot;
      
      return lots;
   }
};
