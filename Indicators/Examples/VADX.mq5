//+------------------------------------------------------------------+
//|                                                         VADX.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

// #include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
//#property indicator_type1   DRAW_LINE
//#property indicator_color1  LightSeaGreen
//#property indicator_style1  STYLE_SOLID
//#property indicator_width1  1
#property indicator_type1   DRAW_LINE
#property indicator_color1  YellowGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_type2   DRAW_LINE
#property indicator_color2  Wheat
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//#property indicator_label1  "ADX"
#property indicator_label1  "+DI"
#property indicator_label2  "-DI"
//--- input parameters
input int InpPeriodADX=14; // Period ADX
//--- indicator buffers
//double    ExtADXBuffer[];
double    ExtPDIBuffer[];
double    ExtNDIBuffer[];
double    ExtPDBuffer[];
double    ExtNDBuffer[];
//double    ExtTmpBuffer[];

int       ExtADXPeriod;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input parameters
   if(InpPeriodADX>=100 || InpPeriodADX<=0)
     {
      ExtADXPeriod=14;
      PrintFormat("Incorrect value for input variable Period_ADX=%d. Indicator will use value=%d for calculations.",InpPeriodADX,ExtADXPeriod);
     }
   else
      ExtADXPeriod=InpPeriodADX;
//--- indicator buffers
//   SetIndexBuffer(0,ExtADXBuffer);
   SetIndexBuffer(0,ExtPDIBuffer);
   SetIndexBuffer(1,ExtNDIBuffer);
   SetIndexBuffer(2,ExtPDBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtNDBuffer,INDICATOR_CALCULATIONS);
//   SetIndexBuffer(5,ExtTmpBuffer,INDICATOR_CALCULATIONS);
//--- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- set draw begin
//   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtADXPeriod<<1);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtADXPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtADXPeriod);
//--- indicator short name
   string short_name="VAD("+string(ExtADXPeriod)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//   PlotIndexSetString(0,PLOT_LABEL,short_name);
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
//--- checking for bars count
   if(rates_total<ExtADXPeriod)
      return(0);
//--- detect start position
   int start;
   if(prev_calculated>1)
      start=prev_calculated-1;
   else
     {
      start=1;
      ExtPDIBuffer[0]=0.0;
      ExtNDIBuffer[0]=0.0;
//      ExtADXBuffer[0]=0.0;
     }
//--- main cycle
   for(int i=start; i<rates_total && !IsStopped(); i++)
     {
      //--- get some data
      double high_price=high[i];
      double prev_high =high[i-1];
      double low_price =low[i];
      double prev_low  =low[i-1];
      double prev_close=close[i-1];
      //--- fill main positive and main negative buffers
      double tmp_pos=high_price-prev_high;
      double tmp_neg=prev_low-low_price;
      if(tmp_pos<0.0)
         tmp_pos=0.0;
      if(tmp_neg<0.0)
         tmp_neg=0.0;
      if(tmp_pos>tmp_neg)
         tmp_neg=0.0;
      else
        {
         if(tmp_pos<tmp_neg)
            tmp_pos=0.0;
         else
           {
            tmp_pos=0.0;
            tmp_neg=0.0;
           }
        }
      //--- define TR
      double tr=MathMax(MathMax(MathAbs(high_price-low_price),MathAbs(high_price-prev_close)),MathAbs(low_price-prev_close));
      if(tr!=0.0)
        {
         ExtPDBuffer[i]=100.0*tmp_pos/tr;
         ExtNDBuffer[i]=100.0*tmp_neg/tr;
        }
      else
        {
         ExtPDBuffer[i]=0.0;
         ExtNDBuffer[i]=0.0;
        }
      //--- fill smoothed positive and negative buffers
      ExtPDIBuffer[i]= VEMA_Func1(i,ExtPDBuffer, tick_volume, ExtADXPeriod);
      ExtNDIBuffer[i]= VEMA_Func2(i,ExtNDBuffer, tick_volume, ExtADXPeriod);  
      //--- fill ADXTmp buffer
//      double tmp=ExtPDIBuffer[i]+ExtNDIBuffer[i];
//      if(tmp!=0.0)
//         tmp=100.0*MathAbs((ExtPDIBuffer[i]-ExtNDIBuffer[i])/tmp);
//      else
//         tmp=0.0;
//      ExtTmpBuffer[i]=tmp;
      //--- fill smoothed ADX buffer
//      ExtADXBuffer[i]=ExponentialMA(i,ExtADXPeriod,ExtADXBuffer[i-1],ExtTmpBuffer);
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+


double VEMA_Func1(const int pPosition, double &pPrice[], const long &pVolume[], const int pPeriods)
  {

      double currentEnum = 0.;
      static double prevEnum = 0.;
      double currentNum = 0.;
      static double prevNum = 0.;
      double VWAP = 0.;
      double smoothingFactor = 2./((double)pPeriods +1.);
      
      if(pPosition == 0)
      {
         VWAP = pPrice[pPosition];
         prevEnum = 0.;
         prevNum = 0.;
      }
      else
      {
         currentEnum = smoothingFactor * pPrice[pPosition] * (double)pVolume[pPosition] +
                        (1. - smoothingFactor) * prevEnum ;
         currentNum = smoothingFactor * (double)pVolume[pPosition] + (1. - smoothingFactor) * prevNum ; 
         
         VWAP = currentEnum / currentNum;
         prevEnum = currentEnum;
         prevNum = currentNum;     
      }  
   return(VWAP);
  }  
  
double VEMA_Func2(const int pPosition, double &pPrice[], const long &pVolume[], const int pPeriods)
  {

      double currentEnum = 0.;
      static double prevEnum = 0.;
      double currentNum = 0.;
      static double prevNum = 0.;
      double VWAP = 0.;
      double smoothingFactor = 2./((double)pPeriods +1.);
      
      if(pPosition == 0)
      {
         VWAP = pPrice[pPosition];
         prevEnum = 0.;
         prevNum = 0.;
      }
      else
      {
         currentEnum = smoothingFactor * pPrice[pPosition] * (double)pVolume[pPosition] +
                        (1. - smoothingFactor) * prevEnum ;
         currentNum = smoothingFactor * (double)pVolume[pPosition] + (1. - smoothingFactor) * prevNum ; 
         
         VWAP = currentEnum / currentNum;
         prevEnum = currentEnum;
         prevNum = currentNum;     
      }  
   return(VWAP);
  }  
  