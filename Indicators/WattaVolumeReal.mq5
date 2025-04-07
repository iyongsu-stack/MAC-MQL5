//+------------------------------------------------------------------+
//|                                       Watta_Volume_Indicator.mq5 |
//|                                    Copyright ?2006, Profitrader | 
//|                                             profitrader@inbox.ru | 
//+------------------------------------------------------------------+
//---- Copyright
#property copyright "Copyright ?2006, Profitrader"
//---- link to the website of the author
#property link "profitrader@inbox.ru"
#property description "Volume Indicator"
//---- Indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window
//---- one buffer is used for calculation and drawing of the indicator
#property indicator_buffers 3
//---- one plot is used
#property indicator_plots   3
//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
//---- drawing indicator 1 as a line
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_type3   DRAW_HISTOGRAM


//---- Red color is used as the color of the indicator line
#property indicator_color1  clrGreen
#property indicator_color2  clrRed
#property indicator_color3  clrYellow

//---- the line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID


//---- indicator 1 line width is equal to 1
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1

//---- displaying the indicator label
//#property indicator_label1  "Ticks"




input ENUM_APPLIED_VOLUME VolumeType=VOLUME_REAL;  // Volume

//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double p1Buffer[], p2Buffer[], p3Buffer[];
//---- declaration of the integer variables for the start of data calculation
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
   SetIndexBuffer(0,p1Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,p2Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,p3Buffer,INDICATOR_DATA);
   
   ArrayInitialize(p1Buffer, 0.);
   ArrayInitialize(p2Buffer, 0.);
   ArrayInitialize(p3Buffer, 0.);
   
   
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

   int first;


//---- calculation of the 'first' starting number for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      int smallBar=iBars(_Symbol, PERIOD_M1);
      datetime smallTime = iTime(_Symbol, PERIOD_M1, smallBar-1);
      int start = iBarShift(_Symbol, _Period, smallTime);
      first = start - 1;       
     }
   else first=rates_total-prev_calculated; // starting number for calculation of new bars



//---- The main loop of the indicator calculation
   for(int bar=first; bar>=0; bar--)
     {
      int smallNextBar, smallCurBar;
      datetime bigCurTime, bigNextTime;
      double P1=0, P2=0;

      bigCurTime = iTime(_Symbol, _Period, bar); 
      smallCurBar = iBarShift(_Symbol, PERIOD_M1, bigCurTime);

      if(bar == 0)
        {
          smallNextBar = -1;        
        }
      else if(bar > 0)
        {
          bigNextTime = iTime(_Symbol, _Period, bar-1);
          smallNextBar = iBarShift(_Symbol, PERIOD_M1, bigNextTime);        
        } 
  

      for(int i = smallCurBar; i > smallNextBar; i--)
        {
         
           long mVolume;
           if(VolumeType == VOLUME_TICK) mVolume = iTickVolume(Symbol(),PERIOD_M1,i);
           else mVolume = iVolume(Symbol(),PERIOD_M1,i);
           
           if (iClose(Symbol(),PERIOD_M1,i)>iClose(Symbol(),PERIOD_M1,i+1))
           {
             P1 = P1+mVolume;
           }
           if (iClose(Symbol(),PERIOD_M1,i)<iClose(Symbol(),PERIOD_M1,i+1))
           {
             P2 = P2-mVolume;
           }
           if (iClose(Symbol(),PERIOD_M1,i)==iClose(Symbol(),PERIOD_M1,i+1))
           {
             P1 = P1+(mVolume/2);
             P2 = P2-(mVolume/2);
           }

        } 
                
       p1Buffer[(rates_total-1-bar)]=P1;
       p2Buffer[(rates_total-1-bar)]=P2;
       p3Buffer[(rates_total-1-bar)]=P1+P2;
     }
//----     
   return(rates_total);
  }
//+-------------------------------------