//+------------------------------------------------------------------+
//|       ATR without iATR() with smoothing Wilder by William210.mq5 |
//|                                       Copyright 2024, William210 |
//|                         https://www.mql5.com/fr/users/william210 |
//+------------------------------------------------------------------+
//+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
//+-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
#property copyright "Copyright 2024, William210"
#property link      "https://www.mql5.com/fr/users/william210"
#property version   "1.00" // 1022

//+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
// --- Include necessary libraries

#property description "ATR without iATR() with smoothing Wilder^n"
#property description "If this code malfunctions for whatever reasons, forgetting or MQL5 upgrades\nlet me know so I can correct it, thank you\n"
#property description "May this code help you\n"
#property description "You can find all of my multi-timeFrame or non-multi-timeFrame indicator codes in CodeBase or the Marketplace, free or purchasable, by searching for William210."

//+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
// --- Variables
double g_ATRCurr[]; //  Current ATR
double g_TRCal[];  // ATR Calculations

bool g_IsWritten = false; // 파일 작성 여부 확인용 플래그

#define g_ATRCurInd 0
#define g_TRCalInd  1

#property indicator_separate_window
//+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
// --- Declare indicator preferences with input parameters and comments
input group "ATR without iATR() with smoothingWilder"
input uchar g_ATRPeriod   = 14;            // ATR Period

//+-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
// ---  Buffer declaration
#property   indicator_buffers    2   // Number of buffers
#property   indicator_plots      1   // Number of plots on the graph


//+-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
// --- Specify indicator display properties
#property indicator_label1  "Current ATR "            // Label
#property indicator_type1   DRAW_LINE        // Plot type
#property indicator_color1  clrLightSeaGreen // Color
#property indicator_style1  STYLE_SOLID      // Plot style
#property indicator_width1  1                // Plot width


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
//+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
//+-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
int OnInit()

{
//+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
// --- Assign data buffers to indicator plots
//+-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
  if( ! SetIndexBuffer( g_ATRCurInd,   g_ATRCurr,  INDICATOR_DATA))

  {
    PrintFormat( "%s: Error %d SetIndexBuffer( g_ATRCurInd)", __FUNCTION__, GetLastError());
    return(INIT_FAILED);
  }

//+-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
  if( ! SetIndexBuffer( g_TRCalInd,   g_TRCal,  INDICATOR_CALCULATIONS))

  {
    PrintFormat( "%s: Error %d SetIndexBuffer( g_ATRCalInd)", __FUNCTION__, GetLastError());
    return(INIT_FAILED);
  }

//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
//+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
//+-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
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
//+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
//+-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
// --- Determine Starting Index for Calculations
  int i_Start;            // Start of patch
  double i_Cumul = 0.0;   // Cumulative TR

  if( prev_calculated == 0)

  {
    // --- During the first run, ensure enough bars are available for calculations
    i_Start = g_ATRPeriod + 1;

    //+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
    // --- Initialize buffers with empty values
    ArrayInitialize( g_ATRCurr, EMPTY_VALUE);
    ArrayInitialize( g_TRCal, EMPTY_VALUE);
    g_IsWritten = false; // 초기화 시 파일 쓰기 플래그 리셋

    //+-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
    // --- First Values
    for( int i = 1; i < g_ATRPeriod + 1 && !IsStopped(); i++)

    {
      g_TRCal[ i] = MathMax( high[ i], close[ i - 1]) - MathMin( low[ i], close[ i - 1]);
      i_Cumul += g_TRCal[ i];
    }

    i_Cumul /= g_ATRPeriod;
    g_ATRCurr[ g_ATRPeriod] = i_Cumul;
  }

  else

  {

    i_Start = prev_calculated;
  }

//+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
// --- With this code, the average is only updated when a new bar is opened
  if( prev_calculated < rates_total)

  {
    for( int i = i_Start; i < rates_total && !IsStopped(); i++)

    {
      g_TRCal  [ i]   = MathMax( high[ i], close[ i - 1]) - MathMin( low[ i], close[i  - 1]);
      g_ATRCurr[ i]   = g_ATRCurr[ i - 1] + ( g_TRCal[ i] - g_TRCal[i - g_ATRPeriod]) / g_ATRPeriod;

    }
  }

//+-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-__-
  // --- File Writing Logic ---
  Print("Check Write: rates_total=", rates_total, " g_IsWritten=", g_IsWritten);
  if(rates_total > 0 && !g_IsWritten)
  {
     string filename = "raw\\ATR_DownLoad.csv";
     int handle = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_ANSI);

     if(handle != INVALID_HANDLE)
     {
        FileWrite(handle, "Time", "Open", "Close", "High", "Low", "ATR");

        for(int k=0; k<rates_total; k++)
        {
           string timeStr = TimeToString(time[k], TIME_DATE|TIME_MINUTES);
           FileWrite(handle, timeStr, open[k], close[k], high[k], low[k], g_ATRCurr[k]);
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
