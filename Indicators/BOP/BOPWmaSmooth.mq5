//+------------------------------------------------------------------+
//|                                                 BOPWmaSmooth.mq5 |
//|                                         Copyright 2025, YourName |
//|                                                 https://mql5.com |
//| 18.10.2025 - Initial release                                     |
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


//-------------------
input int           inpWmaPeriod = 60;          //inpWmaPeriod
input int           inpSmoothPeriod = 10;       //inpSmoothPeriod

double  SumBulls[], SumBears[], WmaBulls[], WmaBears[], BOP[], SmoothBOP[], SmoothBOPC[];

void OnInit()
  {

   ArrayInitialize(SumBulls,0.0);
   ArrayInitialize(SumBears,0.0);
   ArrayInitialize(WmaBulls,0.0);
   ArrayInitialize(WmaBears,0.0);
   ArrayInitialize(BOP,0.0);
   ArrayInitialize(SmoothBOP,0.0);
   ArrayInitialize(SmoothBOPC,0.0);    

   //--- indicator buffers mapping 
   SetIndexBuffer(0,SmoothBOP,INDICATOR_DATA);
   SetIndexBuffer(1,SmoothBOPC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,BOP,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,SumBulls,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SumBears,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,WmaBulls,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,WmaBears,INDICATOR_CALCULATIONS);

   IndicatorSetString(INDICATOR_SHORTNAME,"BOPWmaSmooth ("+(string)inpWmaPeriod+", "+(string)inpSmoothPeriod+")");
  }
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//   if(Bars(_Symbol,_Period)<rates_total) return(-1);

   double BullsRewardDaily, BearsRewardDaily, BullsRewardBasedOnOpen, BearsRewardBasedOnOpen, 
          BullsRewardBasedOnClose, BearsRewardBasedOnClose, BullsRewardBasedOnOpenClose, BearsRewardBasedOnOpenClose,
          HighLowRange;
   
   int i=(int)MathMax(prev_calculated-1,0); for(; i<rates_total && !_StopFlag; i++)
     {
      HighLowRange=high[i]-low[i];
      BullsRewardBasedOnOpen      = (HighLowRange!=0) ? (high[i] - open[i])/HighLowRange : 0;
      BearsRewardBasedOnOpen      = (HighLowRange!=0) ? (open[i] - low[i])/HighLowRange : 0;
      BullsRewardBasedOnClose     = (HighLowRange!=0) ? (close[i] - low[i])/HighLowRange : 0;
      BearsRewardBasedOnClose     = (HighLowRange!=0) ? (high[i] - close[i])/HighLowRange : 0;
      BullsRewardBasedOnOpenClose = (HighLowRange!=0) ? (close[i]>open[i]) ? (close[i] - open[i])/HighLowRange : 0 : 0;
      BearsRewardBasedOnOpenClose = (HighLowRange!=0) ? (close[i]<open[i]) ? (open[i] - close[i])/HighLowRange : 0 : 0;
      BullsRewardDaily            = (BullsRewardBasedOnOpen + BullsRewardBasedOnClose + BullsRewardBasedOnOpenClose) / 3;
      BearsRewardDaily            = (BearsRewardBasedOnOpen + BearsRewardBasedOnClose + BearsRewardBasedOnOpenClose) / 3;
      
      //---
      //SumBulls[i] = SumBulls[i-1] + BullsRewardDaily;
      //SumBears[i] = SumBears[i-1] + BearsRewardDaily;
      SumBulls[i] = (i>0) ? SumBulls[i-1] + BullsRewardDaily : BullsRewardDaily;
      SumBears[i] = (i>0) ? SumBears[i-1] + BearsRewardDaily : BearsRewardDaily;

      WmaBulls[i] = iWma(i,inpWmaPeriod, SumBulls);
      WmaBears[i] = iWma(i,inpWmaPeriod, SumBears);

      BOP[i] = WmaBulls[i] - WmaBears[i];
      SmoothBOP[i] = iSmooth(BOP[i],inpSmoothPeriod,0,i,rates_total);
      SmoothBOPC[i] = (i>0) ? (SmoothBOP[i]>=SmoothBOP[i-1]) ? 0 : (SmoothBOP[i]<SmoothBOP[i-1]) ? 1 : SmoothBOP[i-1] : 0;   
     }
   return(i);
  }

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


//==============================================
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




