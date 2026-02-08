//------------------------------------------------------------------
//                                                   ChoppingIndex.mq5
//                                             Copyright © 2018, mladen
//                                                 mladenfx@gmail.com
//------------------------------------------------------------------
#property copyright   "© mladen, 2018"
#property link        "mladenfx@gmail.com"
#property version     "1.00"
#property description "Choppiness index - JMA smoothed"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   4

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_DOT
#property indicator_width1  1
#property indicator_label1  "Average"

#property indicator_type2   DRAW_LINE
#property indicator_color2  clrWhite
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_label2  "Upper Band"

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrWhite
#property indicator_style3  STYLE_DOT
#property indicator_width3  1
#property indicator_label3  "Lower Band"

#property indicator_type4   DRAW_COLOR_LINE
#property indicator_color4  clrLimeGreen,clrCrimson
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
#property indicator_label4  "Choppiness Index"

#include <mySmoothAlgorithm2.mqh>

input int    inpChoPeriod    = 120;  // Choppiness index period
input int    inpSmoothPeriod = 40;  // Smooth period
input int    inpAvgPeriod    = 1000;  // Average period
input int    inpStdPeriod    = 4000;  // Std period
input double inpSmoothPhase  = 0;   // Smooth phase

HiAverage *iAverage;
HiStdDev1 *iStdDev1;

double avgVal[], stdPVal[], stdMVal[], csi[], csic[], choppingScale[];

bool g_IsWritten = false; // 파일 작성 여부 확인용 플래그

//------------------------------------------------------------------
// Custom indicator initialization function
//------------------------------------------------------------------
int OnInit()
{
   SetIndexBuffer(0, stdPVal, INDICATOR_DATA);
   SetIndexBuffer(1, avgVal, INDICATOR_DATA);
   SetIndexBuffer(2, stdMVal, INDICATOR_DATA);
   SetIndexBuffer(3, csi,    INDICATOR_DATA);
   SetIndexBuffer(4, csic,   INDICATOR_COLOR_INDEX);
   
   // [Fix] choppingScale 버퍼 할당 추가 (INDICATOR_CALCULATIONS)
   // SetIndexBuffer를 하지 않으면 메모리 할당이 안 되어 Array Out of Range 발생
   SetIndexBuffer(5, choppingScale, INDICATOR_CALCULATIONS);

   IndicatorSetString(INDICATOR_SHORTNAME, "Jma smoothed Choppiness index (" + string(inpChoPeriod) + "," + string(inpSmoothPeriod) + ")");

   // 객체 초기 생성
   iAverage = new HiAverage((inpAvgPeriod > 1) ? inpAvgPeriod : 2);
   if(CheckPointer(iAverage) == POINTER_INVALID) Print("Init: HiAverage 객체 생성 실패!");

   iStdDev1 = new HiStdDev1((inpStdPeriod > 1) ? inpStdPeriod : 2);
   if(CheckPointer(iStdDev1) == POINTER_INVALID) Print("Init: HiStdDev1 객체 생성 실패!");

   return(INIT_SUCCEEDED);
}

//------------------------------------------------------------------
// Custom indicator deinitialization function
//------------------------------------------------------------------
void OnDeinit(const int reason)
{
   // 메모리 정리 작업
   if(CheckPointer(iAverage) == POINTER_DYNAMIC) delete iAverage;
   if(CheckPointer(iStdDev1) == POINTER_DYNAMIC) delete iStdDev1;
}

//------------------------------------------------------------------
// Custom indicator iteration function
//------------------------------------------------------------------
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   Print("OnCalculate Start: rates_total=", rates_total, " prev_calculated=", prev_calculated);
   if(Bars(_Symbol, _Period) < rates_total) { Print("Error: Bars < rates_total"); return(-1); }
   
   // 초기화 로직: 처음 시작하거나 데이터 갱신 시
   if(prev_calculated > rates_total || prev_calculated <= 0)
   {
      // 배열 초기화
      ArrayInitialize(avgVal, 0.0);
      ArrayInitialize(stdPVal, 0.0);
      ArrayInitialize(stdMVal, 0.0);
      ArrayInitialize(csi, 0.0);
      ArrayInitialize(csic, 0.0);
      ArrayInitialize(choppingScale, 0.0);
      
      g_IsWritten = false; // [Fix] 초기화 시 파일 쓰기 플래그 리셋 (재다운로드 가능하게 함)

      // 객체 상태 초기화 (재생성)
      if(CheckPointer(iAverage) == POINTER_DYNAMIC) delete iAverage;
      if(CheckPointer(iStdDev1) == POINTER_DYNAMIC) delete iStdDev1;

      iAverage = new HiAverage((inpAvgPeriod > 1) ? inpAvgPeriod : 2);
      iStdDev1 = new HiStdDev1((inpStdPeriod > 1) ? inpStdPeriod : 2);
   }

   double _log = MathLog(inpChoPeriod) / 100.00;
   int start_idx = (prev_calculated > 0) ? prev_calculated - 1 : 0;

   for (int i = start_idx; i < rates_total; i++)
   {
      double atrSum = 0.00;
      double maxHig = high[i];
      double minLow = low[i];

      // i-k-1 >= 0 체크가 있으므로 루프 안전함
      for (int k = 0; k < inpChoPeriod && (i - k - 1) >= 0; k++)
      {
         atrSum += MathMax(high[i - k], close[i - k - 1]) - MathMin(low[i - k], close[i - k - 1]);
         maxHig = MathMax(maxHig, MathMax(high[i - k], close[i - k - 1]));
         minLow = MathMin(minLow, MathMin(low[i - k], close[i - k - 1]));
      }

      double _val = (maxHig != minLow) ? atrSum / (maxHig - minLow) : 0;
      double _csi = (_val != 0) ? MathLog(_val) / _log : 0;
      
      // 스무딩 계산
      csi[i] = iSmooth(_csi, inpSmoothPeriod, inpSmoothPhase, i, rates_total, 0);
      
      // 색상 처리
      csic[i] = (i > 0) ? (csi[i] > csi[i - 1]) ? 0 : (csi[i] < csi[i - 1]) ? 1 : csic[i - 1] : 0;

      // 평균 및 표준편차 밴드 계산
      if(CheckPointer(iAverage) != POINTER_INVALID && CheckPointer(iStdDev1) != POINTER_INVALID)
      {

         avgVal[i] = iAverage.Calculate(i, csi[i]);
         double std = iStdDev1.Calculate(i, avgVal[i], csi[i]);

         stdPVal[i] = avgVal[i] + std;
         stdMVal[i] = avgVal[i] - std;

         if(std != 0.)  
         {
             choppingScale[i] = (csi[i]-avgVal[i])/std;
         }
         else 
         {
             // [Fix] i=0 일 때 i-1 참조 안전장치 추가
             if(i > 0) choppingScale[i] = choppingScale[i-1];
             else choppingScale[i] = 0.0;
         }
      }
   }
   
   
   // --- File Writing Logic ---
   Print("Check Write: rates_total=", rates_total, " g_IsWritten=", g_IsWritten);
   if(rates_total > 0 && !g_IsWritten) 
   {
      string filename = "ChoppingIndex_DownLoad.csv";
      int handle = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_ANSI);
      
      if(handle != INVALID_HANDLE) 
      {
         FileWrite(handle, "Time", "Open", "Close", "High", "Low", "CSI", "Average", "ChoppingScale");
         
         for(int k=0; k<rates_total; k++) 
         {
            string timeStr = TimeToString(time[k], TIME_DATE|TIME_MINUTES);
            FileWrite(handle, timeStr, open[k], close[k], high[k], low[k], csi[k], avgVal[k], choppingScale[k]);
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
