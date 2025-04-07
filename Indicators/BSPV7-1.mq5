//+------------------------------------------------------------------+
//|                                                      BSPV7-1.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"



#property indicator_separate_window

#property indicator_buffers 11
#property indicator_plots   2


#property indicator_type1 DRAW_COLOR_HISTOGRAM
#property indicator_color1 Gray,Lime,Magenta
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2

#property indicator_type2   DRAW_LINE

#property indicator_color2  clrYellow

#property indicator_style2  STYLE_SOLID

#property indicator_width2  1




input ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume

input int                 AvgPeriod      = 3;            //Avg Period
input int                 AvgPeriod2      = 14;         //EMA1 Period 
input int                 VolAvgPeriod    =20;           // Volume Avg Period
input double              Sensitivity     = 1.;         //Sensitivity                



double SellPressure[], BuyPressure[], mVolume[], AvgBSPDiff2[], 
       AvgSellPressure[], AvgBuyPressure[], 
       AvgSellPressure2[], AvgBuyPressure2[], Trend[], ColorTrend[], IndVolume[];


//+------------------------------------------------------------------+  
void OnInit()
  {
   SetIndexBuffer(0,Trend,INDICATOR_DATA);
   SetIndexBuffer(1,ColorTrend,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,IndVolume,INDICATOR_DATA);   
   SetIndexBuffer(3,AvgBuyPressure2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,AvgSellPressure2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,AvgBSPDiff2,INDICATOR_CALCULATIONS);   
   SetIndexBuffer(6,AvgBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,AvgSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,mVolume,INDICATOR_CALCULATIONS);
   
  
/*
   ArrayInitialize(AvgBuyPressure2,0.);
   ArrayInitialize(AvgSellPressure2,0.); 
   ArrayInitialize(AvgBSPDiff2,0.); 
   ArrayInitialize(AvgBuyPressure,0.);
   ArrayInitialize(AvgSellPressure,0.); 
   ArrayInitialize(BuyPressure,0.);
   ArrayInitialize(SellPressure,0.);
   ArrayInitialize(mVolume,0.);

*/
     
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

   int first, second, third, forth;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=0;  
      second = first + AvgPeriod;  
      third = second + AvgPeriod2; 
      forth = first + VolAvgPeriod; 
     }
   else
     { 
      first=prev_calculated-1; 
      second = prev_calculated -1;
      third = prev_calculated -1;
      forth = prev_calculated -1;
     } 


//---- The main loop of the indicator calculation
   for(int bar=first; bar<rates_total; bar++)
     {
        
       if(VolumeType == VOLUME_TICK) mVolume[bar] = (double)tick_volume[bar];
       else mVolume[bar] = (double)volume[bar];

       double tempTotalPressure = high[bar] - low[bar];
       if(tempTotalPressure == 0.) tempTotalPressure = 0.0000001;

       double tempBuyRatio = (close[bar] - low[bar])/tempTotalPressure;
       double tempSellRatio = (high[bar] - close[bar])/tempTotalPressure;

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
       AvgBSPDiff2[bar] = AvgBuyPressure2[bar] - AvgSellPressure2[bar];
       
       Trend[bar]=MathAbs(AvgBSPDiff2[bar]);

       if(AvgBSPDiff2[bar]>0) ColorTrend[bar]=1;
       if(AvgBSPDiff2[bar]<0) ColorTrend[bar]=2;
       
     }   
     
  for(int bar=forth; bar<rates_total; bar++)
     {
        IndVolume[bar] = Sensitivity*Average(bar, VolAvgPeriod, mVolume)/2.0;       
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
