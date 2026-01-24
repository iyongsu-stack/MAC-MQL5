//+------------------------------------------------------------------+
//|                                                        BSPV5.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"



#property indicator_separate_window
//---- one buffer is used for calculation and drawing of the indicator
#property indicator_buffers 16
//---- one plot is used
#property indicator_plots   3
//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
//---- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
//#property indicator_type4   DRAW_LINE
//#property indicator_type5   DRAW_LINE



//---- Red color is used as the color of the indicator line
#property indicator_color1  clrYellow
#property indicator_color2  clrGreen
#property indicator_color3  clrRed
//#property indicator_color4  clrPink
//#property indicator_color5  clrYellow

//---- the line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID
//#property indicator_style4  STYLE_SOLID
//#property indicator_style5  STYLE_SOLID


//---- indicator 1 line width is equal to 1
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
//#property indicator_width4  2
//#property indicator_width5  2

#property indicator_level1 0.


//---- displaying the indicator label
//#property indicator_label1  "Ticks"

/*
#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3, XMA4, XMA5;
CXMA::Smooth_Method XMA_Method=MODE_EMA;     // Averaging method

*/


input ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume

input int                 AvgPeriod      = 3;            //Avg Period
input int                 EMAPeriod      = 1400;         //EMA1 Period                 
input int                 EMA2Period     = 21;           //EMA2 Period
//int                        XPhase         = 15;           // Smoothing parameter



//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double SellPressure[], BuyPressure[], mVolume[], 
       AvgSellPressure[], AvgBuyPressure[],
       EMASPressure[], EMABPressure[], EMAVolume[],
       NSPressure[], NBPressure[], NVolume[],
       SellPower[], BuyPower[], EMASellPower[], EMABuyPower[], BSPowerDiff[];



//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,BSPowerDiff,INDICATOR_DATA);
   SetIndexBuffer(1,EMABuyPower,INDICATOR_DATA);
   SetIndexBuffer(2,EMASellPower,INDICATOR_DATA);
   SetIndexBuffer(3,BuyPower,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SellPower,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,NBPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,NSPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,NVolume,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,EMABPressure,INDICATOR_DATA);
   SetIndexBuffer(9,EMASPressure,INDICATOR_DATA);
   SetIndexBuffer(10,EMAVolume,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,AvgBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,AvgSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(15,mVolume,INDICATOR_CALCULATIONS);
  
   
   ArrayInitialize(BSPowerDiff,0.);
   ArrayInitialize(EMASellPower,0.);
   ArrayInitialize(EMABuyPower,0.);
   ArrayInitialize(BuyPower,0.);
   ArrayInitialize(SellPower,0.);
   ArrayInitialize(NBPressure,0.);
   ArrayInitialize(NSPressure,0.);
   ArrayInitialize(NVolume,0.);
   ArrayInitialize(EMABPressure,0.);
   ArrayInitialize(EMASPressure,0.);
   ArrayInitialize(EMAVolume,0.);
   ArrayInitialize(BuyPressure,0.);
   ArrayInitialize(SellPressure,0.);
   ArrayInitialize(AvgBuyPressure,0.);
   ArrayInitialize(AvgSellPressure,0.);
   ArrayInitialize(mVolume,0.);

 
     
//----
  }
  
  
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

double alpha1 = 2.0 / (1.0+MathSqrt(EMAPeriod));
double alpha2 = 2.0 / (1.0+MathSqrt(EMA2Period));


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
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=0;  
      second = first + AvgPeriod;  
      third = second + EMAPeriod;  
      fourth = third + EMA2Period;             
     }
   else
     { 
      first=prev_calculated-1; 
      second = prev_calculated -1;
      third = prev_calculated -1;
      fourth = prev_calculated -1;
     } 


//---- The main loop of the indicator calculation
   for(int bar=first; bar<rates_total; bar++)
     {
        
       if(VolumeType == VOLUME_TICK) mVolume[bar] = (double)tick_volume[bar];
       else mVolume[bar] = (double)volume[bar];

       SellPressure[bar] =  -(high[bar] - close[bar]);
       BuyPressure[bar] = close[bar] - low[bar];
     } 
     
  for(int bar=second; bar<rates_total; bar++)
     {
        
       AvgBuyPressure[bar]= Average(bar, AvgPeriod, BuyPressure);
       AvgSellPressure[bar]= Average(bar, AvgPeriod, SellPressure);
     }  
     
  for(int bar=third; bar<rates_total; bar++)
     {
        
       EMABPressure[bar]= iEma(EMABPressure, AvgBuyPressure, bar, alpha1);
       if(EMABPressure[bar]==0.)  EMABPressure[bar]=0.0000001;
       NBPressure[bar] = AvgBuyPressure[bar]/EMABPressure[bar];

       EMASPressure[bar]= iEma(EMASPressure, AvgSellPressure, bar, alpha1);
       if(EMASPressure[bar]==0.)  EMASPressure[bar]=0.0000001;
       NSPressure[bar] = AvgSellPressure[bar]/EMASPressure[bar];

       EMAVolume[bar]= iEma(EMAVolume, mVolume, bar, alpha1);
       if(EMAVolume[bar] == 0.) EMAVolume[bar]=1.;
       NVolume[bar] = mVolume[bar]/EMAVolume[bar];
       
       BuyPower[bar] = NBPressure[bar] * NVolume[bar];
       SellPower[bar] = NSPressure[bar] * NVolume[bar];
       
     }  
     
  for(int bar=fourth; bar<rates_total; bar++)
     {
        
       EMABuyPower[bar] = iEma(EMABuyPower, BuyPower, bar, alpha2);
       EMASellPower[bar] = iEma(EMASellPower, SellPower, bar, alpha2);
       BSPowerDiff[bar] = EMABuyPower[bar] - EMASellPower[bar];
       
     }       
     
         
//----     
   return(rates_total);
  }
//+----------------------


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
   return(t2_Array[r-1]+alp*(t1_Array[r]-t2_Array[r-1]));
}

/*
   for(int avgbar=forth; avgbar<rates_total; avgbar++)
     {
        ema_p3AvgBuffer[avgbar]= iEma( ema_p3AvgBuffer, p3AvgBuffer, avgbar);
                
     }
*/