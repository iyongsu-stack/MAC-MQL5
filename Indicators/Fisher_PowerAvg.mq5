//+------------------------------------------------------------------+
//|                                              Fisher_PowerAvg.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   1
#property indicator_label1  "Fisher PowerAvg"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrMediumSeaGreen,clrOrangeRed
#property indicator_width1  2
#include <MovingAverages.mqh>
//
//--- input parameters
//

enum enCalcMode
{
   calc_hl, // Include current high and low in calculation
   calc_no  // Don't include current high and low in calculation
};
input int                inpPeriod   = 32;           // Period
input int                signalPeriod = 5;
input int                powerPeriod = 3;
input enCalcMode         inpCalcMode = calc_no;      // Calculation mode
input ENUM_APPLIED_PRICE inpPrice    = PRICE_MEDIAN; // Price


//
//--- buffers declarations
//

double val[],valc[],signal[],prices[],work[], velocity[], power[], powerAvg[];
//------------------------------------------------------------------
// Custom indicator initialization function
//------------------------------------------------------------------
int OnInit()
{
   //
   //--- indicator buffers mapping
   //
         SetIndexBuffer(0,powerAvg, INDICATOR_DATA);
         SetIndexBuffer(1,valc  ,INDICATOR_COLOR_INDEX); 
         SetIndexBuffer(2,power, INDICATOR_CALCULATIONS);
         SetIndexBuffer(3,velocity, INDICATOR_CALCULATIONS);
         SetIndexBuffer(4,val   ,INDICATOR_CALCULATIONS);
         SetIndexBuffer(5,signal,INDICATOR_CALCULATIONS);
         SetIndexBuffer(6,prices,INDICATOR_CALCULATIONS);
         SetIndexBuffer(7,work  ,INDICATOR_CALCULATIONS);
   //
   //---
   //
   IndicatorSetString(INDICATOR_SHORTNAME,"Fisher PowerAvg("+(string)inpPeriod+", " +(string)signalPeriod+ ", "+(string)powerPeriod+")");
   return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason) { }

//------------------------------------------------------------------
// Custom indicator iteration function
//------------------------------------------------------------------
//
//---
//

#define _setPrice(_priceType,_target,_index) \
   { \
   switch(_priceType) \
   { \
      case PRICE_CLOSE:    _target = close[_index];                                              break; \
      case PRICE_OPEN:     _target = open[_index];                                               break; \
      case PRICE_HIGH:     _target = high[_index];                                               break; \
      case PRICE_LOW:      _target = low[_index];                                                break; \
      case PRICE_MEDIAN:   _target = (high[_index]+low[_index])/2.0;                             break; \
      case PRICE_TYPICAL:  _target = (high[_index]+low[_index]+close[_index])/3.0;               break; \
      case PRICE_WEIGHTED: _target = (high[_index]+low[_index]+close[_index]+close[_index])/4.0; break; \
      default : _target = 0; \
   }}

//
//---
//

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int i= prev_calculated-1; if (i<0) i=0; for (; i<rates_total && !_StopFlag; i++)
   {
 
        _setPrice(inpPrice,prices[i],i);
      int _start = i-inpPeriod+1; if (_start<0) _start = 0;
         double _hi = inpCalcMode==calc_hl ? MathMax(high[i],prices[ArrayMaximum(prices,_start,inpPeriod)]) : prices[ArrayMaximum(prices,_start,inpPeriod)];
         double _lo = inpCalcMode==calc_hl ? MathMin(low[i] ,prices[ArrayMinimum(prices,_start,inpPeriod)]) : prices[ArrayMinimum(prices,_start,inpPeriod)];
         double _os = (_hi!=_lo) ? 2.0*((prices[i]-_lo)/(_hi-_lo)-0.5) : 0;
         double _sm = (i>0) ? 0.5*_os + 0.5*work[i-1] : _os;
      
      //
      //---
      //
        
      work[i]   = MathMax(MathMin(_sm,0.999),-0.999);
      val[i]    = 0.25*MathLog((1+work[i])/(1-work[i])) + (i>0 ? 0.5*val[i-1] : 0);
      signal[i] = SimpleMA(i, signalPeriod, val);

      if(i==0) velocity[i] =0.; 
      else  velocity[i] = MathArctan((signal[i]-signal[i-1])) * 180./3.14159;
      
      if(i==0 || i==1) power[i] =0.; 
      else  power[i] = MathArctan((velocity[i]-velocity[i-1])*1.) * 180./3.14159;

      powerAvg[i] = SimpleMA(i, powerPeriod, power);
      


///      signal[i] = (i>0) ? val[i-1] : val[i];
//      valc[i]   = (val[i]>signal[i]) ? 1 :(val[i]<signal[i]) ? 2 :(i>0) ? valc[i-1]: 0;
      valc[i]   = (powerAvg[i]>0.) ? 1 :(powerAvg[i]<0.) ? 2 :(i>0) ? valc[i-1]: 0;
   }
   return (i);
}
//----------

