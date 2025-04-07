//+------------------------------------------------------------------+
//|                                              BSP7-7-SmoothLR.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"

#property indicator_separate_window




#property indicator_buffers 11
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
//#property indicator_type2   DRAW_LINE
//#property indicator_type3   DRAW_LINE
//#property indicator_type4   DRAW_LINE
//#property indicator_type5   DRAW_LINE



#property indicator_color1  clrYellow
//#property indicator_color2  clrWhite
//#property indicator_color3  clrGreen
//#property indicator_color4  clrRed
//#property indicator_color5  clrYellow

#property indicator_style1  STYLE_SOLID
//#property indicator_style2  STYLE_SOLID
//#property indicator_style3  STYLE_SOLID
//#property indicator_style4  STYLE_SOLID


#property indicator_width1  1
//#property indicator_width2  1
//#property indicator_width3  1
//#property indicator_width4  1

#property indicator_level1 0.


#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3,XMA4, XMA5, XMA6, XMA7;



input ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume

input int                 AvgPeriod      = 7;            //Avg Period
input int                 EmaPeriod      = 7;         //EMA1 Period
input int                 AvgPeriod2     = 28;         //2'nd Avg Period
input int                 LRPeriod       = 2;         //LR Period 
input double              ThreshHold     = 0.;     //ThreshHold
input uint XLength1=2;                             // Smooth Depth of Buy Pressure
input uint XLength2=2;                             // Smooth Depth of Sell Pressure
input uint XLength3=2;                             // Smooth Depth of BSPDiff                   
input int XPhase1=5;                               // Smoothing parameter of BuySell Pressure
input int XPhase2=5;                               // Smoothing parameter of BSPDiff
input int Shift=0;                                 // Horizontal shift of the indicator in bars 

input CXMA::Smooth_Method XMA_Method=(int)MODE_EMA; // Averaging method

int starting_bar;


double SellPressure[], BuyPressure[], mVolume[], 
       AvgSellPressure[], AvgBuyPressure[], 
       tema_SellPressure[], tema_BuyPressure[], 
       BSPDiff[], LR_AvgBSPDiff[],
       ema_BuyPressure[], ema_SellPressure[];


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,LR_AvgBSPDiff,INDICATOR_DATA);   
   SetIndexBuffer(1,BSPDiff,INDICATOR_CALCULATIONS);   
   SetIndexBuffer(2,tema_BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,tema_SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,AvgBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,AvgSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,mVolume,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,ema_BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,ema_SellPressure,INDICATOR_CALCULATIONS);
  
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

   int first, second, third, fourth;
   double dema_BuyPressure, dema_SellPressure,
          temp_BSPDiff, ema_BSPDiff, dema_BSPDiff;
   
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
                                    XPhase1,XLength1,ema_BuyPressure[bar],bar,false);
       dema_SellPressure=XMA2.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase1,XLength1,ema_SellPressure[bar],bar,false);      
       tema_BuyPressure[bar]=XMA3.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase1,XLength2,dema_BuyPressure,bar,false);
       tema_SellPressure[bar]=XMA4.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase1,XLength2,dema_SellPressure,bar,false);






       if(MathAbs(tema_BuyPressure[bar])<=ThreshHold) tema_BuyPressure[bar] = 0.;
       if(MathAbs(tema_SellPressure[bar])<= ThreshHold) tema_SellPressure[bar] = 0.;       

       temp_BSPDiff = tema_BuyPressure[bar] - tema_SellPressure[bar];

       ema_BSPDiff  = XMA5.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase2,XLength3,temp_BSPDiff, bar,false);
       dema_BSPDiff = XMA6.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase2,XLength3,ema_BSPDiff,bar,false);
       BSPDiff[bar] = XMA7.XMASeries(starting_bar,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase2,XLength3,dema_BSPDiff,bar,false);
     }       

  for(int bar=fourth; bar<rates_total; bar++)
     {        
       LR_AvgBSPDiff[bar]= LinearRegression(bar,LRPeriod, BSPDiff);
     }       


         
//----     
   return(rates_total);
  }
//+----------------------



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

