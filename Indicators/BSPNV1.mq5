//+------------------------------------------------------------------+
//|                                                       BSPNV1.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"
#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   
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
//---


BP = close<open ?       (close[1]<open ?               math.max(high-close[1], close-low) :
                      /* close[1]>=open */             math.max(high-open, close-low)) : 
    (close>open ?       (close[1]>open ?               high-low : 
                      /* close[1]>=open */             math.max(open-close[1], high-low)) :           
    /*close == open*/   (high-close>close-low ?       
                                                      (close[1]<open ?              math.max(high-close[1],close-low) : 
                                                      /*close[1]>=open */           high-open) : 
                        (high-close<close-low ? 
                                                      (close[1]>open ?              high-low : 
                                                                                    math.max(open-close[1], high-low)) : 
                      /* high-close<=close-low */                             
                                                      (close[1]>open ?              math.max(high-open, close-low) : 
                                                      (close[1]<open ?              math.max(open-close[1], high-low) : 
                                                      /* close[1]==open */          high-low)))))    
        
SP = close<open ?       (close[1]>open ?              math.max(close[1]-open, high-low):
                                                      high-low) : 
     (close>open ?      (close[1]>open ?              math.max(close[1]-low, high-close) :
                                                      math.max(open-low, high-close)) : 
     /*close == open*/  (high-close>close-low ?   
                                                      (close[1]>open ?               math.max(close[1]-open, high-low) : 
                                                                                     high-low) : 
                        (high-close<close-low ?      
                                                      (close[1]>open ?               math.max(close[1]-low, high-close) : 
                                                                                     open-low) : 
                        /* high-close<=close-low */                              
                                                      (close[1]>open ?               math.max(close[1]-open, high-low) : 
                                                      (close[1]<open ?               math.max(open-low, high-close) : 
                                                                                     high-low)))))   


//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {

BP = close<open ? 
          (close[1]<open ?  math.max(high-close[1], close-low) : math.max(high-open, close-low)) : 
          (close>open ? (close[1]>open ? high-low : math.max(open-close[1], high-low)) : (high-close>close-low ? (close[1]<open ? math.max(high-close[1],close-low) : high-open) : (high-close<close-low ? (close[1]>open ?    high-low : math.max(open-close[1], high-low)) : (close[1]>open ?  math.max(high-open, close-low) : (close[1]<open ?  math.max(open-close[1], high-low) : high-low)))))    
        
SP = close<open ? (close[1]>open ? math.max(close[1]-open, high-low): high-low) : (close>open ? (close[1]>open ?  math.max(close[1]-low, high-close) : math.max(open-low, high-close)) : (high-close>close-low ?   (close[1]>open ?  math.max(close[1]-open, high-low) : high-low) : (high-close<close-low ? (close[1]>open ?  math.max(close[1]-low, high-close) : open-low) : (close[1]>open ?  math.max(close[1]-open, high-low) : (close[1]<open ?  math.max(open-low, high-close) : high-low)))))

//---
   
  }
//+------------------------------------------------------------------+
