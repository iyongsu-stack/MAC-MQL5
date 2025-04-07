//+------------------------------------------------------------------+
//|                                                   GridStr_V2.mq5 |
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
input double FixedVolume = 1;

sinput string TI; 	// Timer
input bool UseDailyTimer = true;
input bool UseLocalTime = false;
input int DailyStartHour = 8; 
input int DailyEndHour = 16;

double GridSizePoint = 50. ;


enum EnumCrossGrid
{
   UpCross,
   DnCross,
   NoCross,
};
EnumCrossGrid LastCrossed = NoCross;

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
bool DailyTimerOn=true, lastTimerOn = false, FirstTrading = true;
double GridSize, UpGrid, DnGrid, CurrGrid, testPrice ;      
ulong buyTickets[], sellTickets[], Tickets[], numSellTickets, numBuyTickets, numTickets,
      LastBuyTicket, LastSellTicket;
int CountCross = 0;



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
	if(UseDailyTimer  == true) DailyTimerOn = Timer.DailyTimer(DailyStartHour, 0, DailyEndHour, 0);

   if( DailyTimerOn == true)
   {
      //First trading
      if(FirstTrading == true)
      {
         if(!FirstGridTrading()) return;
         FirstTrading = false;  
      }

      testPrice = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID), Digits());

      EnumCrossGrid isCrossed = CheckCrossGrid();
      
      GridTrading(isCrossed); 
   
   }

	// Time-Out, Close all positions


	if(lastTimerOn == true  &&  DailyTimerOn == false)
	{
      CloseAllPosition();
	}
   lastTimerOn = DailyTimerOn;

}


///=============================================================================
bool FirstGridTrading()
{

   LastBuyTicket = Trade.Buy(_Symbol, FixedVolume);
   LastSellTicket = Trade.Sell(_Symbol, FixedVolume);
   if(LastBuyTicket == 0 || LastSellTicket == 0) { Print("Buy or Sell Error Point #2"); return(false);}

   CurrGrid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID), Digits());
   GridSize = GridSizePoint * Point();
   UpGrid = CurrGrid + GridSize;
   DnGrid = CurrGrid - GridSize;

   return(true);
}


//===========================================
int CheckCrossGrid()
{
   double currPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   if(currPrice > UpGrid)
   { return(UpCross);}
   else if(currPrice < DnGrid)
      { return(DnCross);}

   return(NoCross);
}


//==========================================
bool GridTrading(EnumCrossGrid pIsCrossed)
{
   if( (pIsCrossed == UpCross  && LastCrossed == UpCross) || (pIsCrossed == UpCross  && LastCrossed == NoCross))
   {
      if(!Trade.Close(LastBuyTicket)) { Print("Close Error point #3"); return(false);}
      if(!FirstGridTrading()) { Print("Close Error point #4"); return(false);}    
      LastCrossed = pIsCrossed;     
   }
   else if( (pIsCrossed == DnCross && LastCrossed == DnCross) ||(pIsCrossed == DnCross && LastCrossed == NoCross) )
   {
      if(!Trade.Close(LastSellTicket)) { Print("Close Error point #5"); return(false);}
      if(!FirstGridTrading()) { Print("Close Error point #6"); return(false);}  
      LastCrossed = pIsCrossed;       
   } 
   else if( (pIsCrossed == UpCross && LastCrossed == DnCross) ||  (pIsCrossed == DnCross && LastCrossed == UpCross) )
   {
      CloseAllPosition();
      FirstTrading = true; 
      LastCrossed = NoCross;
   }
   
   return(true);   
}  

void CloseAllPosition()
{
   GetPositionTickets(); 
		
	for(int i = 0; i < numTickets; i++)
	{ if(!Trade.Close(Tickets[i]) ) Print("Close Error at Point #1");  }     


}

void GetPositionTickets()
{
	Positions.GetBuyTickets(MagicNumber, buyTickets);
	Positions.GetSellTickets(MagicNumber, sellTickets);
	Positions.GetTickets(MagicNumber, Tickets);


	numBuyTickets = ArraySize(buyTickets);
	numSellTickets = ArraySize(sellTickets);
	numTickets = ArraySize(Tickets);

}
