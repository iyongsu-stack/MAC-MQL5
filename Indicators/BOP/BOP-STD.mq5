//------------------------------------------------------------------
#property copyright "© mladen, 2018"
#property link      "mladenfx@gmail.com"
#property version   "1.00"
//------------------------------------------------------------------
#property indicator_separate_window

#property indicator_buffers 9
#property indicator_plots   8

#property indicator_label7  "BOP-Avg"
#property indicator_label8  "BOP"

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_LINE
#property indicator_type8   DRAW_COLOR_LINE


#property indicator_color1  clrYellow
#property indicator_color2  clrYellow
#property indicator_color3  clrYellow
#property indicator_color4  clrYellow
#property indicator_color5  clrYellow
#property indicator_color6  clrYellow
#property indicator_color7  clrWhite
#property indicator_color8  clrLimeGreen, clrOrange

#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DASH
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID
#property indicator_style5  STYLE_DASH
#property indicator_style6  STYLE_DOT
#property indicator_style7  STYLE_SOLID
#property indicator_style8  STYLE_SOLID

#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
#property indicator_width8  2

//-------------------
input int           inpSmoothPeriod = 150;       // Smoothing period
input int           inpAvgPeriod    = 200;       // Avg period
input int           inpStdPeriod    = 10000;     // Std period
input double        inpStdMulti1    = 1.0;        // Std multiplier1
input double        inpStdMulti2    = 2.0;        // Std multiplier2
input double        inpStdMulti3    = 3.0;        // Std multiplier3

double  BOP[], BOPC[], BOPAvg[], Up3[], Up2[], Up1[], Down1[], Down2[], Down3[];

void OnInit()
  {

   ArrayInitialize(BOP,0.0);
   ArrayInitialize(BOPC,0);    
   ArrayInitialize(BOPAvg,0.0);
   ArrayInitialize(Up3,0.0);
   ArrayInitialize(Up2,0.0);
   ArrayInitialize(Up1,0.0);
   ArrayInitialize(Down1,0.0);
   ArrayInitialize(Down2,0.0);
   ArrayInitialize(Down3,0.0);

   //--- indicator buffers mapping 
   SetIndexBuffer(0,Up3,INDICATOR_DATA);
   SetIndexBuffer(1,Up2,INDICATOR_DATA);
   SetIndexBuffer(2,Up1,INDICATOR_DATA);
   SetIndexBuffer(3,Down1,INDICATOR_DATA);
   SetIndexBuffer(4,Down2,INDICATOR_DATA);
   SetIndexBuffer(5,Down3,INDICATOR_DATA);
   SetIndexBuffer(6,BOPAvg,INDICATOR_DATA);
   SetIndexBuffer(7,BOP,INDICATOR_DATA);
   SetIndexBuffer(8,BOPC,INDICATOR_COLOR_INDEX);

   //---
   IndicatorSetString(INDICATOR_SHORTNAME,"BOP-Std ("+(string)inpSmoothPeriod+", "+
                     (string)inpAvgPeriod+", "+(string)inpStdPeriod+", "+
                     (string)inpStdMulti1+", "+(string)inpStdMulti2+", "+(string)inpStdMulti3+")");
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
   if(Bars(_Symbol,_Period)<rates_total) return(-1);
   bool NewBarFlag=isNewBar(_Symbol);
   double standardDeviationL = 0;

//---
   int i=(int)MathMax(prev_calculated-1,0); for(; i<rates_total && !_StopFlag; i++)
   {
      double HighLowRange=high[i]-low[i];
      double BullsRewardBasedOnOpen      = (HighLowRange!=0) ? (high[i] - open[i])/HighLowRange : 0;
      double BearsRewardBasedOnOpen      = (HighLowRange!=0) ? (open[i] - low[i])/HighLowRange : 0;
      double BullsRewardBasedOnClose     = (HighLowRange!=0) ? (close[i] - low[i])/HighLowRange : 0;
      double BearsRewardBasedOnClose     = (HighLowRange!=0) ? (high[i] - close[i])/HighLowRange : 0;
      double BullsRewardBasedOnOpenClose = (HighLowRange!=0) ? (close[i]>open[i]) ? (close[i] - open[i])/HighLowRange : 0 : 0;
      double BearsRewardBasedOnOpenClose = (HighLowRange!=0) ? (close[i]<open[i]) ? (open[i] - close[i])/HighLowRange : 0 : 0;
      double BullsRewardDaily            = (BullsRewardBasedOnOpen + BullsRewardBasedOnClose + BullsRewardBasedOnOpenClose) / 3;
      double BearsRewardDaily            = (BearsRewardBasedOnOpen + BearsRewardBasedOnClose + BearsRewardBasedOnOpenClose) / 3;
      //---
      BOP[i] = iSmooth(BullsRewardDaily-BearsRewardDaily,inpSmoothPeriod,0,i,rates_total);
      BOPC[i] = (i>0) ? (BOP[i]>BOP[i-1]) ? 0 : (BOP[i]<BOP[i-1]) ? 1 : BOP[i-1] : 0;   
      BOPAvg[i] = Average(i,inpAvgPeriod,BOP);

      if(NewBarFlag)
      {
         standardDeviationL = StdDev3(i,inpStdPeriod, BOP);
         Up3[i] = standardDeviationL * inpStdMulti3;
         Up2[i] = standardDeviationL * inpStdMulti2;
         Up1[i] = standardDeviationL * inpStdMulti1;
         Down1[i] = -standardDeviationL * inpStdMulti1;
         Down2[i] = -standardDeviationL * inpStdMulti2;
         Down3[i] = -standardDeviationL * inpStdMulti3;
      }
   }

   return(i);
  }








//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

//  StdDev3--------------------------------
double StdDev3(int end, int SDPeriod, const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
    {
      if(i<0) continue;
      dAmount+=(S_Array[i])*(S_Array[i]);
    }       

    StdValue = MathSqrt(dAmount/SDPeriod);
    return(StdValue);
}  


//  StdDev--------------------------------
double StdDev(int end, int SDPeriod, const double &Avg_Array[], const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
    {
      if(i<0) continue;
      dAmount+=(S_Array[i]-Avg_Array[i])*(S_Array[i]-Avg_Array[i]);
    }       

    StdValue = MathSqrt(dAmount/SDPeriod);
    return(StdValue);
} 


//  Average--------------------------------
double Average(int end, int avgPeriod, const double &S_Array[])
{
    double sum;
    sum=0.0;
      
   
    for(int i=end+1-avgPeriod;i<=end;i++)
    {
      if(i<0) continue;
      sum+=S_Array[i];
    }
       
    return(sum/avgPeriod);

}


//  isNewBar--------------------------------
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


//  iSmooth--------------------------------
#define _smoothInstances     2
#define _smoothInstancesSize 10
double m_wrk[][_smoothInstances*_smoothInstancesSize];

double iSmooth(double price,double length,double phase,int r,int bars,int instanceNo=0)
  {
   #define bsmax  5
   #define bsmin  6
   #define volty  7
   #define vsum   8
   #define avolty 9

   if(ArrayRange(m_wrk,0)!=bars) ArrayResize(m_wrk,bars); if(ArrayRange(m_wrk,0)!=bars) return(price); instanceNo*=_smoothInstancesSize;
   if(r==0 || length<=1) { int k=0; for(; k<7; k++) m_wrk[r][instanceNo+k]=price; for(; k<10; k++) m_wrk[r][instanceNo+k]=0; return(price); }

   double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
   double pow1   = MathMax(len1-2.0,0.5);
   double del1   = price - m_wrk[r-1][instanceNo+bsmax];
   double del2   = price - m_wrk[r-1][instanceNo+bsmin];
   int    forBar = MathMin(r,10);

   m_wrk[r][instanceNo+volty]=0;
   if(MathAbs(del1) > MathAbs(del2)) m_wrk[r][instanceNo+volty] = MathAbs(del1);
   if(MathAbs(del1) < MathAbs(del2)) m_wrk[r][instanceNo+volty] = MathAbs(del2);
   m_wrk[r][instanceNo+vsum]=m_wrk[r-1][instanceNo+vsum]+(m_wrk[r][instanceNo+volty]-m_wrk[r-forBar][instanceNo+volty])*0.1;

   m_wrk[r][instanceNo+avolty]=m_wrk[r-1][instanceNo+avolty]+(2.0/(MathMax(4.0*length,30)+1.0))*(m_wrk[r][instanceNo+vsum]-m_wrk[r-1][instanceNo+avolty]);
   double dVolty=(m_wrk[r][instanceNo+avolty]>0) ? m_wrk[r][instanceNo+volty]/m_wrk[r][instanceNo+avolty]: 0;
   if(dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
   if(dVolty < 1)                      dVolty = 1.0;

   double pow2 = MathPow(dVolty, pow1);
   double len2 = MathSqrt(0.5*(length-1))*len1;
   double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

   if(del1 > 0) m_wrk[r][instanceNo+bsmax] = price; else m_wrk[r][instanceNo+bsmax] = price - Kv*del1;
   if(del2 < 0) m_wrk[r][instanceNo+bsmin] = price; else m_wrk[r][instanceNo+bsmin] = price - Kv*del2;

   double corr  = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
   double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
   double alpha = MathPow(beta,pow2);

   m_wrk[r][instanceNo+0] = price + alpha*(m_wrk[r-1][instanceNo+0]-price);
   m_wrk[r][instanceNo+1] = (price - m_wrk[r][instanceNo+0])*(1-beta) + beta*m_wrk[r-1][instanceNo+1];
   m_wrk[r][instanceNo+2] = (m_wrk[r][instanceNo+0] + corr*m_wrk[r][instanceNo+1]);
   m_wrk[r][instanceNo+3] = (m_wrk[r][instanceNo+2] - m_wrk[r-1][instanceNo+4])*MathPow((1-alpha),2) + MathPow(alpha,2)*m_wrk[r-1][instanceNo+3];
   m_wrk[r][instanceNo+4] = (m_wrk[r-1][instanceNo+4] + m_wrk[r][instanceNo+3]);

   return(m_wrk[r][instanceNo+4]);

   #undef bsmax
   #undef bsmin
   #undef volty
   #undef vsum
   #undef avolty
  }    
//+------------------------------------------------------------------+
