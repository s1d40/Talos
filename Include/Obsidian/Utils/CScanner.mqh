//+------------------------------------------------------------------+
//|                                                     CScanner.mqh |
//|                                  Copyright 2026, Project Talos . |
//|                                       https://www.mql5.com       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Project Talos."
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Data Structure for Scan Results                                  |
//+------------------------------------------------------------------+
struct ScanResult
  {
   string            symbol;
   double            price;
   double            change_percent;
   double            rvol;
   int               shift_used; // 0=Today, 1=Yesterday
  };

//+------------------------------------------------------------------+
//| Class CScanner                                                   |
//| Purpose: Scans Market Watch for High Momentum Stocks/Assets      |
//| Based on Warrior Trading 'Small Account' criteria:               |
//| 1. High Relative Volume (RVol)                                   |
//| 2. Strong % Change (Gap Up)                                      |
//| 3. Specific Price Range                                          |
//+------------------------------------------------------------------+
class CScanner
  {
private:
   double            m_min_price;
   double            m_max_price;
   double            m_min_change_percent;
   double            m_min_rvol;
   double            m_impact_mult;    // NEW: Multiplier for "Huge Move" override
   int               m_avg_vol_period; // Period to calculate Avg Volume (e.g. 30 days)
   bool              m_debug;          // Debug mode flag

public:
                     CScanner();
                    ~CScanner();

   //--- Configuration
   void              SetPriceRange(double min, double max) { m_min_price = min; m_max_price = max; }
   void              SetMinChange(double percent)          { m_min_change_percent = percent; }
   void              SetMinRVol(double rvol)               { m_min_rvol = rvol; }
   void              SetImpactMultiplier(double mult)      { m_impact_mult = mult; } // NEW
   void              SetAvgVolumePeriod(int period)        { m_avg_vol_period = period; } // NEW
   void              SetDebugMode(bool debug)              { m_debug = debug; }

   //--- Core Functionality
   int               ScanMarket(ScanResult &results[]); // Returns count of matches and fills struct array
   
private:
   double            GetRelativeVolume(string symbol, int &shift_used);
   double            GetChangePercent(string symbol, int shift);
   double            GetAvgVolume(string symbol);
   void              ExportToJSON(ScanResult &results[]); // NEW: Export Data
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CScanner::CScanner() :
   m_min_price(1.00),
   m_max_price(20.00),
   m_min_change_percent(5.0),
   m_min_rvol(2.0),
   m_impact_mult(3.0),
   m_avg_vol_period(30),
   m_debug(false)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CScanner::~CScanner()
  {
  }
//+------------------------------------------------------------------+
//| Scan the 'Market Watch' list for candidates                      |
//+------------------------------------------------------------------+
int CScanner::ScanMarket(ScanResult &results[])
  {
   ArrayFree(results);
   int matches = 0;
   int total_symbols = SymbolsTotal(true); 

   if(m_debug) Print("--- DEBUG SCAN STARTED: ", total_symbols, " symbols in Market Watch ---");

   for(int i = 0; i < total_symbols; i++)
     {
      string symbol = SymbolName(i, true);
      
      // 1. Price Filter
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      if(bid < m_min_price || bid > m_max_price) 
        {
         continue;
        }

      // Determine which day to look at (Today or Yesterday if Today just started)
      int shift_used = 0;
      double rvol = GetRelativeVolume(symbol, shift_used); // Pass by reference to know which day was used
      
      // 3. Change % Filter (Calculated before Volume filter for Override Logic)
      double change = GetChangePercent(symbol, shift_used);
      
      // LOGIC: Impact Override
      // If the move is HUGE (e.g., > N * min requirement), ignore the Volume Filter.
      bool is_huge_move = (MathAbs(change) >= (m_min_change_percent * m_impact_mult));

      // 2. Relative Volume Filter (with Override)
      if(!is_huge_move && rvol < m_min_rvol) 
        {
         continue;
        }

      // 3. Change % Filter Check
      if(MathAbs(change) < m_min_change_percent) 
        {
         continue; 
        }

      // Match Found!
      matches++;
      ArrayResize(results, matches);
      
      // Fill Struct
      results[matches - 1].symbol = symbol;
      results[matches - 1].price = bid;
      results[matches - 1].change_percent = change;
      results[matches - 1].rvol = rvol;
      results[matches - 1].shift_used = shift_used;
     }
     
   // Sort results by RVol (Highest Volume first) - Simple Bubble Sort for small list
   int n = ArraySize(results);
   for(int i=0; i<n-1; i++)
     {
      for(int j=0; j<n-i-1; j++)
        {
         if(results[j].rvol < results[j+1].rvol)
           {
            ScanResult temp = results[j];
            results[j] = results[j+1];
            results[j+1] = temp;
           }
        }
     }
     
   // EXPORT DATA FOR OVERSEER
   if(matches > 0) ExportToJSON(results);
     
   return matches;
  }

//+------------------------------------------------------------------+
//| Export Scan Results to JSON for Python Overseer                  |
//+------------------------------------------------------------------+
void CScanner::ExportToJSON(ScanResult &results[])
  {
   int handle = FileOpen("black_mirror_targets.json", FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE) return;
   
   string json = "{";
   int count = ArraySize(results);
   
   for(int i=0; i<count; i++)
     {
      string key = "\"" + results[i].symbol + "\":";
      string body = StringFormat("{\"price\":%.2f,\"change\":%.2f,\"rvol\":%.2f}", 
                                 results[i].price, results[i].change_percent, results[i].rvol);
      
      json += key + body;
      if(i < count - 1) json += ",";
     }
   
   json += "}";
   
   FileWrite(handle, json);
   FileClose(handle);
   
   if(m_debug) Print("Black Mirror Targets exported to JSON.");
  }

//+------------------------------------------------------------------+
//| Calculate Percentage Change from Previous Close                  |
//+------------------------------------------------------------------+
double CScanner::GetChangePercent(string symbol, int shift)
  {
   // If shift is 0 (Today), compare D1[0] close (current price) with D1[1] close.
   // If shift is 1 (Yesterday), compare D1[1] close with D1[2] close.
   
   double current_price;
   double prev_close;

   if(shift == 0)
     {
      current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
      prev_close = iClose(symbol, PERIOD_D1, 1);
     }
   else
     {
      current_price = iClose(symbol, PERIOD_D1, 1); // Close of yesterday
      prev_close = iClose(symbol, PERIOD_D1, 2);    // Close of day before yesterday
     }
   
   if(prev_close == 0) return 0.0;
   
   return ((current_price - prev_close) / prev_close) * 100.0;
  }
//+------------------------------------------------------------------+
//| Calculate Relative Volume (Smart Shift)                          |
//+------------------------------------------------------------------+
double CScanner::GetRelativeVolume(string symbol, int &shift_used)
  {
   double avg_vol = GetAvgVolume(symbol);
   if(avg_vol <= 0) return 0.0;
   
   long vol_today = iVolume(symbol, PERIOD_D1, 0);
   double rvol_today = (double)vol_today / avg_vol;

   // SMART LOGIC:
   // If today's RVol is tiny (< 0.1) it means the day likely just started.
   // In this case, let's check Yesterday's full stats to show "Recap" data.
   if(rvol_today < 0.1)
     {
      long vol_yest = iVolume(symbol, PERIOD_D1, 1);
      double rvol_yest = (double)vol_yest / avg_vol;
      shift_used = 1; // Tell caller we used yesterday
      return rvol_yest;
     }

   shift_used = 0;
   return rvol_today;
  }
//+------------------------------------------------------------------+
//| Calculate Average Volume over N days                             |
//+------------------------------------------------------------------+
double CScanner::GetAvgVolume(string symbol)
  {
   long sum_vol = 0;
   int bars = iBars(symbol, PERIOD_D1);
   
   if(bars < m_avg_vol_period + 1) return 0.0; // Not enough data
   
   // Loop from index 1 (yesterday) to m_avg_vol_period
   for(int i = 1; i <= m_avg_vol_period; i++)
     {
      sum_vol += iVolume(symbol, PERIOD_D1, i);
     }
     
   return (double)sum_vol / m_avg_vol_period;
  }
//+------------------------------------------------------------------+
