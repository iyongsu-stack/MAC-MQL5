///+------------------------------------------------------------------+
//|                                                 MATonySignal.mq5 |
//|                                         Copyright ? 2008, Jpkfox |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright ? 2008, Jpkfox"
#property link ""
#property description "Indicator of the maximal trend"
//---- indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window
//---- number of indicator buffers
#property indicator_buffers 2
//---- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a multy-color histogram
#property indicator_type1   DRAW_COLOR_HISTOGRAM
//---- the following colors are used in the histogram
#property indicator_color1  clrOrangeRed,clrPurple,clrGray,clrMediumBlue,clrDodgerBlue
//---- Indicator line width is equal to 2
#property indicator_width1  2
//---- displaying the indicator label
#property indicator_label1  "MATonySignal"
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET 0   // The constant for getting the command for the indicator recalculation back to the terminal

//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input ENUM_MA_METHOD MA_SMethod=MODE_EMA;          // Smoothing MA method
input uint MA_Length=14;                           // MA period              
input ENUM_APPLIED_PRICE AppliedPrice=PRICE_CLOSE; // Applied price
input uint MomPeriod=1;                            // Period for the difference
input uint MA_Level=7;                            // minimal price difference in points for the start                            
input int Shift=0;                                 // horizontal shift of the indicator in bars
//+-----------------------------------+

//---- declaration of dynamic arrays that will further be
// used as indicator buffers
double IndBuffer[];
double ColorIndBuffer[];

double dLevel;
//---- Declaration of integer variables of data starting point
int min_rates_total;
//---- Declaration of integer variables for storing indicator handles
int MA_Handle;
//+------------------------------------------------------------------+  
//| MATonySignal indicator initialization function                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_total=int(MA_Length+MomPeriod);
   dLevel=_Point*MA_Level;

//---- getting handle of the iMA indicator
   MA_Handle=iMA(NULL,0,MA_Length,0,MA_SMethod,AppliedPrice);
   if(MA_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the iMA indicator");
      return(1);
     }

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(IndBuffer,true);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

//---- setting dynamic array as a color index buffer  
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(ColorIndBuffer,true);

//---- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"MATonySignal(",MA_Length,", ",Shift,")");
//---- creating name for displaying if separate sub-window and in tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//---- determine the accuracy of displaying indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);

//---- the number of the indicator 3 horizontal levels  
   IndicatorSetInteger(INDICATOR_LEVELS,3);
//---- values of the indicator horizontal levels  
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,+1.0);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,0);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-1.0);
//---- gray and magenta colors are used for horizontal levels lines  
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrBlue);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,clrGray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,clrBlue);
//---- short dot-dash is used for the horizontal level line  
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,STYLE_DASHDOTDOT);

//---- end of initialization
   return(0);
  }
//+------------------------------------------------------------------+
//| MATonySignal iteration function                                  |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- checking the number of bars to be enough for calculation
   if(BarsCalculated(MA_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);

//---- declaration of variables with a floating point  
   double dma,MA[];
//---- Declaration of integer variables
   int to_copy,limit;
  
//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(MA,true);

//---- calculation of the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total-1; // starting index for the calculation of all bars
   else limit=rates_total-prev_calculated;  // starting index for calculation of new bars only
   to_copy=int(limit+1+MomPeriod); // calculated number of new copied data only

//---- copy the newly appeared data
   if(CopyBuffer(MA_Handle,0,0,to_copy,MA)<=0) return(RESET);

//---- main indicator calculation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      dma=MA[bar]-MA[bar+MomPeriod];

      IndBuffer[bar]=0.0;
      ColorIndBuffer[bar]=2;
      if(dma>0) if(dma>+dLevel) {IndBuffer[bar]=+2; ColorIndBuffer[bar]=4;} else {IndBuffer[bar]=+1; ColorIndBuffer[bar]=3;}
      if(dma<0) if(dma<-dLevel) {IndBuffer[bar]=-2; ColorIndBuffer[bar]=0;} else {IndBuffer[bar]=-1; ColorIndBuffer[bar]=1;}
     }
//----    
   return(rates_total);
  }
//+-----------------------------