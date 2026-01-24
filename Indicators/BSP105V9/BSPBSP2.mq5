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


input int                 WmaBSP        = 30;            // WmaBSP
input int                 StdPeriodL    = 5000;        // StdPeriodL

input double              MultiFactorL1  = 1.0;         // StdMultiFactorL1
input double              MultiFactorL2  = 2.0;         // StdMultiFactorL2
input double              MultiFactorL3  = 3.0;         // StdMultiFactorL3
input double              BSPCutOff      = 7.0;         // MaxBspCutOff


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
                                +(string)MultiFactorL2 +", " +(string)MultiFactorL3 +", " + (string)BSPCutOff +  ")";      
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


       double tempBuyRatio, tempSellRatio, tempTotalPressure ;
       
       // tempBuyRatio 계산 - 현재 캔들과 이전 캔들의 상태를 기반으로 계산
       bool isCurrentBearish = (close[bar] < open[bar]);  // 현재 캔들이 약세(음봉)
       bool isCurrentBullish = (close[bar] > open[bar]);  // 현재 캔들이 강세(양봉)
       bool isCurrentDoji = (close[bar] == open[bar]);    // 현재 캔들이 도지(종가==시가)
       bool isPrevBearish = (close[bar-1] < open[bar-1]); // 이전 캔들이 약세
       bool isPrevBullish = (close[bar-1] > open[bar-1]); // 이전 캔들이 강세
       bool isPrevDoji = (close[bar-1] == open[bar-1]);   // 이전 캔들이 도지
       
       double highClose = high[bar] - close[bar];  // 상단 여백
       double closeLow = close[bar] - low[bar];    // 하단 여백
       double range = high[bar] - low[bar];        // 캔들 범위
       
       // tempBuyRatio 계산
       if (isCurrentBearish)
       {
          // 현재 캔들이 약세인 경우
          if (isPrevBearish)
             tempBuyRatio = MathMax(high[bar] - close[bar-1], close[bar] - low[bar]);
          else
             tempBuyRatio = MathMax(high[bar] - open[bar], close[bar] - low[bar]);
       }
       else if (isCurrentBullish)
       {
          // 현재 캔들이 강세인 경우
          if (isPrevBullish)
             tempBuyRatio = range;
          else
             tempBuyRatio = MathMax(open[bar] - close[bar-1], range);
       }
       else // isCurrentDoji
       {
          // 현재 캔들이 도지인 경우
          if (highClose > closeLow)
          {
             // 상단 여백이 하단 여백보다 큰 경우
             if (isPrevBearish)
                tempBuyRatio = MathMax(high[bar] - close[bar-1], close[bar] - low[bar]);
             else
                tempBuyRatio = high[bar] - open[bar];
          }
          else if (highClose < closeLow)
          {
             // 하단 여백이 상단 여백보다 큰 경우
             if (isPrevBullish)
                tempBuyRatio = range;
             else
                tempBuyRatio = MathMax(open[bar] - close[bar-1], range);
          }
          else // highClose == closeLow
          {
             // 상단 여백과 하단 여백이 같은 경우
             if (isPrevBullish)
                tempBuyRatio = MathMax(high[bar] - open[bar], close[bar] - low[bar]);
             else if (isPrevBearish)
                tempBuyRatio = MathMax(open[bar] - close[bar-1], range);
             else // isPrevDoji
                tempBuyRatio = range;
          }
       }
       
       // tempSellRatio 계산
       if (isCurrentBearish)
       {
          // 현재 캔들이 약세인 경우
          if (isPrevBullish)
             tempSellRatio = MathMax(close[bar-1] - open[bar], range);
          else
             tempSellRatio = range;
       }
       else if (isCurrentBullish)
       {
          // 현재 캔들이 강세인 경우
          if (isPrevBullish)
             tempSellRatio = MathMax(close[bar-1] - low[bar], high[bar] - close[bar]);
          else
             tempSellRatio = MathMax(open[bar] - low[bar], high[bar] - close[bar]);
       }
       else // isCurrentDoji
       {
          // 현재 캔들이 도지인 경우
          if (highClose > closeLow)
          {
             // 상단 여백이 하단 여백보다 큰 경우
             if (isPrevBullish)
                tempSellRatio = MathMax(close[bar-1] - open[bar], range);
             else
                tempSellRatio = range;
          }
          else if (highClose < closeLow)
          {
             // 하단 여백이 상단 여백보다 큰 경우
             if (isPrevBullish)
                tempSellRatio = MathMax(close[bar-1] - low[bar], high[bar] - close[bar]);
             else
                tempSellRatio = open[bar] - low[bar];
          }
          else // highClose == closeLow
          {
             // 상단 여백과 하단 여백이 같은 경우
             if (isPrevBullish)
                tempSellRatio = MathMax(close[bar-1] - open[bar], range);
             else if (isPrevBearish)
                tempSellRatio = MathMax(open[bar] - low[bar], high[bar] - close[bar]);
             else // isPrevDoji
                tempSellRatio = range;
          }
       }

       tempTotalPressure=1.;
       tempBuyRatio = tempBuyRatio/tempTotalPressure;
       tempSellRatio = tempSellRatio/tempTotalPressure;
       
       DiffPressure[bar] =( MathAbs(tempBuyRatio) + MathAbs(tempSellRatio) ) * ToPoint;

       DiffBSP[bar]=( MathAbs(tempBuyRatio) - MathAbs(tempSellRatio) ) * ToPoint;
       if(DiffBSP[bar]>= 0.) DiffBSPC[bar] = 0;
       else DiffBSPC[bar]= 1;
       

       if(bar>=second)   StdS[bar] = iWma(bar, WmaBSP, DiffPressure);

       if(bar>=third && MnewBar)
        {
         standardDeviation = StdDev(bar, StdPeriodL, DiffPressure);
      
         if(DiffPressure[bar] > standardDeviation*BSPCutOff) 
          {
            DiffPressure[bar] = standardDeviation*BSPCutOff; 
            standardDeviation = StdDev(bar, StdPeriodL, DiffPressure);
          }         

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