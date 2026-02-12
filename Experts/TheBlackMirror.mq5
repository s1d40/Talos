//+------------------------------------------------------------------+
//|                                                 TheBlackMirror.mq5 |
//|                                  Copyright 2026, Project Talos . |
//|                                       https://www.mql5.com       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Project Talos."
#property link      "https://www.mql5.com"
#property version   "3.10" // Added Adjustable Inputs

#include <Obsidian/Utils/CScanner.mqh>
#include <Obsidian/Utils/CScannerGUI.mqh>

//--- Input Parameters
input group "Scanner Settings"
input double InpMinPrice      = 0.10;     // Min Price ($)
input double InpMaxPrice      = 100000.0; // Max Price ($)
input double InpMinChange     = 2.0;      // Min Change % 
input double InpMinRVol       = 1.5;      // Min Relative Volume 
input double InpImpactMult    = 3.0;      // Impact Override Multiplier (Ignore Vol if Move > X * MinChange)
input int    InpVolPeriod     = 30;       // Avg Volume Period (Days)

input group "System Settings"
input int    InpScanInterval  = 60;       // Scan Interval (seconds)
input bool   InpDebugMode     = true;     // Debug Mode (Print logs)

//--- Global Objects
CScanner     *scanner;
CScannerGUI  *gui;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- Initialize Scanner
   scanner = new CScanner();
   scanner.SetPriceRange(InpMinPrice, InpMaxPrice);
   scanner.SetMinChange(InpMinChange);
   scanner.SetMinRVol(InpMinRVol);
   scanner.SetImpactMultiplier(InpImpactMult); // Pass Impact Multiplier
   scanner.SetAvgVolumePeriod(InpVolPeriod);   // Pass Volume Period
   scanner.SetDebugMode(InpDebugMode);

   //--- Initialize GUI
   gui = new CScannerGUI();
   gui.Init();

   //--- Set Timer
   EventSetTimer(InpScanInterval);
   
   Print("The Black Mirror V3.1 (App Mode) Initialized.");
   
   //--- Initial Scan
   RunScan();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(CheckPointer(gui) == POINTER_DYNAMIC)
      delete gui;
   if(CheckPointer(scanner) == POINTER_DYNAMIC)
      delete scanner;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  }
//+------------------------------------------------------------------+
//| Chart Event Handler (Clicks)                                     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      // --- Manual Refresh Button ---
      if(sparam == "HydraGUI_Btn_Refresh")
      {
         Print("MANUAL SCAN: User requested update.");
         RunScan();
         
         // Visual feedback: reset button state
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         ChartRedraw();
         return;
      }

      string clicked_action = gui.ProcessClick(sparam);
      
      if(clicked_action == "SORT")
      {
         Print("Re-sorting data...");
         ChartRedraw();
      }
      else if(clicked_action != "")
      {
         Print("User clicked: ", clicked_action, ". Opening Chart...");
         long chart_id = ChartOpen(clicked_action, PERIOD_M5); // Open M5 chart for day trading
         if(chart_id > 0)
            Print("Chart Opened successfully.");
         else
            Print("Failed to open chart. Error: ", GetLastError());
            
         // Reset button state (visual only)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         ChartRedraw();
      }
     }
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   RunScan();
  }
//+------------------------------------------------------------------+
//| Helper: Run the Scan and Update GUI                              |
//+------------------------------------------------------------------+
void RunScan()
  {
   ScanResult results[]; // Use Struct Array
   int count = scanner.ScanMarket(results);
   
   // Update GUI with Results
   gui.Update(results);
   
   // Log Matches to Experts Tab (for Copy/Paste)
   if(count > 0)
     {
      Print("--- THE BLACK MIRROR MATCHES: ", count, " ---");
      for(int i = 0; i < count; i++)
        {
         string period = (results[i].shift_used == 0) ? "TODAY" : "YESTERDAY";
         string log_msg = StringFormat("%s | Price: %.2f | Chg: %.2f%% | RVol: %.2fx | %s",
                                       results[i].symbol,
                                       results[i].price,
                                       results[i].change_percent,
                                       results[i].rvol,
                                       period);
         Print(log_msg);
        }
      Print("---------------------------------------------");
     }
  }
//+------------------------------------------------------------------+