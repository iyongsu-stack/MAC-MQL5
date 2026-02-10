//+------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property link        "https://www.mql5.com"
#property description "Chandelier exit"
//+------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   8
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDeepSkyBlue
#property indicator_style1  STYLE_DOT
#property indicator_type2   DRAW_LINE
#property indicator_style2  STYLE_DOT
#property indicator_color2  clrPaleVioletRed
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDeepSkyBlue
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrPaleVioletRed
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrDeepSkyBlue
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrPaleVioletRed
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrDeepSkyBlue
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrPaleVioletRed

//--- input parameters

input int     AtrPeriod      =  22; // Atr period
input double  AtrMultiplier1 = 3.0; // Atr 1st multiplier
input double  AtrMultiplier2 = 4.5; // Atr 2nd multiplier
input int     LookBackPeriod =  22; // Look-back period

double UplBuffer1[],UpdBuffer1[],DnlBuffer1[],DndBuffer1[],UplBuffer2[],UpdBuffer2[],DnlBuffer2[],DndBuffer2[];
bool g_IsWritten = false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,UplBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,DnlBuffer1,INDICATOR_DATA);
   SetIndexBuffer(2,UplBuffer2,INDICATOR_DATA);
   SetIndexBuffer(3,DnlBuffer2,INDICATOR_DATA);
   SetIndexBuffer(4,UpdBuffer1,INDICATOR_DATA); PlotIndexSetInteger(4,PLOT_ARROW,159);
   SetIndexBuffer(5,DndBuffer1,INDICATOR_DATA); PlotIndexSetInteger(5,PLOT_ARROW,159);
   SetIndexBuffer(6,UpdBuffer2,INDICATOR_DATA); PlotIndexSetInteger(6,PLOT_ARROW,159);
   SetIndexBuffer(7,DndBuffer2,INDICATOR_DATA); PlotIndexSetInteger(7,PLOT_ARROW,159);
   return (INIT_SUCCEEDED);
  }
//
//
//
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Work array                                                       |
//+------------------------------------------------------------------+
double  work[][6];
#define _hi1    0
#define _lo1    1
#define _hi2    2
#define _lo2    3
#define _trend1 4
#define _trend2 5
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(Bars(_Symbol,_Period)<rates_total) return(prev_calculated);
   if(ArrayRange(work,0)!=rates_total) ArrayResize(work,rates_total);

   int i=(int)MathMax(prev_calculated-1,1); for(; i<rates_total && !_StopFlag; i++)
     {
      UplBuffer1[i] = UpdBuffer1[i] = DnlBuffer1[i] = DndBuffer1[i] = EMPTY_VALUE;
      UplBuffer2[i] = UpdBuffer2[i] = DnlBuffer2[i] = DndBuffer2[i] = EMPTY_VALUE;

      //
      //-------------------
      //

      int  _start = MathMax(i-LookBackPeriod,0);
      double _atr = 0; for(int k=1; k<=AtrPeriod && (i-k-1)>=0; k++) _atr += MathMax(high[i-k],close[MathMax(i-k-1,0)])- MathMin(low[i-k],close[MathMax(i-k-1,0)]); _atr/=(double)AtrPeriod;
      double _max = high[ArrayMaximum(high,_start,LookBackPeriod)];
      double _min = low [ArrayMinimum(low ,_start,LookBackPeriod)];

      work[i][_hi1]    = _max-AtrMultiplier1*_atr;
      work[i][_lo1]    = _min+AtrMultiplier1*_atr;
      work[i][_hi2]    = _max-AtrMultiplier2*_atr;
      work[i][_lo2]    = _min+AtrMultiplier2*_atr;
      work[i][_trend1] = (i>0) ? work[i-1][_trend1] : 0;
      work[i][_trend2] = (i>0) ? work[i-1][_trend2] : 0;
      if(i>0)
        {
         if(close[i] > work[i-1][_lo1]) work[i][_trend1]=  1;
         if(close[i] < work[i-1][_hi1]) work[i][_trend1]= -1;
         if(close[i] > work[i-1][_lo2]) work[i][_trend2]=  1;
         if(close[i] < work[i-1][_hi2]) work[i][_trend2]= -1;

         if(AtrMultiplier1>0 && work[i][_trend1] ==  1) { if(work[i][_hi1]<work[i-1][_hi1]) work[i][_hi1]=work[i-1][_hi1]; UplBuffer1[i] = work[i][_hi1]; if(UplBuffer1[i-1]==EMPTY_VALUE) UpdBuffer1[i]=UplBuffer1[i];}
         if(AtrMultiplier1>0 && work[i][_trend1] == -1) { if(work[i][_lo1]>work[i-1][_lo1]) work[i][_lo1]=work[i-1][_lo1]; DnlBuffer1[i] = work[i][_lo1]; if(DnlBuffer1[i-1]==EMPTY_VALUE) DndBuffer1[i]=DnlBuffer1[i];}
         if(AtrMultiplier2>0 && work[i][_trend2] ==  1) { if(work[i][_hi2]<work[i-1][_hi2]) work[i][_hi2]=work[i-1][_hi2]; UplBuffer2[i] = work[i][_hi2]; if(UplBuffer2[i-1]==EMPTY_VALUE) UpdBuffer2[i]=UplBuffer2[i];}
         if(AtrMultiplier2>0 && work[i][_trend2] == -1) { if(work[i][_lo2]>work[i-1][_lo2]) work[i][_lo2]=work[i-1][_lo2]; DnlBuffer2[i] = work[i][_lo2]; if(DnlBuffer2[i-1]==EMPTY_VALUE) DndBuffer2[i]=DnlBuffer2[i];}
        }
     }
   // --- File Writing Logic ---
   if(rates_total > 0 && !g_IsWritten) 
   {
      string filename = "ChandelieExit_DownLoad.csv";
      int handle = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_ANSI);
      
      if(handle != INVALID_HANDLE) 
      {
         FileWrite(handle, "Time", "Open", "Close", "High", "Low", "UplBuffer1", "DnlBuffer1", "UplBuffer2", "DnlBuffer2");
         
         for(int k=0; k<rates_total; k++) 
         {
            string timeStr = TimeToString(time[k], TIME_DATE|TIME_MINUTES);
            
            // Sanitize EMPTY_VALUE (DBL_MAX) to "NaN" for ML/Data Science compatibility
            string val1 = (UplBuffer1[k] == EMPTY_VALUE) ? "NaN" : DoubleToString(UplBuffer1[k], _Digits);
            string val2 = (DnlBuffer1[k] == EMPTY_VALUE) ? "NaN" : DoubleToString(DnlBuffer1[k], _Digits);
            string val3 = (UplBuffer2[k] == EMPTY_VALUE) ? "NaN" : DoubleToString(UplBuffer2[k], _Digits);
            string val4 = (DnlBuffer2[k] == EMPTY_VALUE) ? "NaN" : DoubleToString(DnlBuffer2[k], _Digits);

            FileWrite(handle, timeStr, open[k], close[k], high[k], low[k], val1, val2, val3, val4);
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

   return (i);
  }
//+------------------------------------------------------------------+

  