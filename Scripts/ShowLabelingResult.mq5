//+------------------------------------------------------------------+
//|                                          ShowLabelingResult.mq5   |
//|                                                    Yong-su, Kim   |
//|                          CE Trailing Stop Labeling Visualization  |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "CE Trailing Stop 라벨링 시뮬레이션 결과를 차트에 표시합니다."
#property description "Win 거래: 진입 시각의 Low 아래에 녹색 점"

#property script_show_inputs

#include <DKSimplestCSVReader.mqh>

//--- Input parameters
input string InpFilename = "ce_trailing_wins.csv";  // CSV file name

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

   int plotted = 0;
   int skipped = 0;

   for(uint i = 0; i < CSVFile.RowCount(); i++)
   {
      // Parse CSV row
      datetime inTime = StringToTime(CSVFile.GetValue(i, "InTime"));
      string   symbol = CSVFile.GetValue(i, "Symbol");

      // Symbol matching (relaxed)
      if(StringFind(currentSymbol, symbol) == -1 && StringFind(symbol, currentSymbol) == -1)
      {
         skipped++;
         continue;
      }

      // Time range check
      if(inTime < chartStartTime || inTime > chartEndTime)
      {
         skipped++;
         continue;
      }

      // Find the bar index for InTime
      int barIndex = iBarShift(currentSymbol, PERIOD_CURRENT, inTime, false);
      if(barIndex < 0)
      {
         skipped++;
         continue;
      }

      // Get the Low of that bar
      double barLow = iLow(currentSymbol, PERIOD_CURRENT, barIndex);

      // Place green dot below the Low
      string objName = StringFormat("WinDot-%d", i);
      double dotPrice = barLow - 0.3;  // Offset below Low (adjust for visibility)

      if(ObjectCreate(0, objName, OBJ_ARROW, 0, inTime, dotPrice))
      {
         ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 159);  // Dot symbol
         ObjectSetInteger(0, objName, OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);

         // Add tooltip with trade info
         string inPriceStr  = CSVFile.GetValue(i, "InPrice");
         string outPriceStr = CSVFile.GetValue(i, "OutPrice");
         string pnlStr      = CSVFile.GetValue(i, "PnL");
         string exitType    = CSVFile.GetValue(i, "ExitType");
         string tooltip     = StringFormat("Entry: %s | Exit: %s | PnL: %s | Type: %s",
                                           inPriceStr, outPriceStr, pnlStr, exitType);
         ObjectSetString(0, objName, OBJPROP_TOOLTIP, tooltip);

         plotted++;
      }
      else
      {
         PrintFormat("Failed to create object (Row %d): Error %d", i, GetLastError());
      }
   }

   ChartRedraw(0);

   PrintFormat("=== Labeling Result Visualization ===");
   PrintFormat("  Total CSV rows : %d", CSVFile.RowCount());
   PrintFormat("  Plotted (Win)  : %d", plotted);
   PrintFormat("  Skipped        : %d", skipped);
   PrintFormat("  Green dots placed below Low at each winning entry.");
}
//+------------------------------------------------------------------+
