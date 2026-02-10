//+------------------------------------------------------------------+
//|                                                  TestCompile.mq5 |
//|                                  Copyright 2026, AntiGravity AI  |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, AntiGravity AI"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

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
   return(rates_total);
  }
