//+------------------------------------------------------------------+
//|                                                 BSP10-1-TP-1.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 3
#property indicator_plots   2

#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE


#property indicator_color1  clrGreen
#property indicator_color2  clrRed

#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID

#property indicator_width1  1
#property indicator_width2  1


ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume

input     int           SmaPeriod1   = 1440;    //SmaPeriod1
input     int           WmaPeriod1   = 7   ;    //WmaPeriod1
input     double        MultiFactor  = 0.5 ;    //Sma MultiFactor

double TotalPressure[], avg1TotalPressure[], avg2TotalPressure[];


//+------------------------------------------------------------------+  
void OnInit()
  {


   SetIndexBuffer(0,avg1TotalPressure,INDICATOR_DATA);
   SetIndexBuffer(1,avg2TotalPressure,INDICATOR_DATA);
   SetIndexBuffer(2,TotalPressure,INDICATOR_CALCULATIONS);

  
 
     
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
   double mVolume;
   
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=2;
      second = first + WmaPeriod1; 
      third  = first + SmaPeriod1; 
     }
   else
     { 
      first=prev_calculated-1; 
      second = first;
      third  = first;
    } 


//---- The main loop of the indicator calculation
   for(int bar=first; bar<rates_total; bar++)
     {
        
       if(VolumeType == VOLUME_TICK) mVolume = (double)tick_volume[bar];
       else mVolume = (double)volume[bar];

       TotalPressure[bar] = mVolume;
     } 

   for(int bar=second; bar<rates_total; bar++)
     {
            
       avg1TotalPressure[bar] = iWma(bar, WmaPeriod1, TotalPressure);

     } 

     
   for(int bar=third; bar<rates_total; bar++)
     {
            
       avg2TotalPressure[bar] = iSma(bar, SmaPeriod1, TotalPressure)* MultiFactor;

     } 

   return(rates_total);
  }
//+----------------------

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

double iSma(int end, int avgPeriod, const double &S_Array[])
{
    double sum;
    sum=0.0;
      
    for(int i=end+1-avgPeriod;i<=end;i++)
    {
          sum+=S_Array[i];
    }
       
    return(sum/avgPeriod);

}
