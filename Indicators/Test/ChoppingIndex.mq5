//------------------------------------------------------------------
#property copyright   "© mladen, 2018"
#property link        "mladenfx@gmail.com"
#property version     "1.00"
#property description "Choppiness index - JMA smoothed"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Choppiness index"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen,clrCrimson
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#include <mySmoothingAlgorithm.mqh>

input int    inpChoPeriod    = 30;  // Choppiness index period
input int    inpSmoothPeriod = 80;  // Smooth period
input double inpSmoothPhase  = 0;   // Smooth phase

double csi[],csic[];

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
int OnInit()
{
   SetIndexBuffer(0,csi,INDICATOR_DATA);
   SetIndexBuffer(1,csic,INDICATOR_COLOR_INDEX);
   IndicatorSetString(INDICATOR_SHORTNAME,"Jma smoothed Choppiness index ("+string(inpChoPeriod)+","+string(inpSmoothPeriod)+")");
   return(INIT_SUCCEEDED);
}
//
//---
//
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   if(Bars(_Symbol,_Period)<rates_total) return(-1);
   double _log = MathLog(inpChoPeriod)/100.00;
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      double atrSum =    0.00;
      double maxHig = high[i];
      double minLow =  low[i];
              
         for (int k = 0; k<inpChoPeriod && (i-k-1)>=0; k++)
         {
            atrSum += MathMax(high[i-k],close[i-k-1])-MathMin(low[i-k],close[i-k-1]);
            maxHig  = MathMax(maxHig,MathMax(high[i-k],close[i-k-1]));
            minLow  = MathMin(minLow,MathMin( low[i-k],close[i-k-1]));
         }
         double _val = (maxHig!=minLow) ? atrSum/(maxHig-minLow) : 0;
         double _csi = (_val!=0) ? MathLog(_val)/_log : 0;
         csi[i] = iSmooth(_csi,inpSmoothPeriod,inpSmoothPhase,i,rates_total,0);  
         csic[i] = (i>0) ? (csi[i]>csi[i-1]) ? 0 : (csi[i]<csi[i-1]) ? 1 : csic[i-1] : 0;
   }      
   return(rates_total);
}
