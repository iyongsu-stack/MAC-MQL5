//+------------------------------------------------------------------+
//|                                                       Deinit.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV4/ExternVariables.mqh>

void MyIndicatorRelease(void)
{

   if(NLRSHandle      !=  INVALID_HANDLE)  IndicatorRelease(NLRSHandle);
   if(NLRMHandle      !=  INVALID_HANDLE)  IndicatorRelease(NLRMHandle);
   if(NLRLHandle      !=  INVALID_HANDLE)  IndicatorRelease(NLRLHandle);
   if(LASHandleM      !=  INVALID_HANDLE)  IndicatorRelease(LASHandleM);
   if(LASHandleL      !=  INVALID_HANDLE)  IndicatorRelease(LASHandleL);   
   if(LASHandleS      !=  INVALID_HANDLE)  IndicatorRelease(LASHandleS);   
   if(WmaHandleS      !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleS);  
   if(WmaHandleM      !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleM);  
   if(WmaHandleL      !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleL);   
   if(BSPHandle       !=  INVALID_HANDLE)  IndicatorRelease(BSPHandle);
   
}