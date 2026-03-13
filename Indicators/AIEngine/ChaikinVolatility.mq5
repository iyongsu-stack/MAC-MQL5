//+------------------------------------------------------------------+
//|                                                          CHV.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//| AIEngine clean version — file writing logic removed              |
//+------------------------------------------------------------------+
#property copyright   "2009, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Chaikin Volatility"
#property strict
#include <MovingAverages.mqh>
#include <mySmoothingAlgorithm.mqh>

#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   5

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_COLOR_LINE

#property indicator_color1  clrYellow
#property indicator_color2  clrYellow
#property indicator_color3  clrYellow
#property indicator_color4  clrYellow
#property indicator_color5  clrLightBlue,clrDarkOrange

#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DASH
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID
#property indicator_style5  STYLE_SOLID

#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1

#property indicator_label1  "StdDev+3"
#property indicator_label2  "StdDev+2"
#property indicator_label3  "StdDev+1"
#property indicator_label4  "StdDev-1"
#property indicator_label5  "CHV"

#property indicator_level1 0.

enum SmoothMethod
  {
   SMA=0,
   EMA=1,
   WMA=2
  };

input int          InpSmoothPeriod=30;
input int          InpCHVPeriod=30;
input SmoothMethod InpSmoothType=WMA;
input int          InpStdDevPeriod=5000;
input double       InpMultiFactor1=1.0;
input double       InpMultiFactor2=2.0;
input double       InpMultiFactor3=3.0;

double             ExtUp3StdBuffer[];
double             ExtUp2StdBuffer[];
double             ExtUp1StdBuffer[];
double             ExtDown1StdBuffer[];
double             ExtCHVBuffer[];
double             ExtCHVColorBuffer[];
double             ExtHLBuffer[];
double             ExtSHLBuffer[];
double             CVScale[];
double             ExtStdDevBuffer[];

int                ExtSmoothPeriod,ExtCHVPeriod,ExtStdDevPeriod;
HiStdDev3         *iStdDev3;

void OnInit()
  {
   string MAName;
   if(InpSmoothType==SMA) MAName="SMA";
   else if(InpSmoothType==EMA) MAName="EMA";
   else if(InpSmoothType==WMA) MAName="WMA";

   if(InpSmoothPeriod<=0) { ExtSmoothPeriod=30; } else ExtSmoothPeriod=InpSmoothPeriod;
   if(InpCHVPeriod<=0)    { ExtCHVPeriod=30;    } else ExtCHVPeriod=InpCHVPeriod;
   if(InpStdDevPeriod<=0) { ExtStdDevPeriod=5000;} else ExtStdDevPeriod=InpStdDevPeriod;

   if(InpMultiFactor1 <= 0.0) printf("WARNING: InpMultiFactor1=%.2f should be positive.",InpMultiFactor1);
   if(InpMultiFactor2 <= 0.0) printf("WARNING: InpMultiFactor2=%.2f should be positive.",InpMultiFactor2);
   if(InpMultiFactor3 <= 0.0) printf("WARNING: InpMultiFactor3=%.2f should be positive.",InpMultiFactor3);

   for(int p=0; p<5; p++) PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   SetIndexBuffer(0,ExtUp3StdBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtUp2StdBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtUp1StdBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtDown1StdBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtCHVBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,ExtCHVColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,ExtHLBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,ExtSHLBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,CVScale,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,ExtStdDevBuffer,INDICATOR_CALCULATIONS);

   int drawBegin = ExtSmoothPeriod+ExtCHVPeriod-1;
   for(int p=0; p<5; p++) PlotIndexSetInteger(p,PLOT_DRAW_BEGIN,drawBegin);

   IndicatorSetString(INDICATOR_SHORTNAME,"Chaikin Volatility("+string(ExtSmoothPeriod)+","+string(ExtCHVPeriod)+","+MAName+","+
   string(ExtStdDevPeriod)+","+string(InpMultiFactor1)+","+string(InpMultiFactor2)+","+string(InpMultiFactor3)+")");
   IndicatorSetInteger(INDICATOR_DIGITS,1);

   iStdDev3 = new HiStdDev3(ExtStdDevPeriod);
   if(CheckPointer(iStdDev3) == POINTER_INVALID)
      Print("ERROR: HiStdDev3 creation failed!");
  }

void OnDeinit(const int reason)
  {
   if(CheckPointer(iStdDev3) == POINTER_DYNAMIC) delete iStdDev3;
   iStdDev3 = NULL;
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
   int    i,pos,posCHV;
   double stdDev;
   
   if(CheckPointer(iStdDev3) == POINTER_INVALID)
      Print("WARNING: HiStdDev3 invalid. StdDev bands won't be calculated.");
   
   posCHV=ExtCHVPeriod+ExtSmoothPeriod-2;
   if(rates_total<posCHV) return(0);

   const bool MnewBar = (prev_calculated<=0) ? true : isNewBar(_Symbol);

   if(prev_calculated<1 || prev_calculated > rates_total)
     {
      pos=0;
      ArrayInitialize(ExtUp3StdBuffer,0.0);
      ArrayInitialize(ExtUp2StdBuffer,0.0);
      ArrayInitialize(ExtUp1StdBuffer,0.0);
      ArrayInitialize(ExtDown1StdBuffer,0.0);
      ArrayInitialize(ExtCHVBuffer,0.0);
      ArrayInitialize(ExtCHVColorBuffer,0);
      ArrayInitialize(ExtHLBuffer,0.0);
      ArrayInitialize(ExtSHLBuffer,0.0);
      ArrayInitialize(CVScale,0.0);
      ArrayInitialize(ExtStdDevBuffer,0.0);

      if(CheckPointer(iStdDev3) == POINTER_DYNAMIC) delete iStdDev3;
      iStdDev3 = new HiStdDev3(ExtStdDevPeriod);
      if(CheckPointer(iStdDev3) == POINTER_INVALID) Print("OnCalculate: HiStdDev3 recreation failed");
     }
   else pos=prev_calculated-1;
      
   for(i=pos;i<rates_total && !IsStopped();i++) 
     {
      if(i >= ArraySize(High) || i >= ArraySize(Low)) break;
      ExtHLBuffer[i]=High[i]-Low[i];
     }
      
   if(pos<ExtSmoothPeriod-1)
     {
      pos=ExtSmoothPeriod-1;
      for(i=0;i<pos;i++) ExtSHLBuffer[i]=0.0;
     }
     
   if(InpSmoothType==SMA)
      SimpleMAOnBuffer(rates_total,prev_calculated,0,ExtSmoothPeriod,ExtHLBuffer,ExtSHLBuffer);
   else if(InpSmoothType==EMA)
      ExponentialMAOnBuffer(rates_total,prev_calculated,0,ExtSmoothPeriod,ExtHLBuffer,ExtSHLBuffer);
   else if(InpSmoothType==WMA)
      LinearWeightedMAOnBuffer(rates_total,prev_calculated,0,ExtSmoothPeriod,ExtHLBuffer,ExtSHLBuffer);
      
   if(pos<posCHV) pos=posCHV;
   
   for(i=pos;i<rates_total && !IsStopped();i++)
     {
      int prevIdx = i - ExtCHVPeriod;
      if(prevIdx < 0 || prevIdx >= ArraySize(ExtSHLBuffer))
        {
         ExtCHVBuffer[i] = EMPTY_VALUE;
         ExtCHVColorBuffer[i] = (i > 0) ? ExtCHVColorBuffer[i-1] : 0;
         continue;
        }
      
      if(ExtSHLBuffer[prevIdx]!=0.0 && MathAbs(ExtSHLBuffer[prevIdx]) > 1e-10)
         ExtCHVBuffer[i]=100.0*(ExtSHLBuffer[i]-ExtSHLBuffer[prevIdx])/ExtSHLBuffer[prevIdx];
      else
         ExtCHVBuffer[i]=0.0;

      if(i > 0 && ExtCHVBuffer[i] != EMPTY_VALUE && ExtCHVBuffer[i-1] != EMPTY_VALUE)
        {
         if(ExtCHVBuffer[i] > ExtCHVBuffer[i-1])      ExtCHVColorBuffer[i] = 0;
         else if(ExtCHVBuffer[i] < ExtCHVBuffer[i-1])  ExtCHVColorBuffer[i] = 1;
         else ExtCHVColorBuffer[i] = ExtCHVColorBuffer[i-1];
        }
      else
         ExtCHVColorBuffer[i] = (i > 0) ? ExtCHVColorBuffer[i-1] : 0;

      if(CheckPointer(iStdDev3) != POINTER_INVALID)
        {
         if(prev_calculated <= 0 || i == rates_total - 1)
           {
            stdDev = iStdDev3.Calculate(i, ExtCHVBuffer[i]);
            ExtStdDevBuffer[i] = stdDev;
            
            double mf1 = (InpMultiFactor1 > 0.0) ? InpMultiFactor1 : 1.0;
            double mf2 = (InpMultiFactor2 > 0.0) ? InpMultiFactor2 : 2.0;
            double mf3 = (InpMultiFactor3 > 0.0) ? InpMultiFactor3 : 3.0;
            
            ExtUp1StdBuffer[i]   =  stdDev * mf1;
            ExtDown1StdBuffer[i] = -stdDev * mf1;
            ExtUp2StdBuffer[i]   =  stdDev * mf2;
            ExtUp3StdBuffer[i]   =  stdDev * mf3;

            if(stdDev != 0) CVScale[i] = ExtCHVBuffer[i]/stdDev;
            else CVScale[i] = (i > 0) ? CVScale[i-1] : 0.0;
           }   
        }
      else
        {
         ExtUp1StdBuffer[i]   = EMPTY_VALUE;
         ExtDown1StdBuffer[i] = EMPTY_VALUE;
         ExtUp2StdBuffer[i]   = EMPTY_VALUE;
         ExtUp3StdBuffer[i]   = EMPTY_VALUE;
         CVScale[i]           = EMPTY_VALUE;
        }
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
