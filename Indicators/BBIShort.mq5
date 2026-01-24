//+------------------------------------------------------------------+
//|                                                     BBIShort.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   2

#property indicator_label1  "Nonlinear regression"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrDeepPink,clrLimeGreen
#property indicator_width1  2



#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1


//--- input parameters
input int                  InpPeriod=50;              // EMA Period
input int                  NLRPeriod=4;               // NLR Period
input ENUM_APPLIED_VOLUME  InpVolumeType=VOLUME_TICK; // Volumes
input double               delta=0.0;             // delta (flat level)

//--- handle of EMA
int       ExtEmaHandle;

//--- indicator buffers
double    BullsBearsIntegral[];
double    BullsBearsIntegralNLR[];
double    BullsBearsIntegralNLRC[];
double    ExtBullsBearsBuffer[];
double    ExtTempBuffer[];
double    ExtVolumesBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BullsBearsIntegralNLR,INDICATOR_DATA);
   SetIndexBuffer(1,BullsBearsIntegralNLRC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,BullsBearsIntegral,INDICATOR_DATA);   
   SetIndexBuffer(3,ExtBullsBearsBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtTempBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtVolumesBuffer,INDICATOR_CALCULATIONS);

   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpPeriod-1);
   IndicatorSetString(INDICATOR_SHORTNAME,"BullsBearsVolume("+(string)InpPeriod+"  NLRPeriod: "+(string)NLRPeriod+") ");


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

   int limit,first, period=InpPeriod;
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
      limit=InpPeriod;
   else limit=prev_calculated-1;

//--- the main loop of calculations
   for(int i=limit;i<rates_total && !IsStopped();i++)
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

     }


   if(prev_calculated<InpPeriod)
      first=InpPeriod+NLRPeriod;
   else first=prev_calculated-1;
   
   for(int i=first;i<rates_total && !IsStopped();i++)
     {
      BullsBearsIntegralNLR[i]=iNlr(BullsBearsIntegral[i],NLRPeriod,i,0,rates_total);
      BullsBearsIntegralNLRC[i]=(i>0) ?(BullsBearsIntegralNLR[i]>BullsBearsIntegralNLR[i-1]) ? 2 :(BullsBearsIntegralNLR[i]<BullsBearsIntegralNLR[i-1]) ? 1 : BullsBearsIntegralNLR[i-1]: 0;
     }
   
   
   return(rates_total);
  }
//+-------------------




//+------------------------------------------------------------------+
//| Non-Linear Regression Function : 2'nd order regression           |
//+------------------------------------------------------------------+
double workNlr[][1];
double nlrYValue[];
double nlrXValue[];
//
//---
//
double iNlr(double price,int Length,int shift,int desiredBar,int bars,int instanceNo=0)
  {
   if(ArrayRange(workNlr,0)!=bars) ArrayResize(workNlr,bars);
   if(ArraySize(nlrYValue)!=Length) ArrayResize(nlrYValue,Length);
   if(ArraySize(nlrXValue)!=Length) ArrayResize(nlrXValue,Length);
//
//---
//
   double AvgX = 0;
   double AvgY = 0;
   int r=shift;
   workNlr[r][instanceNo]=price;
   ArrayInitialize(nlrXValue,0);
   ArrayInitialize(nlrYValue,0);
   for(int i=0;i<Length && (r-i)>=0;i++)
     {
      nlrXValue[i] = i;
      nlrYValue[i] = workNlr[r-i][instanceNo];
      AvgX  += nlrXValue[i];
      AvgY  += nlrYValue[i];
     }
   AvgX /= Length;
   AvgY /= Length;
//
//---
//
   double SXX   = 0;
   double SXY   = 0;
   double SYY   = 0;
   double SXX2  = 0;
   double SX2X2 = 0;
   double SYX2  = 0;

   for(int i=0;i<Length;i++)
     {
      double XM  = nlrXValue[i] - AvgX;
      double YM  = nlrYValue[i] - AvgY;
      double XM2 = nlrXValue[i] * nlrXValue[i] - AvgX*AvgX;
      SXX   += XM*XM;
      SXY   += XM*YM;
      SYY   += YM*YM;
      SXX2  += XM*XM2;
      SX2X2 += XM2*XM2;
      SYX2  += YM*XM2;
     }
//
//---
//
   double tmp;
   double ACoeff=0;
   double BCoeff=0;
   double CCoeff=0;

   tmp=SXX*SX2X2-SXX2*SXX2;
   if(tmp!=0)
     {
      BCoeff = ( SXY*SX2X2 - SYX2*SXX2 ) / tmp;
      CCoeff = ( SXX*SYX2  - SXX2*SXY )  / tmp;
     }
   ACoeff = AvgY   - BCoeff*AvgX       - CCoeff*AvgX*AvgX;
   tmp    = ACoeff + BCoeff*desiredBar + CCoeff*desiredBar*desiredBar;
   return(tmp);
  }
