//+------------------------------------------------------------------+
//|                                                CScannerGUI.mqh   |
//|                                  Copyright 2026, Project Talos . |
//|                                       https://www.mql5.com       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Project Talos."
#property link      "https://www.mql5.com"

#include <Obsidian/Utils/CScanner.mqh>

#define GUI_PREFIX "HydraGUI_"
#define ROW_HEIGHT 20
#define COL_WIDTH 80
#define START_X 2
#define START_Y 25

enum ENUM_SCANNER_SORT
{
   SCAN_SORT_RVOL,
   SCAN_SORT_CHANGE,
   SCAN_SORT_PRICE
};

//+------------------------------------------------------------------+
//| Class CScannerGUI                                                |
//| Purpose: Handles Visual Dashboard for Scanner Results            |
//+------------------------------------------------------------------+
class CScannerGUI
  {
private:
   int               m_max_rows;
   color             m_bg_color;
   color             m_text_color;
   color             m_up_color;
   color             m_down_color;
   
   ENUM_SCANNER_SORT m_sort_mode;
   ScanResult        m_current_data[]; // Local copy for sorting

public:
                     CScannerGUI();
                    ~CScannerGUI();

   void              Init();
   void              Update(ScanResult &data[]);
   void              Cleanup();
   
   // Returns Symbol if row clicked, "SORT" if header clicked, or ""
   string            ProcessClick(string sparam); 

private:
   void              CreateLabel(string name, int x, int y, string text, color clr, bool bold=false, bool button=false);
   void              CreateRect(string name, int x, int y, int w, int h, color clr);
   void              SortData();
   void              RedrawRows();
   void              SetupChartMode(); // Hides candles/grids
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CScannerGUI::CScannerGUI() :
   m_max_rows(30),
   m_bg_color(clrBlack),
   m_text_color(clrWhiteSmoke),
   m_up_color(clrLimeGreen),
   m_down_color(clrRed),
   m_sort_mode(SCAN_SORT_CHANGE) 
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CScannerGUI::~CScannerGUI()
  {
   Cleanup();
  }
//+------------------------------------------------------------------+
//| Initialize Static GUI Elements                                   |
//+------------------------------------------------------------------+
void CScannerGUI::Init()
  {
   Cleanup(); // Ensure clean slate
   SetupChartMode(); // Clean the chart visuals

   // Calculate dynamic rows based on screen height
   int screen_h = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   int screen_w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   m_max_rows = (screen_h - 50) / ROW_HEIGHT;
   if(m_max_rows < 5) m_max_rows = 5; // Safety min

   // Background Panel (Full Screen)
   CreateRect(GUI_PREFIX + "BG", 0, 0, screen_w, screen_h, C'20,20,20'); 

   // Headers (Now Clickable Buttons)
   int y = 5;
   
   CreateLabel(GUI_PREFIX + "Head_Sym", START_X + 5, y, "SYMBOL", clrGold, true);
   
   // Sortable Headers
   color col_prc = (m_sort_mode == SCAN_SORT_PRICE) ? clrYellow : m_text_color;
   color col_chg = (m_sort_mode == SCAN_SORT_CHANGE) ? clrYellow : m_text_color;
   color col_vol = (m_sort_mode == SCAN_SORT_RVOL) ? clrYellow : m_text_color;

   CreateLabel(GUI_PREFIX + "Head_Prc", START_X + COL_WIDTH + 5, y, "PRICE", col_prc, true, true);
   CreateLabel(GUI_PREFIX + "Head_Chg", START_X + 2 * COL_WIDTH + 5, y, "% CHG", col_chg, true, true);
   CreateLabel(GUI_PREFIX + "Head_Vol", START_X + 3 * COL_WIDTH + 5, y, "RVOL", col_vol, true, true);
   
   // --- REFRESH BUTTON (Top Right) ---
   string btn_name = GUI_PREFIX + "Btn_Refresh";
   ObjectCreate(0, btn_name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, btn_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, btn_name, OBJPROP_XDISTANCE, screen_w - 105);
   ObjectSetInteger(0, btn_name, OBJPROP_YDISTANCE, 5);
   ObjectSetInteger(0, btn_name, OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, btn_name, OBJPROP_YSIZE, 25);
   ObjectSetString(0, btn_name, OBJPROP_TEXT, "SCAN NOW");
   ObjectSetInteger(0, btn_name, OBJPROP_BGCOLOR, clrDodgerBlue);
   ObjectSetInteger(0, btn_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, btn_name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, btn_name, OBJPROP_STATE, false);
   
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Clean Chart Visuals (App Mode)                                   |
//+------------------------------------------------------------------+
void CScannerGUI::SetupChartMode()
  {
   // Use standard property IDs (long type cast to fix ambiguity)
   long bg_color = (long)C'20,20,20';
   
   ChartSetInteger(0, CHART_SHOW_GRID, 0);
   ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, 0);
   ChartSetInteger(0, CHART_SHOW_OHLC, 0);
   ChartSetInteger(0, CHART_SHOW_BID_LINE, 0);
   ChartSetInteger(0, CHART_SHOW_ASK_LINE, 0);
   ChartSetInteger(0, CHART_SHOW_TICKER, 0);
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, bg_color); 
   ChartSetInteger(0, CHART_FOREGROUND, 0);
   ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
   
   // Hide candles by making them background color
   ChartSetInteger(0, CHART_COLOR_CHART_UP, bg_color);
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, bg_color);
   
   // FIXED TYPO HERE: CANDLE instead of CHANDLE
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, bg_color);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, bg_color);
   
   ChartSetInteger(0, CHART_COLOR_CHART_LINE, bg_color);
  }

//+------------------------------------------------------------------+
//| Update the GUI with new data                                     |
//+------------------------------------------------------------------+
void CScannerGUI::Update(ScanResult &data[])
  {
   // Copy data to local array
   int total = ArraySize(data);
   ArrayResize(m_current_data, total);
   for(int i=0; i<total; i++) m_current_data[i] = data[i];
   
   SortData();
   RedrawRows();
  }

//+------------------------------------------------------------------+
//| Sort Data locally based on m_sort_mode                           |
//+------------------------------------------------------------------+
void CScannerGUI::SortData()
  {
   int n = ArraySize(m_current_data);
   if(n < 2) return;

   // Simple Bubble Sort (Fast enough for 30-50 items)
   for(int i=0; i<n-1; i++)
     {
      for(int j=0; j<n-i-1; j++)
        {
         bool swap = false;
         switch(m_sort_mode)
           {
            case SCAN_SORT_PRICE:  swap = (m_current_data[j].price < m_current_data[j+1].price); break; 
            case SCAN_SORT_CHANGE: swap = (MathAbs(m_current_data[j].change_percent) < MathAbs(m_current_data[j+1].change_percent)); break; 
            case SCAN_SORT_RVOL:   swap = (m_current_data[j].rvol < m_current_data[j+1].rvol); break; 
           }
           
         if(swap)
           {
            ScanResult temp = m_current_data[j];
            m_current_data[j] = m_current_data[j+1];
            m_current_data[j+1] = temp;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Redraw only the rows                                             |
//+------------------------------------------------------------------+
void CScannerGUI::RedrawRows()
  {
   int count = ArraySize(m_current_data);
   
   // Re-calc rows on redraw to handle resizing
   int screen_h = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   m_max_rows = (screen_h - 50) / ROW_HEIGHT;
   if(m_max_rows < 5) m_max_rows = 5;

   for(int i = 0; i < m_max_rows; i++)
     {
      int y = START_Y + (i * ROW_HEIGHT);
      string name_sym = GUI_PREFIX + "Row_" + IntegerToString(i) + "_Sym";
      string name_prc = GUI_PREFIX + "Row_" + IntegerToString(i) + "_Prc";
      string name_chg = GUI_PREFIX + "Row_" + IntegerToString(i) + "_Chg";
      string name_vol = GUI_PREFIX + "Row_" + IntegerToString(i) + "_Vol";

      if(i < count)
        {
         color chg_color = (m_current_data[i].change_percent >= 0) ? m_up_color : m_down_color;
         string rvol_str = DoubleToString(m_current_data[i].rvol, 1) + "x";
         if(m_current_data[i].shift_used == 1) rvol_str += " (Y)"; 

         CreateLabel(name_sym, START_X + 5, y, m_current_data[i].symbol, clrWhite, false, true); 
         CreateLabel(name_prc, START_X + COL_WIDTH + 5, y, DoubleToString(m_current_data[i].price, 2), m_text_color);
         CreateLabel(name_chg, START_X + 2 * COL_WIDTH + 5, y, DoubleToString(m_current_data[i].change_percent, 1) + "%", chg_color);
         CreateLabel(name_vol, START_X + 3 * COL_WIDTH + 5, y, rvol_str, clrSkyBlue);
        }
      else
        {
         ObjectDelete(0, name_sym);
         ObjectDelete(0, name_prc);
         ObjectDelete(0, name_chg);
         ObjectDelete(0, name_vol);
        }
     }
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Process Click Event                                              |
//+------------------------------------------------------------------+
string CScannerGUI::ProcessClick(string sparam)
  {
   // 1. Check Headers (Sort)
   if(StringFind(sparam, "Head_Prc") > 0) { m_sort_mode = SCAN_SORT_PRICE; Init(); SortData(); RedrawRows(); return "SORT"; }
   if(StringFind(sparam, "Head_Chg") > 0) { m_sort_mode = SCAN_SORT_CHANGE; Init(); SortData(); RedrawRows(); return "SORT"; }
   if(StringFind(sparam, "Head_Vol") > 0) { m_sort_mode = SCAN_SORT_RVOL; Init(); SortData(); RedrawRows(); return "SORT"; }

   // 2. Check Rows (Open Chart)
   if(StringFind(sparam, GUI_PREFIX + "Row_") >= 0 && StringFind(sparam, "_Sym") > 0)
     {
      return ObjectGetString(0, sparam, OBJPROP_TEXT);
     }
   return "";
  }
//+------------------------------------------------------------------+
//| Cleanup Objects                                                  |
//+------------------------------------------------------------------+
void CScannerGUI::Cleanup()
  {
   ObjectsDeleteAll(0, GUI_PREFIX);
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//| Helper: Create Label                                             |
//+------------------------------------------------------------------+
void CScannerGUI::CreateLabel(string name, int x, int y, string text, color clr, bool bold=false, bool button=false)
  {
   if(ObjectFind(0, name) < 0)
     {
      // Create logic depending on type
      if(button)
         ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      else
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
     }
   
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9); 
   
   if(bold) ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   else ObjectSetString(0, name, OBJPROP_FONT, "Arial");

   if(button)
     {
      // Button styling to look like a label but act clickable
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'20,20,20'); 
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'40,40,40');
      ObjectSetInteger(0, name, OBJPROP_XSIZE, COL_WIDTH - 5);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, ROW_HEIGHT - 2);
      ObjectSetInteger(0, name, OBJPROP_STATE, false); 
     }
  }
//+------------------------------------------------------------------+
//| Helper: Create Rectangle                                         |
//+------------------------------------------------------------------+
void CScannerGUI::CreateRect(string name, int x, int y, int w, int h, color clr)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
  }
//+------------------------------------------------------------------+