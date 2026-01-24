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
 
   _lwma.init(LwmaPeriod);

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

   iStdDev1 = new HiStdDev1(StdPeriodL);
   if(CheckPointer(iStdDev1) == POINTER_INVALID)   Print("HiStdDev1 객체 생성 실패!");

   iStdDev2 = new HiStdDev2(StdPeriodS);
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