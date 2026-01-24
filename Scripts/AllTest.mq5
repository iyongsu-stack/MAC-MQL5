//--- description 
#property description "Script draws \"Buy\" signs in the chart window." 
//--- display window of the input parameters during the script's launch 

#include <TradeHedge.mqh>
CTradeHedge Trade;
CPositions Positions;

ulong MagicNumber = 10507;
double FixedVolume = 0.1;
ulong buyTickets[], sellTickets[], Tickets[], numSellTickets, numBuyTickets, numTickets,
      LastBuyTicket, LastSellTicket;


//+------------------------------------------------------------------+ 
//| Script program start function                                    | 
//+------------------------------------------------------------------+ 
void OnStart() 
  { 

   double array[] ;
 
   ArrayResize(array, ArraySize(array) + 1);
   array[0] = 0.1;
   ArrayResize(array, 0);
   int size = ArraySize(array);
//   double value = array[0];
   Comment(size);


     
//   	double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
//		int digits = (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
//      Comment( digits );
//      Comment(point);

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