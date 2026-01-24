//+------------------------------------------------------------------+
//|                                                  LRSlopeMACD.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property description "Linear Regression Slope"
#property indicator_buffers 2
#property indicator_plots   2


#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE

#property indicator_color1  clrGreen
#property indicator_color2  clrRed


#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID


#property indicator_width1  2
#property indicator_width2  2


//--- input params
input int            InpChPeriod1 = 180;           //Period1
input int            InpChPeriod2 = 200;           //Period2


double mBuffer1[],mBuffer2[]; 






//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

//--- check input variables
   
   SetIndexBuffer(0,mBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,mBuffer2,INDICATOR_DATA);

   string shortname;
   StringConcatenate(shortname,"LR Slope(",InpChPeriod1,",", InpChPeriod2, ")");
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

   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      first=InpChPeriod1-1; 
     }
   else first=prev_calculated-1; 

   for(bar=first; bar<rates_total; bar++)
     {
 
        mBuffer1[bar]= LinearRegression(bar, InpChPeriod1, close); 
                
     }
    
    
    
   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      first=InpChPeriod2-1; 
     }
   else first=prev_calculated-1; 

   for(bar=first; bar<rates_total; bar++)
     {
 
        mBuffer2[bar]= LinearRegression(bar, InpChPeriod2, close);
                
     }    
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+


double LinearRegression(int end, int mPeriod, const double &close[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=end+1-mPeriod;i<=end;i++)
         {
          sumX+=X;
          sumY+=close[i];
          sumXY+=X*close[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-mPeriod*sumXY)/(MathPow(sumX,2)-mPeriod*sumX2);
       b=(sumY-a*sumX)/mPeriod;


      return(a);

}
