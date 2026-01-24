//+------------------------------------------------------------------+
//|                                        BSP10-5-WMAWMAABS2STD.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#property indicator_separate_window

#property indicator_buffers 15
#property indicator_plots   6

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE

#property indicator_color1  clrDarkTurquoise
#property indicator_color2  clrLawnGreen
#property indicator_color3  clrYellow
#property indicator_color4  clrCoral
#property indicator_color5  clrHotPink
#property indicator_color6  clrWhite


#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID
#property indicator_style5  STYLE_SOLID
#property indicator_style6  STYLE_SOLID

#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  2


ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int                 WmaPeriod    = 6;          // wmaPeriod
input int                 WmaPeriod2   = 15;          // WmaPeriod2
input int                 StdPeriodL    = 1440;          // StdPeriodL
input int                 StdPeriodS   = 30;          // StdPeriodS
input double              MultiFactorL1   = 0.5;          // MultiFactorL1
input double              MultiFactorL2   = 0.75;          // MultiFactorL2
input double              MultiFactorL3   = 1.0;          // MultiFactorL3
input double              MultiFactorL4   = 1.25;          // MultiFactorL4
input double              MultiFactorL5   = 1.5;          // MultiFactorL5
input double              MultiFactorS   = 1.0;          // MultiFactorS




double SellPressure[], BuyPressure[],
       avg1SellPressure[], avg1BuyPressure[],
       SumSellPressure[], SumBuyPressure[], SumDiffPressure[], WmaSumDiffPressure[], 
       DiffPressure[], 
       StdAvgDiffPressureL1[],
       StdAvgDiffPressureL2[], 
       StdAvgDiffPressureL3[],
       StdAvgDiffPressureL4[], 
       StdAvgDiffPressureL5[],  
       StdAvgDiffPressureS[]   ;


//+------------------------------------------------------------------+  
void OnInit()
  {


   SetIndexBuffer(0,StdAvgDiffPressureL1,INDICATOR_DATA);
   SetIndexBuffer(1,StdAvgDiffPressureL2,INDICATOR_DATA);
   SetIndexBuffer(2,StdAvgDiffPressureL3,INDICATOR_DATA);
   SetIndexBuffer(3,StdAvgDiffPressureL4,INDICATOR_DATA);
   SetIndexBuffer(4,StdAvgDiffPressureL5,INDICATOR_DATA);
   SetIndexBuffer(5,StdAvgDiffPressureS,INDICATOR_DATA);
   SetIndexBuffer(6,DiffPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,WmaSumDiffPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,SumDiffPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,SumBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,SumSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,avg1BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,avg1SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,SellPressure,INDICATOR_CALCULATIONS);
  
   string short_name = "BSPWMAWMAVGDIFFRABSSTD( "+ (string)WmaPeriod +", "+ (string)WmaPeriod2+", " + (string)StdPeriodL +", " +(string)StdPeriodS +", "+
                                                  (string)MultiFactorL1 +", "+(string)MultiFactorL2 +", "+(string)MultiFactorL3 +", "+(string)MultiFactorL4 + ", "+
                                                  (string)MultiFactorL5 + ", " + (string)MultiFactorS +" )";      
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
   double mVolume, standardDeviationL, standardDeviationS;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2; 
      second = first + WmaPeriod; 
      third = second + WmaPeriod2;
      fourth = third + StdPeriodL;
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
     } 
   

   if(StdPeriodL < StdPeriodS)
     {
       Alert("StdPeriodL Should be bigger then StdPeriodS");
       return(false);
     }
  
  
  for(int bar=fourth; bar<rates_total; bar++)
     {        
       standardDeviationL = StdDev(bar, StdPeriodL, DiffPressure);
       standardDeviationS = StdDev(bar, StdPeriodS, DiffPressure);
       
       StdAvgDiffPressureL1[bar] =  standardDeviationL * MultiFactorL1;
       StdAvgDiffPressureL2[bar] =  standardDeviationL * MultiFactorL2;
       StdAvgDiffPressureL3[bar] =  standardDeviationL * MultiFactorL3;
       StdAvgDiffPressureL4[bar] =  standardDeviationL * MultiFactorL4;
       StdAvgDiffPressureL5[bar] =  standardDeviationL * MultiFactorL5;
       
       StdAvgDiffPressureS[bar] =  standardDeviationS * MultiFactorS;
         
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
