//+------------------------------------------------------------------+
//|                                                      MyFirst.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

// Timer
#include <Timer.mqh>
CTimer Timer;
CNewBar NewBar;

//Fisher transform input data
enum enCalcMode
{
   calc_hl, // Include current high and low in calculation
   calc_no  // Don't include current high and low in calculation
};

input int                fisherInpPeriod   = 20;           // Period
input int                fisherSignalPeriod = 3;
input enCalcMode         fisherInpCalcMode = calc_no;      // Calculation mode
input ENUM_APPLIED_PRICE fisherInpPrice    = PRICE_WEIGHTED; // Price

// StdDev input data
input int            StdDevPeriod=5;   // Period
input int            StdDevShift=0;     // Shift
input ENUM_MA_METHOD StdDevMethod=MODE_EMA; // Method
input double         StdDevLevel = 0.0003;


//VWAP input data
input int SlowVWAPPeriod = 72;
input int FastVWAPPeriod = 5;
input ENUM_MA_METHOD SLOW_MA_METHOD = MODE_SMA;
input ENUM_MA_METHOD FAST_MA_METHOD = MODE_EMA;
input ENUM_APPLIED_PRICE VWAPInpPrice    = PRICE_WEIGHTED; 

enum PriceTrend
{
   PriceAscending,
   PriceDescending,
};
PriceTrend currentPriceTrend;


enum FisherTrend
{
   FisherAscending,
   FisherDescending,
};
FisherTrend currentFisherTrend;


enum StdDevOk
{
   Go,
   NoGo,
};
StdDevOk currentStdDevOK;


bool glBuyPlaced = false, glSellPlaced=false;
int fisherHandle, stdDevHandle, slowVWAPHandle, fastVWAPHandle;
double fisherData[], fisherSignal[], currentFisherData, currentFisherSignal, 
       slowVWAPData[], fastVWAPData[], currentSlowVWAPData, currentFastVWAPData, 
       stdDevData[], currentStdDevData ;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

      //fisher Transform indicator setup
      ArraySetAsSeries(fisherData, true); 
      ArraySetAsSeries(fisherSignal, true);    
      fisherHandle = iCustom(_Symbol, 0, "Examples\\Fisher2", 
                                       fisherInpPeriod, fisherSignalPeriod, fisherInpCalcMode, fisherInpPrice); 

      //Std Dev indicator setup
      ArraySetAsSeries(stdDevData, true);
      stdDevHandle = iCustom(_Symbol, 0, "Examples\\StdDev", StdDevPeriod, StdDevShift, StdDevMethod); 
      
      //VWAP indicator setup
      ArraySetAsSeries(slowVWAPData, true);
      ArraySetAsSeries(fastVWAPData, true);
      slowVWAPHandle = iCustom(_Symbol, 0, "VWAP2", SlowVWAPPeriod, SLOW_MA_METHOD, VWAPInpPrice);
      fastVWAPHandle = iCustom(_Symbol, 0, "VWAP2", FastVWAPPeriod, FAST_MA_METHOD, VWAPInpPrice);
      


   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

	// Check for new bar
   bool newBar = NewBar.CheckNewBar(_Symbol,_Period);
   if(newBar == true)
   {
      //Fisher Transform indicator
      CopyBuffer(fisherHandle, 0, 0, 3, fisherData );
      CopyBuffer(fisherHandle, 2, 0, 3, fisherSignal );
      currentFisherData = fisherData[1];
      currentFisherSignal = fisherSignal[1];
      
//      Print("current Fisher Data: ", (float)currentFisherData, "current Fisher Signal: ", (float)currentFisherSignal);
      
      if(currentFisherData >= currentFisherSignal) currentFisherTrend = FisherAscending;
      else currentFisherTrend = FisherDescending;
      Print("Fisher Trend: ", currentFisherTrend);
      
      //Std Dev indicator
      CopyBuffer(stdDevHandle, 0, 0, 3, stdDevData);
      currentStdDevData = stdDevData[1];
//      Print("current StdDev: ", (float)currentStdDevData);


      if(currentStdDevData > StdDevLevel ) currentStdDevOK = Go;
      else currentStdDevOK = NoGo;
//      Print("StdDevOk: ", currentStdDevOK);
      
           
      //VWAP indicator
      CopyBuffer(slowVWAPHandle, 0, 0, 3, slowVWAPData);
      CopyBuffer(fastVWAPHandle, 0, 0, 3, fastVWAPData);
      currentSlowVWAPData = slowVWAPData[1];
      currentFastVWAPData = fastVWAPData[1];
//      Print("Slow VWAP: ", (float)currentSlowVWAPData, "Fast VWAP: ", (float)currentFastVWAPData);
      
      if(currentFastVWAPData >= currentSlowVWAPData ) currentPriceTrend = PriceAscending;
      else currentPriceTrend = PriceDescending;
//      Print("PriceTrend: ", currentPriceTrend);
      
      //Long Buy order
      if(currentPriceTrend == PriceAscending && currentStdDevOK == Go && 
         currentFisherTrend == FisherAscending && glBuyPlaced == false )
      {
         Print("Long Buy at: ", TimeToString(TimeLocal()) );
         glBuyPlaced = true;
      }

      //Long Close order
      else if( currentFisherTrend == FisherDescending && glBuyPlaced == true )
      {
         Print("Long closed at: ", TimeToString(TimeLocal()) );
         glBuyPlaced = false;
      }

      //Short Sell order
      else if(currentPriceTrend == PriceDescending && currentStdDevOK == Go && 
         currentFisherTrend == FisherDescending && glSellPlaced == false )
      {
         Print("Short sell at: ", TimeToString(TimeLocal()) );
         glSellPlaced = true;
      }

      //Short Close order
      else if(currentFisherTrend == FisherAscending && glSellPlaced == true)
      {
         Print("Short closed at: ", TimeToString(TimeLocal()) );
         glSellPlaced = false;      
      }
   
    }
     
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
