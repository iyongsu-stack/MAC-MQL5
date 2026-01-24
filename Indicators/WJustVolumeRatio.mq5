//+------------------------------------------------------------------+
//|                                             WJustVolumeRatio.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
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
#property indicator_plots   1

//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
//---- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//#property indicator_type2   DRAW_LINE
//#property indicator_type3   DRAW_HISTOGRAM



#property indicator_color1  clrAqua
//#property indicator_color2  clrRed

//---- the line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
//#property indicator_style2  STYLE_SOLID

//---- indicator 1 line width is equal to 1
#property indicator_width1  1
//#property indicator_width2  1

#property indicator_level1 2.0

#property indicator_level2 1.0

#property indicator_level3 0.5





input ENUM_APPLIED_VOLUME VolumeType    = VOLUME_REAL;  // Volume Type
input int                 ShortPeriod = 30;           // Average Period
input int                 LongPeriod = 4320;           // Average Period1


//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double shortBuffer[], longBuffer[], ratio[];
//---- declaration of the integer variables for the start of data calculation
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
   SetIndexBuffer(0,ratio,INDICATOR_DATA); 
   SetIndexBuffer(1,shortBuffer,INDICATOR_CALCULATIONS); 
   SetIndexBuffer(2,longBuffer,INDICATOR_CALCULATIONS); 
   

   string shortname;
   StringConcatenate(shortname,"JustVolumeRatio(",ShortPeriod,", ", LongPeriod, ")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   
     
   ArrayInitialize(ratio, 0.);
   ArrayInitialize(shortBuffer, 0.);
   ArrayInitialize(longBuffer, 0.);

   
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

   int first, second;


//---- calculation of the 'first' starting number for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first = ShortPeriod+1;       
      second =  LongPeriod+1;   
     }
   else
     {     
       first=prev_calculated-1; // starting number for calculation of new bars 
       second = prev_calculated-1; 

     } 
   for(int avgbar=first; avgbar<rates_total; avgbar++)
     {
 
        shortBuffer[avgbar]= Average(avgbar, ShortPeriod, tick_volume); 
     }

   for(int avgbar=second; avgbar<rates_total; avgbar++)
     { 
        longBuffer[avgbar]= Average(avgbar, LongPeriod, tick_volume); 
        ratio[avgbar] = (shortBuffer[avgbar]/longBuffer[avgbar]);                
     }


   
   return(rates_total);
  }
//+-------------------------------------




double Average(int end, int avgPeriod, const long &S_Array[])
{
    long sum;
    sum=0.0;
      
    for(int i=end+1-avgPeriod;i<=end;i++)
    {
          sum+=S_Array[i];
    }
       
    return(double(sum/avgPeriod));

}



double LinearRegression(int end, int exPeriod, const double &S_Array[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=end+1-exPeriod;i<=end;i++)
         {
          sumX+=X;
          sumY+=S_Array[i];
          sumXY+=X*S_Array[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-exPeriod*sumXY)/(MathPow(sumX,2)-exPeriod*sumX2);
       b=(sumY-a*sumX)/exPeriod;


      return(a);

}