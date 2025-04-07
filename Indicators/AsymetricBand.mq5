//+------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property description "Asymmetric bands"
//+------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   3
#property indicator_label1  "Band up"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLimeGreen
#property indicator_label2  "Average"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDarkGray
#property indicator_style2  STYLE_DOT
#property indicator_label3  "Band down"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrOrangeRed
//--- input parameters
input int                inpBandPeriod     = 14;          // Bands period
input ENUM_APPLIED_PRICE inpBandPrice      = PRICE_CLOSE; // Price
input ENUM_MA_METHOD     inpBandMethod     = MODE_SMA;    // Bands average method
input double             inpBandDeviations = 2;           // Bands deviation
//--- buffers declarations
double valu[],vald[],vala[],wu[],wd[];
//--- indicator handles
int _maHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,valu,INDICATOR_DATA);
   SetIndexBuffer(1,vala,INDICATOR_DATA);
   SetIndexBuffer(2,vald,INDICATOR_DATA);
   SetIndexBuffer(3,wu,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,wd,INDICATOR_CALCULATIONS);
   _maHandle=iMA(_Symbol,0,inpBandPeriod,0,inpBandMethod,inpBandPrice); if(_maHandle==INVALID_HANDLE) { return(INIT_FAILED); }
//---
   IndicatorSetString(INDICATOR_SHORTNAME,"Asymmetric bands ("+(string)inpBandPeriod+")");
//---
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
double _avgVal[1];
//
//---
//
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(Bars(_Symbol,_Period)<rates_total) return(prev_calculated);
   if(BarsCalculated(_maHandle)<rates_total) return(prev_calculated);
   int i=(int)MathMax(prev_calculated-1,1); for(; i<rates_total && !_StopFlag; i++)
     {
      double price=getPrice(inpBandPrice,open,close,high,low,i,rates_total);
      int _avgCopied=CopyBuffer(_maHandle,0,time[i],1,_avgVal);
      vala[i]=(_avgCopied==1) ? _avgVal[0]: 0;
      double diff=price-vala[i];
      if(diff>0)
        {
         wu[i] = (i>inpBandPeriod) ? (wu[i-1]*(inpBandPeriod-1)+diff*diff)/inpBandPeriod : 0;
         wd[i] = (i>inpBandPeriod) ?  wd[i-1]*(inpBandPeriod-1)/inpBandPeriod : 0;
        }
      else
        {
         wd[i] = (i>inpBandPeriod) ? (wd[i-1]*(inpBandPeriod-1)+diff*diff)/inpBandPeriod : 0;
         wu[i] = (i>inpBandPeriod) ?  wu[i-1]*(inpBandPeriod-1)/inpBandPeriod : 0;
        }
      valu[i] = vala[i] + inpBandDeviations*MathSqrt(wu[i]);
      vald[i] = vala[i] - inpBandDeviations*MathSqrt(wd[i]);
     }
   return (i);
  }
//+------------------------------------------------------------------+
//| custom functions                                                 |
//+------------------------------------------------------------------+
double getPrice(ENUM_APPLIED_PRICE tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i,int _bars)
  {
   switch(tprice)
     {
      case PRICE_CLOSE:     return(close[i]);
      case PRICE_OPEN:      return(open[i]);
      case PRICE_HIGH:      return(high[i]);
      case PRICE_LOW:       return(low[i]);
      case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
      case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
      case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
     }
   return(0);
  }
//+----------