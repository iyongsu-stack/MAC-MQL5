//+------------------------------------------------------------------+
//|                                                      MyFirst.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

input int VWAPPeriod = 72;
input ENUM_MA_METHOD MaMethod = MODE_EMA;
input int MaPeriod = 5;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //Moving Average data
   double ma[];
   ArraySetAsSeries(ma, true); 
   int maHandle = iMA(_Symbol, 0, MaPeriod, 0, MaMethod, PRICE_WEIGHTED ); 
   CopyBuffer(maHandle, 0, 0, 3, ma );
   double beforeMA = ma[1];
   
   //VWAP data
   double vwap[];
   ArraySetAsSeries(vwap, true);
   int vwapHandle = iCustom(_Symbol, 0, "VWAP2", VWAPPeriod );
   CopyBuffer(vwapHandle, 0, 0, 3, vwap);
   double beforeVWAP = vwap[1];

   Print("ma[1]: ", (float)ma[1], ", ma[0]: ", (float)ma[0], ", vwap[1]: ", (float)vwap[1], ", vwap[0]: ", (float)vwap[0]);

   if(beforeMA >= beforeVWAP) Print("Ascending Trend");
   else Print("Descending Trend");
     
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
