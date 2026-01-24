//+------------------------------------------------------------------+
//|                                                      BSP10-1.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 3
#property indicator_plots   3

#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_type3   DRAW_HISTOGRAM

#property indicator_color1  clrGreen
#property indicator_color2  clrRed
#property indicator_color3  clrYellow

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID

#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2

ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


double SellPressure[], BuyPressure[], TotalPressure[], DiffPressure[];


//+------------------------------------------------------------------+  
void OnInit()
  {


   SetIndexBuffer(0,BuyPressure,INDICATOR_DATA);
   SetIndexBuffer(1,SellPressure,INDICATOR_DATA);
   SetIndexBuffer(2,DiffPressure,INDICATOR_DATA);
  
 
     
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

   int first;
   double mVolume;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;  
     }
   else
     { 
      first=prev_calculated-1; 
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
       
       BuyPressure[bar] = tempBuyRatio * mVolume;
       SellPressure[bar] = -(tempSellRatio * mVolume);
       DiffPressure[bar] = BuyPressure[bar] + SellPressure[bar];
     } 


   return(rates_total);
  }
//+----------------------
