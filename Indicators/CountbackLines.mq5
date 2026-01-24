//+------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property description "Countback lines"
//+------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_label1  "Hi"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDeepSkyBlue
#property indicator_width1  2
#property indicator_label2  "Low"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_width2  2
//--- input parameters
input int  inpCblPeriod=13; // Countback lines period
double cblu[],cbld[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,cblu,INDICATOR_DATA);
   SetIndexBuffer(1,cbld,INDICATOR_DATA);
//--- indicator short name assignment
   IndicatorSetString(INDICATOR_SHORTNAME,"Countback lines ("+(string)inpCblPeriod+")");
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
   int i=(int)MathMax(prev_calculated-1,1); for(; i<rates_total && !_StopFlag; i++)
     {
      int _start= MathMax(i-inpCblPeriod+1,0);
      double hi = high[ArrayMaximum(high,_start,inpCblPeriod)];
      double lo = low [ArrayMinimum(low ,_start,inpCblPeriod)];

      cblu[i]=(i>0) ? cblu[i-1]: lo;
      while(true)
        {
         if(high[i]<hi)                                      {                        break; }
         if(checkLowStrict(2,i,low) && checkLowRef(2,i,low)) { cblu[i] = low[i-2];   break; }
         if(checkLowStrict(3,i,low) && checkLowRef(3,i,low)) { cblu[i] = low[i-3];   break; }
         if(checkLowStrict(4,i,low) && checkLowRef(4,i,low)) { cblu[i] = low[i-4];   break; }
         if(checkLowStrict(5,i,low) && checkLowRef(5,i,low)) { cblu[i] = low[i-5];   break; }
         break;
        }
      cbld[i]=(i>0) ? cbld[i-1]: hi;
      while(true)
        {
         if(low[i]>lo)                                           {                        break; }
         if(checkHighStrict(2,i,high) && checkHighRef(2,i,high)) { cbld[i] = high[i-2];   break; }
         if(checkHighStrict(3,i,high) && checkHighRef(3,i,high)) { cbld[i] = high[i-3];   break; }
         if(checkHighStrict(4,i,high) && checkHighRef(4,i,high)) { cbld[i] = high[i-4];   break; }
         if(checkHighStrict(5,i,high) && checkHighRef(5,i,high)) { cbld[i] = high[i-5];   break; }
         break;
        }
     }
   return (i);
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
bool checkLowStrict(int count, int i, const double& low[]) { int k=count-1; for(; k>=0 && (i-k)>=0 && (i-count)>=0; k--) if(low[i-count] >= low[i-k]) break;  return(k==-1); }
bool checkLowRef   (int count, int i, const double& low[]) { int k=count-1; for(; k> 0 && (i-k)>=0;                 k--) if(low[i-k]     <  low[i])   break;  return(k > 0); }
//
//---
//
bool checkHighStrict(int count, int i, const double& high[]) { int k=count-1; for(; k>=0 && (i-k)>=0 && (i-count)>=0; k--) if(high[i-count] <= high[i-k]) break;  return(k==-1); }
bool checkHighRef   (int count, int i, const double& high[]) { int k=count-1; for(; k> 0 && (i-k)>=0;                 k--) if(high[i-k]     >  high[i])   break;  return(k > 0); }
//+-------------