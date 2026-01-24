//+------------------------------------------------------------------+
//|                                             VWAP+ATR CHANNEL.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <MovingAverages.mqh>

#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   7
//--- plot vwap
#property indicator_label1  "VWAP"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//+--------------------------------------------------+
//|  Envelope levels indicator drawing parameters    |
//+--------------------------------------------------+
//---- drawing the levels as lines
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
//#property indicator_type4   DRAW_LINE
//#property indicator_type5   DRAW_LINE
//#property indicator_type6   DRAW_LINE
//#property indicator_type7   DRAW_LINE
//---- selection of levels colors
#property indicator_color2  clrLawnGreen
#property indicator_color3  clrLawnGreen
//#property indicator_color4  White
//#property indicator_color5  White
//#property indicator_color6  Red
//#property indicator_color7  Purple
//---- levels are dott-dash curves
#property indicator_style2 STYLE_DASHDOTDOT
#property indicator_style3 STYLE_DASHDOTDOT
//#property indicator_style4 STYLE_DASHDOTDOT
//#property indicator_style5 STYLE_DASHDOTDOT
//#property indicator_style6 STYLE_DASHDOTDOT
//#property indicator_style7 STYLE_DASHDOTDOT
//---- levels width is equal to 1
#property indicator_width2  2
#property indicator_width3  2
//#property indicator_width4  2
//#property indicator_width5  2
//#property indicator_width6  2
//#property indicator_width7  2
//---- display levels labels
#property indicator_label2  "+1 Envelope"
#property indicator_label3  "-1 Envelope"
//#property indicator_label4  "+1 Envelope"
//#property indicator_label5  "-1 Envelope"
//#property indicator_label6  "-2 Envelope"
//#property indicator_label7  "-3 Envelope"







//--- input parameters
input int      VWAPeriod =2;
input double Mult_Factor = 1.;
input ENUM_MA_METHOD MA_METHOD = MODE_SMA;
input ENUM_APPLIED_PRICE inpPrice    = PRICE_CLOSE; // Price
input int BBPeriod = 20;
//double Mult_Factor2= Mult_Factor1 * 2;
//double Mult_Factor3= Mult_Factor1 * 3;

//--- indicator buffers
double VWAPBuffer[], ExtMLBuffer[], price[];
double ExtLineBuffer1[],ExtLineBuffer2[], ExtStdDevBuffer[];
// double ,ExtLineBuffer1[]ExtLineBuffer2[],ExtLineBuffer5[],ExtLineBuffer6[];

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
   SetIndexBuffer(0,VWAPBuffer);
   SetIndexBuffer(1,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLineBuffer2,INDICATOR_DATA);
//   SetIndexBuffer(3,ExtLineBuffer3,INDICATOR_DATA);
//   SetIndexBuffer(4,ExtLineBuffer4,INDICATOR_DATA);
//   SetIndexBuffer(5,ExtLineBuffer5,INDICATOR_DATA);
//   SetIndexBuffer(6,ExtLineBuffer6,INDICATOR_DATA);
   SetIndexBuffer(3, price, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, ExtMLBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, ExtStdDevBuffer, INDICATOR_CALCULATIONS);
   
   

//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"VWAP-BB channel("+string(VWAPeriod)+"," +string(BBPeriod)+ ")");
   PlotIndexSetString(1,PLOT_LABEL,"+1 Envelope");
   PlotIndexSetString(2,PLOT_LABEL,"-1 Envelope");
//   PlotIndexSetString(3,PLOT_LABEL,"+1 Envelope");
//   PlotIndexSetString(4,PLOT_LABEL,"-1 Envelope");
//   PlotIndexSetString(5,PLOT_LABEL,"-2 Envelope");
//   PlotIndexSetString(6,PLOT_LABEL,"-3 Envelope");


//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   
//---- set the position, from which the levels drawing starts
   PlotIndexGetInteger(0, PLOT_DRAW_BEGIN,BBPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,BBPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,BBPeriod);
//   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,ATRPeriod);
//   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,ATRPeriod);
//   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,ATRPeriod);
//   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,ATRPeriod);

//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   
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


   if(rates_total <= VWAPeriod) return(0);

   int pos;
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;

//--- main cycle
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {

         // Calculate VWAP 
         _setPrice(inpPrice,price[i],i);
         switch(MA_METHOD)
         {
            case  MODE_SMA :
               VWAPBuffer[i]=VWAP_SMA_Func(i, price, tick_volume, VWAPeriod);
               break;

            default :
               VWAPBuffer[i]=VWAP_EMA_Func(i, price, tick_volume, VWAPeriod);
               break;
          }
          
      //--- middle line
      ExtMLBuffer[i]=SimpleMA(i,BBPeriod,price);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,price,ExtMLBuffer,BBPeriod);
      //--- upper line
      ExtLineBuffer1[i]=VWAPBuffer[i]+Mult_Factor*ExtStdDevBuffer[i];
      //--- lower line
      ExtLineBuffer2[i]=VWAPBuffer[i]-Mult_Factor*ExtStdDevBuffer[i];
         
      }



//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
}

double StdDev_Func(int position,const double &price[],const double &MAprice[],int period)
{
//--- variables
   double StdDev_dTmp=0.0;
//--- check for position
   if(position<period) return(StdDev_dTmp);
//--- calcualte StdDev
   for(int i=0;i<period;i++)
      { StdDev_dTmp+=MathPow(price[position-i]-MAprice[position],2); }
   StdDev_dTmp=MathSqrt(StdDev_dTmp/period);
//--- return calculated value
   return(StdDev_dTmp);
}
//+------------------------------------------------------------------+




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
  
  
