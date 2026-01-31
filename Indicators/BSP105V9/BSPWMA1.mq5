//+------------------------------------------------------------------+
//|                                                       BSPWMA.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 3
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGreen,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#include <mySmoothingAlgorithm.mqh>
#include <myBSPCalculation.mqh>

ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int                 WmaPeriod1   = 10;          // wmaPeriod1


double DiffPressure[], DiffPressure1[], DiffPressureC1[];

double ToPoint;       

//+------------------------------------------------------------------+  
void OnInit()
  {

   ArrayInitialize(DiffPressure,0.0);
   ArrayInitialize(DiffPressure1,0.0);
   ArrayInitialize(DiffPressureC1,0); 


   SetIndexBuffer(0,DiffPressure1,INDICATOR_DATA);
   SetIndexBuffer(1,DiffPressureC1,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,DiffPressure,INDICATOR_CALCULATIONS);

   string short_name = "BSPWMA1("+ (string)WmaPeriod1 + ")";      
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
     
//----
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

   int start;
   double mVolume;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      start=2; 
      // [Bug Fix] 전체 재계산 시 버퍼 초기화
      ArrayInitialize(DiffPressure,0.0);
      ArrayInitialize(DiffPressure1,0.0);
      ArrayInitialize(DiffPressureC1,0);
     }
   else
     { 
      start=prev_calculated-1;
     } 


//---- The main loop of the indicator calculation
   for(int bar=start; bar<rates_total; bar++)
     {
        
       if(VolumeType == VOLUME_TICK) mVolume = (double)tick_volume[bar];
       else mVolume = (double)volume[bar];

      double tempBuyRatio = CalculateBuyRatio(open, high, low, close, bar);
      double tempSellRatio = CalculateSellRatio(open, high, low, close, bar);
      double tempDiffPressure = (MathAbs(tempBuyRatio) - MathAbs(tempSellRatio))*ToPoint;    

      DiffPressure[bar] = DiffPressure[bar-1] + tempDiffPressure;

      DiffPressure1[bar] = iWma(bar, WmaPeriod1, DiffPressure);
      DiffPressureC1[bar] = (bar>0) ? (DiffPressure1[bar]>=DiffPressure1[bar-1]) ? 0 : 
                                          (DiffPressure1[bar]<DiffPressure1[bar-1]) ? 1 : DiffPressure1[bar-1] : 0;

    }
   return(rates_total);
  }
//+----------------------
