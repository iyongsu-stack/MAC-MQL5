//+------------------------------------------------------------------+
//|                                                  LRChannelv1.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window


#property description "Linear Regression Channel"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5
#property indicator_type1   DRAW_LINE
#property indicator_style1  STYLE_SOLID

#property indicator_type2   DRAW_LINE
#property indicator_style2  STYLE_DOT

#property indicator_type3   DRAW_LINE
#property indicator_style3  STYLE_DOT

#property indicator_type4   DRAW_LINE
#property indicator_style4  STYLE_DOT

#property indicator_type5   DRAW_LINE
#property indicator_style5  STYLE_DOT


#property indicator_color1  Green
#property indicator_color2  Yellow
#property indicator_color3  Yellow
#property indicator_color4  Red
#property indicator_color5  Red
#property indicator_applied_price PRICE_CLOSE
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2
#property indicator_width5  2



//--- input params
input int InChPeriod = 15; //Channel Period
input double InpMultiFactor = 2.0;

int ExChPeriod,rCount;
//---- buffers
double rlBuffer[],upBuffer[],downBuffer[],highBuffer[],lowBuffer[]; 






//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

//--- check input variables
   int BarsTotal;
   BarsTotal=Bars(_Symbol,PERIOD_CURRENT);
   if(InChPeriod<2)
     {
      ExChPeriod=2;
      printf("Incorrect input value InChPeriod=%d. Indicator will use InChPeriod=%d.",
             InChPeriod,ExChPeriod);
     }
   else if(InChPeriod>=BarsTotal)
     {
      ExChPeriod=BarsTotal-1;
      printf("Total Bars=%d. Incorrect input value InChPeriod=%d. Indicator will use InChPeriod=%d.",
             BarsTotal,InChPeriod,ExChPeriod);
     }
   else ExChPeriod=InChPeriod;
   
   SetIndexBuffer(0,rlBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,upBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,downBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,highBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,lowBuffer,INDICATOR_DATA);
   PlotIndexSetString(0,PLOT_LABEL,"Main Line("+string(ExChPeriod)+")");
   PlotIndexSetString(1,PLOT_LABEL,"Up Line("+string(ExChPeriod)+")");
   PlotIndexSetString(2,PLOT_LABEL,"Down Line("+string(ExChPeriod)+")");
   PlotIndexSetString(3,PLOT_LABEL,"High Line("+string(ExChPeriod)+")");
   PlotIndexSetString(4,PLOT_LABEL,"Low Line("+string(ExChPeriod)+")");

   
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
   double a;
//--- check for bars count
    if(rates_total<ExChPeriod+1)return(0);
//--- if  new bar set, calculate    
    if(rCount!=rates_total)
      {
       PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
       PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
       PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
       PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
       PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);

        a= LinearRegression(rates_total, close, rlBuffer); 
        
        StdDev(rates_total, a, close, rlBuffer, upBuffer, InpMultiFactor);
        StdDev(rates_total, a, close, rlBuffer, downBuffer, -1.*InpMultiFactor);


        
        
        rCount=rates_total;
      }
      
    return(rates_total);
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+


double LinearRegression(int rates_total, const double &close[], double &Tarray[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=rates_total-1-ExChPeriod;i<rates_total-1;i++)
         {
          sumX+=X;
          sumY+=close[i];
          sumXY+=X*close[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-ExChPeriod*sumXY)/(MathPow(sumX,2)-ExChPeriod*sumX2);
       b=(sumY-a*sumX)/ExChPeriod;

      X=0;
      for(int i=rates_total-1-ExChPeriod;i<rates_total;i++){
         Tarray[i]=b+a*X;
         X++;
      }   

      return(a);

}


void StdDev(int rates_total, double a, const double &close[], double &Sarray[], double &Tarray[], double multiFactor)
{

    double F=0.0, S=0.0;

       for(int i=rates_total-1-ExChPeriod;i<rates_total;i++)
         {
          F+=MathPow(close[i]-rlBuffer[i],2);
         }
//--- calculate deviation S       
       S=NormalizeDouble(MathSqrt(F/(ExChPeriod+1))/MathCos(MathArctan(a*M_PI/180)*M_PI/180),_Digits);
//--- calculate values of last buffers
       for(int i=rates_total-1-ExChPeriod;i<rates_total;i++)
         {
          Tarray[i] = Sarray[i]+ S*multiFactor;

/*
          upBuffer[i]=rlBuffer[i]+S;
          downBuffer[i]=rlBuffer[i]-S;
          highBuffer[i]=rlBuffer[i]+2*S;
          lowBuffer[i]=rlBuffer[i]-2*S;
*/
         }

}

