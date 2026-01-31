//+------------------------------------------------------------------+
//|                                                        BSPLR.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 6
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_level1 0.

input int                 LRPeriod     = 20;          //LrPeriod
input int                 StdPeriod    = 5000;        //StdPeriod
input double              MultiFactorL1 = 1.0;         //MultiFactorL1
input double              MultiFactorL2 = 2.0;         //MultiFactorL2
input double              MultiFactorL3 = 3.0;         //MultiFactorL3  

double DiffPressure[], LRPressure[], Up1LRStd[], Up2LRStd[], Up3LRStd[],
       Down1LRStd[], Down2LRStd[], Down3LRStd[];

double ToPoint;       

//+------------------------------------------------------------------+  
void OnInit()
  {
   SetIndexBuffer(0,DiffPressure,INDICATOR_DATA);     
   SetIndexBuffer(1,LRPressure,INDICATOR_DATA);
   SetIndexBuffer(2,Up1LRStd,INDICATOR_DATA);
   SetIndexBuffer(3,Up2LRStd,INDICATOR_DATA);
   SetIndexBuffer(4,Up3LRStd,INDICATOR_DATA);
   SetIndexBuffer(5,Down1LRStd,INDICATOR_DATA);
   SetIndexBuffer(6,Down2LRStd,INDICATOR_DATA);
   SetIndexBuffer(7,Down3LRStd,INDICATOR_DATA);
   
  
   string short_name = "BSPLR("+ (string)LRPeriod + ", " + (string)StdPeriod + ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
 
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
     
//----
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
   bool MnewBar = isNewBar(_Symbol);
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2; 
      second  = first + LRPeriod;
      third = second + StdPeriod;
      // [Bug Fix] 전체 재계산 시 버퍼 초기화
      ArrayInitialize(DiffPressure,0.0);
      ArrayInitialize(LRPressure,0.0);
      ArrayInitialize(Up1LRStd,0.0);
      ArrayInitialize(Up2LRStd,0.0);
      ArrayInitialize(Up3LRStd,0.0);
      ArrayInitialize(Down1LRStd,0.0);
      ArrayInitialize(Down2LRStd,0.0);
      ArrayInitialize(Down3LRStd,0.0);
     }
   else
     { 
      first=prev_calculated-1;
      second = first; 
      third = second;
     } 


//---- The main loop of the indicator calculation
   for(int bar=first; bar<rates_total; bar++)
     {
        
       double tempBuyRatio, tempSellRatio, tempDiffPressure, standardDeviation;

       tempBuyRatio = close[bar]<open[bar] ?       (close[bar-1]<open[bar] ?               MathMax(high[bar]-close[bar-1], close[bar]-low[bar]) :
                               /* close[1]>=open */             MathMax(high[bar]-open[bar], close[bar]-low[bar])) : 
             (close[bar]>open[bar] ?       (close[bar-1]>open[bar] ?               high[bar]-low[bar] : 
                               /* close[1]>=open */             MathMax(open[bar]-close[bar-1], high[bar]-low[bar])) :           
             /*close == open*/   (high[bar]-close[bar]>close[bar]-low[bar] ?       
                                                               (close[bar-1]<open[bar] ?              MathMax(high[bar]-close[bar-1],close[bar]-low[bar]) : 
                                                               /*close[1]>=open */           high[bar]-open[bar]) : 
                                 (high[bar]-close[bar]<close[bar]-low[bar] ? 
                                                               (close[bar-1]>open[bar] ?              high[bar]-low[bar] : 
                                                                                             MathMax(open[bar]-close[bar-1], high[bar]-low[bar])) : 
                               /* high-close<=close-low */                             
                                                               (close[bar-1]>open[bar] ?              MathMax(high[bar]-open[bar], close[bar]-low[bar]) : 
                                                               (close[bar-1]<open[bar] ?              MathMax(open[bar]-close[bar-1], high[bar]-low[bar]) : 
                                                               /* close[1]==open */          high[bar]-low[bar])))))  ;  
                 
         tempSellRatio = close[bar]<open[bar] ?       (close[bar-1]>open[bar] ?              MathMax(close[bar-1]-open[bar], high[bar]-low[bar]):
                                                               high[bar]-low[bar]) : 
              (close[bar]>open[bar] ?      (close[bar-1]>open[bar] ?              MathMax(close[bar-1]-low[bar], high[bar]-close[bar]) :
                                                               MathMax(open[bar]-low[bar], high[bar]-close[bar])) : 
              /*close == open*/  (high[bar]-close[bar]>close[bar]-low[bar] ?   
                                                               (close[bar-1]>open[bar] ?               MathMax(close[bar-1]-open[bar], high[bar]-low[bar]) : 
                                                                                              high[bar]-low[bar]) : 
                                 (high[bar]-close[bar]<close[bar]-low[bar] ?      
                                                               (close[bar-1]>open[bar] ?               MathMax(close[bar-1]-low[bar], high[bar]-close[bar]) : 
                                                                                              open[bar]-low[bar]) : 
                                 /* high-close<=close-low */                              
                                                               (close[bar-1]>open[bar] ?               MathMax(close[bar-1]-open[bar], high[bar]-low[bar]) : 
                                                               (close[bar-1]<open[bar] ?               MathMax(open[bar]-low[bar], high[bar]-close[bar]) : 
                                                                                              high[bar]-low[bar])))))   ;
       

       tempTotalPressure=1.;
       tempBuyRatio = tempBuyRatio/tempTotalPressure;
       tempSellRatio = tempSellRatio/tempTotalPressure;
       tempDiffPressure = (MathAbs(tempBuyRatio) - MathAbs(tempSellRatio))*ToPoint;

       DiffPressure[bar] = DiffPressure[bar-1] + tempDiffPressure;


       if(bar>=second)
       {        
          LRPressure[bar] = LinearRegression(bar, LRPeriod, DiffPressure);  
       }  

       if(bar>=third)
       {
          standardDeviation = StdDev3((bar-1), StdPeriod, LRPressure);

          Up1LRStd[bar]   =   standardDeviation * MultiFactorL1;
          Down1LRStd[bar] =  -standardDeviation * MultiFactorL1;

          Up2LRStd[bar]   =   standardDeviation * MultiFactorL2;
          Down2LRStd[bar] =  -standardDeviation * MultiFactorL2;

          Up3LRStd[bar]   =   standardDeviation * MultiFactorL3;
          Down3LRStd[bar] =  -standardDeviation * MultiFactorL3;
       }  

   }
     
   return(rates_total);
  }
//+----------------------


double LinearRegression(int end, int period, const double &close[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=end+1-period;i<=end;i++)
         {
          sumX+=X;
          sumY+=close[i];
          sumXY+=X*close[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-period*sumXY)/(MathPow(sumX,2)-period*sumX2);
       b=(sumY-a*sumX)/period;


      return(a);
}

double StdDev3(int end, int SDPeriod, const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
    {
      dAmount+=(S_Array[i])*(S_Array[i]);
    }       

    StdValue = MathSqrt(dAmount/SDPeriod);
    return(StdValue);
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

