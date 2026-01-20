//+------------------------------------------------------------------+
//|                                           BSPercentAvgShort2.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.01"


#include <mySmoothAlgorithm2.mqh>
#include <myBSPCalculation.mqh>

#property indicator_separate_window

#property indicator_buffers 13
#property indicator_plots  7 

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_COLOR_LINE

#property indicator_color1  clrWhite
#property indicator_color2  clrWhite
#property indicator_color3  clrWhite
#property indicator_color4  clrWhite
#property indicator_color5  clrWhite
#property indicator_color6  clrWhite
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

input int                 AvgPeriod     = 30;        // AvgPeriods  
input int                 SmoothPeriod  = 5;        // SmoothPeriod
input int                 StdPeriod     = 5000;      // StdPeriod
input double              MultiFactor1  = 1.0;       // MultiFactor1
input double              MultiFactor2  = 2.0;       // MultiFactor2
input double              MultiFactor3  = 3.0;       // MultiFactor3

ENUM_APPLIED_VOLUME  VolumeType = VOLUME_TICK;    // Volume

// 상수 정의
#define MIN_TOTAL_PRESSURE 0.001

double BuyRatio[], SellRatio[], AvgBuyRatio[], AvgSellRatio[], DiffRatio[], 
       SmoothDiffRatio[], SmoothDiffRatioC[], up3StdDiffBSP[], up2StdDiffBSP[], up1StdDiffBSP[], 
                                              down3StdDiffBSP[], down2StdDiffBSP[], down1StdDiffBSP[];
double ToPoint;
// SmoothDiffRatio의 RMS(=sqrt(sum(x^2)/N))를 빠르게 계산하기 위한 롤링 계산기
HiStdDev3 *iStdDev3;


//+------------------------------------------------------------------+  
void OnInit()
  {
   // 버퍼 초기 값이 차트에 "0"으로 그려지지 않도록 EmptyValue 지정
   for(int p=0; p<7; p++)
      PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   ArrayInitialize(BuyRatio,0.0);
   ArrayInitialize(SellRatio,0.0);
   ArrayInitialize(AvgBuyRatio,0.0);
   ArrayInitialize(AvgSellRatio,0.0);
   ArrayInitialize(DiffRatio,0.0);
   ArrayInitialize(SmoothDiffRatio,0.0);
   ArrayInitialize(SmoothDiffRatioC,0);
   ArrayInitialize(up3StdDiffBSP,0.0);
   ArrayInitialize(down3StdDiffBSP,0.0);
   ArrayInitialize(up2StdDiffBSP,0.0);
   ArrayInitialize(down2StdDiffBSP,0.0);
   ArrayInitialize(up1StdDiffBSP,0.0);
   ArrayInitialize(down1StdDiffBSP,0.0);


   SetIndexBuffer(0, up3StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(1, up2StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(2, up1StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(3, down1StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(4, down2StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(5, down3StdDiffBSP,INDICATOR_DATA);
   SetIndexBuffer(6, SmoothDiffRatio,INDICATOR_DATA);
   SetIndexBuffer(7, SmoothDiffRatioC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(8, DiffRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9, BuyRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10, SellRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11, AvgBuyRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12, AvgSellRatio,INDICATOR_CALCULATIONS);

   string short_name = "BSPercentAvgStd2("+ (string)AvgPeriod + ", "  + (string)SmoothPeriod +", "  + (string)StdPeriod + ", " + 
                  (string)MultiFactor1 + ", " + (string)MultiFactor2 + ", " + (string)MultiFactor3 + ")";

   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
    
//----

  switch(_Digits)
    {
      case 2: 
       ToPoint=MathPow(10., 3); break; 
      case 3: 
       ToPoint=MathPow(10., 3); break; 
      case 4: 
       ToPoint=MathPow(10., 5); break; 
      case 5: 
       ToPoint=MathPow(10., 5); break; 
    }

   string GoldSymbol = "XAUUSD";
   string thisSymbol = StringSubstr(_Symbol, 0, 6);
   if(thisSymbol == GoldSymbol) ToPoint = 100.;

   iStdDev3 = new HiStdDev3(StdPeriod);
   if(CheckPointer(iStdDev3) == POINTER_INVALID)   Print("HiStdDev3 객체 생성 실패!");


  }

  void OnDeinit(const int reason)
  {
     if(CheckPointer(iStdDev3) == POINTER_DYNAMIC)
        delete iStdDev3;
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
   const int avgPeriod = (AvgPeriod>1) ? AvgPeriod : 2;
   const int smoothPeriod = (SmoothPeriod>1) ? SmoothPeriod : 2;
   const int stdPeriod = (StdPeriod>1) ? StdPeriod : 2;

   // 최소 바 수 체크 (bar-1 접근 + avg/smooth/std 윈도우 확보)
   const int min_needed = 2 + avgPeriod + smoothPeriod + stdPeriod;
   if(rates_total <= min_needed)
      return(0);

   int first, second, third, fourth;
   double standardDeviation;

   // 첫 계산(히스토리 채움)에서는 new bar 여부와 무관하게 모두 계산
   const bool MnewBar = (prev_calculated<=0) ? true : isNewBar(_Symbol);


   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      first = 2;  
      second = first + avgPeriod;
      third = second + smoothPeriod;
      fourth = third + stdPeriod;
     }
   else
     { 
      first = prev_calculated - 1; 
      second = first;
      third = first;
      fourth = first;
     } 

   // 메인 계산 루프
   for(int bar = first; bar < rates_total; bar++)
     {
      double tempBuyRatio = CalculateBuyRatio(open, high, low, close, bar);
      double tempSellRatio = CalculateSellRatio(open, high, low, close, bar);
      double tempTotalPressure = MathAbs(tempBuyRatio) + MathAbs(tempSellRatio);
      
      // 0으로 나누기 방지
      if(tempTotalPressure == 0.0) tempTotalPressure = MIN_TOTAL_PRESSURE;
      
      // 비율을 퍼센트로 변환
      BuyRatio[bar]  = MathAbs(tempBuyRatio) / tempTotalPressure * 100.0;
      SellRatio[bar] = MathAbs(tempSellRatio) / tempTotalPressure * 100.0;
      
      if(bar >= second)
      {
         AvgBuyRatio[bar] = myAverage(bar, AvgPeriod, BuyRatio);
         AvgSellRatio[bar] = myAverage(bar, AvgPeriod, SellRatio);
         DiffRatio[bar] = AvgBuyRatio[bar] - AvgSellRatio[bar];
      }
      else
      {
         // 충분한 히스토리가 없을 때는 EMPTY_VALUE로 설정
         AvgBuyRatio[bar] = EMPTY_VALUE;
         AvgSellRatio[bar] = EMPTY_VALUE;
         DiffRatio[bar] = EMPTY_VALUE;
      }

      if(bar >= third) 
      {
         SmoothDiffRatio[bar] = iSmooth(DiffRatio[bar],SmoothPeriod,0,bar,rates_total,0);
         
         if(MnewBar)
         {
            standardDeviation = iStdDev3.Calculate(bar, SmoothDiffRatio[bar]);

            up1StdDiffBSP[bar]   = standardDeviation * MultiFactor1;
            down1StdDiffBSP[bar] = -standardDeviation * MultiFactor1;

            up2StdDiffBSP[bar]   = standardDeviation * MultiFactor2;
            down2StdDiffBSP[bar] = -standardDeviation * MultiFactor2;

            up3StdDiffBSP[bar]   = standardDeviation * MultiFactor3;
            down3StdDiffBSP[bar] = -standardDeviation * MultiFactor3;
         }
         
         // DRAW_COLOR_LINE의 색상 인덱스는 0..N-1 (여기서는 0=Green, 1=Red)
         if(bar > 0 && SmoothDiffRatio[bar] != EMPTY_VALUE && SmoothDiffRatio[bar-1] != EMPTY_VALUE)
         {
            if(SmoothDiffRatio[bar] > SmoothDiffRatio[bar-1])
               SmoothDiffRatioC[bar] = 0;
            else if(SmoothDiffRatio[bar] < SmoothDiffRatio[bar-1])
               SmoothDiffRatioC[bar] = 1;
            else
               SmoothDiffRatioC[bar] = SmoothDiffRatioC[bar-1];
         }
         else
            SmoothDiffRatioC[bar] = (bar > 0) ? SmoothDiffRatioC[bar-1] : 0;
      }
      else
      {
         SmoothDiffRatio[bar] = EMPTY_VALUE;
         SmoothDiffRatioC[bar] = (bar > 0) ? SmoothDiffRatioC[bar-1] : 0;
      }
      
    }  

   return(rates_total);
  }
