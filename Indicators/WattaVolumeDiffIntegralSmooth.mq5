//+------------------------------------------------------------------+
//|                                WattaVolumeDiffIntegralSmooth.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   2
//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
#property indicator_label1  "WattaVolumeDiffIntegralSmooth"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrDeepPink,clrLimeGreen
#property indicator_width1  2



#property indicator_type2   DRAW_LINE
#property indicator_color2  clrAqua
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

enum Session
{
   AsiaSession,
   EuroSession,
   AmericaSession,
   NoTradingSession,
};

Session LastSession=NoTradingSession, CurSession=NoTradingSession;

#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3;


input ENUM_APPLIED_VOLUME VolumeType    = VOLUME_REAL;  // Volume Type
input int                 AsiaTime      = 3;            // AsiaSession Time
input int                 EuroTime      = 7;            // EuroSession Time
input int                 AmericaTime   = 14;           // AmericaSession Time
input int                 NoTradingTime = 22;           // NoTradingSession Time
input bool                ResetEverySession = false;    // Reset per Session
input CXMA::Smooth_Method XMA_Method=(int)MODE_EMA;     // Averaging method
input uint                XLength1      = 5;            // Depth of the first averaging
input uint                XLength2      = 5;            // Depth of the second averaging
input uint                XLength3      = 5;            // Depth of the third averaging                   
input int                 XPhase        = 15;           // Smoothing parameter


//input int                 LRPeriod      = 60;           //LR period


double p1Buffer[], p2Buffer[], p3Buffer[], p3SumBuffer[], 
       ema_p3SumBuffer[], dema_p3SumBuffer[], tema_p3SumBuffer[], tema_p3SumBufferC[] ;



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,tema_p3SumBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,tema_p3SumBufferC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,p3SumBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,p1Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,p2Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,p3Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,ema_p3SumBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,dema_p3SumBuffer,INDICATOR_CALCULATIONS);
   
   

   string shortname;
//   StringConcatenate(shortname,"BuySellPowerDiffIntegralNLR" );
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

   ArrayInitialize(tema_p3SumBuffer, 0.);
   ArrayInitialize(p3SumBuffer, 0.);
   ArrayInitialize(p1Buffer, 0.);
   ArrayInitialize(p2Buffer, 0.);
   ArrayInitialize(p3Buffer, 0.);
   ArrayInitialize(ema_p3SumBuffer, 0.);
   ArrayInitialize(dema_p3SumBuffer, 0.);
   ArrayInitialize(tema_p3SumBufferC, 0.);
   
   
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

   int first, second ;
   int min_rates_1,min_rates_2;


   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      int smallBar=iBars(_Symbol, PERIOD_M1);
      datetime smallTime = iTime(_Symbol, PERIOD_M1, smallBar-1);
      int start = iBarShift(_Symbol, _Period, smallTime);
      first = start - 1;
      second =  rates_total-first + 1;        
      min_rates_1=second + XMA1.GetStartBars((int)MODE_EMA,XLength1,XPhase);
      min_rates_2=min_rates_1+XMA1.GetStartBars((int)MODE_EMA,XLength2,XPhase);

      
     }
   else
     {     
       first=rates_total-prev_calculated; // starting number for calculation of new bars 
       second = prev_calculated-1; 

     } 



   for(int bar=first; bar>=0; bar--)
     {
      int smallNextBar, smallCurBar;
      datetime bigCurTime, bigNextTime;
      double P1=0, P2=0;

      bigCurTime = iTime(_Symbol, _Period, bar); 
      smallCurBar = iBarShift(_Symbol, PERIOD_M1, bigCurTime);

      if(bar == 0)
        {
          smallNextBar = -1;        
        }
      else if(bar > 0)
        {
          bigNextTime = iTime(_Symbol, _Period, bar-1);
          smallNextBar = iBarShift(_Symbol, PERIOD_M1, bigNextTime);        
        } 
  

      for(int i = smallCurBar; i > smallNextBar; i--)
        {
         
           long mVolume;
           if(VolumeType == VOLUME_TICK) mVolume = iTickVolume(Symbol(),PERIOD_M1,i);
           else mVolume = iVolume(Symbol(),PERIOD_M1,i);
 
           double highest_m1aa = iHigh(Symbol(), PERIOD_M1, iHighest(Symbol(), PERIOD_M1, MODE_HIGH, 2, i));
           double lowest_m1aa  = iLow(Symbol(), PERIOD_M1, iLowest(Symbol(), PERIOD_M1, MODE_LOW, 2, i)); 
           if((highest_m1aa-lowest_m1aa)==0.) continue;
           P1 = mVolume*(iClose(Symbol(),PERIOD_M1,i)-lowest_m1aa )/(highest_m1aa-lowest_m1aa);
         
           P2 = mVolume - P1;
/*
         
           P1 = mVolume *(  (iClose(Symbol(),PERIOD_M1,i)-iLow(Symbol(),PERIOD_M1,i))/
                            (iHigh(Symbol(),PERIOD_M1,i)-iLow(Symbol(),PERIOD_M1,i))  );
           P2 = mVolume *(  (iHigh(Symbol(),PERIOD_M1,i)-iClose(Symbol(),PERIOD_M1,i))/
                            (iHigh(Symbol(),PERIOD_M1,i)-iLow(Symbol(),PERIOD_M1,i))  );
*/
        } 
                
       p1Buffer[(rates_total-1-bar)]=P1;
       p2Buffer[(rates_total-1-bar)]=-P2;
       p3Buffer[(rates_total-1-bar)]=P1-P2;
       
       CurSession = WhatIsSession(bigCurTime);
       
       if( (LastSession != CurSession) && (ResetEverySession || (CurSession == AsiaSession)) )
            p3SumBuffer[(rates_total-1-bar)] = p3Buffer[(rates_total-1-bar)];
       else p3SumBuffer[(rates_total-1-bar)] = p3SumBuffer[(rates_total-1-bar-1)]
                                               + p3Buffer[(rates_total-1-bar)];
      
       LastSession = CurSession;  
                                
       
     }


   for(int i=second; i<rates_total && !IsStopped(); i++)
     {

      ema_p3SumBuffer[i]=XMA1.XMASeries(second,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength1,p3SumBuffer[i],i,false);
      
      dema_p3SumBuffer[i]=XMA2.XMASeries(min_rates_1,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength2,ema_p3SumBuffer[i],i,false);

      tema_p3SumBuffer[i]=XMA3.XMASeries(min_rates_2,prev_calculated,rates_total,XMA_Method,XPhase,XLength3,dema_p3SumBuffer[i],i,false);

      tema_p3SumBufferC[i]=(i>0) ?(tema_p3SumBuffer[i]>tema_p3SumBuffer[i-1]) ? 2 :(tema_p3SumBuffer[i]<tema_p3SumBuffer[i-1]) ? 1 : tema_p3SumBuffer[i-1]: 0;



     }




/*
   for(int avgbar=forth; avgbar<rates_total; avgbar++)
     {
        ema_p3AvgBuffer[avgbar]= iEma( ema_p3AvgBuffer, p3AvgBuffer, avgbar);
                
     }


*/


   
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

/*
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

