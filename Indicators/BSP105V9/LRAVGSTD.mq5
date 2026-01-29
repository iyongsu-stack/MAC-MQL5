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

#property indicator_separate_window

#property indicator_buffers 11
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
input int                 AvgPeriod    = 30;          //AvgPeriod
input int                 StdPeriodL    = 5000;        // StdPeriodL
input int                 StdPeriodS    = 2;        // StdPeriodS(=2 고정)

input double              MultiFactorL1  = 1.;         // StdMultiFactorL1
input double              MultiFactorL2  = 2.0;         // StdMultiFactorL2
input double              MultiFactorL3  = 3.0;         // StdMultiFactorL3

input double              MaxBSPMult     = 20.0;         // MaxBSPmultfactor



double DiffPressure[], LWMAVal[],
       avgValLR[], stdS[], stdSC[], 
       up1StdAvgValLR[], up2StdAvgValLR[], up3StdAvgValLR[],
       down1StdAvgValLR[], down2StdAvgValLR[], down3StdAvgValLR[];

double ToPoint;    

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
   
  
   string short_name = "BSPLRAVGSTD("+ (string)LwmaPeriod + ", "  + (string)AvgPeriod + ", " +
                                            (string)StdPeriodL + ", " + (string)StdPeriodS + ", " + 
                                            (string)MultiFactorL1 + ", " + (string)MultiFactorL2 + ", " + 
                                            (string)MultiFactorL3 + ", "  + (string)MaxBSPMult +  ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
 
   _lwma.init((LwmaPeriod > 1) ? LwmaPeriod : 2);

   // [Code Improvement] 포인트 계산 로직을 모든 상품에 범용적으로 적용 가능하도록 개선
   // 상품의 종류(Forex, CFD 등)와 최소 가격 단위(_Point)를 직접 참조하여 ToPoint를 동적으로 계산합니다.
   // 이를 통해 "XAUUSD"와 같은 특정 심볼 이름을 하드코딩할 필요가 없어지며, 다른 CFD 상품에도 자동 대응됩니다.
   
   // 1. 상품의 최소 가격 변동폭(_Point)이 유효한지 확인합니다.
   if(_Point > 0)
     {
       // 2. 기본적으로 ToPoint를 (1.0 / _Point)로 설정합니다.
       //    이것만으로 대부분의 CFD, 주식, 지수(XAUUSD, US30 등)는 최소 가격 변동이 '1'로 정규화됩니다.
       //    예: XAUUSD의 _Point가 0.01이면, ToPoint는 1/0.01 = 100이 됩니다.
       ToPoint = 1.0 / _Point;

       // 3. 만약 상품이 Forex일 경우에만, 4자리/2자리 브로커와의 호환성을 위해 스케일을 보정합니다.
       ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
       if (calcMode == SYMBOL_TRADE_CALC_MODE_FOREX && _Digits % 2 == 0)
       {
           // _Digits가 짝수(2, 4)인 경우 10을 추가로 곱해 1핍(pip)의 가치를 '10'으로 통일합니다.
           ToPoint *= 10.0;
       }
   }
   else
   {
       // 4. _Point가 0인 비정상적인 경우에 대한 방어 코드
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

   // 최소 바 수 체크 (bar-1 접근 + lwma/avg/std 윈도우 확보)
   const int min_needed = 2 + lwmaPeriod + avgPeriod + MathMax(stdPeriodL, stdPeriodS);
   if(rates_total <= min_needed)
      return(0);

   int first, second;
   double mVolume, standardDeviationL;

   // 첫 계산(히스토리 채움)에서는 new bar 여부와 무관하게 모두 계산
   const bool MnewBar = (prev_calculated<=0) ? true : isNewBar(_Symbol);

   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      first = 2;  
      second = first + avgPeriod;
      
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
     }
   else
     { 
      first = prev_calculated - 1; 
      second = first;
     } 

   // 메인 계산 루프
   for(int bar = first; bar < rates_total; bar++)
     {
      if(VolumeType == VOLUME_TICK) mVolume = (double)tick_volume[bar];
      else mVolume = (double)volume[bar];

      double tempBuyRatio = CalculateBuyRatio(open, high, low, close, bar);
      double tempSellRatio = CalculateSellRatio(open, high, low, close, bar);
      double tempDiffPressure = (MathAbs(tempBuyRatio) - MathAbs(tempSellRatio))*ToPoint;    

      DiffPressure[bar] = DiffPressure[bar-1] + tempDiffPressure;

      LWMAVal[bar] = _lwma.calculate(DiffPressure[bar], bar, rates_total);
             
      if(bar >= second)
       {
         avgValLR[bar] = myAverage(bar, AvgPeriod, LWMAVal);

         stdS[bar] = iStdDev2.Calculate(bar, avgValLR[bar], LWMAVal[bar]);  
         
         // DRAW_COLOR_LINE의 색상 인덱스는 0..N-1 (여기서는 0=Green, 1=Red)
         if(bar > 0 && stdS[bar] != EMPTY_VALUE && stdS[bar-1] != EMPTY_VALUE)
         {
            if(stdS[bar] > stdS[bar-1])
               stdSC[bar] = 0;
            else if(stdS[bar] < stdS[bar-1])
               stdSC[bar] = 1;
            else
               stdSC[bar] = stdSC[bar-1];
         }
         else
            stdSC[bar] = (bar > 0) ? stdSC[bar-1] : 0;

         if(MnewBar)
         {
           standardDeviationL = iStdDev1.Calculate(bar, avgValLR[bar], LWMAVal[bar]);

           up1StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL1;
           down1StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL1;

           up2StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL2;
           down2StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL2;

           up3StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL3;
           down3StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL3;
         }
       }
      else
       {
         // 충분한 히스토리가 없을 때는 EMPTY_VALUE로 설정
         avgValLR[bar] = EMPTY_VALUE;
         stdS[bar] = EMPTY_VALUE;
         stdSC[bar] = (bar > 0) ? stdSC[bar-1] : 0;
       }
    }  

   return(rates_total);
  }
//+----------------------