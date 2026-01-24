//+------------------------------------------------------------------+
//|                                                  LRChannelv3.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#property description "Linear Regression Channel"
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   6


#property indicator_type1   DRAW_COLOR_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE

#property indicator_color1  clrDarkGray,clrDeepPink,clrLimeGreen
#property indicator_color2  clrGreen
#property indicator_color3  clrYellow
#property indicator_color4  clrYellow
#property indicator_color5  clrRed
#property indicator_color6  clrRed

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_DASHDOT
#property indicator_style4  STYLE_DASHDOT
#property indicator_style5  STYLE_DASHDOT
#property indicator_style6  STYLE_DASHDOT

#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2
#property indicator_width5  2
#property indicator_width6  2

#property indicator_label1  "NLR"
#property indicator_label2  "Center"
#property indicator_label3  "Up"
#property indicator_label4  "Down"
#property indicator_label5  "High"
#property indicator_label6  "Low"

#property indicator_applied_price PRICE_CLOSE

enum HTC
{
   byClose,
   byEnd
};


//--- input params
input int            InpChPeriod = 40;           //Channel Period
input double         InpMultiFactor = 2.0;       //Channel Width(SD*Multi)
input int            InpNLRPeriod = 30;          //NLR-MA Line Period

input HTC            HowToChannel  = byClose;      //How to Make Channel


int ExChPeriod,rCount;
//---- buffers
double rlBuffer[],upBuffer[],downBuffer[],highBuffer[],lowBuffer[], val[],valc[]; 






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
   
   SetIndexBuffer(0,val,INDICATOR_DATA);
   SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);  
   SetIndexBuffer(2,rlBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,upBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,downBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,highBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,lowBuffer,INDICATOR_DATA);

/*
   PlotIndexSetString(0,PLOT_LABEL,"NLR Line("+string(InpNLRPeriod)+")");
   PlotIndexSetString(2,PLOT_LABEL,"Main Line("+string(ExChPeriod)+")");
   PlotIndexSetString(3,PLOT_LABEL,"Up Line("+string(ExChPeriod)+")");
   PlotIndexSetString(4,PLOT_LABEL,"Down Line("+string(ExChPeriod)+")");
   PlotIndexSetString(5,PLOT_LABEL,"High Line("+string(ExChPeriod)+")");
   PlotIndexSetString(6,PLOT_LABEL,"Low Line("+string(ExChPeriod)+")");

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
   double centerLRa, upperLRa, LowerLRa;
   
      for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
     {
      val[i]=iNlr(getPrice(PRICE_CLOSE,open,close,high,low,i,rates_total),InpNLRPeriod,i,0,rates_total);
      valc[i]=(i>0) ?(val[i]>val[i-1]) ? 2 :(val[i]<val[i-1]) ? 1 : valc[i-1]: 0;
     }
    
//--- check for bars count
    if(rates_total<ExChPeriod+1)return(0);
//--- if  new bar set, calculate    
    if(rCount!=rates_total)
      {
       PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
       PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
       PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
       PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
       PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);

        centerLRa= LinearRegression(rates_total, close, rlBuffer); 
        
        if(HowToChannel == byClose){
         StdDev(rates_total, centerLRa, close, rlBuffer, upBuffer, InpMultiFactor);
         StdDev(rates_total, centerLRa, close, rlBuffer, downBuffer, -1.*InpMultiFactor);        
        }else{
         upperLRa = LinearRegression(rates_total, high, upBuffer);
         LowerLRa = LinearRegression(rates_total, low, downBuffer);                
        }
                
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


// Non Linear Regression Line calculation code
double workNlr[][1];
double nlrYValue[];
double nlrXValue[];
//
//---
//
double iNlr(double price,int Length,int shift,int desiredBar,int bars,int instanceNo=0)
  {
   if(ArrayRange(workNlr,0)!=bars) ArrayResize(workNlr,bars);
   if(ArraySize(nlrYValue)!=Length) ArrayResize(nlrYValue,Length);
   if(ArraySize(nlrXValue)!=Length) ArrayResize(nlrXValue,Length);
//
//---
//
   double AvgX = 0;
   double AvgY = 0;
   int r=shift;
   workNlr[r][instanceNo]=price;
   ArrayInitialize(nlrXValue,0);
   ArrayInitialize(nlrYValue,0);
   for(int i=0;i<Length && (r-i)>=0;i++)
     {
      nlrXValue[i] = i;
      nlrYValue[i] = workNlr[r-i][instanceNo];
      AvgX  += nlrXValue[i];
      AvgY  += nlrYValue[i];
     }
   AvgX /= Length;
   AvgY /= Length;
//
//---
//
   double SXX   = 0;
   double SXY   = 0;
   double SYY   = 0;
   double SXX2  = 0;
   double SX2X2 = 0;
   double SYX2  = 0;

   for(int i=0;i<Length;i++)
     {
      double XM  = nlrXValue[i] - AvgX;
      double YM  = nlrYValue[i] - AvgY;
      double XM2 = nlrXValue[i] * nlrXValue[i] - AvgX*AvgX;
      SXX   += XM*XM;
      SXY   += XM*YM;
      SYY   += YM*YM;
      SXX2  += XM*XM2;
      SX2X2 += XM2*XM2;
      SYX2  += YM*XM2;
     }
//
//---
//
   double tmp;
   double ACoeff=0;
   double BCoeff=0;
   double CCoeff=0;

   tmp=SXX*SX2X2-SXX2*SXX2;
   if(tmp!=0)
     {
      BCoeff = ( SXY*SX2X2 - SYX2*SXX2 ) / tmp;
      CCoeff = ( SXX*SYX2  - SXX2*SXY )  / tmp;
     }
   ACoeff = AvgY   - BCoeff*AvgX       - CCoeff*AvgX*AvgX;
   tmp    = ACoeff + BCoeff*desiredBar + CCoeff*desiredBar*desiredBar;
   return(tmp);
  }
//
//---
//
double getPrice(ENUM_APPLIED_PRICE tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i,int _bars)
  {
   if(i>=0)
      switch(tprice)
        {
         case PRICE_CLOSE:     return(close[i]);
         case PRICE_OPEN:      return(open[i]);
         case PRICE_HIGH:      return(high[i]);
         case PRICE_LOW:       return(low[i]);
         case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
         case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
         case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
        }
   return(0);
  }
//+--------