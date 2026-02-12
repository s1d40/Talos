//+------------------------------------------------------------------+
//|                                                CRegimeFilter.mqh |
//|                                  Copyright 2026, Hydra Project.  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

enum ENUM_MARKET_REGIME
{
   REGIME_TRENDING,
   REGIME_RANGING,
   REGIME_UNKNOWN
};

class CRegimeFilter
{
private:
   int    m_adx_handle;
   double m_threshold;
   string m_symbol;
   ENUM_TIMEFRAMES m_period;

public:
   CRegimeFilter() : m_adx_handle(INVALID_HANDLE), m_threshold(25.0) {}
   
   bool Init(string symbol, ENUM_TIMEFRAMES period, double threshold = 25.0)
   {
      m_symbol = symbol;
      m_period = period;
      m_threshold = threshold;
      m_adx_handle = iADX(m_symbol, m_period, 14);
      return (m_adx_handle != INVALID_HANDLE);
   }

   ENUM_MARKET_REGIME GetRegime()
   {
      if(m_adx_handle == INVALID_HANDLE) return REGIME_UNKNOWN;
      
      double buffer[1];
      // Lê o buffer 0 (linha principal do ADX) do candle fechado [1]
      if(CopyBuffer(m_adx_handle, 0, 1, 1, buffer) < 1) return REGIME_UNKNOWN;
      
      if(buffer[0] >= m_threshold)
         return REGIME_TRENDING;
      else
         return REGIME_RANGING;
   }
};
