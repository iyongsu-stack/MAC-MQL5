//+------------------------------------------------------------------+
//|                                            FisherStratage_V2.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"


// Trade
#include <TradeHedge.mqh>
CTradeHedge Trade;
CPositions Positions;

// Price
#include <Price.mqh>
CBars Price;

// Money management
#include <MoneyManagement.mqh>

// Trailing stops
#include <TrailingStops.mqh>
CTrailing Trail;

// Timer
#include <Timer.mqh>
CTimer Timer;
CNewBar NewBar;



//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+

input ulong Slippage = 3;
input ulong MagicNumber = 1050;

sinput string MM; 	// Money Management
input bool UseMoneyManagement = false;
input double RiskPercent = 2;
input double FixedVolume = 0.1;

sinput string SL; 	// Stop Loss & Take Profit
input int StopLoss = 0;
input int TakeProfit = 0;

sinput string TS;		// Trailing Stop
input bool UseTrailingStop = true;
input int TrailingStop = 20;
input int MinimumProfit = 0;
input int Step = 10; 

sinput string TI; 	// Timer
input bool TradeOnNewBar = true;
input bool UseTimer = true;
input int MyStartDay = MONDAY;
input int MyStartHour = 8;  //
input int MyEndDay = FRIDAY;
input int MyEndHour = 16;
input bool UseLocalTime = false;

//Fisher transform signal input data
enum enCalcMode
{
   calc_hl, // Include current high and low in calculation
   calc_no  // Don't include current high and low in calculation
};

input int                fisherInpPeriod   = 20;           // Period
input int                fisherSignalPeriod = 5;
input enCalcMode         fisherInpCalcMode = calc_no;      // Calculation mode
input ENUM_APPLIED_PRICE fisherInpPrice    = PRICE_WEIGHTED; // Price

//VWAP signal input data
input int SlowVWAPPeriod = 72;  //Calibration required
input int FastVWAPPeriod = 2;
input ENUM_MA_METHOD SLOW_MA_METHOD = MODE_SMA;
input ENUM_MA_METHOD FAST_MA_METHOD = MODE_EMA;
input ENUM_APPLIED_PRICE VWAPInpPrice    = PRICE_WEIGHTED; 

//ATR channel input parameters
input int      ATR_VWAPeriod =2;
input ENUM_MA_METHOD ATR_MA_METHOD = MODE_EMA;
input ENUM_APPLIED_PRICE ATR_inpPrice    = PRICE_WEIGHTED; 
input int ATR_Period = 14;
input double ATR_Mult_Factor1= 1.2;  //Calibration required



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


//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
bool timerOn, lastTimerOn = false;
int fisherHandle, slowVWAPHandle, fastVWAPHandle, ATRHandle, numBuyTickets, numSellTickets, numTickets;
double fisherData[], fisherSignal[], currentFisherData, currentFisherSignal, 
       slowVWAPData[], fastVWAPData[], currentSlowVWAPData, currentFastVWAPData;
       
//Trailing Stop Variable
ulong buyTickets[], sellTickets[], Tickets[];
double highATR[], lowATR[], shortTrailPrice=100000., longTrailPrice=0., currentPrice;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	
	Trade.MagicNumber(MagicNumber);
	Trade.Deviation(Slippage);

   //fisher Transform indicator setup
   ArraySetAsSeries(fisherData, true); 
   ArraySetAsSeries(fisherSignal, true);    
   fisherHandle = iCustom(_Symbol, 0, "Examples\\Fisher2", 
                                       fisherInpPeriod, fisherSignalPeriod, fisherInpCalcMode, fisherInpPrice); 
      
   //VWAP indicator setup
   ArraySetAsSeries(slowVWAPData, true);
   ArraySetAsSeries(fastVWAPData, true);
   slowVWAPHandle = iCustom(_Symbol, 0, "VWAP2", SlowVWAPPeriod, SLOW_MA_METHOD, VWAPInpPrice);
   fastVWAPHandle = iCustom(_Symbol, 0, "VWAP2", FastVWAPPeriod, FAST_MA_METHOD, VWAPInpPrice);

   ArraySetAsSeries(highATR, true);
   ArraySetAsSeries(lowATR, true);
   ATRHandle = iCustom(_Symbol, 0, "VWAP+ATR CHANNEL", ATR_VWAPeriod, ATR_MA_METHOD, ATR_inpPrice, ATR_Period, ATR_Mult_Factor1);
      
   return(INIT_SUCCEEDED);


}



void OnTick()
{

	// Check for new bar
	bool newBar = true;	
	if(TradeOnNewBar == true) newBar = NewBar.CheckNewBar(_Symbol,_Period);
		
	// weeklyTimer
	if(UseTimer == true) timerOn = Timer.WeeklyTimer(MyStartDay,MyStartHour,MyEndDay,MyEndHour,UseLocalTime);
		
	//Start trading
	if(newBar == true && timerOn == true)
   {
     
      My_IndicatorSet();
      
      SetTrailingStop();

      //Long Buy order placement
      if(currentPriceTrend == PriceAscending && currentFisherTrend == FisherAscending && numBuyTickets <= 0 )
      {
         //Close all Short positions
		   for(int i = 0; i < numSellTickets; i++) Trade.Close(sellTickets[i]);

         //Open Long Buy position
         Trade.Buy(_Symbol, FixedVolume);
         GetPositionTickets();
      }


      //Short Sell order placement
      if(currentPriceTrend == PriceDescending && currentFisherTrend == FisherDescending  && numSellTickets <= 0 )
      {
         //Close all Long positions
		   for(int i = 0; i < numBuyTickets; i++) Trade.Close(buyTickets[i]);
		   
         //Open Short Sell
         Trade.Sell(_Symbol, FixedVolume);
         
         GetPositionTickets();
      }

    }

   //My Trailing-Stop
   CheckTrailingStop();       
 
	// Time-Out, Close all positions
	if(lastTimerOn == true  &&  timerOn == false)
	{
		for(int i = 0; i < numTickets; i++) Trade.Close(Tickets[i]);  
		GetPositionTickets();      
	}
   lastTimerOn = timerOn;


}




void GetPositionTickets()
{
	Positions.GetBuyTickets(MagicNumber, buyTickets);
	Positions.GetSellTickets(MagicNumber, sellTickets);
	Positions.GetTickets(MagicNumber, Tickets);

	if(buyTickets[0] == 0 ) numBuyTickets = 0;
	else numBuyTickets = ArraySize(buyTickets);

	if(sellTickets[0] == 0 ) numSellTickets = 0;
	else numSellTickets = ArraySize(sellTickets);

	if(Tickets[0] == 0 ) numTickets = 0;
	else numTickets = ArraySize(Tickets);

}



void CheckTrailingStop()
{

   GetPositionTickets();
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   //Long Position Trailing-Stop
   if(numBuyTickets>=1 && bid < longTrailPrice) { for(int i = 0; i < numBuyTickets; i++)  {Trade.Close(buyTickets[i]);}  }; // && currentFisherTrend == FisherDescending) // Calibration required
   
   //Short Position Trailing-Stop
   if(numSellTickets>=1 && ask > shortTrailPrice) { for(int i = 0; i < numSellTickets; i++) {Trade.Close(sellTickets[i]);}  }; // && currentFisherTrend == FisherAscending) // Calibration required

   GetPositionTickets();
}


void SetTrailingStop()
{
   
   //ATR channel indicator
   CopyBuffer(ATRHandle, 1, 0, 3, highATR);
   CopyBuffer(ATRHandle, 2, 0, 3, lowATR);
   double tempShortTrailPrice = highATR[1];
   double tempLongTrailPrice = lowATR[1];
   
   // Long position Trailing Stop reset
   if(numBuyTickets >=1){ if(tempLongTrailPrice > longTrailPrice) longTrailPrice = tempLongTrailPrice; }
   else longTrailPrice = 0.;
   
   // Short position Trailing stop reset
   if(numSellTickets >= 1) { if(tempShortTrailPrice < shortTrailPrice) shortTrailPrice = tempShortTrailPrice; }
   else shortTrailPrice = 10000.;
   

}


void My_IndicatorSet()
{
 
   //Fisher Transform indicator
   CopyBuffer(fisherHandle, 0, 0, 3, fisherData );
   CopyBuffer(fisherHandle, 2, 0, 3, fisherSignal );
   currentFisherData = fisherData[1];
   currentFisherSignal = fisherSignal[1];

   if(currentFisherData >= currentFisherSignal) currentFisherTrend = FisherAscending;
   else currentFisherTrend = FisherDescending;
        
   //VWAP indicator
   CopyBuffer(slowVWAPHandle, 0, 0, 3, slowVWAPData);
   CopyBuffer(fastVWAPHandle, 0, 0, 3, fastVWAPData);
   currentSlowVWAPData = slowVWAPData[1];
   currentFastVWAPData = fastVWAPData[1];

   if(currentFastVWAPData >= currentSlowVWAPData ) currentPriceTrend = PriceAscending;
   else currentPriceTrend = PriceDescending;

}