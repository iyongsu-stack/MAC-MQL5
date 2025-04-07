/*
 * Place the SmoothAlgorithms.mqh file
 * to the terminal_data_folder\MQL5\Include
 */
//+------------------------------------------------------------------+
//|                                                        ParMA.mq5 |
//|          Parabolic approximation code: Copyright ?2005, alexjou |
//|                               Copyright ?2010, Nikolay Kositsin |
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "2010,   Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
#property version   "1.00"

//---- drawing the indicator in the main window
#property indicator_chart_window
//---- one buffer is used for calculation and drawing of the indicator
#property indicator_buffers 1
//---- only one plot is used
#property indicator_plots   1
//---- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//---- dodger blue color is used as the color of the indicator line
#property indicator_color1 DodgerBlue

//---- indicator input parameters
input int ParMAPeriod=13;    //ParMA period
input int ParMAShift=0;      //Horizontal shift of ParMA in bars
input int ParMAPriceShift=0; //Vertical shift of ParMA in points

//---- Indicator buffer
double ExtLineBuffer[];

double dPriceShift;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- name for the data window and the label for sub-windows
   string short_name="ParMA";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name+"("+string(ParMAPeriod)+")");
//---- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ParMAPeriod);
//---- setting values of the indicator that won't be visible on the chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- set ExtLineBuffer as indicator buffer
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//---- shifting the average horizontally by ParMA Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,ParMAShift);
//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- initialization of the vertical shift
   dPriceShift=_Point*ParMAPriceShift;
//----
  }
//+------------------------------------------------------------------+
//| The ParMA class of the SmoothAlgorithms.mqh library is used      | 
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh> 
//+------------------------------------------------------------------+ 
//|  Moving Average                                                  |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,     // number of bars in history at the current tick
                 const int prev_calculated, // number of bars calculated at previous call
                 const int begin,           // number of beginning of reliable counting of bars
                 const double &price[]      // price array for calculation of the indicator
                 )
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<begin+ParMAPeriod)
      return(0);

//---- declarations of local variables 
   int first,bar;

//---- calculation of the 'first' starting number for the bars recalculation cycle
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      first=begin; // starting index for calculation of all bars
      for(bar=0; bar<=begin; bar++)
         ExtLineBuffer[bar]=0;
     }
   else first=prev_calculated-1; // starting index for calculation of new bars

//---- declaration of the CParMA class variable from the ParMASeries_Cls.mqh file
   static CParMA ParMA1;

//---- main indicator calculation loop
   for(bar=first; bar<rates_total; bar++)
     {
      //---- Getting the average value. One call of the ParMASeries function.  
      ExtLineBuffer[bar]=ParMA1.ParMASeries(begin,prev_calculated,rates_total,
                                            ParMAPeriod,price[bar],bar,false)+dPriceShift;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
