//+------------------------------------------------------------------+
//|                                                    BWMFI_MTF.mq5 |
//| AIEngine clean version — file writing logic removed              |
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

input ENUM_TIMEFRAMES InpTimeframe  = PERIOD_CURRENT;
input ENUM_APPLIED_VOLUME InpVolumeType=VOLUME_TICK;

double ExtMFIBuffer[];
double ExtColorBuffer[];

void OnInit()
  {
   SetIndexBuffer(0,ExtMFIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorBuffer,INDICATOR_COLOR_INDEX);

   string tf_name = EnumToString(InpTimeframe);
   if(InpTimeframe == PERIOD_CURRENT) tf_name = EnumToString(Period());
   string short_name = "BWMFI(" + tf_name + ")";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
  }

void CalculateMFI_Logic(const int start, const int total, 
                        const double &high[], const double &low[], const long &volume[],
                        double &mfi_buffer[], double &color_buffer[])
{
   for(int i=start; i<total && !IsStopped(); i++)
     {
      if(volume[i] == 0)
        {
         if(i > 0) mfi_buffer[i] = mfi_buffer[i-1];
         else      mfi_buffer[i] = 0.0;
        }
      else
        {
         mfi_buffer[i] = (high[i] - low[i]) / _Point / volume[i];
        }

      if(i > 0)
        {
         bool mfi_up, vol_up;

         if(mfi_buffer[i] > mfi_buffer[i-1]) mfi_up = true;
         else if(mfi_buffer[i] < mfi_buffer[i-1]) mfi_up = false;
         else {
             int k = i - 1;
             while(k >= 0 && mfi_buffer[k] == mfi_buffer[k+1]) k--;
             if(k >= 0) mfi_up = (mfi_buffer[k+1] > mfi_buffer[k]);
             else mfi_up = true;
         }
         
         if(volume[i] > volume[i-1]) vol_up = true;
         else if(volume[i] < volume[i-1]) vol_up = false;
         else {
             int k = i - 1;
             while(k >= 0 && volume[k] == volume[k+1]) k--;
             if(k >= 0) vol_up = (volume[k+1] > volume[k]);
             else vol_up = true;
         }

         if(mfi_up && vol_up)        color_buffer[i] = 0.0;
         if(!mfi_up && !vol_up)      color_buffer[i] = 1.0;
         if(mfi_up && !vol_up)       color_buffer[i] = 2.0;
         if(!mfi_up && vol_up)       color_buffer[i] = 3.0;
        }
      else
        {
         color_buffer[i] = 0.0;
        }
     }
}

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
   if(InpTimeframe == PERIOD_CURRENT || InpTimeframe == Period())
     {
      int start = (prev_calculated > 0) ? prev_calculated - 1 : 0;
      
      if(InpVolumeType == VOLUME_TICK)
         CalculateMFI_Logic(start, rates_total, high, low, tick_volume, ExtMFIBuffer, ExtColorBuffer);
      else
         CalculateMFI_Logic(start, rates_total, high, low, volume, ExtMFIBuffer, ExtColorBuffer);
         
      return rates_total;
     }

   int bars_target = iBars(Symbol(), InpTimeframe);
   if(bars_target < 2) return 0;
   
   MqlRates target_rates[];
   ArraySetAsSeries(target_rates, true);
   
   int copied = CopyRates(Symbol(), InpTimeframe, 0, bars_target, target_rates);
   if(copied <= 0) return 0;
   
   ArraySetAsSeries(target_rates, false);
   
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
     
   CalculateMFI_Logic(0, target_total, target_high, target_low, target_vol, target_mfi, target_col);
   
   int start_idx = (prev_calculated > 0) ? prev_calculated - 1 : 0;

   datetime target_current_time = iTime(Symbol(), InpTimeframe, 0);
   int current_tf_start_idx = iBarShift(Symbol(), Period(), target_current_time, false);
   
   if(current_tf_start_idx >= 0 && current_tf_start_idx < rates_total)
     {
      if(start_idx > current_tf_start_idx)
         start_idx = current_tf_start_idx;
     }
   
   for(int i=start_idx; i<rates_total; i++)
     {
      datetime bar_time = time[i];
      int shift = iBarShift(Symbol(), InpTimeframe, bar_time, false);
      
      if(shift < 0) 
        {
         ExtMFIBuffer[i] = 0; 
         ExtColorBuffer[i] = 0;
         continue;
        }
        
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
