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


input int                 AvgPeriod1    = 30;          // AvgPeriod1  
input int                 AvgPeriod2    = 60;          // AvgPeriod2
input int                 AvgPeriod3    = 90;          // AvgPeriod3
input int                 AvgPeriod4    = 120;         // AvgPeriod4
input int                 StdPeriodL    = 5000;        // StdPeriodL


ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


double DiffBSP[], DiffBSPAvg1[], DiffBSPAvg2[], DiffBSPAvg3[], DiffBSPAvg4[];
double ToPoint;       

//+------------------------------------------------------------------+  
void OnInit()
  {

   ArrayInitialize(DiffBSP,0.0);
   ArrayInitialize(DiffBSPAvg1,0.0);
   ArrayInitialize(DiffBSPAvg2,0.0);
   ArrayInitialize(DiffBSPAvg3,0.0);
   ArrayInitialize(DiffBSPAvg4,0.0);

   SetIndexBuffer(0, DiffBSPAvg1,INDICATOR_DATA);
   SetIndexBuffer(1, DiffBSPAvg2,INDICATOR_DATA);
   SetIndexBuffer(2, DiffBSPAvg3,INDICATOR_DATA);
   SetIndexBuffer(3, DiffBSPAvg4,INDICATOR_DATA);
   SetIndexBuffer(4, DiffBSP,INDICATOR_CALCULATIONS);
     

   string short_name = "BSPPercentAvg("+ (string)AvgPeriod1 + ", "  + (string)AvgPeriod2 + ", " +
                                       (string)AvgPeriod3 + ", " +  (string)AvgPeriod4 + ")";      
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

   int first, second, third, fourth, fifth;
   double mVolume;
   bool MnewBar = isNewBar(_Symbol);

   string GoldSymbol = "XAUUSD";
   if(_Symbol == GoldSymbol) ToPoint = 100.;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;  
      second = first + AvgPeriod1;
      third = first + AvgPeriod2;
      fourth = first + AvgPeriod3;
      fifth = first + AvgPeriod4;
     }
   else
     { 
      first=prev_calculated-1; 
      second = first;
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
 

       tempTotalPressure=( MathAbs(tempBuyRatio) + MathAbs(tempSellRatio) );
       if(tempTotalPressure == 0) tempTotalPressure = 0.001;
       tempBuyRatio = MathAbs(tempBuyRatio)/MathAbs(tempTotalPressure)*100.;
       tempSellRatio = MathAbs(tempSellRatio)/MathAbs(tempTotalPressure)*100.;
       
       DiffBSP[bar]= MathAbs(tempBuyRatio) - MathAbs(tempSellRatio);
       
       if(bar>=second)   DiffBSPAvg1[bar] = iAverage(bar, AvgPeriod1, DiffBSP);
       if(bar>=third)   DiffBSPAvg2[bar] = iAverage(bar, AvgPeriod2, DiffBSP);
       if(bar>=fourth && MnewBar)   DiffBSPAvg3[bar] = iAverage(bar, AvgPeriod3, DiffBSP);
       if(bar>=fifth && MnewBar)   DiffBSPAvg4[bar] = iAverage(bar, AvgPeriod4, DiffBSP);
        
     }  

   return(rates_total);
  }
//+----------------------

//------------------------
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

//------------------------
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
