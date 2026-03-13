//+------------------------------------------------------------------+
//|                                                 BSPWmaSmooth.mq5 |
//| AIEngine clean version — file writing logic removed              |
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

ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;

input int inpWmaPeriod = 10;
input int inpSmoothPeriod = 3;

double SumBuyRatio[], SumSellRatio[], WmaBuyRatio[], WmaSellRatio[], 
       DiffRatio[], SmoothDiffRatio[], SmoothDiffRatioC1[];

double ToPoint;       

void OnInit()
  {
   ArrayInitialize(SumBuyRatio,0.0);
   ArrayInitialize(SumSellRatio,0.0);
   ArrayInitialize(WmaBuyRatio,0.0);
   ArrayInitialize(WmaSellRatio,0.0); 
   ArrayInitialize(DiffRatio,0.0);
   ArrayInitialize(SmoothDiffRatio,0.0);
   ArrayInitialize(SmoothDiffRatioC1,0); 

   SetIndexBuffer(0,SmoothDiffRatio,INDICATOR_DATA);
   SetIndexBuffer(1,SmoothDiffRatioC1,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,DiffRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,SumBuyRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SumSellRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,WmaBuyRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,WmaSellRatio,INDICATOR_CALCULATIONS);

   string short_name = "BSPWmaSmooth("+ (string)inpWmaPeriod +", "+ (string)inpSmoothPeriod + ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
 
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

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double& high[],
                const double& low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   double mVolume; 

   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      ArrayInitialize(SumBuyRatio,0.0);
      ArrayInitialize(SumSellRatio,0.0);
      ArrayInitialize(WmaBuyRatio,0.0);
      ArrayInitialize(WmaSellRatio,0.0);
      ArrayInitialize(DiffRatio,0.0);
      ArrayInitialize(SmoothDiffRatio,0.0);
      ArrayInitialize(SmoothDiffRatioC1,0);
     }

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

   return(rates_total);
  }
//+------------------------------------------------------------------+
