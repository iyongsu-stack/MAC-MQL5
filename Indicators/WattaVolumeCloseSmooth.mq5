//+------------------------------------------------------------------+
//|                                       WattaVolumeCloseSmooth.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   1
//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
#property indicator_label1  "WattaVolumeDiffIntegralSmooth"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrDeepPink,clrLimeGreen
#property indicator_width1  3

#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3;


input uint                XLength      = 4;            // Depth of the first averaging
input int                 XPhase        = 15;           // Smoothing parameter


uint                XLength1      = XLength;            // Depth of the first averaging
uint                XLength2      = XLength;            // Depth of the second averaging
uint                XLength3      = XLength;            // Depth of the third averaging                   

CXMA::Smooth_Method XMA_Method=(int)MODE_EMA;     // Averaging method


double ema_close[], dema_close[], tema_close[], tema_closeC[] ;



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,tema_close,INDICATOR_DATA);
   SetIndexBuffer(1,tema_closeC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,ema_close,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,dema_close,INDICATOR_CALCULATIONS);
  

   string shortname;
   StringConcatenate(shortname,"Close Tema (", XLength, ")" );
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

   ArrayInitialize(tema_close, 0.);
   ArrayInitialize(tema_closeC, 0.);
   ArrayInitialize(ema_close, 0.);
   ArrayInitialize(dema_close, 0.);
      
//----
  }




//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+


int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of price maximums for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   int first, min_rates_1, min_rates_2;


   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      min_rates_1= XMA1.GetStartBars((int)MODE_EMA,XLength1,XPhase);
      min_rates_2=min_rates_1+XMA1.GetStartBars((int)MODE_EMA,XLength2,XPhase);
      first = 0;
      
     }
   else
     {     
       first = prev_calculated-1; 
     } 




   for(int i=first; i<rates_total && !IsStopped(); i++)
     {

      ema_close[i]=XMA1.XMASeries(0,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength1,close[i],i,false);      
      dema_close[i]=XMA2.XMASeries(min_rates_1,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength2,ema_close[i],i,false);
      tema_close[i]=XMA3.XMASeries(min_rates_2,prev_calculated,rates_total,XMA_Method,XPhase,XLength3,dema_close[i],i,false);
      tema_closeC[i]=(i>0) ?(tema_close[i]>tema_close[i-1]) ? 2 :(tema_close[i]<tema_close[i-1]) ? 1 : tema_close[i-1]: 0;

     }



   
   return(rates_total);
  }
//+-------------------------------------


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

/*

Session WhatIsSession(datetime m_Time)
{

   MqlDateTime currTime;
   TimeToStruct(m_Time, currTime);
   int hour0 = currTime.hour;
   
   if( (hour0>=AsiaTime) && (hour0<EuroTime) ) return(AsiaSession);
   if( (hour0>=EuroTime) && (hour0<AmericaTime)) return(EuroSession);
   if( (hour0>=AmericaTime) && (hour0<NoTradingTime)) return(AmericaSession);
   return(NoTradingSession);
}


double iEma(const double &t2_Array[], const double &t1_Array[], int r)
{
   return(t2_Array[r-1]+alpha*(t1_Array[r]-t2_Array[r-1]));
}

*/

double Average(int end, int avgPeriod, const double &S_Array[])
{
    double sum;
    sum=0.0;
      
    for(int i=end+1-avgPeriod;i<=end;i++)
    {
          sum+=S_Array[i];
    }
       
    return(sum/avgPeriod);

}



double LinearRegression(int end, int exPeriod, const double &S_Array[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=end+1-exPeriod;i<=end;i++)
         {
          sumX+=X;
          sumY+=S_Array[i];
          sumXY+=X*S_Array[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-exPeriod*sumXY)/(MathPow(sumX,2)-exPeriod*sumX2);
       b=(sumY-a*sumX)/exPeriod;


      return(a);

}

