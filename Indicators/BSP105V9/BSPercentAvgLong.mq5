//+------------------------------------------------------------------+
//|                                                       BSPBSP2.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <mySmoothingAlgorithm.mqh>

#property indicator_separate_window

#property indicator_buffers 5
#property indicator_plots   4

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE

#property indicator_color1  clrRed
#property indicator_color2  clrGreen
#property indicator_color3  clrYellow
#property indicator_color4  clrWhite

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID

#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1

input int                 AvgPeriod1    = 30;          // AvgPeriod1  
input int                 AvgPeriod2    = 180;          // AvgPeriod2
input int                 AvgPeriod3    = 3600;          // AvgPeriod3
input int                 AvgPeriod4    = 72000;         // AvgPeriod4


ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


double DiffBSP[], DiffBSPAvg1[], DiffBSPAvg2[], DiffBSPAvg3[], DiffBSPAvg4[];
double ToPoint;       

//+------------------------------------------------------------------+  
void OnInit()
  {

   ArrayInitialize(DiffBSP,0.0);
   ArrayInitialize(DiffBSPAvg1,0.0);
   ArrayInitialize(DiffBSPAvg2,0.0);
   ArrayInitialize(DiffBSPAvg3,0.0);
   ArrayInitialize(DiffBSPAvg4,0.0);

   SetIndexBuffer(0, DiffBSPAvg1,INDICATOR_DATA);
   SetIndexBuffer(1, DiffBSPAvg2,INDICATOR_DATA);
   SetIndexBuffer(2, DiffBSPAvg3,INDICATOR_DATA);
   SetIndexBuffer(3, DiffBSPAvg4,INDICATOR_DATA);
   SetIndexBuffer(4, DiffBSP,INDICATOR_CALCULATIONS);
     

   string short_name = "BSPPercentAvg("+ (string)AvgPeriod1 + ", "  + (string)AvgPeriod2 + ", " +
                                       (string)AvgPeriod3 + ", " +  (string)AvgPeriod4 + ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
    
//----

  switch(_Digits)
    {
      case 2: 
       ToPoint=MathPow(10., 3); break; 
      case 3: 
       ToPoint=MathPow(10., 3); break; 
      case 4: 
       ToPoint=MathPow(10., 5); break; 
      case 5: 
       ToPoint=MathPow(10., 5); break; 
    }

   string GoldSymbol = "XAUUSD";
   string thisSymbol = StringSubstr(_Symbol, 0, 6);
   if(thisSymbol == GoldSymbol) ToPoint = 100.;

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

   int first, second, third, fourth, fifth;
   double mVolume;
   bool MnewBar = isNewBar(_Symbol);


   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;  
      second = first + AvgPeriod1;
      third = first + AvgPeriod2;
      fourth = first + AvgPeriod3;
      fifth = first + AvgPeriod4;
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
 

       tempTotalPressure=( MathAbs(tempBuyRatio) + MathAbs(tempSellRatio) );
       if(tempTotalPressure == 0) tempTotalPressure = 0.001;
       tempBuyRatio = MathAbs(tempBuyRatio)/MathAbs(tempTotalPressure)*100.;
       tempSellRatio = MathAbs(tempSellRatio)/MathAbs(tempTotalPressure)*100.;
       
       DiffBSP[bar]= MathAbs(tempBuyRatio) - MathAbs(tempSellRatio);
       
       if(bar>=second)   DiffBSPAvg1[bar] = iAverage(bar, AvgPeriod1, DiffBSP);
       if(bar>=third)   DiffBSPAvg2[bar] = iAverage(bar, AvgPeriod2, DiffBSP);
       if(bar>=fourth && MnewBar)   DiffBSPAvg3[bar] = iAverage(bar, AvgPeriod3, DiffBSP);
       if(bar>=fifth && MnewBar)   DiffBSPAvg4[bar] = iAverage(bar, AvgPeriod4, DiffBSP);
        
     }  

   return(rates_total);
  }