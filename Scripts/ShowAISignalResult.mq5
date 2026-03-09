//+------------------------------------------------------------------+
//|                                          ShowAISignalResult.mq5   |
//|                                                    Yong-su, Kim   |
//|              AI ABC Model Signal Visualization (Filter + Win/Lose) |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "AI 학습결과를 차트에 시각화합니다."
#property description "FILTERED: 빨간 X (M30_DiPlus<=35로 제외)"
#property description "PASS_WIN: 청색 화살표 (필터 통과 + 성공)"
#property description "PASS_LOSE: 빨간 화살표 (필터 통과 + 실패)"

#property script_show_inputs

#include <DKSimplestCSVReader.mqh>

//--- Input parameters
input string InpFilename = "processed\\ABC_signals_v2.csv";  // CSV file name
input double InpOffset    = 0.1;                              // Marker offset below Low

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   // Clear previous objects
   ObjectsDeleteAll(0, -1, -1);
   ChartRedraw(0);

   CDKSimplestCSVReader CSVFile;

   if(!CSVFile.ReadCSV(InpFilename, FILE_ANSI, ";", true))
   {
      PrintFormat("Error reading CSV file: %s (Error: %d)", InpFilename, GetLastError());
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

   int cntFiltered = 0;
   int cntPassWin  = 0;
   int cntPassLose = 0;
   int skipped     = 0;

   for(uint i = 0; i < CSVFile.RowCount(); i++)
   {
      // Parse CSV row
      datetime inTime      = StringToTime(CSVFile.GetValue(i, "InTime"));
      string   symbol      = CSVFile.GetValue(i, "Symbol");
      string   filterStatus= CSVFile.GetValue(i, "FilterStatus");

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

      // Get the Low of that bar for marker placement
      double barLow = iLow(currentSymbol, PERIOD_CURRENT, barIndex);

      // Determine marker properties based on FilterStatus
      int    arrowCode = 0;
      color  arrowColor = clrWhite;
      int    arrowWidth = 2;
      string prefix = "";

      if(filterStatus == "FILTERED")
      {
         // M30 필터 제외 → 빨간색 X
         arrowCode  = 251;      // X mark
         arrowColor = clrRed;
         arrowWidth = 1;
         prefix = "F";
         cntFiltered++;
      }
      else if(filterStatus == "PASS_WIN")
      {
         // 필터 통과 + 성공 → 청색 상향 화살표
         arrowCode  = 233;      // Up arrow
         arrowColor = clrDodgerBlue;
         arrowWidth = 2;
         prefix = "W";
         cntPassWin++;
      }
      else if(filterStatus == "PASS_LOSE")
      {
         // 필터 통과 + 실패 → 빨간색 하향 화살표
         arrowCode  = 234;      // Down arrow
         arrowColor = clrOrangeRed;
         arrowWidth = 2;
         prefix = "L";
         cntPassLose++;
      }
      else
      {
         skipped++;
         continue;
      }

      // Create marker object
      string objName = StringFormat("AISig-%s-%d", prefix, i);
      double dotPrice = barLow - InpOffset;

      if(ObjectCreate(0, objName, OBJ_ARROW, 0, inTime, dotPrice))
      {
         ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
         ObjectSetInteger(0, objName, OBJPROP_COLOR, arrowColor);
         ObjectSetInteger(0, objName, OBJPROP_WIDTH, arrowWidth);
         ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);

         // Build tooltip
         string probStr    = CSVFile.GetValue(i, "Prob");
         string m30Str     = CSVFile.GetValue(i, "M30_DiPlus");
         string retStr     = CSVFile.GetValue(i, "Ret_pts");
         string exitStr    = CSVFile.GetValue(i, "Exit_type");
         string inPriceStr = CSVFile.GetValue(i, "InPrice");

         string tooltip = StringFormat("[%s] Prob: %s | M30_DI+: %s | Entry: %s | Ret: %s pts | Exit: %s",
                                        filterStatus, probStr, m30Str, inPriceStr, retStr, exitStr);
         ObjectSetString(0, objName, OBJPROP_TOOLTIP, tooltip);
      }
      else
      {
         PrintFormat("Failed to create object (Row %d): Error %d", i, GetLastError());
      }
   }

   ChartRedraw(0);

   // Print summary
   int totalPass = cntPassWin + cntPassLose;
   double winRate = (totalPass > 0) ? (double)cntPassWin / totalPass * 100.0 : 0.0;

   PrintFormat("=== AI Signal Visualization ===");
   PrintFormat("  Total CSV rows : %d", CSVFile.RowCount());
   PrintFormat("  ----------------------------");
   PrintFormat("  FILTERED (Red X)    : %d", cntFiltered);
   PrintFormat("  PASS_WIN (Blue ↑)   : %d", cntPassWin);
   PrintFormat("  PASS_LOSE (Red ↓)   : %d", cntPassLose);
   PrintFormat("  ----------------------------");
   PrintFormat("  Filter Pass Rate    : %.1f%%  (%d / %d)",
               (double)totalPass / (totalPass + cntFiltered) * 100.0,
               totalPass, totalPass + cntFiltered);
   PrintFormat("  Win Rate (Pass only): %.1f%%  (%d / %d)",
               winRate, cntPassWin, totalPass);
   PrintFormat("  Skipped             : %d", skipped);
}
//+------------------------------------------------------------------+
