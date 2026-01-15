//+------------------------------------------------------------------+
//|                                                       BSPBSP2.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.01"

#include <mySmoothingAlgorithm.mqh>
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

//+------------------------------------------------------------------+  
void OnInit()
  {

   ArrayInitialize(BuyRatio,0.0);
   ArrayInitialize(SellRatio,0.0);
   ArrayInitialize(AvgBuyRatio,0.0);
   ArrayInitialize(AvgSellRatio,0.0);
   ArrayInitialize(DiffRatio,0.0);
   ArrayInitialize(SmoothDiffRatio,0.0);
   ArrayInitialize(SmoothDiffRatioC,0);
   ArrayInitialize(DiffRatio,0.0);
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

   string short_name = "BSPercentAvgStd("+ (string)AvgPeriod + ", "  + (string)SmoothPeriod +", "  + (string)StdPeriod + ", " + 
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
   int first, second, third, fourth;
   double mVolume, standardDeviation;
   bool MnewBar = isNewBar(_Symbol);

   // 첫 계산인지 확인
   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      first = 2;  
      second = first + AvgPeriod;
      third = second + SmoothPeriod;
      fourth = third + StdPeriod;
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
      // 인덱스 검증
      if(bar <= 0) continue;
        
      if(VolumeType == VOLUME_TICK) mVolume = (double)tick_volume[bar];
      else mVolume = (double)volume[bar];

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
         AvgBuyRatio[bar] = iAverage(bar, AvgPeriod, BuyRatio);
         AvgSellRatio[bar] = iAverage(bar, AvgPeriod, SellRatio);
         DiffRatio[bar] = AvgBuyRatio[bar] - AvgSellRatio[bar];
      }

      if(bar >= third) 
      {
         SmoothDiffRatio[bar] = iSmooth(DiffRatio[bar],SmoothPeriod,0,bar,rates_total);
         
         if(SmoothDiffRatio[bar] > SmoothDiffRatio[bar-1] )
            SmoothDiffRatioC[bar] = 0;
         else if(SmoothDiffRatio[bar] < SmoothDiffRatio[bar-1])
            SmoothDiffRatioC[bar] = 1;
         else
            SmoothDiffRatioC[bar] = SmoothDiffRatioC[bar-1];
      } else {
         SmoothDiffRatioC[bar] = 0;
      }

      // 표준편차 계산 (새로운 바가 형성되었을 때만)
      if(bar >= fourth && MnewBar && bar > 0)
      {
         standardDeviation = StdDev3(bar - 1, StdPeriod, SmoothDiffRatio);

         up1StdDiffBSP[bar]   = standardDeviation * MultiFactor1;
         down1StdDiffBSP[bar] = -standardDeviation * MultiFactor1;

         up2StdDiffBSP[bar]   = standardDeviation * MultiFactor2;
         down2StdDiffBSP[bar] = -standardDeviation * MultiFactor2;

         up3StdDiffBSP[bar]   = standardDeviation * MultiFactor3;
         down3StdDiffBSP[bar] = -standardDeviation * MultiFactor3;
      }  
     }  

   return(rates_total);
  }
