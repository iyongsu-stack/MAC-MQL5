//+------------------------------------------------------------------+
//|                                                     DeinitV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV7/ExternVariables.mqh>

void MyIndicatorRelease(void)
{

   if(LASHandleM       !=  INVALID_HANDLE)  IndicatorRelease(LASHandleM);
   if(LASHandleL       !=  INVALID_HANDLE)  IndicatorRelease(LASHandleL);
   if(WmaHandleS       !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleS);
   if(BSPNlrWmaHandleS !=  INVALID_HANDLE)  IndicatorRelease(BSPNlrWmaHandleS);
   if(BSPNlrWmaHandleL !=  INVALID_HANDLE)  IndicatorRelease(BSPNlrWmaHandleL);
   if(NLRLHandleL      !=  INVALID_HANDLE)  IndicatorRelease(NLRLHandleL);   
   if(WmaHandleL       !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleL);   
   if(BSPHandle        !=  INVALID_HANDLE)  IndicatorRelease(BSPHandle);  
   
}