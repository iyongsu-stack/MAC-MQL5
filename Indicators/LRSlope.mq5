//+------------------------------------------------------------------+
//|                                                      LRSlope.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property description "Linear Regression Slope"
#property indicator_buffers 3
#property indicator_plots   1


#property indicator_type1   DRAW_HISTOGRAM
//#property indicator_type2   DRAW_LINE
//#property indicator_type3   DRAW_LINE

#property indicator_color1  clrGreen
//#property indicator_color2  clrBlue
//#property indicator_color3  clrRed

#property indicator_style1  STYLE_SOLID
//#property indicator_style2  STYLE_DOT
//#property indicator_style3  STYLE_DOT

#property indicator_width1  2
//#property indicator_width2  2
//#property indicator_width3  2


//--- input params
input int            InpChPeriod = 180;           //Long Period


int ExChPeriod;
//---- buffers
double rlBuffer[],upBuffer[],downBuffer[]; 






//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

//--- check input variables
   int BarsTotal;
   BarsTotal=Bars(_Symbol,PERIOD_CURRENT);
   if(InpChPeriod<2)
     {
      ExChPeriod=2;
      printf("Incorrect input value InChPeriod=%d. Indicator will use InChPeriod=%d.",
             InpChPeriod,ExChPeriod);
     }
   else if(InpChPeriod>=BarsTotal)
     {
      ExChPeriod=BarsTotal-1;
      printf("Total Bars=%d. Incorrect input value InChPeriod=%d. Indicator will use InChPeriod=%d.",
             BarsTotal,InpChPeriod,ExChPeriod);
     }
   else ExChPeriod=InpChPeriod;
   
   SetIndexBuffer(0,rlBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,upBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,downBuffer,INDICATOR_CALCULATIONS);

   string shortname;
   StringConcatenate(shortname,"LR Slope(",InpChPeriod,")");
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
      first=InpChPeriod-1; 
     }
   else first=prev_calculated-1; 

   for(bar=first; bar<rates_total; bar++)
     {
 
        rlBuffer[bar]= LinearRegression(bar, close); 
        upBuffer[bar]= LinearRegression(bar, high);
        downBuffer[bar] = LinearRegression(bar, low);
                
     }
    
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+


double LinearRegression(int end, const double &close[])
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
       a=(sumX*sumY-ExChPeriod*sumXY)/(MathPow(sumX,2)-ExChPeriod*sumX2);
       b=(sumY-a*sumX)/ExChPeriod;


      return(a*100000.);

}
