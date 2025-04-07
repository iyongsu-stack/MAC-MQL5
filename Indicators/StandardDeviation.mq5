//+------------------------------------------------------------------+
//|                                            StandardDeviation.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window
#property description "Linear Regression Slope"
#property indicator_buffers 1
#property indicator_plots   1


#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// #property indicator_level1  150000
// #property indicator_level2  -150000


//--- input params
input ENUM_MA_METHOD maMathod = MODE_EMA;      //Sma Method
input int            stdPeriod = 10;          //Std Period
input int            avgPeriod = 3;           //Std Average Period


ENUM_APPLIED_PRICE


double stdBuffer[],stdAvgBuffer[]; 






//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

   SetIndexBuffer(0,stdBuffer,INDICATOR_DATA);
//   SetIndexBuffer(1,stdBuffer,INDICATOR_CALCULATIONS);
//   SetIndexBuffer(2,stdAvgBuffer,INDICATOR_CALCULATIONS);
   
   
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,stdPeriod);

   string shortname;
   StringConcatenate(shortname,"STD(",stdPeriod,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   
   
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//---
   int first, bar, second;       
   double sum, sum2;

// First Linear Regression
   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      first=rates_total-stdPeriod; 
     }
   else first=rates_total - prev_calculated; 
   for(bar=first; bar<=0; bar--)
   { 
/*      
      sum = 0.;

      for(int i = bar; i>bar-stdPeriod;i--){
         sum = sum + close[i];
      }
              
      sum = sum/stdPeriod;    
          
      sum2 = 0.0;

      for(int i = bar; i>bar-stdPeriod;i--){
         sum2 = sum2 + (close[i]- sum) * (close[i]- sum);
      }  
            
      sum2 = sum2/(stdPeriod-1);      */
            
      stdBuffer[bar]=iStdDev(_Symbol, _Period, stdPeriod, bar, maMathod, PRICE_CLOSE);
   
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
}




//+------------------------------------------------------------------+
