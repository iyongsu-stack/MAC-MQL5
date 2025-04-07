//+------------------------------------------------------------------+
//|                                                   StopLossV7.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV7/ExternVariables.mqh>
//#include <BSPV7/OpenCloseV7.mqh>

void StopLossCheck(void)
{
   if( BSPValue>=MathAbs(SLBSPValue) && !isStopLossDownTrend) 
     {
      StopLossDownTrend();
      isStopLossDownTrend=true;
     } 
   else if( BSPValue<=-MathAbs(SLBSPValue)&& !isStopLossUpTrend) 
     {
      StopLossUpTrend();
      isStopLossUpTrend=true;
     }

   return; 
}
