//+------------------------------------------------------------------+
//|                                                BSP105BSPV3-1.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 9
#property indicator_plots   8

#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_LINE
#property indicator_type8   DRAW_LINE

#property indicator_color1  clrGreen,clrRed
#property indicator_color2  clrWhite
#property indicator_color3  clrYellow
#property indicator_color4  clrYellow
#property indicator_color5  clrYellow
#property indicator_color6  clrYellow
#property indicator_color7  clrYellow
#property indicator_color8  clrYellow

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_DOT
#property indicator_style3  STYLE_DOT
#property indicator_style4  STYLE_DASH
#property indicator_style5  STYLE_SOLID
#property indicator_style6  STYLE_SOLID
#property indicator_style7  STYLE_DASH
#property indicator_style8  STYLE_DOT

#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
#property indicator_width8  1


input int                 WmaPeriod    = 6;          // WmaPeriod1
input int                 StdPeriodL    = 10000;        // StdPeriodL

input double              MultiFactorL1  = 0.8;         // StdMultiFactorL1
input double              MultiFactorL2  = 2.0;         // StdMultiFactorL2
input double              MultiFactorL3  = 4.0;         // StdMultiFactorL3


ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


double DiffPressure[], WmaDiffPressure[], DiffPressureC[], 
       up1StdL[], up2StdL[], up3StdL[], down1StdL[], down2StdL[], down3StdL[];


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0, DiffPressure,INDICATOR_DATA);
   SetIndexBuffer(1, DiffPressureC, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, WmaDiffPressure,INDICATOR_DATA);
   SetIndexBuffer(3, up3StdL,INDICATOR_DATA);
   SetIndexBuffer(4, up2StdL,INDICATOR_DATA);
   SetIndexBuffer(5, up1StdL,INDICATOR_DATA);
   SetIndexBuffer(6, down1StdL,INDICATOR_DATA);
   SetIndexBuffer(7, down2StdL,INDICATOR_DATA);
   SetIndexBuffer(8, down3StdL,INDICATOR_DATA);
   
   

   string short_name = "BSPstd("+ (string)WmaPeriod + ", "  + (string)StdPeriodL + ", " +(string)MultiFactorL1 + ", " 
                                +(string)MultiFactorL2 +", " +(string)MultiFactorL3 + ")";      
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

   int first, second, third;
   double mVolume, standardDeviation;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;  
      second = first + WmaPeriod;
      third = first + StdPeriodL;
     }
   else
     { 
      first=prev_calculated-1; 
      second = first;
      third = first;
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
       
       DiffPressure[bar] =( MathAbs(tempBuyRatio) - MathAbs(tempSellRatio) ) * 10000.;
       
       if(DiffPressure[bar]>= 0.) DiffPressureC[bar] = 0;
       else DiffPressureC[bar]= 1;

     }  

   for(int bar=second; bar<rates_total; bar++)
     {
      WmaDiffPressure[bar]=iWma(bar, WmaPeriod, DiffPressure);
     }

   for(int bar=third; bar<rates_total; bar++)
     {
      standardDeviation = StdDev(bar, StdPeriodL, DiffPressure);
      
      up1StdL[bar] = standardDeviation * MultiFactorL1;
      down1StdL[bar] = - standardDeviation * MultiFactorL1;
      
      up2StdL[bar] = standardDeviation * MultiFactorL2;
      down2StdL[bar] = - standardDeviation * MultiFactorL2;
      
      up3StdL[bar] = standardDeviation * MultiFactorL3;
      down3StdL[bar] = - standardDeviation * MultiFactorL3;      
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

