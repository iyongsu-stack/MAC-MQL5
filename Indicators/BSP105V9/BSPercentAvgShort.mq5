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

#property indicator_buffers 9
#property indicator_plots  7 

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_COLOR_LINE

#property indicator_color1  clrWhite
#property indicator_color2  clrWhite
#property indicator_color3  clrWhite
#property indicator_color4  clrWhite
#property indicator_color5  clrWhite
#property indicator_color6  clrWhite
#property indicator_color7  clrGreen,clrRed

#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DASH
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID
#property indicator_style5  STYLE_DASH
#property indicator_style6  STYLE_DOT
#property indicator_style7  STYLE_SOLID


#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  2

input int                 AvgPeriod    = 30;          // AvgPeriods  
input int                 StdPeriod    = 5000;        // StdPeriod
input double              MultiFactor1  = 1.0;        // MultiFactor1
input double              MultiFactor2  = 2.0;        // MultiFactor2
input double              MultiFactor3  = 3.0;        // MultiFactor3

ENUM_APPLIED_VOLUME  VolumeType = VOLUME_TICK;    // Volume


double DiffBSP[], DiffBSPAvg[], DiffBSPColor[], up3StdDiffBSP[], up2StdDiffBSP[], up1StdDiffBSP[], 
                                down3StdDiffBSP[], down2StdDiffBSP[], down1StdDiffBSP[];
double ToPoint;       

//+------------------------------------------------------------------+  
void OnInit()
  {

   ArrayInitialize(DiffBSP,0.0);
   ArrayInitialize(DiffBSPAvg,0.0);
   ArrayInitialize(DiffBSPColor,0);
   ArrayInitialize(up3StdDiffBSP,0.0);
   ArrayInitialize(up2StdDiffBSP,0.0);
   ArrayInitialize(up1StdDiffBSP,0.0);
   ArrayInitialize(down1StdDiffBSP,0.0);
   ArrayInitialize(down2StdDiffBSP,0.0);
   ArrayInitialize(down3StdDiffBSP,0.0);

   SetIndexBuffer(0, up3StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(1, up2StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(2, up1StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(3, down1StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(4, down2StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(5, down3StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(6, DiffBSPAvg,INDICATOR_DATA);
   SetIndexBuffer(7, DiffBSPColor,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(8, DiffBSP,INDICATOR_CALCULATIONS);

   string short_name = "BSPercentAvgShort("+ (string)AvgPeriod + ", "  + (string)StdPeriod + ", " + 
                  (string)MultiFactor1 + ", " + (string)MultiFactor2 + ", " + (string)MultiFactor3 + ")";

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

   int first, second, third;
   double mVolume, standardDeviation;
   bool MnewBar = isNewBar(_Symbol);


   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;  
      second = first + AvgPeriod;
      third = first + StdPeriod;
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
 

       tempTotalPressure=( MathAbs(tempBuyRatio) + MathAbs(tempSellRatio) );
       if(tempTotalPressure == 0) tempTotalPressure = 0.001;
       tempBuyRatio = MathAbs(tempBuyRatio)/MathAbs(tempTotalPressure)*100.;
       tempSellRatio = MathAbs(tempSellRatio)/MathAbs(tempTotalPressure)*100.;
       
       DiffBSP[bar]= MathAbs(tempBuyRatio) - MathAbs(tempSellRatio);
       
       if(bar>=second)   DiffBSPAvg[bar] = iAverage(bar, AvgPeriod, DiffBSP);
       DiffBSPColor[bar] = (bar>0) ? (DiffBSPAvg[bar]>DiffBSPAvg[bar-1]) ? 0 : (DiffBSPAvg[bar]<DiffBSPAvg[bar-1]) ? 1 : DiffBSPAvg[bar-1] : 0;  

       if((bar>=third) && MnewBar)
       {
          standardDeviation = StdDev3((bar-1), StdPeriod, DiffBSPAvg);

          up1StdDiffBSP[bar]   =   standardDeviation * MultiFactor1;
          down1StdDiffBSP[bar] =  -standardDeviation * MultiFactor1;

          up2StdDiffBSP[bar]   =   standardDeviation * MultiFactor2;
          down2StdDiffBSP[bar] =  -standardDeviation * MultiFactor2;

          up3StdDiffBSP[bar]   =   standardDeviation * MultiFactor3;
          down3StdDiffBSP[bar] =  -standardDeviation * MultiFactor3;
       }  

     }  

   return(rates_total);
  }