//+------------------------------------------------------------------+
//|                                                    BWMFI_MTF.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Lime,SaddleBrown,Blue,Pink
#property indicator_width1  2

//--- input parameters
input ENUM_TIMEFRAMES InpTimeframe  = PERIOD_CURRENT; // Timeframe
input ENUM_APPLIED_VOLUME InpVolumeType=VOLUME_TICK;  // Volumes

//---- buffers
double ExtMFIBuffer[];
double ExtColorBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- indicators
   SetIndexBuffer(0,ExtMFIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorBuffer,INDICATOR_COLOR_INDEX);

//--- name for DataWindow
   string tf_name = EnumToString(InpTimeframe);
   if(InpTimeframe == PERIOD_CURRENT) tf_name = EnumToString(Period());
   string short_name = "BWMFI(" + tf_name + ")";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
  }

//+------------------------------------------------------------------+
//| Calculate MFI Logic (Generic)                                    |
//+------------------------------------------------------------------+
void CalculateMFI_Logic(const int start, const int total, 
                        const double &high[], const double &low[], const long &volume[],
                        double &mfi_buffer[], double &color_buffer[])
{
   for(int i=start; i<total && !IsStopped(); i++)
     {
      // 1. Calculate MFI
      if(volume[i] == 0)
        {
         if(i > 0) mfi_buffer[i] = mfi_buffer[i-1];
         else      mfi_buffer[i] = 0.0;
        }
      else
        {
         mfi_buffer[i] = (high[i] - low[i]) / _Point / volume[i];
        }

      // 2. Determine Color
      // Need comparison with previous bar
      if(i > 0)
        {
         bool mfi_up = (mfi_buffer[i] > mfi_buffer[i-1]);
         bool vol_up = (volume[i] > volume[i-1]);
         
         // Logic for 'false' (down or equal):
         // Usually equal is treated as down or same? Original code treats strict > and <. 
         // Original code: if(ExtMFIBuffer[n]>ExtMFIBuffer[n-1]) ...
         // Let's refine strict match to original:
         // If equal, it maintains previous 'up' state? 
         // Looking at original: 
         // while(n>0) { if >... break; if <... break; n--; } -> Recovers state from history if equal.
         // Simpler approach for generic loop:
         if(mfi_buffer[i] == mfi_buffer[i-1]) mfi_up = false; // Simplified, or standard: EQUAL usually doesn't change color, or treated as down?
         // Original code scans back if equal. Let's do simplistic check for now or replicate scan back.
         
         // Replicating scan back is expensive in loop.
         // Effectively: if Equal, use previous state?
         // Optimized: track state in variables.
         
         // But wait, the standard logic:
         // Green (0): MFI Up, Vol Up
         // Fade (1): MFI Down, Vol Down
         // Fake (2): MFI Up, Vol Down
         // Squat (3): MFI Down, Vol Up
         
         // Assuming > is Up, <= is Down for simplicity, or strict?
         
         if(mfi_buffer[i] > mfi_buffer[i-1]) mfi_up = true;
         else if(mfi_buffer[i] < mfi_buffer[i-1]) mfi_up = false;
         else {
             // Equal: find last non-equal
             int k = i - 1;
             while(k >= 0 && mfi_buffer[k] == mfi_buffer[k+1]) k--;
             if(k >= 0) mfi_up = (mfi_buffer[k+1] > mfi_buffer[k]);
             else mfi_up = true; // Default
         }
         
         if(volume[i] > volume[i-1]) vol_up = true;
         else if(volume[i] < volume[i-1]) vol_up = false;
         else {
             int k = i - 1;
             while(k >= 0 && volume[k] == volume[k+1]) k--;
             if(k >= 0) vol_up = (volume[k+1] > volume[k]);
             else vol_up = true;
         }

         if(mfi_up && vol_up)        color_buffer[i] = 0.0; // Green
         if(!mfi_up && !vol_up)      color_buffer[i] = 1.0; // Fade (Brown)
         if(mfi_up && !vol_up)       color_buffer[i] = 2.0; // Fake (Blue)
         if(!mfi_up && vol_up)       color_buffer[i] = 3.0; // Squat (Pink)
        }
      else
        {
         color_buffer[i] = 0.0; // Default first bar
        }
     }
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
   // If Timeframe is CURRENT
   if(InpTimeframe == PERIOD_CURRENT || InpTimeframe == Period())
     {
      int start = (prev_calculated > 0) ? prev_calculated - 1 : 0;
      
      // Select Volume array
      // Note: We cannot pass 'volume' or 'tick_volume' conditionally easily if types differ?
      // Both are 'long'.
      
      if(InpVolumeType == VOLUME_TICK)
         CalculateMFI_Logic(start, rates_total, high, low, tick_volume, ExtMFIBuffer, ExtColorBuffer);
      else
         CalculateMFI_Logic(start, rates_total, high, low, volume, ExtMFIBuffer, ExtColorBuffer);
         
      return rates_total;
     }

   // --- MULTI-TIMEFRAME CALCULATION ---
   
   // 1. Check Target Data Availability
   int bars_target = iBars(Symbol(), InpTimeframe);
   if(bars_target < 2) return 0;
   
   // 2. Fetch Target Data
   // We need to fetch enough data. To be safe/simple, fetch all or a significant optimization.
   // Optimized: Map current time[0] to target index, and time[total] to target index.
   // For correctness and simplicity in "Test" indicator, let's copy a safe amount.
   
   MqlRates target_rates[];
   ArraySetAsSeries(target_rates, true); // Series=true means 0 is Newest
   
   // Copying needed amount
   // Check first required time
   datetime start_time = time[rates_total - 1]; // Oldest on chart if series?
   // Note: OnCalculate arrays (time, open...) availability depends on ArraySetAsSeries.
   // By default OnCalculate arrays are NOT Series (0=Oldest) unless set.
   // Standard approach: 0 is Oldest.
   
   int copied = CopyRates(Symbol(), InpTimeframe, 0, bars_target, target_rates);
   if(copied <= 0) return 0;
   
   // target_rates is SERIES (0=Newest)
   // Let's create temp arrays for calculation (simulating high, low, volume)
   // We need them in 0=Oldest for our Calc Logic?
   // Or adapt Logic.
   // Our Logic is 0=Oldest (i++).
   
   // Reorder target_rates to 0=Oldest?
   // Or just use Series=false.
   ArraySetAsSeries(target_rates, false); // 0=Oldest
   
   int target_total = copied;
   double target_high[]; ArrayResize(target_high, target_total);
   double target_low[];  ArrayResize(target_low, target_total);
   long   target_vol[];  ArrayResize(target_vol, target_total);
   double target_mfi[];  ArrayResize(target_mfi, target_total);
   double target_col[];  ArrayResize(target_col, target_total);
   
   for(int i=0; i<target_total; i++)
     {
      target_high[i] = target_rates[i].high;
      target_low[i]  = target_rates[i].low;
      target_vol[i]  = (InpVolumeType == VOLUME_TICK) ? target_rates[i].tick_volume : target_rates[i].real_volume;
     }
     
   // Calculate on Target Data
   CalculateMFI_Logic(0, target_total, target_high, target_low, target_vol, target_mfi, target_col);
   
   // Map to Current Chart
   int start_idx = (prev_calculated > 0) ? prev_calculated - 1 : 0;

   // FIX: Force recalculation of ALL bars belonging to the current (forming) Target Bar.
   // Otherwise, closed M1 bars within the current M5 bar will retain their "old" M5 state.
   datetime target_current_time = iTime(Symbol(), InpTimeframe, 0);
   int current_tf_start_idx = iBarShift(Symbol(), Period(), target_current_time, false);
   
   // If valid index found, assume we must update from there to the end
   if(current_tf_start_idx >= 0 && current_tf_start_idx < rates_total)
     {
      // If our optimized start_idx is AFTER the beginning of the current TF bar,
      // pull it back to the beginning of the current TF bar.
      if(start_idx > current_tf_start_idx)
         start_idx = current_tf_start_idx;
     }
   
   for(int i=start_idx; i<rates_total; i++)
     {
      // Find corresponding bar in Target TF
      // iBarShift (Symbol, TF, Time[i], exact=false)
      // returns index in Series or Non-Series? 
      // iBarShift returns index as if Series (0=Newest) is TRUE by default? No.
      // Documentation: "Returned value is the index of the bar...".
      // Usually matches the ArraySetAsSeries setting?
      // Actually iBarShift always returns index based on "Series" numbering (0 is newest)? 
      // Wait, MQL5 iBarShift behavior: "Returns the index of the bar which covers the specified time."
      // If we use CopyRates with 0=Oldest, our array indices are 0..N-1 (Old->New).
      // But iBarShift returns index relative to current time (0=Latest).
      // So if iBarShift returns 0, it means the latest bar. In our 0=Oldest array, that is index (Total-1).
      // So IndexInOldestArray = Total - 1 - iBarShiftIndex.
      
      datetime bar_time = time[i];
      int shift = iBarShift(Symbol(), InpTimeframe, bar_time, false);
      
      if(shift < 0) 
        {
         ExtMFIBuffer[i] = 0; 
         ExtColorBuffer[i] = 0;
         continue;
        }
        
      // Convert shift to our array index (0=Oldest)
      int target_idx_poly = target_total - 1 - shift;
      
      if(target_idx_poly >= 0 && target_idx_poly < target_total)
        {
         ExtMFIBuffer[i]   = target_mfi[target_idx_poly];
         ExtColorBuffer[i] = target_col[target_idx_poly];
        }
      else
        {
         ExtMFIBuffer[i] = 0;
        }
     }
     
   return rates_total;
  }
//+------------------------------------------------------------------+