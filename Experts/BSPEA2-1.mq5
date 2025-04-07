//+------------------------------------------------------------------+
//|                                                     BSPEA2-1.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#define TIME_ADD_MINUTE 60;
#define IND1 "BSP104NLRSTD"
#define IND2 "BSP104LWMA"
#define IND3 "BSP104LWMAPRESTD"
#define IND4 "BSP104LWMALR"
#define IND5 "NonLR"


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
input int                  ShortWmaPeriod    = 30;          // ShortWmaPeriod1
input int                  ShortLRPeriod     = 5;           // ShortLRPeriod
input int                  ShortAvgPeriod    = 60;          // ShortAvgPeriod
input int                  ShortStdPeriod    = 1440;        // ShortStdPeriod
input double               ShortMultiFactor  = 1.5;         // ShortStdMultiFactor

input int                  LongWmaPeriod     = 100;          // LongWmaPeriod1
input int                  LongLRPeriod      = 5;            // LongLRPeriod
input int                  LongAvgPeriod     = 60;           // LongAvgPeriod
input int                  LongStdPeriod     = 2880;         // LongStdPeriod
input double               LongMultiFactor   = 0.7;          // LongStdMultiFactor

input int                  LwmaInpPeriod     =  6;           // LWMAPeriod

input int                  PreStdInpPeriod   =  6;           // PreStdPeriod
input int                  PreStdPeriod      = 1440;         // PreStdStdPeriod
input double               PreStdMultiFactor = 0.2;          // PreStdStdMultiFactor

input int                  LwmaLRInpPeriod   =  6;           // LWMALRPeriod
input int                  LwmaLRPeriod      = 3;            // LWMALR-LR Period

input int                  NonLRPeriod       = 20;           // NonLR Period


sinput   const string  Message2="";//Trading Time parameter
input    int               StartTime           = 2;            // Starting Time (Server Time)
input    int               EndTime             = 22;           // Ending(Last Open Position) Time (Server Time)
input    int               ClickSecond         = 60;           // TimePeriod to execute

sinput   const string  Message3="";//EA Parameter
input    int               iMagicNumber        =  10000;       // Magic Number
input    int               CanOpenBarAfter     =  10;          //Number of bar after Inside Bar
input double               Lots                =  0.01;        /*Lots*/             // Lot; if 0, MaximumRisk value is used
input double               MaximumRisk         =  1;           /*MaximumRisk*/      // Risk(if Lots=0) 0.01lot/1000$
input int                  StopLoss            =  0;        /*StopLoss*/            // Stop Loss in points
input int                  TakeProfit          =  0;           /*TakeProfit*/       // Take Profit in points
input bool                 VirtualSLTP         =  false;        /*VirtualSLTP*/     // Stop Loss, Take Profit setting.

int Shift= 1;             /*Shift*/            // The bar on which the indicator values are checked: 0 - new forming bar, 1 - first completed bar

enum BandState
  {
   Upper,
   Inside,      
   Lower,        
  };
BandState ShortNlrStdState, LongNlrStdState;

enum trend
  {
   UpTrend,
   DownTrend, 
   NoTrend,       
  };
trend NLRTrend;

struct position_Info
{
   int    numberOfPositions;
   double sizeOfPositions;
   double startingPrice;
   double lastPrice;
   double stopLossBSPValue;
   double takeProfitBSPValue;
};
position_Info LongPositionInfo, ShortPositionInfo;


struct open_Ready
{
   bool   shortEnter;
   bool   shortExit;
   bool   LongEnter;
   bool   LongExit;

   int    canOpenBar;
};
open_Ready LongOpenReady, ShortOpenReady;


int ShortNlrStdHandle = INVALID_HANDLE,
    LongNlrStdHandle  = INVALID_HANDLE,
    LwmaHandle        = INVALID_HANDLE,
    LwmaPreStdHandle  = INVALID_HANDLE,
    LwmaLRHandle      = INVALID_HANDLE, 
    NonLRHandle       = INVALID_HANDLE;

double ShortNlrStdUpBand[], ShortNlrStdDownBand[], ShortNlrStdBuffer[], 
       LongNlrStdUpBand[], LongNlrStdDownBand[], LongNlrStdBuffer[], 
       LwmaBuffer[], LwmaPreStdBuffer[], LwmaLRBuffer[], LwmaColorBuffer[], NonLRColorBuffer[];

double lot,slv=0,msl,tpv=0,mtp, BSPStopLossValue;

bool _VirtualSLTP;

datetime NextClick;
bool FirstClick=true;

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
   ShortNlrStdHandle = iCustom(_Symbol,PERIOD_M1,IND1, ShortWmaPeriod, ShortLRPeriod, ShortAvgPeriod, 
                                                       ShortStdPeriod, ShortMultiFactor);
   LongNlrStdHandle  = iCustom(_Symbol,PERIOD_M1,IND1, LongWmaPeriod, LongLRPeriod, LongAvgPeriod, 
                                                       LongStdPeriod, LongMultiFactor);
   LwmaHandle       = iCustom(_Symbol,PERIOD_M1,IND2, LwmaInpPeriod);
   LwmaPreStdHandle  = iCustom(_Symbol,PERIOD_M1,IND3, PreStdInpPeriod, PreStdPeriod, PreStdMultiFactor);
   LwmaLRHandle      = iCustom(_Symbol,PERIOD_M1,IND4, LwmaLRInpPeriod, LwmaLRPeriod);
   NonLRHandle       = iCustom(_Symbol,PERIOD_M1,IND5, NonLRPeriod);

   if(ShortNlrStdHandle==INVALID_HANDLE || LongNlrStdHandle==INVALID_HANDLE || 
      LwmaHandle==INVALID_HANDLE || LwmaPreStdHandle==INVALID_HANDLE || 
      LwmaLRHandle==INVALID_HANDLE || NonLRHandle==INVALID_HANDLE )
   {
      Alert("Error when loading the indicator, please try again");
      return(-1);
   }  
  
   if(!Sym.Name(_Symbol)){
      Alert("CSymbolInfo initialization error, please try again");    
      return(-1);
   }

   ArraySetAsSeries(ShortNlrStdUpBand, true);
   ArraySetAsSeries(ShortNlrStdDownBand, true);
   ArraySetAsSeries(ShortNlrStdBuffer, true);
   ArraySetAsSeries(LongNlrStdUpBand, true);
   ArraySetAsSeries(LongNlrStdDownBand, true);
   ArraySetAsSeries(LongNlrStdBuffer, true);
   ArraySetAsSeries(LwmaBuffer, true);
   ArraySetAsSeries(LwmaColorBuffer, true);
   ArraySetAsSeries(LwmaPreStdBuffer, true);
   ArraySetAsSeries(LwmaLRBuffer, true);
   ArraySetAsSeries(NonLRColorBuffer, true);

   PositionInfo();
        
   return(0);
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

   if(ShortNlrStdHandle  != INVALID_HANDLE)  IndicatorRelease(ShortNlrStdHandle);
   if(LongNlrStdHandle   != INVALID_HANDLE)  IndicatorRelease(LongNlrStdHandle);
   if(LwmaHandle         != INVALID_HANDLE)  IndicatorRelease(LwmaHandle);   
   if(LwmaPreStdHandle   != INVALID_HANDLE)  IndicatorRelease(LwmaPreStdHandle);
   if(LwmaLRHandle       != INVALID_HANDLE)  IndicatorRelease(LwmaLRHandle);
   if(NonLRHandle        != INVALID_HANDLE)  IndicatorRelease(NonLRHandle);   

}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){

   bool OpenBuy=false,
        OpenSell=false,   
        CloseBuy=false,
        CloseSell=false;
   
   datetime curTime=TimeCurrent();     
         
   if(!Indicators()) return;  
/*   
   if( isNewBar(_Symbol) ) {

      if(PositionsTotal() >= 1)
      {
                     
         CloseBuy = SignalCloseBuy();
         if(CloseBuy){
             ClosePosition(POSITION_TYPE_BUY);
         }    
            
         CloseSell = SignalCloseSell();
         if(CloseSell){
            ClosePosition(POSITION_TYPE_SELL);
         }       
      }
      

      if(Times(curTime))
      {

         OpenBuy = SignalOpenBuy();
         if(OpenBuy ){
             OpenPosition(POSITION_TYPE_BUY);
         }    
   
         OpenSell = SignalOpenSell();      
         if(OpenSell){
            OpenPosition(POSITION_TYPE_SELL);
         }
         
      }
      
      
   }   
*/
//   Virtual_SLTP();

}



//+------------------------------------------------------------------+
//|   Function for copying indicator data and price                   |
//+------------------------------------------------------------------+
bool Indicators(){

   if(CopyBuffer(ShortNlrStdHandle,  0,  Shift,  1,  ShortNlrStdBuffer)     == -1   ||
      CopyBuffer(ShortNlrStdHandle,  2,  Shift,  1,  ShortNlrStdUpBand)     == -1   ||
      CopyBuffer(ShortNlrStdHandle,  3,  Shift,  1,  ShortNlrStdDownBand)   == -1   ||
      CopyBuffer(LongNlrStdHandle,   0,  Shift,  1,  LongNlrStdBuffer)      == -1   ||
      CopyBuffer(LongNlrStdHandle,   2,  Shift,  1,  LongNlrStdUpBand)      == -1   ||
      CopyBuffer(LongNlrStdHandle,   3,  Shift,  1,  LongNlrStdDownBand)    == -1   ||
      CopyBuffer(LwmaHandle,         0,  Shift,  1,  LwmaBuffer)            == -1   ||
      CopyBuffer(LwmaHandle,         1,  Shift,  1,  LwmaColorBuffer)       == -1   ||
      CopyBuffer(LwmaPreStdHandle,   1,  Shift,  1,  LwmaPreStdBuffer)      == -1   ||
      CopyBuffer(LwmaLRHandle,       0,  Shift,  1,  LwmaLRBuffer)          == -1   ||
      CopyBuffer(NonLRHandle,        1,  Shift,  1,  NonLRColorBuffer)      == -1)   
   {
      return(false);
   }


/*
   if(BSPBuffer[0]>=BSPUpBand[0]) BSPState = Upper;
   else if(BSPBuffer[0]<=BSPDownBand[0]) BSPState = Lower;
   else BSPState = Inside; 

   if(BSPLRBuffer[0] >= 0.) BSPLRState = Plus;
   else BSPLRState = Minus;
         
   if( (int)NormalizeDouble(NLRBuffer[0], 0) == 2) NLRTrend = UpTrend;
   else if( (int)NormalizeDouble(NLRBuffer[0], 0) == 1) NLRTrend = DownTrend;
   else NLRTrend = NoTrend;  

   if((LongPositionInfo.numberOfPositions >= 1)&& (BSPLRState == Minus)){
      LongPositionInfo.canClose = true;
   }else LongPositionInfo.canClose = false;

   if((ShortPositionInfo.numberOfPositions >= 1)&& (BSPLRState == Plus) ){
      ShortPositionInfo.canClose = true;
   }else ShortPositionInfo.canClose = false;

   if((LastBSPState == Upper) && (BSPState == Inside)){
      BSPUpCrossed = true;
      BSPDownCrossed   = false;
   }else if((LastBSPState == Lower) && (BSPState == Inside) ){
      BSPUpCrossed = false;
      BSPDownCrossed   = true;      
   }else{
      BSPUpCrossed = false;
      BSPDownCrossed   = false;         
   }
   
   if(BSPUpCrossed){
      ShortPositionInfo.numOfBarAfter = 1;
   }else if((ShortPositionInfo.numOfBarAfter >= 1) && (ShortPositionInfo.numOfBarAfter <= CanOpenBarAfter) &&
            (BSPState == Inside)){
      ShortPositionInfo.numOfBarAfter += 1;
   }else{
      ShortPositionInfo.numOfBarAfter = 0;
   }   


   if(BSPDownCrossed){
      LongPositionInfo.numOfBarAfter = 1;
   }else if((LongPositionInfo.numOfBarAfter >= 1) && (LongPositionInfo.numOfBarAfter <= CanOpenBarAfter) &&
            (BSPState == Inside)){
      LongPositionInfo.numOfBarAfter += 1;
   }else{
      LongPositionInfo.numOfBarAfter = 0;  
   }   


   if((LongPositionInfo.numberOfPositions == 0) && (BSPState == Lower) && (BSPLRState == Plus)){
      LongPositionInfo.canOpen = true;
   }else if((LongPositionInfo.numberOfPositions == 0) && (LongPositionInfo.numOfBarAfter >=1) &&
            (BSPLRState == Plus) ){
      LongPositionInfo.canOpen = true;      
   }else{
      LongPositionInfo.canOpen = false;
   }

   if((ShortPositionInfo.numberOfPositions == 0) && (BSPState == Upper) && (BSPLRState == Minus)){
      ShortPositionInfo.canOpen = true;
   }else if((ShortPositionInfo.numberOfPositions == 0) && (ShortPositionInfo.numOfBarAfter >=1) &&
            (BSPLRState == Minus) ){
      ShortPositionInfo.canOpen = true;      
   }else{
      ShortPositionInfo.canOpen = false;
   }

   LastBSPState = BSPState;
   
*/   
   return(true);   
}



//+------------------------------------------------------------------+
//|   Function for determining buy signals                           |
//+------------------------------------------------------------------+
bool SignalOpenBuy(){

   if( (NLRTrend ==UpTrend) ){
         return(true);
   } 
   else return(false);
   
}

//+------------------------------------------------------------------+
//|   Function for determining sell signals                           |
//+------------------------------------------------------------------+
bool SignalOpenSell(){

   if( (NLRTrend ==DownTrend) ){
      return(true);
   }   
   else return(false);
   
}


//+------------------------------------------------------------------+
//|   Function for determining buy closing signals                  |
//+------------------------------------------------------------------+
bool SignalCloseBuy(){

   if( (NLRTrend == DownTrend)){
      return(true);
   }   
   return(false);
}

//+------------------------------------------------------------------+
//|   Function for determining sell closing signals                  |
//+------------------------------------------------------------------+
bool SignalCloseSell(){

   if( (NLRTrend == UpTrend)){
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
   
   PositionInfo();
    
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
   
   PositionInfo();
   
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


 
 //+------------------------------------------------------------------------+
//|  Function for calculat the number of buy or sell orders by this EA     |
//+------------------------------------------------------------------------+

void PositionInfo()
{
   LongPositionInfo.numberOfPositions    = 0;
   LongPositionInfo.sizeOfPositions      = 0.;
   LongPositionInfo.startingPrice        = 0.;
   LongPositionInfo.lastPrice            = 0.;
   ShortPositionInfo.numberOfPositions   = 0;
   ShortPositionInfo.sizeOfPositions     = 0.;
   ShortPositionInfo.startingPrice       = 0.;
   ShortPositionInfo.lastPrice           = 0.;

   for(int i=PositionsTotal()-1; i>=0; i--){
 
      if(Pos.SelectByIndex(i)){
      
         if( (PositionGetSymbol(i) == _Symbol) && (PositionGetInteger(POSITION_MAGIC) == iMagicNumber))
         {
         
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
            {
               LongPositionInfo.numberOfPositions += 1;
               LongPositionInfo.sizeOfPositions += PositionGetDouble(POSITION_VOLUME);
               if(LongPositionInfo.startingPrice == 0. || LongPositionInfo.lastPrice == 0.)
               { 
                  LongPositionInfo.startingPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                  LongPositionInfo.lastPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               }   
               if(PositionGetDouble(POSITION_PRICE_OPEN)<LongPositionInfo.startingPrice)
                  LongPositionInfo.startingPrice = PositionGetDouble(POSITION_PRICE_OPEN);  
               if(PositionGetDouble(POSITION_PRICE_OPEN)>LongPositionInfo.lastPrice) 
                  LongPositionInfo.lastPrice =  PositionGetDouble(POSITION_PRICE_OPEN);        
            }
         
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
            {
               ShortPositionInfo.numberOfPositions += 1;
               ShortPositionInfo.sizeOfPositions += PositionGetDouble(POSITION_VOLUME);
               if(ShortPositionInfo.startingPrice == 0. || ShortPositionInfo.lastPrice == 0.)
               { 
                  ShortPositionInfo.startingPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                  ShortPositionInfo.lastPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               }   
               if(PositionGetDouble(POSITION_PRICE_OPEN)>ShortPositionInfo.startingPrice)
                  ShortPositionInfo.startingPrice = PositionGetDouble(POSITION_PRICE_OPEN);  
               if(PositionGetDouble(POSITION_PRICE_OPEN)<ShortPositionInfo.lastPrice) 
                  ShortPositionInfo.lastPrice =  PositionGetDouble(POSITION_PRICE_OPEN);        
             }         
         }
      }       
   }       
 
   return;
}

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