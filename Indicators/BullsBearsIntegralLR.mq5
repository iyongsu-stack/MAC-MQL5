//+------------------------------------------------------------------+
//|                                         BullsBearsIntegralLR.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Shovel"
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1

//--- plot Bulls Bears Volume  
#property indicator_label1  "BUBEVO"
#property indicator_type1   DRAW_LINE
#property indicator_style1  STYLE_SOLID
#property indicator_color1  clrYellow
#property indicator_width1  1
#property indicator_level1  0.0
#property indicator_applied_price PRICE_CLOSE

//--- input parameters
input int                  InpPeriod=50;              // EMA Period
input int                  LRPeriod=5;               // LR Period
input ENUM_APPLIED_VOLUME  InpVolumeType=VOLUME_TICK; // Volumes
input double               delta=0.0;             // delta (flat level)

//--- handle of EMA
int       ExtEmaHandle;

//--- indicator buffers
double    BullsBearsIntegral[];
double    BullsBearsIntegralLR[];
double    ExtBullsBearsBuffer[];
double    ExtTempBuffer[];
double    ExtVolumesBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BullsBearsIntegralLR,INDICATOR_DATA);
   SetIndexBuffer(1,BullsBearsIntegral,INDICATOR_CALCULATIONS);   
   SetIndexBuffer(2,ExtBullsBearsBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtTempBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtVolumesBuffer,INDICATOR_CALCULATIONS);

   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpPeriod-1);
   IndicatorSetString(INDICATOR_SHORTNAME,"BullsBearsVolume("+(string)InpPeriod+"  LRPeriod: "+(string)LRPeriod+") ");


//--- get MA handle
   ExtEmaHandle=iMA(NULL,0,InpPeriod,0,MODE_EMA,PRICE_CLOSE);

//--- initialization done
   return(0);
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
//---

   int limit,first, period=InpPeriod;
   double _bear,_bull;
//--- value point
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);

//--- check for bars count
   if(rates_total<InpPeriod)
      return(0);// not enough bars for calculation  
//--- not all data may be calculated
   int calculated=BarsCalculated(ExtEmaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtEmaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
//---- get ma buffers
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtEmaHandle,0,0,to_copy,ExtTempBuffer)<=0)
     {
      Print("getting ExtEmaHandle is failed! Error",GetLastError());
      return(0);
     }
//--- first calculation or number of bars was changed
   if(prev_calculated<InpPeriod)
      limit=InpPeriod;
   else limit=prev_calculated-1;

//--- the main loop of calculations
   for(int i=limit;i<rates_total && !IsStopped();i++)
     {
      _bull = high[i]-ExtTempBuffer[i];
      _bear = low[i]-ExtTempBuffer[i];

      //--- fill indicators buffer
      if(_bull>0 && _bear>0) ExtBullsBearsBuffer[i]=_bull-_bear;
      else if(_bull<0 && _bear<0) ExtBullsBearsBuffer[i]=-(MathAbs(_bear)-MathAbs(_bull));
      else  ExtBullsBearsBuffer[i]=_bull+_bear;

      //--- value volume
      long _volume=(InpVolumeType==VOLUME_TICK)?tick_volume[i]:volume[i];

      //--- add volume to indicators buffer
      ExtBullsBearsBuffer[i]=ExtBullsBearsBuffer[i]*(double)_volume;

      //--- remove noise
      if(MathAbs(ExtBullsBearsBuffer[i])<delta) ExtBullsBearsBuffer[i]=0.0;
      BullsBearsIntegral[i] = BullsBearsIntegral[i-1]+ExtBullsBearsBuffer[i];

     }


   if(prev_calculated<InpPeriod)
      first=InpPeriod+LRPeriod;
   else first=prev_calculated-1;
   
   for(int i=first;i<rates_total && !IsStopped();i++)
     {
       BullsBearsIntegralLR[i] = LinearRegression(i, LRPeriod, BullsBearsIntegral);
     }
   
   
   return(rates_total);
  }
//+-------------------







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