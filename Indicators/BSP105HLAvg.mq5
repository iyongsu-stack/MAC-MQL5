//+------------------------------------------------------------------+
//|                                                  BSP105HLAvg.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 3
#property indicator_plots   2

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_type2   DRAW_HISTOGRAM

#property indicator_color1  clrGreen,clrRed
#property indicator_color2  clrGreen

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID

#property indicator_width1  2
#property indicator_width2  1

input int                 WmaPeriod     = 360;           // WmaPeriod
input double              MultiRatio    = 1.0;          // MultiRatio



double HL[], AvgHL[], AvgHLC[] ;

//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,AvgHL,INDICATOR_DATA);
   SetIndexBuffer(1,AvgHLC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,HL,INDICATOR_DATA);
   
   

   string short_name = "HLAvg("+ (string)WmaPeriod + ", " + (string)MultiRatio +  ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
    
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

   int first, second;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;  
      second = first + WmaPeriod;
     }
   else
     { 
      first=prev_calculated-1; 
      second = first;
     } 


//---- The main loop of the indicator calculation
   for(int bar=first; bar<rates_total; bar++)
     {       
       HL[bar] =( high[bar] - low[bar] );
     }  

   for(int bar=second; bar<rates_total; bar++)
     {
       AvgHL[bar]=iWma(bar, WmaPeriod, HL)*MultiRatio;
       
       if(AvgHL[bar]>=AvgHL[bar-1]) AvgHLC[bar]=0;
       else AvgHLC[bar]=1;
     }


   return(rates_total);
  }
//+----------------------


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

