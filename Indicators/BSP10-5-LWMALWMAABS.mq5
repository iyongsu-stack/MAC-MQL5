//+------------------------------------------------------------------+
//|                                               BSP10-5-WMAWMA.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 9
#property indicator_plots   2

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrGreen,clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2


ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int                 LwmaPeriod1    = 12;          // wmaPeriod
input int                 LwmaPeriod2   = 200;          // WmaPeriod2


double SellPressure[], BuyPressure[],
       avg1SellPressure[], avg1BuyPressure[],
       SumSellPressure[], SumBuyPressure[], SumDiffPressure[], SumDiffPressureC[], WmaSumDiffPressure[];


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,WmaSumDiffPressure,INDICATOR_DATA);
   SetIndexBuffer(1,SumDiffPressure,INDICATOR_DATA);
   SetIndexBuffer(2,SumDiffPressureC,INDICATOR_COLOR_INDEX);   
   SetIndexBuffer(3,SumBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SumSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,avg1BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,avg1SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,SellPressure,INDICATOR_CALCULATIONS);
  
   string short_name = "BSPLWMALWMAABS("+ (string)LwmaPeriod1 +", "+ (string)LwmaPeriod2 + ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

   _lwma1.init(LwmaPeriod1);
   _lwma2.init(LwmaPeriod1);
   _lwma3.init(LwmaPeriod2);

 
     
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

   int first;
   double mVolume;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2; 
     }
   else
     { 
      first=prev_calculated-1;
     
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
       


       tempTotalPressure=1.;
       tempBuyRatio = tempBuyRatio/tempTotalPressure;
       tempSellRatio = tempSellRatio/tempTotalPressure;

       BuyPressure[bar] = (tempBuyRatio)*100.;
       SellPressure[bar] = (tempSellRatio)*100.; 

/*       
       BuyPressure[bar] = (tempBuyRatio * mVolume+BuyPressure[bar-1])/2.;
       SellPressure[bar] = (tempSellRatio * mVolume+SellPressure[bar-1])/2.; 
*/
       avg1BuyPressure[bar] = _lwma1.calculate(BuyPressure[bar],bar,rates_total);;
       avg1SellPressure[bar] = _lwma2.calculate(SellPressure[bar],bar,rates_total);;

       SumBuyPressure[bar] = SumBuyPressure[bar-1] + avg1BuyPressure[bar];
       SumSellPressure[bar] = SumSellPressure[bar-1] + avg1SellPressure[bar];
       SumDiffPressure[bar]=SumBuyPressure[bar] - SumSellPressure[bar];  
       SumDiffPressureC[bar] = (bar>0) ? (SumDiffPressure[bar]>SumDiffPressure[bar-1]) ? 0 : 
                                          (SumDiffPressure[bar]<SumDiffPressure[bar-1]) ? 1 : SumDiffPressure[bar-1] : 0;
    
       WmaSumDiffPressure[bar] = _lwma3.calculate(SumDiffPressure[bar],bar,rates_total);


     }
     
/*     
   for(int bar=second; bar<rates_total; bar++)
     {
            

     } 


   for(int bar=third; bar<rates_total; bar++)
     {
            

     } 
*/

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


class CLwma
{
   private :
      struct sLwmaArrayStruct
         {
            double value;
            double wsumm;
            double vsumm;
         };
      sLwmaArrayStruct m_array[];
      int              m_arraySize;
      int              m_period;
      double           m_weight;
   public :
      CLwma() : m_period(1), m_weight(1), m_arraySize(-1) {                     return; }
     ~CLwma()                                              { ArrayFree(m_array); return; }
    
     //
     //---
     //

     void init(int period)
     {
         m_period = (period>1) ? period : 1;
     }
        
     double calculate(double value, int i, int bars)
     {
        if (m_arraySize<bars)
          { m_arraySize=ArrayResize(m_array,bars+500); if (m_arraySize<bars) return(0); }

         //
         //
         //

         m_array[i].value=value;
               if (i>m_period)
               {
                     m_array[i].wsumm  = m_array[i-1].wsumm+value*m_period-m_array[i-1       ].vsumm;
                     m_array[i].vsumm  = m_array[i-1].vsumm+value         -m_array[i-m_period].value;
               }
               else
               {
                     m_weight          = 0;
                     m_array[i].wsumm  = 0;
                     m_array[i].vsumm  = 0;
                     for(int k=0, w=m_period; k<m_period && i>=k; k++,w--)
                     {
                           m_weight             += w;
                           m_array[i].wsumm += m_array[i-k].value*(double)w;
                           m_array[i].vsumm += m_array[i-k].value;
                     }
               }
               return(m_array[i].wsumm/m_weight);
      }  
};
CLwma _lwma1, _lwma2, _lwma3 ;