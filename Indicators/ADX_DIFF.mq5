//+------------------------------------------------------------------+
//|                                                     ADX_DIFF.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1

//#property indicator_type1   DRAW_LINE
//#property indicator_color1  Silver
//#property indicator_width1  2

#property indicator_label1  "ADX_DIFF"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrMediumSeaGreen,clrOrangeRed
#property indicator_width1  2

//input double Ind_level1 = 5.;
//double Ind_level2 = Ind_level1 * (-1);
#define INDICATOR_NAME "ADX MTF"     
#property indicator_level1 12.
#property indicator_level2 -12.
#property indicator_levelcolor clrDarkGray
#property indicator_levelstyle STYLE_DASHDOT


#include <MovingAverages.mqh>

input ENUM_TIMEFRAMES TimeFrame=PERIOD_M10; 
input double level1 = 12.;
input int adx_period = 7;

double level2 = level1 * -1.;

double DI_DIFF[], AvgDiff[], valc[];
int adxHandle, plusBuffNumb=1, minusBuffNumb=2;


//------------------------------------------------------------------
// Custom indicator initialization function
//------------------------------------------------------------------
int OnInit()
{
   //
   //--- indicator buffers mapping
   //
   SetIndexBuffer(0,DI_DIFF,INDICATOR_DATA);
   SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);


   IndicatorSetInteger(INDICATOR_DIGITS,2);

   adxHandle=iADX(Symbol(), TimeFrame, adx_period); 

   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame),")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

   return (INIT_SUCCEEDED);
}


int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{

   if(BarsCalculated(adxHandle)<Bars(Symbol(),TimeFrame)) return(prev_calculated);

   datetime IndTime[1];

   int i= prev_calculated-1; if (i<0) i=0; for (; i<rates_total && !_StopFlag; i++)
   {
      CopyTime(_Symbol,TimeFrame,time[i],1,IndTime);

      if(i == 0)
      {
         DI_DIFF[i] = 0.;
      }
      else if(time[i]>=IndTime[0] && time[i-1]<IndTime[0])
      {
         double plusArr[1],minusArr[1];
         CopyBuffer(adxHandle,plusBuffNumb,time[i],1,plusArr);
         CopyBuffer(adxHandle,minusBuffNumb,time[i],1,minusArr);
         
         DI_DIFF[i] = plusArr[0] - minusArr[0];

      }
      else
      {
         DI_DIFF[i] = DI_DIFF[i-1];
      }
           
      valc[i]   = (DI_DIFF[i]<level1 && DI_DIFF[i] > level2) ? 1 :(DI_DIFF[i]>=level1 && DI_DIFF[i] <= level2) ? 2 : 0;
   }
   return (i);
}

string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
