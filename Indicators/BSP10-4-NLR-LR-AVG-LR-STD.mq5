//+------------------------------------------------------------------+
//|                                           BSP10-4-NLR-LR-STD.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"


#property indicator_separate_window

#property indicator_buffers 14
#property indicator_plots   4

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE

#property indicator_color1  clrYellow
#property indicator_color2  clrWhite
#property indicator_color3  clrGreen
#property indicator_color4  clrRed

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID

#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1

#property indicator_level1 0.
ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int                 NLRPeriod     = 1;          // NLR Period
input int                 WmaPeriod    = 100;          // WmaPeriod1
input int                 LRPeriod     = 5;           // LRPeriod
input int                 AvgPeriod    = 60;          // AvgPeri
input int                 avgAvgPeriod  = 60;           // Avg LRAvg
input int                 StdPeriod    = 1440;        // StdPeriod
input double              MultiFactor  = 2.0;         // StdMultiFactor


double SellPressure[], BuyPressure[],
       avg1SellPressure[], avg1BuyPressure[],
       SumSellPressure[], SumBuyPressure[], SumDiffPressure[],
       val[], valLR[], avgValLR[], LrAvgValLR[], avgAvgValLR[], stdAvgValLR[], upStdAvgValLR[], downStdAvgValLR[];


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,avgValLR,INDICATOR_DATA); 
   SetIndexBuffer(1,avgAvgValLR,INDICATOR_DATA);    
   SetIndexBuffer(2,upStdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(3,downStdAvgValLR,INDICATOR_DATA);  
   SetIndexBuffer(4,valLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,stdAvgValLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,val,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,SumDiffPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,SumBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,SumSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,avg1BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,avg1SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,SellPressure,INDICATOR_CALCULATIONS);
  
//----
  }
  
  
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

double alpha1 = 2.0 / (1.0+(double)WmaPeriod);


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

   int first, second, third, fourth, fifth, sixth, seventh, eighth;
   double mVolume, standardDeviation;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=50; 
      second = first + WmaPeriod; 
      third = second + NLRPeriod;
      fourth = third + LRPeriod; 
      fifth  = fourth + AvgPeriod;
      sixth  = fifth  + avgAvgPeriod;
      seventh = sixth + StdPeriod;
      eighth  = sixth + StdPeriod;
      
     }
   else
     { 
      first=prev_calculated-1;
      second = first; 
      third = first; 
      fourth = first;
      fifth = first;
      sixth = first;
      seventh = first;
      eighth = first;
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
/*
       double tempBuyPressure = tempBuyRatio * mVolume;
       double tempSellPressure = tempSellRatio * mVolume; 

*/

       
       BuyPressure[bar] = (tempBuyRatio * mVolume+BuyPressure[bar-1])/2.;
       SellPressure[bar] = (tempSellRatio * mVolume+SellPressure[bar-1])/2.; 
     }
     
     
   for(int bar=second; bar<rates_total; bar++)
     {
            
       avg1BuyPressure[bar] = iWma(bar, WmaPeriod, BuyPressure);
       avg1SellPressure[bar] = iWma(bar, WmaPeriod, SellPressure);

       SumBuyPressure[bar] = SumBuyPressure[bar-1] + avg1BuyPressure[bar];
       SumSellPressure[bar] = SumSellPressure[bar-1] + avg1SellPressure[bar];

       SumDiffPressure[bar]=SumBuyPressure[bar] - SumSellPressure[bar];      

     } 
    
   for(int bar=third; bar<rates_total; bar++)
     {
      val[bar]=iNlr(SumDiffPressure[bar],NLRPeriod,bar,0,rates_total);
     }
     
   for(int bar=fourth; bar<rates_total; bar++)
     {
      valLR[bar]=LinearRegression(bar, LRPeriod, val);
     }

  for(int bar=fifth; bar<rates_total; bar++)
     {        
       avgValLR[bar]= iWma(bar, AvgPeriod, valLR);
     }       


  for(int bar=sixth; bar<rates_total; bar++)
     {        
       avgAvgValLR[bar]= iWma(bar, avgAvgPeriod, avgValLR);
     }       


  for(int bar=seventh; bar<rates_total; bar++)
     {        
       stdAvgValLR[bar]= iAverage(bar, StdPeriod, avgValLR);
     }       

  for(int bar=eighth; bar<rates_total; bar++)
     {        
       standardDeviation = StdDev(bar, StdPeriod, stdAvgValLR, avgValLR);
       upStdAvgValLR[bar] = avgAvgValLR[bar] + standardDeviation * MultiFactor;
       downStdAvgValLR[bar] = avgAvgValLR[bar] - standardDeviation * MultiFactor;
     }               



   return(rates_total);
  }
//+----------------------


double LinearRegression(int end, int period, const double &close[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=end+1-period;i<=end;i++)
         {
          sumX+=X;
          sumY+=close[i];
          sumXY+=X*close[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-period*sumXY)/(MathPow(sumX,2)-period*sumX2);
       b=(sumY-a*sumX)/period;


      return(a);

}




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


double iAverage(int end, int avgPeriod, const double &S_Array[])
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

double StdDev(int end, int SDPeriod, const double &Avg_Array[], const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
    {
      dAmount+=(S_Array[i]-Avg_Array[i])*(S_Array[i]-Avg_Array[i]);
    }       

    StdValue = MathSqrt(dAmount/SDPeriod);
    return(StdValue);
}  