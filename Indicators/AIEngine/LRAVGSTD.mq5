//+------------------------------------------------------------------+
//|                                                     LRAVGSTD.mq5 |
//|                                                     Yong-su, Kim |
//| AIEngine clean version — file writing logic removed              |
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
ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;

input int                 LwmaPeriod    = 25;
input int                 AvgPeriod    = 60;
input int                 StdPeriodL    = 5000;
input int                 StdPeriodS    = 2;

input double              MultiFactorL1  = 1.;
input double              MultiFactorL2  = 2.0;
input double              MultiFactorL3  = 3.0;

input group "Time Filter"
input int StdCalcStartTimeHour = 1;
input int StdCalcStartTimeMinute = 30;
input int StdCalcEndTimeHour = 23;
input int StdCalcEndTimeMinute = 30;

input double              MaxBSPMult     = 20.0;

double DiffPressure[], LWMAVal[],
       avgValLR[], stdS[], stdSC[], 
       up1StdAvgValLR[], up2StdAvgValLR[], up3StdAvgValLR[],
       down1StdAvgValLR[], down2StdAvgValLR[], down3StdAvgValLR[], BSPScale[];

double ToPoint;    

HiStdDev1 *iStdDev1;
HiStdDev2 *iStdDev2;

void OnInit()
  {
   for(int p=0; p<7; p++) PlotIndexSetDouble(p,PLOT_EMPTY_VALUE,EMPTY_VALUE);

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
           ToPoint *= 10.0;
     }
   else
     {
       ToPoint = 1.0;
       Print("Warning: Symbol ", _Symbol, " has a point size of 0. ToPoint set to 1.");
     }

   iStdDev1 = new HiStdDev1((StdPeriodL > 1) ? StdPeriodL : 2);
   if(CheckPointer(iStdDev1) == POINTER_INVALID) Print("HiStdDev1 creation failed!");

   iStdDev2 = new HiStdDev2((StdPeriodS > 1) ? StdPeriodS : 2);
   if(CheckPointer(iStdDev2) == POINTER_INVALID) Print("HiStdDev2 creation failed!");
  }
  
void OnDeinit(const int reason)
  {
   if(CheckPointer(iStdDev1) == POINTER_DYNAMIC) delete iStdDev1;
   if(CheckPointer(iStdDev2) == POINTER_DYNAMIC) delete iStdDev2;
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double& high[],
                const double& low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   const int lwmaPeriod = (LwmaPeriod>1) ? LwmaPeriod : 2;
   const int avgPeriod = (AvgPeriod>1) ? AvgPeriod : 2;
   const int stdPeriodL = (StdPeriodL>1) ? StdPeriodL : 2;
   const int stdPeriodS = (StdPeriodS>1) ? StdPeriodS : 2;

   int first;
   double mVolume, standardDeviationL;

   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      first = 2;  
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
     
      if(CheckPointer(iStdDev1) == POINTER_DYNAMIC) delete iStdDev1;
      if(CheckPointer(iStdDev2) == POINTER_DYNAMIC) delete iStdDev2;
      
      iStdDev1 = new HiStdDev1(stdPeriodL);
      if(CheckPointer(iStdDev1) == POINTER_INVALID) Print("OnCalculate: HiStdDev1 recreation failed");
      
      iStdDev2 = new HiStdDev2(stdPeriodS);
      if(CheckPointer(iStdDev2) == POINTER_INVALID) Print("OnCalculate: HiStdDev2 recreation failed");
      
      _lwma.init(lwmaPeriod);
     }
   else
     { 
      first = prev_calculated - 1; 
     } 

   for(int bar = first; bar < rates_total; bar++)
     {
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
      if (isCalcTime)
        {         
         standardDeviationL = iStdDev1.Calculate(bar, avgValLR[bar], LWMAVal[bar]);
         up1StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL1;
         down1StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL1;
         up2StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL2;
         down2StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL2;
         up3StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL3;
         down3StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL3;

         if(standardDeviationL != 0) BSPScale[bar] = stdS[bar] / standardDeviationL;
         else BSPScale[bar] = (bar > 0) ? BSPScale[bar-1] : 0.0;
        }
      else
        {
         up1StdAvgValLR[bar]   =   up1StdAvgValLR[bar-1];
         down1StdAvgValLR[bar] =  down1StdAvgValLR[bar-1];
         up2StdAvgValLR[bar]   =   up2StdAvgValLR[bar-1];
         down2StdAvgValLR[bar] =  down2StdAvgValLR[bar-1];
         up3StdAvgValLR[bar]   =   up3StdAvgValLR[bar-1];
         down3StdAvgValLR[bar] =  down3StdAvgValLR[bar-1];
         if(bar > 0) BSPScale[bar] = BSPScale[bar-1];
        }         
     }  

   return(rates_total);
  }
//+------------------------------------------------------------------+
