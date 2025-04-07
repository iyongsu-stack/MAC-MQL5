//+------------------------------------------------------------------+
//|                                            AdvancedFractalV3.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4
//--- plot UpFactal Long
#property indicator_label1 "Factal Up Long"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrAqua
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot DownFractal Long
#property indicator_label2  "Fractal Down"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- plot UpFactal Short
#property indicator_label3 "Factal Up Short"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrAqua
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot DownFractal Short
#property indicator_label4  "Fractal Down Short"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrRed
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- input parameters
input uint     longFrames=50;   // Frames
input uint     shortFrames=10;   // Frames

//--- indicator buffers
double         BufferUpFactalLong[];
double         BufferDownFractalLong[];
double         BufferUpFactalShort[];
double         BufferDownFractalShort[];
//--- global variables
int            longframes, shortframes;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- settings parameters
   longframes=int(longFrames<1 ? 1 : longFrames);
   shortframes=int(shortFrames<1 ? 1 : shortFrames);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferUpFactalLong,INDICATOR_DATA);
   SetIndexBuffer(1,BufferDownFractalLong,INDICATOR_DATA);
   SetIndexBuffer(2,BufferUpFactalShort,INDICATOR_DATA);
   SetIndexBuffer(3,BufferDownFractalShort,INDICATOR_DATA);

//--- setting a buffers parameters
   PlotIndexSetInteger(0,PLOT_ARROW,234);
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,10);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetInteger(1,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,7);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetInteger(2,PLOT_ARROW,119);
   PlotIndexSetInteger(2,PLOT_LINE_WIDTH,10);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetInteger(3,PLOT_ARROW,119);
   PlotIndexSetInteger(3,PLOT_LINE_WIDTH,7);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);
   
//--- strings parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"Advanced fractals("+(string)longframes+", "+(string)shortframes+")");
//---
   return(INIT_SUCCEEDED);
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
//--- Checking for minimum number of bars
   int first, second;
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=longframes;
      ArrayInitialize(BufferUpFactalLong,0.0);
      ArrayInitialize(BufferDownFractalLong,0.0);
      second = shortframes;
      ArrayInitialize(BufferUpFactalShort,0.0);
      ArrayInitialize(BufferDownFractalShort,0.0);
      
     }
   else 
    {
      first=prev_calculated-longframes-1; // starting number for calculation of new bars
      second = prev_calculated-shortframes-1;
    }  


//--- Calculate indicator
   for(int i=first; i<rates_total && !IsStopped(); i++)
     {
      bool FrUpLong=true;
      bool FrDnLong=true;
      for(int n=1; n<=longframes; n++)
        {


         if(high[i-n]>=high[i]) FrUpLong=false;
         if(low[i-n]<=low[i]) FrDnLong=false;
        }
      //----Fractals up
      if(FrUpLong)
         BufferUpFactalLong[i]=high[i];
      //----Fractals down
      if(FrDnLong)
         BufferDownFractalLong[i]=low[i];
     }

   for(int i=second; i<rates_total && !IsStopped(); i++)
     {
      bool FrUpShort=true;
      bool FrDnShort=true;
      for(int n=1; n<=shortframes; n++)
        {
         if( high[i-n]>=high[i]) FrUpShort=false;
         if( low[i-n]<=low[i]) FrDnShort=false;
        }
      //----Fractals up
      if(FrUpShort)
         BufferUpFactalShort[i]=high[i];
      //----Fractals down
      if(FrDnShort)
         BufferDownFractalShort[i]=low[i];
     }     
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+--------------