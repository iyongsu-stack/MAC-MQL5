//+------------------------------------------------------------------+
//|                                                   GridStr_V1.mq5 |
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

// Timer
#include <Timer.mqh>
CTimer Timer;
CNewBar NewBar;



//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
sinput string Trading; 	// Trading
input ulong Slippage = 3;
input ulong MagicNumber = 10507;
input double FixedVolume = 0.1;

sinput string TI; 	// Timer
input bool TradeOnNewBar = false;
input bool UseWeeklyTimer = false;
input bool UseDailyTimer = true;
input int MyStartDay = MONDAY;
input int MyStartHour = 8; 
input int MyEndDay = FRIDAY;
input int MyEndHour = 16;
input bool UseLocalTime = false;
input int DailyStartHour = 8; 
input int DailyEndHour = 16;

double GridSizePoint = 70. ;


enum EnumCrossGrid
{
   UpCross,
   DnCross,
   NoCross,
};

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
bool WeeklytimerOn=false, DailyTimerOn=true, lastTimerOn = false, FirstTrading = true;
double GridSize, UpGrid, DnGrid, CurrGrid ;      
ulong buyTickets[], sellTickets[], Tickets[], numSellTickets, numBuyTickets, numTickets,
      LastBuyTicket, LastSellTicket;
datetime testTime1, testTime2, testTime3;



//==============================================================================
int OnInit()
{
	
	Trade.MagicNumber(MagicNumber);
	Trade.Deviation(Slippage);

  
   return(INIT_SUCCEEDED);

}


//==============================================================================
void OnTick()
{

	// weeklyTimer
	testTime1 = TimeCurrent();
   if(UseWeeklyTimer == true) WeeklytimerOn = Timer.WeeklyTimer(MyStartDay,MyStartHour,MyEndDay,MyEndHour,UseLocalTime);
	else WeeklytimerOn = true;
	
	if(UseDailyTimer  == true) DailyTimerOn = Timer.DailyTimer(DailyStartHour, 0, DailyEndHour, 0);
	else DailyTimerOn = true;

   if(WeeklytimerOn == true   && DailyTimerOn == true)
   {

      testTime2 = TimeCurrent();


   
   }

	// Time-Out, Close all positions
   bool MyTimerOn;
   if(UseDailyTimer == true) MyTimerOn = DailyTimerOn;
   else MyTimerOn = WeeklytimerOn;

	if(lastTimerOn == true  &&  MyTimerOn == false)
	{
      testTime3 = TimeCurrent();
	}
   lastTimerOn = MyTimerOn;

}
