//+------------------------------------------------------------------+
//|                                                          CHV.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Chaikin Volatility"
#property strict
#include <MovingAverages.mqh>
#include <mySmoothingAlgorithm.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   5

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_COLOR_LINE

#property indicator_color1  clrYellow
#property indicator_color2  clrYellow
#property indicator_color3  clrYellow
#property indicator_color4  clrYellow
#property indicator_color5  clrLightBlue,clrDarkOrange

#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DASH
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID
#property indicator_style5  STYLE_SOLID

#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1

#property indicator_label1  "StdDev+3"
#property indicator_label2  "StdDev+2"
#property indicator_label3  "StdDev+1"
#property indicator_label4  "StdDev-1"
#property indicator_label5  "CHV"

#property indicator_level1 0.

//--- enum
enum SmoothMethod
  {
   SMA=0,// Simple MA
   EMA=1,// Exponential MA
   WMA=2 // Weighted MA
  };
//--- input parameters
input int          InpSmoothPeriod=30;  // Smoothing period
input int          InpCHVPeriod=30;     // CHV period
input SmoothMethod InpSmoothType=WMA;   // Smoothing method
input int          InpStdDevPeriod=5000;// StdDev period
input double       InpMultiFactor1=1.0; // StdDev MultiFactor1
input double       InpMultiFactor2=2.0; // StdDev MultiFactor2
input double       InpMultiFactor3=3.0; // StdDev MultiFactor3
//---- buffers
double             ExtUp3StdBuffer[];
double             ExtUp2StdBuffer[];
double             ExtUp1StdBuffer[];
double             ExtDown1StdBuffer[];
double             ExtCHVBuffer[];
double             ExtCHVColorBuffer[];
double             ExtHLBuffer[];
double             ExtSHLBuffer[];
double             CVScale[];
double             ExtStdDevBuffer[];
bool               g_IsWritten = false;
//--- global variables
int                ExtSmoothPeriod,ExtCHVPeriod,ExtStdDevPeriod;
HiStdDev3         *iStdDev3;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input variables
   string MAName;
//--- set MA name
   if(InpSmoothType==SMA)
      MAName="SMA";
   else if(InpSmoothType==EMA)
      MAName="EMA";
   else if(InpSmoothType==WMA)
      MAName="WMA";
//--- check inputs
   if(InpSmoothPeriod<=0)
     {
      ExtSmoothPeriod=30;
      printf("Incorrect value for input variable InpSmoothPeriod=%d. Indicator will use value=%d for calculations.",InpSmoothPeriod,ExtSmoothPeriod);
     }
   else ExtSmoothPeriod=InpSmoothPeriod;
   
   if(InpCHVPeriod<=0)
     {
      ExtCHVPeriod=30;
      printf("Incorrect value for input variable InpCHVPeriod=%d. Indicator will use value=%d for calculations.",InpCHVPeriod,ExtCHVPeriod);
     }
   else ExtCHVPeriod=InpCHVPeriod;
   
   if(InpStdDevPeriod<=0)
     {
      ExtStdDevPeriod=5000;
      printf("Incorrect value for input variable InpStdDevPeriod=%d. Indicator will use value=%d for calculations.",InpStdDevPeriod,ExtStdDevPeriod);
     }
   else ExtStdDevPeriod=InpStdDevPeriod;

//--- 입력 파라미터 검증: MultiFactor 값들이 양수인지 확인
   if(InpMultiFactor1 <= 0.0)
      printf("WARNING: Incorrect value for input variable InpMultiFactor1=%.2f. Should be positive.",InpMultiFactor1);
   if(InpMultiFactor2 <= 0.0)
      printf("WARNING: Incorrect value for input variable InpMultiFactor2=%.2f. Should be positive.",InpMultiFactor2);
   if(InpMultiFactor3 <= 0.0)
      printf("WARNING: Incorrect value for input variable InpMultiFactor3=%.2f. Should be positive.",InpMultiFactor3);

//--- set EmptyValue for plots
   for(int p=0; p<5; p++)
      PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- define buffers
   SetIndexBuffer(0,ExtUp3StdBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtUp2StdBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtUp1StdBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtDown1StdBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtCHVBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,ExtCHVColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,ExtHLBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,ExtSHLBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,CVScale,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,ExtStdDevBuffer,INDICATOR_CALCULATIONS);

//--- set draw begin
   int drawBegin = ExtSmoothPeriod+ExtCHVPeriod-1;
   for(int p=0; p<5; p++)
      PlotIndexSetInteger(p,PLOT_DRAW_BEGIN,drawBegin);

//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"Chaikin Volatility("+string(ExtSmoothPeriod)+","+string(ExtCHVPeriod)+","+MAName+","+
   string(ExtStdDevPeriod)+","+string(InpMultiFactor1)+","+string(InpMultiFactor2)+","+string(InpMultiFactor3)+")");
//--- round settings
   IndicatorSetInteger(INDICATOR_DIGITS,1);

//--- create HiStdDev3 object
   iStdDev3 = new HiStdDev3(ExtStdDevPeriod);
   if(CheckPointer(iStdDev3) == POINTER_INVALID)
     {
      Print("ERROR: HiStdDev3 객체 생성 실패! 인디케이터가 제대로 작동하지 않을 수 있습니다.");
      // 객체 생성 실패 시 초기화 중단하지 않고 계속 진행하되, OnCalculate에서 null 체크 필요
     }
//---- OnInit done
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(CheckPointer(iStdDev3) == POINTER_DYNAMIC)
      delete iStdDev3;
   iStdDev3 = NULL; // 안전을 위해 포인터 초기화
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- variables of indicator
   int    i,pos,posCHV;
   double stdDev;
   
//--- HiStdDev3 객체 null 체크
   if(CheckPointer(iStdDev3) == POINTER_INVALID)
     {
      // 객체가 없으면 StdDev 계산 없이 CHV만 계산
      Print("WARNING: HiStdDev3 객체가 유효하지 않습니다. StdDev 밴드가 계산되지 않습니다.");
     }
   
//--- check for rates total
   posCHV=ExtCHVPeriod+ExtSmoothPeriod-2;
   if(rates_total<posCHV)
      return(0);

//--- check for new bar (for StdDev calculation)
   const bool MnewBar = (prev_calculated<=0) ? true : isNewBar(_Symbol);

//--- start working
   if(prev_calculated<1 || prev_calculated > rates_total)
     {
      pos=0;
      
      // [Bug Fix] 전체 재계산 시 버퍼 초기화 필수
      // 초기화하지 않으면 이전 쓰레기 값이 남아 누적 연산이 폭발함
      ArrayInitialize(ExtUp3StdBuffer,0.0);
      ArrayInitialize(ExtUp2StdBuffer,0.0);
      ArrayInitialize(ExtUp1StdBuffer,0.0);
      ArrayInitialize(ExtDown1StdBuffer,0.0);
      ArrayInitialize(ExtCHVBuffer,0.0);
      ArrayInitialize(ExtCHVColorBuffer,0);
      ArrayInitialize(ExtHLBuffer,0.0);
      ArrayInitialize(ExtSHLBuffer,0.0);
      ArrayInitialize(CVScale,0.0);
      ArrayInitialize(ExtStdDevBuffer,0.0);
     
      g_IsWritten = false;
     
      // [Bug Fix] 객체 상태 초기화 (Stateful Object Reset)
      // iStdDev3 객체가 내부적으로 이전 계산 상태(누적값 등)를 가지고 있을 수 있으므로
      // 전체 재계산 시 객체를 새로 생성하여 상태를 리셋해야 합니다.
      if(CheckPointer(iStdDev3) == POINTER_DYNAMIC) delete iStdDev3;
      
      iStdDev3 = new HiStdDev3(ExtStdDevPeriod);
      if(CheckPointer(iStdDev3) == POINTER_INVALID) Print("OnCalculate: HiStdDev3 재생성 실패");
     }
   else pos=prev_calculated-1;
      
//--- fill H-L(i) buffer
   for(i=pos;i<rates_total && !IsStopped();i++) 
     {
      // 배열 범위 체크 및 제로 나누기 방지
      if(i >= ArraySize(High) || i >= ArraySize(Low))
         break;
      ExtHLBuffer[i]=High[i]-Low[i];
     }
      
//--- calculate smoothed H-L(i) buffer
   if(pos<ExtSmoothPeriod-1)
     {
      pos=ExtSmoothPeriod-1;
      for(i=0;i<pos;i++) ExtSHLBuffer[i]=0.0;
     }
     
   if(InpSmoothType==SMA)
      SimpleMAOnBuffer(rates_total,prev_calculated,0,ExtSmoothPeriod,ExtHLBuffer,ExtSHLBuffer);
   else if(InpSmoothType==EMA)
      ExponentialMAOnBuffer(rates_total,prev_calculated,0,ExtSmoothPeriod,ExtHLBuffer,ExtSHLBuffer);
   else if(InpSmoothType==WMA)
      LinearWeightedMAOnBuffer(rates_total,prev_calculated,0,ExtSmoothPeriod,ExtHLBuffer,ExtSHLBuffer);
      
//--- correct calc position
   if(pos<posCHV) pos=posCHV;
   
//--- calculate CHV buffer and StdDev bands
   for(i=pos;i<rates_total && !IsStopped();i++)
     {
      // 배열 범위 체크: i-ExtCHVPeriod가 유효한 범위인지 확인
      int prevIdx = i - ExtCHVPeriod;
      if(prevIdx < 0 || prevIdx >= ArraySize(ExtSHLBuffer))
        {
         ExtCHVBuffer[i] = EMPTY_VALUE;
         ExtCHVColorBuffer[i] = (i > 0) ? ExtCHVColorBuffer[i-1] : 0;
         continue;
        }
      
      //--- CHV 계산 (제로 나누기 방지)
      if(ExtSHLBuffer[prevIdx]!=0.0 && MathAbs(ExtSHLBuffer[prevIdx]) > 1e-10)
         ExtCHVBuffer[i]=100.0*(ExtSHLBuffer[i]-ExtSHLBuffer[prevIdx])/ExtSHLBuffer[prevIdx];
      else
         ExtCHVBuffer[i]=0.0;

      //--- set CHV color (0=Green for rising, 1=Red for falling)
      if(i > 0 && ExtCHVBuffer[i] != EMPTY_VALUE && ExtCHVBuffer[i-1] != EMPTY_VALUE)
        {
         if(ExtCHVBuffer[i] > ExtCHVBuffer[i-1])
            ExtCHVColorBuffer[i] = 0;  // Green
         else if(ExtCHVBuffer[i] < ExtCHVBuffer[i-1])
            ExtCHVColorBuffer[i] = 1;  // Red
         else
            ExtCHVColorBuffer[i] = ExtCHVColorBuffer[i-1];
        }
      else
         ExtCHVColorBuffer[i] = (i > 0) ? ExtCHVColorBuffer[i-1] : 0;

      //--- calculate Standard Deviation bands
      // 모든 바에 대해 StdDev 계산 (초기 로드 시 전체 계산, 업데이트 시 새 바만)
      if(CheckPointer(iStdDev3) != POINTER_INVALID)
        {
         // 초기 로드이거나 새 바인 경우에만 Calculate 호출
         // Calculate 함수는 내부적으로 bar 값 체크를 하므로 안전
         if(prev_calculated <= 0 || i == rates_total - 1)
           {
            stdDev = iStdDev3.Calculate(i, ExtCHVBuffer[i]);
            ExtStdDevBuffer[i] = stdDev;
            
            // 검증된 MultiFactor 값 사용 (음수나 0이면 기본값 사용)
            double mf1 = (InpMultiFactor1 > 0.0) ? InpMultiFactor1 : 1.0;
            double mf2 = (InpMultiFactor2 > 0.0) ? InpMultiFactor2 : 2.0;
            double mf3 = (InpMultiFactor3 > 0.0) ? InpMultiFactor3 : 3.0;
            
            ExtUp1StdBuffer[i]   =  stdDev * mf1;
            ExtDown1StdBuffer[i] = -stdDev * mf1;

            ExtUp2StdBuffer[i]   =  stdDev * mf2;
            ExtUp3StdBuffer[i]   =  stdDev * mf3;

            if(stdDev != 0) CVScale[i] = ExtCHVBuffer[i]/stdDev;
            else CVScale[i] = (i > 0) ? CVScale[i-1] : 0.0;

           }   

        }
      else
        {
         // HiStdDev3 객체가 없으면 EMPTY_VALUE 설정
         ExtUp1StdBuffer[i]   = EMPTY_VALUE;
         ExtDown1StdBuffer[i] = EMPTY_VALUE;
         ExtUp2StdBuffer[i]   = EMPTY_VALUE;
         ExtUp3StdBuffer[i]   = EMPTY_VALUE;
         CVScale[i]           = EMPTY_VALUE;
        }
     }
//----
   if(rates_total > 0 && !g_IsWritten) {
      string filename = "Chaikin_Volatility_DownLoad.csv";
      int handle = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_ANSI);
      
      if(handle != INVALID_HANDLE) {
         FileWrite(handle, "Time", "Open", "Close", "High", "Low", "CHV", "StdDev", "CVScale");
         
         for(int k=0; k<rates_total; k++) {
            string timeStr = TimeToString(Time[k], TIME_DATE|TIME_MINUTES);
            FileWrite(handle, timeStr, Open[k], Close[k], High[k], Low[k], ExtCHVBuffer[k], ExtStdDevBuffer[k], CVScale[k]);
         }
         FileClose(handle);
         Print("Data download complete: ", filename);
         g_IsWritten = true;
      } else {
         Print("Failed to open file for writing: ", filename, " Error: ", GetLastError());
      }
   }

   return(rates_total);
  }
//+------------------------------------------------------------------+
