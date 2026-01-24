//+------------------------------------------------------------------+
//|                                       Ticks_Volume_Indicator.mq5 |
//|                                    Copyright ?2006, Profitrader | 
//|                                             profitrader@inbox.ru | 
//+------------------------------------------------------------------+
//---- Copyright
#property copyright "Copyright ?2006, Profitrader"
//---- link to the website of the author
#property link "profitrader@inbox.ru"
#property description "Ticks Volume Indicator"
//---- Indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window


#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   5

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE

#property indicator_color1  clrYellow
#property indicator_color2  clrYellow
#property indicator_color3  clrTomato
#property indicator_color4  clrBeige
#property indicator_color5  clrTomato


#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3 STYLE_DASHDOT
#property indicator_style4 STYLE_DASHDOT
#property indicator_style5 STYLE_DASHDOT


#property indicator_width1  2
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1

#property indicator_label1  "TVI"
#property indicator_label2  "Edge"
#property indicator_label3  "+1.0"
#property indicator_label4  "avg"
#property indicator_label5  "-1.0"


//+----------------------------------------------+
//|  CXMA class description                      |
//+----------------------------------------------+
#include <SmoothAlgorithms.mqh> 
#include <MovingAverages.mqh>
//+----------------------------------------------+
//---- declaration of the CXMA class variables from the SmoothAlgorithms.mqh file
CXMA XMA1,XMA2,XMA3,XMA4,XMA5;
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input ENUM_APPLIED_VOLUME VolumeType=VOLUME_TICK;  // Volume
//input Smooth_Method XMA_Method=MODE_EMA; // Averaging method
CXMA::Smooth_Method XMA_Method=(int)MODE_EMA; // Averaging method
input uint XLength1=5;                             // Depth of the first averaging
input uint XLength2=5;                             // Depth of the second averaging
input uint XLength3=5;                             // Depth of the third averaging                   
input int XPhase=15;                               // Smoothing parameter
input int stdPeriod = 100;
input int avgPeriod = 100;
input double stdMultiFactor = 1.0;
input ENUM_MA_METHOD avgMAMethod = MODE_EMA;

// for JJMA it varies within the range -100 ... +100 and influences the quality of the transient period;
// for VIDIA it is a CMO period, for AMA it is a slow average period
input int Shift=0;                                 // Horizontal shift of the indicator in bars 
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double TVIBuffer[], TVIEdge[], stdDev[], avgTVI[], upStdDev[], downStdDev[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total,min_rates_1,min_rates_2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_1=XMA1.GetStartBars((int)MODE_EMA,XLength1,XPhase);
   min_rates_2=min_rates_1+XMA1.GetStartBars((int)MODE_EMA,XLength2,XPhase);
   min_rates_total=min_rates_2+XMA1.GetStartBars((int)MODE_EMA,XLength3,XPhase);
//---- set SignBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,TVIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,TVIEdge,INDICATOR_DATA);   
   SetIndexBuffer(2,upStdDev,INDICATOR_DATA);
   SetIndexBuffer(3,avgTVI,INDICATOR_DATA);
   SetIndexBuffer(4,downStdDev,INDICATOR_DATA);
   SetIndexBuffer(5,stdDev,INDICATOR_CALCULATIONS);
/*
//---- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- shifting the beginning of calculation of indicator 1 drawing by 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- Creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"Ticks_Volume_Indicator");
//--- Determining the accuracy of displaying the indicator values
//   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);


   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total+3);
   
*/   
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
//---- checking the number of bars to be enough for the calculation
   if(rates_total<min_rates_total) return(0);

//---- declaration of local variables 
   double UpTicks,DownTicks,EMA_UpTicks,EMA_DownTicks,DEMA_UpTicks,DEMA_DownTicks,res,TVI_calculate;
   int first,bar, stdfirst;
   long Vol;

//---- calculation of the 'first' starting number for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=0;                   // starting index for calculation of all bars
      stdfirst = stdPeriod-1;
     }
   else {
      first=prev_calculated-1; // starting number for calculation of new bars
      stdfirst = prev_calculated-1;
   }

//---- The main loop of the indicator calculation
   for(bar=first; bar<rates_total; bar++)
   {
      if(VolumeType==VOLUME_TICK) Vol=long(tick_volume[bar]);
      else Vol=long(volume[bar]);

      UpTicks=(Vol+(close[bar]-open[bar])/_Point)/2;
      DownTicks=Vol-UpTicks;
      
      EMA_UpTicks=XMA1.XMASeries(0,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength1,UpTicks,bar,false);
      EMA_DownTicks=XMA2.XMASeries(0,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength1,DownTicks,bar,false);
      
      DEMA_UpTicks=XMA3.XMASeries(min_rates_1,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength2,EMA_UpTicks,bar,false);
      DEMA_DownTicks=XMA4.XMASeries(min_rates_1,prev_calculated,rates_total,(int)MODE_EMA,XPhase,XLength2,EMA_DownTicks,bar,false);
      
      res=(DEMA_UpTicks+DEMA_DownTicks); 
      
      if(res) TVI_calculate=10.*(DEMA_UpTicks-DEMA_DownTicks)/res;
      else TVI_calculate=0.0;  

      TVIBuffer[bar]=10.*XMA5.XMASeries(min_rates_2,prev_calculated,rates_total,XMA_Method,XPhase,XLength3,TVI_calculate,bar,false);

      if(bar<=4) TVIEdge[bar]=0.;
      else{
         if( (TVIBuffer[bar-1]-TVIBuffer[bar-2])<=0. && (TVIBuffer[bar]-TVIBuffer[bar-1])>0  ) TVIEdge[bar]=1.;
         else if((TVIBuffer[bar-1]-TVIBuffer[bar-2])>=0. && (TVIBuffer[bar]-TVIBuffer[bar-1])<0) TVIEdge[bar]=-1.;
         else TVIEdge[bar]=0.;
      }         
   }
   
//int ExponentialMAOnBuffer(const int rates_total,const int prev_calculated,const int begin,const int period,const double& price[],double& buffer[])

   ExponentialMAOnBuffer(rates_total, prev_calculated, 0, avgPeriod, TVIBuffer, avgTVI);
//   for(bar=avgfirst;bar<rates_total; bar++) avgTVI[bar] =iMAOnArray(TVIBuffer, avgPeriod, Shift, MODE_EMA, bar);

   for(bar=stdfirst; bar<rates_total; bar++) 
   {
      GetStdDev(bar);
      upStdDev[bar] = avgTVI[bar] + stdDev[bar]*stdMultiFactor;
      downStdDev[bar] = avgTVI[bar] - stdDev[bar]*stdMultiFactor;
   }  
   
   
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+



void GetStdDev(int position)
{
    
    double sum = 0.0;
    for(int i=(position-stdPeriod+1);i<=position;i++)
    {
      sum += avgTVI[i];
    }
        
      sum = sum/stdPeriod;    
    
    double sum2 = 0.0;
    for(int i=(position-stdPeriod+1);i<=position;i++)
    {
      sum2 = sum2 + (avgTVI[i]- sum) * (avgTVI[i]- sum);
    }  
      
      sum2 = sum2/stdPeriod;      
      stdDev[position] = MathSqrt(sum2);
      
      return;
}
