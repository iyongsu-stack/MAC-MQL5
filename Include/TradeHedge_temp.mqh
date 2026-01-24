//+------------------------------------------------------------------+
//|                                                   TradeHedge.mqh |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You may 
 modify it if necessary. You may even share it, provided the 
 copyright above is present. No commercial use is permitted. 
*/

#include <errordescription.mqh>


//+------------------------------------------------------------------+
//| Position Tickets & Counts                                        |
//+------------------------------------------------------------------+


// Open position information
class CPositions
{
   protected:
      ulong BuyTickets[];
      ulong SellTickets[];
      ulong Tickets[];
      int BuyCount;
      int SellCount;
      int TotalCount;
      
      void GetOpenPositions(ulong pMagicNumber = 0);
      int ResizeArray(ulong &array[]);   
   
   
   public:
      int Buy(ulong pMagicNumber);
      int Sell(ulong pMagicNumber);
      int TotalPositions(ulong pMagicNumber);
      
      void GetBuyTickets(ulong pMagicNumber, ulong &pTickets[]);
      void GetSellTickets(ulong pMagicNumber, ulong &pTickets[]);
      void GetTickets(ulong pMagicNumber, ulong &pTickets[]);
};

// Get open positions
void CPositions::GetOpenPositions(ulong pMagicNumber = 0)
{  
   BuyCount = 0;
   SellCount = 0;
   TotalCount = 0;
   
   ArrayResize(BuyTickets, 0);
//   ArrayInitialize(BuyTickets, 0);
   
   ArrayResize(SellTickets, 0);
//   ArrayInitialize(SellTickets, 0);
   
   ArrayResize(Tickets, 0);
//   ArrayInitialize(Tickets, 0);  
   
   
   for(int i = 0; i < PositionsTotal(); i++)
	{
	   ulong ticket = PositionGetTicket(i);
	   if(ticket == 0) return;
	   PositionSelectByTicket(ticket);
	   
	   if(PositionGetInteger(POSITION_MAGIC) != pMagicNumber && pMagicNumber > 0) continue;
	   
	   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
	   {
	      BuyCount++;
	      int arrayIndex = ResizeArray(BuyTickets);
	      BuyTickets[arrayIndex] = PositionGetInteger(POSITION_TICKET);
	   }
	   else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
	   {
	      SellCount++;
	      int arrayIndex = ResizeArray(SellTickets);
	      SellTickets[arrayIndex] = PositionGetInteger(POSITION_TICKET);
	   }
	   
	   TotalCount++; 
      int arrayIndex = ResizeArray(Tickets);
      Tickets[arrayIndex] = PositionGetInteger(POSITION_TICKET);
	}
}

int CPositions::ResizeArray(ulong &array[])
{

   int arrayIndex = 0;
   int newSize = ArrayResize(array, ArraySize(array) + 1);
   arrayIndex = newSize - 1;
   

/*   int arrayIndex = 0;
   if(ArraySize(array) > 1)
   {
      int newSize = ArrayResize(array, ArraySize(array) + 1);
      arrayIndex = newSize - 1;
   }
*/   
   return arrayIndex;
}

int CPositions::Buy(ulong pMagicNumber)
{
   GetOpenPositions(pMagicNumber);
   return(BuyCount);
}

int CPositions::Sell(ulong pMagicNumber)
{
   GetOpenPositions(pMagicNumber);
   return(SellCount);
}

int CPositions::TotalPositions(ulong pMagicNumber)
{
   GetOpenPositions(pMagicNumber);
   return(TotalCount);
}

void CPositions::GetBuyTickets(ulong pMagicNumber,ulong &pTickets[])
{
   GetOpenPositions(pMagicNumber);
   ArrayResize(pTickets, 0);
   ArrayCopy(pTickets, BuyTickets);
   return;
}

void CPositions::GetSellTickets(ulong pMagicNumber,ulong &pTickets[])
{
   GetOpenPositions(pMagicNumber);
   ArrayResize(pTickets, 0);
   ArrayCopy(pTickets, SellTickets);
   return;
}

void CPositions::GetTickets(ulong pMagicNumber,ulong &pTickets[])
{
   GetOpenPositions(pMagicNumber);
   ArrayResize(pTickets, 0);
   ArrayCopy(pTickets, Tickets);
   return;
}


//+------------------------------------------------------------------+
//| Position Information Functions                                   |
//+------------------------------------------------------------------+


string PositionComment(ulong pTicket = 0)
{
	bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetString(POSITION_COMMENT));
	else return(NULL);
}


long PositionTypeHedge(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetInteger(POSITION_TYPE));
	else return(WRONG_VALUE);
}


long PositionIdentifier(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetInteger(POSITION_IDENTIFIER));
	else return(WRONG_VALUE);
}


double PositionOpenPrice(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetDouble(POSITION_PRICE_OPEN));
	else return(WRONG_VALUE);
}


long PositionOpenTime(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetInteger(POSITION_TIME));
	else return(WRONG_VALUE);
}


double PositionVolume(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetDouble(POSITION_VOLUME));
	else return(WRONG_VALUE);
}


double PositionStopLoss(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetDouble(POSITION_SL));
	else return(WRONG_VALUE);
}


double PositionTakeProfit(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetDouble(POSITION_TP));
	else return(WRONG_VALUE);
}


double PositionProfit(ulong pTicket = 0)
{
	bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetDouble(POSITION_PROFIT));
	else return(WRONG_VALUE);
}

long PositionMagicNumber(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetInteger(POSITION_MAGIC));
	else return(NULL);
}