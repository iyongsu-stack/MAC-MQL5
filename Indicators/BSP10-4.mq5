//+------------------------------------------------------------------+
//|                                                      BSP10-4.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"
#property indicator_separate_window

#property indicator_separate_window

#property indicator_buffers 11
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
/*
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
*/
ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


enum Session
{
   AsiaSession,
   EuroSession,
   AmericaSession,
   NoTradingSession,
};

Session LastSession=NoTradingSession, CurSession=NoTradingSession;

input int                 WmaPeriod1    = 40;          // EmaPeriod1
input int                 WmaPeriod2    = 40;          // EmaPeriod2
input int                 WmaPeriod3    = 40;          // EmaPeriod3
input int                 AsiaTime      = 2;            // AsiaSession Time
input int                 EuroTime      = 8;            // EuroSession Time
input int                 AmericaTime   = 14;           // AmericaSession Time
input int                 NoTradingTime = 22;           // NoTradingSession Time
input bool                ResetEverySession = false;    // Reset per Session


double SellPressure[], BuyPressure[],
       avg1SellPressure[], avg1BuyPressure[],
       avg2SellPressure[], avg2BuyPressure[],
       avg3SellPressure[], avg3BuyPressure[],       
       SumSellPressure[], SumBuyPressure[], SumDiffPressure[];


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,SumDiffPressure,INDICATOR_DATA);
   SetIndexBuffer(1,SumBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,SumSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,avg1BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,avg1SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,avg2BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,avg2SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,avg3BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,avg3SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,SellPressure,INDICATOR_CALCULATIONS);
  
 
     
//----
  }
  
  
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

double alpha1 = 2.0 / (1.0+(double)WmaPeriod1);


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
   double mVolume;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2; 
      second = first + WmaPeriod1; 
      third = second + WmaPeriod2; 
      fourth = third + WmaPeriod3; 
      
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
       


       tempTotalPressure=MathAbs(high[bar] - low[bar]);
       if (tempTotalPressure == 0.) tempTotalPressure = 100.;       
       tempBuyRatio = tempBuyRatio/tempTotalPressure;
       tempSellRatio = tempSellRatio/tempTotalPressure;
       
       BuyPressure[bar] = (tempBuyRatio * mVolume+BuyPressure[bar-1])/2.;
       SellPressure[bar] = (tempSellRatio * mVolume+SellPressure[bar-1])/2.; 


/*
       tempTotalPressure=tempSellRatio + tempBuyRatio;
       if (tempTotalPressure == 0.) tempTotalPressure = 0.00000001;       
       tempBuyRatio = tempBuyRatio/tempTotalPressure;
       tempSellRatio = tempSellRatio/tempTotalPressure;
       
       BuyPressure[bar] = tempBuyRatio * mVolume;
       SellPressure[bar] = tempSellRatio * mVolume;
       
*/       
     }
     
     
   for(int bar=second; bar<rates_total; bar++)
     {
            
       avg1BuyPressure[bar] = iWma(bar, WmaPeriod1, BuyPressure);
       avg1SellPressure[bar] = iWma(bar, WmaPeriod1, SellPressure);

     } 


   for(int bar=third; bar<rates_total; bar++)
     {
            
       avg2BuyPressure[bar] = iWma(bar, WmaPeriod2, avg1BuyPressure);
       avg2SellPressure[bar] = iWma(bar, WmaPeriod2, avg1SellPressure);

     } 
     
     for(int bar=fourth; bar<rates_total; bar++)
     {
            
       avg3BuyPressure[bar] = iWma(bar, WmaPeriod3, avg2BuyPressure);
       avg3SellPressure[bar] = iWma(bar, WmaPeriod3, avg2SellPressure);

       datetime curTime=time[bar];
       CurSession = WhatIsSession(curTime);
      
       if( (LastSession != CurSession) && (ResetEverySession || (CurSession == AsiaSession)) ) 
       {
         SumBuyPressure[bar] = avg3BuyPressure[bar];
         SumSellPressure[bar] = avg3SellPressure[bar];
       }
            
       else
       {
         SumBuyPressure[bar] = SumBuyPressure[bar-1] + avg3BuyPressure[bar];
         SumSellPressure[bar] = SumSellPressure[bar-1] + avg3SellPressure[bar];
       }
/*
       SumBuyPressure[bar] = SumBuyPressure[bar-1] + avg3BuyPressure[bar];
       SumSellPressure[bar] = SumSellPressure[bar-1] + avg3SellPressure[bar];
*/
       SumDiffPressure[bar]=SumBuyPressure[bar] - SumSellPressure[bar];      

       LastSession = CurSession;  

     } 

   return(rates_total);
  }
//+----------------------

Session WhatIsSession(datetime m_Time)
{

   MqlDateTime currTime;
   TimeToStruct(m_Time, currTime);
   int hour0 = currTime.hour;
   
   if( (hour0>=AsiaTime) && (hour0<EuroTime) ) return(AsiaSession);
   if( (hour0>=EuroTime) && (hour0<AmericaTime)) return(EuroSession);
   if( (hour0>=AmericaTime) && (hour0<NoTradingTime)) return(AmericaSession);
   return(NoTradingSession);
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
