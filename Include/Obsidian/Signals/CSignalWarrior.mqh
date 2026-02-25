//+------------------------------------------------------------------+
//|                                               CSignalWarrior.mqh |
//|                                  Copyright 2026, Project Talos . |
//|                                       https://www.mql5.com       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Project Talos."
#property link      "https://www.mql5.com"

#include "ISignal.mqh"
#include "..\Utils\CMathLib.mqh" // v6.0 Math Core

//+------------------------------------------------------------------+
//| Class CSignalWarrior                                             |
//| Purpose: Implements Ross Cameron's Momentum Strategy             |
//| Logic: Dip Buying on EMA 9 + VWAP Trend Confirmation             |
//+------------------------------------------------------------------+
class CSignalWarrior : public ISignal
  {
private:
   int               m_handle_ema9;
   int               m_handle_ema20;
   double            m_vwap_buffer[]; // Manual VWAP calculation might be needed if no indicator
   string            m_symbol;
   ENUM_TIMEFRAMES   m_period;

public:
                     CSignalWarrior();
                    ~CSignalWarrior();

   virtual bool      Init(string symbol, ENUM_TIMEFRAMES period);
   virtual ENUM_SIGNAL_TYPE CheckSignal();
   virtual string    GetName() { return "Warrior Momentum"; }

private:
   double            GetVWAP(int shift);
   double            GetEMA(int handle, int shift);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalWarrior::CSignalWarrior() : m_handle_ema9(INVALID_HANDLE), m_handle_ema20(INVALID_HANDLE)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalWarrior::~CSignalWarrior()
  {
   if(m_handle_ema9 != INVALID_HANDLE) IndicatorRelease(m_handle_ema9);
   if(m_handle_ema20 != INVALID_HANDLE) IndicatorRelease(m_handle_ema20);
  }

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
bool CSignalWarrior::Init(string symbol, ENUM_TIMEFRAMES period)
  {
   m_symbol = symbol;
   m_period = period;
   
   // Ross Cameron uses EMA 9 and EMA 20 for trend/support
   m_handle_ema9  = iMA(m_symbol, m_period, 9, 0, MODE_EMA, PRICE_CLOSE);
   m_handle_ema20 = iMA(m_symbol, m_period, 20, 0, MODE_EMA, PRICE_CLOSE);
   
   return true;
  }

//+------------------------------------------------------------------+
//| Main Signal Logic                                                |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CSignalWarrior::CheckSignal()
  {
   // 1. Get Data
   double close = iClose(m_symbol, m_period, 1);
   double high  = iHigh(m_symbol, m_period, 1);
   double low   = iLow(m_symbol, m_period, 1);
   double open  = iOpen(m_symbol, m_period, 1);
   
   double ema9  = GetEMA(m_handle_ema9, 1);
   double ema20 = GetEMA(m_handle_ema20, 1);
   double vwap  = GetVWAP(0); 

   if(ema9 == 0 || vwap == 0) return SIGNAL_NONE;

   // 2. RVol VALIDATION (v6.1 Upgrade)
   long vol_buffer[];
   if(CopyTickVolume(m_symbol, m_period, 1, 20, vol_buffer) < 20) return SIGNAL_NONE;
   double sum_vol = 0;
   for(int i=0; i<20; i++) sum_vol += (double)vol_buffer[i];
   double avg_vol = sum_vol / 20.0;
   double current_vol = (double)iTickVolume(m_symbol, m_period, 0);
   double rvol = (avg_vol > 0) ? (current_vol / avg_vol) : 0;
   if(rvol < 1.3) return SIGNAL_NONE; 

   // 3. BULLISH SETUP (Long Only Ross Cameron)
   if(close > vwap && close > ema20)
   {
      if(CMathLib::IsBuyingClimax(m_symbol, m_period, 5.0)) return SIGNAL_NONE;
      bool near_ema9 = (MathAbs(close - ema9) / ema9 < 0.015);
      bool was_pullback = (close <= open); 
      if(near_ema9 && was_pullback) return SIGNAL_BUY;
   }

   // 4. BEARISH SETUP (Short - Death Flush)
   if(close < vwap && close < ema20)
   {
      // No Climax check for shorts here (unlimited downside potential in panic)
      bool near_ema9 = (MathAbs(close - ema9) / ema9 < 0.015);
      bool was_rally = (close >= open); // Small bounce into EMA 9
      if(near_ema9 && was_rally) return SIGNAL_SELL;
   }

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| Helper: Get EMA Value                                            |
//+------------------------------------------------------------------+
double CSignalWarrior::GetEMA(int handle, int shift)
  {
   double buf[1];
   if(CopyBuffer(handle, 0, shift, 1, buf) < 0) return 0.0;
   return buf[0];
  }

//+------------------------------------------------------------------+
//| Helper: Calculate Approximate Intraday VWAP                      |
//+------------------------------------------------------------------+
double CSignalWarrior::GetVWAP(int shift)
  {
   // Simplified Intraday VWAP calculation
   // Sum(Price * Vol) / Sum(Vol) starting from day start
   
   datetime time_start = iTime(m_symbol, PERIOD_D1, 0);
   int start_bar = iBarShift(m_symbol, m_period, time_start);
   
   if(start_bar < 0) return 0.0;
   
   double sum_pv = 0;
   double sum_vol = 0;
   
   // Loop from start of day to current bar (shift)
   // Limit lookback to prevent CPU freeze on M1
   int lookback = MathMin(start_bar, 1000); 
   
   for(int i = shift; i <= lookback; i++)
     {
      double p = iClose(m_symbol, m_period, i); // Using Close as proxy for Typ Price
      long v = iVolume(m_symbol, m_period, i);
      
      sum_pv += p * v;
      sum_vol += (double)v;
     }
     
   if(sum_vol == 0) return 0.0;
   return sum_pv / sum_vol;
  }
//+------------------------------------------------------------------+
