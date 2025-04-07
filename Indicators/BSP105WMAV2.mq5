//+------------------------------------------------------------------+
//|                                                  BSP105WMAV2.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#property indicator_separate_window

#property indicator_buffers 15
#property indicator_plots   8

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrGreen,clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrWhite
#property indicator_style3  STYLE_DASH
#property indicator_width3  1

#property indicator_type4   DRAW_LINE
#property indicator_color4  clrWhite
#property indicator_style4  STYLE_DASHDOTDOT
#property indicator_width4  1

#property indicator_type5   DRAW_LINE
#property indicator_color5  clrWhite
#property indicator_style5  STYLE_DOT
#property indicator_width5  1

#property indicator_type6   DRAW_LINE
#property indicator_color6  clrWhite
#property indicator_style6  STYLE_DOT
#property indicator_width6  1

#property indicator_type7   DRAW_LINE
#property indicator_color7  clrWhite
#property indicator_style7  STYLE_DASHDOTDOT
#property indicator_width7  1

#property indicator_type8   DRAW_LINE
#property indicator_color8  clrWhite
#property indicator_style8  STYLE_DASH
#property indicator_width8  1


ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int                 WmaPeriod    = 12;          // wmaPeriod
input int                 WmaPeriod2   = 200;         // WmaPeriod2
input int                 StdPeriod    = 10000;       // WmaPeriod2
input double              MultiFactor1 = 1.0;         // MultiFactor1
input double              MultiFactor2 = 2.0;         // MultiFactor2
input double              MultiFactor3 = 3.0;         // MultiFactor3                 



double SellPressure[], BuyPressure[],
       avg1SellPressure[], avg1BuyPressure[],
       SumSellPressure[], SumBuyPressure[], SumDiffPressure[], SumDiffPressureC[], WmaSumDiffPressure[],
       StdU1[], StdU2[], StdU3[], StdM1[], StdM2[], StdM3[]; 


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,WmaSumDiffPressure,INDICATOR_DATA);
   SetIndexBuffer(1,SumDiffPressure,INDICATOR_DATA);
   SetIndexBuffer(2,SumDiffPressureC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3,StdU3,INDICATOR_DATA);
   SetIndexBuffer(4,StdU2,INDICATOR_DATA);
   SetIndexBuffer(5,StdU1,INDICATOR_DATA);
   SetIndexBuffer(6,StdM1,INDICATOR_DATA);
   SetIndexBuffer(7,StdM2,INDICATOR_DATA);
   SetIndexBuffer(8,StdM3,INDICATOR_DATA);
   SetIndexBuffer(9,SumBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,SumSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,avg1BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,avg1SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,SellPressure,INDICATOR_CALCULATIONS);
  
   string short_name = "BSPWMAWMAABS("+ (string)WmaPeriod +", "+ (string)WmaPeriod2 + ", "+ (string)StdPeriod +
                                       ", "+ (string)MultiFactor1 +", "+ (string)MultiFactor2 +", "+ (string)MultiFactor3 +")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
 
     
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

   int first, second, third, fourth;
   double mVolume, standardDeviation;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2; 
      second = first + WmaPeriod; 
      third = second + WmaPeriod2;
      fourth = third + StdPeriod;
     }
   else
     { 
      first=prev_calculated-1;
      second = first; 
      third = first;
      fourth = first;
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
       


       tempTotalPressure=1.;
       tempBuyRatio = tempBuyRatio/tempTotalPressure;
       tempSellRatio = tempSellRatio/tempTotalPressure;

       BuyPressure[bar] = (tempBuyRatio)*100.;
       SellPressure[bar] = (tempSellRatio)*100.; 

/*       
       BuyPressure[bar] = (tempBuyRatio * mVolume+BuyPressure[bar-1])/2.;
       SellPressure[bar] = (tempSellRatio * mVolume+SellPressure[bar-1])/2.; 
*/
     }
     
     
   for(int bar=second; bar<rates_total; bar++)
     {
            
       avg1BuyPressure[bar] = iWma(bar, WmaPeriod, BuyPressure);
       avg1SellPressure[bar] = iWma(bar, WmaPeriod, SellPressure);

       SumBuyPressure[bar] = SumBuyPressure[bar-1] + avg1BuyPressure[bar];
       SumSellPressure[bar] = SumSellPressure[bar-1] + avg1SellPressure[bar];
       SumDiffPressure[bar]=SumBuyPressure[bar] - SumSellPressure[bar];  
       SumDiffPressureC[bar] = (bar>0) ? (SumDiffPressure[bar]>SumDiffPressure[bar-1]) ? 0 : 
                                          (SumDiffPressure[bar]<SumDiffPressure[bar-1]) ? 1 : SumDiffPressure[bar-1] : 0;
    

     } 


   for(int bar=third; bar<rates_total; bar++)
     {
            
       WmaSumDiffPressure[bar] = iWma(bar, WmaPeriod2, SumDiffPressure);

     } 


   for(int bar=fourth; bar<rates_total; bar++)
     {
      standardDeviation = StdDev(bar, StdPeriod, WmaSumDiffPressure, SumDiffPressure);

      StdU3[bar] =  WmaSumDiffPressure[bar] + standardDeviation * MultiFactor3;
      StdU2[bar] =  WmaSumDiffPressure[bar] + standardDeviation * MultiFactor2;
      StdU1[bar] =  WmaSumDiffPressure[bar] + standardDeviation * MultiFactor1;
      StdM1[bar] =  WmaSumDiffPressure[bar] - standardDeviation * MultiFactor1;
      StdM2[bar] =  WmaSumDiffPressure[bar] - standardDeviation * MultiFactor2;
      StdM3[bar] =  WmaSumDiffPressure[bar] - standardDeviation * MultiFactor3;
      
     }




   return(rates_total);
  }
//+----------------------


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
