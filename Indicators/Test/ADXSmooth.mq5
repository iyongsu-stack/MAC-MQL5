//+------------------------------------------------------------------+
//|                                                 ADX Smoothed.mq5 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2007, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_type1   DRAW_LINE
#property indicator_color1  Lime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label1  "Di Plus"

#property indicator_type2   DRAW_LINE
#property indicator_color2  Red
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_label2  "Di Minus"

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrYellow
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_label3  "ADX"

#property indicator_level1 88.0
#property indicator_level2 50.0
#property indicator_level3 12.0
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT

input int    period = 30;
input double alpha1 = 0.25;
input double alpha2 = 0.33;
input int    PriceType=0;

double DiPlusBuffer[];
double DiMinusBuffer[];
double ADXBuffer[];
int ADX_Handle;
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
   ADX_Handle=iADX(NULL,0,period);
   if(ADX_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ADX indicator");

   min_rates_total=period+1; // Ensure we have enough history

   // Buffers are NOT set as series (default forward indexing: 0 = oldest)
   SetIndexBuffer(0,DiPlusBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   
   SetIndexBuffer(1,DiMinusBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   
   SetIndexBuffer(2,ADXBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   
   string shortname;
   StringConcatenate(shortname,"ADX(",period,")smothed");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   IndicatorSetInteger(INDICATOR_DIGITS,0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(BarsCalculated(ADX_Handle)<rates_total || rates_total<min_rates_total) return(0);

   int start;
   double ADX[],DIP[],DIM[];
   
   // Running state variables (Level 1 smoothing state)
   // We need to persist the last calculated state of the 'previous' completed bar
   static double Last_DiPlus_, Last_DiMinus_, Last_Adx_; 
   
   // Temporary variables for current calculation
   double DiPlus, DiMinus, Adx;

   // Arrays as standard (0=oldest) to match loop
   // CopyBuffer creates standard arrays if target is dynamic and not set as series
   
   // Initialization Logic
   if(prev_calculated < min_rates_total) 
     {
      start = 1; // Start from index 1 because we need index 0 (i-1) for calculation
      
      // Initialize buffers
      ArrayInitialize(DiPlusBuffer, 0.0);
      ArrayInitialize(DiMinusBuffer, 0.0);
      ArrayInitialize(ADXBuffer, 0.0);
      
      // Reset State
      Last_DiPlus_ = 0.0;
      Last_DiMinus_ = 0.0;
      Last_Adx_ = 0.0;
     }
   else 
     {
      start = prev_calculated - 1; // Re-calculate last bar (open) and any new bars
     }

   // Copy data from ADX indicator
   // Copy everything from 0 (oldest available in ADX handle?) 
   // Note: CopyBuffer(..., 0, count, ...) copies from 'start_pos' index.
   // If handle is standard, 0 is newest? MQL5 iADX usually returns series-like access via CopyBuffer?
   // MQL5 "CopyBuffer" copies data. If we want 0=oldest in target locally, we need to handle that.
   // Actually, safe way: Copy all and check.
   
   // Using 'rates_total' to ensure we have aligned arrays.
   // Optimize: We can assume arrays align if we copy full history.
   if(CopyBuffer(ADX_Handle,0,0,rates_total,ADX)<=0) return(0);
   if(CopyBuffer(ADX_Handle,1,0,rates_total,DIP)<=0) return(0);
   if(CopyBuffer(ADX_Handle,2,0,rates_total,DIM)<=0) return(0);
   
   // Ensure local arrays are NOT series (0=oldest) to match forward loop
   ArraySetAsSeries(ADX, false);
   ArraySetAsSeries(DIP, false);
   ArraySetAsSeries(DIM, false);

   // Retrieve state for the loop start
   // Current 'running' state equals the committed state from (start-1)
   // Warning: if start=1, Last_DiPlus_ corresponds to index 0.
   DiPlus = Last_DiPlus_;
   DiMinus = Last_DiMinus_;
   Adx = Last_Adx_;

   for(int i = start; i < rates_total; i++)
     {
      // Original Formula adapted for Forward Loop:
      // Original (Series): [bar] is current, [bar+1] is older
      // Formula: 2*Val[current] + (alpha-2)*Val[older] + (1-alpha)*Smooth[older]
      // Forward: [i] is current, [i-1] is older
      
      // Level 1 Smoothing (Intermediate)
      // Uses Input Arrays (DIP, DIM, ADX) and Previous Intermediate State (DiPlus, etc.)
      DiPlus = 2 * DIP[i] + (alpha1 - 2) * DIP[i-1] + (1 - alpha1) * DiPlus;
      DiMinus = 2 * DIM[i] + (alpha1 - 2) * DIM[i-1] + (1 - alpha1) * DiMinus;
      Adx = 2 * ADX[i] + (alpha1 - 2) * ADX[i-1] + (1 - alpha1) * Adx;

      // Level 2 Smoothing (Output Buffers)
      // Buffer[current] = alpha2 * Intermediate + (1-alpha2) * Buffer[older]
      DiPlusBuffer[i] = alpha2 * DiPlus + (1 - alpha2) * DiPlusBuffer[i-1];
      DiMinusBuffer[i] = alpha2 * DiMinus + (1 - alpha2) * DiMinusBuffer[i-1];
      ADXBuffer[i] = alpha2 * Adx + (1 - alpha2) * ADXBuffer[i-1];
      
      // Update State Logic
      // If this bar (i) is a completed bar (not the forming bar at rates_total-1),
      // we save its intermediate state to static variables so we can resume from here next tick.
      if (i < rates_total - 1)
        {
         Last_DiPlus_ = DiPlus;
         Last_DiMinus_ = DiMinus;
         Last_Adx_ = Adx;
        }
     }
     
   return(rates_total);
  }
//+------------------------------------------------------------------+
