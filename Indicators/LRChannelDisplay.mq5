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
#property indicator_buffers 3
#property indicator_plots   3


#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
/*
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE    */

#property indicator_color1  clrRed
#property indicator_color2  clrYellow
#property indicator_color3  clrYellow
/*
#property indicator_color5  clrRed
#property indicator_color6  clrRed        */

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_DASHDOT
#property indicator_style3  STYLE_DASHDOT
/*
#property indicator_style5  STYLE_DASHDOT
#property indicator_style6  STYLE_DASHDOT    */

#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
/*
#property indicator_width5  2
#property indicator_width6  2    */

#property indicator_label1  "Center"
#property indicator_label2  "Up"
#property indicator_label3  "Down"
/*
#property indicator_label5  "High"
#property indicator_label6  "Low"      */

//#property indicator_applied_price PRICE_CLOSE
/*
enum HTC
{
   byClose,
   byEnd
};

*/
//--- input params
input int            InpChPeriod = 5;           //Channel Period
input double         InpMultiFactor = 2.0;       //Channel Width(SD*Multi)
//input int            InpNLRPeriod = 30;          //NLR-MA Line Period

//input HTC            HowToChannel  = byClose;      //How to Make Channel


int ExChPeriod, m_rates_total;
//---- buffers
double rlBuffer[], m_High[], m_Low[], m_Time[], upBuffer[],downBuffer[]; 
// double ,highBuffer[],lowBuffer[];

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
   SetIndexBuffer(1,upBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,downBuffer,INDICATOR_DATA);
//   SetIndexBuffer(5,highBuffer,INDICATOR_DATA);
//   SetIndexBuffer(6,lowBuffer,INDICATOR_DATA);

   PlotIndexSetString(0,PLOT_LABEL,"NLR Line("+string(InpChPeriod)+", " + string(InpMultiFactor)+")");
/*
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
   ArrayCopy(m_Time, time, 0, 0, rates_total);
   ArrayCopy(m_High, high, 0, 0, rates_total);
   ArrayCopy(m_Low, low, 0, 0, rates_total);
   m_rates_total = rates_total;
//--- return value of prev_calculated for next call
   return(rates_total);
}


//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---
   datetime time0;
   int barshift=0;
   double centerLRa, std;

   ArrayInitialize(rlBuffer, EMPTY_VALUE);
   ArrayInitialize(upBuffer, EMPTY_VALUE);
   ArrayInitialize(downBuffer, EMPTY_VALUE);

//--- the left mouse button has been pressed on the chart 
   if(id==CHARTEVENT_CLICK) 
     { 
      //Print("The coordinates of the mouse click on the chart are: x = ",lparam,"  y = ",dparam);
      double price;
      int subwindow=0, xpos=(int)lparam, ypos=(int)dparam;
      ChartXYToTimePrice(0,xpos,ypos,subwindow,time0,price);
      barshift = iBarShift(Symbol(),Period(),time0+PeriodSeconds()/2,false);
//      Alert(" Subwindow: ",IntegerToString(subwindow)," Time: ",TimeToString(time,TIME_SECONDS)," Bar: ",IntegerToString(bar));
//      Alert("time: "+TimeToString(m_Time[bar], TIME_SECONDS)+"bar: "+IntegerToString(bar));
        
     } 

     PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,m_rates_total-barshift-ExChPeriod-1);
/*
     PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
     PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
     PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);
     PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,rates_total-ExChPeriod-1);      */

     centerLRa= LinearRegression(barshift, m_High, m_Low, rlBuffer); 
     
     StdDev(barshift, centerLRa, m_High, m_Low, rlBuffer, upBuffer, InpMultiFactor);
     std=StdDev(barshift, centerLRa, m_High, m_Low, rlBuffer, downBuffer, -1.*InpMultiFactor); 
     
     Alert("a: "+ DoubleToString(centerLRa*100000., 2)+"     std: "+DoubleToString(std*100000., 0));       

     
     
/*        
     if(HowToChannel == byClose){
         StdDev(rates_total, centerLRa, close, rlBuffer, upBuffer, InpMultiFactor);
         StdDev(rates_total, centerLRa, close, rlBuffer, downBuffer, -1.*InpMultiFactor);        
     }else{
         upperLRa = LinearRegression(rates_total, high, upBuffer);
         LowerLRa = LinearRegression(rates_total, low, downBuffer);                
     }
*/

}




double LinearRegression(int shift, const double &high[], const double &low[], double &Tarray[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=m_rates_total-shift-ExChPeriod-1;i<m_rates_total-shift-1;i++)
       {
          sumX+=X;
          sumY+=high[i];
          sumXY+=X*high[i];
          sumX2+=MathPow(X,2);

          sumX+=X;
          sumY+=low[i];
          sumXY+=X*low[i];
          sumX2+=MathPow(X,2);

          X++;
       }
       
       a=(sumX*sumY-2.*ExChPeriod*sumXY)/(MathPow(sumX,2)-2*ExChPeriod*sumX2);
       b=(sumY-a*sumX)/(2*ExChPeriod);

      X=0;
      for(int i=m_rates_total-shift-ExChPeriod-1;i<=m_rates_total-shift-1;i++){
         Tarray[i]=b+a*X;
         X++;
      }   

      return(a);

}


double StdDev(int shift, double a, const double &High[], const double &Low[], double &Sarray[], double &Tarray[], double multiFactor)
{

    double F=0.0, S=0.0;

       for(int i=m_rates_total-shift-ExChPeriod-1;i<m_rates_total-shift-1;i++)
         {
          F+=MathPow(High[i]-Sarray[i],2);
          F+=MathPow(Low[i]-Sarray[i],2);
          
         }
//--- calculate deviation S       
       S=NormalizeDouble(MathSqrt(F/(2*ExChPeriod+1))/MathCos(MathArctan(a*M_PI/180)*M_PI/180),_Digits);
//--- calculate values of last buffers
       for(int i=m_rates_total-shift-ExChPeriod-1;i<=m_rates_total-shift-1;i++)
         {
          Tarray[i] = Sarray[i]+ S*multiFactor;
         }
       return(S);
}

