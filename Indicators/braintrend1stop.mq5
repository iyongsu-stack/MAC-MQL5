//+------------------------------------------------------------------+
//|                                              BrainTrend1Stop.mq5 |
//|                               Copyright © 2005, BrainTrading Inc |
//|                                      http://www.braintrading.com |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2005, BrainTrading Inc."
//---- link to the website of the author
#property link      "http://www.braintrading.com/"
//---- Indicator Version Number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- four buffers are used for calculation and drawing the indicator
#property indicator_buffers 4
//---- only four plots are used
#property indicator_plots   4
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- magenta color is used as the color of the bearish indicator line
#property indicator_color1  Magenta
//---- thickness of line of the indicator 1 is equal to 1
#property indicator_width1  1
//---- displaying of the bearish label of the indicator
#property indicator_label1  "Brain1Sell"
//+----------------------------------------------+
//|  Parameters of drawing the bullish indicator |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- cyan color is used as the color of the bullish line of the indicator
#property indicator_color2  Cyan
//---- thickness of line of the indicator 2 is equal to 1
#property indicator_width2  1
//---- displaying of the bullish label of the indicator
#property indicator_label2 "Brain1Buy"
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing the indicator 3 as a symbol
#property indicator_type3   DRAW_LINE
//---- magenta color is used as the color of the bearish indicator line
#property indicator_color3  Magenta
//---- thickness of line of the indicator 3 is equal to 1
#property indicator_width3  1
//---- Indicator line is a solid one
#property indicator_style3 STYLE_SOLID
//---- Indicator line width is equal to 2
#property indicator_width3 2
//---- displaying of the bearish label of the indicator
#property indicator_label3  "Brain1Sell"
//+----------------------------------------------+
//|  Parameters of drawing the bullish indicator |
//+----------------------------------------------+
//---- drawing the indicator 4 as a symbol
#property indicator_type4   DRAW_LINE
//---- cyan color is used as the color of the bullish line of the indicator
#property indicator_color4  Cyan
//---- thickness of line of the indicator 4 is equal to 1
#property indicator_width4  1
//---- Indicator line is a solid one
#property indicator_style4 STYLE_SOLID
//---- Indicator line width is equal to 2
#property indicator_width4 2
//---- displaying of the bullish label of the indicator
#property indicator_label4 "Brain1Buy"

//+----------------------------------------------+
//| Input parameters of the indicator            |
//+----------------------------------------------+
input int ATR_Period=7; //Period of ATR 
input int STO_Period=9; //Period of Stochastic
input ENUM_MA_METHOD MA_Method=MODE_SMA; ///Method of averaging
input ENUM_STO_PRICE STO_Price=STO_LOWHIGH; //Method of prices calculation 
input int Stop_dPeriod=3; //Period expansion for a stop
//+----------------------------------------------+

//---- declaration of dynamic arrays that further 
// will be used as indicator buffers
double SellStopBuffer[];
double BuyStopBuffer[];
double SellStopBuffer_[];
double BuyStopBuffer_[];
//---
double d,s,r,R_;
int p,x1,x2,P_,StartBars;
int ATR_Handle,ATR1_Handle,STO_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- initialization of global variables 
   d=2.3;
   s=1.5;
   x1 = 53;
   x2 = 47;
   StartBars=(int)MathMax(MathMax(ATR_Period,STO_Period),ATR_Period+Stop_dPeriod)+2;
//---- getting handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");
//---- getting handle of the ATR indicator
   ATR1_Handle=iATR(NULL,0,ATR_Period+Stop_dPeriod);
   if(ATR1_Handle==INVALID_HANDLE)Print(" Failed to get handle of the indicator ATR1");
//---- getting handle of the Stochastic indicator
   STO_Handle=iStochastic(NULL,0,STO_Period,STO_Period,1,MA_Method,STO_Price);
   if(STO_Handle==INVALID_HANDLE)Print(" Failed to get handle of the Stochastic indicator");

//---- turning a dynamic array into an indicator buffer
   SetIndexBuffer(0,SellStopBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//--- Create label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Brain1SellStop");
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,159);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellStopBuffer,true);

//---- turning a dynamic array into an indicator buffer
   SetIndexBuffer(1,BuyStopBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//--- Create label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"Brain1BuyStop");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyStopBuffer,true);

//---- turning a dynamic array into an indicator buffer
   SetIndexBuffer(2,SellStopBuffer_,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,StartBars);
//--- Create label to display in DataWindow
   PlotIndexSetString(2,PLOT_LABEL,"Brain1SellStop");
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellStopBuffer_,true);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);

//---- turning a dynamic array into an indicator buffer
   SetIndexBuffer(3,BuyStopBuffer_,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 4
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,StartBars);
//--- Create label to display in DataWindow
   PlotIndexSetString(3,PLOT_LABEL,"Brain1BuyStop");
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyStopBuffer_,true);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);

//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and for the label of sub-windows 
   string short_name="BrainTrend1Stop";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
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
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(ATR_Handle)<rates_total
      || BarsCalculated(STO_Handle)<rates_total
      || rates_total<StartBars)
      return(0);

//---- declaration of local variables 
   int to_copy,limit,bar;
   double range,range1,val1,val2,val3;
   double value2[],Range[],Range1[],value3,value4,value5;

//--- calculations of the necessary amount of data to be copied and
//the limit starting number for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      to_copy=rates_total; // calculated number of all bars
      limit=rates_total-StartBars; // starting number for calculation of all bars
     }
   else
     {
      to_copy=rates_total-prev_calculated+1; // calculated number of new bars
      limit=rates_total-prev_calculated; // starting number for calculation of new bars
     }

//---- copy the newly appeared data into the Range[], Range1[] and value2[] arrays
   if(CopyBuffer(ATR_Handle,0,0,to_copy,Range)<=0) return(0);
   if(CopyBuffer(STO_Handle,0,0,to_copy,value2)<=0) return(0);
   if(CopyBuffer(ATR1_Handle,0,0,to_copy,Range1)<=0) return(0);

//---- indexing elements in arrays, as in timeseries  
   ArraySetAsSeries(Range,true);
   ArraySetAsSeries(Range1,true);
   ArraySetAsSeries(value2,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

//---- restore values of the variables
   p=P_;
   r=R_;

//---- main cycle of calculation of the indicator
   for(bar=limit; bar>=0; bar--)
     {
      //---- memorize values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         P_=p;
         R_=r;
        }
      range=Range[bar]/d;
      range1=Range1[bar]*s;

      val1 = 0.0;
      val2 = 0.0;
      val3=MathAbs(close[bar]-close[bar+2]);

      SellStopBuffer[bar]=0.0;
      BuyStopBuffer[bar]=0.0;
      SellStopBuffer_[bar]=0.0;
      BuyStopBuffer_[bar]=0.0;

      if(val3>range)
        {
         if(value2[bar]<x2 && p!=1)
           {
            value3=high[bar]+range1/4;
            val1=value3;
            p = 1;
            r = val1;
            SellStopBuffer[bar]=val1;
            SellStopBuffer_[bar]=val1;
           }

         if(value2[bar]>x1 && p!=2)
           {
            value3=low[bar]-range1/4;
            val2=value3;
            p = 2;
            r = val2;
            BuyStopBuffer[bar]=val2;
            BuyStopBuffer_[bar]=val2;
           }
        }

      value4 = high[bar] + range1;
      value5 = low [bar] - range1;

      if(val1==0 && val2==0)
        {
         if(p==1)
           {
            if(value4<r) r=value4;
            SellStopBuffer[bar]=r;
            SellStopBuffer_[bar]=r;
           }

         if(p==2)
           {
            if(value5>r) r=value5;
            BuyStopBuffer[bar]=r;
            BuyStopBuffer_[bar]=r;
           }
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+