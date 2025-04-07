//+------------------------------------------------------------------+
//|                                                    TimerTest.mq5 |
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
return(0);
}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{

	
	// Timer
	datetime currentTime;
	if(UseTimer == true)
	{
		timerOn = Timer.WeeklyTimer(MyStartDay,MyStartHour,MyEndDay,MyEndHour,UseLocalTime);
	}
   if(timerOn == true && lastTimerOn == false)	
   {
      Print("Start trading at: ", TimeToString(TimeCurrent()));
   }
	// Time-Out, Close all positions
	if(lastTimerOn == true  &&  timerOn == false)
	{
	   Print("Close All Position at", TimeToString(TimeCurrent()));
	}
   lastTimerOn = timerOn;


	


}