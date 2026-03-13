//+------------------------------------------------------------------+
//|                                          ShowLabelingResult.mq5   |
//|                                                    Yong-su, Kim   |
//|                          CE Trailing Stop Labeling Visualization  |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "2.00"
#property description "AI 진입(Entry) + 피라미딩(Addon) + 청산(Exit) 시각화"
#property description "Entry Win=Blue, Entry Loss=Pink, Addon=Green/Orange, Exit=Red/Lime"

#property script_show_inputs

#include <DKSimplestCSVReader.mqh>

//--- Input parameters
input string InpFilename = "sim_visual_entry_pyramid.csv";  // CSV file name

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   // Clear previous objects first
   ObjectsDeleteAll(0, -1, -1);
   ChartRedraw(0);

   CDKSimplestCSVReader CSVFile;

   if(!CSVFile.ReadCSV(InpFilename, FILE_ANSI, ";", true))
   {
      PrintFormat("Error reading CSV file: %s", InpFilename);
      return;
   }

   PrintFormat("Successfully read %d lines from: %s", CSVFile.RowCount(), InpFilename);

   // Get chart info
   string currentSymbol = Symbol();
   int    totalBars     = iBars(currentSymbol, PERIOD_CURRENT);

   if(totalBars <= 0)
   {
      PrintFormat("Error: No bars available on chart");
      return;
   }

   datetime chartStartTime = iTime(currentSymbol, PERIOD_CURRENT, totalBars - 1);
   datetime chartEndTime   = TimeCurrent();

   int      plotted          = 0;
   int      skipped          = 0;
   int      entryCount       = 0;
   int      addonCount       = 0;
   int      exitCount        = 0;
   datetime firstPlottedTime = 0;
   datetime lastPlottedTime  = 0;

   for(uint i = 0; i < CSVFile.RowCount(); i++)
   {
      // Parse CSV row
      datetime inTime = StringToTime(CSVFile.GetValue(i, "InTime"));
      string   symbol = CSVFile.GetValue(i, "Symbol");
      double   pnl    = StringToDouble(CSVFile.GetValue(i, "PnL"));
      string   type   = CSVFile.GetValue(i, "Type");       // Entry / Addon_1 / Addon_2 / Exit
      string   exitType = CSVFile.GetValue(i, "ExitType");
      string   groupStr = CSVFile.GetValue(i, "GroupId");

      // Symbol matching (relaxed)
      if(StringFind(currentSymbol, symbol) == -1 && StringFind(symbol, currentSymbol) == -1)
      {
         // Try comparing base names (e.g., XAUUSD in XAUUSD_Duka)
         string baseSymbol = symbol;
         int underscorePos = StringFind(symbol, "_");
         if(underscorePos > 0)
            baseSymbol = StringSubstr(symbol, 0, underscorePos);
         
         string baseChart = currentSymbol;
         int underscorePos2 = StringFind(currentSymbol, "_");
         if(underscorePos2 > 0)
            baseChart = StringSubstr(currentSymbol, 0, underscorePos2);
         
         if(StringFind(baseChart, baseSymbol) == -1 && StringFind(baseSymbol, baseChart) == -1)
         {
            skipped++;
            continue;
         }
      }

      // Time range check
      if(inTime < chartStartTime || inTime > chartEndTime)
      {
         skipped++;
         continue;
      }

      // Find the bar index
      int barIndex = iBarShift(currentSymbol, PERIOD_CURRENT, inTime, false);
      if(barIndex < 0)
      {
         skipped++;
         continue;
      }

      double barLow  = iLow(currentSymbol, PERIOD_CURRENT, barIndex);
      double barHigh = iHigh(currentSymbol, PERIOD_CURRENT, barIndex);

      // ── 타입별 오브젝트 생성 ──────────────────────────────────
      string objName;
      double dotPrice;
      int    arrowCode;
      color  objColor;
      int    objWidth;

      if(type == "Entry")
      {
         // 1차 진입: Low 아래 위화살표
         objName   = StringFormat("Entry-%d-G%s", i, groupStr);
         dotPrice  = barLow - 0.5;
         arrowCode = 233;  // Up arrow ▲
         objColor  = (pnl > 0) ? clrDodgerBlue : clrMagenta;  // PnL=확률(양수)
         objWidth  = 3;
         entryCount++;
      }
      else if(type == "Addon" || StringFind(type, "Addon") >= 0)
      {
         // 피라미딩 신호 (prob >= 0.25): Low 아래 다이아몬드
         objName   = StringFormat("Addon-%d", i);
         dotPrice  = barLow - 0.3;
         arrowCode = 119;  // Diamond ◆
         objColor  = clrLime;
         objWidth  = 2;
         addonCount++;
      }
      else if(type == "Exit")
      {
         // 청산: High 위 아래화살표
         objName   = StringFormat("Exit-%d-G%s", i, groupStr);
         dotPrice  = barHigh + 0.5;
         arrowCode = 234;  // Down arrow ▼

         if(exitType == "CE_TP")
            objColor = clrLime;     // CE 수익 청산 = 연두
         else
            objColor = clrRed;      // SL 손절 = 빨강

         objWidth = 3;
         exitCount++;
      }
      else
      {
         // 기존 호환: PnL 기반 색상
         objName   = StringFormat("Dot-%d", i);
         dotPrice  = barLow - 0.3;
         arrowCode = 233;
         objColor  = (pnl > 0) ? clrBlue : clrMagenta;
         objWidth  = 2;
      }

      if(ObjectCreate(0, objName, OBJ_ARROW, 0, inTime, dotPrice))
      {
         ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
         ObjectSetInteger(0, objName, OBJPROP_COLOR, objColor);
         ObjectSetInteger(0, objName, OBJPROP_WIDTH, objWidth);
         ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, true);
         ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);

         // Tooltip
         string inPriceStr  = CSVFile.GetValue(i, "InPrice");
         string outPriceStr = CSVFile.GetValue(i, "OutPrice");
         string pnlStr      = CSVFile.GetValue(i, "PnL");
         string tooltip     = StringFormat("[%s] G%s | Price: %s | PnL: %s | %s",
                                           type, groupStr, inPriceStr, pnlStr, exitType);
         ObjectSetString(0, objName, OBJPROP_TOOLTIP, tooltip);

         plotted++;

         if(firstPlottedTime == 0 || inTime < firstPlottedTime)
            firstPlottedTime = inTime;
         if(inTime > lastPlottedTime)
            lastPlottedTime = inTime;
      }
      else
      {
         PrintFormat("Failed to create object (Row %d): Error %d", i, GetLastError());
      }
   }

   // ── 최초 객체 위치로 차트 자동 이동 ──────────────────────────
   if(firstPlottedTime > 0)
   {
      int firstBarIdx   = iBarShift(currentSymbol, PERIOD_CURRENT, firstPlottedTime, false);
      int visibleBars   = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
      int scrollTarget  = firstBarIdx + (int)(visibleBars * 0.75);
      ChartNavigate(0, CHART_END, scrollTarget);
      PrintFormat("[AutoScroll] 최초 객체: %s → 바 인덱스 %d",
                  TimeToString(firstPlottedTime, TIME_DATE|TIME_MINUTES), firstBarIdx);
   }

   ChartRedraw(0);

   PrintFormat("=== Visualization Result ===");
   PrintFormat("  Total CSV rows : %d", CSVFile.RowCount());
   PrintFormat("  Plotted        : %d", plotted);
   PrintFormat("    Entry        : %d", entryCount);
   PrintFormat("    Addon        : %d", addonCount);
   PrintFormat("    Exit         : %d", exitCount);
   PrintFormat("  Skipped        : %d", skipped);
   PrintFormat("  Legend: Blue▲=Entry, Green◆=Addon1, Orange◆=Addon2, Lime▼=CE_TP, Red▼=SL");
}
//+------------------------------------------------------------------+
