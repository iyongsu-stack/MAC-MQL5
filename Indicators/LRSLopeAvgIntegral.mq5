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
#property indicator_buffers 4
#property indicator_plots   2


#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2



//--- input params
input int            InpChPeriod = 20;         //Long Period
input int            avgPeriod = 90;           //Avg Period



int ExChPeriod;
//---- buffers
double rlBuffer[],averageBuffer[], newRlBuffer[], integral[]; 

enum Signal1
{
   MINUS,
   PLUS
};
Signal1 SignalA, SignalB;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

//--- check input variables
   SignalA = MINUS;
   SignalB = MINUS;
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
   
   SetIndexBuffer(0,newRlBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,integral,INDICATOR_DATA);
   SetIndexBuffer(2,rlBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,averageBuffer,INDICATOR_CALCULATIONS);
//   SetIndexBuffer(2,downBuffer,INDICATOR_DATA);

   string shortname;
   StringConcatenate(shortname,"LR Slope(",InpChPeriod,")", "Average(", avgPeriod, ")");
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
   int first, second, bar;       

   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      first=InpChPeriod-1; 
     }
   else first=prev_calculated-1; 

   for(bar=first; bar<rates_total; bar++)
     {
 
        rlBuffer[bar]= LinearRegression(bar, close); 
                
     }

   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      second=avgPeriod-1; 
     }
   else second=prev_calculated-1; 

   for(bar=second; bar<rates_total; bar++)
     {
        double sum=0.;
        for(int i = bar-avgPeriod+1; i<=bar; i++){
         sum+=rlBuffer[i];
        }
        
        averageBuffer[bar]=sum/avgPeriod;
        newRlBuffer[bar] = rlBuffer[bar] - averageBuffer[bar];

        if(newRlBuffer[bar]>=0.) SignalB = PLUS;
        else SignalB = MINUS;
        
        if(newRlBuffer[bar-1]>=0.) SignalA = PLUS;
        else SignalA = MINUS;


        if(SignalA != SignalB) integral[bar]=newRlBuffer[bar];
        else integral[bar]=integral[bar-1]+newRlBuffer[bar];
                        
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
