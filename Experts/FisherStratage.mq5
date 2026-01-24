//+------------------------------------------------------------------+
//|                                                 FishStdStrtg.mq5 |
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
input bool UseTrailingStop = false;
input int TrailingStop = 0;
input int MinimumProfit = 0;
input int Step = 0; 

sinput string BE;		// Break Even
input bool UseBreakEven = false;
input int BreakEvenProfit = 0;
input int LockProfit = 0;

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
input int                fisherSignalPeriod = 3;
input enCalcMode         fisherInpCalcMode = calc_no;      // Calculation mode
input ENUM_APPLIED_PRICE fisherInpPrice    = PRICE_WEIGHTED; // Price

// StdDev signal input data
input int            StdDevPeriod=5;   // Period
input int            StdDevShift=0;     // Shift
input ENUM_MA_METHOD StdDevMethod=MODE_SMA; // Method
input double         StdDevLevel = 0.0003;


//VWAP signal input data
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


//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
bool glBuyPlaced = false, glSellPlaced=false, timerOn, lastTimerOn = false;
int fisherHandle, stdDevHandle, slowVWAPHandle, fastVWAPHandle;
double fisherData[], fisherSignal[], currentFisherData, currentFisherSignal, 
       slowVWAPData[], fastVWAPData[], currentSlowVWAPData, currentFastVWAPData, 
       stdDevData[], currentStdDevData ;
ulong glBuyTicket, glSellTicket;



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

   //Std Dev indicator setup
   ArraySetAsSeries(stdDevData, true);
   stdDevHandle = iCustom(_Symbol, 0, "Examples\\StdDev", StdDevPeriod, StdDevShift, StdDevMethod); 
      
   //VWAP indicator setup
   ArraySetAsSeries(slowVWAPData, true);
   ArraySetAsSeries(fastVWAPData, true);
   slowVWAPHandle = iCustom(_Symbol, 0, "VWAP2", SlowVWAPPeriod, SLOW_MA_METHOD, VWAPInpPrice);
   fastVWAPHandle = iCustom(_Symbol, 0, "VWAP2", FastVWAPPeriod, FAST_MA_METHOD, VWAPInpPrice);
      
   return(INIT_SUCCEEDED);


}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{

	// Check for new bar
	bool newBar = true;
	int barShift = 0;
	
	if(TradeOnNewBar == true) 
	{
		newBar = NewBar.CheckNewBar(_Symbol,_Period);
		barShift = 1;
	}
	
	
	// Timer-weeklyTimer
	if(UseTimer == true)
	{
		timerOn = Timer.WeeklyTimer(MyStartDay,MyStartHour,MyEndDay,MyEndHour,UseLocalTime);
	}
	
	
	// Update prices
	Price.Update(_Symbol,_Period);
	
	//Starting trading
	if(newBar == true && timerOn == true)
   {

      //Fisher Transform indicator
      CopyBuffer(fisherHandle, 0, 0, 3, fisherData );
      CopyBuffer(fisherHandle, 2, 0, 3, fisherSignal );
      currentFisherData = fisherData[1];
      currentFisherSignal = fisherSignal[1];
         //      Print("current Fisher Data: ", (float)currentFisherData, "current Fisher Signal: ", (float)currentFisherSignal);
      if(currentFisherData >= currentFisherSignal) currentFisherTrend = FisherAscending;
      else currentFisherTrend = FisherDescending;
         //      Print("Fisher Trend: ", currentFisherTrend);
      

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
      

      //Long Buy order placement
      if(currentPriceTrend == PriceAscending && currentStdDevOK == Go && 
         currentFisherTrend == FisherAscending && glBuyPlaced == false )
      {
         Print("Long Buy at: ", TimeToString(TimeLocal()) );
         glBuyPlaced = true;
      }


      //Long Close order placement
      else if( currentFisherTrend == FisherDescending && glBuyPlaced == true )
      {
         Print("Long closed at: ", TimeToString(TimeLocal()) );
         glBuyPlaced = false;
      }


      //Short Sell order placement
      else if(currentPriceTrend == PriceDescending && currentStdDevOK == Go && 
         currentFisherTrend == FisherDescending && glSellPlaced == false )
      {
         Print("Short sell at: ", TimeToString(TimeLocal()) );
         glSellPlaced = true;
      }


      //Short Close order placement
      else if(currentFisherTrend == FisherAscending && glSellPlaced == true)
      {
         Print("Short closed at: ", TimeToString(TimeLocal()) );
         glSellPlaced = false;      
      }
   
    }


/*	
	// Order placement
	if(newBar == true && timerOn == true)
	{
		
		// Money management
		double tradeSize;
		if(UseMoneyManagement == true) tradeSize = MoneyManagement(_Symbol,FixedVolume,RiskPercent,StopLoss);
		else tradeSize = VerifyVolume(_Symbol,FixedVolume);
		
		
		// Open buy order
		if(Positions.Buy(MagicNumber) == 0)
		{
			glBuyTicket = Trade.Buy(_Symbol,tradeSize);
		
			if(glBuyTicket > 0)  
			{
				double openPrice = PositionOpenPrice(glBuyTicket);
				
				double buyStop = BuyStopLoss(_Symbol,StopLoss,openPrice);
				if(buyStop > 0) AdjustBelowStopLevel(_Symbol,buyStop);
				
				double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,openPrice);
				if(buyProfit > 0) AdjustAboveStopLevel(_Symbol,buyProfit);
				
				if(buyStop > 0 || buyProfit > 0) Trade.ModifyPosition(glBuyTicket,buyStop,buyProfit);
				glSellTicket = 0;
			} 
		}
		
		
		// Open sell order
		if(Positions.Sell(MagicNumber) == 0)
		{
			glSellTicket = Trade.Sell(_Symbol,tradeSize);
			
			if(glSellTicket > 0)
			{
				double openPrice = PositionOpenPrice(glSellTicket);
				
				double sellStop = SellStopLoss(_Symbol,StopLoss,openPrice);
				if(sellStop > 0) sellStop = AdjustAboveStopLevel(_Symbol,sellStop);
				
				double sellProfit = SellTakeProfit(_Symbol,TakeProfit,openPrice);
				if(sellProfit > 0) sellProfit = AdjustBelowStopLevel(_Symbol,sellProfit);
				
				if(sellStop > 0 || sellProfit > 0) Trade.ModifyPosition(glSellTicket,sellStop,sellProfit);
				glBuyTicket = 0;
			} 
		}
		
	} // Order placement end
	
	
	// Get position tickets
	ulong tickets[];
	Positions.GetTickets(MagicNumber, tickets);
	int numTickets = ArraySize(tickets);
	
	
	// Break even
	if(UseBreakEven == true && numTickets > 0)
	{
		for(int i = 0; i < numTickets; i++)
		{
		   Trail.BreakEven(tickets[i], BreakEvenProfit, LockProfit);
		}
	}
	
	
	// Trailing stop
	if(UseTrailingStop == true && numTickets > 0)
	{
		for(int i = 0; i < numTickets; i++)
		{
		   Trail.TrailingStop(tickets[i], TrailingStop, MinimumProfit, Step);
		}
	}
*/

	// Time-Out, Close all positions
	if(lastTimerOn == true  &&  timerOn == false)
	{
	   Print("Close All Position at", TimeToString(TimeCurrent()));
	}
   lastTimerOn = timerOn;




}