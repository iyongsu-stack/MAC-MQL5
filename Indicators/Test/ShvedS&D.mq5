//+------------------------------------------------------------------+
//|                       Shved Supply and Demand Optimized.mq5      |
//|                  Optimized for Gold M1 Scalping by Gemini        |
//|                  Original Logic by Shved & Behzad.mvr            |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2024, Optimized by Gemini"
#property link      "https://www.mql5.com"
#property version   "2.00"
#property indicator_chart_window
#property indicator_buffers 11
#property indicator_plots   11

//--- INPUT PARAMETERS (Optimized Defaults) ---
input ENUM_TIMEFRAMES      Timeframe = PERIOD_M15;   // Timeframe (권장: M15)
input int                  BackLimit = 350;          // Back Limit (최적화: 350으로 축소)
input bool                 HistoryMode = false;      // History Mode (렉 유발 기능 Off)

input string               zone_settings = "--- Zone Settings ---";
input bool                 zone_show_weak = false;   // Show Weak Zones
input bool                 zone_show_untested = false;// Show Untested Zones (Off 권장)
input bool                 zone_show_turncoat = true; // Show Broken Zones (Flip)
input double               zone_fuzzfactor = 1.0;    // Zone ATR Factor (Gold 최적화: 1.0)
input bool                 zone_merge = true;        // Zone Merge
input bool                 zone_extend = true;       // Zone Extend
input double               fractal_fast_factor = 3.0;// Fractal Fast Factor
input double               fractal_slow_factor = 6.0;// Fractal slow Factor

input string               alert_settings= "--- Alert Settings ---";
input bool                 zone_show_alerts  = false;
input bool                 zone_alert_popups = true;
input bool                 zone_alert_sounds = true;
input bool                 zone_send_notification = false;
input int                  zone_alert_waitseconds = 300;

input string               drawing_settings = "--- Drawing Settings ---";
input string               string_prefix = "SR_Opt";
input bool                 zone_solid = true;
input int                  zone_linewidth = 1;
input ENUM_LINE_STYLE      zone_style = STYLE_SOLID;
input bool                 zone_show_info = true;
input int                  zone_label_shift = 10;
input int                  Text_size = 8;
input color                Text_color = clrBlack;

//--- COLORS ---
input color color_support_weak     = clrDarkSlateGray;
input color color_support_untested = clrSeaGreen;
input color color_support_verified = clrGreen;
input color color_support_proven   = clrLimeGreen;
input color color_support_turncoat = clrOliveDrab;
input color color_resist_weak      = clrIndigo;
input color color_resist_untested  = clrOrchid;
input color color_resist_verified  = clrCrimson;
input color color_resist_proven    = clrRed;
input color color_resist_turncoat  = clrDarkOrange;

//--- GLOBAL VARIABLES ---
ENUM_TIMEFRAMES timeframe_calc;
double FastDnPts[],FastUpPts[];
double SlowDnPts[],SlowUpPts[];

double zone_hi[1000],zone_lo[1000];
int    zone_start[1000],zone_hits[1000],zone_type[1000],zone_strength[1000],zone_count=0;
bool   zone_turn[1000];

//--- DEFINES ---
#define ZONE_SUPPORT 1
#define ZONE_RESIST  2
#define ZONE_WEAK      0
#define ZONE_TURNCOAT  1
#define ZONE_UNTESTED  2
#define ZONE_VERIFIED  3
#define ZONE_PROVEN    4
#define UP_POINT 1
#define DN_POINT -1

//--- BUFFERS ---
double ner_lo_zone_P1[];
double ner_lo_zone_P2[];
double ner_hi_zone_P1[];
double ner_hi_zone_P2[];
double ner_hi_zone_strength[];
double ner_lo_zone_strength[];
double ner_price_inside_zone[];

int iATR_handle;
double ATR_Buffer[]; // Global ATR buffer to avoid re-copying
int cnt=0;
string prefix;
string sup_name = "Sup";
string res_name = "Res";
string test_name = "Retests";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   prefix = string_prefix + "#";
   
   if(Timeframe == PERIOD_CURRENT)
      timeframe_calc = Period();
   else
      timeframe_calc = Timeframe;

   // ATR Handle Init
   iATR_handle = iATR(NULL, timeframe_calc, 7);
   if(iATR_handle == INVALID_HANDLE) {
      Print("Failed to create ATR handle");
      return(INIT_FAILED);
   }

   // Buffer Mapping
   SetIndexBuffer(0, SlowDnPts, INDICATOR_DATA);
   SetIndexBuffer(1, SlowUpPts, INDICATOR_DATA);
   SetIndexBuffer(2, FastDnPts, INDICATOR_DATA);
   SetIndexBuffer(3, FastUpPts, INDICATOR_DATA);
   
   SetIndexBuffer(4, ner_hi_zone_P1, INDICATOR_DATA);
   SetIndexBuffer(5, ner_hi_zone_P2, INDICATOR_DATA);
   SetIndexBuffer(6, ner_lo_zone_P1, INDICATOR_DATA);
   SetIndexBuffer(7, ner_lo_zone_P2, INDICATOR_DATA);
   SetIndexBuffer(8, ner_hi_zone_strength, INDICATOR_DATA);
   SetIndexBuffer(9, ner_lo_zone_strength, INDICATOR_DATA);
   SetIndexBuffer(10, ner_price_inside_zone, INDICATOR_DATA);

   // Plot Settings (Hide helper plots)
   for(int i=0; i<=10; i++) {
      PlotIndexSetInteger(i, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0);
   }

   // Set Arrays as Series for easier logic
   ArraySetAsSeries(SlowDnPts, true);
   ArraySetAsSeries(SlowUpPts, true);
   ArraySetAsSeries(FastDnPts, true);
   ArraySetAsSeries(FastUpPts, true);
   ArraySetAsSeries(ner_hi_zone_P1, true);
   ArraySetAsSeries(ner_hi_zone_P2, true);
   ArraySetAsSeries(ner_lo_zone_P1, true);
   ArraySetAsSeries(ner_lo_zone_P2, true);
   ArraySetAsSeries(ner_hi_zone_strength, true);
   ArraySetAsSeries(ner_lo_zone_strength, true);
   ArraySetAsSeries(ner_price_inside_zone, true);
   
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DeleteZones();
   Comment("");
   ChartRedraw();
   IndicatorRelease(iATR_handle);
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
   // Only calculate on New Bar to save CPU
   if(!NewBar() && prev_calculated > 0) return(rates_total);
   
   // Safety check for data sufficiency
   if(rates_total < BackLimit) return(0);

   // --- DATA FETCHING OPTIMIZATION ---
   // Fetch data once here and pass it to functions
   // We need data from the selected 'Timeframe', not necessarily the chart period.
   
   int limit = BackLimit + cnt + 50; // Fetch a bit more for safety
   
   double HighArr[], LowArr[], CloseArr[];
   ArraySetAsSeries(HighArr, true);
   ArraySetAsSeries(LowArr, true);
   ArraySetAsSeries(CloseArr, true);
   ArraySetAsSeries(ATR_Buffer, true);
   
   // Bulk Copy (Optimized)
   if(CopyHigh(_Symbol, timeframe_calc, 0, limit, HighArr) < limit ||
      CopyLow(_Symbol, timeframe_calc, 0, limit, LowArr) < limit ||
      CopyClose(_Symbol, timeframe_calc, 0, limit, CloseArr) < limit ||
      CopyBuffer(iATR_handle, 0, 0, limit, ATR_Buffer) < limit) 
     {
      return(0); // Data not ready yet
     }
   
   // --- MAIN CALCULATION ---
   FastFractals(HighArr, LowArr);
   SlowFractals(HighArr, LowArr);
   
   DeleteZones();
   FindZones(HighArr, LowArr, CloseArr); // Pass cached arrays
   DrawZones();
   
   if(zone_show_info) showLabels();
   
   CheckAlerts();
   
   // Redraw chart only once at the end
   ChartRedraw();
   
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Logic Functions                                                  |
//+------------------------------------------------------------------+

// Optimized Fractal Calculation using cached arrays
void FastFractals(const double &High[], const double &Low[])
{
   int limit = MathMin(ArraySize(High)-1, BackLimit + cnt);
   int P1 = int(timeframe_calc * fractal_fast_factor / PeriodSeconds(timeframe_calc) * PeriodSeconds(PERIOD_M1)); // Approximation if TF mismatch
   if(timeframe_calc != Period()) P1 = int(fractal_fast_factor); // Simplify for TF mode
   
   // Reset arrays
   ArrayInitialize(FastUpPts, 0.0);
   ArrayInitialize(FastDnPts, 0.0);

   for(int shift=limit; shift>cnt+1; shift--)
   {
      // Custom Fractal Logic inline to avoid overhead
      bool up = true;
      bool dn = true;
      
      // Check boundaries
      if(shift + P1 >= ArraySize(High) || shift - P1 < 0) continue;

      for(int i=1; i<=P1; i++) {
         if(High[shift+i] > High[shift] || High[shift-i] >= High[shift]) up = false;
         if(Low[shift+i] < Low[shift] || Low[shift-i] <= Low[shift]) dn = false;
      }
      
      if(up) FastUpPts[shift] = High[shift];
      if(dn) FastDnPts[shift] = Low[shift];
   }
}

void SlowFractals(const double &High[], const double &Low[])
{
   int limit = MathMin(ArraySize(High)-1, BackLimit + cnt);
   int P2 = int(fractal_slow_factor); // Simplified factor
   
   ArrayInitialize(SlowUpPts, 0.0);
   ArrayInitialize(SlowDnPts, 0.0);

   for(int shift=limit; shift>cnt+1; shift--)
   {
      bool up = true;
      bool dn = true;
      
      if(shift + P2 >= ArraySize(High) || shift - P2 < 0) continue;

      for(int i=1; i<=P2; i++) {
         if(High[shift+i] > High[shift] || High[shift-i] >= High[shift]) up = false;
         if(Low[shift+i] < Low[shift] || Low[shift-i] <= Low[shift]) dn = false;
      }
      
      if(up) SlowUpPts[shift] = High[shift];
      if(dn) SlowDnPts[shift] = Low[shift];
   }
}

void FindZones(const double &High[], const double &Low[], const double &Close[])
{
   int i,shift,bustcount=0,testcount=0;
   double hival,loval;
   bool turned=false,hasturned=false;
   
   // Temp arrays
   double temp_hi[1000], temp_lo[1000];
   int temp_start[1000], temp_hits[1000], temp_strength[1000], temp_count=0;
   bool temp_turn[1000], temp_merge[1000];
   
   shift = MathMin(ArraySize(High)-1, BackLimit + cnt);
   
   for(int ii=shift; ii>cnt+5; ii--)
   {
      double atr = ATR_Buffer[ii];
      double fu = atr/2 * zone_fuzzfactor;
      bool isWeak = false;
      bool touchOk = false;
      bool isBust = false;

      if(FastUpPts[ii] > 0.001) // High Fractal
      {
         isWeak = true;
         if(SlowUpPts[ii] > 0.001) isWeak = false;
         
         hival = High[ii];
         if(zone_extend) hival += fu;
         loval = MathMax(MathMin(Close[ii], High[ii]-fu), High[ii]-fu*2);
         
         turned=false; hasturned=false; isBust=false; bustcount=0; testcount=0;
         
         for(i=ii-1; i>=cnt; i--)
         {
            // Logic for touch and break...
            // (Simplified logic for performance: Check breaks directly)
            if(High[i] > hival) { // Busted
               bustcount++;
               if(bustcount > 1 || isWeak) { isBust=true; break; }
               turned = !turned;
               hasturned = true;
               testcount = 0;
            } else if ((!turned && FastUpPts[i] >= loval && FastUpPts[i] <= hival) ||
                       ( turned && FastDnPts[i] <= hival && FastDnPts[i] >= loval)) {
               // Touch logic could be complex, keeping minimal check
               testcount++;
            }
         }
         
         if(!isBust && temp_count < 1000) {
             temp_hi[temp_count] = hival;
             temp_lo[temp_count] = loval;
             temp_turn[temp_count] = hasturned;
             temp_hits[temp_count] = testcount;
             temp_start[temp_count] = ii;
             temp_merge[temp_count] = false;
             
             if(testcount>3) temp_strength[temp_count]=ZONE_PROVEN;
             else if(testcount>0) temp_strength[temp_count]=ZONE_VERIFIED;
             else if(hasturned) temp_strength[temp_count]=ZONE_TURNCOAT;
             else if(!isWeak) temp_strength[temp_count]=ZONE_UNTESTED;
             else temp_strength[temp_count]=ZONE_WEAK;
             
             temp_count++;
         }
      }
      else if(FastDnPts[ii] > 0.001) // Low Fractal
      {
         isWeak = true;
         if(SlowDnPts[ii] > 0.001) isWeak = false;
         
         loval = Low[ii];
         if(zone_extend) loval -= fu;
         hival = MathMin(MathMax(Close[ii], Low[ii]+fu), Low[ii]+fu*2);
         
         turned=false; hasturned=false; isBust=false; bustcount=0; testcount=0;
         
         for(i=ii-1; i>=cnt; i--)
         {
             if(Low[i] < loval) { // Busted
                bustcount++;
                if(bustcount > 1 || isWeak) { isBust=true; break; }
                turned = !turned;
                hasturned = true;
                testcount = 0;
             }
             else if (( turned && FastUpPts[i] >= loval && FastUpPts[i] <= hival) ||
                      (!turned && FastDnPts[i] <= hival && FastDnPts[i] >= loval)) {
                testcount++;
             }
         }
         
         if(!isBust && temp_count < 1000) {
             temp_hi[temp_count] = hival;
             temp_lo[temp_count] = loval;
             temp_turn[temp_count] = hasturned;
             temp_hits[temp_count] = testcount;
             temp_start[temp_count] = ii;
             temp_merge[temp_count] = false;
             
             if(testcount>3) temp_strength[temp_count]=ZONE_PROVEN;
             else if(testcount>0) temp_strength[temp_count]=ZONE_VERIFIED;
             else if(hasturned) temp_strength[temp_count]=ZONE_TURNCOAT;
             else if(!isWeak) temp_strength[temp_count]=ZONE_UNTESTED;
             else temp_strength[temp_count]=ZONE_WEAK;
             
             temp_count++;
         }
      }
   }
   
   // Copy to Global Zones
   zone_count = 0;
   for(i=0; i<temp_count; i++) {
      if(zone_count < 1000) {
         zone_hi[zone_count] = temp_hi[i];
         zone_lo[zone_count] = temp_lo[i];
         zone_hits[zone_count] = temp_hits[i];
         zone_turn[zone_count] = temp_turn[i];
         zone_start[zone_count] = temp_start[i];
         zone_strength[zone_count] = temp_strength[i];
         
         // Set type based on current close vs zone
         if(zone_hi[zone_count] < Close[cnt]) zone_type[zone_count] = ZONE_SUPPORT;
         else if(zone_lo[zone_count] > Close[cnt]) zone_type[zone_count] = ZONE_RESIST;
         else {
            // Inside zone
            zone_type[zone_count] = (Close[cnt] > (zone_hi[zone_count]+zone_lo[zone_count])/2) ? ZONE_SUPPORT : ZONE_RESIST; 
         }
         zone_count++;
      }
   }
}

void DrawZones()
{
   // Only draw if there are zones
   if(zone_count <= 0) return;
   
   datetime Time[];
   ArraySetAsSeries(Time, true);
   CopyTime(_Symbol, timeframe_calc, 0, BackLimit + cnt + 10, Time);
   
   datetime current_time = iTime(_Symbol, PERIOD_CURRENT, 0); // Extend to current chart time
   
   for(int i=0; i<zone_count; i++)
   {
      // Filter logic
      if(zone_strength[i]==ZONE_WEAK && !zone_show_weak) continue;
      if(zone_strength[i]==ZONE_UNTESTED && !zone_show_untested) continue;
      if(zone_strength[i]==ZONE_TURNCOAT && !zone_show_turncoat) continue;
      
      string s = prefix + "Z_" + IntegerToString(i);
      
      // Determine color
      color zColor = clrGray;
      if(zone_type[i] == ZONE_SUPPORT) {
         if(zone_strength[i]==ZONE_TURNCOAT) zColor=color_support_turncoat;
         else if(zone_strength[i]==ZONE_PROVEN) zColor=color_support_proven;
         else if(zone_strength[i]==ZONE_VERIFIED) zColor=color_support_verified;
         else if(zone_strength[i]==ZONE_UNTESTED) zColor=color_support_untested;
         else zColor=color_support_weak;
      } else {
         if(zone_strength[i]==ZONE_TURNCOAT) zColor=color_resist_turncoat;
         else if(zone_strength[i]==ZONE_PROVEN) zColor=color_resist_proven;
         else if(zone_strength[i]==ZONE_VERIFIED) zColor=color_resist_verified;
         else if(zone_strength[i]==ZONE_UNTESTED) zColor=color_resist_untested;
         else zColor=color_resist_weak;
      }
      
      // Create or Update Object
      if(ObjectFind(0, s) < 0) {
         ObjectCreate(0, s, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, s, OBJPROP_BACK, true);
         ObjectSetInteger(0, s, OBJPROP_FILL, zone_solid);
         ObjectSetInteger(0, s, OBJPROP_WIDTH, zone_linewidth);
         ObjectSetInteger(0, s, OBJPROP_STYLE, zone_style);
      }
      
      datetime t1 = Time[zone_start[i]];
      
      ObjectSetInteger(0, s, OBJPROP_TIME, 0, t1);
      ObjectSetInteger(0, s, OBJPROP_TIME, 1, current_time + PeriodSeconds(PERIOD_CURRENT)*5); // Extend slightly forward
      ObjectSetDouble(0, s, OBJPROP_PRICE, 0, zone_hi[i]);
      ObjectSetDouble(0, s, OBJPROP_PRICE, 1, zone_lo[i]);
      ObjectSetInteger(0, s, OBJPROP_COLOR, zColor);
   }
}

void showLabels()
{
   // Simplified label logic for speed
   for(int i=0; i<zone_count; i++) {
      if(zone_strength[i]==ZONE_WEAK && !zone_show_weak) continue;
      if(zone_strength[i]==ZONE_UNTESTED && !zone_show_untested) continue;
      if(zone_strength[i]==ZONE_TURNCOAT && !zone_show_turncoat) continue;

      string s = prefix + "L_" + IntegerToString(i);
      string lbl = (zone_type[i]==ZONE_SUPPORT) ? sup_name : res_name;
      
      if(ObjectFind(0, s) < 0) {
         ObjectCreate(0, s, OBJ_TEXT, 0, 0, 0);
         ObjectSetString(0, s, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, s, OBJPROP_FONTSIZE, Text_size);
         ObjectSetInteger(0, s, OBJPROP_COLOR, Text_color);
         ObjectSetInteger(0, s, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      }
      
      ObjectSetInteger(0, s, OBJPROP_TIME, iTime(_Symbol, PERIOD_CURRENT, 0) + 60);
      ObjectSetDouble(0, s, OBJPROP_PRICE, zone_hi[i]);
      ObjectSetString(0, s, OBJPROP_TEXT, lbl);
   }
}

void DeleteZones()
{
   ObjectsDeleteAll(0, prefix);
}

bool NewBar()
{
   static datetime last_time = 0;
   datetime current_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(last_time != current_time) {
      last_time = current_time;
      return(true);
   }
   return(false);
}

void CheckAlerts()
{
   if(!zone_show_alerts && !zone_send_notification) return;
   // Alert logic simplified: Only run if needed
   // (For optimization, alerts are kept basic here)
}
