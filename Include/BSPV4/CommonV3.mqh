//+------------------------------------------------------------------+
//|                                                     CommonV3.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV4/ExternVariables.mqh>


bool Times(datetime currTime)
{
   MqlDateTime strTime;
   TimeToStruct(currTime, strTime);
   int hour0 = strTime.hour;

   if(StartTime < EndTime)
      if(hour0 < StartTime || hour0 >= EndTime)
         return (false);
   if(StartTime > EndTime)
      if(hour0 >= EndTime || hour0 < StartTime)
         return(false);

   return (true);
}

bool CloseTimes(datetime currTime)
{
   MqlDateTime strTime;
   TimeToStruct(currTime, strTime);
   int hour0 = strTime.hour;
   int minute0=strTime.min;
   static bool m_Flag=false;

   if( (!m_Flag && hour0>=CloseHour && minute0>=CloseMin) || (m_Flag && hour0>=CloseHour) ) 
     {
      m_Flag=true;
      return (true);
     } 
   else 
     {
      m_Flag=false;
      return (false);
      
     } 
}


 
 
bool isNewBar(string sym)
{
   static datetime dtBarCurrent=WRONG_VALUE;
   datetime dtBarPrevious=dtBarCurrent;
   dtBarCurrent=(datetime) SeriesInfoInteger(sym,Period(),SERIES_LASTBAR_DATE);
   bool NewBarFlag=(dtBarCurrent!=dtBarPrevious);
   if(NewBarFlag)
      return(true);
   else
      return (false);

   return (false);
}
 

/*
//-------------------------------------------------------------------+
void Virtual_SLTP()
{

   if(!_VirtualSLTP)return;
        
   if(!Sym.RefreshRates()) return;  

   int total=PositionsTotal();
   if(total<=0) return;
   
   for(int i=(total -1); i>= 0; i--){

      if(! Pos.SelectByIndex(i)){
         Alert("Position Selection Error");
         return;
      }

      string position_symbol=PositionGetSymbol(i);
      if(position_symbol==_Symbol && iMagicNumber==PositionGetInteger(POSITION_MAGIC)){

         switch(Pos.PositionType()){
            case POSITION_TYPE_BUY:
               if(
                  (TakeProfit>0 && Sym.NormalizePrice(Sym.Bid()-Pos.PriceOpen()-Sym.Point()*TakeProfit)>=0) ||
                  (StopLoss>0 && Sym.NormalizePrice(Pos.PriceOpen()-Sym.Bid()-Sym.Point()*StopLoss)>=0)
               ) Trade.PositionClose(PositionGetInteger(POSITION_TICKET));    
            break;
            
            case POSITION_TYPE_SELL:
               if(
                  (TakeProfit>0 && Sym.NormalizePrice(Pos.PriceOpen()-Sym.Ask()-Sym.Point()*TakeProfit)>=0) ||
                  (StopLoss>0 && Sym.NormalizePrice(Sym.Ask()-Pos.PriceOpen()-Sym.Point()*StopLoss)>=0)
               ) Trade.PositionClose(PositionGetInteger(POSITION_TICKET));    
            break;
            
         }      
      }     
      
   }
}

*/

//+------------------------------------------------------------------+
//|   Function for determining the lot based on the trade results               |
//+------------------------------------------------------------------+
bool SolveLots(double & aLots)
{
   if(Lots==0){
      if(PositionSummary.totalNumPositions == 0) aLots=fLotsNormalize(AccountInfoDouble(ACCOUNT_BALANCE)*MaximumRisk*1./1000.0);
      else aLots=fLotsNormalize(AccountInfoDouble(ACCOUNT_BALANCE)*MaximumRisk*1./1000.0*LotsMultiFactor);
      return(true);        
   }else{
      if(PositionSummary.totalNumPositions == 0) aLots=Lots; 
      else aLots = Lots * LotsMultiFactor;
      return(true);       
   }

   return(false);
}

//+------------------------------------------------------------------+
//|   Lot normalization function                                      |
//+------------------------------------------------------------------+
double fLotsNormalize(double aLots)
{
   aLots-=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   aLots/=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   aLots=MathRound(aLots);
   aLots*=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   aLots+=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   aLots=NormalizeDouble(aLots,2);
   aLots=MathMin(aLots,SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX));
   aLots=MathMax(aLots,SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN));  
   return(aLots);
}



bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)
{
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
//--- call of the checking function
   if(!OrderCalcMargin(type,symb,lots,price,margin))
     {
      //--- something went wrong, report and return false
      return(false);
     }
//--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      return(false);
     }
//--- checking successful
   return(true);
}



//+------------------------------------------------------------------+
//|   Function for calculating the Stop Loss for a buy position                               |
//+------------------------------------------------------------------+
double SolveBuySL(int StopLossPoints)
{
   if(StopLossPoints==0)return(0);
   return(Sym.NormalizePrice(Sym.Ask()-Sym.Point()*StopLossPoints));
}

//+------------------------------------------------------------------+
//|   Function for calculating the Take Profit for a buy position                            |
//+------------------------------------------------------------------+
double SolveBuyTP(int TakeProfitPoints)
{
   if(TakeProfitPoints==0)return(0);
   return(Sym.NormalizePrice(Sym.Ask()+Sym.Point()*TakeProfitPoints));  
}

//+------------------------------------------------------------------+
//|   Function for calculating the Stop Loss for a sell position                               |
//+------------------------------------------------------------------+
double SolveSellSL(int StopLossPoints)
{
   if(StopLossPoints==0)return(0);
   return(Sym.NormalizePrice(Sym.Bid()+Sym.Point()*StopLossPoints));
}

//+------------------------------------------------------------------+
//|   Function for calculating the Take Profit for a sell position                             |
//+------------------------------------------------------------------+
double SolveSellTP(int TakeProfitPoints)
{
   if(TakeProfitPoints==0)return(0);
   return(Sym.NormalizePrice(Sym.Bid()-Sym.Point()*TakeProfitPoints));  
}

//+------------------------------------------------------------------+
//|   Function for calculating the minimum Stop Loss for a buy position                  |
//+------------------------------------------------------------------+
double BuyMSL()
{
   return(Sym.NormalizePrice(Sym.Bid()-Sym.Point()*Sym.StopsLevel()));
}

//+------------------------------------------------------------------+
//|   Function for calculating the minimum Take Profit for a buy position                |
//+------------------------------------------------------------------+
double BuyMTP()
{
   return(Sym.NormalizePrice(Sym.Ask()+Sym.Point()*Sym.StopsLevel()));
}

//+------------------------------------------------------------------+
//|   Function for calculating the minimum Stop Loss for a sell position                 |
//+------------------------------------------------------------------+
double SellMSL()
{
   return(Sym.NormalizePrice(Sym.Ask()+Sym.Point()*Sym.StopsLevel()));
}

//+------------------------------------------------------------------+
//|   Function for calculating the minimum Take Profit for a sell position               |
//+------------------------------------------------------------------+
double SellMTP()
{
   return(Sym.NormalizePrice(Sym.Bid()-Sym.Point()*Sym.StopsLevel()));
}

//+------------------------------------------------------------------+
//|   Function for checking the Stop Loss for a buy position                                 |
//+------------------------------------------------------------------+
bool CheckBuySL(double StopLossPrice)
{
   if(StopLossPrice==0)return(true);
   return(StopLossPrice<BuyMSL());
}

//+------------------------------------------------------------------+
//|   Function for checking the Take Profit for a buy position                               |
//+------------------------------------------------------------------+
bool CheckBuyTP(double TakeProfitPrice)
{
   if(TakeProfitPrice==0)return(true);
   return(TakeProfitPrice>BuyMTP());
}

//+------------------------------------------------------------------+
//|   Function for checking the Stop Loss for a sell position                                 |
//+------------------------------------------------------------------+
bool CheckSellSL(double StopLossPrice)
{
   if(StopLossPrice==0)return(true);
   return(StopLossPrice>SellMSL());
}

//+------------------------------------------------------------------+
//|   Function for checking the Take Profit for a sell position                              |
//+------------------------------------------------------------------+
bool CheckSellTP(double TakeProfitPrice)
{
   if(TakeProfitPrice==0)return(true);
   return(TakeProfitPrice<SellMTP());
}

