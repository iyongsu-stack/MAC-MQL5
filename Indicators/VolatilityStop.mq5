//+------------------------------------------------------------------+
//|                                              ChandeKrollStop.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   2
//--- plot StopLong
#property indicator_label1  "Stop Long"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot StopShort
#property indicator_label2  "Stop Short"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- input parameters
input uint     InpAtrLength   =  10;   // ATR Length
input uint     InpAtrCoeff    =  1;    // ATR Coefficient
input uint     InpStopLength  =  9;    // Stop Length

//--- indicator buffers
double         ExtBufferStopLong[];
double         ExtBufferStopShort[];
double         ExtBufferATR[];
double         ExtBufferFirstHighStop[];
double         ExtBufferFirstLowStop[];

//--- global variables
int      ExtHandleATR;
int      ExtAtrLength;
int      ExtAtrCoeff;
int      ExtStopLength;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtBufferStopLong,INDICATOR_DATA);
   SetIndexBuffer(1,ExtBufferStopShort,INDICATOR_DATA);
   SetIndexBuffer(2,ExtBufferATR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtBufferFirstHighStop,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtBufferFirstLowStop,INDICATOR_CALCULATIONS);
  
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(ExtBufferStopLong,true);
   ArraySetAsSeries(ExtBufferStopShort,true);
   ArraySetAsSeries(ExtBufferATR,true);
   ArraySetAsSeries(ExtBufferFirstHighStop,true);
   ArraySetAsSeries(ExtBufferFirstLowStop,true);
  
//--- setting the periods for calculating and a short name for the indicator
   ExtAtrLength =int(InpAtrLength <1 ? 1 : InpAtrLength);
   ExtAtrCoeff  =int(InpAtrCoeff  <1 ? 1 : InpAtrCoeff);
   ExtStopLength=int(InpStopLength<1 ? 1 : InpStopLength);
   IndicatorSetString(INDICATOR_SHORTNAME,StringFormat("Chande Kroll Stop (%lu, %lu, %lu)",ExtAtrLength,ExtAtrCoeff,ExtStopLength));
  
//--- creating an ATR indicator handle
   ResetLastError();
   ExtHandleATR=iATR(NULL,PERIOD_CURRENT,ExtAtrLength);
   if(ExtHandleATR==INVALID_HANDLE)
     {
      PrintFormat("The iATR(%lu) object was not created: Error %ld",ExtAtrLength,GetLastError());
      return INIT_FAILED;
     }
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
//--- checking for the minimum number of bars for calculation
   if(rates_total<fmax(ExtAtrLength,ExtStopLength))
      return 0;
      
//--- setting predefined indicator arrays as timeseries
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
  
//--- checking and calculating the number of bars to be calculated
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-1;
      ArrayInitialize(ExtBufferStopLong,EMPTY_VALUE);
      ArrayInitialize(ExtBufferStopShort,EMPTY_VALUE);
      ArrayInitialize(ExtBufferATR,0);
      ArrayInitialize(ExtBufferFirstHighStop,0);
      ArrayInitialize(ExtBufferFirstLowStop,0);
     }
    
//--- calculate RAW data
   int count=(limit>1 ? rates_total : 1),copied=0;
   copied=CopyBuffer(ExtHandleATR,0,0,count,ExtBufferATR);
   if(copied!=count)
      return 0;
   double array_h[];
   double array_l[];
   for(int i=limit; i>=0; i--)
     {
      int count=ExtAtrLength;
      if(i+count>rates_total-1)
         count=rates_total-1-i;
      if(count==0)
         continue;
      if(ArrayCopy(array_h,high,0,i,count)!=count || ArrayCopy(array_l,low,0,i,count)!=count)
         continue;

      vector vh;
      vector vl;
      vh.Swap(array_h);
      vl.Swap(array_l);
      ExtBufferFirstHighStop[i]=vh.Max() - ExtAtrCoeff * ExtBufferATR[i];
      ExtBufferFirstLowStop[i] =vl.Min() + ExtAtrCoeff * ExtBufferATR[i];
     }
    
//--- calculation Chande Kroll Stop
   for(int i=limit; i>=0; i--)
     {
      int count=ExtStopLength;
      if(i+count>rates_total-1)
         count=rates_total-1-i;
      if(count==0)
         continue;
      if(ArrayCopy(array_h,ExtBufferFirstHighStop,0,i,count)!=count || ArrayCopy(array_l,ExtBufferFirstLowStop,0,i,count)!=count)
         continue;

      vector vh;
      vector vl;
      vh.Swap(array_h);
      vl.Swap(array_l);
      ExtBufferStopShort[i]=vh.Max();
      ExtBufferStopLong[i]=vl.Min();
     }
    
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------