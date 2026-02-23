//+------------------------------------------------------------------+
//|                                                 BSPWmaSmooth.mq5 |
//|                                         Copyright 2025, YourName |
//|                                                 https://mql5.com |
//| 13.10.2025 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, YourName"
#property link      "https://mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 7
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGreen,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#include <mySmoothingAlgorithm.mqh>
#include <myBSPCalculation.mqh>

ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int inpWmaPeriod = 10;          // inpwmaPeriod
input int inpSmoothPeriod = 3;      // inpSmoothPeriod



bool g_IsWritten = false;


double SumBuyRatio[], SumSellRatio[], WmaBuyRatio[], WmaSellRatio[], 
       DiffRatio[], SmoothDiffRatio[], SmoothDiffRatioC1[];

double ToPoint;       

//+------------------------------------------------------------------+  
void OnInit()
  {

   ArrayInitialize(SumBuyRatio,0.0);
   ArrayInitialize(SumSellRatio,0.0);
   ArrayInitialize(WmaBuyRatio,0.0);
   ArrayInitialize(WmaSellRatio,0.0); 
   ArrayInitialize(DiffRatio,0.0);
   ArrayInitialize(SmoothDiffRatio,0.0);
   ArrayInitialize(SmoothDiffRatioC1,0); 
   g_IsWritten = false; 


   SetIndexBuffer(0,SmoothDiffRatio,INDICATOR_DATA);
   SetIndexBuffer(1,SmoothDiffRatioC1,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,DiffRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,SumBuyRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SumSellRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,WmaBuyRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,WmaSellRatio,INDICATOR_CALCULATIONS);

   string short_name = "BSPWmaSmooth("+ (string)inpWmaPeriod +", "+ (string)inpSmoothPeriod + ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
 
   // [Code Improvement] 포인트 계산 로직을 모든 상품에 범용적으로 적용 가능하도록 개선
   if(_Point > 0)
     {
       ToPoint = 1.0 / _Point;
       ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
       bool isGold = (StringFind(_Symbol, "XAU") != -1) || (StringFind(_Symbol, "GOLD") != -1);
       if (calcMode == SYMBOL_CALC_MODE_FOREX && _Digits % 2 == 0 && !isGold)
           ToPoint *= 10.0;
     }
   else
     {
       ToPoint = 1.0;
       Print("Warning: Symbol ", _Symbol, " has a point size of 0. ToPoint set to 1.");
     }
     
  }  
  
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+


int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of price maximums for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   double mVolume; 

   // [Bug Fix] 전체 재계산 시 버퍼 초기화
   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      ArrayInitialize(SumBuyRatio,0.0);
      ArrayInitialize(SumSellRatio,0.0);
      ArrayInitialize(WmaBuyRatio,0.0);
      ArrayInitialize(WmaSellRatio,0.0);
      ArrayInitialize(DiffRatio,0.0);
      ArrayInitialize(SmoothDiffRatio,0.0);
      ArrayInitialize(SmoothDiffRatioC1,0);
      g_IsWritten = false;
     }

//---- The main loop of the indicator calculation

   int bar=(int)MathMax(prev_calculated-1,1); for(; bar<rates_total && !_StopFlag; bar++)
     {
        
       if(VolumeType == VOLUME_TICK) mVolume = (double)tick_volume[bar];
       else mVolume = (double)volume[bar];

      double tempBuyRatio = CalculateBuyRatio(open, high, low, close, bar);
      double tempSellRatio = CalculateSellRatio(open, high, low, close, bar);

      SumBuyRatio[bar] = SumBuyRatio[bar-1] + MathAbs(tempBuyRatio);
      SumSellRatio[bar] = SumSellRatio[bar-1] + MathAbs(tempSellRatio);

      WmaBuyRatio[bar] = iWma(bar, inpWmaPeriod, SumBuyRatio);
      WmaSellRatio[bar] = iWma(bar, inpWmaPeriod, SumSellRatio);

      DiffRatio[bar] = WmaBuyRatio[bar] - WmaSellRatio[bar];

      SmoothDiffRatio[bar] = iSmooth(DiffRatio[bar],inpSmoothPeriod,0,bar,rates_total);
      SmoothDiffRatioC1[bar] = (bar>0) ? (SmoothDiffRatio[bar]>=SmoothDiffRatio[bar-1]) ? 0 : 
                                          (SmoothDiffRatio[bar]<SmoothDiffRatio[bar-1]) ? 1 : SmoothDiffRatio[bar-1] : 0;
     } 

   // --- File Writing Logic ---
   if(bar >= rates_total && !g_IsWritten) {
      string filename = "raw\\BSPWmaSmooth_DownLoad.csv";
      int handle = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_ANSI);
      
      if(handle != INVALID_HANDLE) {
         FileWrite(handle, "Time", "Open", "Close", "High", "Low", "SmoothDiffRatio");
         
         for(int k=0; k<rates_total; k++) {
            string timeStr = TimeToString(time[k], TIME_DATE|TIME_MINUTES);
            FileWrite(handle, timeStr, open[k], close[k], high[k], low[k], SmoothDiffRatio[k]);
         }
         FileClose(handle);
         Print("Data download complete: ", filename);
         g_IsWritten = true;
      } else {
         Print("Failed to open file for writing: ", filename);
      }
   } 

   return(rates_total);

  }
//+----------------------
