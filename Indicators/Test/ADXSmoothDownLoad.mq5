//+------------------------------------------------------------------+
//|                                                 ADX Smoothed.mq5 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2007, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   6

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlack
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label1  "Di Plus"

#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlack
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_label2  "Di Minus"

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrYellow
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
#property indicator_label3  "ADX"

#property indicator_type4   DRAW_LINE
#property indicator_color4  clrWhite
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
#property indicator_label4  "Average"

#property indicator_type5   DRAW_LINE
#property indicator_color5  clrWhite
#property indicator_style5  STYLE_DOT
#property indicator_width5  1
#property indicator_label5  "Upper Band"

#property indicator_type6   DRAW_LINE
#property indicator_color6  clrWhite
#property indicator_style6  STYLE_DOT
#property indicator_width6  1
#property indicator_label6  "Lower Band"

#property indicator_level1 88.0
#property indicator_level2 50.0
#property indicator_level3 12.0
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT

#include <mySmoothAlgorithm2.mqh>

input int    period = 14;
input double alpha1 = 0.25;
input double alpha2 = 0.33;
input int    PriceType=0;

input int    inpAvgPeriod    = 1000;  // Average period
input int    inpStdPeriod    = 4000;  // Std period

double DiPlusBuffer[];
double DiMinusBuffer[];
double ADXBuffer[];
double AvgADXBuffer[];
double stdPVal[];
double stdMVal[];
double ADXScale[];

int ADX_Handle;
int min_rates_total;

HiAverage *iAverage;
HiStdDev1 *iStdDev1;
bool g_IsWritten = false;

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
   
   SetIndexBuffer(3,AvgADXBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   SetIndexBuffer(4,stdPVal,INDICATOR_DATA);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   SetIndexBuffer(5,stdMVal,INDICATOR_DATA);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   SetIndexBuffer(6,ADXScale,INDICATOR_CALCULATIONS);
   
   string shortname;
   StringConcatenate(shortname,"ADX(",period,")smothed");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   IndicatorSetInteger(INDICATOR_DIGITS,1);
   
   // Initialize algorithm objects
   iAverage = new HiAverage((inpAvgPeriod > 1) ? inpAvgPeriod : 2);
   if(CheckPointer(iAverage) == POINTER_INVALID) Print("Init: HiAverage failed!");

   iStdDev1 = new HiStdDev1((inpStdPeriod > 1) ? inpStdPeriod : 2);
   if(CheckPointer(iStdDev1) == POINTER_INVALID) Print("Init: HiStdDev1 failed!");
  }
  
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(CheckPointer(iAverage) == POINTER_DYNAMIC) delete iAverage;
   if(CheckPointer(iStdDev1) == POINTER_DYNAMIC) delete iStdDev1;
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
      ArrayInitialize(AvgADXBuffer, 0.0);
      ArrayInitialize(stdPVal, 0.0);
      ArrayInitialize(stdMVal, 0.0);
      ArrayInitialize(ADXScale, 0.0);
      
      g_IsWritten = false;
      
      // Reset State
      Last_DiPlus_ = 0.0;
      Last_DiMinus_ = 0.0;
      Last_Adx_ = 0.0;
      
      // Re-create objects to clear their internal state
      if(CheckPointer(iAverage) == POINTER_DYNAMIC) delete iAverage;
      if(CheckPointer(iStdDev1) == POINTER_DYNAMIC) delete iStdDev1;
      iAverage = new HiAverage((inpAvgPeriod > 1) ? inpAvgPeriod : 2);
      iStdDev1 = new HiStdDev1((inpStdPeriod > 1) ? inpStdPeriod : 2);
     }
   else 
     {
      start = prev_calculated - 1; // Re-calculate last bar (open) and any new bars
     }

   if(CopyBuffer(ADX_Handle,0,0,rates_total,ADX)<=0) return(0);
   if(CopyBuffer(ADX_Handle,1,0,rates_total,DIP)<=0) return(0);
   if(CopyBuffer(ADX_Handle,2,0,rates_total,DIM)<=0) return(0);
   
   // Ensure local arrays are NOT series (0=oldest) to match forward loop
   ArraySetAsSeries(ADX, false);
   ArraySetAsSeries(DIP, false);
   ArraySetAsSeries(DIM, false);

   // Retrieve state for the loop start
   DiPlus = Last_DiPlus_;
   DiMinus = Last_DiMinus_;
   Adx = Last_Adx_;

   for(int i = start; i < rates_total; i++)
     {
      // Original Formula adapted for Forward Loop:
      // Level 1 Smoothing (Intermediate)
      DiPlus = 2 * DIP[i] + (alpha1 - 2) * DIP[i-1] + (1 - alpha1) * DiPlus;
      DiMinus = 2 * DIM[i] + (alpha1 - 2) * DIM[i-1] + (1 - alpha1) * DiMinus;
      Adx = 2 * ADX[i] + (alpha1 - 2) * ADX[i-1] + (1 - alpha1) * Adx;

      // Level 2 Smoothing (Output Buffers)
      DiPlusBuffer[i] = alpha2 * DiPlus + (1 - alpha2) * DiPlusBuffer[i-1];
      DiMinusBuffer[i] = alpha2 * DiMinus + (1 - alpha2) * DiMinusBuffer[i-1];
      ADXBuffer[i] = alpha2 * Adx + (1 - alpha2) * ADXBuffer[i-1];
      
      // Update State Logic
      if (i < rates_total - 1)
        {
         Last_DiPlus_ = DiPlus;
         Last_DiMinus_ = DiMinus;
         Last_Adx_ = Adx;
        }
        
      // Statistics Calculation
      if(CheckPointer(iAverage) != POINTER_INVALID && CheckPointer(iStdDev1) != POINTER_INVALID)
        {
         double avg = iAverage.Calculate(i, ADXBuffer[i]);
         double std = iStdDev1.Calculate(i, avg, ADXBuffer[i]);
         
         AvgADXBuffer[i] = avg;
         stdPVal[i] = avg + std;
         stdMVal[i] = avg - std;
         
         if(std != 0.)
           {
            ADXScale[i] = (ADXBuffer[i] - avg) / std;
           }
         else
           {
            if(i > 0) ADXScale[i] = ADXScale[i-1];
            else ADXScale[i] = 0.0;
           }
        }
     }
     
   // --- File Writing Logic ---
   if(rates_total > 0 && !g_IsWritten) 
     {
      string filename = "ADXSmooth_DownLoad.csv";
      int handle = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_ANSI);
      
      if(handle != INVALID_HANDLE) 
        {
         FileWrite(handle, "Time", "Open", "Close", "High", "Low", "ADX", "Average", "Scale");
         
         for(int k=0; k<rates_total; k++) 
           {
            string timeStr = TimeToString(time[k], TIME_DATE|TIME_MINUTES);
            // Write requested values: Time, OCHL, ADX, Average, Scale
            FileWrite(handle, timeStr, open[k], close[k], high[k], low[k], ADXBuffer[k], AvgADXBuffer[k], ADXScale[k]);
           }
         FileClose(handle);
         Print("Data download complete: ", filename);
         g_IsWritten = true;
        } 
      else 
        {
         Print("Failed to open file for writing: ", filename, " Error: ", GetLastError());
        }
     }
     
   return(rates_total);
  }
//+------------------------------------------------------------------+
