//+------------------------------------------------------------------+
//|                                                          QQE.mq5 |
//|                                   Converted from MQL4 by Gemini  |
//|                                     Original © 2006 Roman Ignatov|
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006 Roman Ignatov (MQL5 Port)"
#property link      "mailto:roman.ignatov@gmail.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6  // 계산용 버퍼 포함 총 6개 필요
#property indicator_plots   2

//--- Plot settings
#property indicator_label1  "RSI MA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "QQE Line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_DOT
#property indicator_width2  2

//--- Input parameters
input int SF = 12;           // Smoothing Factor
input int RSI_Period = 32; // RSI Period

//--- Indicator buffers
double RsiMaBuffer[];        // 화면 표시 1
double TrLevelSlowBuffer[];  // 화면 표시 2

//--- Calculation buffers (Hidden)
double RsiBuffer[];          // RSI 원본 값 저장
double AtrRsiBuffer[];       // RSI의 변동폭(ATR)
double MaAtrRsiBuffer[];      // 변동폭의 EMA
double DarBuffer[];          // Double Smoothed ATR (4.236 곱한 값)

//--- Global variables
int Wilders_Period;
int handle_RSI;              // RSI 지표 핸들

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // 1. 변수 초기화
   Wilders_Period = RSI_Period * 2 - 1;

   // 2. 버퍼 매핑
   SetIndexBuffer(0, RsiMaBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, TrLevelSlowBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, RsiBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, AtrRsiBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, MaAtrRsiBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, DarBuffer, INDICATOR_CALCULATIONS);

   // 3. 배열을 시계열처럼 인덱싱하지 않고 기본값(0부터 시작) 사용
   // MQL5는 Loop 최적화를 위해 ArraySetAsSeries를 false로 두는 것이 일반적임.

   // 4. 이름 설정
   string short_name = StringFormat("QQE(%d, %d)", RSI_Period, SF);
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);

   // 5. RSI 지표 핸들 생성
   handle_RSI = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE);
   if(handle_RSI == INVALID_HANDLE)
     {
      Print("Failed to create RSI handle");
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
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
   // 데이터 부족 시 종료
   if(rates_total < Wilders_Period)
      return(0);

   // 1. RSI 값 복사 (지표 핸들에서 버퍼로)
   int copy_count = CopyBuffer(handle_RSI, 0, 0, rates_total, RsiBuffer);
   if(copy_count <= 0)
      return(0);

   // [Bug Fix] 전체 재계산 시 버퍼 초기화
   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      ArrayInitialize(RsiMaBuffer,0.0);
      ArrayInitialize(AtrRsiBuffer,0.0);
      ArrayInitialize(MaAtrRsiBuffer,0.0);
      ArrayInitialize(DarBuffer,0.0);
      ArrayInitialize(TrLevelSlowBuffer,0.0);
     }

   // 2. 루프 범위 설정
   int start = prev_calculated - 1;
   if(start < 0)
      start = 0;

   //--- Main Calculation Loop
   for(int i = start; i < rates_total; i++)
     {
      // [Step 1] RSI Smoothing (RsiMa) -> EMA 방식
      // EMA Formula: Price * alpha + PrevEMA * (1-alpha)
      if(i == 0)
        {
         RsiMaBuffer[i] = RsiBuffer[i];
         AtrRsiBuffer[i] = 0;
         MaAtrRsiBuffer[i] = 0;
         DarBuffer[i] = 0;
         TrLevelSlowBuffer[i] = RsiMaBuffer[i]; // 초기값
         continue;
        }

      // -- Calc RsiMa (SF Period EMA)
      double alpha_sf = 2.0 / (SF + 1.0); // EMA 계수
      RsiMaBuffer[i] = RsiBuffer[i] * alpha_sf + RsiMaBuffer[i-1] * (1.0 - alpha_sf);

      // [Step 2] ATR of RSI
      // abs(Current RsiMa - Prev RsiMa)
      AtrRsiBuffer[i] = MathAbs(RsiMaBuffer[i] - RsiMaBuffer[i-1]);

      // [Step 3] Smooth ATR (Wilders Period EMA) -> MaAtrRsi
      double alpha_wilder = 2.0 / (Wilders_Period + 1.0);
      MaAtrRsiBuffer[i] = AtrRsiBuffer[i] * alpha_wilder + MaAtrRsiBuffer[i-1] * (1.0 - alpha_wilder);

      // [Step 4] Smooth MaAtrRsi again (Wilders Period EMA) * 4.236 -> DAR
      // 원래 코드는 iMAOnArray를 두 번 태우는 구조임.
      // 12번 라인의: dar = iMAOnArray(MaAtrRsi, ... ) * 4.236;
      // 이를 위해 별도의 EMA 계산을 한 번 더 수행해야 함.
      // 여기서는 임시 변수 대신 DarBuffer에 EMA 결과를 저장하지 않고 값만 계산해도 되지만,
      // iMAOnArray를 흉내내기 위해 이전 값을 저장하는 버퍼(DarBuffer)를 씁니다.
      
      // 주의: 여기서 DarBuffer는 'DAR 값 자체'가 아니라 'MaAtrRsi의 EMA'를 저장함.
      // 실제 dar 값은 나중에 4.236을 곱해서 사용.
      DarBuffer[i] = MaAtrRsiBuffer[i] * alpha_wilder + DarBuffer[i-1] * (1.0 - alpha_wilder);
      
      double dar = DarBuffer[i] * 4.236;

      // [Step 5] Trailing Level Logic (QQE Core Logic)
      // 원본 코드의 12~17번 라인 로직 재구현
      double rsi0 = RsiMaBuffer[i];
      double rsi1 = RsiMaBuffer[i-1];
      double tr   = TrLevelSlowBuffer[i-1];
      double dv   = tr; // dv는 이전 tr 값

      if(rsi0 < tr)
        {
         tr = rsi0 + dar;
         if(rsi1 < dv)
           {
            if(tr > dv)
               tr = dv;
           }
        }
      else if(rsi0 > tr)
        {
         tr = rsi0 - dar;
         if(rsi1 > dv)
           {
            if(tr < dv)
               tr = dv;
           }
        }

      TrLevelSlowBuffer[i] = tr;
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
