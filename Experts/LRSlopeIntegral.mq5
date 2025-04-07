//+------------------------------------------------------------------------+
//|                                                    LRSlopeIntegral.mq5 |
//|                                                     Yong-su, Kim       |
//|                                             https://www.mql5.com       |
//+------------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#define TIME_ADD_MINUTE 60;
#define IND1 "LRSlopeSquareIntegral"
#define IND2 "NormalizeMACD"
#define 

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/PositionInfo.mqh>

CTrade Trade;
CDealInfo Deal;
CSymbolInfo Sym;
CPositionInfo Pos;


//--- input parameters
sinput   const string  Message1="";// Signal Input Parameter
input double               slopeMultiFactor  = 1.0;           //Slope MultiFactor
input double               MACDMultiFactor   = 1.0;           // MACD MultiFactor

sinput   const string  Message2="";//Trading Time parameter
input    int               StartTime           = 5;            // Starting Time (Server Time)
input    int               EndTime             = 22;           // Ending(Last Open Position) Time (Server Time)

sinput   const string  Message3="";//EA Parameter
input int                  iMagicNumber        =  10000;       // Magic Number
input double               Lots                =  0.01;        /*Lots*/             // Lot; if the value is 0, MaximumRisk value is used
input double               MaximumRisk         =  1;           /*MaximumRisk*/      // Risk (it is used if Lots=0) 0.01lot/1000$
input int                  StopLoss            =  1000;        /*StopLoss*/         // Stop Loss in points
input int                  TakeProfit          =  0;           /*TakeProfit*/       // Take Profit in points
input bool                 VirtualSLTP         =  true;        /*VirtualSLTP*/      // Stop Loss and Take Profit are not set. Instead, a position is closed upon reaching loss or profit as specified in the StopLoss and TakeProfit parameters.
input int                  ReOpenInterval      = 0;            //ReStart Trading Minute
input int                  Shift               = 1;             /*Shift*/            // The bar on which the indicator values are checked: 0 - new forming bar, 1 - first completed bar

//Signal1 input Parameter
int            inpChPeriod1 = (int)1000*slopeMultiFactor;          //Long Period
int            inpChPeriod2 = 3;           //Square Period
int            avgPeriod = 900;             //AvgPeriod

//Signal2 input Parameter
int inpFastPeriod   = (int)6*MACDMultiFactor;           // MACD fast period
int inpSlowPeriod   = (int)13*MACDMultiFactor;           // MACD slow period
int inpMacdSignal   = (int)5*MACDMultiFactor;            // Signal period





enum Trend
  {
   UpTrend,      
   DownTrend,        
  };
Trend MACDTrend, LRsquareTrend;


int MACDHandle=INVALID_HANDLE;
int LRsquareHandle = INVALID_HANDLE;

double LRsquareBuffer[], MACDUpperBuffer[], MACDLowerBuffer[];




double lot,slv=0,msl,tpv=0,mtp;

bool _VirtualSLTP;
datetime ReStartTradingTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){

   Trade.SetExpertMagicNumber(iMagicNumber);

   _VirtualSLTP=VirtualSLTP;
   if(_VirtualSLTP && StopLoss<=0 && TakeProfit<=0){
      _VirtualSLTP=false;
   }

   // Loading indicators..
   LRsquareHandle=iCustom(_Symbol,_Period,IND1, inpChPeriod1, inpChPeriod2, avgPeriod);
   MACDHandle = iCustom(_Symbol,_Period,IND1, inpFastPeriod, inpSlowPeriod, inpMacdSignal);
   if(LRsquareHandle==INVALID_HANDLE || MACDHandle == INVALID_HANDLE ){
      Alert("Error when loading the indicator, please try again");
      return(-1);
   }  
  
   if(!Sym.Name(_Symbol)){
      Alert("CSymbolInfo initialization error, please try again");    
      return(-1);
   }

   ArraySetAsSeries(LRsquareBuffer, true);
   ArraySetAsSeries(MACDUpperBuffer, true);
   ArraySetAsSeries(MACDLowerBuffer, true);
   
   Print("Initialization of the Expert Advisor complete");
  
   return(0);
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
   if(LRsquareHandle!=INVALID_HANDLE) IndicatorRelease(LRsquareHandle);
   if(MACDHandle!=INVALID_HANDLE) IndicatorRelease(MACDHandle);
   
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){

   bool CloseBuy=false,
        CloseSell=false,
        OpenBuy=false,
        OpenSell=false;
   

   if(isNewBar(_Symbol)){

      if(!Indicators()) return;  

      CloseBuy = SignalCloseBuy();
      CloseSell = SignalCloseSell();

      if( Times() ){
          OpenBuy = SignalOpenBuy();
          OpenSell = SignalOpenSell();      
      }

      if( CloseBuy ){
         ClosePosition(POSITION_TYPE_BUY);
      }
      
      if( CloseSell ){
          ClosePosition(POSITION_TYPE_SELL);
      }
      
      if(OpenBuy){
          OpenPosition(POSITION_TYPE_BUY);
      }
      
      if(OpenSell){
        OpenPosition(POSITION_TYPE_SELL);
      }      
      
   }
    
   Virtual_SLTP();

}


//+------------------------------------------------------------------+
//|   Function for copying indicator data and price                   |
//+------------------------------------------------------------------+
bool Indicators(){
   if(
      CopyBuffer(LRsquareHandle,0,Shift,1,LRsquareBuffer)==-1 ||
      CopyBuffer(MACDHandle,0,Shift,1,ma)==-1 ||
      CopyBuffer(MACDHandle,2,Shift,1,lowerBuffer)==-1
   ){
      return(false);
   }

   if(NormalizeDouble(NLRTrendBuffer[1], 0) == 2.) NLRTrend0 = UpTrend;
   else NLRTrend0 = DownTrend; 
   
   if(NormalizeDouble(NLRTrendBuffer[2], 0) == 2.) NLRTrend1 = UpTrend;
   else NLRTrend1 = DownTrend; 
   
   upperChannelValue = upperBuffer[1];
   lowerChannelValue = lowerBuffer[1];
   
   return(true);
}


//+------------------------------------------------------------------+
//|   Function for determining buy signals                           |
//+------------------------------------------------------------------+
bool SignalOpenBuy(){

   if( (NumberOfOrders(POSITION_TYPE_BUY)<=0) && (Sym.Bid() > upperChannelValue) ){
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//|   Function for determining sell signals                           |
//+------------------------------------------------------------------+
bool SignalOpenSell(){

   if((NumberOfOrders(POSITION_TYPE_SELL)<=0) && (Sym.Bid() < lowerChannelValue) ){
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//|   Function for determining buy closing signals                  |
//+------------------------------------------------------------------+
bool SignalCloseBuy(){

   if((NumberOfOrders(POSITION_TYPE_BUY)>=1) && (NLRTrend1 == UpTrend) && (NLRTrend0 == DownTrend )){
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//|   Function for determining sell closing signals                  |
//+------------------------------------------------------------------+
bool SignalCloseSell(){

   if((NumberOfOrders(POSITION_TYPE_SELL)>=1) && (NLRTrend1 == DownTrend) && (NLRTrend0 == UpTrend ) ){
      return(true);
   }
   return(false); 

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