//+------------------------------------------------------------------+
//|                                           BSP9-EMA-SMOOTH-LR.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 13
#property indicator_plots   1

#property indicator_type1   DRAW_LINE

#property indicator_color1  clrYellow

#property indicator_style1  STYLE_SOLID

#property indicator_width1  1

#property indicator_level1 0.

#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3;

ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int                 AvgPeriod      = 2;         //Avg Period
input int                 EmaPeriod      = 7;         //EMA1 Period
input int                 LRPeriod       = 3;         //LR Period
input uint                XLength        = 2;         // Smooth Depth
input int                 XPhase         = 5;         // Smoothing parameter
input int                 XShift         = 0;         // Horizontal shift 




//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double BSPDiff[], LR_BSPDiff[],
       SellPressure[], BuyPressure[], TotalPressure[],
       avg_SellPressure[], avg_BuyPressure[],
       dema_SellPressure[], dema_BuyPressure[], dema_TotalPressure[],    
       ema_BuyPressure[], ema_SellPressure[], wma_TotalPressure[];

int    starting_bar;

//+------------------------------------------------------------------+  
void OnInit()
  {

   string str="";
   StringConcatenate(str,AvgPeriod,",",EmaPeriod, ",",LRPeriod);
   IndicatorSetString(INDICATOR_SHORTNAME,"("+str+")");

   SetIndexBuffer(0,LR_BSPDiff,INDICATOR_DATA);   
   SetIndexBuffer(1,BSPDiff,INDICATOR_CALCULATIONS);   
   SetIndexBuffer(2,dema_BuyPressure,INDICATOR_CALCULATIONS);   
   SetIndexBuffer(3,dema_SellPressure,INDICATOR_CALCULATIONS);  
   SetIndexBuffer(4,dema_TotalPressure,INDICATOR_CALCULATIONS);      
   SetIndexBuffer(5,ema_BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,ema_SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,wma_TotalPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,avg_BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,avg_SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,TotalPressure,INDICATOR_CALCULATIONS);
  
   starting_bar = 2+AvgPeriod+EmaPeriod;
 
     
//----
  }
  
  
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

double alpha1 = 2.0 / (1.0+(double)EmaPeriod);

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
   double mVolume, temp_BSPDiff, ema_BSPDiff, dema_BSPDiff;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;  
      second = first + AvgPeriod;  
      third = second + EmaPeriod;
      fourth = third + LRPeriod;
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
       

       
       tempTotalPressure=tempSellRatio + tempBuyRatio;
       if (tempTotalPressure == 0.) tempTotalPressure = 0.00000001;       
       tempBuyRatio = tempBuyRatio/tempTotalPressure;
       tempSellRatio = tempSellRatio/tempTotalPressure;
       
       BuyPressure[bar] = tempBuyRatio * mVolume;
       SellPressure[bar] = tempSellRatio * mVolume;
       TotalPressure[bar] = BuyPressure[bar] + SellPressure[bar];
     } 

  for(int bar=second; bar<rates_total; bar++)
     {
        
       avg_BuyPressure[bar]= Average(bar, AvgPeriod, BuyPressure);
       avg_SellPressure[bar]= Average(bar, AvgPeriod, SellPressure);
     }  

     
     
  for(int bar=third; bar<rates_total; bar++)
     {
        
       ema_BuyPressure[bar]= iEma(ema_BuyPressure, avg_BuyPressure, bar, alpha1);
       ema_SellPressure[bar]= iEma(ema_SellPressure, avg_SellPressure, bar, alpha1);

       dema_BuyPressure[bar]= iEma(dema_BuyPressure, ema_BuyPressure, bar, alpha1);
       dema_SellPressure[bar]=iEma(dema_SellPressure, ema_SellPressure, bar, alpha1);     

       wma_TotalPressure[bar] = iWma(bar, EmaPeriod, TotalPressure);
       dema_TotalPressure[bar] = iEma(dema_TotalPressure, wma_TotalPressure, bar, alpha1);
       
       temp_BSPDiff = (dema_BuyPressure[bar] - dema_SellPressure[bar])/*/dema_TotalPressure[bar]*100.*/;

       ema_BSPDiff  = XMA1.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength,temp_BSPDiff, bar,false);
       dema_BSPDiff = XMA2.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength,ema_BSPDiff,bar,false);
       BSPDiff[bar] = XMA3.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength,dema_BSPDiff,bar,false);
     }       

  for(int bar=fourth; bar<rates_total; bar++)
     {        
       LR_BSPDiff[bar]= LinearRegression(bar,LRPeriod, BSPDiff);
     }       
          
//----     
   return(rates_total);
  }
//+----------------------

double iEma(const double &t2_Array[], const double &t1_Array[], int r, double alp)
{
   return(alp*t1_Array[r]+(1-alp)*t2_Array[r-1]);
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

double LinearRegression(int end, int period, const double &close[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=end+1-period;i<=end;i++)
         {
          sumX+=X;
          sumY+=close[i];
          sumXY+=X*close[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-period*sumXY)/(MathPow(sumX,2)-period*sumX2);
       b=(sumY-a*sumX)/period;


      return(a);

}