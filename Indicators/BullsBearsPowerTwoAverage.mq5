//+------------------------------------------------------------------+
//|                                    BullsBearsPowerTwoAverage.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Shovel"
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrAqua
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1


//--- input parameters
input int                  InpPeriod=30;              // Expnetial Period
input int                  AvgPeriod1=1440;             // Long Average Period1
input int                  AvgPeriod2=21;             // Short Average Period2


input ENUM_APPLIED_VOLUME  InpVolumeType=VOLUME_TICK; // Volumes
input double               delta=0.0;             // delta (flat level)

//--- handle of EMA
int       ExtEmaHandle;

//--- indicator buffers
double    PercentBuffer[];
double    AverageBuffer1[];
double    AverageBuffer2[];
double    ExtBullsBearsBuffer[];
double    ExtTempBuffer[];
double    ExtVolumesBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,PercentBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,AverageBuffer1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,AverageBuffer2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtBullsBearsBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtTempBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtVolumesBuffer,INDICATOR_CALCULATIONS);

//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpPeriod-1);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"BullsBearsVolumeRatio( "+(string)InpPeriod+","+(string)AvgPeriod1+ ","+(string)AvgPeriod2+    " ) ");
//--- get MA handle
   ExtEmaHandle=iMA(NULL,0,InpPeriod,0,MODE_EMA,PRICE_CLOSE);

//--- initialization done
   return(0);
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
//---

   int i,limit,period=InpPeriod, first, second;
   double _bear,_bull;
//--- value point
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);

//--- check for bars count
   if(rates_total<InpPeriod)
      return(0);// not enough bars for calculation  
//--- not all data may be calculated
   int calculated=BarsCalculated(ExtEmaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtEmaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
//---- get ma buffers
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtEmaHandle,0,0,to_copy,ExtTempBuffer)<=0)
     {
      Print("getting ExtEmaHandle is failed! Error",GetLastError());
      return(0);
     }
//--- first calculation or number of bars was changed
   if(prev_calculated<InpPeriod)
     {   
      limit =InpPeriod;
      first = InpPeriod + AvgPeriod1;
      second= InpPeriod + AvgPeriod2;
     } 
   else 
     {
      limit=prev_calculated-1;
      first = prev_calculated-1;
      second= prev_calculated-1;
     } 

//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      _bull = high[i]-ExtTempBuffer[i];
      _bear = low[i]-ExtTempBuffer[i];

      //--- fill indicators buffer
      if(_bull>0 && _bear>0) ExtBullsBearsBuffer[i]=_bull-_bear;
      else if(_bull<0 && _bear<0) ExtBullsBearsBuffer[i]=-(MathAbs(_bear)-MathAbs(_bull));
      else  ExtBullsBearsBuffer[i]=_bull+_bear;

      //--- value volume
      long _volume=(InpVolumeType==VOLUME_TICK)?tick_volume[i]:volume[i];

      //--- add volume to indicators buffer
      ExtBullsBearsBuffer[i]=MathAbs(ExtBullsBearsBuffer[i]*(double)_volume);

      //--- remove noise
      if(MathAbs(ExtBullsBearsBuffer[i])<delta) ExtBullsBearsBuffer[i]=0.0;
     } 





   for(int avgbar=first; avgbar<rates_total; avgbar++)
     { 
        AverageBuffer1[avgbar]= Average(avgbar, AvgPeriod1, ExtBullsBearsBuffer);                 
     }  


     
   for(int avgbar=second; avgbar<rates_total; avgbar++)
     { 
        AverageBuffer2[avgbar]= Average(avgbar, AvgPeriod2, ExtBullsBearsBuffer); 
        if(AverageBuffer1[avgbar]==0.) 
          {
            PercentBuffer[avgbar] = PercentBuffer[avgbar-1];
            continue;
          }
        PercentBuffer[avgbar]=(AverageBuffer2[avgbar]/AverageBuffer1[avgbar]-1.)*100.;                
     }  
     
       


//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+-----------



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