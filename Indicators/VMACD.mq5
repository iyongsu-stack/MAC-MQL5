//+------------------------------------------------------------------+
//|                                                        VMACD.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window

#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_color1  Silver
#property indicator_color2  Red
#property indicator_width1  2
#property indicator_width2  1
#property indicator_label1  "VMACD"
#property indicator_label2  "VSignal"
//--- input parameters
input int                InpFastVEMA=12;               // Fast EMA period
input int                InpSlowVEMA=26;               // Slow EMA period
input int                InpSignalSMA=9;              // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price
//--- indicator buffers
double ExtVMacdBuffer[];
double ExtVSignalBuffer[];
double ExtFastVMaBuffer[];
double ExtSlowVMaBuffer[];

int    ExtFastVMaHandle;
int    ExtSlowVMaHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtVMacdBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtVSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtFastVMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtSlowVMaBuffer,INDICATOR_CALCULATIONS);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpSignalSMA-1);
//--- name for indicator subwindow label
   string short_name=StringFormat("VMACD(%d,%d,%d)",InpFastVEMA,InpSlowVEMA,InpSignalSMA);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
  }

//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
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

//--- get MA handles
   ExtFastVMaHandle=iCustom(NULL,0,"VWAP2", InpFastVEMA,MODE_EMA);
   ExtSlowVMaHandle=iCustom(NULL,0,"VWAP2", InpSlowVEMA,MODE_EMA);


   if(rates_total<InpSignalSMA)
      return(0);
//--- not all data may be calculated
   int calculated=BarsCalculated(ExtFastVMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtFastVMaHandle is calculated (",calculated," bars). Error ",GetLastError());
      return(0);
     }
   calculated=BarsCalculated(ExtSlowVMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtSlowVMaHandle is calculated (",calculated," bars). Error ",GetLastError());
      return(0);
     }
//--- we can copy not all data
   int to_copy = rates_total  - 1;
   if(prev_calculated > 0) to_copy = rates_total  - (prev_calculated - 1);

//--- get Fast VEMA buffer
   if(IsStopped()) // checking for stop flag
      return(0);
   if(CopyBuffer(ExtFastVMaHandle,0,0,to_copy,ExtFastVMaBuffer) <= 0)
     {
      Print("Getting fast EMA is failed! Error ",GetLastError());
      return(0);
     }
//--- get SlowSMA buffer
   if(IsStopped()) // checking for stop flag
      return(0);
   if(CopyBuffer(ExtSlowVMaHandle,0,0,to_copy,ExtSlowVMaBuffer)<=0)
     {
      Print("Getting slow SMA is failed! Error ",GetLastError());
      return(0);
     }
//---
   int start;
   if(prev_calculated==0)
      start=0;
   else
      start=prev_calculated-1;
//--- calculate MACD
   for(int i=start; i<rates_total && !IsStopped(); i++)
      ExtVMacdBuffer[i]=ExtFastVMaBuffer[i]-ExtSlowVMaBuffer[i];
//--- calculate Signal
   SimpleMAOnBuffer(rates_total,prev_calculated,0,InpSignalSMA,ExtVMacdBuffer,ExtVSignalBuffer);
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
