//+------------------------------------------------------------------+
//|                                            HeikinAshi_SepWnd.mq5 |
//|                                            Copyright 2012, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "The Heikin Ashi indicator in the sub-window"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1
//--- plot Hekin Ashi
#property indicator_label1  "Heikin Ashi Open;Heikin Ashi High;Heikin Ashi Low;Heikin Ashi Close"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrDodgerBlue,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//---
input int               InpHaPeriod = 1;                 // Heikin Ashi period
//--- indicator buffers
double         HaOpenBuffer[];
double         HaHighBuffer[];
double         HaLowBuffer[];
double         HaCloseBuffer[];
double         HaColors[];
//---
int            minRequiredBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   minRequiredBars = InpHaPeriod;
//--- indicator buffers mapping
   SetIndexBuffer(0, HaOpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HaHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, HaLowBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, HaCloseBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, HaColors, INDICATOR_COLOR_INDEX);
//---
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, minRequiredBars);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
//---
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//---
   IndicatorSetInteger(INDICATOR_LEVELS, 1);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, clrGray);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE, STYLE_SOLID);
//---
   IndicatorSetString(INDICATOR_SHORTNAME, "Heikin Ashi ("+(string)InpHaPeriod+")");  
//---
   return(0);
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
   int startBar;
   double haOpen, haHigh, haLow, haClose;
//---
   if ( rates_total < minRequiredBars) {
      Print("Not enough data to calculate");
      return(0);
   }
//---
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      startBar = minRequiredBars;
      for ( int bar = 0; bar < startBar; bar++ ) {
         HaOpenBuffer[bar] = open[bar];
         HaHighBuffer[bar] = high[bar];
         HaLowBuffer[bar] = low[bar];
         HaCloseBuffer[bar] = close[bar];
      }
   } else {
      startBar = prev_calculated - 1;
   }
//---
   for ( int bar = startBar; bar < rates_total && !IsStopped(); bar++ ) {
      //---
      haOpen = (HaOpenBuffer[bar-InpHaPeriod] + HaCloseBuffer[bar-InpHaPeriod]) / 2;
      haClose = (open[bar] + high[bar] + low[bar] + close[bar]) / 4;
      haHigh = MathMax(high[bar], MathMax(haOpen, haClose));
      haLow = MathMin(low[bar], MathMin(haOpen, haClose));
      //---
      if ( InpHaPeriod > 1 ) {
         haOpen = (haClose > haOpen) ? MathMax(haOpen, HaOpenBuffer[bar-1]) : MathMin(haOpen, HaOpenBuffer[bar-1]);
      }
      //---
      HaOpenBuffer[bar] = haOpen;
      HaHighBuffer[bar] = haHigh;
      HaLowBuffer[bar] = haLow;
      HaCloseBuffer[bar] = haClose;
      //---
      if ( haClose > haOpen ) {
         HaColors[bar] = 0.0;
      } else {
         HaColors[bar] = 1.0;
      }
   }
//---
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, close[rates_total-1]);
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+