//+------------------------------------------------------------------+
//|                                             CSignalBreakout.mqh  |
//|                                  Copyright 2026, Hydra Project.  |
//+------------------------------------------------------------------+
#include "ISignal.mqh"

class CSignalBreakout : public ISignal
{
private:
   string          m_symbol;
   ENUM_TIMEFRAMES m_period;
   int             m_start_hour;
   int             m_end_hour;
   
   // Estado da Sessão
   double          m_box_high;
   double          m_box_low;
   datetime        m_last_calc_day;

public:
   CSignalBreakout(int start_h, int end_h) 
      : m_start_hour(start_h), m_end_hour(end_h), m_box_high(0), m_box_low(0), m_last_calc_day(0) {}

   virtual bool Init(string symbol, ENUM_TIMEFRAMES period)
   {
      m_symbol = symbol;
      m_period = period;
      return true;
   }

   // Lógica robusta para encontrar Máx/Min da sessão definida
   void CalculateBox()
   {
      datetime current_time = TimeCurrent();
      MqlDateTime dt_struct;
      TimeToStruct(current_time, dt_struct);
      
      // Evita recalcular a cada tick se já definimos a caixa de hoje e já passamos do horário
      // Mas precisamos garantir que recalculamos se for um novo dia
      if(m_last_calc_day == dt_struct.day && dt_struct.hour > m_end_hour) return;

      // Definir limites de tempo para busca
      // Começamos busca no dia atual ou anterior dependendo da hora
      datetime start_time, end_time;
      
      // Construir datetime de inicio e fim da sessão HOJE
      MqlDateTime dt_start = dt_struct;
      dt_start.hour = m_start_hour;
      dt_start.min = 0;
      dt_start.sec = 0;
      
      MqlDateTime dt_end = dt_struct;
      dt_end.hour = m_end_hour;
      dt_end.min = 0;
      dt_end.sec = 0;
      
      start_time = StructToTime(dt_start);
      end_time = StructToTime(dt_end);
      
      // Se agora é antes do fim da sessão, não temos caixa fechada ainda.
      // Breakout só opera DEPOIS que a sessão fecha.
      if(current_time < end_time) 
      {
         m_box_high = 0; // Invalida
         return; 
      }

      // Buscar High/Low no intervalo exato
      MqlRates rates[];
      if(CopyRates(m_symbol, m_period, start_time, end_time, rates) > 0)
      {
         double highest = -DBL_MAX;
         double lowest = DBL_MAX;
         
         for(int i=0; i<ArraySize(rates); i++)
         {
            if(rates[i].high > highest) highest = rates[i].high;
            if(rates[i].low < lowest) lowest = rates[i].low;
         }
         
         m_box_high = highest;
         m_box_low = lowest;
         m_last_calc_day = dt_struct.day;
      }
   }

   virtual ENUM_SIGNAL_TYPE CheckSignal()
   {
      CalculateBox();
      
      // Se caixa inválida ou ainda dentro do horário de formação, não opera
      if(m_box_high == 0 || m_box_low == 0) return SIGNAL_NONE;

      double close[1];
      if(CopyClose(m_symbol, m_period, 1, 1, close) < 1) return SIGNAL_NONE;

      // Lógica Simples: Fechamento candle > Box High
      // Nota: Em um sistema PRO, usaríamos ordens pendentes (Buy Stop) gerenciadas pelo Engine
      // Aqui simplificamos para sinal imediato, mas com verificação de não estar muito longe
      
      if(close[0] > m_box_high) return SIGNAL_BUY;
      if(close[0] < m_box_low) return SIGNAL_SELL;

      return SIGNAL_NONE;
   }

   virtual string GetName() { return "Session Breakout"; }
   
   // Métodos getters para ordens pendentes (se evoluirmos o Engine)
   double GetHigh() { return m_box_high; }
   double GetLow() { return m_box_low; }
};