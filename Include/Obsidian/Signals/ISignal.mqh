//+------------------------------------------------------------------+
//|                                                      ISignal.mqh |
//|                                  Copyright 2026, Hydra Project.  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hydra Project."
#property link      ""
#property strict

enum ENUM_SIGNAL_TYPE
{
   SIGNAL_BUY,
   SIGNAL_SELL,
   SIGNAL_NONE
};

class ISignal
{
public:
   virtual bool            Init(string symbol, ENUM_TIMEFRAMES period) = 0;
   virtual ENUM_SIGNAL_TYPE CheckSignal() = 0;
   virtual string          GetName() = 0;
};
