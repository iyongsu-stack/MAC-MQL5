//+------------------------------------------------------------------+
//|                                                       BOPWma.mq5 |
//|                                         Copyright 2025, YourName |
//|                                                 https://mql5.com |
//| 18.10.2025 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, YourName"
#property link      "https://mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 6
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGreen,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#include <mySmoothingAlgorithm.mqh>
#include <myBSPCalculation.mqh>

//-------------------
input int           inpWmaPeriod = 10;       //inpWmaPeriod

double  SumBulls[], SumBears[], WmaBulls[], WmaBears[], BOP[],BOPC[];

void OnInit()
  {

   ArrayInitialize(SumBulls,0.0);
   ArrayInitialize(SumBears,0.0);
   ArrayInitialize(WmaBulls,0.0);
   ArrayInitialize(WmaBears,0.0);
   ArrayInitialize(BOP,0.0);
   ArrayInitialize(BOPC,0.0);    

   //--- indicator buffers mapping 
   SetIndexBuffer(0,BOP,INDICATOR_DATA);
   SetIndexBuffer(1,BOPC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,SumBulls,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,SumBears,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,WmaBulls,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,WmaBears,INDICATOR_CALCULATIONS);

   IndicatorSetString(INDICATOR_SHORTNAME,"BOPWma ("+(string)inpWmaPeriod+")");
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
   
   // [Bug Fix] 전체 재계산 시 버퍼 초기화
   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      ArrayInitialize(SumBulls,0.0);
      ArrayInitialize(SumBears,0.0);
      ArrayInitialize(WmaBulls,0.0);
      ArrayInitialize(WmaBears,0.0);
      ArrayInitialize(BOP,0.0);
      ArrayInitialize(BOPC,0);
     }
   
   int i=(int)MathMax(prev_calculated-1,0); for(; i<rates_total && !_StopFlag; i++)
     {
      double BullsRewardDaily = CalculateBullsReward(open, high, low, close, i);
      double BearsRewardDaily = CalculateBearsReward(open, high, low, close, i);
      
      //---
      //SumBulls[i] = SumBulls[i-1] + BullsRewardDaily;
      //SumBears[i] = SumBears[i-1] + BearsRewardDaily;
      SumBulls[i] = (i>0) ? SumBulls[i-1] + BullsRewardDaily : BullsRewardDaily;
      SumBears[i] = (i>0) ? SumBears[i-1] + BearsRewardDaily : BearsRewardDaily;

      WmaBulls[i] = iWma(i,inpWmaPeriod, SumBulls);
      WmaBears[i] = iWma(i,inpWmaPeriod, SumBears);

      BOP[i] = WmaBulls[i] - WmaBears[i];
      BOPC[i] = (i>0) ? (BOP[i]>BOP[i-1]) ? 0 : (BOP[i]<BOP[i-1]) ? 1 : 0 : 0;   
     }
   return(i);
  }

