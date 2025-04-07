//+------------------------------------------------------------------+
//|                                                    TimerTest.mq5 |
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
input ulong MagicNumber = 0507;

sinput string MM; 	// Money Management
input bool UseMoneyManagement = true;
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


//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

ulong glBuyTicket, glSellTicket;
bool timerOn, lastTimerOn = false;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	Trade.MagicNumber(MagicNumber);
	Trade.Deviation(Slippage);
   return(0);

}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{

	
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
	

	


}