//+------------------------------------------------------------------+
//|                                                  TVI-Perfect.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#define IND1 "NonLR"
#define IND2 "TVI"


#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/PositionInfo.mqh>

CTrade Trade;
CDealInfo Deal;
CSymbolInfo Sym;
CPositionInfo Pos;

//--- input parameters
sinput   const string Time="";//-=[ Time Settings ]=-
input    int               StartTime           = 2;       // Opening Time (Server Time)
input    int               EndTime             = 22;      // Last Open Position Time (Server Time)
input    int               iMagicNumber        = 1000;   // Magic Number
input double               Lots                =  0.01;           /*Lots*/             // Lot; if the value is 0, MaximumRisk value is used
input double               MaximumRisk         =  1;          /*MaximumRisk*/      // Risk (it is used if Lots=0) 0.01lot/1000$
input bool                 VirtualSLTP         =  true;          /*VirtualSLTP*/      // Stop Loss and Take Profit are not set. Instead, a position is closed upon reaching loss or profit as specified in the StopLoss and TakeProfit parameters.
input int                  StopLoss            =  100;           /*StopLoss*/         // Stop Loss in points
input int                  TakeProfit          =  0;             /*TakeProfit*/       // Take Profit in points
//Trend input
input ENUM_TIMEFRAMES      LNLTimeFrame         = PERIOD_M1;
input ENUM_TIMEFRAMES      MNLTimeFrame         = PERIOD_M5;
input ENUM_TIMEFRAMES      SNLTimeFrame         = PERIOD_M30;
input ENUM_TIMEFRAMES      TVITimeFrame         = PERIOD_M1;
input int                  inpPeriod          = 25;          // Period
input ENUM_APPLIED_PRICE   inpPrice           = PRICE_CLOSE; // Price

int Shift= 0;             /*Shift*/            // The bar on which the indicator values are checked: 0 - new forming bar, 1 - first completed bar

enum Trend
  {
   UpTrend,      
   DownTrend,        
  };
Trend LongTrend, MediumTrend, ShortTrend;


int LNLHandle=INVALID_HANDLE, MNLHandle=INVALID_HANDLE, SNLHandle=INVALID_HANDLE, TVIHandle=INVALID_HANDLE ;

double lt[2], mt[2], st[2];

double lot,slv=0,msl,tpv=0,mtp;

bool _VirtualSLTP;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){

   Trade.SetExpertMagicNumber(iMagicNumber);
   _VirtualSLTP=VirtualSLTP;
   if(_VirtualSLTP && StopLoss<=0 && TakeProfit<=0){
      _VirtualSLTP=false;
   }

   // Loading indicators...
   LNLHandle=iCustom(_Symbol,LNLTimeFrame,IND1, inpPeriod, inpPrice);
   MNLHandle=iCustom(_Symbol,MNLTimeFrame,IND1, inpPeriod, inpPrice);
   SNLHandle=iCustom(_Symbol,SNLTimeFrame,IND1, inpPeriod, inpPrice);
   TVIHandle=iCustom(_Symbol,TVITimeFrame,IND2);

   if((LNLHandle==INVALID_HANDLE) || (MNLHandle==INVALID_HANDLE) || (SNLHandle==INVALID_HANDLE) || (TVIHandle==INVALID_HANDLE)){
      Alert("Error when loading the indicator, please try again");
      return(-1);
   }  
  
   if(!Sym.Name(_Symbol)){
      Alert("CSymbolInfo initialization error, please try again");    
      return(-1);
   }

   Print("Initialization of the Expert Advisor complete");
  
   return(0);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
   if(LNLHandle!=INVALID_HANDLE)IndicatorRelease(LNLHandle);
   if(MNLHandle!=INVALID_HANDLE)IndicatorRelease(MNLHandle);
   if(SNLHandle!=INVALID_HANDLE)IndicatorRelease(SNLHandle);
   if(TVIHandle!=INVALID_HANDLE)IndicatorRelease(TVIHandle);

}




//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){

/*   bool CloseBuy=false,
        CloseSell=false,
        OpenBuyNewBar=false,
        OpenSellNewBar=false;
   
   if(!Indicators()) return;  

   if(isNewBar(_Symbol)){
      CloseBuy = SignalCloseBuy();
      CloseSell = SignalCloseSell();

      if(Times()){
          OpenBuyNewBar = SignalOpenBuyNewBar();
          OpenSellNewBar = SignalOpenSellNewBar();      
      }
   }

   if( CloseBuy ) {
      ClosePosition(POSITION_TYPE_BUY);
   }
   if( CloseSell ){
       ClosePosition(POSITION_TYPE_SELL);
   }
   if(OpenBuyNewBar){
       OpenPosition(POSITION_TYPE_BUY);
   }
   if(OpenSellNewBar){
       OpenPosition(POSITION_TYPE_SELL);
   }
*/    
   Virtual_SLTP();
}


void Virtual_SLTP(){

   if(!_VirtualSLTP)return;
        
   if(!Sym.RefreshRates()) return;  

   uint total=PositionsTotal();
   if(total<=0) return;
   
   for(uint i=0; i<total; i++){

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


void OpenPosition(ENUM_POSITION_TYPE m_PositionType)
{

   if(!Sym.RefreshRates())return;        
   if(!SolveLots(lot))return;
   
   if(m_PositionType == POSITION_TYPE_BUY){

      if(!VirtualSLTP){
         slv=SolveBuySL(StopLoss);
         tpv=SolveBuyTP(TakeProfit);
      }
                  
      if(CheckBuySL(slv) && CheckBuyTP(tpv)){

        Trade.SetDeviationInPoints(Sym.Spread()*3);
        if(! Trade.Buy(lot,_Symbol,0,slv,tpv,""))  return;        
      }else  Print("Cannot open a Buy position, nearing the Stop Loss or Take Profit");
   }


   if(m_PositionType == POSITION_TYPE_SELL){
      
      if(!VirtualSLTP){
         slv=SolveSellSL(StopLoss);
         tpv=SolveSellTP(TakeProfit);
      }
   
      if(CheckSellSL(slv) && CheckSellTP(tpv)){
         Trade.SetDeviationInPoints(Sym.Spread()*3);
         if(! Trade.Sell(lot,_Symbol,0,slv,tpv,"")) return;         
      }else Print("Cannot open a Sell position, nearing the Stop Loss or Take Profit");
   }   
}                           
    

void ClosePosition(ENUM_POSITION_TYPE m_PositionType)
{

   if(!Sym.RefreshRates())return;        

   for(int k=PositionsTotal()-1; k>=0; k--){

      if(Pos.SelectByIndex(k)){
         if((PositionGetSymbol(k) == _Symbol) && (PositionGetInteger(POSITION_MAGIC) == iMagicNumber) &&
             (PositionGetInteger(POSITION_TYPE)==m_PositionType) )

               Trade.SetDeviationInPoints(Sym.Spread()*3);

               Trade.PositionClose(PositionGetInteger(POSITION_TICKET));
      
      }
   }
}
 

//+------------------------------------------------------------------+
//|   Function for determining the lot based on the trade results               |
//+------------------------------------------------------------------+
bool SolveLots(double & aLots)
{
   if(Lots==0){
      aLots=fLotsNormalize(AccountInfoDouble(ACCOUNT_MARGIN_FREE)*MaximumRisk*100./1000.0);
      return(true);        
   }else{
      aLots=Lots; 
      return(true);       
   }

   return(false);
}

//+------------------------------------------------------------------+
//|   Lot normalization function                                      |
//+------------------------------------------------------------------+
double fLotsNormalize(double aLots){
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


/*
//+------------------------------------------------------------------+
//|   Function for copying indicator data and price                   |
//+------------------------------------------------------------------+
bool Indicators(){
   if(
      CopyBuffer(Handle,0,Shift,2,st)==-1 ||
      CopyBuffer(Handle,1,Shift,2,mt)==-1 ||
      CopyBuffer(Handle,2,Shift,2,lt)==-1
   ){
      return(false);
   }

   if((lt[1]-lt[0])>0) LongTrend = UpTrend;
   else LongTrend = DownTrend; 

   if((mt[1]-mt[0])>0) MediumTrend = UpTrend;
   else MediumTrend = DownTrend;
   
   if((st[1]-st[0])>0) ShortTrend = UpTrend;
   else ShortTrend = DownTrend;

   return(true);
}

*/
//+------------------------------------------------------------------+
//|   Function for determining buy signals                           |
//+------------------------------------------------------------------+
bool SignalOpenBuyNewBar(){

   if( (NumberOfOrders(POSITION_TYPE_BUY)<=0) && (LongTrend==UpTrend) && (MediumTrend==UpTrend) && (ShortTrend == UpTrend)){
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//|   Function for determining sell signals                           |
//+------------------------------------------------------------------+
bool SignalOpenSellNewBar(){

   if((NumberOfOrders(POSITION_TYPE_SELL)<=0) && (LongTrend==DownTrend) && (MediumTrend==DownTrend) && (ShortTrend == DownTrend) ){
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//|   Function for determining buy closing signals                  |
//+------------------------------------------------------------------+
bool SignalCloseBuy(){

   if((NumberOfOrders(POSITION_TYPE_BUY)>=1) && (MediumTrend==DownTrend) ){
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//|   Function for determining sell closing signals                  |
//+------------------------------------------------------------------+
bool SignalCloseSell(){

   if((NumberOfOrders(POSITION_TYPE_SELL)>=1) && (MediumTrend==UpTrend) ){
      return(true);
   }
   return(false); 

}

//+------------------------------------------------------------------+
//|   Function for calculating the Stop Loss for a buy position                               |
//+------------------------------------------------------------------+
double SolveBuySL(int StopLossPoints){
   if(StopLossPoints==0)return(0);
   return(Sym.NormalizePrice(Sym.Ask()-Sym.Point()*StopLossPoints));
}

//+------------------------------------------------------------------+
//|   Function for calculating the Take Profit for a buy position                            |
//+------------------------------------------------------------------+
double SolveBuyTP(int TakeProfitPoints){
   if(TakeProfitPoints==0)return(0);
   return(Sym.NormalizePrice(Sym.Ask()+Sym.Point()*TakeProfitPoints));  
}

//+------------------------------------------------------------------+
//|   Function for calculating the Stop Loss for a sell position                               |
//+------------------------------------------------------------------+
double SolveSellSL(int StopLossPoints){
   if(StopLossPoints==0)return(0);
   return(Sym.NormalizePrice(Sym.Bid()+Sym.Point()*StopLossPoints));
}

//+------------------------------------------------------------------+
//|   Function for calculating the Take Profit for a sell position                             |
//+------------------------------------------------------------------+
double SolveSellTP(int TakeProfitPoints){
   if(TakeProfitPoints==0)return(0);
   return(Sym.NormalizePrice(Sym.Bid()-Sym.Point()*TakeProfitPoints));  
}

//+------------------------------------------------------------------+
//|   Function for calculating the minimum Stop Loss for a buy position                  |
//+------------------------------------------------------------------+
double BuyMSL(){
   return(Sym.NormalizePrice(Sym.Bid()-Sym.Point()*Sym.StopsLevel()));
}

//+------------------------------------------------------------------+
//|   Function for calculating the minimum Take Profit for a buy position                |
//+------------------------------------------------------------------+
double BuyMTP(){
   return(Sym.NormalizePrice(Sym.Ask()+Sym.Point()*Sym.StopsLevel()));
}

//+------------------------------------------------------------------+
//|   Function for calculating the minimum Stop Loss for a sell position                 |
//+------------------------------------------------------------------+
double SellMSL(){
   return(Sym.NormalizePrice(Sym.Ask()+Sym.Point()*Sym.StopsLevel()));
}

//+------------------------------------------------------------------+
//|   Function for calculating the minimum Take Profit for a sell position               |
//+------------------------------------------------------------------+
double SellMTP(){
   return(Sym.NormalizePrice(Sym.Bid()-Sym.Point()*Sym.StopsLevel()));
}

//+------------------------------------------------------------------+
//|   Function for checking the Stop Loss for a buy position                                 |
//+------------------------------------------------------------------+
bool CheckBuySL(double StopLossPrice){
   if(StopLossPrice==0)return(true);
   return(StopLossPrice<BuyMSL());
}

//+------------------------------------------------------------------+
//|   Function for checking the Take Profit for a buy position                               |
//+------------------------------------------------------------------+
bool CheckBuyTP(double TakeProfitPrice){
   if(TakeProfitPrice==0)return(true);
   return(TakeProfitPrice>BuyMTP());
}

//+------------------------------------------------------------------+
//|   Function for checking the Stop Loss for a sell position                                 |
//+------------------------------------------------------------------+
bool CheckSellSL(double StopLossPrice){
   if(StopLossPrice==0)return(true);
   return(StopLossPrice>SellMSL());
}

//+------------------------------------------------------------------+
//|   Function for checking the Take Profit for a sell position                              |
//+------------------------------------------------------------------+
bool CheckSellTP(double TakeProfitPrice){
   if(TakeProfitPrice==0)return(true);
   return(TakeProfitPrice<SellMTP());
}


//+------------------------------------------------------------------------+
//|  Function for calculat the number of buy or sell orders by this EA     |
//+------------------------------------------------------------------------+

int NumberOfOrders(ENUM_POSITION_TYPE m_Type)
{
   int numbers  = 0;

   for(int i=PositionsTotal()-1; i>=0; i--){
 
      if(Pos.SelectByIndex(i)){
      
         if( (PositionGetSymbol(i) == _Symbol) && (PositionGetInteger(POSITION_MAGIC) == iMagicNumber) &&
             (PositionGetInteger(POSITION_TYPE)==m_Type)) numbers+=1;
      }       
   }       
 
   return (numbers);
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

bool Times()
 {
   MqlDateTime currTime;
   TimeCurrent(currTime);
   int hour0 = currTime.hour;

   if(StartTime < EndTime)
      if(hour0 < StartTime || hour0 >= EndTime)
         return (false);

   if(StartTime > EndTime)
      if(hour0 >= EndTime || hour0 < StartTime)
         return(false);

   return (true);
 }