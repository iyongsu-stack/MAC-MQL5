
//+------------------------------------------------------------------+
//| Calculate Buy Ratio                                              |
//+------------------------------------------------------------------+
double CalculateBuyRatio(const double &open[], const double &high[], const double &low[], const double &close[], int bar)
{
   if(bar <= 0) return(0.0);
   
   double buyRatio = 0.0;
   
   // 현재 캔들이 하락 캔들인 경우
   if(close[bar] < open[bar])
   {
      if(close[bar-1] < open[bar])
         buyRatio = MathMax(high[bar] - close[bar-1], close[bar] - low[bar]);
      else
         buyRatio = MathMax(high[bar] - open[bar], close[bar] - low[bar]);
   }
   // 현재 캔들이 상승 캔들인 경우
   else if(close[bar] > open[bar])
   {
      if(close[bar-1] > open[bar])
         buyRatio = high[bar] - low[bar];
      else
         buyRatio = MathMax(open[bar] - close[bar-1], high[bar] - low[bar]);
   }
   // 현재 캔들이 도지 캔들인 경우
   else
   {
      if(high[bar] - close[bar] > close[bar] - low[bar])
      {
         if(close[bar-1] < open[bar])
            buyRatio = MathMax(high[bar] - close[bar-1], close[bar] - low[bar]);
         else
            buyRatio = high[bar] - open[bar];
      }
      else if(high[bar] - close[bar] < close[bar] - low[bar])
      {
         if(close[bar-1] > open[bar])
            buyRatio = high[bar] - low[bar];
         else
            buyRatio = MathMax(open[bar] - close[bar-1], high[bar] - low[bar]);
      }
      else
      {
         if(close[bar-1] > open[bar])
            buyRatio = MathMax(high[bar] - open[bar], close[bar] - low[bar]);
         else if(close[bar-1] < open[bar])
            buyRatio = MathMax(open[bar] - close[bar-1], high[bar] - low[bar]);
         else
            buyRatio = high[bar] - low[bar];
      }
   }
   
   return(buyRatio);
}

//+------------------------------------------------------------------+
//| Calculate Sell Ratio                                             |
//+------------------------------------------------------------------+
double CalculateSellRatio(const double &open[], const double &high[], const double &low[], const double &close[], int bar)
{
   if(bar <= 0) return(0.0);
   
   double sellRatio = 0.0;
   
   // 현재 캔들이 하락 캔들인 경우
   if(close[bar] < open[bar])
   {
      if(close[bar-1] > open[bar])
         sellRatio = MathMax(close[bar-1] - open[bar], high[bar] - low[bar]);
      else
         sellRatio = high[bar] - low[bar];
   }
   // 현재 캔들이 상승 캔들인 경우
   else if(close[bar] > open[bar])
   {
      if(close[bar-1] > open[bar])
         sellRatio = MathMax(close[bar-1] - low[bar], high[bar] - close[bar]);
      else
         sellRatio = MathMax(open[bar] - low[bar], high[bar] - close[bar]);
   }
   // 현재 캔들이 도지 캔들인 경우
   else
   {
      if(high[bar] - close[bar] > close[bar] - low[bar])
      {
         if(close[bar-1] > open[bar])
            sellRatio = MathMax(close[bar-1] - open[bar], high[bar] - low[bar]);
         else
            sellRatio = high[bar] - low[bar];
      }
      else if(high[bar] - close[bar] < close[bar] - low[bar])
      {
         if(close[bar-1] > open[bar])
            sellRatio = MathMax(close[bar-1] - low[bar], high[bar] - close[bar]);
         else
            sellRatio = open[bar] - low[bar];
      }
      else
      {
         if(close[bar-1] > open[bar])
            sellRatio = MathMax(close[bar-1] - open[bar], high[bar] - low[bar]);
         else if(close[bar-1] < open[bar])
            sellRatio = MathMax(open[bar] - low[bar], high[bar] - close[bar]);
         else
            sellRatio = high[bar] - low[bar];
      }
   }
   
   return(sellRatio);
}