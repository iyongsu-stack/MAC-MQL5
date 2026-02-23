//+------------------------------------------------------------------+
//|                                                 ADXSmoothMTF.mq5 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
//| 멀티 타임프레임(MTF) 지원 ADX Smoothed 인디케이터                 |
//| - iCustom 자기참조 패턴으로 상위 TF 계산을 위임                   |
//| - CopyBuffer 시간기반(datetime) 매핑으로 정확한 바 대응           |
//| - 보간(Interpolation) 지원으로 부드러운 시각 표현                 |
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
input ENUM_TIMEFRAMES InpTimeframe    = PERIOD_CURRENT; // 타임프레임 (기본: 현재 차트)
input int             period          = 14;             // ADX 기간 (Original=14)
input double          alpha1          = 0.25;           // 1차 스무딩 계수
input double          alpha2          = 0.33;           // 2차 스무딩 계수
input int             PriceType       = 0;              // 가격 유형
input bool            InpInterpolate  = true;           // MTF 보간 사용?

//--- 인디케이터 버퍼 (3 DATA + 1 CALCULATIONS)
double DiPlusBuffer[];
double DiMinusBuffer[];
double ADXBuffer[];
double CountBuffer[];    // MTF 재계산 바 수 추적용

//--- 전역 변수
int             ADX_Handle;        // 동일 TF: iADX 핸들
int             _mtfHandle;        // MTF: iCustom 자기참조 핸들
int             min_rates_total;
ENUM_TIMEFRAMES _actualTF;         // 실제 사용될 타임프레임
string          _indicatorName;    // 자기 참조용 인디케이터 경로
bool            g_mtfCalculated;   // MTF 최초 계산 완료 여부
bool            g_IsWritten = false; // 파일 작성 여부 (중복 방지)

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- 타임프레임 결정: PERIOD_CURRENT 해석 + 하위 TF 자동 차단
   _actualTF = (InpTimeframe == PERIOD_CURRENT) ? Period() : InpTimeframe;
   _actualTF = (ENUM_TIMEFRAMES)MathMax((int)_actualTF, (int)Period());

   ADX_Handle  = INVALID_HANDLE;
   _mtfHandle  = INVALID_HANDLE;
   min_rates_total = period + 1;

   //--- 버퍼 설정
   SetIndexBuffer(0, DiPlusBuffer,  INDICATOR_DATA);
   SetIndexBuffer(1, DiMinusBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ADXBuffer,     INDICATOR_DATA);
   SetIndexBuffer(3, CountBuffer,   INDICATOR_CALCULATIONS);

   for(int k = 0; k < 3; k++)
     {
      PlotIndexSetInteger(k, PLOT_DRAW_BEGIN, min_rates_total);
      PlotIndexSetDouble(k, PLOT_EMPTY_VALUE, EMPTY_VALUE);
     }

   //--- MTF 모드 vs 동일 TF 모드 분기
   if(_actualTF != Period())
     {
      //--- MTF: iCustom으로 자기 자신을 상위 TF에서 호출
      _indicatorName = getIndicatorName();
      _mtfHandle = iCustom(_Symbol, _actualTF, _indicatorName,
                           PERIOD_CURRENT, period, alpha1, alpha2, PriceType, InpInterpolate);
      if(_mtfHandle == INVALID_HANDLE)
        {
         Print("❌ MTF iCustom 핸들 생성 실패! TF=", EnumToString(_actualTF),
               " 인디케이터=", _indicatorName, " err=", GetLastError());
         return(INIT_FAILED);
        }
      g_mtfCalculated = false;
      EventSetMillisecondTimer(500);  // 주말 대비 타이머 백업
      Print("✅ MTF 모드 ON. TF=", EnumToString(_actualTF),
            " ChartTF=", EnumToString(Period()), " 인디케이터=", _indicatorName);
     }
   else
     {
      //--- 동일 TF: iADX 핸들 생성
      ADX_Handle = iADX(_Symbol, _actualTF, period);
      if(ADX_Handle == INVALID_HANDLE)
        {
         Print("❌ ADX 핸들 생성 실패! TF=", EnumToString(_actualTF), " err=", GetLastError());
         return(INIT_FAILED);
        }
      Print("✅ 동일 TF 모드. TF=", EnumToString(_actualTF), " Period=", period);
     }

   //--- 인디케이터 이름 설정
   string shortname;
   StringConcatenate(shortname, "ADX(", period, ")smoothed[", EnumToString(_actualTF), "]");
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
   IndicatorSetInteger(INDICATOR_DIGITS, 0);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| 인디케이터 해제 함수 (핸들 누수 방지)                             |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(ADX_Handle != INVALID_HANDLE)
     { IndicatorRelease(ADX_Handle); ADX_Handle = INVALID_HANDLE; }
   if(_mtfHandle != INVALID_HANDLE)
     { IndicatorRelease(_mtfHandle); _mtfHandle = INVALID_HANDLE; }
  }

//+------------------------------------------------------------------+
//| 파일 쓰기 함수                                                    |
//+------------------------------------------------------------------+
void WriteToFile(const int rates_total, const datetime& time[], const double& open[], const double& high[], const double& low[], const double& close[])
  {
   string filename = "raw\\ADXSmoothMTF_DownLoad.csv";
   int handle = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_ANSI);

   if(handle != INVALID_HANDLE)
     {
      FileWrite(handle, "Time", "Open", "Close", "High", "Low", "DiPlus", "DiMinus", "ADX");

      for(int k=0; k<rates_total; k++)
        {
         string timeStr = TimeToString(time[k], TIME_DATE|TIME_MINUTES);
         FileWrite(handle, timeStr, open[k], close[k], high[k], low[k], DiPlusBuffer[k], DiMinusBuffer[k], ADXBuffer[k]);
        }
      FileClose(handle);
      Print("✅ Data download complete: ", filename);
      g_IsWritten = true;
     }
   else
     {
      Print("❌ Failed to open file for writing: ", filename, " Error: ", GetLastError());
     }
  }

//+------------------------------------------------------------------+
//| 타이머: 주말 등 틱 없는 환경에서 MTF 데이터 준비 대기 및 계산     |
//+------------------------------------------------------------------+
void OnTimer()
  {
   //--- 이미 계산 완료 또는 핸들 무효 → 타이머 종료
   if(g_mtfCalculated || _mtfHandle == INVALID_HANDLE)
     { EventKillTimer(); return; }

   //--- iCustom(상위 TF) 데이터 준비 확인
   int bc = BarsCalculated(_mtfHandle);
   if(bc <= 0) return;  // 아직 준비 안 됨, 다음 타이머에서 재시도

   //--- 데이터 준비 완료 → 차트 리로드로 OnCalculate 재호출 유도
   //--- (버퍼에 직접 쓰기는 터미널이 인식하지 못함 → ChartSetSymbolPeriod 필요)
   g_mtfCalculated = true;
   EventKillTimer();
   Print("✅ MTF 데이터 준비 완료! 차트 리로드로 OnCalculate 재호출. BC=", bc);
   ChartSetSymbolPeriod(0, _Symbol, Period());
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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

   //--- MTF 모드
   if(_actualTF != Period())
     {
      calculated = CalcMultiTimeframe(rates_total, prev_calculated, time);
      //--- 최초 계산 성공 시 타이머 백업 종료
      if(!g_mtfCalculated && calculated > 0)
        { g_mtfCalculated = true; EventKillTimer(); }
     }
   else
     {
      //--- 동일 TF 모드
      if(BarsCalculated(ADX_Handle) <= 0)
         return(prev_calculated);
      calculated = CalcSameTimeframe(rates_total, prev_calculated);
     }

   //--- 파일 저장 (계산이 완료되었고 아직 저장 안 했으면)
   if(calculated > 0 && !g_IsWritten && calculated >= rates_total)
      WriteToFile(rates_total, time, open, high, low, close);

   return(calculated);
  }

//+------------------------------------------------------------------+
//| 동일 타임프레임: 원본 2단계 스무딩 로직                           |
//+------------------------------------------------------------------+
int CalcSameTimeframe(const int rates_total, const int prev_calculated)
  {
   int start;
   double ADX[], DIP[], DIM[];

   //--- 상태 변수 (1차 스무딩 상태 유지)
   static double Last_DiPlus_, Last_DiMinus_, Last_Adx_;

   //--- 임시 변수
   double DiPlus, DiMinus, Adx;

   //--- 초기화 로직
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

   //--- ADX 데이터 복사
   if(CopyBuffer(ADX_Handle, 0, 0, rates_total, ADX) <= 0) return(0);
   if(CopyBuffer(ADX_Handle, 1, 0, rates_total, DIP) <= 0) return(0);
   if(CopyBuffer(ADX_Handle, 2, 0, rates_total, DIM) <= 0) return(0);

   ArraySetAsSeries(ADX, false);
   ArraySetAsSeries(DIP, false);
   ArraySetAsSeries(DIM, false);

   //--- 상태 복원
   DiPlus = Last_DiPlus_;
   DiMinus = Last_DiMinus_;
   Adx = Last_Adx_;

   //--- 메인 계산 루프
   for(int i = start; i < rates_total; i++)
     {
      //--- 1차 스무딩
      DiPlus  = 2 * DIP[i] + (alpha1 - 2) * DIP[i-1] + (1 - alpha1) * DiPlus;
      DiMinus = 2 * DIM[i] + (alpha1 - 2) * DIM[i-1] + (1 - alpha1) * DiMinus;
      Adx     = 2 * ADX[i] + (alpha1 - 2) * ADX[i-1] + (1 - alpha1) * Adx;

      //--- 2차 스무딩 (출력 버퍼)
      DiPlusBuffer[i]  = alpha2 * DiPlus  + (1 - alpha2) * DiPlusBuffer[i-1];
      DiMinusBuffer[i] = alpha2 * DiMinus + (1 - alpha2) * DiMinusBuffer[i-1];
      ADXBuffer[i]     = alpha2 * Adx     + (1 - alpha2) * ADXBuffer[i-1];

      //--- 완결된 바의 상태 저장
      if(i < rates_total - 1)
        {
         Last_DiPlus_  = DiPlus;
         Last_DiMinus_ = DiMinus;
         Last_Adx_     = Adx;
        }
     }

   //--- MTF 자기참조 시 재계산 바 수 기록
   CountBuffer[rates_total - 1] = MathMax(rates_total - prev_calculated + 1, 1);
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| 멀티 타임프레임: iCustom 자기참조 + CopyBuffer 시간기반 매핑      |
//| - 상위 TF 인스턴스가 스무딩 계산을 완료                           |
//| - 이 함수는 결과를 현재 차트 바에 매핑만 수행                     |
//+------------------------------------------------------------------+
int CalcMultiTimeframe(const int rates_total, const int prev_calculated,
                       const datetime &time[])
  {
   //--- iCustom 핸들 데이터 준비 여부 확인
   if(BarsCalculated(_mtfHandle) < 0)
      return(prev_calculated);   // ← 핵심: prev_calculated 반환으로 이전 상태 유지

   //--- 상위 TF 히스토리 데이터 존재 확인
   if(!timeFrameCheck(_actualTF, time))
      return(prev_calculated);

   //--- 재계산 바 수 가져오기 (상위 TF 인스턴스의 CountBuffer)
   double result[];
   if(CopyBuffer(_mtfHandle, 3, 0, 1, result) == -1)
      return(prev_calculated);

   //--- 계산 시작점 결정 (최적화)
   #define _mtfRatio (double)PeriodSeconds(_actualTF) / PeriodSeconds(_Period)
   int i = MathMin(MathMax(prev_calculated - 1, 0),
                   MathMax(rates_total - (int)(result[0] * _mtfRatio) - 1, 0));
   int _prevMark = 0;
   int _seconds  = PeriodSeconds(_actualTF);

   //--- 현재 차트의 각 바에 대해 상위 TF 데이터 매핑
   for(; i < rates_total && !_StopFlag; i++)
     {
      int _currMark = (int)(time[i] / _seconds);

      if(_currMark != _prevMark)
        {
         //--- 상위 TF 바가 변경됨 → CopyBuffer로 새 값 가져오기 (시간 기반)
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
         //--- 동일 상위 TF 바 내 → 이전 값 복사 (최적화)
         DiPlusBuffer[i]  = DiPlusBuffer[i-1];
         DiMinusBuffer[i] = DiMinusBuffer[i-1];
         ADXBuffer[i]     = ADXBuffer[i-1];
        }

      //--- 보간: MTF 바 경계에서 값을 선형 보간하여 부드럽게 표시
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

//+------------------------------------------------------------------+
//| 유틸리티: 인디케이터 자기 참조 경로 생성                          |
//| - MQL5 프로그램 경로에서 Indicators/ 이하 상대경로 추출           |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| 유틸리티: 상위 TF 히스토리 데이터 존재 확인                       |
//| - 서버에서 데이터가 아직 로딩 안 된 경우 Comment로 사용자 안내    |
//+------------------------------------------------------------------+
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
                 EnumToString(_timeFrame) + " 타임프레임 데이터 누락\n다음 틱에서 재시도...");
         warned = true;
         return(false);
        }
     }
   if(warned) { Comment(""); warned = false; }
   return(true);
  }
//+------------------------------------------------------------------+
