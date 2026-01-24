//+------------------------------------------------------------------+
//|                                          BSP10-5-WMAWMAABSTD.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#property indicator_separate_window

#property indicator_buffers 12
#property indicator_plots   3

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE

#property indicator_color1  clrGreen,clrRed
#property indicator_color2  clrYellow
#property indicator_color3  clrYellow

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID

#property indicator_width1  2
#property indicator_width2  1
#property indicator_width3  1


ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int                 WmaPeriod    = 6;          // wmaPeriod
input int                 WmaPeriod2   = 15;          // WmaPeriod2
input int                 StdPeriod1    = 2880;          // StdPeriod1
input int                 StdPeriod2   = 30;          // StdPeriod2
input double              MultiFactor1   = 1.3;          // MultiFactor1
input double              MultiFactor2   = 0.8;          // MultiFactor2




double SellPressure[], BuyPressure[],
       avg1SellPressure[], avg1BuyPressure[],
       SumSellPressure[], SumBuyPressure[], SumDiffPressure[], WmaSumDiffPressure[], 
       DiffPressure[], DiffPressureC[], 
       upStdAvgDiffPressure[], downStdAvgDiffPressure[];


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,DiffPressure,INDICATOR_DATA);
   SetIndexBuffer(1,DiffPressureC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,upStdAvgDiffPressure,INDICATOR_DATA);
   SetIndexBuffer(3,downStdAvgDiffPressure,INDICATOR_DATA);
   SetIndexBuffer(4,WmaSumDiffPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,SumDiffPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,SumBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,SumSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,avg1BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,avg1SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,SellPressure,INDICATOR_CALCULATIONS);
  
   string short_name = "BSPWMAWMAVGDIFFRABSSTD( "+ (string)WmaPeriod +", "+ (string)WmaPeriod2+", " + (string)StdPeriod1 +", " +(string)StdPeriod2 +", "+
                                                  (string)MultiFactor1 +", "+(string)MultiFactor2 +")";      
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
   double mVolume, standardDeviation1, standardDeviation2;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2; 
      second = first + WmaPeriod; 
      third = second + WmaPeriod2;
      fourth = third + StdPeriod1;
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
       WmaSumDiffPressure[bar] = iWma(bar, WmaPeriod2, SumDiffPressure);
       DiffPressure[bar] = SumDiffPressure[bar] - WmaSumDiffPressure[bar];
       DiffPressureC[bar] = (bar>0) ? (DiffPressure[bar]>DiffPressure[bar-1]) ? 0 : (DiffPressure[bar]<DiffPressure[bar-1]) ? 1 : DiffPressure[bar-1] : 0;

     } 
   

  if(StdPeriod1 < StdPeriod2)
     {
       Alert("StdPeriod1 should be larger than StdPeriod2");
       return(false);
     }  
  
  for(int bar=fourth; bar<rates_total; bar++)
     {        
       standardDeviation1 = StdDev(bar, StdPeriod1, DiffPressure);
       standardDeviation2 = StdDev(bar, StdPeriod2, DiffPressure);

       if( (standardDeviation1*MultiFactor1) >= (standardDeviation2*MultiFactor2) )
         {
            upStdAvgDiffPressure[bar] =  standardDeviation1 * MultiFactor1;
            downStdAvgDiffPressure[bar] = (-1) * standardDeviation1 * MultiFactor1;
         }
      else
         {
            upStdAvgDiffPressure[bar] = standardDeviation2 * MultiFactor2;
            downStdAvgDiffPressure[bar] = (-1) * standardDeviation2 * MultiFactor2;
         }          
     }               


   return(rates_total);
  }
//+----------------------



double StdDev(int end, int SDPeriod, const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
    {
      dAmount+=(S_Array[i])*(S_Array[i]);
    }       

    StdValue = MathSqrt(dAmount/SDPeriod);
    return(StdValue);
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
