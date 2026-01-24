//+------------------------------------------------------------------+
//|                                                      BSPV7-3.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"


#property indicator_separate_window

#property indicator_buffers 8
#property indicator_plots   3

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
//#property indicator_type4   DRAW_LINE
//#property indicator_type5   DRAW_LINE



#property indicator_color1  clrGreen
#property indicator_color2  clrRed
#property indicator_color3  clrYellow
//#property indicator_color4  clrPink
//#property indicator_color5  clrYellow

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID
//#property indicator_style4  STYLE_SOLID
//#property indicator_style5  STYLE_SOLID


#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
//#property indicator_width4  2
//#property indicator_width5  2

#property indicator_level1 0.



input ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume

input int                 AvgPeriod      = 14;            //Avg Period
input int                 AvgPeriod2      = 7;         //EMA1 Period                 
input double              ThreshHold     = 0.;     //ThreshHold
//int                        XPhase         = 15;           // Smoothing parameter



//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double SellPressure[], BuyPressure[], mVolume[], AvgBSPDiff2[], 
       AvgSellPressure[], AvgBuyPressure[], 
       AvgSellPressure2[], AvgBuyPressure2[];
/*       EMASPressure[], EMABPressure[], EMAVolume[],
       NSPressure[], NBPressure[], NVolume[],
       SellPower[], BuyPower[], EMASellPower[], EMABuyPower[], BSPowerDiff[];

*/

//+------------------------------------------------------------------+  
void OnInit()
  {

/*
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
   SetIndexBuffer(10,EMAVolume,INDICATOR_CALCULATIONS); */  
   SetIndexBuffer(0,AvgBuyPressure2,INDICATOR_DATA);
   SetIndexBuffer(1,AvgSellPressure2,INDICATOR_DATA);
   SetIndexBuffer(2,AvgBSPDiff2,INDICATOR_DATA);   
   SetIndexBuffer(3,AvgBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,AvgSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,mVolume,INDICATOR_CALCULATIONS);
  
/*   
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
   ArrayInitialize(EMAVolume,0.);       */  
   ArrayInitialize(AvgBuyPressure2,0.);
   ArrayInitialize(AvgSellPressure2,0.); 
   ArrayInitialize(AvgBSPDiff2,0.); 
   ArrayInitialize(AvgBuyPressure,0.);
   ArrayInitialize(AvgSellPressure,0.); 
   ArrayInitialize(BuyPressure,0.);
   ArrayInitialize(SellPressure,0.);
   ArrayInitialize(mVolume,0.);

 
     
//----
  }
  
  
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

double alpha1 = 2.0 / (1.0+MathSqrt(AvgPeriod2));


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
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;  
      second = first + AvgPeriod;  
      third = second + AvgPeriod2;  
     }
   else
     { 
      first=prev_calculated-1; 
      second = prev_calculated -1;
      third = prev_calculated -1;
     } 


//---- The main loop of the indicator calculation
   for(int bar=first; bar<rates_total; bar++)
     {
        
       if(VolumeType == VOLUME_TICK) mVolume[bar] = (double)tick_volume[bar];
       else mVolume[bar] = (double)volume[bar];


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
       
       BuyPressure[bar] = tempBuyRatio * mVolume[bar];
       SellPressure[bar] = tempSellRatio * mVolume[bar];
     } 
     
  for(int bar=second; bar<rates_total; bar++)
     {
        
       AvgBuyPressure[bar]= Average(bar, AvgPeriod, BuyPressure);
       AvgSellPressure[bar]= Average(bar, AvgPeriod, SellPressure);
     }  
     
  for(int bar=third; bar<rates_total; bar++)
     {
        
       AvgBuyPressure2[bar]= iEma(AvgBuyPressure2, AvgBuyPressure, bar, alpha1);
       AvgSellPressure2[bar]= iEma(AvgSellPressure2, AvgSellPressure, bar, alpha1);
       if(MathAbs(AvgBuyPressure2[bar])<=ThreshHold) AvgBuyPressure2[bar] = 0.;
       if(MathAbs(AvgSellPressure2[bar])<= ThreshHold) AvgSellPressure2[bar] = 0.;       
       AvgBSPDiff2[bar] = AvgBuyPressure2[bar] - AvgSellPressure2[bar];
     }       
/*     
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
*/     
         
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
