//+------------------------------------------------------------------+
//|                                              HeatMapVolumeV1.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"

#property indicator_separate_window
#property description "Linear Regression Slope"
#property indicator_buffers 4
#property indicator_plots   4


#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_HISTOGRAM

#property indicator_color1  clrGreen
#property indicator_color2  clrYellow
#property indicator_color3  clrRed
#property indicator_color4  clrWhite

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID

#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  1



//--- input params
input int            AvgPeriod = 14;           //Avg Period
input int            StdPeriod = 14;           //Std Period
input double         DevMulti1 = 1.1;          //MultiFactor 1
input double         DevMulti2 = 2.0;          //MultiFactor 2



double mVolume[], AvgVolume[], StdVolume1[], StdVolume2[]; 






//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   
   SetIndexBuffer(0,StdVolume1,INDICATOR_DATA);
   SetIndexBuffer(1,StdVolume2,INDICATOR_DATA);
   SetIndexBuffer(2,AvgVolume,INDICATOR_DATA);
   SetIndexBuffer(3,mVolume,INDICATOR_DATA);
  
/*
   string shortname;
   StringConcatenate(shortname,"LR Slope(",InpChPeriod,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
*/   
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
   int first, second, third;       

   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      first = 0;
      second=AvgPeriod-1;
      third = second + StdPeriod; 
     }
   else
     {
      first=prev_calculated-1; 
      second = prev_calculated-1; 
      third = prev_calculated-1; 
     }


   for(int bar=first; bar<rates_total; bar++)
     {
       mVolume[bar] = (double)tick_volume[bar];                 
     }
   
   for(int bar=second; bar<rates_total; bar++)
     {
       AvgVolume[bar] = Average(bar, AvgPeriod, mVolume);                 
     }
    
   for(int bar=third; bar<rates_total; bar++)
     {
       StdVolume1[bar] = AvgVolume[bar] + StdDev(bar, StdPeriod, AvgVolume, mVolume)*DevMulti1;
       StdVolume2[bar] = AvgVolume[bar] + (StdVolume1[bar]/DevMulti1)*DevMulti2;                        
     }

    
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

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


