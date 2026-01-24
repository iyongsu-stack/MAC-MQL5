//+------------------------------------------------------------------+
//|                                         LRSlopeSquareHighLow.mq5 |
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

#property indicator_color1  clrYellow

#property indicator_style1  STYLE_SOLID

#property indicator_width1  2


//--- input params
input int            InpChPeriod = 20;           //Long Period
input int            InpChPeriod2 = 3;


int ExChPeriod;
//---- buffers
double rlBuffer[], sqareBuffer[], squareBufferMinus[]; 






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
   
   SetIndexBuffer(0,squareBufferMinus,INDICATOR_DATA);
   SetIndexBuffer(1,sqareBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,rlBuffer,INDICATOR_CALCULATIONS);

   string shortname;
   StringConcatenate(shortname,"LR Slope(",InpChPeriod,", ", InpChPeriod2, ")");
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
   int first, bar, second, third;       

   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      first=InpChPeriod-1; 
     }
   else first=prev_calculated-1; 

   for(bar=first; bar<rates_total; bar++)
     { 
        rlBuffer[bar]= LinearRegression2(bar, InpChPeriod, close);                
     }
     
   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      second=InpChPeriod + InpChPeriod2 -1; 
     }
   else second=prev_calculated-1; 

   for(bar=second; bar<rates_total; bar++)
     {
 
        sqareBuffer[bar]= LinearRegression2(bar,InpChPeriod2, rlBuffer); 
                
     }     

   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      third=InpChPeriod + InpChPeriod2; 
     }
   else third=prev_calculated-1; 

   for(bar=third; bar<rates_total; bar++)
     {
 
        squareBufferMinus[bar]= sqareBuffer[bar] - sqareBuffer[bar-1];
                
     }     


    
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+


double LinearRegression2(int end, int period, const double &close[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=end+1-period;i<=end;i++)
         {
          sumX+=X;
          sumY+=close[i];
          sumXY+=X*close[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-period*sumXY)/(MathPow(sumX,2)-period*sumX2);
       b=(sumY-a*sumX)/period;


      return(a);

}

double LinearRegression1(int end, const double &High[], const double &Low[])
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
          sumY+=High[i];
          sumXY+=X*High[i];
          sumX2+=MathPow(X,2);

          sumX+=X;
          sumY+=Low[i];
          sumXY+=X*Low[i];
          sumX2+=MathPow(X,2);

          X++;
       }
       
       a=(sumX*sumY-2.*ExChPeriod*sumXY)/(MathPow(sumX,2)-2*ExChPeriod*sumX2);
       b=(sumY-a*sumX)/(2*ExChPeriod);


      return(a);

}

