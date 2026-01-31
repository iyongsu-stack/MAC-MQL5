//------------------------------------------------------------------
#property copyright "© mladen, 2018"
#property link "mladenfx@gmail.com"
#property version "1.00"
//------------------------------------------------------------------
#property indicator_separate_window

#property indicator_buffers 10
#property indicator_plots 7

#property indicator_label7 "Diff"

#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_LINE
#property indicator_type3 DRAW_LINE
#property indicator_type4 DRAW_LINE
#property indicator_type5 DRAW_LINE
#property indicator_type6 DRAW_LINE
#property indicator_type7 DRAW_COLOR_LINE

#property indicator_color1 clrWhite
#property indicator_color2 clrWhite
#property indicator_color3 clrWhite
#property indicator_color4 clrWhite
#property indicator_color5 clrWhite
#property indicator_color6 clrWhite
#property indicator_color7 clrLimeGreen, clrOrange

#property indicator_style1 STYLE_DOT
#property indicator_style2 STYLE_DASH
#property indicator_style3 STYLE_SOLID
#property indicator_style4 STYLE_SOLID
#property indicator_style5 STYLE_DASH
#property indicator_style6 STYLE_DOT
#property indicator_style7 STYLE_SOLID

#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1
#property indicator_width5 1
#property indicator_width6 1
#property indicator_width7 1

#define MIN_TOTAL_PRESSURE 0.001

#include <myBSPCalculation.mqh>
#include <mySmoothingAlgorithm.mqh>

//-------------------
input int inpSmoothPeriod = 15;  // Smoothing period
input int inpAvgPeriod = 240;    // Avg period
input int inpStdPeriod = 5000;   // Std period
input double inpStdMulti1 = 1.0; // Std multiplier1
input double inpStdMulti2 = 2.0; // Std multiplier2
input double inpStdMulti3 = 3.0; // Std multiplier3

double BOP[], BOPAvg[], Diff[], DiffC[], Up3[], Up2[], Up1[], Down1[], Down2[],
    Down3[];

HiStdDev3 *stdDev3 = NULL; // StdDev3 클래스 인스턴스

void OnInit() {
  // HiStdDev3 클래스 인스턴스 생성
  if (stdDev3 != NULL)
    delete stdDev3;
  stdDev3 = new HiStdDev3(inpStdPeriod);

  ArrayInitialize(BOP, 0.0);
  ArrayInitialize(BOPAvg, 0.0);
  ArrayInitialize(Diff, 0.0);
  ArrayInitialize(DiffC, 0);
  ArrayInitialize(Up3, 0.0);
  ArrayInitialize(Up2, 0.0);
  ArrayInitialize(Up1, 0.0);
  ArrayInitialize(Down1, 0.0);
  ArrayInitialize(Down2, 0.0);
  ArrayInitialize(Down3, 0.0);

  //--- indicator buffers mapping
  SetIndexBuffer(0, Up3, INDICATOR_DATA);
  SetIndexBuffer(1, Up2, INDICATOR_DATA);
  SetIndexBuffer(2, Up1, INDICATOR_DATA);
  SetIndexBuffer(3, Down1, INDICATOR_DATA);
  SetIndexBuffer(4, Down2, INDICATOR_DATA);
  SetIndexBuffer(5, Down3, INDICATOR_DATA);
  SetIndexBuffer(6, Diff, INDICATOR_DATA);
  SetIndexBuffer(7, DiffC, INDICATOR_COLOR_INDEX);
  SetIndexBuffer(8, BOPAvg, INDICATOR_CALCULATIONS);
  SetIndexBuffer(9, BOP, INDICATOR_CALCULATIONS);

  //---
  IndicatorSetString(
      INDICATOR_SHORTNAME,
      "BOPAvgStd (" + (string)inpSmoothPeriod + ", " + (string)inpAvgPeriod +
          ", " + (string)inpStdPeriod + ", " + (string)inpStdMulti1 + ", " +
          (string)inpStdMulti2 + ", " + (string)inpStdMulti3 + ")");
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  // HiStdDev3 객체 메모리 해제
  if (stdDev3 != NULL) {
    delete stdDev3;
    stdDev3 = NULL;
  }
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[],
                const double &high[], const double &low[],
                const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[]) {
  if (Bars(_Symbol, _Period) < rates_total)
    return (-1);
  bool NewBarFlag = isNewBar(_Symbol);
  double standardDeviationL = 0;

  // [Bug Fix] 전체 재계산 시 버퍼 초기화 및 객체 상태 리셋
  if (prev_calculated > rates_total || prev_calculated <= 0) {
    ArrayInitialize(BOP, 0.0);
    ArrayInitialize(BOPAvg, 0.0);
    ArrayInitialize(Diff, 0.0);
    ArrayInitialize(DiffC, 0);
    ArrayInitialize(Up3, 0.0);
    ArrayInitialize(Up2, 0.0);
    ArrayInitialize(Up1, 0.0);
    ArrayInitialize(Down1, 0.0);
    ArrayInitialize(Down2, 0.0);
    ArrayInitialize(Down3, 0.0);
    if (CheckPointer(stdDev3) == POINTER_DYNAMIC)
      delete stdDev3;
    stdDev3 = new HiStdDev3(inpStdPeriod);
    if (CheckPointer(stdDev3) == POINTER_INVALID)
      Print("OnCalculate: HiStdDev3 재생성 실패");
  }

  //---
  int i = (int)MathMax(prev_calculated - 1, 0);
  for (; i < rates_total && !_StopFlag; i++) {
    //---
    double tempBuyRatio = CalculateBuyRatio(open, high, low, close, i);
    double tempSellRatio = CalculateSellRatio(open, high, low, close, i);
    double tempTotalPressure = MathAbs(tempBuyRatio) + MathAbs(tempSellRatio);

    // 0으로 나누기 방지
    if (tempTotalPressure == 0.0)
      tempTotalPressure = MIN_TOTAL_PRESSURE; // test Purpose

    // 비율을 퍼센트로 변환
    double BuyRatio = MathAbs(tempBuyRatio) / tempTotalPressure;
    double SellRatio = MathAbs(tempSellRatio) / tempTotalPressure;

    BOP[i] = iSmooth(BuyRatio - SellRatio, inpSmoothPeriod, 0, i, rates_total);
    BOPAvg[i] = myAverage(i, inpAvgPeriod, BOP);
    Diff[i] = BOP[i] - BOPAvg[i];
    DiffC[i] = (i > 0) ? (Diff[i] > Diff[i - 1])
                             ? 0
                             : (Diff[i] < Diff[i - 1]) ? 1 : Diff[i - 1]
                       : 0;

      standardDeviationL = stdDev3.Calculate(i, Diff[i]);
      Up3[i] = standardDeviationL * inpStdMulti3;
      Up2[i] = standardDeviationL * inpStdMulti2;

      Up1[i] = standardDeviationL * inpStdMulti1;

      Down1[i] = -standardDeviationL * inpStdMulti1;

      Down2[i] = -standardDeviationL * inpStdMulti2;
      Down3[i] = -standardDeviationL * inpStdMulti3;
  }

  return (i);
}
