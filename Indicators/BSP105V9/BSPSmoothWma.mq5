//+------------------------------------------------------------------+
//|                                                 BSPSmoothWma.mq5 |
//|                                         Copyright 2025, YourName |
//|                                                 https://mql5.com |
//| 13.10.2025 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, YourName"
#property link      "https://mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 7
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGreen,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2


ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int inpSmoothPeriod = 40;      // inpSmoothPeriod
input int inpWmaPeriod = 30;          // inpwmaPeriod

double SumBuyRatio[], SumSellRatio[], SmoothBuyRatio[], SmoothSellRatio[], 
       DiffRatio[], WmaDiffRatio[], WmaDiffRatioC1[];

double ToPoint;       

//+------------------------------------------------------------------+  
void OnInit()
  {

   ArrayInitialize(SumBuyRatio,0.0);
   ArrayInitialize(SumSellRatio,0.0);
   ArrayInitialize(SmoothBuyRatio,0.0);
   ArrayInitialize(SmoothSellRatio,0.0);  
   ArrayInitialize(WmaDiffRatio,0.0); 
   ArrayInitialize(DiffRatio,0.0);
   ArrayInitialize(WmaDiffRatioC1,0); 


   SetIndexBuffer(0,WmaDiffRatio,INDICATOR_DATA);
   SetIndexBuffer(1,WmaDiffRatioC1,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,DiffRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,SumBuyRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SumSellRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,SmoothBuyRatio,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,SmoothSellRatio,INDICATOR_CALCULATIONS);

   string short_name = "BSPSmoothWma("+ (string)inpSmoothPeriod +", "+ (string)inpWmaPeriod + ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
 
   // [Code Improvement] 포인트 계산 로직을 모든 상품에 범용적으로 적용 가능하도록 개선
   if(_Point > 0)
     {
       ToPoint = 1.0 / _Point;
       ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
       if (calcMode == SYMBOL_TRADE_CALC_MODE_FOREX && _Digits % 2 == 0)
           ToPoint *= 10.0;
     }
   else
     {
       ToPoint = 1.0;
       Print("Warning: Symbol ", _Symbol, " has a point size of 0. ToPoint set to 1.");
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

   double mVolume; 

   // [Bug Fix] 전체 재계산 시 버퍼 초기화
   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      ArrayInitialize(SumBuyRatio,0.0);
      ArrayInitialize(SumSellRatio,0.0);
      ArrayInitialize(SmoothBuyRatio,0.0);
      ArrayInitialize(SmoothSellRatio,0.0);
      ArrayInitialize(DiffRatio,0.0);
      ArrayInitialize(WmaDiffRatio,0.0);
      ArrayInitialize(WmaDiffRatioC1,0);
     }

//---- The main loop of the indicator calculation

   int bar=(int)MathMax(prev_calculated-1,1); for(; bar<rates_total && !_StopFlag; bar++)
     {
        
       if(VolumeType == VOLUME_TICK) mVolume = (double)tick_volume[bar];
       else mVolume = (double)volume[bar];


       double tempBuyRatio, tempSellRatio ;

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
       


      tempBuyRatio = MathAbs(tempBuyRatio);
      tempSellRatio = MathAbs(tempSellRatio);

      SumBuyRatio[bar] = SumBuyRatio[bar-1] + tempBuyRatio;
      SumSellRatio[bar] = SumSellRatio[bar-1] + tempSellRatio;

      SmoothBuyRatio[bar] = iSmooth(SumBuyRatio[bar], inpSmoothPeriod, 0, bar, rates_total);
      SmoothSellRatio[bar] = iSmooth(SumSellRatio[bar], inpSmoothPeriod, 0, bar, rates_total);

      DiffRatio[bar] = SmoothBuyRatio[bar] - SmoothSellRatio[bar];

      WmaDiffRatio[bar] = iWma(bar,inpWmaPeriod, DiffRatio);
      WmaDiffRatioC1[bar] = (bar>0) ? (WmaDiffRatio[bar]>=WmaDiffRatio[bar-1]) ? 0 : 
                                          (WmaDiffRatio[bar]<WmaDiffRatio[bar-1]) ? 1 : WmaDiffRatio[bar-1] : 0;
     } 

   return(rates_total);

  }
//+----------------------


//+------------------------------------------------------------------+

double iWma(int end, int wmaPeriod, const double &S_Array[])
{

   double Sum = 0., Weight=0., Norm=0., wma=0.;
   
   for(int i=0;i<wmaPeriod;i++)
   { 
      if(end-i<0) break;    
      Weight = (wmaPeriod-i)*wmaPeriod;
      Norm += Weight; 
      Sum += S_Array[end-i]*Weight;
   }
   if(Norm>0) wma = Sum/Norm;
   else wma = 0.; 
   
   return(wma);
}

//
#define _smoothInstances     2
#define _smoothInstancesSize 10
double m_wrk[][_smoothInstances*_smoothInstancesSize];
//
//---
//
double iSmooth(double price,double length,double phase,int r,int bars,int instanceNo=0)
  {
   #define bsmax  5
   #define bsmin  6
   #define volty  7
   #define vsum   8
   #define avolty 9

   if(ArrayRange(m_wrk,0)!=bars) ArrayResize(m_wrk,bars); if(ArrayRange(m_wrk,0)!=bars) return(price); instanceNo*=_smoothInstancesSize;
   if(r==0 || length<=1) { int k=0; for(; k<7; k++) m_wrk[r][instanceNo+k]=price; for(; k<10; k++) m_wrk[r][instanceNo+k]=0; return(price); }

//
//---
//

   double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
   double pow1   = MathMax(len1-2.0,0.5);
   double del1   = price - m_wrk[r-1][instanceNo+bsmax];
   double del2   = price - m_wrk[r-1][instanceNo+bsmin];
   int    forBar = MathMin(r,10);

   m_wrk[r][instanceNo+volty]=0;
   if(MathAbs(del1) > MathAbs(del2)) m_wrk[r][instanceNo+volty] = MathAbs(del1);
   if(MathAbs(del1) < MathAbs(del2)) m_wrk[r][instanceNo+volty] = MathAbs(del2);
   m_wrk[r][instanceNo+vsum]=m_wrk[r-1][instanceNo+vsum]+(m_wrk[r][instanceNo+volty]-m_wrk[r-forBar][instanceNo+volty])*0.1;

//
//---
//

   m_wrk[r][instanceNo+avolty]=m_wrk[r-1][instanceNo+avolty]+(2.0/(MathMax(4.0*length,30)+1.0))*(m_wrk[r][instanceNo+vsum]-m_wrk[r-1][instanceNo+avolty]);
   double dVolty=(m_wrk[r][instanceNo+avolty]>0) ? m_wrk[r][instanceNo+volty]/m_wrk[r][instanceNo+avolty]: 0;
   if(dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
   if(dVolty < 1)                      dVolty = 1.0;

//
//---
//

   double pow2 = MathPow(dVolty, pow1);
   double len2 = MathSqrt(0.5*(length-1))*len1;
   double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

   if(del1 > 0) m_wrk[r][instanceNo+bsmax] = price; else m_wrk[r][instanceNo+bsmax] = price - Kv*del1;
   if(del2 < 0) m_wrk[r][instanceNo+bsmin] = price; else m_wrk[r][instanceNo+bsmin] = price - Kv*del2;

//
//---
//

   double corr  = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
   double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
   double alpha = MathPow(beta,pow2);

   m_wrk[r][instanceNo+0] = price + alpha*(m_wrk[r-1][instanceNo+0]-price);
   m_wrk[r][instanceNo+1] = (price - m_wrk[r][instanceNo+0])*(1-beta) + beta*m_wrk[r-1][instanceNo+1];
   m_wrk[r][instanceNo+2] = (m_wrk[r][instanceNo+0] + corr*m_wrk[r][instanceNo+1]);
   m_wrk[r][instanceNo+3] = (m_wrk[r][instanceNo+2] - m_wrk[r-1][instanceNo+4])*MathPow((1-alpha),2) + MathPow(alpha,2)*m_wrk[r-1][instanceNo+3];
   m_wrk[r][instanceNo+4] = (m_wrk[r-1][instanceNo+4] + m_wrk[r][instanceNo+3]);

//
//---
//

   return(m_wrk[r][instanceNo+4]);

   #undef bsmax
   #undef bsmin
   #undef volty
   #undef vsum
   #undef avolty
  }    
//+------------------------------------------------------------------+
