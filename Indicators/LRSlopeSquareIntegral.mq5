//+------------------------------------------------------------------+
//|                                              LRSlopeSquareV2.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property description "Linear Regression Slope"
#property indicator_buffers 9
#property indicator_plots   2


#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1



#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3;
CXMA::Smooth_Method XMA_Method=(int)MODE_EMA; // Averaging method


//--- input params
input int            InpChPeriod1 = 8;          //Long Period
input int            InpChPeriod2 = 3;           //Square Period
input int            avgPeriod = 30;             //AvgPeriod


enum Signal1
{
   MINUS,
   PLUS
};
Signal1 SignalA, SignalB;



uint           XLength1     =2;            //Depth of the first averaging
uint           XLength2     =2;            //Depth of the second averaging
uint           XLength3     =2;            //Depth of the third averaging                   
int            XPhase       =15;           //Smoothing parameter



int ExChPeriod;
//---- buffers
double rlBuffer[],squareBuffer[], temp1_squarBuffer[], temp2_squareBuffer[], temp3_squareBuffer[], newSquareBuffer[], avgBuffer[], integral[]; 

int min_rates_total,min_rates_1,min_rates_2;





//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

//--- check input variables
   int BarsTotal;
   BarsTotal=Bars(_Symbol,PERIOD_CURRENT);
   if(InpChPeriod1<2)
     {
      ExChPeriod=2;
      printf("Incorrect input value InChPeriod=%d. Indicator will use InChPeriod=%d.",
             InpChPeriod1,ExChPeriod);
     }
   else if(InpChPeriod1>=BarsTotal)
     {
      ExChPeriod=BarsTotal-1;
      printf("Total Bars=%d. Incorrect input value InChPeriod=%d. Indicator will use InChPeriod=%d.",
             BarsTotal,InpChPeriod1,ExChPeriod);
     }
   else ExChPeriod=InpChPeriod1;
   
   min_rates_1=XMA1.GetStartBars((int)MODE_EMA,XLength1,XPhase);
   min_rates_2=min_rates_1+XMA1.GetStartBars((int)MODE_EMA,XLength2,XPhase);
   min_rates_total=min_rates_2+XMA1.GetStartBars((int)MODE_EMA,XLength3,XPhase);


   SetIndexBuffer(0,integral,INDICATOR_DATA);
   SetIndexBuffer(1,newSquareBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,avgBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,squareBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,rlBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,temp1_squarBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,temp2_squareBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,temp3_squareBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,avgBuffer,INDICATOR_DATA);

   
   
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

   string shortname;
   StringConcatenate(shortname,"LR Slope Sqare(",InpChPeriod2,")");
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


// First Linear Regression
   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      first=InpChPeriod1-1; 
     }
   else first=prev_calculated-1; 

   for(bar=first; bar<rates_total; bar++)
     {
 
        rlBuffer[bar]= LinearRegression(bar,ExChPeriod, close);                 
     }
     
// Second Linear Regression    
   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      second=InpChPeriod1 + InpChPeriod2 -1; 
     }
   else second=prev_calculated-1; 

   for(bar=second; bar<rates_total; bar++)
     { 
        temp1_squarBuffer[bar]= LinearRegression(bar,InpChPeriod2, rlBuffer); 
        temp2_squareBuffer[bar]=XMA1.XMASeries(second,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength1,temp1_squarBuffer[bar],bar,false);
        temp3_squareBuffer[bar]=XMA2.XMASeries(second,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength1,temp2_squareBuffer[bar],bar,false);
        squareBuffer[bar]=XMA3.XMASeries(second,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength1,temp3_squareBuffer[bar],bar,false);                

     } 
     
   if(prev_calculated>rates_total || prev_calculated<=0) 
     {
      third=InpChPeriod1 + InpChPeriod2 + avgPeriod-1; 
     }
   else third=prev_calculated-1; 

   for(bar=third; bar<rates_total; bar++)
     {
        double sum=0.;
        for(int i = bar-avgPeriod+1; i<=bar; i++){
         sum+=squareBuffer[i];
        }
        
        avgBuffer[bar]=sum/avgPeriod;
        newSquareBuffer[bar] = squareBuffer[bar] - avgBuffer[bar];

        if(newSquareBuffer[bar]>=0.) SignalB = PLUS;
        else SignalB = MINUS;
        
        if(newSquareBuffer[bar-1]>=0.) SignalA = PLUS;
        else SignalA = MINUS;


        if(SignalA != SignalB) integral[bar]=newSquareBuffer[bar];
        else integral[bar]=integral[bar-1]+newSquareBuffer[bar];
                        
     }         

   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+


double LinearRegression(int end, int period, const double &close[])
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
