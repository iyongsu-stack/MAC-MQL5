//+------------------------------------------------------------------+
//|                                                      inertia.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"

#property indicator_separate_window

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   1
#property indicator_label1  "Inertia"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrOrangeRed
#property indicator_width1  2


//
//
//
//
input int RVIPeriod       = 10;
input int AvgPeriod       = 14;
input int SmoothingPeriod = 20;

//
//
//
//
//

double InertiaBuffer[];
double bufferiHUp[];
double bufferiHDo[];
double bufferiLUp[];
double bufferiLDo[];
double bufferiRvi[];
double stdDevHigh[], stdDevLow[];

int stdDevHighHandle, stdDevLowHandle;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,InertiaBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,bufferiHUp,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,bufferiHDo,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,bufferiLUp,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,bufferiLDo,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,bufferiRvi,INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME,"Dorsey inertia ("+(string)RVIPeriod+","+(string)SmoothingPeriod+")");
   stdDevHighHandle = iStdDev(NULL,0,RVIPeriod,0,MODE_SMA,PRICE_HIGH);
   stdDevLowHandle = iStdDev(NULL,0,RVIPeriod,0,MODE_SMA,PRICE_LOW);
   return(0);
}


//
//
//
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

   int counted_bars=prev_calculated;
   int start, r,i;

   
   if(prev_calculated>1)
   {
      start=prev_calculated-1;
      CopyBuffer(stdDevHighHandle, 0, 0, 3, stdDevHigh );
      CopyBuffer(stdDevLowHandle, 0, 0, 3, stdDevLow );   
      
   }
   else
   {
      if(RVIPeriod>=SmoothingPeriod) start = RVIPeriod;
      else start = SmoothingPeriod;
      
      CopyBuffer(stdDevHighHandle, 0, 0, rates_total, stdDevHigh );
      CopyBuffer(stdDevLowHandle, 0, 0, rates_total, stdDevLow );   

      for(int l = 0; l < start ; l++)
      {
         bufferiHUp[l]=0;
         bufferiHDo[l]=0;
         bufferiLUp[l]=0;
         bufferiLDo[l]=0;
         bufferiRvi[l]=0;      
         InertiaBuffer[l]=0;
      }

   }
//--- main cycle
//   for(int i=start; i<rates_total && !IsStopped(); i++)


   
   
   for(i=start; i<rates_total; i++)
   {
      double stdDev = stdDevHigh[i]; 
      double u      = 0;
      double d      = 0;
      
         if (high[i]>high[i-1]) u = stdDev;
         if (high[i]<high[i-1]) d = stdDev;
         
         bufferiHUp[i] = ((AvgPeriod-1.0)*bufferiHUp[i-1]+u)/AvgPeriod;
         bufferiHDo[i] = ((AvgPeriod-1.0)*bufferiHDo[i-1]+d)/AvgPeriod;

      //
      //
      //
      //
      //
      
      stdDev = stdDevLow[i];
      u      = 0;
      d      = 0;
            
         if (low[i]>low[i-1]) u = stdDev;
         if (low[i]<low[i-1]) d = stdDev;
         
         bufferiLUp[r] = ((AvgPeriod-1.0)*bufferiLUp[i-1]+u)/AvgPeriod;
         bufferiLDo[r] = ((AvgPeriod-1.0)*bufferiLDo[i-1]+d)/AvgPeriod;
        
      //
      //
      //
      //
      //
 
         double rvih = 0.0;
         double rvil = 0.0;

         if((bufferiHUp[i]+bufferiHDo[i]) != 0.0) rvih = 100.00*bufferiHUp[i]/(bufferiHUp[i]+bufferiHDo[i]);
         if((bufferiLUp[i]+bufferiLDo[i]) != 0.0) rvil = 100.00*bufferiLUp[i]/(bufferiLUp[i]+bufferiLDo[i]);
              
         bufferiRvi[i] = (rvih+rvil)/2.0;

      //
      //
      //
      //
      //
               
         double sum = 0;
         for (int k=0; k< SmoothingPeriod; k++) sum += bufferiRvi[i-k];
                               InertiaBuffer[i] = sum / SmoothingPeriod;
   }
   
   //
   //
   //
   //
   //
   
   return(0);
}