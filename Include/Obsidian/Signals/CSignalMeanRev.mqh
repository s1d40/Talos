//+------------------------------------------------------------------+
//|                                               CSignalMeanRev.mqh |
//|                                  Copyright 2026, Hydra Project.  |
//+------------------------------------------------------------------+
#include "ISignal.mqh"

class CSignalMeanRev : public ISignal
{
private:
   string          m_symbol;
   ENUM_TIMEFRAMES m_period;
   int             m_rsi_handle;
   int             m_bands_handle;
   int             m_ema_filter_handle;
   
   int             m_rsi_period;
   int             m_rsi_upper;
   int             m_rsi_lower;
   int             m_bands_period;
   double          m_bands_dev;
   int             m_filter_ema_period;

public:
   CSignalMeanRev(int rsi_p, int rsi_up, int rsi_low, int bb_p, double bb_dev, int ema_filter_p)
      : m_rsi_period(rsi_p), m_rsi_upper(rsi_up), m_rsi_lower(rsi_low), 
        m_bands_period(bb_p), m_bands_dev(bb_dev), m_filter_ema_period(ema_filter_p) {}

   virtual bool Init(string symbol, ENUM_TIMEFRAMES period)
   {
      m_symbol = symbol;
      m_period = period;
      m_rsi_handle = iRSI(m_symbol, m_period, m_rsi_period, PRICE_CLOSE);
      m_bands_handle = iBands(m_symbol, m_period, m_bands_period, 0, m_bands_dev, PRICE_CLOSE);
      m_ema_filter_handle = iMA(m_symbol, m_period, m_filter_ema_period, 0, MODE_EMA, PRICE_CLOSE);
      
      if(m_rsi_handle == INVALID_HANDLE || m_bands_handle == INVALID_HANDLE || m_ema_filter_handle == INVALID_HANDLE)
      {
         Print("Erro ao criar handles do MeanReversion");
         return false;
      }
      return true;
   }

   virtual ENUM_SIGNAL_TYPE CheckSignal()
   {
      double rsi[1], upper[1], lower[1], ema[1], close[1], open[1], low[1], high[1];
      
      // Índice 1 = Vela Fechada
      if(CopyBuffer(m_rsi_handle, 0, 1, 1, rsi) < 1) return SIGNAL_NONE;
      if(CopyBuffer(m_bands_handle, 1, 1, 1, upper) < 1) return SIGNAL_NONE; 
      if(CopyBuffer(m_bands_handle, 2, 1, 1, lower) < 1) return SIGNAL_NONE; 
      if(CopyBuffer(m_ema_filter_handle, 0, 1, 1, ema) < 1) return SIGNAL_NONE;
      if(CopyClose(m_symbol, m_period, 1, 1, close) < 1) return SIGNAL_NONE;
      if(CopyOpen(m_symbol, m_period, 1, 1, open) < 1) return SIGNAL_NONE;
      if(CopyLow(m_symbol, m_period, 1, 1, low) < 1) return SIGNAL_NONE;
      if(CopyHigh(m_symbol, m_period, 1, 1, high) < 1) return SIGNAL_NONE;

      // --- FALLING KNIFE PROTECTION (v6.1) ---
      bool is_falling_knife = false;
      double body = open[0] - close[0];
      double lower_wick = close[0] - low[0];
      
      // Se o corpo é grande e a sombra inferior é pequena (< 20% do corpo), é faca caindo
      if(body > 0 && lower_wick < (body * 0.2)) is_falling_knife = true;

      // Compra: Preço < Banda Inferior E RSI < 30 E Preço > EMA Macro (Pullback na alta)
      if(close[0] < lower[0] && rsi[0] < m_rsi_lower && close[0] > ema[0]) 
      {
         if(is_falling_knife) 
         {
            // Print("MEAN_REV: Buy Blocked (Falling Knife Detected)");
            return SIGNAL_NONE;
         }
         return SIGNAL_BUY;
      }
      
      // Venda: Preço > Banda Superior E RSI > 70 E Preço < EMA Macro (Pullback na baixa)
      if(close[0] > upper[0] && rsi[0] > m_rsi_upper && close[0] < ema[0]) return SIGNAL_SELL;

      return SIGNAL_NONE;
   }

   virtual string GetName() { return "Mean Reversion"; }
};