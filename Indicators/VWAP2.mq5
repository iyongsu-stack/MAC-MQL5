//+------------------------------------------------------------------+
//|                                                        VWAP2.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//+------------------------------------------------------------------+
//|                                                         VWAP.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot vwap
#property indicator_label1  "VWAP"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      Periods =3;
input ENUM_MA_METHOD MA_METHOD = MODE_EMA;
input ENUM_APPLIED_PRICE inpPrice    = PRICE_CLOSE; // Price


//--- indicator buffers
double VWAPBuffer[];
double price[];


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


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {


//--- indicator buffers mapping
   SetIndexBuffer(0,VWAPBuffer);
   SetIndexBuffer(1, price, INDICATOR_CALCULATIONS);

//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"VWAP("+string(Periods)+")");

   PlotIndexGetInteger(0, PLOT_DRAW_BEGIN, Periods);

//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   
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


   if(rates_total <= Periods) return(0);

   int pos;
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;

//--- main cycle
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {
         _setPrice(inpPrice,price[i],i);
         switch(MA_METHOD)
         {
            case  MODE_SMA :
               VWAPBuffer[i]=VWAP_SMA_Func(i, price, tick_volume, Periods);
               break;

            default :
               VWAPBuffer[i]=VWAP_EMA_Func(i, price, tick_volume, Periods);
               break;
          }
            
 //        Print("position: ", i, "VWAP: ", (float)VWAPBuffer[i]);      
      }

//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Calculate VWAP                                                   |
//+------------------------------------------------------------------+
double VWAP_SMA_Func(const int pPosition, const double &pPrice[], const long &pVolume[], const int pPeriods)
  {

      double tempPV = 0.;
      double tempVolume = 0.;
      double VWAP = 0;
 
 //     Print("pPosition: ", pPosition, " Time: ", pTime[pPosition]);
           
      if(pPosition>=pPeriods)
      {
         for(int i=0; i<pPeriods; i++)
         {
            tempPV += pPrice[pPosition - i] * (double)pVolume[pPosition - i];
            tempVolume += (double)pVolume[pPosition - i]; 
         }
         VWAP = tempPV / tempVolume;               
      }
   return(VWAP);
  }
  
double VWAP_EMA_Func(const int pPosition, const double &pPrice[], const long &pVolume[], const int pPeriods)
  {

      double currentEnum = 0.;
      static double prevEnum = 0.;
      double currentNum = 0.;
      static double prevNum = 0.;
      double VWAP = 0.;
      double smoothingFactor = 2./((double)pPeriods +1.);
      
      if(pPosition == 0)
      {
         VWAP = pPrice[pPosition];
         prevEnum = 0.;
         prevNum = 0.;
      }
      else
      {
         currentEnum = smoothingFactor * pPrice[pPosition] * (double)pVolume[pPosition] +
                        (1. - smoothingFactor) * prevEnum ;
         currentNum = smoothingFactor * (double)pVolume[pPosition] + (1. - smoothingFactor) * prevNum ; 
         
         VWAP = currentEnum / currentNum;
         prevEnum = currentEnum;
         prevNum = currentNum;     
      }  
   return(VWAP);
  }  