//+------------------------------------------------------------------+
//|                                                       BSPBSP2.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 10
#property indicator_plots   8

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_LINE
#property indicator_type8   DRAW_COLOR_HISTOGRAM

#property indicator_color1  clrWhite
#property indicator_color2  clrYellow
#property indicator_color3  clrYellow
#property indicator_color4  clrYellow
#property indicator_color5  clrYellow
#property indicator_color6  clrYellow
#property indicator_color7  clrYellow
#property indicator_color8  clrGreen,clrRed

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_DOT
#property indicator_style3  STYLE_DASH
#property indicator_style4  STYLE_SOLID
#property indicator_style5  STYLE_SOLID
#property indicator_style6  STYLE_DASH
#property indicator_style7  STYLE_DOT
#property indicator_style8  STYLE_SOLID

#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
#property indicator_width8  1

#include <mySmoothingAlgorithm.mqh>
#include <myBSPCalculation.mqh>

HiStdDev3 stdDev3;


input int                 WmaBSP        = 30;            // WmaBSP
input int                 StdPeriodL    = 5000;        // StdPeriodL

input double              MultiFactorL1  = 1.0;         // StdMultiFactorL1
input double              MultiFactorL2  = 2.0;         // StdMultiFactorL2
input double              MultiFactorL3  = 3.0;         // StdMultiFactorL3

ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


double DiffPressure[], StdS[], 
       up1StdL[], up2StdL[], up3StdL[],
       Down1StdL[], Down2StdL[], Down3StdL[], 
       DiffBSP[], DiffBSPC[];
       
double ToPoint;       


//+------------------------------------------------------------------+  
void OnInit()
  {

   ArrayInitialize(DiffPressure,0.0);
   ArrayInitialize(DiffBSP,0.0);
   ArrayInitialize(DiffBSPC,0);
   ArrayInitialize(StdS,0.0);
   ArrayInitialize(up1StdL,0.0);
   ArrayInitialize(up2StdL,0.0);
   ArrayInitialize(up3StdL,0.0);
   ArrayInitialize(Down1StdL,0.0);
   ArrayInitialize(Down2StdL,0.0);
   ArrayInitialize(Down3StdL,0.0);  

   SetIndexBuffer(0, StdS,INDICATOR_DATA);
   SetIndexBuffer(1, up3StdL,INDICATOR_DATA);
   SetIndexBuffer(2, up2StdL,INDICATOR_DATA);
   SetIndexBuffer(3, up1StdL,INDICATOR_DATA);
   SetIndexBuffer(4, Down1StdL,INDICATOR_DATA);
   SetIndexBuffer(5, Down2StdL,INDICATOR_DATA);
   SetIndexBuffer(6, Down3StdL,INDICATOR_DATA);
   SetIndexBuffer(7, DiffBSP,INDICATOR_DATA);
   SetIndexBuffer(8, DiffBSPC,INDICATOR_COLOR_INDEX);   
   SetIndexBuffer(9, DiffPressure,INDICATOR_CALCULATIONS);
     

   string short_name = "BSPstd("+ (string)WmaBSP + ", "  + (string)StdPeriodL + ", " +(string)MultiFactorL1 + ", " 
                                +(string)MultiFactorL2 +", " +(string)MultiFactorL3 +  ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
    
//----

  // [Code Improvement] 포인트 계산 로직을 모든 상품에 범용적으로 적용 가능하도록 개선
  if(_Point > 0)
    {
      ToPoint = 1.0 / _Point;
      ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
      bool isGold = (StringFind(_Symbol, "XAU") != -1) || (StringFind(_Symbol, "GOLD") != -1);
      if (calcMode == SYMBOL_TRADE_CALC_MODE_FOREX && _Digits % 2 == 0 && !isGold)
          ToPoint *= 10.0;
    }
  else
    {
      ToPoint = 1.0;
      Print("Warning: Symbol ", _Symbol, " has a point size of 0. ToPoint set to 1.");
    }
  }
  
  void OnDeinit(const int reason)
  {
     if(CheckPointer(stdDev3) == POINTER_DYNAMIC)
        delete stdDev3;
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

   int first, second, third;
   double mVolume, standardDeviation;
   bool MnewBar = isNewBar(_Symbol);

   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;  
      second = first + WmaBSP;
      third = first + StdPeriodL;
      // [Bug Fix] 전체 재계산 시 버퍼 초기화
      ArrayInitialize(DiffPressure,0.0);
      ArrayInitialize(StdS,0.0);
      ArrayInitialize(up1StdL,0.0);
      ArrayInitialize(up2StdL,0.0);
      ArrayInitialize(up3StdL,0.0);
      ArrayInitialize(Down1StdL,0.0);
      ArrayInitialize(Down2StdL,0.0);
      ArrayInitialize(Down3StdL,0.0);
      ArrayInitialize(DiffBSP,0.0);
      ArrayInitialize(DiffBSPC,0);

      if(CheckPointer(stdDev3) == POINTER_DYNAMIC) delete stdDev3;
      stdDev3 = new HiStdDev3(StdPeriodL);
      if(CheckPointer(stdDev3) == POINTER_INVALID) Print("OnCalculate: HiStdDev3 재생성 실패");
     }
   else
     { 
      first=prev_calculated-1; 
      second = first;
      third = first;
     } 


//---- The main loop of the indicator calculation
   for(int bar=first; bar<rates_total; bar++)
     {
        
       if(VolumeType == VOLUME_TICK) mVolume = (double)tick_volume[bar];
       else mVolume = (double)volume[bar];


       double tempBuyRatio = CalculateBuyRatio(open, high, low, close, bar);
       double tempSellRatio = CalculateSellRatio(open, high, low, close, bar);
  
       
       DiffPressure[bar] =( MathAbs(tempBuyRatio) + MathAbs(tempSellRatio) ) * ToPoint;

       DiffBSP[bar]=( MathAbs(tempBuyRatio) - MathAbs(tempSellRatio) ) * ToPoint;
       if(DiffBSP[bar]>= 0.) DiffBSPC[bar] = 0;
       else DiffBSPC[bar]= 1;
       

       if(bar>=second)   StdS[bar] = iWma(bar, WmaBSP, DiffPressure);

       if(bar>=third)
        {
         standardDeviation = stdDev3.Calculate(bar, DiffPressure[bar]);
      
         up1StdL[bar] = standardDeviation * MultiFactorL1;      
         up2StdL[bar] = standardDeviation * MultiFactorL2;     
         up3StdL[bar] = standardDeviation * MultiFactorL3;
         Down1StdL[bar] = -standardDeviation * MultiFactorL1;      
         Down2StdL[bar] = -standardDeviation * MultiFactorL2;     
         Down3StdL[bar] = -standardDeviation * MultiFactorL3;       
        }
       
        
  
     }  

     
     
   return(rates_total);
  }
//+----------------------


double StdDev(int end, int SDPeriod, const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
    {
      dAmount+=(S_Array[i])*(S_Array[i]);
    }       

    StdValue = MathSqrt(dAmount/SDPeriod);
    return(StdValue);
}  


double iWma(int end, int wmaPeriod, const double &S_Array[])
{

   double Sum = 0., Weight=0., Norm=0., wma=0.;
   
   for(int i=0;i<wmaPeriod;i++)
   { 
      Weight = (wmaPeriod-i)*wmaPeriod;
      Norm += Weight; 
      Sum += S_Array[end-i]*Weight;
   }
   if(Norm>0) wma = Sum/Norm;
   else wma = 0; 
   
   return(wma);
}


bool isNewBar(string sym)
{
   static datetime dtBarCurrent=WRONG_VALUE;
   datetime dtBarPrevious=dtBarCurrent;
   dtBarCurrent=(datetime) SeriesInfoInteger(sym,Period(),SERIES_LASTBAR_DATE);
   bool NewBarFlag=(dtBarCurrent!=dtBarPrevious);
   if(NewBarFlag)
      return(true);
   else
      return (false);

   return (false);
}
//git test