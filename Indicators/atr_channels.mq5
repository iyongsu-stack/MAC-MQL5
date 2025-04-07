/*
 * For the indicator to work, place the
 * SmoothAlgorithms.mqh
 * in the directory: MetaTrader\\MQL5\Include
 */
 //+-----------------------------------------------------------------+
//|                                                 ATR Channels.mq5 |
//|                         Copyright © 2005, Luis Guilherme Damiani |
//|                                      http://www.damianifx.com.br |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2005, Luis Guilherme Damiani"
#property link      "http://www.damianifx.com.br"
#property description "ATR Channels"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers
#property indicator_buffers 7 
//---- seven plots are used
#property indicator_plots   7
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//---- blue-violet color is used as the color of the indicator line
#property indicator_color1 BlueViolet
//---- the indicator line is a dash-dotted curve
#property indicator_style1  STYLE_DASHDOTDOT
//---- Indicator line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "XMA"

//+--------------------------------------------------+
//|  Envelope levels indicator drawing parameters    |
//+--------------------------------------------------+
//---- drawing the levels as lines
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_LINE
//---- selection of levels colors
#property indicator_color2  Purple
#property indicator_color3  Red
#property indicator_color4  Blue
#property indicator_color5  Blue
#property indicator_color6  Red
#property indicator_color7  Purple
//---- levels are dott-dash curves
#property indicator_style2 STYLE_DASHDOTDOT
#property indicator_style3 STYLE_DASHDOTDOT
#property indicator_style4 STYLE_DASHDOTDOT
#property indicator_style5 STYLE_DASHDOTDOT
#property indicator_style6 STYLE_DASHDOTDOT
#property indicator_style7 STYLE_DASHDOTDOT
//---- levels width is equal to 1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
//---- display levels labels
#property indicator_label2  "+3 Envelope"
#property indicator_label3  "+2 Envelope"
#property indicator_label4  "+1 Envelope"
#property indicator_label5  "-1 Envelope"
#property indicator_label6  "-2 Envelope"
#property indicator_label7  "-3 Envelope"

//+-----------------------------------+
//|  Smoothings classes description   |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+

//---- declaration of the CXMA class variables from the SmoothAlgorithms.mqh file
CXMA XMA;
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum Applied_price_ //Type of constant
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPLE_,         //Simple Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_   //TrendFollow_2 Price 
  };
/*enum Smooth_Method - enumeration is declared in the SmoothAlgorithms.mqh file
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_JJMA,  //JJMA
   MODE_JurX,  //JurX
   MODE_ParMA, //ParMA
   MODE_T3,    //T3
   MODE_VIDYA, //VIDYA
   MODE_AMA,   //AMA
  }; */
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int    ATRPeriod=18;
input double Mult_Factor1= 1.6;
input double Mult_Factor2= 3.2;
input double Mult_Factor3= 4.8;

input Smooth_Method MA_SMethod=MODE_SMA;   // Smoothing method
input int SmLength=100;                    // Smoothing depth                    
input int SmPhase=15;                      // Smoothing parameter
                                           // for JJMA that can change withing the range -100 ... +100. It impacts the quality of the intermediate process of smoothing;
                                           // for VIDIA it is a CMO period, for AMA it is a slow average period
input Applied_price_ IPC=PRICE_CLOSE;      // Price constant
/* , used for the indicator calculation (1-CLOSE, 2-OPEN, 3-HIGH, 4-LOW, 
  5-MEDIAN, 6-TYPICAL, 7-WEIGHTED, 8-SIMPLE, 9-QUARTER, 10-TRENDFOLLOW, 11-0.5 * TRENDFOLLOW.) */
input int Shift=0;                        // Horizontal shift of the indicator in bars
input int PriceShift=0;                   // Vertical shift of the indicator in points
//+-----------------------------------+

//---- declaration of a dynamic array that further 
//---- will be used as an indicator buffer
double ExtLineBuffer0[];

//---- declaration of dynamic arrays that further 
//---- will be used as indicator buffers
double ExtLineBuffer1[],ExtLineBuffer2[],ExtLineBuffer3[];
double ExtLineBuffer4[],ExtLineBuffer5[],ExtLineBuffer6[];

//---- declaration of the average vertical shift value variable
double dPriceShift;
//---- declaration of a variable for storing handle of the indicator
int ATR_Handle;
//---- declaration of the integer variables for the start of data calculation
int StartBarsXMA,StartBarsATR,StartBars;
//+------------------------------------------------------------------+   
//| ATR Channels indicator initialization function                   | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- getting handle of the ATR indicator
   ATR_Handle=iATR(NULL,PERIOD_CURRENT,ATRPeriod);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");
   
//---- initialization of variables of the start of data calculation
   StartBarsXMA=XMA.GetStartBars(MA_SMethod, SmLength, SmPhase)+1;
   StartBarsATR=StartBarsXMA+ATRPeriod;
   StartBars=StartBarsXMA+StartBarsATR;

//---- setting up alerts for unacceptable values of external variables
   XMA.XMALengthCheck("Length", SmLength);
   XMA.XMAPhaseCheck("Phase", SmPhase, MA_SMethod);

//---- initialization of the vertical shift
   dPriceShift=_Point*PriceShift;

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtLineBuffer0,INDICATOR_DATA);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//---- create a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"XMA");
//---- setting values of the indicator that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ExtLineBuffer0,true);

//---- converting dynamic arrays into indicator buffers
   SetIndexBuffer(1,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLineBuffer2,INDICATOR_DATA);
   SetIndexBuffer(3,ExtLineBuffer3,INDICATOR_DATA);
   SetIndexBuffer(4,ExtLineBuffer4,INDICATOR_DATA);
   SetIndexBuffer(5,ExtLineBuffer5,INDICATOR_DATA);
   SetIndexBuffer(6,ExtLineBuffer6,INDICATOR_DATA);
//---- set the position, from which the levels drawing starts
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,StartBars);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,StartBars);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,StartBars);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,StartBars);
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,StartBars);
//---- create labels to display in Data Window
   PlotIndexSetString(1,PLOT_LABEL,"+3 Envelope");
   PlotIndexSetString(2,PLOT_LABEL,"+2 Envelope");
   PlotIndexSetString(3,PLOT_LABEL,"+1 Envelope");
   PlotIndexSetString(4,PLOT_LABEL,"-1 Envelope");
   PlotIndexSetString(5,PLOT_LABEL,"-2 Envelope");
   PlotIndexSetString(6,PLOT_LABEL,"-3 Envelope");
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ExtLineBuffer1,true);
   ArraySetAsSeries(ExtLineBuffer2,true);
   ArraySetAsSeries(ExtLineBuffer3,true);
   ArraySetAsSeries(ExtLineBuffer4,true);
   ArraySetAsSeries(ExtLineBuffer5,true);
   ArraySetAsSeries(ExtLineBuffer6,true);

//---- initializations of a variable for the indicator short name
   string shortname;
   string Smooth=XMA.GetString_MA_Method(MA_SMethod);
   StringConcatenate(shortname,"ATR Channels(",SmLength," ",Smooth,")");
//---- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- initialization end
  }
//+------------------------------------------------------------------+ 
//| ATR Channels iteration function                                  | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<StartBars) return(0);

//---- declaration of variables with a floating point  
   double price_,xxma,Range[];
//---- Declaration of integer variables and getting already calculated bars
   int to_copy,limit,bar;

//---- calculations of the necessary amount of data to be copied and
//---- the limit starting index for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      to_copy=rates_total; // calculated number of all bars
      limit=rates_total-1; // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
      to_copy=limit+1; // calculated number of new bars only
     }
     
//---- copy newly appeared data in the Range[] array
   if(CopyBuffer(ATR_Handle,0,0,to_copy,Range)<=0) return(0);

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(Range,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);


//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- call of the PriceSeries function to get the input price 'price_'
      price_=PriceSeries(IPC,bar,open,low,high,close);
 
      xxma = XMA.XMASeries(rates_total-1, prev_calculated, rates_total, MA_SMethod, SmPhase, SmLength, price_, bar, true);
      //----       
      ExtLineBuffer0[bar]=xxma+dPriceShift;
      
      ExtLineBuffer1[bar]=xxma+Range[bar]*Mult_Factor3+dPriceShift;
      ExtLineBuffer2[bar]=xxma+Range[bar]*Mult_Factor2+dPriceShift;
      ExtLineBuffer3[bar]=xxma+Range[bar]*Mult_Factor1+dPriceShift;
      ExtLineBuffer4[bar]=xxma-Range[bar]*Mult_Factor1+dPriceShift;
      ExtLineBuffer5[bar]=xxma-Range[bar]*Mult_Factor2+dPriceShift;
      ExtLineBuffer6[bar]=xxma-Range[bar]*Mult_Factor3+dPriceShift;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
