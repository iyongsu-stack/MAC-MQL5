//+------------------------------------------------------------------+
//|                                                 ADXSmoothMTF.mq5 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//| AIEngine clean version — file writing logic removed              |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2007, MetaQuotes Software Corp."
#property link      "https://www.mql5.com/en/code/546"
#property version   "3.00"
#property indicator_separate_window
#property indicator_buffers 4
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
#property indicator_label3  "ADXMTF"

#property indicator_level1 88.0
#property indicator_level2 50.0
#property indicator_level3 12.0
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT

//--- 입력 파라미터
input ENUM_TIMEFRAMES InpTimeframe    = PERIOD_CURRENT;
input int             period          = 14;
input double          alpha1          = 0.25;
input double          alpha2          = 0.33;
input int             PriceType       = 0;
input bool            InpInterpolate  = true;

double DiPlusBuffer[];
double DiMinusBuffer[];
double ADXBuffer[];
double CountBuffer[];

int             ADX_Handle;
int             _mtfHandle;
int             min_rates_total;
ENUM_TIMEFRAMES _actualTF;
string          _indicatorName;
bool            g_mtfCalculated;

//+------------------------------------------------------------------+
int OnInit()
  {
   _actualTF = (InpTimeframe == PERIOD_CURRENT) ? Period() : InpTimeframe;
   _actualTF = (ENUM_TIMEFRAMES)MathMax((int)_actualTF, (int)Period());

   ADX_Handle  = INVALID_HANDLE;
   _mtfHandle  = INVALID_HANDLE;
   min_rates_total = period + 1;

   SetIndexBuffer(0, DiPlusBuffer,  INDICATOR_DATA);
   SetIndexBuffer(1, DiMinusBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ADXBuffer,     INDICATOR_DATA);
   SetIndexBuffer(3, CountBuffer,   INDICATOR_CALCULATIONS);

   for(int k = 0; k < 3; k++)
     {
      PlotIndexSetInteger(k, PLOT_DRAW_BEGIN, min_rates_total);
      PlotIndexSetDouble(k, PLOT_EMPTY_VALUE, EMPTY_VALUE);
     }

   if(_actualTF != Period())
     {
      _indicatorName = getIndicatorName();
      _mtfHandle = iCustom(_Symbol, _actualTF, _indicatorName,
                           PERIOD_CURRENT, period, alpha1, alpha2, PriceType, InpInterpolate);
      if(_mtfHandle == INVALID_HANDLE)
        {
         Print("MTF iCustom handle creation failed! TF=", EnumToString(_actualTF),
               " indicator=", _indicatorName, " err=", GetLastError());
         return(INIT_FAILED);
        }
      g_mtfCalculated = false;
      EventSetMillisecondTimer(500);
     }
   else
     {
      ADX_Handle = iADX(_Symbol, _actualTF, period);
      if(ADX_Handle == INVALID_HANDLE)
        {
         Print("ADX handle creation failed! TF=", EnumToString(_actualTF), " err=", GetLastError());
         return(INIT_FAILED);
        }
     }

   string shortname;
   StringConcatenate(shortname, "ADX(", period, ")smoothed[", EnumToString(_actualTF), "]");
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
   IndicatorSetInteger(INDICATOR_DIGITS, 0);

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(ADX_Handle != INVALID_HANDLE)
     { IndicatorRelease(ADX_Handle); ADX_Handle = INVALID_HANDLE; }
   if(_mtfHandle != INVALID_HANDLE)
     { IndicatorRelease(_mtfHandle); _mtfHandle = INVALID_HANDLE; }
  }

void OnTimer()
  {
   if(g_mtfCalculated || _mtfHandle == INVALID_HANDLE)
     { EventKillTimer(); return; }
   int bc = BarsCalculated(_mtfHandle);
   if(bc <= 0) return;
   g_mtfCalculated = true;
   EventKillTimer();
   ChartSetSymbolPeriod(0, _Symbol, Period());
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double& high[],
                const double& low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(Bars(_Symbol, _Period) < rates_total)
      return(prev_calculated);

   int calculated = 0;

   if(_actualTF != Period())
     {
      calculated = CalcMultiTimeframe(rates_total, prev_calculated, time);
      if(!g_mtfCalculated && calculated > 0)
        { g_mtfCalculated = true; EventKillTimer(); }
     }
   else
     {
      if(BarsCalculated(ADX_Handle) <= 0)
         return(prev_calculated);
      calculated = CalcSameTimeframe(rates_total, prev_calculated);
     }

   return(calculated);
  }

int CalcSameTimeframe(const int rates_total, const int prev_calculated)
  {
   int start;
   double ADX[], DIP[], DIM[];
   static double Last_DiPlus_, Last_DiMinus_, Last_Adx_;
   double DiPlus, DiMinus, Adx;

   if(prev_calculated < min_rates_total)
     {
      start = 1;
      ArrayInitialize(DiPlusBuffer, 0.0);
      ArrayInitialize(DiMinusBuffer, 0.0);
      ArrayInitialize(ADXBuffer, 0.0);
      Last_DiPlus_ = 0.0;
      Last_DiMinus_ = 0.0;
      Last_Adx_ = 0.0;
     }
   else
     {
      start = prev_calculated - 1;
     }

   if(CopyBuffer(ADX_Handle, 0, 0, rates_total, ADX) <= 0) return(0);
   if(CopyBuffer(ADX_Handle, 1, 0, rates_total, DIP) <= 0) return(0);
   if(CopyBuffer(ADX_Handle, 2, 0, rates_total, DIM) <= 0) return(0);

   ArraySetAsSeries(ADX, false);
   ArraySetAsSeries(DIP, false);
   ArraySetAsSeries(DIM, false);

   DiPlus = Last_DiPlus_;
   DiMinus = Last_DiMinus_;
   Adx = Last_Adx_;

   for(int i = start; i < rates_total; i++)
     {
      DiPlus  = 2 * DIP[i] + (alpha1 - 2) * DIP[i-1] + (1 - alpha1) * DiPlus;
      DiMinus = 2 * DIM[i] + (alpha1 - 2) * DIM[i-1] + (1 - alpha1) * DiMinus;
      Adx     = 2 * ADX[i] + (alpha1 - 2) * ADX[i-1] + (1 - alpha1) * Adx;

      DiPlusBuffer[i]  = alpha2 * DiPlus  + (1 - alpha2) * DiPlusBuffer[i-1];
      DiMinusBuffer[i] = alpha2 * DiMinus + (1 - alpha2) * DiMinusBuffer[i-1];
      ADXBuffer[i]     = alpha2 * Adx     + (1 - alpha2) * ADXBuffer[i-1];

      if(i < rates_total - 1)
        {
         Last_DiPlus_  = DiPlus;
         Last_DiMinus_ = DiMinus;
         Last_Adx_     = Adx;
        }
     }

   CountBuffer[rates_total - 1] = MathMax(rates_total - prev_calculated + 1, 1);
   return(rates_total);
  }

int CalcMultiTimeframe(const int rates_total, const int prev_calculated,
                       const datetime &time[])
  {
   if(BarsCalculated(_mtfHandle) < 0)
      return(prev_calculated);
   if(!timeFrameCheck(_actualTF, time))
      return(prev_calculated);

   double result[];
   if(CopyBuffer(_mtfHandle, 3, 0, 1, result) == -1)
      return(prev_calculated);

   #define _mtfRatio (double)PeriodSeconds(_actualTF) / PeriodSeconds(_Period)
   int i = MathMin(MathMax(prev_calculated - 1, 0),
                   MathMax(rates_total - (int)(result[0] * _mtfRatio) - 1, 0));
   int _prevMark = 0;
   int _seconds  = PeriodSeconds(_actualTF);

   for(; i < rates_total && !_StopFlag; i++)
     {
      int _currMark = (int)(time[i] / _seconds);

      if(_currMark != _prevMark)
        {
         _prevMark = _currMark;

         #define _mtfCopy(_buff, _buffNo) \
            if(CopyBuffer(_mtfHandle, _buffNo, time[i], 1, result) <= 0) break; \
            _buff[i] = result[0]

         _mtfCopy(DiPlusBuffer,  0);
         _mtfCopy(DiMinusBuffer, 1);
         _mtfCopy(ADXBuffer,     2);
        }
      else
        {
         DiPlusBuffer[i]  = DiPlusBuffer[i-1];
         DiMinusBuffer[i] = DiMinusBuffer[i-1];
         ADXBuffer[i]     = ADXBuffer[i-1];
        }

      if(!InpInterpolate) continue;
      int _nextMark = (i < rates_total - 1) ? (int)(time[i+1] / _seconds) : _prevMark + 1;
      if(_nextMark == _prevMark) continue;

      int n, k;
      for(n = 1; (i - n) > 0 && time[i-n] >= _prevMark * _seconds; n++) continue;
      for(k = 1; (i - k) >= 0 && k < n; k++)
        {
         #define _mtfInterpolate(_buff) \
            _buff[i-k] = _buff[i] + (_buff[i-n] - _buff[i]) * k / n

         _mtfInterpolate(DiPlusBuffer);
         _mtfInterpolate(DiMinusBuffer);
         _mtfInterpolate(ADXBuffer);
        }
     }

   return(i);
  }

string getIndicatorName()
  {
   string _path = MQL5InfoString(MQL5_PROGRAM_PATH);
   StringToLower(_path);
   string _partsA[];
   ushort _partsS = StringGetCharacter("\\", 0);
   int    _partsN = StringSplit(_path, _partsS, _partsA);
   string name = _partsA[_partsN - 1];
   for(int n = _partsN - 2; n >= 0 && _partsA[n] != "indicators"; n--)
      name = _partsA[n] + "\\" + name;
   return(name);
  }

bool timeFrameCheck(ENUM_TIMEFRAMES _timeFrame, const datetime &time[])
  {
   static bool warned = false;
   if(time[0] < SeriesInfoInteger(_Symbol, _timeFrame, SERIES_FIRSTDATE))
     {
      datetime startTime, testTime[];
      if(SeriesInfoInteger(_Symbol, PERIOD_M1, SERIES_TERMINAL_FIRSTDATE, startTime))
         if(startTime > 0)
           {
            CopyTime(_Symbol, _timeFrame, time[0], 1, testTime);
            SeriesInfoInteger(_Symbol, _timeFrame, SERIES_FIRSTDATE, startTime);
           }
      if(startTime <= 0 || startTime > time[0])
        {
         Comment(MQL5InfoString(MQL5_PROGRAM_NAME) + "\n" +
                 EnumToString(_timeFrame) + " timeframe data missing\nRetrying on next tick...");
         warned = true;
         return(false);
        }
     }
   if(warned) { Comment(""); warned = false; }
   return(true);
  }
//+------------------------------------------------------------------+
