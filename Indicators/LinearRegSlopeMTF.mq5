//+------------------------------------------------------------------+
//|                                            LinearRegSlopeMTF.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_chart_window 
//---- number of indicator buffers 2
#property indicator_buffers 2 
//---- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type1   DRAW_FILLING
//---- the following colors are used for the indicator
#property indicator_color1 Coral,DodgerBlue
//---- displaying the indicator label
#property indicator_label1  "Linear Reg Slope"

//+-----------------------------------+
//|  CXMA class description           |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+
//---- declaration of the CXMA class variables from the SmoothAlgorithms.mqh file
CXMA XMA1;
//+-----------------------------------+
//|  Declaration of enumerations          |
//+-----------------------------------+
enum Applied_price_ //Type od constant
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPL_,         //Simpl Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_   //TrendFollow_2 Price 
  };



//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+

input ENUM_TIMEFRAMES      TimeFrame         =            PERIOD_H1;
input Smooth_Method SlMethod=MODE_SMA; //smoothing method
input int SlLength=12; //smoothing depth                    
input int SlPhase=15; //smoothing parameter,
                      // for JJMA that can change withing the range -100 ... +100. It impacts the quality of the intermediate process of smoothing;
// For VIDIA, it is a CMO period, for AMA, it is a slow moving average period
input Applied_price_ IPC=PRICE_CLOSE;//price constant
/* , used for calculation of the indicator ( 1-CLOSE, 2-OPEN, 3-HIGH, 4-LOW, 
  5-MEDIAN, 6-TYPICAL, 7-WEIGHTED, 8-SIMPL, 9-QUARTER, 10-TRENDFOLLOW, 11-0.5 * TRENDFOLLOW.) */
input int Shift=0; // horizontal shift of the indicator in bars
input int TriggerShift=1; // bar shift for the trigger
//+-----------------------------------+

//---- Declaration of integer variables of data starting point
int min_rates_total;
//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double RegSlopeBuffer[],TriggerBuffer[], mtf_RegSlopeBuffer[], mtf_TriggerBuffer[];
//---- Declaration of global variables
int TriggerShift_,TrigShift,TrigShift_;
double SumX,Divisor;
//---- declaration of dynamic arrays that will further be 
// used as ring buffers
int Count[], mtf_handle;
double Smooth[];
ENUM_TIMEFRAMES  tf;



//+------------------------------------------------------------------+
//|  recalculation of position of a newest element in the array      |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos
(
 int &CoArr[],// Return the current value of the price series by the link
 int Size // number of the elements in the ring buffer
 )
// Recount_ArrayZeroPos(count, SlLength)
//+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max2=Size;
   Max1=Max2-1;

   count--;
   if(count<0) count=Max1;

   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//----
  }
//+------------------------------------------------------------------+   
//| LinearRegSlope_V2 indicator initialization function              | 
//+------------------------------------------------------------------+ 
void OnInit()
  {

   if(TimeFrame <= Period()) tf = Period(); else tf = TimeFrame; 

//---- Initialization of variables of the start of data calculation
   min_rates_total=XMA1.GetStartBars(SlMethod,1,SlPhase)+SlLength+TriggerShift;

//---- setting alerts for invalid values of external parameters
   XMA1.XMALengthCheck("SlLength", SlLength);
   XMA1.XMAPhaseCheck("SlPhase", SlPhase, SlMethod);
   if(TriggerShift>SlLength-2)
     {
      Print("TriggerShift input parameter value cannot exceed SlLength-2");
      TrigShift=1;
      TrigShift_=SlLength-2;
     }
   else
     {
      TrigShift=SlLength-1-TriggerShift;
      TrigShift_=TriggerShift;
     }

//---- Initialization of variables   
   SumX=SlLength *(SlLength-1)*0.5;
   double SumXSqr=(SlLength-1.0)*SlLength *(2.0*SlLength-1.0)/6.0;
   Divisor=SumX*SumX-SlLength*SumXSqr;
   TriggerShift_=int(min_rates_total);

//---- memory distribution for variables' arrays  
   ArrayResize(Count,SlLength);
   ArrayResize(Smooth,SlLength);

//---- Initialization of arrays of variables
   ArrayInitialize(Count,0);
   ArrayInitialize(Smooth,0.0);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,RegSlopeBuffer,INDICATOR_DATA);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,TriggerBuffer,INDICATOR_DATA);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- initializations of variable for indicator short name
   string shortname;
   string Smooth1=XMA1.GetString_MA_Method(SlMethod);
   StringConcatenate(shortname,"Linear Reg Slope(",SlLength,", ",Smooth1,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//--- determining the accuracy of displaying the indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- end of initialization

   if(TimeFrame > 0) 
   {
      mtf_handle = iCustom(Symbol(),TimeFrame,"LinearRegSlopeMTF",TimeFrame,SlMethod,SlLength,SlPhase,
                           IPC,Shift,TriggerShift );
   }

  }
//+------------------------------------------------------------------+ 
//| LinearRegSlope_V2 iteration function                             | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &Time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {



//---- checking the number of bars to be enough for calculation
   if(rates_total<min_rates_total) return(0);

//---- declaration of variables with a floating point  
   double price_,SumY,SumXY,Intercept,Slope;
//---- Declaration of integer variables and getting the bars already calculated
   int first,bar,iii, mtflimit, shift, x, y, copied;   
   datetime mtf_time;

   


   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=0; // starting number for calculation of all bars
      mtflimit = rates_total - 1;
     }
   else 
   {      
      first=prev_calculated-1; // starting number for calculation of new bars
      mtflimit = PeriodSeconds(tf)/PeriodSeconds(Period());
   }

//--- the main loop of calculations
   if(tf > Period())
   {
      ArraySetAsSeries(Time,true);   
  
      for(shift=0,y=0;shift<mtflimit;shift++)
      {
         if(Time[shift] < iTime(NULL,TimeFrame,y)) y++; 
         mtf_time = iTime(NULL,TimeFrame,y);
      
         x = rates_total - shift - 1;
         
         copied = CopyBuffer(mtf_handle,0,mtf_time,mtf_time,mtf_RegSlopeBuffer);
         if(copied <= 0) return(0);
      
         copied = CopyBuffer(mtf_handle,1,mtf_time,mtf_time,mtf_TriggerBuffer);
         if(copied <= 0) return(0) ;
  
         RegSlopeBuffer[x] = mtf_RegSlopeBuffer[0];
         TriggerBuffer[x] = mtf_TriggerBuffer[0];
      }
   }
   else
   {

//---- Main calculation loop of the indicator
      for(bar=first; bar<rates_total && !IsStopped(); bar++)
        {
      //---- Calling the PriceSeries function to get the input price price_
         price_=PriceSeries(IPC,bar,open,low,high,close);
         Smooth[Count[0]]=XMA1.XMASeries(0,prev_calculated,rates_total,SlMethod,SlPhase,SlLength,price_,bar,false);

         SumY=0.0;
         SumXY=0.0;

         if(bar>=SlLength)
            for(iii=0; iii<SlLength; iii++)
              {
               SumY+=Smooth[Count[iii]];
               SumXY+=iii*Smooth[Count[iii]];
              }

         if(Divisor) Slope=(SlLength*SumXY-SumX*SumY)/Divisor;
         else        Slope=EMPTY_VALUE;

         if(bar>=SlLength)
           {
            Intercept=(SumY-Slope*SumX)/SlLength;
            RegSlopeBuffer[bar]=Intercept+Slope*TrigShift;
           }

         if(bar>TriggerShift_) TriggerBuffer[bar]=2.0*RegSlopeBuffer[bar]-RegSlopeBuffer[bar-TrigShift_];
         else                  TriggerBuffer[bar]=EMPTY_VALUE;

         //---- recalculation of the elements positions in the Smooth[] ring buffer
         if(bar<rates_total-1) Recount_ArrayZeroPos(Count,SlLength);
        }
   }     
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
