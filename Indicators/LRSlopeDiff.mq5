//+------------------------------------------------------------------+
//|                                                  LRSlopeDiff.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property description "Linear Regression Slope"
#property indicator_buffers 2
#property indicator_plots   1


#property indicator_type1   DRAW_HISTOGRAM

#property indicator_color1  clrYellow

#property indicator_style1  STYLE_SOLID

#property indicator_width1  2


//--- input params
input int            InpChPeriod1 = 2;           //Long Period
input int            InpChPeriod2 = 3;


int ExChPeriod;
//---- buffers
double diffBuffer[]; 






//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

   
   SetIndexBuffer(0,diffBuffer,INDICATOR_DATA);

   string shortname;
   StringConcatenate(shortname,"LR SlopeDiff(",InpChPeriod1,",", InpChPeriod2, ")");
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
   int first, bar; 
   double a, b;      

   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      first=InpChPeriod1 + InpChPeriod2; 
     }
   else first=prev_calculated-1; 

   for(bar=first; bar<rates_total; bar++)
     {
 
        a = LinearRegression(bar, bar-InpChPeriod1,  close);
        b = LinearRegression(bar-InpChPeriod1, bar-InpChPeriod1-InpChPeriod2, close);
        diffBuffer[bar]=a-b;        
     }



//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+


double LinearRegression(int end, int start, const double &close[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X, number=(end-start+1);

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=start;i<=end;i++)
         {
          sumX+=X;
          sumY+=close[i];
          sumXY+=X*close[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-number*sumXY)/(MathPow(sumX,2)-number*sumX2);
       b=(sumY-a*sumX)/number;


      return(a*100.);

}
