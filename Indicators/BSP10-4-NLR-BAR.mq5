//+------------------------------------------------------------------+
//|                                              BSP10-4-NLR-BAR.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"
#property indicator_separate_window

#property indicator_buffers 14
#property indicator_plots   1

#property indicator_type1   DRAW_HISTOGRAM

#property indicator_color1  clrGreen

#property indicator_style1  STYLE_SOLID

#property indicator_width1  2

ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


enum Session
{
   AsiaSession,
   EuroSession,
   AmericaSession,
   NoTradingSession,
};


Session LastSession=NoTradingSession, CurSession=NoTradingSession;


enum m_Trend
{
   UpTrend,
   DownTrend,
   NoTrend,
};

m_Trend CurTrend=NoTrend, LastTrend=NoTrend;

input int                 NLRPeriod     = 3;          // NLR Period
input int                 WmaPeriod1    = 6;          // EmaPeriod1
input int                 WmaPeriod2    = 1;          // EmaPeriod2
input int                 WmaPeriod3    = 1;          // EmaPeriod3
input int                 AsiaTime      = 2;            // AsiaSession Time
input int                 EuroTime      = 8;            // EuroSession Time
input int                 AmericaTime   = 14;           // AmericaSession Time
input int                 NoTradingTime = 22;           // NoTradingSession Time
input bool                ResetEverySession = false;    // Reset per Session


double SellPressure[], BuyPressure[],
       avg1SellPressure[], avg1BuyPressure[],
       avg2SellPressure[], avg2BuyPressure[],
       avg3SellPressure[], avg3BuyPressure[],       
       SumSellPressure[], SumBuyPressure[], SumDiffPressure[],
       val[], valc[], test[];


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,test,INDICATOR_DATA);
   SetIndexBuffer(1,val,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,valc,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,SumDiffPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SumBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,SumSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,avg1BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,avg1SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,avg2BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,avg2SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,avg3BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,avg3SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,SellPressure,INDICATOR_CALCULATIONS);
  
 
     
//----
  }
  
  
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

double alpha1 = 2.0 / (1.0+(double)WmaPeriod1);


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

   int first, second, third, fourth, fifth, NumBar=0;
   double mVolume;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2; 
      second = first + WmaPeriod1; 
      third = second + WmaPeriod2; 
      fourth = third + WmaPeriod3; 
      fifth = fourth + NLRPeriod;      
     }
   else
     { 
      first=prev_calculated-1;
      second = first; 
      third = first; 
      fourth = first; 
      fifth = first;
    } 


//---- The main loop of the indicator calculation
   for(int bar=first; bar<rates_total; bar++)
     {
        
       if(VolumeType == VOLUME_TICK) mVolume = (double)tick_volume[bar];
       else mVolume = (double)volume[bar];


       double tempBuyRatio, tempSellRatio, tempTotalPressure ;

       tempBuyRatio = close[bar]<open[bar] ?       (close[bar-1]<open[bar] ?               MathMax(high[bar]-close[bar-1], close[bar]-low[bar]) :
                               /* close[1]>=open */             MathMax(high[bar]-open[bar], close[bar]-low[bar])) : 
             (close[bar]>open[bar] ?       (close[bar-1]>open[bar] ?               high[bar]-low[bar] : 
                               /* close[1]>=open */             MathMax(open[bar]-close[bar-1], high[bar]-low[bar])) :           
             /*close == open*/   (high[bar]-close[bar]>close[bar]-low[bar] ?       
                                                               (close[bar-1]<open[bar] ?              MathMax(high[bar]-close[bar-1],close[bar]-low[bar]) : 
                                                               /*close[1]>=open */           high[bar]-open[bar]) : 
                                 (high[bar]-close[bar]<close[bar]-low[bar] ? 
                                                               (close[bar-1]>open[bar] ?              high[bar]-low[bar] : 
                                                                                             MathMax(open[bar]-close[bar-1], high[bar]-low[bar])) : 
                               /* high-close<=close-low */                             
                                                               (close[bar-1]>open[bar] ?              MathMax(high[bar]-open[bar], close[bar]-low[bar]) : 
                                                               (close[bar-1]<open[bar] ?              MathMax(open[bar]-close[bar-1], high[bar]-low[bar]) : 
                                                               /* close[1]==open */          high[bar]-low[bar])))))  ;  
                 
         tempSellRatio = close[bar]<open[bar] ?       (close[bar-1]>open[bar] ?              MathMax(close[bar-1]-open[bar], high[bar]-low[bar]):
                                                               high[bar]-low[bar]) : 
              (close[bar]>open[bar] ?      (close[bar-1]>open[bar] ?              MathMax(close[bar-1]-low[bar], high[bar]-close[bar]) :
                                                               MathMax(open[bar]-low[bar], high[bar]-close[bar])) : 
              /*close == open*/  (high[bar]-close[bar]>close[bar]-low[bar] ?   
                                                               (close[bar-1]>open[bar] ?               MathMax(close[bar-1]-open[bar], high[bar]-low[bar]) : 
                                                                                              high[bar]-low[bar]) : 
                                 (high[bar]-close[bar]<close[bar]-low[bar] ?      
                                                               (close[bar-1]>open[bar] ?               MathMax(close[bar-1]-low[bar], high[bar]-close[bar]) : 
                                                                                              open[bar]-low[bar]) : 
                                 /* high-close<=close-low */                              
                                                               (close[bar-1]>open[bar] ?               MathMax(close[bar-1]-open[bar], high[bar]-low[bar]) : 
                                                               (close[bar-1]<open[bar] ?               MathMax(open[bar]-low[bar], high[bar]-close[bar]) : 
                                                                                              high[bar]-low[bar])))))   ;
       

       
       tempTotalPressure=tempSellRatio + tempBuyRatio;
       if (tempTotalPressure == 0.) tempTotalPressure = 0.00000001;       
       tempBuyRatio = tempBuyRatio/tempTotalPressure;
       tempSellRatio = tempSellRatio/tempTotalPressure;
       
       double tempBuyPressure = tempBuyRatio * mVolume;
       double tempSellPressure = tempSellRatio * mVolume; 

       BuyPressure[bar] = (tempBuyPressure + BuyPressure[bar-1])/2.;
       SellPressure[bar] = (tempSellPressure + SellPressure[bar-1])/2. ; 
     }
     
     
   for(int bar=second; bar<rates_total; bar++)
     {
            
       avg1BuyPressure[bar] = iWma(bar, WmaPeriod1, BuyPressure);
       avg1SellPressure[bar] = iWma(bar, WmaPeriod1, SellPressure);

     } 


   for(int bar=third; bar<rates_total; bar++)
     {
            
       avg2BuyPressure[bar] = iWma(bar, WmaPeriod2, avg1BuyPressure);
       avg2SellPressure[bar] = iWma(bar, WmaPeriod2, avg1SellPressure);

     } 
     
     for(int bar=fourth; bar<rates_total; bar++)
     {
            
       avg3BuyPressure[bar] = iWma(bar, WmaPeriod3, avg2BuyPressure);
       avg3SellPressure[bar] = iWma(bar, WmaPeriod3, avg2SellPressure);

       datetime curTime=time[bar];
       CurSession = WhatIsSession(curTime);
/*      
       if( (LastSession != CurSession) && (ResetEverySession || (CurSession == AsiaSession)) ) 
       {
         SumBuyPressure[bar] = avg3BuyPressure[bar];
         SumSellPressure[bar] = avg3SellPressure[bar];
       }
            
       else
       {
         SumBuyPressure[bar] = SumBuyPressure[bar-1] + avg3BuyPressure[bar];
         SumSellPressure[bar] = SumSellPressure[bar-1] + avg3SellPressure[bar];
       }
*/

       SumBuyPressure[bar] = SumBuyPressure[bar-1] + avg3BuyPressure[bar];
       SumSellPressure[bar] = SumSellPressure[bar-1] + avg3SellPressure[bar];

       SumDiffPressure[bar]=SumBuyPressure[bar] - SumSellPressure[bar];      

       LastSession = CurSession;  
     } 
     
     
     
   for(int bar=fifth; bar<rates_total; bar++)
     {
      val[bar]=iNlr(SumDiffPressure[bar],NLRPeriod,bar,0,rates_total);
      valc[bar]=(bar>0) ?(val[bar]>val[bar-1]) ? 2 :(val[bar]<val[bar-1]) ? 1 : valc[bar-1]: 0;

      if(val[bar]>val[bar-1]) CurTrend = UpTrend;
      else if(val[bar]<val[bar-1]) CurTrend = DownTrend;
      else CurTrend = NoTrend;

      if( (LastTrend == UpTrend) && (CurTrend == DownTrend) ) 
      {
         test[bar] = -1.;
      }   
      else if( (LastTrend == DownTrend) && (CurTrend == UpTrend) )
      { 
         test[bar] = 1.;
      }   
      else 
      {
         if(CurTrend == UpTrend) test[bar] = test[bar-1] +1.;
         else test[bar] = test[bar-1] -1.;
      }     
      
      LastTrend = CurTrend;
     }
     

   return(rates_total);
  }
//+----------------------

//+------------------------------------------------------------------+
//| Non Linear Regression Function                                   |
//+------------------------------------------------------------------+
double workNlr[][1];
double nlrYValue[];
double nlrXValue[];

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

double iEma(const double &t2_Array[], const double &t1_Array[], int r, double alp)
{
   return(alp*t1_Array[r]+(1-alp)*t2_Array[r-1]);
}

double iWma(int end, int wmaPeriod, const double &S_Array[])
{

   double Sum = 0., Weight=0., Norm=0., wma=0.;
   
   for(int i=0;i<wmaPeriod;i++)
   { 
      Weight = (wmaPeriod-i)*wmaPeriod;
      Norm += Weight; 
      Sum += S_Array[end-i]*Weight;
   }
   if(Norm>0) wma = Sum/Norm;
   else wma = 0; 
   
   return(wma);
}
