//+------------------------------------------------------------------+
//|                                                 BSP105NORMAL.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 18
#property indicator_plots   7

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGreen,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_LINE

#property indicator_color2  clrYellow
#property indicator_color3  clrYellow
#property indicator_color4  clrYellow
#property indicator_color5  clrYellow
#property indicator_color6  clrYellow
#property indicator_color7  clrYellow

#property indicator_style2  STYLE_DOT
#property indicator_style3  STYLE_DASH
#property indicator_style4  STYLE_SOLID
#property indicator_style5  STYLE_SOLID
#property indicator_style6  STYLE_DASH
#property indicator_style7  STYLE_DOT


#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1


#property indicator_level1 0.

ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume


input int                 WmaPeriod    = 120;          // wmaPeriod
input int                 WmaPeriod2   = 5;          // WmaPeriod2
input int                 StdL         = 5000;        // StdL
input double              MultiFactor1 = 1.0;         // MultiFactor1
input double              MultiFactor2 = 2.0;         // MultiFactor2
input double              MultiFactor3 = 3.0;         // MultiFactor3



double SellPressure[], BuyPressure[], Volume[],
       avg1SellPressure[], avg1BuyPressure[], avg1Volume[], nfBuyPressure[], nfSellPressure[],
       SumSellPressure[], SumBuyPressure[], DiffPressure[], DiffPressureC[], 
       up3Std[], up2Std[],up1Std[], down1Std[], down2Std[],down3Std[] ;


//+------------------------------------------------------------------+  
void OnInit()
  {

   SetIndexBuffer(0,DiffPressure,INDICATOR_DATA);
   SetIndexBuffer(1,DiffPressureC,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,up3Std,INDICATOR_DATA); 
   SetIndexBuffer(3,up2Std,INDICATOR_DATA); 
   SetIndexBuffer(4,up1Std,INDICATOR_DATA); 
   SetIndexBuffer(5,down1Std,INDICATOR_DATA); 
   SetIndexBuffer(6,down2Std,INDICATOR_DATA); 
   SetIndexBuffer(7,down3Std,INDICATOR_DATA); 
   SetIndexBuffer(8,SumBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,SumSellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,avg1Volume,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,avg1BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,avg1SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,Volume,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,BuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(15,SellPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(16,nfBuyPressure,INDICATOR_CALCULATIONS);
   SetIndexBuffer(17,nfSellPressure,INDICATOR_CALCULATIONS);
   
   
  
   string short_name = "BSPNormal("+ (string)WmaPeriod +", "+ (string)WmaPeriod2 + ", "+ (string)StdL +", "+
                                     (string)MultiFactor1 +", "+ (string)MultiFactor2 +", "+ (string)MultiFactor3 + ")";      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
 
     
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

   int first, second, third, fourth;
   double mVolume, standardDeviationL;
   bool NewBar = isNewBar(_Symbol);
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2; 
      second = first + WmaPeriod; 
      third = second + WmaPeriod2;
      fourth = third + StdL;
     }
   else
     { 
      first=prev_calculated-1;
      second = first; 
      third = first;
      fourth = first;    
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

       BuyPressure[bar] = (tempBuyRatio)*10000.;
       SellPressure[bar] = (tempSellRatio)*10000.; 
       Volume[bar] = mVolume;

      if(bar>=second)
        {           
          avg1BuyPressure[bar] = Average(bar, WmaPeriod, BuyPressure);
          avg1SellPressure[bar] = Average(bar, WmaPeriod, SellPressure);
          avg1Volume[bar] = Average(bar, WmaPeriod, Volume);

          nfBuyPressure[bar] = BuyPressure[bar]*avg1Volume[bar]/avg1BuyPressure[bar];
          nfSellPressure[bar] = SellPressure[bar]*avg1Volume[bar]/avg1SellPressure[bar];
        } 

      if(bar>=third)
        {            
          SumBuyPressure[bar] = iWma(bar, WmaPeriod2, nfBuyPressure);
          SumSellPressure[bar] = iWma(bar, WmaPeriod2, nfSellPressure);

          DiffPressure[bar]=SumBuyPressure[bar] - SumSellPressure[bar];  

          if(DiffPressure[bar]>=0.) DiffPressureC[bar] = 0;
          else DiffPressureC[bar] = 1;
        } 

      if( (bar>=fourth) && NewBar)
        {           
          standardDeviationL = StdDev((bar-1), StdL, DiffPressure);

          up1Std[bar]   =   standardDeviationL * MultiFactor1;
          down1Std[bar] =  -standardDeviationL * MultiFactor1;

          up2Std[bar]   =   standardDeviationL * MultiFactor2;
          down2Std[bar] =  -standardDeviationL * MultiFactor2;

          up3Std[bar]   =   standardDeviationL * MultiFactor3;
          down3Std[bar] =  -standardDeviationL * MultiFactor3;
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




double Average(int end, int avgPeriod, const double &S_Array[])
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
