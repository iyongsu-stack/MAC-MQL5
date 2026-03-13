//+------------------------------------------------------------------+
//|                                                   BOPAvgStd.mq5  |
//|                                              © mladen, 2018      |
//| AIEngine clean version — file writing logic removed              |
//+------------------------------------------------------------------+
#property copyright "© mladen, 2018"
#property link "mladenfx@gmail.com"
#property version "1.00"
#property indicator_separate_window

#property indicator_buffers 11
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

#include <mySmoothingAlgorithm.mqh>
#include <myBSPCalculation.mqh>
#include <myFunction.mqh>

input int inpSmoothPeriod = 50;
input int inpAvgPeriod = 50;
input int inpStdPeriod = 5000;
input double inpStdMulti1 = 1.0;
input double inpStdMulti2 = 2.0;
input double inpStdMulti3 = 3.0;

input group "Time Filter"
input int StdCalcStartTimeHour = 1;
input int StdCalcStartTimeMinute = 30;
input int StdCalcEndTimeHour = 23;
input int StdCalcEndTimeMinute = 30;

double BOP[], BOPAvg[], Diff[], DiffC[], Up3[], Up2[], Up1[], Down1[], Down2[],
    Down3[], Scale[];

HiStdDev3 *stdDev3 = NULL;

void OnInit() {
  if (_Symbol != "XAUUSD" || _Period != PERIOD_M1) {
     Alert("Error: Symbol must be XAUUSD and Period must be M1");
     return;
  }

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
  ArrayInitialize(Scale, 0.0);

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
  SetIndexBuffer(10, Scale, INDICATOR_CALCULATIONS);

  IndicatorSetString(
      INDICATOR_SHORTNAME,
      "BOPAvgStd (" + (string)inpSmoothPeriod + ", " + (string)inpAvgPeriod +
          ", " + (string)inpStdPeriod + ", " + (string)inpStdMulti1 + ", " +
          (string)inpStdMulti2 + ", " + (string)inpStdMulti3 + ")");
}

void OnDeinit(const int reason) {
  if (stdDev3 != NULL) {
    delete stdDev3;
    stdDev3 = NULL;
  }
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
  if (Bars(_Symbol, _Period) < rates_total)
    return (-1);
  bool NewBarFlag = isNewBar(_Symbol);
  double standardDeviationL = 0;

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
    ArrayInitialize(Scale, 0.0);
    if (CheckPointer(stdDev3) == POINTER_DYNAMIC)
      delete stdDev3;
    stdDev3 = new HiStdDev3(inpStdPeriod);
    if (CheckPointer(stdDev3) == POINTER_INVALID)
      Print("OnCalculate: HiStdDev3 recreation failed");
  }

  int i = (int)MathMax(prev_calculated - 1, 0);
  for (; i < rates_total && !_StopFlag; i++) {
    double BullsRewardDaily = CalculateBullsReward(open, high, low, close, i);
    double BearsRewardDaily = CalculateBearsReward(open, high, low, close, i);

    BOP[i] = iSmooth(BullsRewardDaily - BearsRewardDaily, inpSmoothPeriod, 0, i,rates_total);
    BOPAvg[i] = myAverage(i, inpAvgPeriod, BOP);
    Diff[i] = BOP[i] - BOPAvg[i];
    DiffC[i] = (i > 0) ? (Diff[i] > Diff[i - 1]) ? 0 : (Diff[i] < Diff[i - 1]) ? 1 : Diff[i - 1] : 0;

    bool isCalcTime = IsStdCalculationTime(time[i]);
    if (isCalcTime) {
      standardDeviationL = stdDev3.Calculate(i, Diff[i]);
      Up3[i] = standardDeviationL * inpStdMulti3;
      Up2[i] = standardDeviationL * inpStdMulti2;
      Up1[i] = standardDeviationL * inpStdMulti1;
      Down1[i] = -standardDeviationL * inpStdMulti1;
      Down2[i] = -standardDeviationL * inpStdMulti2;
      Down3[i] = -standardDeviationL * inpStdMulti3;

      if(standardDeviationL != 0) Scale[i] = Diff[i] / standardDeviationL;
      else Scale[i] = (i > 0) ? Scale[i-1] : 0.0;
    } else {
       if (i > 0) {
          Up3[i] = Up3[i-1];
          Up2[i] = Up2[i-1];
          Up1[i] = Up1[i-1];
          Down1[i] = Down1[i-1];
          Down2[i] = Down2[i-1];
          Down3[i] = Down3[i-1];
          Scale[i] = Scale[i-1];
        } else {
          Up3[i] = 0.0; Up2[i] = 0.0; Up1[i] = 0.0;
          Down1[i] = 0.0; Down2[i] = 0.0; Down3[i] = 0.0;
          Scale[i] = 0.0;
       }
    }
  }

  return (i);
}
//+------------------------------------------------------------------+
