//+------------------------------------------------------------------+
//|                                                       BSP7-6.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"



#property indicator_separate_window

#property indicator_buffers 14
#property indicator_plots   4

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
//#property indicator_type5   DRAW_LINE



#property indicator_color1  clrYellow
#property indicator_color2  clrWhite
#property indicator_color3  clrGreen
#property indicator_color4  clrRed
//#property indicator_color5  clrYellow

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID


#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1

#property indicator_level1 0.

#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3,XMA4;


input ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int                 AvgPeriod      = 7;            //Avg Period
input int                 EmaPeriod      = 7;         //EMA1 Period
input int                 AvgPeriod2     = 35;         //2'nd Avg Period
input int                 StdPeriod      = 1440;         //Std Period 
input double              StdMultiFactor = 1.0;        //Std Multi FActor                
input double              ThreshHold     = 0.;     //ThreshHold
input uint XLength1=2;                             // Depth of the first averaging
input uint XLength2=2;                             // Depth of the second averaging
input int XPhase=7;                               // Smoothing parameter
input int Shift=0;                                 // Horizontal shift of the indicator in bars 

CXMA::Smooth_Method XMA_Method=(int)MODE_EMA; // Averaging method

int starting_bar;

//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double BSPDiff[], AvgBSPDiff[], Up_AvgBSPDiff[], Down_AvgBSPDiff[],
       SellPressure[], BuyPressure[], mVolume[], 
       AvgSellPressure[], AvgBuyPressure[], 
       tema_SellPressure[], tema_BuyPressure[],      
       ema_BuyPressure[], ema_SellPressure[], std_AvgBSPDiff[];


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,BSPDiff,INDICATOR_DATA);   
   SetIndexBuffer(1,AvgBSPDiff,INDICATOR_DATA);   
   SetIndexBuffer(2,Up_AvgBSPDiff,INDICATOR_DATA);  
   SetIndexBuffer(3,Down_AvgBSPDiff,INDICATOR_DATA);      
   SetIndexBuffer(4,tema_BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,tema_SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,AvgBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,AvgSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,mVolume,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,ema_BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,ema_SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,std_AvgBSPDiff,INDICATOR_CALCULATIONS);
  
   starting_bar = 2+AvgPeriod+EmaPeriod;
 
     
//----
  }
  
  
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

double alpha1 = 2.0 / (1.0+MathSqrt(EmaPeriod));


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

   int first, second, third, fourth, fifth, sixth;
   double standardDeviation, dema_BuyPressure, dema_SellPressure;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;  
      second = first + AvgPeriod;  
      third = second + EmaPeriod; 
      fourth = third + AvgPeriod2;
      fifth = third + StdPeriod; 
      sixth = fifth + StdPeriod;
     }
   else
     { 
      first=prev_calculated-1; 
      second = first;
      third = first;
      fourth = first;
      fifth = first;
      sixth = first;
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
        
       ema_BuyPressure[bar]= iEma(ema_BuyPressure, AvgBuyPressure, bar, alpha1);
       ema_SellPressure[bar]= iEma(ema_SellPressure, AvgSellPressure, bar, alpha1);

       dema_BuyPressure=XMA1.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength1,ema_BuyPressure[bar],bar,false);
       dema_SellPressure=XMA2.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength1,ema_SellPressure[bar],bar,false);      
       tema_BuyPressure[bar]=XMA3.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength2,dema_BuyPressure,bar,false);
       tema_SellPressure[bar]=XMA4.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength2,dema_SellPressure,bar,false);






       if(MathAbs(tema_BuyPressure[bar])<=ThreshHold) tema_BuyPressure[bar] = 0.;
       if(MathAbs(tema_SellPressure[bar])<= ThreshHold) tema_SellPressure[bar] = 0.;       
       BSPDiff[bar] = tema_BuyPressure[bar] - tema_SellPressure[bar];
     }       

  for(int bar=fourth; bar<rates_total; bar++)
     {        
       AvgBSPDiff[bar]= Average(bar, AvgPeriod2, BSPDiff);
     }       

  for(int bar=fifth; bar<rates_total; bar++)
     {        
       std_AvgBSPDiff[bar]= Average(bar, StdPeriod, BSPDiff);
     }       



  for(int bar=sixth; bar<rates_total; bar++)
     {        
       standardDeviation = StdDev(bar, StdPeriod, std_AvgBSPDiff, BSPDiff);
       Up_AvgBSPDiff[bar] = AvgBSPDiff[bar] + standardDeviation * StdMultiFactor;
       Down_AvgBSPDiff[bar] = AvgBSPDiff[bar] - standardDeviation * StdMultiFactor;
     }       

         
//----     
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



double iEma(const double &t2_Array[], const double &t1_Array[], int r, double alp)
{
   return(t2_Array[r-1]+alp*(t1_Array[r]-t2_Array[r-1]));
}

