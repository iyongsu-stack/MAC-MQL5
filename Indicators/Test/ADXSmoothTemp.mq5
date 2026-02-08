//+------------------------------------------------------------------+
//|                                                 ADX Smoothed.mq5 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
#property version   "1.00"
#property indicator_separate_window

#property indicator_buffers 13
#property indicator_plots   6

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label1  "Di Plus"

#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_label2  "Di Minus"

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrYellow
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_label3  "ADX"

#property indicator_type4   DRAW_LINE
#property indicator_color4  clrGold
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
#property indicator_label4  "ADX Avg"

#property indicator_type5   DRAW_LINE
#property indicator_color5  clrDarkOrange
#property indicator_style5  STYLE_DOT
#property indicator_width5  1
#property indicator_label5  "ADX Upper"

#property indicator_type6   DRAW_LINE
#property indicator_color6  clrDarkOrange
#property indicator_style6  STYLE_DOT
#property indicator_width6  1
#property indicator_label6  "ADX Lower"

#property indicator_level1 88.0
#property indicator_level2 50.0
#property indicator_level3 12.0
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DASHDOTDOT

input int    period = 100;         // ADX period
input double alpha1 = 0.25;        // alpha1
input double alpha2 = 0.33;        // alpha2
input int    AvgPeriod = 3000;     // ADX Average Period

input group "Time Filter"
input int StdCalcStartTimeHour = 1;      // Start Calculation (Hour)
input int StdCalcStartTimeMinute = 30;   // Start Calculation (Minute)
input int StdCalcEndTimeHour = 23;       // End Calculation (Hour)
input int StdCalcEndTimeMinute = 30;     // End Calculation (Minute)

double DiPlusBuffer[];
double DiMinusBuffer[];
double ADXBuffer[];
double ADX_AvgBuffer[];
double ADX_StdPBuffer[];
double ADX_StdMBuffer[];

// ADX 계산을 위한 내부 버퍼
double ExtTRBuffer[];
double ExtPDMBuffer[];
double ExtMDMBuffer[];
double ExtDXBuffer[];
double ExtADXBuffer[]; // 기존 ADXBuffer 대신 계산된 ADX 저장
double ExtPDIBuffer[]; // 기존 DIP, DiPlus 대체
double ExtMDIBuffer[]; // 기존 DIM, DiMinus 대체

int min_rates_total;

//+------------------------------------------------------------------+
//| 이동 평균 및 표준편차 계산 클래스                                  |
//| HiStdDev3 개념 기반                                               |
//+------------------------------------------------------------------+
class C_ADX_AvgStd
  {
private:
   double            m_buffer[];       // 데이터 원형 버퍼
   int               m_size;           // 윈도우 크기 (기간)
   int               m_index;          // 현재 쓰기 위치 
   int               m_count;          // 현재 데이터 개수
   double            m_sum;            // 합계
   double            m_sum_sq;         // 제곱합

public:
   // 생성자
   C_ADX_AvgStd(int p_period)
     {
      m_size = p_period;
      if(m_size <= 0) m_size = 20; // 기본 안전장치
      ArrayResize(m_buffer, m_size);
      ArrayInitialize(m_buffer, 0.0);
      Reset();
     }

   // 소멸자
   ~C_ADX_AvgStd() {}

   // 상태 초기화
   void Reset()
     {
      m_index = 0;
      m_count = 0;
      m_sum = 0.0;
      m_sum_sq = 0.0;
      ArrayInitialize(m_buffer, 0.0);
     }

   // 평균, 상단(StdP), 하단(StdM) 계산
   // 입력: value (현재 ADX 값)
   // 출력: avg, std_p (평균+표준편차), std_m (평균-표준편차) 참조로 전달
   void Calculate(double value, double &avg, double &std_p, double &std_m)
     {
      // 1. 버퍼가 꽉 찼으면 가장 오래된 값 제거
      if(m_count >= m_size)
        {
         double old_val = m_buffer[m_index];
         m_sum -= old_val;
         m_sum_sq -= (old_val * old_val);
        }
      else
        {
         m_count++;
        }

      // 2. 새 값 추가
      m_buffer[m_index] = value;
      m_sum += value;
      m_sum_sq += (value * value);

      // 3. 인덱스 이동
      m_index++;
      if(m_index >= m_size) m_index = 0;

      // 4. 계산
      if(m_count > 0)
        {
         avg = m_sum / m_count;
         
         double variance = (m_sum_sq / m_count) - (avg * avg);
         double std_dev = (variance > 0) ? MathSqrt(variance) : 0.0;
         
         std_p = avg + std_dev;
         std_m = avg - std_dev;
        }
      else
        {
         avg = value;
         std_p = value;
         std_m = value;
        }
     }
  };

C_ADX_AvgStd *ExtAdxCalc; // Global pointer

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
   min_rates_total=period+AvgPeriod+1;

   SetIndexBuffer(0,DiPlusBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   ArraySetAsSeries(DiPlusBuffer,true);

   SetIndexBuffer(1,DiMinusBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   ArraySetAsSeries(DiMinusBuffer,true);

   SetIndexBuffer(2,ADXBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   ArraySetAsSeries(ADXBuffer,true);

   SetIndexBuffer(3,ADX_AvgBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   ArraySetAsSeries(ADX_AvgBuffer,true);

   SetIndexBuffer(4,ADX_StdPBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   ArraySetAsSeries(ADX_StdPBuffer,true);

   SetIndexBuffer(5,ADX_StdMBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   ArraySetAsSeries(ADX_StdMBuffer,true);

   // 내부 계산용 버퍼 연결
   SetIndexBuffer(6,ExtTRBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,ExtPDMBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,ExtMDMBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,ExtDXBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,ExtADXBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,ExtPDIBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,ExtMDIBuffer,INDICATOR_CALCULATIONS);
   
   // Series 설정 (역순 인덱싱)
   ArraySetAsSeries(ExtTRBuffer,true);
   ArraySetAsSeries(ExtPDMBuffer,true);
   ArraySetAsSeries(ExtMDMBuffer,true);
   ArraySetAsSeries(ExtDXBuffer,true);
   ArraySetAsSeries(ExtADXBuffer,true);
   ArraySetAsSeries(ExtPDIBuffer,true);
   ArraySetAsSeries(ExtMDIBuffer,true);

   string shortname;
   StringConcatenate(shortname,"ADX(",period,",",AvgPeriod,")smothed");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   IndicatorSetInteger(INDICATOR_DIGITS,0);
   
   // Initialize algorithm
   ExtAdxCalc = new C_ADX_AvgStd(AvgPeriod);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(CheckPointer(ExtAdxCalc)==POINTER_DYNAMIC) delete ExtAdxCalc;
  }

//+------------------------------------------------------------------+
//| Custom helper function to check calculation time                 |
//+------------------------------------------------------------------+
bool IsStdCalculationTime(datetime time) {
  MqlDateTime dt;
  TimeToStruct(time, dt);

  int currentMinutes = dt.hour * 60 + dt.min;
  int startMinutes = StdCalcStartTimeHour * 60 + StdCalcStartTimeMinute;
  int endMinutes = StdCalcEndTimeHour * 60 + StdCalcEndTimeMinute;

  // Case 1: Start < End (e.g., 01:30 to 23:30)
  if (startMinutes < endMinutes) {
    return (currentMinutes >= startMinutes && currentMinutes < endMinutes);
  }
  // Case 2: Start > End (e.g., 22:00 to 06:00)
  else {
    return (currentMinutes >= startMinutes || currentMinutes < endMinutes);
  }
}

//+------------------------------------------------------------------+
//| ADX 계산 함수 (Wilder's Smoothing)                                |
//+------------------------------------------------------------------+
void CalculateADX(const int rates_total,
                  const int prev_calculated,
                  const double &high[],
                  const double &low[],
                  const double &close[])
  {
   int i, start;
   
   // 초기값 설정 및 시작 인덱스 계산
   if(prev_calculated < 2)
     {
      start = rates_total - 2;
      
      // 버퍼 초기화
      ExtTRBuffer[rates_total-1] = 0;
      ExtPDMBuffer[rates_total-1] = 0;
      ExtMDMBuffer[rates_total-1] = 0;
      ExtDXBuffer[rates_total-1] = 0;
      ExtADXBuffer[rates_total-1] = 0;
      ExtPDIBuffer[rates_total-1] = 0;
      ExtMDIBuffer[rates_total-1] = 0;
     }
   else
     {
      start = rates_total - prev_calculated;
     }

   // 1. TR, +DM, -DM 계산 및 스무딩
   for(i = start; i >= 0; i--)
     {
      if(i == rates_total-1) continue;
      
      double h = high[i];
      double l = low[i];
      double c = close[i];
      double h1 = high[i+1];
      double l1 = low[i+1];
      double c1 = close[i+1];

      // True Range 계산
      double tr = MathMax(MathMax(h - l, MathAbs(h - c1)), MathAbs(l - c1));
      
      // Directional Movement 계산
      double pdm = (h - h1) > (l1 - l) ? (h - h1) : 0;
      double mdm = (l1 - l) > (h - h1) ? (l1 - l) : 0;
      
      if(pdm < 0) pdm = 0;
      if(mdm < 0) mdm = 0;
      
      // Wilder's Smoothing 적용
      // 첫 계산인 경우 (단순 합계가 필요하지만 여기선 EMA 방식 근사 사용 또는 초기화 필요)
      // 정확한 Wilder's 방식은 초기값 = 단순평균, 이후 = (Prev*(N-1) + Curr)/N
      // 단순화를 위해 EMA 방식과 유사한 Wilder's 공식 적용: Prev + (Curr - Prev)/N -> 아님.
      // 공식: (Prev_Smoothed * (period-1) + Curr) / period
      
      if(i == rates_total - 2) // 데이터 시작점
        {
         ExtTRBuffer[i] = tr;
         ExtPDMBuffer[i] = pdm;
         ExtMDMBuffer[i] = mdm;
        }
      else
        {
         ExtTRBuffer[i] = (ExtTRBuffer[i+1] * (period - 1) + tr) / period;
         ExtPDMBuffer[i] = (ExtPDMBuffer[i+1] * (period - 1) + pdm) / period;
         ExtMDMBuffer[i] = (ExtMDMBuffer[i+1] * (period - 1) + mdm) / period;
        }
        
      // 2. DI+, DI- 계산
      double tr_val = ExtTRBuffer[i];
      if(tr_val == 0) tr_val = 1.0; // 0 나누기 방지
      
      ExtPDIBuffer[i] = 100.0 * ExtPDMBuffer[i] / tr_val;
      ExtMDIBuffer[i] = 100.0 * ExtMDMBuffer[i] / tr_val;
      
      // 3. DX 계산
      double di_sum = ExtPDIBuffer[i] + ExtMDIBuffer[i];
      double di_diff = MathAbs(ExtPDIBuffer[i] - ExtMDIBuffer[i]);
      
      if(di_sum == 0) ExtDXBuffer[i] = 0;
      else ExtDXBuffer[i] = 100.0 * di_diff / di_sum;
      
      // 4. ADX 계산 (DX의 Smoothed)
      if(i == rates_total - 2)
        {
         ExtADXBuffer[i] = ExtDXBuffer[i];
        }
      else
        {
         ExtADXBuffer[i] = (ExtADXBuffer[i+1] * (period - 1) + ExtDXBuffer[i]) / period;
        }
     }
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
   if(rates_total<min_rates_total) return(0);

   // Series 배열 설정 (입력 데이터)
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   // 1. 커스텀 ADX 계산 호출
   CalculateADX(rates_total, prev_calculated, high, low, close);

   int limit,bar;
   double DiPlus,DiMinus,Adx;
   static double DiPlus_,DiMinus_,Adx_;

   if(prev_calculated>rates_total || prev_calculated<=0)
     {
      limit=rates_total-2;
      DiPlus_=0.0;
      DiMinus_=0.0;
      Adx_=0.0;
      DiPlusBuffer[rates_total-1]=0.0;
      DiMinusBuffer[rates_total-1]=0.0;
      ADXBuffer[rates_total-1]=0.0;
      
      ADXBuffer[rates_total-1]=0.0;
      
      // Reset calculations on full recalc
      if(CheckPointer(ExtAdxCalc)==POINTER_DYNAMIC) ExtAdxCalc.Reset();
      ADX_AvgBuffer[rates_total-1]=0.0;
      ADX_StdPBuffer[rates_total-1]=0.0;
      ADX_StdMBuffer[rates_total-1]=0.0;
     }

   else limit=rates_total-prev_calculated;

   DiPlus=DiPlus_;
   DiMinus=DiMinus_;
   Adx=Adx_;

   for(bar=limit; bar>=0; bar--)
     {
      if(rates_total!=prev_calculated && bar==0)
        {
         DiPlus_=DiPlus;
         DiMinus_=DiMinus;
         Adx_=Adx;
        }

      // Time Filter Check
      bool isCalcTime = IsStdCalculationTime(time[bar]);

      if(isCalcTime)
        {
         // 기존 복사된 값이 아닌 계산된 buffer 값 사용
         double currentPDI = ExtPDIBuffer[bar];
         double currentMDI = ExtMDIBuffer[bar];
         double currentADX = ExtADXBuffer[bar];
         double nextPDI = ExtPDIBuffer[bar+1];
         double nextMDI = ExtMDIBuffer[bar+1];
         double nextADX = ExtADXBuffer[bar+1];

         DiPlus=2*currentPDI+(alpha1-2)*nextPDI+(1-alpha1)*DiPlus;
         DiMinus=2*currentMDI+(alpha1-2)*nextMDI+(1-alpha1)*DiMinus;
         Adx=2*currentADX+(alpha1-2)*nextADX+(1-alpha1)*Adx;

         DiPlusBuffer[bar]=alpha2*DiPlus+(1-alpha2)*DiPlusBuffer[bar+1];
         DiMinusBuffer[bar]=alpha2*DiMinus+(1-alpha2)*DiMinusBuffer[bar+1];
         ADXBuffer[bar]=alpha2*Adx+(1-alpha2)*ADXBuffer[bar+1];
         
         // Calculate Avg and Std using the new class
         if(CheckPointer(ExtAdxCalc)==POINTER_DYNAMIC)
            ExtAdxCalc.Calculate(ADXBuffer[bar], ADX_AvgBuffer[bar], ADX_StdPBuffer[bar], ADX_StdMBuffer[bar]);
        }
      else
        {
         // 계산 시간이 아닌 경우: 이전 상태 유지 (Flat)
         DiPlusBuffer[bar] = DiPlusBuffer[bar+1];
         DiMinusBuffer[bar] = DiMinusBuffer[bar+1];
         ADXBuffer[bar] = ADXBuffer[bar+1];
         
         ADX_AvgBuffer[bar] = ADX_AvgBuffer[bar+1];
         ADX_StdPBuffer[bar] = ADX_StdPBuffer[bar+1];
         ADX_StdMBuffer[bar] = ADX_StdMBuffer[bar+1];
         
         // 중요: DiPlus, DiMinus, Adx 변수는 업데이트하지 않음 (이전 상태 유지)
         // 이렇게 하면 다음 bar(계산 재개 시점)에서 건너뛴 시간의 왜곡 없이 이전 상태에서 계속됨
        }
     }

   return(rates_total);
  }
