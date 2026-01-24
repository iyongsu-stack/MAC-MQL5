//+------------------------------------------------------------------+
//|                                     BullsBearsIntegralSmooth.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Shovel"
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   2

//--- plot Bulls Bears Volume  
#property indicator_label1  "BuySellInteSmooth"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  Green,Red
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "BuySellInte"
#property indicator_type2   DRAW_LINE
#property indicator_style2  STYLE_SOLID
#property indicator_color2  clrYellow
#property indicator_width2  1


#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3;

//--- input parameters
input int                  InpPeriod=30;              // Period
input ENUM_APPLIED_VOLUME  InpVolumeType=VOLUME_TICK; // Volumes
input double               delta=0.0;             // delta (flat level)
input uint                 XLength      = 4;            // Depth of the first averaging
input int                  XPhase        = 15;           // Smoothing parameter





uint                XLength1      = XLength;            // Depth of the first averaging
uint                XLength2      = XLength;            // Depth of the second averaging
uint                XLength3      = XLength;            // Depth of the third averaging                   

CXMA::Smooth_Method XMA_Method=MODE_LWMA;     // Averaging method


//--- handle of EMA
int       ExtEmaHandle;

//--- indicator buffers
double    BullsBearsIntegral[];
double    ExtBullsBearsBuffer[];
double    ExtTempBuffer[];
double    ExtVolumesBuffer[];
double    ema_BullsBearsIntegral[];
double    dema_BullsBearsIntegral[];
double    tema_BullsBearsIntegral[];
double    tema_BullsBearsIntegralC[];



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

   SetIndexBuffer(0,tema_BullsBearsIntegral,INDICATOR_DATA);
   SetIndexBuffer(1,tema_BullsBearsIntegralC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,BullsBearsIntegral,INDICATOR_DATA);
   SetIndexBuffer(3,ExtTempBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtVolumesBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtBullsBearsBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,ema_BullsBearsIntegral,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,dema_BullsBearsIntegral,INDICATOR_CALCULATIONS);

//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpPeriod-1);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"BullsBearsInte("+(string)InpPeriod+"  Smooth: "+(string)XLength+") ");
//--- get MA handle
   ExtEmaHandle=iMA(NULL,0,InpPeriod,0,MODE_EMA,PRICE_CLOSE);

//--- initialization done
   return(0);
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

   int i,limit,period=InpPeriod, min_rates_1, min_rates_2;
   double _bear,_bull;
//--- value point
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);

//--- check for bars count
   if(rates_total<InpPeriod)
      return(0);// not enough bars for calculation  
//--- not all data may be calculated
   int calculated=BarsCalculated(ExtEmaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtEmaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
//---- get ma buffers
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtEmaHandle,0,0,to_copy,ExtTempBuffer)<=0)
     {
      Print("getting ExtEmaHandle is failed! Error",GetLastError());
      return(0);
     }
//--- first calculation or number of bars was changed
   if(prev_calculated<InpPeriod)
     {
       limit=InpPeriod;
       min_rates_1= InpPeriod + XMA1.GetStartBars(XMA_Method,XLength1,XPhase);
       min_rates_2=min_rates_1+XMA1.GetStartBars(XMA_Method,XLength2,XPhase);     
     }
     
   else limit=prev_calculated-1;

//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      _bull = high[i]-ExtTempBuffer[i];
      _bear = low[i]-ExtTempBuffer[i];

      //--- fill indicators buffer
      if(_bull>0 && _bear>0) ExtBullsBearsBuffer[i]=_bull-_bear;
      else if(_bull<0 && _bear<0) ExtBullsBearsBuffer[i]=-(MathAbs(_bear)-MathAbs(_bull));
      else  ExtBullsBearsBuffer[i]=_bull+_bear;

      //--- value volume
      long _volume=(InpVolumeType==VOLUME_TICK)?tick_volume[i]:volume[i];

      //--- add volume to indicators buffer
      ExtBullsBearsBuffer[i]=ExtBullsBearsBuffer[i]*(double)_volume;

      //--- remove noise
      if(MathAbs(ExtBullsBearsBuffer[i])<delta) ExtBullsBearsBuffer[i]=0.0;
      BullsBearsIntegral[i] = BullsBearsIntegral[i-1]+ExtBullsBearsBuffer[i];
      
      ema_BullsBearsIntegral[i]=XMA1.XMASeries(InpPeriod,prev_calculated,rates_total,XMA_Method,XPhase,
                                    XLength1,BullsBearsIntegral[i],i,false);      
      dema_BullsBearsIntegral[i]=XMA2.XMASeries(min_rates_1,prev_calculated,rates_total,XMA_Method,XPhase,
                                    XLength2,ema_BullsBearsIntegral[i],i,false);
      tema_BullsBearsIntegral[i]=XMA3.XMASeries(min_rates_2,prev_calculated,rates_total,XMA_Method,XPhase,
                                    XLength3,dema_BullsBearsIntegral[i],i,false);
      tema_BullsBearsIntegralC[i]=(i>0) ?(tema_BullsBearsIntegral[i]>tema_BullsBearsIntegral[i-1]) ? 2 
               :(tema_BullsBearsIntegral[i]<tema_BullsBearsIntegral[i-1]) ? 1 : tema_BullsBearsIntegral[i-1]: 0;      

//      Alert("");
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+-------------------