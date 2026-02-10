//+------------------------------------------------------------------+
//|                                            ManualTradeLogger.mq5 |
//|                                  Copyright 2026, AntiGravity AI  |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, AntiGravity AI"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//--- Enums
enum E_STATE {
   STATE_WAITING_OPEN,
   STATE_WAITING_CONFIRM,
   STATE_WAITING_CLOSE
};

//+------------------------------------------------------------------+
//| SManualPosition Struct                                           |
//+------------------------------------------------------------------+
struct SManualPosition {
   datetime          m_openTime;
   double            m_openPrice;
   ENUM_POSITION_TYPE m_type;      
   
   datetime          m_closeTime;
   double            m_closePrice;
   
   string            m_uid;        
   string            m_objArrowOpen;
   string            m_objArrowClose;
   string            m_objTrendLine;
   string            m_objTextParams;

   void Init() {
      m_openTime = 0;
      m_closeTime = 0;
      m_openPrice = 0.0;
      m_closePrice = 0.0;
      m_uid = IntegerToString(GetTickCount()) + "_" + IntegerToString(MathRand());
   }

   void Release() {
      ObjectDelete(0, m_objArrowOpen);
      ObjectDelete(0, m_objArrowClose);
      ObjectDelete(0, m_objTrendLine);
      ObjectDelete(0, m_objTextParams);
   }

   void DrawOpen() {
      m_objArrowOpen = "MTL_Open_" + m_uid;
      ENUM_OBJECT type = OBJ_ARROW_UP;
      color arrowColor = clrBlue;
      
      if(m_type == POSITION_TYPE_SELL) {
         type = OBJ_ARROW_DOWN;
         arrowColor = clrRed;
      }
      
      if(ObjectCreate(0, m_objArrowOpen, type, 0, m_openTime, m_openPrice)) {
         ObjectSetInteger(0, m_objArrowOpen, OBJPROP_COLOR, arrowColor);
         ObjectSetInteger(0, m_objArrowOpen, OBJPROP_WIDTH, 3);
         ObjectSetInteger(0, m_objArrowOpen, OBJPROP_SELECTABLE, true);
         ObjectSetInteger(0, m_objArrowOpen, OBJPROP_HIDDEN, false);
         ObjectSetString(0, m_objArrowOpen, OBJPROP_TOOLTIP, "Click to Delete Position");
         
         // Adjust Anchor so tip touches the price
         if(type == OBJ_ARROW_UP) ObjectSetInteger(0, m_objArrowOpen, OBJPROP_ANCHOR, ANCHOR_TOP);
         else ObjectSetInteger(0, m_objArrowOpen, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      }
   }

   void DrawClose() {
      m_objArrowClose = "MTL_Close_" + m_uid;
      m_objTrendLine  = "MTL_Line_" + m_uid;
      m_objTextParams = "MTL_Text_" + m_uid;
      
      ENUM_OBJECT arrowType = (m_type == POSITION_TYPE_BUY) ? OBJ_ARROW_DOWN : OBJ_ARROW_UP; 
      color closeColor = (m_type == POSITION_TYPE_BUY) ? clrRed : clrBlue; 
      
      if(ObjectCreate(0, m_objArrowClose, arrowType, 0, m_closeTime, m_closePrice)) {
         ObjectSetInteger(0, m_objArrowClose, OBJPROP_COLOR, closeColor);
         ObjectSetInteger(0, m_objArrowClose, OBJPROP_WIDTH, 3);
         ObjectSetInteger(0, m_objArrowClose, OBJPROP_SELECTABLE, true);
         ObjectSetInteger(0, m_objArrowClose, OBJPROP_HIDDEN, false);
         
         // Adjust Anchor so tip touches the price
         if(arrowType == OBJ_ARROW_UP) ObjectSetInteger(0, m_objArrowClose, OBJPROP_ANCHOR, ANCHOR_TOP);
         else ObjectSetInteger(0, m_objArrowClose, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      }

      if(ObjectCreate(0, m_objTrendLine, OBJ_TREND, 0, m_openTime, m_openPrice, m_closeTime, m_closePrice)) {
         ObjectSetInteger(0, m_objTrendLine, OBJPROP_COLOR, clrGray);
         ObjectSetInteger(0, m_objTrendLine, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, m_objTrendLine, OBJPROP_RAY_RIGHT, false); 
         ObjectSetInteger(0, m_objTrendLine, OBJPROP_SELECTABLE, true);
      }

      CalculateAndDrawText();
   }
   
   void CalculateAndDrawText() {
      double profitPoints = 0.0;
      if(m_type == POSITION_TYPE_BUY) 
         profitPoints = (m_closePrice - m_openPrice) / _Point;
      else 
         profitPoints = (m_openPrice - m_closePrice) / _Point;
      
      int startIdx = iBarShift(_Symbol, _Period, m_openTime);
      int endIdx = iBarShift(_Symbol, _Period, m_closeTime);
      int bars = MathAbs(startIdx - endIdx);
      
      string text = StringFormat("P: %.0f pts\nB: %d", profitPoints, bars);
      
      datetime midTime = m_openTime + (m_closeTime - m_openTime) / 2;
      double midPrice = (m_openPrice + m_closePrice) / 2.0;

      if(ObjectCreate(0, m_objTextParams, OBJ_TEXT, 0, midTime, midPrice)) {
         ObjectSetString(0, m_objTextParams, OBJPROP_TEXT, text);
         ObjectSetInteger(0, m_objTextParams, OBJPROP_COLOR, clrBlack); 
         ObjectSetInteger(0, m_objTextParams, OBJPROP_ANCHOR, ANCHOR_CENTER);
         ObjectSetInteger(0, m_objTextParams, OBJPROP_FONTSIZE, 9);
      }
   }
   
   bool IsMyObject(string objName) {
      if(objName == m_objArrowOpen || objName == m_objArrowClose || 
         objName == m_objTrendLine || objName == m_objTextParams) {
         return true;   
      }
      return false;
   }
};

//--- Global Variables
SManualPosition g_positions[];       
SManualPosition g_currentPosition; 
bool g_isWriting = false;

uint g_lastActionTick = 0; // Debounce timer

// Drag Detection Globals
int g_mouseDownX = 0;
int g_mouseDownY = 0;
bool g_isMouseLeftDown = false;

E_STATE  g_state = STATE_WAITING_OPEN;

//--- Helper functions for array
void AddPosition(SManualPosition &pos) {
   int size = ArraySize(g_positions);
   ArrayResize(g_positions, size + 1);
   g_positions[size] = pos;
}

void RemovePosition(int index) {
   int size = ArraySize(g_positions);
   if(index < 0 || index >= size) return;
   
   g_positions[index].Release(); // Delete visual objects
   
   // Shift remaining
   for(int i = index; i < size - 1; i++) {
      g_positions[i] = g_positions[i+1];
   }
   ArrayResize(g_positions, size - 1);
}

void ClearAllPositions() {
   for(int i=0; i<ArraySize(g_positions); i++) {
      g_positions[i].Release();
   }
   ArrayResize(g_positions, 0);
   ObjectDelete(0, "MTL_BTN_BUY");
   ObjectDelete(0, "MTL_BTN_SELL");
   ObjectDelete(0, "MTL_BTN_CANCEL");
}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   ArrayResize(g_positions, 0);
   g_isWriting = false;
   g_state = STATE_WAITING_OPEN;
   
   Print("ManualTradeLogger Started. Click on chart to simulate trades.");
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 1); // Enable Mouse Move events for Drag detection
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(ArraySize(g_positions) > 0) {
      SaveToFile();
   }
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 0); // Disable Mouse Move events
   
   ClearAllPositions(); 
   // Clear pending if any
   if(g_state == STATE_WAITING_CONFIRM) {
       RemoveButtons();
   }
   if(g_isWriting) {
      g_currentPosition.Release();
   }
   
   Print("ManualTradeLogger Stopped.");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   return(rates_total);
}

//+------------------------------------------------------------------+
//| UI Helper Functions                                              |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, color bgColor) {
   if(ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0)) {
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, 60);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, 30);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrNONE);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true); // Important for clicks
   }
}

void RemoveButtons() {
   ObjectDelete(0, "MTL_BTN_BUY");
   ObjectDelete(0, "MTL_BTN_SELL");
   ObjectDelete(0, "MTL_BTN_CANCEL");
}

//+------------------------------------------------------------------+
//| Logic Functions                                                  |
//+------------------------------------------------------------------+
void PrepareEntry(datetime time, double price, int x, int y) {
   g_currentPosition.Init();
   g_currentPosition.m_openTime = time;
   g_currentPosition.m_openPrice = price;
   
   // Create Buttons at Click Position (Offset slightly)
   // Note: x, y are pixel coordinates from top-left
   CreateButton("MTL_BTN_BUY", "Buy", x + 10, y, clrBlue);
   CreateButton("MTL_BTN_SELL", "Sell", x + 80, y, clrRed);
   CreateButton("MTL_BTN_CANCEL", "Cancel", x + 10, y + 35, clrGray);
   
   g_state = STATE_WAITING_CONFIRM;
   Print("Waiting for user confirmation (Buy/Sell)...");
}

void ConfirmEntry(ENUM_POSITION_TYPE type) {
   g_currentPosition.m_type = type;
   g_currentPosition.DrawOpen();
   
   RemoveButtons();
   
   g_isWriting = true;
   g_state = STATE_WAITING_CLOSE;
   g_lastActionTick = GetTickCount(); // Set timer to ignore immediate chart clicks
   
   Print("Position Confirmed. OpenTime: ", TimeToString(g_currentPosition.m_openTime), ", Type: ", EnumToString(type));
}

void CancelEntry() {
   RemoveButtons();
   // Do NOT call Release() here. Objects haven't been created for this pending entry yet.
   // Calling it would delete the PREVIOUS position's objects because g_currentPosition is reused.
   
   g_state = STATE_WAITING_OPEN;
   g_lastActionTick = GetTickCount(); // Debounce to prevent immediate re-opening
   Print("Entry Canceled by User.");
}

void ProcessClose(datetime time, double price) {
   if(time <= g_currentPosition.m_openTime) {
      Print("Info: Ignoring Close request at/before Open Time (Wait for future bars).");
      return;
   }
   
   g_currentPosition.m_closeTime = time;
   g_currentPosition.m_closePrice = price; 
   
   g_currentPosition.DrawClose();
   
   AddPosition(g_currentPosition);
   
   g_isWriting = false;
   g_state = STATE_WAITING_OPEN;
   
   Print("Position Closed. Saved to list.");
}

void ProcessDeletion(string objName) {
   for(int i=0; i<ArraySize(g_positions); i++) {
      if(g_positions[i].IsMyObject(objName)) {
         // Direct delete
         RemovePosition(i);
         Print("Position deleted.");
         return; 
      }
   }
   
   if(g_isWriting && g_currentPosition.IsMyObject(objName)) {
      g_currentPosition.Release(); 
      g_isWriting = false;
      g_state = STATE_WAITING_OPEN; 
      Print("Current entry cancelled via object deletion.");
   }
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_CLICK) {
      // Debounce check: Ignore clicks too soon after state change (500ms)
      if(GetTickCount() - g_lastActionTick < 500) return;

      int x = (int)lparam;
      int y = (int)dparam;
      
      // Drag Detection: If distance from MouseDown is large, it's a drag, ignore.
      int dist = (int)MathSqrt(MathPow(x - g_mouseDownX, 2) + MathPow(y - g_mouseDownY, 2));
      if(dist > 5) {
          Print("Ignored Drag Operation (Distance: ", dist, ")");
          return;
      }
      
      // If buttons are active, do not process map clicks as new entries
      // unless we want to move the buttons? Let's just block new entries.
      if(g_state == STATE_WAITING_CONFIRM) {
         return;
      }
      
      // Map click -> Open Entry Menu
      if(g_state == STATE_WAITING_OPEN) {
         // Reset global object to avoid carrying over old data (Critical for Cancel bug)
         SManualPosition emptyPos;
         g_currentPosition = emptyPos;
      }
      
      datetime clickedTime;
      double clickedPrice;
      int window = 0;
      
      if(ChartXYToTimePrice(0, x, y, window, clickedTime, clickedPrice)) {
         
         int barIdx = iBarShift(_Symbol, _Period, clickedTime);
         if(barIdx == -1) {
            Print("Error: Clicked area has no bar data.");
            return;
         }
         
         MqlRates rates[];
         if(CopyRates(_Symbol, _Period, barIdx, 1, rates) <= 0) {
             Print("Error: Failed to copy rates for bar index: ", barIdx);
             return;
         }
         
         double openPrice = rates[0].open;
         datetime barTime = rates[0].time;
         
         Print("Click Detected. Index: ", barIdx, " Time: ", TimeToString(barTime), " Open: ", openPrice);
         
         if(g_state == STATE_WAITING_OPEN) {
            PrepareEntry(barTime, openPrice, x, y);
         }
         else if(g_state == STATE_WAITING_CLOSE) {
            ProcessClose(barTime, openPrice);
         }
      }
      ChartRedraw();
   }
   
   if(id == CHARTEVENT_OBJECT_CLICK) {
      string objName = sparam;
      
      if(objName == "MTL_BTN_BUY") {
         ConfirmEntry(POSITION_TYPE_BUY);
      }
      else if(objName == "MTL_BTN_SELL") {
         ConfirmEntry(POSITION_TYPE_SELL);
      }
      else if(objName == "MTL_BTN_CANCEL") {
         CancelEntry();
      }
      else {
         ProcessDeletion(objName);
      }
      ChartRedraw();
   }
   
   if(id == CHARTEVENT_MOUSE_MOVE) {
       int x = (int)lparam;
       int y = (int)dparam;
       uint state = (uint)StringToInteger(sparam); // sparam is string "1" for left click
       
       bool leftDown = (state & 1) == 1; // Bit 0 is Left Button
       
       if(leftDown && !g_isMouseLeftDown) {
           // Mouse Down Event
           g_mouseDownX = x;
           g_mouseDownY = y;
           g_isMouseLeftDown = true;
       }
       else if(!leftDown && g_isMouseLeftDown) {
           // Mouse Up Event
           g_isMouseLeftDown = false;
       }
   }
}

//+------------------------------------------------------------------+
//| Sort Positions by Open Time (Bubble Sort)                        |
//+------------------------------------------------------------------+
void SortPositions() {
   int size = ArraySize(g_positions);
   if(size < 2) return;
   
   for(int i=0; i<size-1; i++) {
      for(int j=0; j<size-i-1; j++) {
         if(g_positions[j].m_openTime > g_positions[j+1].m_openTime) {
            SManualPosition temp = g_positions[j];
            g_positions[j] = g_positions[j+1];
            g_positions[j+1] = temp;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Save to CSV File                                                 |
//+------------------------------------------------------------------+
void SaveToFile() {
   // Sort by time before saving
   SortPositions();

   string filename = "";
   int fileIdx = 1;
   
   while(true) {
      filename = StringFormat("PositionCase%d.csv", fileIdx);
      if(!FileIsExist(filename)) break; 
      fileIdx++;
   }
   
   Print("Saving to file: ", filename);
   
   int h = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI, ",");
   if(h == INVALID_HANDLE) {
      Print("Failed to create file: ", filename, " Error: ", GetLastError());
      return;
   }
   
   FileWrite(h, "OpenTime", "OpenType", "CloseTime", "CloseType", "Duration(Bars)", "Profit(Point)");
   
   for(int i=0; i<ArraySize(g_positions); i++) {
      SManualPosition pos = g_positions[i]; // Copy

      string sOpenType = (pos.m_type == POSITION_TYPE_BUY) ? "Buy" : "Sell";
      string sCloseType = (pos.m_type == POSITION_TYPE_BUY) ? "Sell" : "Buy"; 
      
      int bars = MathAbs(iBarShift(_Symbol, _Period, pos.m_openTime) - iBarShift(_Symbol, _Period, pos.m_closeTime));
      double profit = 0.0;
      if(pos.m_type == POSITION_TYPE_BUY) profit = (pos.m_closePrice - pos.m_openPrice) / _Point;
      else profit = (pos.m_openPrice - pos.m_closePrice) / _Point;
      
      FileWrite(h, 
         TimeToString(pos.m_openTime, TIME_DATE|TIME_MINUTES),
         sOpenType,
         TimeToString(pos.m_closeTime, TIME_DATE|TIME_MINUTES),
         sCloseType,
         bars,
         DoubleToString(profit, 0)
      );
   }
   
   FileClose(h);
   Print("File created successfully: ", filename);
}
