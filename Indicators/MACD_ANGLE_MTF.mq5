//+------------------------------------------------------------------+
//|                                               MACD_ANGLE_MTF.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 1 
#property indicator_plots   1
                           
#define INDICATOR_NAME "MACD_ANGLE"     

#property indicator_type1   DRAW_LINE
//#property indicator_color1 clrDodgerBlue,clrDeepPink
//#property indicator_label1  "MACD_ANGLE_HTF"

//+----------------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4; 
input int                InpFastEMA=12;               // Fast EMA period
input int                InpSlowEMA=26;               // Slow EMA period
input int                InpSignalSMA=5;              // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price


double angleBuffer[];
int LTHandle, signalBuffNumb=0;

int OnInit()
{
   //
   //--- indicator buffers mapping
   //
         SetIndexBuffer(0,angleBuffer, INDICATOR_DATA);
//         SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
   //
         string shortname;
         StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame),")");
//         fisherHandle=iCustom(Symbol(),TimeFrame,"FisherTransform",10,0);

         LTHandle = iCustom(_Symbol, TimeFrame, "MacdAngle", InpFastEMA, InpSlowEMA, InpSignalSMA, InpAppliedPrice ); 
         Sleep(3000);

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


   if(BarsCalculated(LTHandle)<Bars(Symbol(),TimeFrame))
   {
      int j = BarsCalculated(LTHandle);
      int k = Bars(Symbol(),TimeFrame);
      Print(j, k);
    return(prev_calculated);
   }

   datetime IndTime[1];

   int i= prev_calculated-1; if (i<0) i=0; for (; i<rates_total && !_StopFlag; i++)
   {
 
      CopyTime(_Symbol,TimeFrame,time[i],1,IndTime);

      if(i == 0)
      {
         angleBuffer[i]=0.;
      }
      else if(time[i]>=IndTime[0] && time[i-1]<IndTime[0])
      {
         double angle[1];
         CopyBuffer(LTHandle,signalBuffNumb,time[i],1,angle);
         
         angleBuffer[i]=angle[0]; 

      }
      else
      {
         angleBuffer[i]=angleBuffer[i-1];

      }
      
//      valc[i]   = (angleBuffer[i] > 0.0) ? 1 :(angleBuffer[i]<0.0) ? 2 :(i>0) ? valc[i-1]: 0;
     
    }


   return (i);
}



string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
