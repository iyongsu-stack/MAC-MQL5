//+------------------------------------------------------------------+
//|                                                     LRAVGSTD.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <mySmoothingAlgorithm.mqh>
#include <myBSPCalculation.mqh>
#include <myFunction.mqh>

#property indicator_separate_window

#property indicator_buffers 12
#property indicator_plots   7

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_COLOR_LINE

#property indicator_color1  clrYellow
#property indicator_color2  clrYellow
#property indicator_color3  clrYellow
#property indicator_color4  clrYellow
#property indicator_color5  clrYellow
#property indicator_color6  clrYellow
#property indicator_color7  clrGreen,clrRed

#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DASH
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID
#property indicator_style5  STYLE_DASH
#property indicator_style6  STYLE_DOT
#property indicator_style7  STYLE_SOLID


#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  2


#property indicator_level1 0.
ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume

input int                 LwmaPeriod    = 25;          // WmaPeriod1
input int                 AvgPeriod    = 60;          //AvgPeriod
input int                 StdPeriodL    = 5000;        // StdPeriodL
input int                 StdPeriodS    = 2;        // StdPeriodS(=2 고정)

input double              MultiFactorL1  = 1.;         // StdMultiFactorL1
input double              MultiFactorL2  = 2.0;         // StdMultiFactorL2
input double              MultiFactorL3  = 3.0;         // StdMultiFactorL3

input group "Time Filter"
input int StdCalcStartTimeHour = 1;      // Start Calculation (Hour)
input int StdCalcStartTimeMinute = 30;   // Start Calculation (Minute)
input int StdCalcEndTimeHour = 23;       // End Calculation (Hour)
input int StdCalcEndTimeMinute = 30;     // End Calculation (Minute)

input double              MaxBSPMult     = 20.0;         // MaxBSPmultfactor

double DiffPressure[], LWMAVal[],
       avgValLR[], stdS[], stdSC[], 
       up1StdAvgValLR[], up2StdAvgValLR[], up3StdAvgValLR[],
       down1StdAvgValLR[], down2StdAvgValLR[], down3StdAvgValLR[], BSPScale[];

double ToPoint;    
bool g_IsWritten = false;

HiStdDev1 *iStdDev1;
HiStdDev2 *iStdDev2;

//+------------------------------------------------------------------+  
void OnInit()
  {
   // 버퍼 초기 값이 차트에 "0"으로 그려지지 않도록 EmptyValue 지정
   for(int p=0; p<7; p++)
      PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   ArrayInitialize(DiffPressure,0.0);
   ArrayInitialize(LWMAVal,0.0);    
   ArrayInitialize(avgValLR,0.0);
   ArrayInitialize(stdS,0.0);
   ArrayInitialize(stdSC,0);
   ArrayInitialize(up1StdAvgValLR,0.0);
   ArrayInitialize(up2StdAvgValLR,0.0);
   ArrayInitialize(up3StdAvgValLR,0.0);   
   ArrayInitialize(down1StdAvgValLR,0.0);
   ArrayInitialize(down2StdAvgValLR,0.0);
   ArrayInitialize(down3StdAvgValLR,0.0); 
   ArrayInitialize(BSPScale,0.0);

   SetIndexBuffer(0,up3StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(1,up2StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(2,up1StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(3,down1StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(4,down2StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(5,down3StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(6,stdS,INDICATOR_DATA);     
   SetIndexBuffer(7,stdSC,INDICATOR_COLOR_INDEX);     
   SetIndexBuffer(8,DiffPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,LWMAVal,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,avgValLR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,BSPScale,INDICATOR_CALCULATIONS);
   
  
   string short_name = "BSPLRAVGSTD("+ (string)LwmaPeriod + ", "  + (string)AvgPeriod + ", " +
                                            (string)StdPeriodL + ", " + (string)StdPeriodS + ", " + 
                                            (string)MultiFactorL1 + ", " + (string)MultiFactorL2 + ", " + 
                                            (string)MultiFactorL3 + ", "  + (string)MaxBSPMult +  ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
 
   _lwma.init((LwmaPeriod > 1) ? LwmaPeriod : 2);

   if(_Point > 0)
     {
       ToPoint = 1.0 / _Point;

       ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
       bool isGold = (StringFind(_Symbol, "XAU") != -1) || (StringFind(_Symbol, "GOLD") != -1);
       if (calcMode == SYMBOL_CALC_MODE_FOREX && _Digits % 2 == 0 && !isGold)
       {
           ToPoint *= 10.0;
       }
   }
   else
   {
       ToPoint = 1.0;
       Print("Warning: Symbol ", _Symbol, " has a point size of 0. ToPoint set to 1.");
   }

   iStdDev1 = new HiStdDev1((StdPeriodL > 1) ? StdPeriodL : 2);
   if(CheckPointer(iStdDev1) == POINTER_INVALID)   Print("HiStdDev1 객체 생성 실패!");

   iStdDev2 = new HiStdDev2((StdPeriodS > 1) ? StdPeriodS : 2);
   if(CheckPointer(iStdDev2) == POINTER_INVALID)   Print("HiStdDev2 객체 생성 실패!");

//----
  }
  
  void OnDeinit(const int reason)
  {
     if(CheckPointer(iStdDev1) == POINTER_DYNAMIC)
        delete iStdDev1;
     if(CheckPointer(iStdDev2) == POINTER_DYNAMIC)
        delete iStdDev2;
  }
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+


int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of price maximums for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   // 입력값 방어 (0/음수 기간 방지)
   const int lwmaPeriod = (LwmaPeriod>1) ? LwmaPeriod : 2;
   const int avgPeriod = (AvgPeriod>1) ? AvgPeriod : 2;
   const int stdPeriodL = (StdPeriodL>1) ? StdPeriodL : 2;
   const int stdPeriodS = (StdPeriodS>1) ? StdPeriodS : 2;

   int first;
   double mVolume, standardDeviationL;

   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      first = 2;  
      
      // [Bug Fix] 전체 재계산 시 버퍼 초기화 필수
      // 초기화하지 않으면 DiffPressure[1]에 이전 쓰레기 값이 남아 누적 연산이 폭발함
      ArrayInitialize(DiffPressure,0.0);
      ArrayInitialize(LWMAVal,0.0);    
      ArrayInitialize(avgValLR,0.0);
      ArrayInitialize(stdS,0.0);
      ArrayInitialize(stdSC,0);
      ArrayInitialize(up1StdAvgValLR,0.0);
      ArrayInitialize(up2StdAvgValLR,0.0);
      ArrayInitialize(up3StdAvgValLR,0.0);   
      ArrayInitialize(down1StdAvgValLR,0.0);
      ArrayInitialize(down2StdAvgValLR,0.0);
      ArrayInitialize(down3StdAvgValLR,0.0); 
      ArrayInitialize(BSPScale,0.0);
     
      // [Bug Fix] 객체 상태 초기화 (Stateful Object Reset)
      // iStdDev 객체들이 내부적으로 이전 계산 상태(누적값 등)를 가지고 있을 수 있으므로
      // 전체 재계산 시 객체를 새로 생성하여 상태를 리셋해야 합니다.
      if(CheckPointer(iStdDev1) == POINTER_DYNAMIC) delete iStdDev1;
      if(CheckPointer(iStdDev2) == POINTER_DYNAMIC) delete iStdDev2;
      
      iStdDev1 = new HiStdDev1(stdPeriodL); // 위에서 정의한 안전한 로컬 변수 사용
      if(CheckPointer(iStdDev1) == POINTER_INVALID) Print("OnCalculate: HiStdDev1 재생성 실패");
      
      iStdDev2 = new HiStdDev2(stdPeriodS); // 위에서 정의한 안전한 로컬 변수 사용
      if(CheckPointer(iStdDev2) == POINTER_INVALID) Print("OnCalculate: HiStdDev2 재생성 실패");
      
      // _lwma 객체도 상태를 가질 수 있으므로 초기화
      _lwma.init(lwmaPeriod); // 위에서 정의한 안전한 로컬 변수 사용
      g_IsWritten = false;

     }
   else
     { 
      first = prev_calculated - 1; 
     } 

   // 메인 계산 루프
   for(int bar = first; bar < rates_total; bar++){
      if(VolumeType == VOLUME_TICK) mVolume = (double)tick_volume[bar];
      else mVolume = (double)volume[bar];

      double tempBuyRatio = CalculateBuyRatio(open, high, low, close, bar);
      double tempSellRatio = CalculateSellRatio(open, high, low, close, bar);
      double tempDiffPressure = (MathAbs(tempBuyRatio) - MathAbs(tempSellRatio))*ToPoint;    

      DiffPressure[bar] = DiffPressure[bar-1] + tempDiffPressure;

      LWMAVal[bar] = _lwma.calculate(DiffPressure[bar], bar, rates_total);
             
      avgValLR[bar] = myAverage(bar, AvgPeriod, LWMAVal);

      stdS[bar] = iStdDev2.Calculate(bar, avgValLR[bar], LWMAVal[bar]);  
      stdSC[bar] = (bar>0) ? (stdS[bar]>=stdS[bar-1]) ? 0 : (stdS[bar]<stdS[bar-1]) ? 1 : stdS[bar-1] : 0;

      bool isCalcTime = IsStdCalculationTime(time[bar]);
      if (isCalcTime) {         
         standardDeviationL = iStdDev1.Calculate(bar, avgValLR[bar], LWMAVal[bar]);
         up1StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL1;
         down1StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL1;
         up2StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL2;
         down2StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL2;
         up3StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL3;
         down3StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL3;

         if(standardDeviationL != 0) BSPScale[bar] = stdS[bar] / standardDeviationL;
         else BSPScale[bar] = (bar > 0) ? BSPScale[bar-1] : 0.0;

      } else {
         up1StdAvgValLR[bar]   =   up1StdAvgValLR[bar-1];
         down1StdAvgValLR[bar] =  down1StdAvgValLR[bar-1];
         up2StdAvgValLR[bar]   =   up2StdAvgValLR[bar-1];
         down2StdAvgValLR[bar] =  down2StdAvgValLR[bar-1];
         up3StdAvgValLR[bar]   =   up3StdAvgValLR[bar-1];
         down3StdAvgValLR[bar] =  down3StdAvgValLR[bar-1];
         if(bar > 0) BSPScale[bar] = BSPScale[bar-1];
      }         
   }  

   // --- File Writing Logic ---
   if(!g_IsWritten) {
      string filename = "LRAVGSTD_DownLoad.csv";
      int handle = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_ANSI);
      
      if(handle != INVALID_HANDLE) {
         FileWrite(handle, "Time", "Open", "Close", "High", "Low", "stdS", "BSPScale");
         
         for(int k=0; k<rates_total; k++) {
            string timeStr = TimeToString(time[k], TIME_DATE|TIME_MINUTES);
            FileWrite(handle, timeStr, open[k], close[k], high[k], low[k], stdS[k], BSPScale[k]);
         }
         FileClose(handle);
         Print("Data download complete: ", filename);
         g_IsWritten = true;
      } else {
         Print("Failed to open file for writing: ", filename);
      }
   }

   return(rates_total);
  }
//+----------------------