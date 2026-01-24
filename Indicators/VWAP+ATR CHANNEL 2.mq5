//+------------------------------------------------------------------+
//|                                           VWAP+ATR CHANNEL 2.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   4


//--- plot vwap
#property indicator_label1  "Long VWAP"
#property indicator_label2  "+ ATR"
#property indicator_label3  "- ATR"
#property indicator_label4  "Short VWAP"

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE

#property indicator_color1  clrRed
#property indicator_color2  Purple
#property indicator_color3  Red
#property indicator_color4  Yellow

#property indicator_style1 STYLE_SOLID
#property indicator_style2 STYLE_DASHDOTDOT
#property indicator_style3 STYLE_DASHDOTDOT
#property indicator_style4 STYLE_SOLID

#property indicator_width1  1
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  1


// input parameters
input int      LongVWAPeriod =4;
input int      ShortVWAPeriod =3;
input double   ATR_Mult_Factor = 1.1;

// Fixed parameters
ENUM_APPLIED_PRICE inp_Price = PRICE_CLOSE;
int ATR_Period = 14;


//--- indicator buffers
double LongVWAPBuffer[], ShortVWAPBuffer[];
double price[], ATR;
double UpperLineBuffer[],LowerLineBuffer[];
double LongPrevEnum[], LongPrevNum[], ShortPrevEnum[], ShortPrevNum[];
int ATR_Handle;

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
   SetIndexBuffer(0,LongVWAPBuffer, INDICATOR_DATA);
   SetIndexBuffer(1,UpperLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowerLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ShortVWAPBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,price, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,LongPrevEnum, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,LongPrevNum, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,ShortPrevEnum, INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,ShortPrevNum, INDICATOR_CALCULATIONS);
   
   
   
   
//--- indicator name
   PlotIndexSetString(0,PLOT_LABEL,"Long VWAP");
   PlotIndexSetString(1,PLOT_LABEL,"Upper ATR");
   PlotIndexSetString(2,PLOT_LABEL,"Lower ATR");
   PlotIndexSetString(3,PLOT_LABEL,"Short VWAP");


//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits+1);
   
//---- set the position, from which the levels drawing starts
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, LongVWAPeriod);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, LongVWAPeriod);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, LongVWAPeriod);
   PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, LongVWAPeriod);

//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   ATR_Handle=iATR(NULL,PERIOD_CURRENT,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");

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


   if(rates_total <= LongVWAPeriod) return(0);

   int position;
   if(prev_calculated>1)
      position = prev_calculated-1;
   else
      position = 0;


//--- main cycle
   for(int i=position; i<rates_total && !IsStopped(); i++)
     {


         // Calculate VWAP 
         _setPrice(inp_Price,price[i],i);

         LongVWAPBuffer[i]=Long_VWAP_EMA_Func(i, price, tick_volume, LongVWAPeriod);
         ShortVWAPBuffer[i]=Short_VWAP_EMA_Func(i, price, tick_volume, ShortVWAPeriod);
       
         double ATRBuffer[1]; 
         CopyBuffer(ATR_Handle,0,time[i],time[i],ATRBuffer);
         ATR = ATRBuffer[0];


         UpperLineBuffer[i]=LongVWAPBuffer[i]+ATR*ATR_Mult_Factor;
         LowerLineBuffer[i]=LongVWAPBuffer[i]-ATR*ATR_Mult_Factor;
             
      }

//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
}


double Long_VWAP_EMA_Func(const int pPosition, const double &pPrice[], const long &pVolume[], const int pPeriods)
  {

      double currentEnum = 0.;
      double currentNum = 0.;
      double VWAP = 0.;
      double smoothingFactor = 2./((double)pPeriods +1.);
      
      if(pPosition == 0)
      {
         VWAP = pPrice[pPosition];
         LongPrevEnum[pPosition] = 0.;
         LongPrevNum[pPosition] = 0.;
      }

      else
      {
         currentEnum = smoothingFactor * pPrice[pPosition] * (double)pVolume[pPosition] +
                        (1. - smoothingFactor) * LongPrevEnum[pPosition - 1] ;
         currentNum = smoothingFactor * (double)pVolume[pPosition] + (1. - smoothingFactor) * LongPrevNum[pPosition -1] ; 
         
         VWAP = currentEnum / currentNum;
         
         LongPrevEnum[pPosition] = currentEnum;
         LongPrevNum[pPosition] = currentNum;     
      } 
      
   return(VWAP);
  }  
  
double Short_VWAP_EMA_Func(const int pPosition, const double &pPrice[], const long &pVolume[], const int pPeriods)
  {

      double currentEnum = 0.;
      double currentNum = 0.;
      double VWAP = 0.;
      double smoothingFactor = 2./((double)pPeriods +1.);
      
      if(pPosition == 0)
      {
         VWAP = pPrice[pPosition];
         ShortPrevEnum[pPosition] = 0.;
         ShortPrevNum[pPosition] = 0.;
      }

      else
      {
         currentEnum = smoothingFactor * pPrice[pPosition] * (double)pVolume[pPosition] +
                        (1. - smoothingFactor) * ShortPrevEnum[pPosition - 1] ;
         currentNum = smoothingFactor * (double)pVolume[pPosition] + (1. - smoothingFactor) * ShortPrevNum[pPosition -1] ; 
         
         VWAP = currentEnum / currentNum;
         
         ShortPrevEnum[pPosition] = currentEnum;
         ShortPrevNum[pPosition] = currentNum;     
      } 
      
   return(VWAP);
  }  




