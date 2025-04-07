//+------------------------------------------------------------------+
//|                                           Ticks Volume Indicator |
//|                                         Copyright ?William Blau |
//|                                    Coded/Verified by Profitrader |
//+------------------------------------------------------------------+
#property copyright "Copyright ?2006, Profitrader."
#property link      "profitrader@inbox.ru"

#property indicator_separate_window

#property indicator_buffers 5
#property indicator_plots   1
//--- plot Line 1
#property indicator_label1  "DT 1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

input int InpPeriod = 180;

//---- buffers
double      relativeTicks[], absoluteTicks[], relativePips[], absolutePips[], 
            averageTicks[];

string fileName;
int fileh =-1, bar=0;
bool startCounting=true;

struct TickStruct
{
   datetime time;
   double   rTicks;
   double   aTicks;
   double   rPips;
   double   aPips;   
};
TickStruct tick; 




//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {

   string label="RTicks-Average: "+ IntegerToString(InpPeriod);
   IndicatorSetString(INDICATOR_SHORTNAME,label);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,0.5); 
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,-0.5); 

   SetIndexBuffer(0,relativeTicks, INDICATOR_CALCULATIONS);
   SetIndexBuffer(1,absoluteTicks, INDICATOR_CALCULATIONS); 
   SetIndexBuffer(2,relativePips, INDICATOR_CALCULATIONS);  
   SetIndexBuffer(3,absolutePips, INDICATOR_CALCULATIONS);  
   SetIndexBuffer(4,averageTicks,INDICATOR_DATA); 
   PlotIndexSetString(4,PLOT_LABEL, "AverageRTicks: "+ IntegerToString(InpPeriod));

   ArrayInitialize(relativeTicks,0.);
   ArrayInitialize(absoluteTicks,0.);
   ArrayInitialize(relativePips,0.);
   ArrayInitialize(absolutePips,0.);
   ArrayInitialize(averageTicks,0.);
   

//==============================================================   
   
   fileName =  StringConcatenate(_Symbol +"_M1"+".bin");
   fileh = FileOpen(fileName,FILE_BIN|FILE_READ);
   if(fileh<1)
   {
      int lasterror = GetLastError();
      Alert("File Open Error");
      return(false);
   }   
   
   FileSeek(fileh, 0, SEEK_SET);  
   
   tick.rTicks=0.0;
   tick.aTicks=0.0;
   tick.rPips=0.0;
   tick.aPips=0.0;
   
   
   return(0);
  }
  
  
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {

   if(fileh>0) FileClose(fileh);

   return(0);
  }
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{


   if(startCounting)
   {
      readTickFile();
      averageArray(int rates_total, int prev_calculated);
      startCounting = false;
   }
   


   if(Bars(_Symbol,_Period)<rates_total) return(prev_calculated);

   return(rates_total);
}  
//+------------------------------------------------------------------+
//| Ticks Volume Indicator                                           |
//+------------------------------------------------------------------+
int start()
  {



   if(startCounting == 0)
   {
      readTickFile();
      averageArray();
      if(fileh>0) FileClose(fileh);
   }
   
   startCounting++; 

   
   
   return(0);
  }
//+------------------------------------------------------------------+

int averageArray(int rates_total, int prev_calculated)
  {

     for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
     {
        averageTicks1[i]=iMAOnArray(relativeTicks,0,InpPeriod,0,MODE_SMA,i);
  }
   return(0);
  }
//+------------------------------------------------------------------+


void readTickFile()
{
   int barPosition ;
   datetime chartTime = iTime(_Symbol, _Period, 0);
   
   while(nextTick())
   {
      if(tick.time >= chartTime)
      {
         barPosition = iBarShift(_Symbol, _Period, tick.time);
         relativeTicks[barPosition] += tick.rTicks;
         absoluteTicks[barPosition] += tick.aTicks;
         relativePips[barPosition] += tick.rPips;
         absolutePips[barPosition] += tick.aPips;
      }  
   }
}


void SaveTickFile()
{
   int value1 = FileWriteDouble(fileh, (double)tick.time, DOUBLE_VALUE); 
       value1 = FileWriteDouble(fileh,  tick.rTicks, DOUBLE_VALUE);
       value1 = FileWriteDouble(fileh,  tick.aTicks, DOUBLE_VALUE); 
       value1 = FileWriteDouble(fileh,  tick.rPips, DOUBLE_VALUE);
       value1 = FileWriteDouble(fileh,  tick.aPips, DOUBLE_VALUE);   
}


bool nextTick()
{
   ResetLastError();
   
   tick.time = (datetime)FileReadDouble(fileh, DOUBLE_VALUE);
   if(GetLastError() != ERR_NO_ERROR){ FileSeek(fileh, 0, SEEK_END); return(false); }

   tick.rTicks = FileReadDouble(fileh, DOUBLE_VALUE);
   if(GetLastError() != ERR_NO_ERROR){ FileSeek(fileh, 0, SEEK_END); return(false); }
   
   tick.aTicks = FileReadDouble(fileh, DOUBLE_VALUE);
   if(GetLastError() != ERR_NO_ERROR){ FileSeek(fileh, 0, SEEK_END); return(false); }

   tick.rPips = FileReadDouble(fileh, DOUBLE_VALUE);
   if(GetLastError() != ERR_NO_ERROR){ FileSeek(fileh, 0, SEEK_END); return(false); }

   tick.aPips = FileReadDouble(fileh, DOUBLE_VALUE);
   if(GetLastError() != ERR_NO_ERROR){ FileSeek(fileh, 0, SEEK_END); return(false); }
   
   return(true);
}
