//+------------------------------------------------------------------+
//|                                    BSP10-4-LWMA-PRESSURE-STD.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 10
#property indicator_plots   3

#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_type2   DRAW_LINE
#property indicator_color2  clrWhite
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrWhite
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

enum m_Trend
{
   UpTrend,
   DownTrend,
   NoTrend,
};
m_Trend CurTrend=NoTrend, LastTrend=NoTrend;

ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume

input int                inpPeriod      =  7;         // Period
input int                stdPeriod      = 1440;       // StdPeriod
input double             stdMultiFactor = 1.0;        // StdMultiFactor



double SellPressure[], BuyPressure[], Pressure[],
       SumSellPressure[], SumBuyPressure[], SumDiffPressure[], 
       LWMAVal[], LWMAValC[], UpStdVal[], DownStdVal[];


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,Pressure,INDICATOR_DATA);
   SetIndexBuffer(1,UpStdVal,INDICATOR_DATA);
   SetIndexBuffer(2,DownStdVal,INDICATOR_DATA);   
   SetIndexBuffer(3,LWMAVal,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,LWMAValC,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,SumDiffPressure,INDICATOR_DATA);
   SetIndexBuffer(6,SumBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,SumSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,SellPressure,INDICATOR_CALCULATIONS);
  
   _lwma.init(inpPeriod);
     
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

   int first, second, ResetBar=0;
   double mVolume, standardDeviation;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
   {
      first=2; 
      second = first + stdPeriod;      
   }
   else
   { 
      first=prev_calculated-1;  
      second = first;    
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
       
       BuyPressure[bar] = (tempBuyRatio * mVolume+BuyPressure[bar-1])/2.;
       SellPressure[bar] = (tempSellRatio * mVolume+SellPressure[bar-1])/2.; 
       
       SumBuyPressure[bar] = SumBuyPressure[bar-1] + BuyPressure[bar];
       SumSellPressure[bar] = SumSellPressure[bar-1] + SellPressure[bar];
       
       SumDiffPressure[bar]=SumBuyPressure[bar] - SumSellPressure[bar];      

       LWMAVal[bar]  = _lwma.calculate(SumDiffPressure[bar],bar,rates_total);
       LWMAValC[bar] = (bar>0) ? (LWMAVal[bar]>LWMAVal[bar-1]) ? 0 : (LWMAVal[bar]<LWMAVal[bar-1]) ? 1 : LWMAVal[bar-1] : 0;

       if(LWMAVal[bar]>LWMAVal[bar-1]) CurTrend = UpTrend;
       else if(LWMAVal[bar]<LWMAVal[bar-1]) CurTrend = DownTrend;
       else CurTrend = NoTrend;

       if(LWMAVal[bar-1]>LWMAVal[bar-2]) LastTrend = UpTrend;
       else if(LWMAVal[bar-1]<LWMAVal[bar-2]) LastTrend = DownTrend;
       else LastTrend = NoTrend;


       if( ((LastTrend == UpTrend) && (CurTrend == DownTrend)) || ((LastTrend == DownTrend) && (CurTrend == UpTrend) )) 
       {
          if(ResetBar == 1) Pressure[bar] = Pressure[bar-2] + (BuyPressure[bar] - SellPressure[bar]);
          else Pressure[bar] = BuyPressure[bar] - SellPressure[bar];
          ResetBar = 1;
       }   
       else 
       {
          Pressure[bar] = Pressure[bar-1] + (BuyPressure[bar] - SellPressure[bar]);
          ResetBar++;
       }     
      
      LastTrend = CurTrend;      
   }
     

   for(int bar=second; bar<rates_total; bar++)
   {        
       standardDeviation = StdDev(bar, stdPeriod, Pressure);
       UpStdVal[bar] =  standardDeviation * stdMultiFactor;
       DownStdVal[bar] = -(standardDeviation * stdMultiFactor);
   }               



   return(rates_total);
}
//+----------------------



double StdDev(int end, int SDPeriod, const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
    {
      dAmount+=(S_Array[i])*(S_Array[i]);
    }       

    StdValue = MathSqrt(dAmount/SDPeriod);
    return(StdValue);
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
CLwma _lwma;