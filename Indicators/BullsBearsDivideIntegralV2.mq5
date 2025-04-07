//+------------------------------------------------------------------+
//|                                   BullsBearsDivideIntegralV2.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"

//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   4

#property indicator_label1  "BUBEVO"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Green,Red
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "integral"
#property indicator_type2   DRAW_LINE
#property indicator_style2  STYLE_SOLID
#property indicator_color2  clrYellow
#property indicator_width2  1


#property indicator_label3  "pAvg1"
#property indicator_type3   DRAW_LINE
#property indicator_style3  STYLE_SOLID
#property indicator_color3  clrAqua
#property indicator_width3  1

#property indicator_label4  "mAvg1"
#property indicator_type4   DRAW_LINE
#property indicator_style4  STYLE_SOLID
#property indicator_color4  clrAqua
#property indicator_width4  1


#property indicator_level1  0.0
#property indicator_applied_price PRICE_CLOSE



//--- input parameters
input int                  InpPeriod=50;              // Period
input int                  AvgPeriod1=30;             // Long Average Period1
input double               MultiFactor = 7.0;         // Multi Factor

ENUM_APPLIED_VOLUME  InpVolumeType=VOLUME_TICK; // Volumes
double               delta=0.0;             // delta (flat level)



enum Signal1
{
   MINUS,
   PLUS
};
Signal1 SignalA, SignalB;

//--- handle of EMA
int       ExtEmaHandle;

//--- indicator buffers
double    integral[];
double    ExtBullsBearsBuffer[];
double    AbsExtBullsBearsBuffer[];
double    ExtColorBuffer[];
double    ExtTempBuffer[];
double    ExtVolumesBuffer[];
double    AverageBuffer1[];
double    mAverageBuffer1[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtBullsBearsBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,integral,INDICATOR_DATA);
   SetIndexBuffer(3,AverageBuffer1,INDICATOR_DATA);
   SetIndexBuffer(4,mAverageBuffer1,INDICATOR_DATA);
   SetIndexBuffer(5,ExtTempBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,ExtVolumesBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,AbsExtBullsBearsBuffer,INDICATOR_CALCULATIONS);
   
   
   

//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpPeriod-1);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"BullsBearsIntegral("+(string)InpPeriod+", Dperiod: "+(string)AvgPeriod1+", MFactor: "+(string)MultiFactor+") ");
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

   int i,limit,period=InpPeriod, first;
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
     } 
   else 
     {
      limit=prev_calculated-1;
      first = prev_calculated-1;
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
      ExtBullsBearsBuffer[i]=ExtBullsBearsBuffer[i]*(double)_volume;
      AbsExtBullsBearsBuffer[i]=MathAbs(ExtBullsBearsBuffer[i]);

      //--- remove noise
      if(MathAbs(ExtBullsBearsBuffer[i])<delta) ExtBullsBearsBuffer[i]=0.0;
      
      //--- fill indicators color buffer
      if(MathAbs(_bull) > MathAbs(_bear))ExtColorBuffer[i]=0.0;  // set color Green
      else                               ExtColorBuffer[i]=1.0;  // set color Red 
      
      if(ExtBullsBearsBuffer[i]>=0.) SignalB = PLUS;
      else SignalB = MINUS;
        
      if(ExtBullsBearsBuffer[i-1]>=0.) SignalA = PLUS;
      else SignalA = MINUS;


      if(SignalA != SignalB) integral[i]=ExtBullsBearsBuffer[i];
      else integral[i]=integral[i-1]+ExtBullsBearsBuffer[i];
     }
     
   for(int avgbar=first; avgbar<rates_total; avgbar++)
     { 
        AverageBuffer1[avgbar]= Average(avgbar, AvgPeriod1, AbsExtBullsBearsBuffer)*MultiFactor; 
        mAverageBuffer1[avgbar] = -1.* AverageBuffer1[avgbar];               
     }  

//--- return value of prev_calculated for next call
   return(rates_total);
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