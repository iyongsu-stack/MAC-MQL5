//+------------------------------------------------------------------+
//|                                                     LRAVGSTD.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 15
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

input int                 LwmaPeriod    = 6;          // WmaPeriod1
input int                 AvgPeriod    = 20;          //AvgPeriod
input int                 StdPeriodL    = 10000;        // StdPeriodL
input int                 StdPeriodS    = 10;        // StdPeriodS

input double              MultiFactorL1  = 0.8;         // StdMultiFactorL1
input double              MultiFactorL2  = 2.0;         // StdMultiFactorL2
input double              MultiFactorL3  = 4.0;         // StdMultiFactorL3

input double              MaxBSPMult     = 5.0;         // MaxBSPmultfactor



double SellPressure[], BuyPressure[], SumSellPressure[], SumBuyPressure[], SumDiffPressure[], LWMAVal[],
       avgValLR[], stdS[], stdSC[], 
       up1StdAvgValLR[], up2StdAvgValLR[], up3StdAvgValLR[],
       down1StdAvgValLR[], down2StdAvgValLR[], down3StdAvgValLR[];

double ToPoint;       

//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,up3StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(1,up2StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(2,up1StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(3,down1StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(4,down2StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(5,down3StdAvgValLR,INDICATOR_DATA); 
   SetIndexBuffer(6,stdS,INDICATOR_DATA);     
   SetIndexBuffer(7,stdSC,INDICATOR_COLOR_INDEX);     
   SetIndexBuffer(8,SumDiffPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,SumBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,SumSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,LWMAVal,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,avgValLR,INDICATOR_CALCULATIONS);
   
  
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

   int first, third, fourth, fifth;
   double mVolume, standardDeviationL;
   bool MnewBar = isNewBar(_Symbol);
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2; 
      third  = first + AvgPeriod;
      fourth = third + StdPeriodL;
      fifth = third + StdPeriodS;
     }
   else
     { 
      first=prev_calculated-1;
      third = first; 
      fourth = first;
      fifth = first;
     } 


//---- The main loop of the indicator calculation
   for(int bar=first; bar<rates_total; bar++)
     {
        
       if(VolumeType == VOLUME_TICK) mVolume = (double)tick_volume[bar];
       else mVolume = (double)volume[bar];


       double tempBuyRatio, tempSellRatio, tempTotalPressure ;

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

       BuyPressure[bar] = (tempBuyRatio)*ToPoint;
       SellPressure[bar] = (tempSellRatio)*ToPoint; 
/*
       if((bar>=fourth) && MnewBar)
       {
         double buyStd = StdDev3((bar-1), StdPeriodL, BuyPressure);
         if( BuyPressure[bar] > (buyStd*MaxBSPMult) ) BuyPressure[bar] = buyStd*MaxBSPMult;
         
         double sellStd = StdDev3((bar-1), StdPeriodL, SellPressure);
         if( SellPressure[bar] > (sellStd*MaxBSPMult) ) SellPressure[bar] = sellStd*MaxBSPMult;
       }              
*/
       SumBuyPressure[bar] = SumBuyPressure[bar-1] + BuyPressure[bar];
       SumSellPressure[bar] = SumSellPressure[bar-1] + SellPressure[bar];
       
       SumDiffPressure[bar]=SumBuyPressure[bar] - SumSellPressure[bar];      

       LWMAVal[bar]  = _lwma.calculate(SumDiffPressure[bar],bar,rates_total);
             

       if(bar>=third)
       {
          avgValLR[bar]= iAverage(bar, AvgPeriod, LWMAVal);
       }
       
       if((bar>=fourth) && MnewBar)
       {
          standardDeviationL = StdDev((bar-1), StdPeriodL, avgValLR, LWMAVal);

          up1StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL1;
          down1StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL1;

          up2StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL2;
          down2StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL2;

          up3StdAvgValLR[bar]   =   standardDeviationL * MultiFactorL3;
          down3StdAvgValLR[bar] =  -standardDeviationL * MultiFactorL3;
       }  
       
       if(bar>=fifth)
       {        
          stdS[bar] = StdDev2(bar, StdPeriodS, avgValLR, LWMAVal);  
          stdSC[bar] = (bar>0) ? (stdS[bar]>stdS[bar-1]) ? 0 : (stdS[bar]<stdS[bar-1]) ? 1 : stdS[bar-1] : 0;          
       }  
   }
     
   return(rates_total);
  }
//+----------------------


double StdDev(int end, int SDPeriod, const double &Avg_Array[], const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
    {
      dAmount+=(S_Array[i]-Avg_Array[i])*(S_Array[i]-Avg_Array[i]);
    }       

    StdValue = MathSqrt(dAmount/SDPeriod);
    return(StdValue);
}  

double StdDev2(int end, int SDPeriod, const double &Avg_Array[], const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
     {
      dAmount+=(S_Array[i] - Avg_Array[i] )*MathAbs(S_Array[i] - Avg_Array[i]);
     }       

    if(dAmount < 0.)
     {
      StdValue = -1*MathSqrt(MathAbs(dAmount/SDPeriod));
     }
    else StdValue = MathSqrt(dAmount/SDPeriod);

    return(StdValue);
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


class CLwma
{
   private :
      struct sLwmaArrayStruct
         {
            double value;
            double wsumm;
            double vsumm;
         };
      sLwmaArrayStruct m_array[];
      int              m_arraySize;
      int              m_period;
      double           m_weight;
   public :
      CLwma() : m_period(1), m_weight(1), m_arraySize(-1) {                     return; }
     ~CLwma()                                              { ArrayFree(m_array); return; }
    
     //
     //---
     //

     void init(int period)
     {
         m_period = (period>1) ? period : 1;
     }
        
     double calculate(double value, int i, int bars)
     {
        if (m_arraySize<bars)
          { m_arraySize=ArrayResize(m_array,bars+500); if (m_arraySize<bars) return(0); }

         //
         //
         //

         m_array[i].value=value;
               if (i>m_period)
               {
                     m_array[i].wsumm  = m_array[i-1].wsumm+value*m_period-m_array[i-1       ].vsumm;
                     m_array[i].vsumm  = m_array[i-1].vsumm+value         -m_array[i-m_period].value;
               }
               else
               {
                     m_weight          = 0;
                     m_array[i].wsumm  = 0;
                     m_array[i].vsumm  = 0;
                     for(int k=0, w=m_period; k<m_period && i>=k; k++,w--)
                     {
                           m_weight             += w;
                           m_array[i].wsumm += m_array[i-k].value*(double)w;
                           m_array[i].vsumm += m_array[i-k].value;
                     }
               }
               return(m_array[i].wsumm/m_weight);
      }  
};
CLwma _lwma;


//+------------------------------------------------------------------+
//| Non Linear Regression Function                                   |
//+------------------------------------------------------------------+
double workNlr[][1];
double nlrYValue[];
double nlrXValue[];

double iNlr(double price,int Length,int shift,int desiredBar,int bars,int instanceNo=0)
{
   if(ArrayRange(workNlr,0)!=bars) ArrayResize(workNlr,bars);
   if(ArraySize(nlrYValue)!=Length) ArrayResize(nlrYValue,Length);
   if(ArraySize(nlrXValue)!=Length) ArrayResize(nlrXValue,Length);
//
//---
//
   double AvgX = 0;
   double AvgY = 0;
   int r=shift;
   workNlr[r][instanceNo]=price;
   ArrayInitialize(nlrXValue,0);
   ArrayInitialize(nlrYValue,0);
   for(int i=0;i<Length && (r-i)>=0;i++)
     {
      nlrXValue[i] = i;
      nlrYValue[i] = workNlr[r-i][instanceNo];
      AvgX  += nlrXValue[i];
      AvgY  += nlrYValue[i];
     }
   AvgX /= Length;
   AvgY /= Length;
//
//---
//
   double SXX   = 0;
   double SXY   = 0;
   double SYY   = 0;
   double SXX2  = 0;
   double SX2X2 = 0;
   double SYX2  = 0;

   for(int i=0;i<Length;i++)
     {
      double XM  = nlrXValue[i] - AvgX;
      double YM  = nlrYValue[i] - AvgY;
      double XM2 = nlrXValue[i] * nlrXValue[i] - AvgX*AvgX;
      SXX   += XM*XM;
      SXY   += XM*YM;
      SYY   += YM*YM;
      SXX2  += XM*XM2;
      SX2X2 += XM2*XM2;
      SYX2  += YM*XM2;
     }
//
//---
//
   double tmp;
   double ACoeff=0;
   double BCoeff=0;
   double CCoeff=0;

   tmp=SXX*SX2X2-SXX2*SXX2;
   if(tmp!=0)
     {
      BCoeff = ( SXY*SX2X2 - SYX2*SXX2 ) / tmp;
      CCoeff = ( SXX*SYX2  - SXX2*SXY )  / tmp;
     }
   ACoeff = AvgY   - BCoeff*AvgX       - CCoeff*AvgX*AvgX;
   tmp    = ACoeff + BCoeff*desiredBar + CCoeff*desiredBar*desiredBar;
   return(tmp);
}


double iAverage(int end, int avgPeriod, const double &S_Array[])
{
    double sum;
    sum=0.0;
      
    for(int i=end+1-avgPeriod;i<=end;i++)
    {
          sum+=S_Array[i];
    }
       
    return(sum/avgPeriod);

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

