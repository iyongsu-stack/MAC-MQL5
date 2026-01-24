//+------------------------------------------------------------------+
//|                                                       BSP6-2.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"


#property indicator_separate_window

#property indicator_buffers 10
#property indicator_plots   2

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE

#property indicator_color1  clrGreen
#property indicator_color2  clrRed

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID


#property indicator_width1  1
#property indicator_width2  1

#property indicator_level1 0.

#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3,XMA4,XMA5;

input ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume
input int                 AvgPeriod      = 2;            //Avg Period
input int                 AvgPeriod2      = 4;         //Avg2 Period   
input int                 LRPeriod        =5;          //LR Period              
input CXMA::Smooth_Method XMA_Method=(int)MODE_EMA; // Averaging method
input uint XLength1=5;                             // Depth of the first averaging
input uint XLength2=5;                             // Depth of the second averaging
input uint XLength3=5;                             // Depth of the third averaging                   
input int XPhase=15;                               // Smoothing parameter
input int Shift=0;                                 // Horizontal shift of the indicator in bars 



//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double SellPressure[], BuyPressure[], mVolume[],  
       AvgSellPressure[], AvgBuyPressure[], 
       DEMA_SellPressure[], DEMA_BuyPressure[],
       TEMA_BSPDiff[], LR_DEMA_SellPressure[], LR_DEMA_BuyPressure[];
       


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,LR_DEMA_BuyPressure,INDICATOR_DATA);
   SetIndexBuffer(1,LR_DEMA_SellPressure,INDICATOR_DATA);
   SetIndexBuffer(2,DEMA_BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,DEMA_SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,TEMA_BSPDiff,INDICATOR_CALCULATIONS);   
   SetIndexBuffer(5,AvgBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,AvgSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,mVolume,INDICATOR_CALCULATIONS);

/*  
   ArrayInitialize(DEMA_BuyPressure,0.);
   ArrayInitialize(DEMA_SellPressure,0.); 
   ArrayInitialize(TEMA_BSPDiff,0.); 
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

   int first, second, third,  fourth;
   double AvgBuyPressure2, AvgSellPressure2, EMA_BuyPressure, EMA_SellPressure;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=0;  
      second = first + AvgPeriod;  
      third = second + AvgPeriod2;  
      fourth = third + LRPeriod;
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

       double tempTotalPressure = high[bar] - low[bar];
       if(tempTotalPressure == 0.) tempTotalPressure = 0.00000001;

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
        
       AvgBuyPressure2= Average(bar, AvgPeriod2, BuyPressure);
       AvgSellPressure2= Average(bar, AvgPeriod2, SellPressure);

       EMA_BuyPressure=XMA1.XMASeries(third,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength1,AvgBuyPressure2,bar,false);
       EMA_SellPressure=XMA2.XMASeries(third,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength1,AvgSellPressure2,bar,false);      
       DEMA_BuyPressure[bar]=XMA3.XMASeries(third,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength2,EMA_BuyPressure,bar,false);
       DEMA_SellPressure[bar]=XMA4.XMASeries(third,prev_calculated,rates_total,(int)MODE_EMA,
                                    XPhase,XLength2,EMA_SellPressure,bar,false);
      
       TEMA_BSPDiff[bar] = DEMA_BuyPressure[bar] - DEMA_SellPressure[bar];
//       TEMA_BSPDiff[bar]=XMA5.XMASeries(third,prev_calculated,rates_total,XMA_Method,
//                                    XPhase,XLength3, DEMA_BSPDiff,bar,false);

     }       


  for(int bar=fourth; bar<rates_total; bar++)
     {
       LR_DEMA_BuyPressure[bar] = LinearRegression(bar, LRPeriod, DEMA_BuyPressure);
       LR_DEMA_SellPressure[bar] = LinearRegression(bar, LRPeriod, DEMA_SellPressure);

     }   
         
//----     
   return(rates_total);
  }
//+----------------------



double LinearRegression(int end, int ExChPeriod, const double &close[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=end+1-ExChPeriod;i<=end;i++)
         {
          sumX+=X;
          sumY+=close[i];
          sumXY+=X*close[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-(double)ExChPeriod*sumXY)/(MathPow(sumX,2)-(double)ExChPeriod*sumX2);
       b=(sumY-a*sumX)/(double)ExChPeriod;


      return(a);

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
