//+------------------------------------------------------------------+
//|                                                  CSignalKAMA.mqh |
//|                                  Copyright 2026, Hydra Project.  |
//+------------------------------------------------------------------+
#include "ISignal.mqh"

class CSignalKAMA : public ISignal
{
private:
   string          m_symbol;
   ENUM_TIMEFRAMES m_period;
   int             m_handle;
   
   // Parâmetros
   int             m_ama_period;
   int             m_fast_ema;
   int             m_slow_ema;
   
   // Filtros de Ruído (Hardcoded por enquanto para teste, depois mover para Inputs)
   double          m_min_slope_points; 

public:
   CSignalKAMA(int ama_p, int fast_p, int slow_p) 
      : m_ama_period(ama_p), m_fast_ema(fast_p), m_slow_ema(slow_p), m_handle(INVALID_HANDLE) 
   {
      m_min_slope_points = 10; // Reduzido de 50 para 10 (1 pip no Ouro) para maior sensibilidade
   }

   virtual bool Init(string symbol, ENUM_TIMEFRAMES period)
   {
      m_symbol = symbol;
      m_period = period;
      m_handle = iAMA(m_symbol, m_period, m_ama_period, m_fast_ema, m_slow_ema, 0, PRICE_CLOSE);
      return (m_handle != INVALID_HANDLE);
   }

   virtual ENUM_SIGNAL_TYPE CheckSignal()
   {
      // [0]=Atual, [1]=Anterior, [2]=Antes do Anterior
      double buffer[3]; 
      if(CopyBuffer(m_handle, 0, 1, 3, buffer) < 3) return SIGNAL_NONE;

      double close[1];
      if(CopyClose(m_symbol, m_period, 1, 1, close) < 1) return SIGNAL_NONE;
      
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

      // Filtro de Inclinação (Slope)
      // KAMA atual (buffer[2] que é candle 1) vs KAMA passada (buffer[0] que é candle 3)
      double slope = MathAbs(buffer[2] - buffer[0]);
      
      // Se a KAMA está "reta" (variação menor que X pontos), o mercado está lateral.
      if(slope < m_min_slope_points * point) return SIGNAL_NONE;

      // Lógica de Cruzamento/Posição
      if(close[0] > buffer[2]) // Preço acima da KAMA
      {
         // Só compra se a KAMA estiver subindo
         if(buffer[2] > buffer[1]) return SIGNAL_BUY;
      }
      
      if(close[0] < buffer[2]) // Preço abaixo da KAMA
      {
         // Só vende se a KAMA estiver caindo
         if(buffer[2] < buffer[1]) return SIGNAL_SELL;
      }

      return SIGNAL_NONE;
   }

   virtual string GetName() { return "KAMA Trend (Filtered)"; }
};
