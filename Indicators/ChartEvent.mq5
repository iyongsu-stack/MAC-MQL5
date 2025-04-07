//+------------------------------------------------------------------+
//|                                                   ChartEvent.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   
//---
   return(INIT_SUCCEEDED);
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
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
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

//--- the left mouse button has been pressed on the chart 
   if(id==CHARTEVENT_CLICK) 
     { 
      //Print("The coordinates of the mouse click on the chart are: x = ",lparam,"  y = ",dparam);
      datetime time;
      double price;
      int subwindow=0, x=(int)lparam, y=(int)dparam, bar;
      ChartXYToTimePrice(0,x,y,subwindow,time,price);
      bar = iBarShift(Symbol(),Period(),time+PeriodSeconds()/2,false);
      Alert(" Subwindow: ",IntegerToString(subwindow)," Time: ",TimeToString(time,TIME_SECONDS)," Bar: ",IntegerToString(bar));

        
     } 

   
  }
//+------------------------------------------------------------------+
