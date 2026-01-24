//+------------------------------------------------------------------+
//|                                                     BSP105V2.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


#define IND1 "NonLR"
#define IND2 "BSP105LRSTDV3AVG"
#define IND3 "BSP105WMA"
#define IND4 "BSP105LRAVGSTDV2"
#define IND5 "BSP105LRSQUARE"
#define IND6 "BSP105BSP"
#define IND7 "BSP105WMAV2"
#define IND8 "BSP105HLAvg"

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/PositionInfo.mqh>

CTrade Trade;
CDealInfo Deal;
CSymbolInfo Sym;
CPositionInfo Pos;



//--- input parameters
sinput   const string  Message1="";// NonLR
input int                 NonLRPeriodS         = 25;          // NonLRPeriodS
input int                 NonLRPeriodL         = 50;          // NonLRPeriodL
sinput   const string  Message2="";// StdAvg
input int                 StdAvgLwmaPeriod     = 50;          // StdAvgWmaPeriod1
input int                 StdAvgLRPeriod       = 5;           // StdAvgLRPeriod
input int                 StdAvgStdPeriodL     = 10000;       // StdAvgStdPeriodL
input int                 StdAvgPeriod         = 3;           // StdAvgStdPeriod
input double              StdAvgMultiFactorL1  = 0.5;         // StdAvgStdMultiFactorL1
input double              StdAvgMultiFactorL2  = 1.0;         // StdAvgStdMultiFactorL2
input double              StdAvgMultiFactorL3  = 2.5;         // StdAvgStdMultiFactorL3
sinput   const string  Message3="";// Wma
input int                 WmaPeriodS           = 10;          // wmaPeriodS
input int                 WmaPeriodL           = 20;          // wmaPeriodL
input int                 WmaPeriodLL          = 50;          // WmaPeriodLL
input int                 WmaPeriod2           = 200;         // WmaPeriod2
sinput   const string  Message4="";// WmaStd
input int                 WmaStdPeriod         = 10000;       // WmaPeriod
input double              WmaMultiFactor1      = 1.0;         // MultiFactor1
input double              WmaMultiFactor2      = 2.0;         // MultiFactor2
input double              WmaMultiFactor3      = 3.0;         // MultiFactor3                 
sinput   const string  Message5="";// AvgStd
input int                 ASLwmaPeriod         = 6;           // ASWmaPeriod1
input int                 ASAvgPeriod          = 20;          // ASAvgPeriod
input int                 ASStdPeriodL         = 10000;       // ASStdPeriodL
input int                 ASStdPeriodS         = 10;          // ASStdPeriodS
input double              ASMultiFactorL1      = 0.8;         // ASStdMultiFactorL1
input double              ASMultiFactorL2      = 1.5;         // ASStdMultiFactorL2
input double              ASMultiFactorL3      = 7.0;         // ASStdMultiFactorL3
sinput   const string  Message6="";// LRSquare
input int                 SqLwmaPeriod         = 3;           // SQWmaPeriod
input int                 SqLRPeriod           = 25;          // SQLRPeriod
input int                 SqLRSPeriod          = 10;          // SQLRSPeriod
input int                 SqStdPeriodL         = 10000;       // SQLong StdPeriod
input int                 SqStdPeriodS         = 10;          // SQShort StdPeriod
input double              SqMultiFactorL       = 1.0;         // SQLong MultiFactorL
input double              SqMultiFactorS       = 0.1;         // SQShort MultiFactorS
sinput   const string  Message7="";// BSPAvg
input int                 BSPWmaPeriod         = 120;         // BSPWmaPeriod
input double              BSPMultiRatio        = 1.0;         // BSPMultiRatio
sinput   const string  Message8="";// HLAvg
input int                 HLWmaPeriod         = 120;          // HLWmaPeriod
input double              HLMultiRatio        = 1.0;          // HLMultiRatio




sinput   const string  Message9="";//Trading Time parameter
input    int              StartTime            = 2;            // Starting Time (Server Time)
input    int              EndTime              = 23;           // Ending(Last Open Position) Time (Server Time)

sinput   const string  Message10="";//EA Parameter
input    int              iMagicNumber         = 10000;       // Magic Number
input double              Lots                 = 0.01;        /*Lots*/             // Lot; if 0, MaximumRisk value is used
input double              MaximumRisk          = 1;           /*MaximumRisk*/      // Risk(if Lots=0) 0.01lot/1000$
input int                 StopLoss             = 0;           /*StopLoss*/            // Stop Loss in points
input int                 TakeProfit           = 0;           /*TakeProfit*/       // Take Profit in points
input bool                VirtualSLTP          = false;       /*VirtualSLTP*/     // Stop Loss, Take Profit setting.
input double              SLBSPMultiFactor     = 0.1;                              //SL BSP Multifactor
input double              TPBSPMultiFactor     = 0.3;                              //TP BSP Multifactor
input double              SLPriceMultiFactor   = 0.3;                              //SL Price Multifactor
input double              TPPriceMultiFactor   = 0.5;                              //TP Price Multifactor


input int                 NumBarReOpen         = 10;                               // Max Number of Bar to ReOpen

int Shift= 1;             /*Shift*/            // The bar on which the indicator values are checked: 0 - new forming bar, 1 - first completed bar
bool StartTrading = false;               // At starting time not to trade.

enum BandState
  {
   BandP3,
   BandP2,
   BandP1,
   BandP0,      
   BandM0,      
   BandM1,
   BandM2,
   BandM3,          
  };
BandState LRStdBand, ASBand, SquareBand, WmaBand;

enum trend
  {
   UpTrend,
   DownTrend, 
   NoTrend,       
  };
trend LongWmaTrend, LLongWmaTrend, ShortWmaTrend, LongNonLRTrend, ShortNonLRTrend, LRStdTrend,  ASTrend, 
      LongNonLRTrend1, ShortNonLRTrend1, LongWmaTrend1, LLongWmaTrend1, ShortWmaTrend1, ASTrend1;

struct position_Info
{
   int    numberOfPositions;
   double sizeOfPositions;
   double startingPrice;
   double lastPrice;
   double stopLossPrice;
   double takeProfitPrice;
};
position_Info BuyPositionInfo, SellPositionInfo;


struct open_Ready
{
   bool   ASReady;
   bool   ShortWmaReady;
};
open_Ready BuyOpenReady, SellOpenReady;

struct close_Ready
{
   bool    ShortNonLReady;
   bool    ShortWmaReady;
   bool    LongNonLReady;
   bool    LongWmaReady;  
   bool    LLongWmaReady; 
   bool    LongWmaChanged;
   bool    ShortMode;
   bool    ReOpenMode;
   int     startingBar;
   double  baseBSP;
   double  ShortStartingBSP;
   double  ShortStopLossBSP;
   double  ShortTakeProfitBSP;
   double  LongStartingBSP;
   double  LongStopLossBSP;
   double  LongTakeProfitBSP;
   
};
close_Ready BuyCloseReady, SellCloseReady;


int NonLRHandleS     = INVALID_HANDLE,
    NonLRHandleL     = INVALID_HANDLE,
    LRStdAvgHandle   = INVALID_HANDLE,
    WmaHandleS       = INVALID_HANDLE,
    WmaHandleL       = INVALID_HANDLE,
    ASHandle         = INVALID_HANDLE,
    BSPHandle        = INVALID_HANDLE, 
    SquareHandle     = INVALID_HANDLE, 
    WmaHandleLL      = INVALID_HANDLE,
    HLHandle         = INVALID_HANDLE;

double ShortNonLRBuffer[], ShortNonLRColorBuffer[],
       LongNonLRBuffer[], LongNonLRColorBuffer[],

       LRStdP1Band[], LRStdP2Band[], LRStdP3Band[], LRStdM1Band[], LRStdM2Band[], 
       LRStdM3Band[], LRStdBuffer[], LRStdColorBuffer[],
       
       ShortWmaBuffer[], ShortWmaColorBuffer[], AvgWmaBuffer[],
       LongWmaBuffer[], LongWmaColorBuffer[], 
       WmaP3Band[], WmaP2Band[], WmaP1Band[], WmaM1Band[],  WmaM2Band[],  WmaM3Band[], 
       LLongWmaBuffer[], LLongWmaColorBuffer[],

       ASBuffer[], ASColorBuffer[], ASP1Band[], ASP2Band[], ASP3Band[], ASM1Band[], ASM2Band[], ASM3Band[],
       SquareBuffer[], SquareP1Band[], SquareM1Band[], 
       
       BSPBuffer[], HLBuffer[];
       

double SLTPBSPValue, ShortWmaValue, LongWmaValue, LLongWmaValue, HLValue, CurPrice;

double lot,slv=0,msl,tpv=0,mtp;

bool _VirtualSLTP;

int TotalNumberOfPositions = 0;

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
   NonLRHandleS      = iCustom(_Symbol,PERIOD_M1,IND1, NonLRPeriodS );
   NonLRHandleL      = iCustom(_Symbol,PERIOD_M1,IND1, NonLRPeriodL );
   LRStdAvgHandle    = iCustom(_Symbol,PERIOD_M1,IND2, StdAvgLwmaPeriod, StdAvgLRPeriod, StdAvgStdPeriodL, StdAvgPeriod, 
                                                       StdAvgMultiFactorL1, StdAvgMultiFactorL2, StdAvgMultiFactorL3);
   WmaHandleS        = iCustom(_Symbol,PERIOD_M1,IND7, WmaPeriodS, WmaPeriod2, WmaStdPeriod, WmaMultiFactor1, 
                                                       WmaMultiFactor2, WmaMultiFactor3 );
   WmaHandleL        = iCustom(_Symbol,PERIOD_M1,IND3, WmaPeriodL, WmaPeriod2);
   WmaHandleLL       = iCustom(_Symbol,PERIOD_M1,IND3, WmaPeriodLL, WmaPeriod2);   
   ASHandle          = iCustom(_Symbol,PERIOD_M1,IND4, ASLwmaPeriod, ASAvgPeriod, ASStdPeriodL, ASStdPeriodS, 
                                                       ASMultiFactorL1, ASMultiFactorL2, ASMultiFactorL3);
   SquareHandle      = iCustom(_Symbol,PERIOD_M1,IND5, SqLwmaPeriod, SqLRPeriod, SqLRSPeriod, SqStdPeriodL, SqStdPeriodS, 
                                                       SqMultiFactorL, SqMultiFactorS);
   BSPHandle         = iCustom(_Symbol,PERIOD_M1,IND6, BSPWmaPeriod, BSPMultiRatio );  
   HLHandle          = iCustom(_Symbol,PERIOD_M1,IND8, HLWmaPeriod, HLMultiRatio );  


   if(NonLRHandleS    == INVALID_HANDLE  || NonLRHandleL    == INVALID_HANDLE || 
      LRStdAvgHandle  == INVALID_HANDLE  || WmaHandleLL     == INVALID_HANDLE ||
      WmaHandleS      == INVALID_HANDLE  || WmaHandleL      == INVALID_HANDLE ||
      BSPHandle       == INVALID_HANDLE  || SquareHandle    == INVALID_HANDLE ||
      ASHandle        == INVALID_HANDLE  || HLHandle        == INVALID_HANDLE )
   {
      Alert("Error when loading the indicator, please try again");
      return(-1);
   }  
  
   if(!Sym.Name(_Symbol)){
      Alert("CSymbolInfo initialization error, please try again");    
      return(-1);
   }

   ArraySetAsSeries(ShortNonLRBuffer, true);
   ArraySetAsSeries(ShortNonLRColorBuffer, true);

   ArraySetAsSeries(LongNonLRBuffer, true);
   ArraySetAsSeries(LongNonLRColorBuffer, true);

   ArraySetAsSeries(LRStdP1Band, true);
   ArraySetAsSeries(LRStdP2Band, true);
   ArraySetAsSeries(LRStdP3Band, true);
   ArraySetAsSeries(LRStdM1Band, true);
   ArraySetAsSeries(LRStdM2Band, true);
   ArraySetAsSeries(LRStdM3Band, true);
   ArraySetAsSeries(LRStdBuffer, true);
   ArraySetAsSeries(LRStdColorBuffer, true);

   ArraySetAsSeries(AvgWmaBuffer, true);
   ArraySetAsSeries(ShortWmaBuffer, true);
   ArraySetAsSeries(ShortWmaColorBuffer, true);
   ArraySetAsSeries(LongWmaBuffer, true);
   ArraySetAsSeries(LongWmaColorBuffer, true);
   ArraySetAsSeries(LLongWmaBuffer, true);
   ArraySetAsSeries(LLongWmaColorBuffer, true);
   ArraySetAsSeries(WmaP3Band, true);
   ArraySetAsSeries(WmaP2Band, true);
   ArraySetAsSeries(WmaP1Band, true);
   ArraySetAsSeries(WmaM1Band, true);
   ArraySetAsSeries(WmaM2Band, true);
   ArraySetAsSeries(WmaM3Band, true);

   ArraySetAsSeries(ASBuffer, true);
   ArraySetAsSeries(ASColorBuffer, true);
   ArraySetAsSeries(ASP1Band, true);
   ArraySetAsSeries(ASP2Band, true);
   ArraySetAsSeries(ASP3Band, true);
   ArraySetAsSeries(ASM1Band, true);
   ArraySetAsSeries(ASM2Band, true);
   ArraySetAsSeries(ASM3Band, true);

   ArraySetAsSeries(SquareBuffer, true);
   ArraySetAsSeries(SquareP1Band, true);
   ArraySetAsSeries(SquareM1Band, true);

   ArraySetAsSeries(BSPBuffer, true);
   ArraySetAsSeries(HLBuffer, true);

   PositionInfo();
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;
   OpenReadyReset();
   CloseReadyReset();
        
   return(0);
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

   if(NonLRHandleS    !=  INVALID_HANDLE)  IndicatorRelease(NonLRHandleS);
   if(NonLRHandleL    !=  INVALID_HANDLE)  IndicatorRelease(NonLRHandleL);
   if(LRStdAvgHandle  !=  INVALID_HANDLE)  IndicatorRelease(LRStdAvgHandle);   
   if(WmaHandleS      !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleS);
   if(WmaHandleL      !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleL);   
   if(WmaHandleLL     !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleLL);   
   if(BSPHandle       !=  INVALID_HANDLE)  IndicatorRelease(BSPHandle);   
   if(SquareHandle    !=  INVALID_HANDLE)  IndicatorRelease(SquareHandle);
   if(ASHandle        !=  INVALID_HANDLE)  IndicatorRelease(ASHandle);  
   if(HLHandle        !=  INVALID_HANDLE)  IndicatorRelease(HLHandle);  

}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){

   if(_Period != PERIOD_M1){
      Alert("TimeFrame should be 1 Minute!");
      return;
   }
     
   bool OpenBuy=false,
        OpenSell=false,   
        CloseBuy=false,
        CloseSell=false;
   
   datetime curTime = TimeCurrent();
      

   if( isNewBar(_Symbol) ) 
     {

      if(!Indicators()) 
        {
         Alert("Indicator Allocation error!");
         return;
        }     

      if( TotalNumberOfPositions >= 1)
        {
                     
         CloseReadyCheck();

         CloseBuy = SignalCloseBuy();
         if(CloseBuy)
           {
            MyBuyClose();
//            if(StartTrading && ReOpenCheck(POSITION_TYPE_SELL) ) 
//              {
//               MySellOpen(true);
//              }
           }    
            
         CloseSell = SignalCloseSell();
         if(CloseSell)
           {
            MySellClose();
//            if(StartTrading && ReOpenCheck(POSITION_TYPE_BUY) ) 
//              {
//               MyBuyOpen(true);
//              } 

           }       
        }
      

      if(StartTrading)
        {

         OpenReadyCheck();

         OpenBuy = SignalOpenBuy();
         if(OpenBuy)
           {
            MyBuyOpen(false);    
           }    
   
         OpenSell = SignalOpenSell();      
         if(OpenSell)
           {
            MySellOpen(false);
           }        
       }          
     }   

//   Virtual_SLTP();

}


//+----------------------------------------------------------------------+
bool SignalCloseBuy()
  {

   if( BuyPositionInfo.numberOfPositions >= 1 )
     {

         if( (ShortWmaValue < BuyCloseReady.ShortStopLossBSP) && 
             (SymbolInfoDouble(_Symbol, SYMBOL_ASK) < BuyPositionInfo.stopLossPrice) )
           {
            return(true);
           }
         if( (ShortWmaValue > BuyCloseReady.ShortTakeProfitBSP) && BuyCloseReady.ShortWmaReady &&
              BuyCloseReady.ShortNonLReady )
           { 
            return(true);
           }
 


/*      
      if(!BuyCloseReady.ShortMode && BuyCloseReady.LongWmaChanged)
        {
         if( (ShortWmaValue < BuyCloseReady.ShortStopLossBSP) && 
             (SymbolInfoDouble(_Symbol, SYMBOL_ASK) < BuyPositionInfo.stopLossPrice) )
           {
            return(true);
           }
         if( (ShortWmaValue > BuyCloseReady.ShortTakeProfitBSP) && BuyCloseReady.ShortWmaReady &&
             (LongWmaTrend1 == DownTrend) && (LongWmaTrend == DownTrend) )
           { 
            return(true);
           }
        }
      else
        {        
         if( (ShortWmaValue < BuyCloseReady.ShortStopLossBSP) && 
             (SymbolInfoDouble(_Symbol, SYMBOL_ASK) < BuyPositionInfo.stopLossPrice) )
           {
            return(true);
           }
         if( (ShortWmaValue > BuyCloseReady.ShortTakeProfitBSP) && BuyCloseReady.ShortWmaReady )
           { 
            return(true);
           }
        }  
*/
     }
     
   return(false);
   
  }

//+----------------------------------------------------------------------+
bool SignalCloseSell()
  {

   if( SellPositionInfo.numberOfPositions >= 1)   
     {

         if( (ShortWmaValue > SellCloseReady.ShortStopLossBSP) && 
             (SymbolInfoDouble(_Symbol, SYMBOL_BID) > SellPositionInfo.stopLossPrice) )
           {
            return(true);
           }
         if( (ShortWmaValue < SellCloseReady.ShortTakeProfitBSP) && SellCloseReady.ShortWmaReady &&
              SellCloseReady.ShortNonLReady)
           {
            return(true);
           } 


/*
      if( !SellCloseReady.ShortMode && SellCloseReady.LongWmaChanged )
        {

         if( (ShortWmaValue > SellCloseReady.ShortStopLossBSP) && 
             (SymbolInfoDouble(_Symbol, SYMBOL_BID) > SellPositionInfo.stopLossPrice) )
           {
            return(true);
           }
         if( (ShortWmaValue < SellCloseReady.ShortTakeProfitBSP) && SellCloseReady.ShortWmaReady &&
             (LongWmaTrend1==UpTrend) && (LongWmaTrend == UpTrend) )
           {
            return(true);
           } 
        }
      else
        {
         if( (ShortWmaValue > SellCloseReady.ShortStopLossBSP) && 
             (SymbolInfoDouble(_Symbol, SYMBOL_BID) > SellPositionInfo.stopLossPrice) )
           {
            return(true);
           }
         if( (ShortWmaValue < SellCloseReady.ShortTakeProfitBSP) && SellCloseReady.ShortWmaReady )
           {
            return(true);
           } 
        
         }  
*/     }

   return(false);
   
  }
  
  
//------------------------------------------------------------------+
void CloseReadyCheck(void)
  {


   if( BuyPositionInfo.numberOfPositions >= 1 )
     {
      if( ShortNonLRTrend == DownTrend) BuyCloseReady.ShortNonLReady = true;
      else BuyCloseReady.ShortNonLReady = false;
      
      if((ShortWmaTrend1 == DownTrend) && (ShortWmaTrend == DownTrend)) BuyCloseReady.ShortWmaReady = true;
      else BuyCloseReady.ShortWmaReady = false;      
      
      if(LongNonLRTrend == DownTrend) BuyCloseReady.LongNonLReady = true;
      else BuyCloseReady.LongNonLReady = false;
      
      if(LongWmaTrend == DownTrend) BuyCloseReady.LongWmaReady = true;
      else BuyCloseReady.LongWmaReady = false;      
      
      if( ASBand == BandP2 || ASBand == BandP3 ) BuyCloseReady.ShortMode = true;
      else BuyCloseReady.ShortMode = false;
      
      if( (LongWmaTrend1 == DownTrend) &&(LongWmaTrend == UpTrend) && (BuyCloseReady.LongWmaChanged == false) ) 
          BuyCloseReady.LongWmaChanged = true;

     }
     
   if( SellPositionInfo.numberOfPositions >= 1)   
     {
      if(ShortNonLRTrend == UpTrend)  SellCloseReady.ShortNonLReady = true;
      else SellCloseReady.ShortNonLReady = false;

      if((ShortWmaTrend1 == UpTrend) && (ShortWmaTrend == UpTrend))  SellCloseReady.ShortWmaReady = true;
      else SellCloseReady.ShortWmaReady = false;
      
      if(LongNonLRTrend == UpTrend)  SellCloseReady.LongNonLReady = true;
      else SellCloseReady.LongNonLReady = false;

      if(LongWmaTrend == UpTrend)  SellCloseReady.LongWmaReady = true;
      else SellCloseReady.LongWmaReady = false;
      
      if( ASBand == BandM2 || ASBand == BandM3 ) SellCloseReady.ShortMode = true; 
      else SellCloseReady.ShortMode = false;

      if( (LongWmaTrend1 == UpTrend) && (LongWmaTrend == DownTrend) && (SellCloseReady.LongWmaChanged == false) ) 
          SellCloseReady.LongWmaChanged = true;

     }
     
  }

//-------------------------------------------------------------------------+
void MyBuyOpen(bool IsReOpen)
  {
      
   if(IsReOpen) 
     {
      OpenPosition(POSITION_TYPE_BUY, "ReOpenBuy");
      BuyCloseReady.ReOpenMode = true;
     }
   else
     {
      OpenPosition(POSITION_TYPE_BUY, "NormalBuy");
      BuyCloseReady.ReOpenMode = false;
     }
    
   BuyCloseReady.startingBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT);
   BuyCloseReady.baseBSP = SLTPBSPValue;
   BuyCloseReady.ShortStartingBSP = ShortWmaValue;
   BuyCloseReady.LongStartingBSP = LongWmaValue;
   BuyCloseReady.ShortStopLossBSP = BuyCloseReady.ShortStartingBSP - SLTPBSPValue*SLBSPMultiFactor;
   BuyCloseReady.LongStopLossBSP = BuyCloseReady.LongStartingBSP - SLTPBSPValue*SLBSPMultiFactor;
   BuyCloseReady.ShortTakeProfitBSP = BuyCloseReady.ShortStartingBSP + SLTPBSPValue*TPBSPMultiFactor;
   BuyCloseReady.LongTakeProfitBSP = BuyCloseReady.LongStartingBSP  + SLTPBSPValue*TPBSPMultiFactor;
    
   PositionInfo(); 
   BuyPositionInfo.stopLossPrice = BuyPositionInfo.startingPrice -  HLValue * SLPriceMultiFactor;
   BuyPositionInfo.takeProfitPrice = BuyPositionInfo.startingPrice + HLValue * TPPriceMultiFactor;
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;    
   OpenReadyReset();

  }

//--------------------------------------------------------------------------+
void MySellOpen(bool IsReOpen)
  {
   
   if(IsReOpen) 
     {
      OpenPosition(POSITION_TYPE_SELL, "ReOpenSell");
      SellCloseReady.ReOpenMode = true;
     }
   else
    {
      OpenPosition(POSITION_TYPE_SELL, "NormalSell");
      SellCloseReady.ReOpenMode = false;
    }
   
   SellCloseReady.startingBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT);
   SellCloseReady.baseBSP = SLTPBSPValue;
   SellCloseReady.ShortStartingBSP = ShortWmaValue;
   SellCloseReady.LongStartingBSP = LongWmaValue;
   SellCloseReady.ShortStopLossBSP = SellCloseReady.ShortStartingBSP + SLTPBSPValue*SLBSPMultiFactor;
   SellCloseReady.LongStopLossBSP = SellCloseReady.LongStartingBSP + SLTPBSPValue*SLBSPMultiFactor;   
   SellCloseReady.ShortTakeProfitBSP = SellCloseReady.ShortStartingBSP - SLTPBSPValue*TPBSPMultiFactor;
   SellCloseReady.LongTakeProfitBSP = SellCloseReady.LongStartingBSP - SLTPBSPValue*TPBSPMultiFactor;
   
   PositionInfo();
   SellPositionInfo.stopLossPrice = SellPositionInfo.startingPrice + HLValue * SLPriceMultiFactor;
   SellPositionInfo.takeProfitPrice = SellPositionInfo.startingPrice - HLValue * TPPriceMultiFactor;
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;   
   OpenReadyReset();

  }


//-------------------------------------------------------------------+
void OpenReadyCheck(void)
  {

   if(BuyPositionInfo.numberOfPositions < 1)
     {
       if( ASBand == BandM2 || ASBand == BandM3  ) BuyOpenReady.ASReady = true;

       if( BuyOpenReady.ASReady && (ShortWmaTrend == UpTrend) ) BuyOpenReady.ShortWmaReady = true;   
       else  BuyOpenReady.ShortWmaReady = false;
     }

   if(SellPositionInfo.numberOfPositions < 1)
     {
      if( ASBand == BandP2 || ASBand == BandP3 ) SellOpenReady.ASReady = true;

      if( SellOpenReady.ASReady && (ShortWmaTrend == DownTrend) ) SellOpenReady.ShortWmaReady = true;   
      else   SellOpenReady.ShortWmaReady = false;   
     }

  }


//+------------------------------------------------------------------+
//|   Function for copying indicator data and price                   |
//+------------------------------------------------------------------+
bool Indicators(){

   double LRStdValue0;
   datetime curTime = TimeCurrent();

   if(CopyBuffer(NonLRHandleS,  0,  Shift,  1, ShortNonLRBuffer)          == -1   ||
      CopyBuffer(NonLRHandleS,  1,  Shift,  1, ShortNonLRColorBuffer)     == -1   ||

      CopyBuffer(NonLRHandleL,  0,  Shift,  1, LongNonLRBuffer)           == -1   ||
      CopyBuffer(NonLRHandleL,  1,  Shift,  1, LongNonLRColorBuffer)      == -1   ||

      CopyBuffer(LRStdAvgHandle,   0,  Shift,  1, LRStdP1Band)            == -1   ||
      CopyBuffer(LRStdAvgHandle,   1,  Shift,  1, LRStdM1Band)            == -1   ||
      CopyBuffer(LRStdAvgHandle,   2,  Shift,  1, LRStdP2Band)            == -1   ||
      CopyBuffer(LRStdAvgHandle,   3,  Shift,  1, LRStdM2Band)            == -1   ||
      CopyBuffer(LRStdAvgHandle,   4,  Shift,  1, LRStdP3Band)            == -1   ||
      CopyBuffer(LRStdAvgHandle,   5,  Shift,  1, LRStdM3Band)            == -1   ||
      CopyBuffer(LRStdAvgHandle,   6,  Shift,  1, LRStdBuffer)            == -1   ||
      CopyBuffer(LRStdAvgHandle,   7,  Shift,  1, LRStdColorBuffer)       == -1   ||

      CopyBuffer(WmaHandleS,       0,  Shift,  1, AvgWmaBuffer)           == -1   ||
      CopyBuffer(WmaHandleS,       1,  Shift,  1, ShortWmaBuffer)         == -1   ||
      CopyBuffer(WmaHandleS,       2,  Shift,  1, ShortWmaColorBuffer)    == -1   ||

      CopyBuffer(WmaHandleS,       3,  Shift,  1, WmaP3Band)              == -1   ||
      CopyBuffer(WmaHandleS,       4,  Shift,  1, WmaP2Band)              == -1   ||
      CopyBuffer(WmaHandleS,       5,  Shift,  1, WmaP1Band)              == -1   ||
      CopyBuffer(WmaHandleS,       6,  Shift,  1, WmaM1Band)              == -1   ||
      CopyBuffer(WmaHandleS,       7,  Shift,  1, WmaM2Band)              == -1   ||
      CopyBuffer(WmaHandleS,       8,  Shift,  1, WmaM3Band)              == -1   ||


      CopyBuffer(WmaHandleL,       1,  Shift,  1, LongWmaBuffer)          == -1   ||
      CopyBuffer(WmaHandleL,       2,  Shift,  1, LongWmaColorBuffer)     == -1   ||

      CopyBuffer(WmaHandleLL,      1,  Shift,  1, LLongWmaBuffer)         == -1   ||
      CopyBuffer(WmaHandleLL,      2,  Shift,  1, LLongWmaColorBuffer)    == -1   ||

      CopyBuffer(ASHandle,         0,  Shift,  1, ASP3Band)               == -1   ||
      CopyBuffer(ASHandle,         1,  Shift,  1, ASP2Band)               == -1   ||
      CopyBuffer(ASHandle,         2,  Shift,  1, ASP1Band)               == -1   ||
      CopyBuffer(ASHandle,         3,  Shift,  1, ASM1Band)               == -1   ||
      CopyBuffer(ASHandle,         4,  Shift,  1, ASM2Band)               == -1   ||
      CopyBuffer(ASHandle,         5,  Shift,  1, ASM3Band)               == -1   ||
      CopyBuffer(ASHandle,         6,  Shift,  2, ASBuffer)               == -1   ||
      CopyBuffer(ASHandle,         7,  Shift,  1, ASColorBuffer)          == -1   ||

      CopyBuffer(SquareHandle,     0,  Shift,  1, SquareBuffer)           == -1   ||
      CopyBuffer(SquareHandle,     2,  Shift,  1, SquareP1Band)           == -1   ||
      CopyBuffer(SquareHandle,     3,  Shift,  1, SquareM1Band)           == -1   ||
      
      CopyBuffer(BSPHandle,        1,  Shift,  1, BSPBuffer)              == -1   ||
      
      CopyBuffer(HLHandle,         1,  Shift,  1, HLBuffer)               == -1   )

   {
      return(false);
   }



   SLTPBSPValue = BSPBuffer[0];
   ShortWmaValue = ShortWmaBuffer[0];
   LongWmaValue = LongWmaBuffer[0];
   LLongWmaValue = LLongWmaBuffer[0];
   LRStdValue0 = LRStdBuffer[0];
   HLValue = HLBuffer[0];   

   ShortNonLRTrend1 = ShortNonLRTrend;
   if( (int)NormalizeDouble(ShortNonLRColorBuffer[0], 0) == 1) ShortNonLRTrend = DownTrend;
   else ShortNonLRTrend = UpTrend;

   LongNonLRTrend1 = LongNonLRTrend;
   if( (int)NormalizeDouble(LongNonLRColorBuffer[0], 0) == 1) LongNonLRTrend = DownTrend;
   else LongNonLRTrend = UpTrend;


   if      (LRStdValue0 > LRStdP3Band[0])      LRStdBand = BandP3;
   else if (LRStdValue0 > LRStdP2Band[0])      LRStdBand = BandP2;
   else if (LRStdValue0 > LRStdP1Band[0])      LRStdBand = BandP1;
   else if (LRStdValue0 >= 0. )                LRStdBand = BandP0;
   else if (LRStdValue0 > LRStdM1Band[0])      LRStdBand = BandM0;
   else if (LRStdValue0 > LRStdM2Band[0])      LRStdBand = BandM1;
   else if (LRStdValue0 > LRStdM3Band[0])      LRStdBand = BandM2;
   else                                        LRStdBand = BandM3;

   if( (int)NormalizeDouble(LRStdColorBuffer[0], 0) == 1) LRStdTrend = DownTrend;
   else LRStdTrend = UpTrend;

     
   if      (ASBuffer[0] > ASP3Band[0])         ASBand = BandP3;
   else if (ASBuffer[0] > ASP2Band[0])         ASBand = BandP2;
   else if (ASBuffer[0] > ASP1Band[0])         ASBand = BandP1; 
   else if (ASBuffer[0] > 0. )                 ASBand = BandP0;
   else if (ASBuffer[0] > ASM1Band[0])         ASBand = BandM0;
   else if (ASBuffer[0] > ASM2Band[0])         ASBand = BandM1;
   else if (ASBuffer[0] > ASM3Band[0])         ASBand = BandM2;
   else                                        ASBand = BandM3; 
   
   if( (int)NormalizeDouble(ASColorBuffer[0], 0) == 1) ASTrend = DownTrend;
   else ASTrend = UpTrend;   
   
   if      (SquareBuffer[0] >= SquareP1Band[0])  SquareBand = BandP1;
   else if (SquareBuffer[0] >= 0.)               SquareBand = BandP0;
   else if (SquareBuffer[0] >= SquareM1Band[0])  SquareBand = BandM0; 
   else                                          SquareBand = BandM1; 

   if      (ShortWmaValue > WmaP3Band[0])       WmaBand = BandP3;
   else if (ShortWmaValue > WmaP2Band[0])       WmaBand = BandP2;
   else if (ShortWmaValue > WmaP1Band[0])       WmaBand = BandP1;
   else if (ShortWmaValue > AvgWmaBuffer[0])    WmaBand = BandP0;
   else if (ShortWmaValue > WmaM1Band[0])       WmaBand = BandM0;
   else if (ShortWmaValue > WmaM2Band[0])       WmaBand = BandM1;
   else if (ShortWmaValue > WmaM3Band[0])       WmaBand = BandM2;
   else                                         WmaBand = BandM3;
   
   ShortWmaTrend1 = ShortWmaTrend;
   if( (int)NormalizeDouble(ShortWmaColorBuffer[0], 0) == 1) ShortWmaTrend = DownTrend;
   else ShortWmaTrend = UpTrend;
   
   LongWmaTrend1 = LongWmaTrend;
   if( (int)NormalizeDouble(LongWmaColorBuffer[0], 0) == 1 ) LongWmaTrend = DownTrend;
   else LongWmaTrend = UpTrend;

   LLongWmaTrend1 = LLongWmaTrend;
   if( (int)NormalizeDouble(LLongWmaColorBuffer[0], 0) == 1 ) LLongWmaTrend = DownTrend;
   else LLongWmaTrend = UpTrend;

        


   if( (ASBuffer[1]>=0. && ASBuffer[0]<=0. ) || (ASBuffer[1]<=0. && ASBuffer[0]>=0.) )
     {
      if( Times(curTime) && !StartTrading )  StartTrading = true;       
      OpenReadyReset();
     }     

   if( !Times(curTime) && StartTrading )  StartTrading = false;  



   return(true);   
}


bool ReOpenCheck(ENUM_POSITION_TYPE BuyOrSell)
  {

   long currentBar = SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT);

   if((BuyOrSell  == POSITION_TYPE_BUY) && !SellCloseReady.ReOpenMode)
     {
      if( ( (currentBar - SellCloseReady.startingBar) <= NumBarReOpen ) &&   
          ( (LRStdBand==BandP0) || (LRStdBand==BandP1) || (LRStdBand==BandP2) || (LRStdBand==BandP3) ) )
        {
         CloseReadyReset();
         return(true);
        }  
      else
        {
         CloseReadyReset();
         return(false);
        }   
     }

   if( (BuyOrSell  == POSITION_TYPE_SELL) && !BuyCloseReady.ReOpenMode)
     {

      if( ( (currentBar - BuyCloseReady.startingBar) <= NumBarReOpen ) &&   
          ( (LRStdBand==BandM0) || (LRStdBand==BandM1) || (LRStdBand==BandM2) || (LRStdBand==BandM3) ) )
        {
         CloseReadyReset();
         return(true);
        }  
      else
        {
         CloseReadyReset();
         return(false);
        }
       

     }
   CloseReadyReset();
   return(false);
  }



//+--------------------------------------------------------------------+
bool SignalOpenBuy()
  {

   if( BuyOpenReady.ShortWmaReady && (TotalNumberOfPositions <= 0) )
     {
       return(true);         
     } 

   return(false);
   
  }

//+---------------------------------------------------------------------+
bool SignalOpenSell()
  {

   if( SellOpenReady.ShortWmaReady && (TotalNumberOfPositions <= 0))
     {
      return(true);
     }   

   return(false);
   
  }


//------------------------------------------------------------------------+
void MyBuyClose(void)
  {
   
   ClosePosition(POSITION_TYPE_BUY);
   PositionInfo();  
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;

  }

//-------------------------------------------------------------------------+
void MySellClose(void)
  {
   
   ClosePosition(POSITION_TYPE_SELL);
   PositionInfo();  
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;

  }


//---------------------------------------------------------------------------+
void ClosePosition(ENUM_POSITION_TYPE m_PositionType)
  {

   if(!Sym.RefreshRates())return;        

   int total=PositionsTotal();
   if(total<=0) return;
   
   for(int i=(total -1); i>=0; i--)
     {

      if(! Pos.SelectByIndex(i))
        {
         Alert("Position Selection Error");
         return;
        }

      string position_symbol=PositionGetSymbol(i);
      ENUM_POSITION_TYPE t_PositionType = Pos.PositionType();

      if(position_symbol==_Symbol && iMagicNumber==PositionGetInteger(POSITION_MAGIC) && (m_PositionType == t_PositionType) )
        {

               Trade.SetDeviationInPoints(Sym.Spread()*3);

               Trade.PositionClose(PositionGetInteger(POSITION_TICKET));      
            
         }      
      }     
      
}


//-------------------------------------------------------------------+
void OpenReadyReset(void)
  {
   BuyOpenReady.ASReady=false;
   BuyOpenReady.ShortWmaReady = false;
   SellOpenReady.ASReady = false;
   SellOpenReady.ShortWmaReady = false;
  }

//-------------------------------------------------------------------+
void CloseReadyReset(void)
  {

   if( BuyPositionInfo.numberOfPositions < 1 )
     {
      BuyCloseReady.ShortNonLReady =false;
      BuyCloseReady.ShortWmaReady = false;
      BuyCloseReady.LongNonLReady = false;
      BuyCloseReady.LongWmaReady = false;
      BuyCloseReady.ShortMode = false;
      BuyCloseReady.ReOpenMode = false;
      BuyCloseReady.LongWmaChanged = false;
      BuyCloseReady.startingBar = 0;
      BuyCloseReady.baseBSP = 0.;
      BuyCloseReady.ShortStartingBSP = 0.;
      BuyCloseReady.LongStartingBSP = 0.;
      BuyCloseReady.ShortStopLossBSP = 0.;
      BuyCloseReady.LongStopLossBSP = 0.;
      BuyCloseReady.ShortTakeProfitBSP = 0.;  
      BuyCloseReady.LongTakeProfitBSP = 0.;  
       
     }

   if( SellPositionInfo.numberOfPositions < 1)
     {
      SellCloseReady.ShortNonLReady=false;
      SellCloseReady.ShortWmaReady = false;
      SellCloseReady.LongNonLReady = false;
      SellCloseReady.LongWmaReady = false;
      SellCloseReady.ShortMode = false;
      SellCloseReady.ReOpenMode = false;
      SellCloseReady.LongWmaChanged = false;
      SellCloseReady.startingBar = 0;
      SellCloseReady.baseBSP = 0.;
      SellCloseReady.ShortStartingBSP = 0.;
      SellCloseReady.LongStartingBSP = 0.;      
      SellCloseReady.ShortStopLossBSP = 0.;
      SellCloseReady.LongStopLossBSP = 0.;      
      SellCloseReady.ShortTakeProfitBSP = 0.;  
      SellCloseReady.LongTakeProfitBSP = 0.;  
        
     }

  }

//-------------------------------------------------------------------+
void Virtual_SLTP(){

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


void OpenPosition(ENUM_POSITION_TYPE m_PositionType, string m_Comment)
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
        if(! Trade.Buy(lot,_Symbol,0,slv,tpv,m_Comment))  return; 
               
      }else  Print("Cannot open a Buy position, nearing the Stop Loss or Take Profit");
   }


   if(m_PositionType == POSITION_TYPE_SELL){
      
      if(!VirtualSLTP){
         slv=SolveSellSL(StopLoss);
         tpv=SolveSellTP(TakeProfit);
      }
   
      if(CheckSellSL(slv) && CheckSellTP(tpv)){
         Trade.SetDeviationInPoints(Sym.Spread()*3);
         if(! Trade.Sell(lot,_Symbol,0,slv,tpv,m_Comment)) return;         
      }else Print("Cannot open a Sell position, nearing the Stop Loss or Take Profit");
   }  
     
}                           
   

 //+------------------------------------------------------------------------+
//|  Function for calculat the number of buy or sell orders by this EA     |
//+------------------------------------------------------------------------+

void PositionInfo()
{
   BuyPositionInfo.numberOfPositions    = 0;
   BuyPositionInfo.sizeOfPositions      = 0.;
   BuyPositionInfo.startingPrice        = 0.;
   BuyPositionInfo.lastPrice            = 0.;
   SellPositionInfo.numberOfPositions   = 0;
   SellPositionInfo.sizeOfPositions     = 0.;
   SellPositionInfo.startingPrice       = 0.;
   SellPositionInfo.lastPrice           = 0.;

   for(int i=PositionsTotal()-1; i>=0; i--){
 
      if(Pos.SelectByIndex(i)){
      
         if( (PositionGetSymbol(i) == _Symbol) && (PositionGetInteger(POSITION_MAGIC) == iMagicNumber))
         {
            ENUM_POSITION_TYPE t_PositionType = Pos.PositionType();
                     
            if(t_PositionType==POSITION_TYPE_BUY)
            {
               BuyPositionInfo.numberOfPositions += 1;
               BuyPositionInfo.sizeOfPositions += PositionGetDouble(POSITION_VOLUME);
               if(BuyPositionInfo.startingPrice == 0. || BuyPositionInfo.lastPrice == 0.)
               { 
                  BuyPositionInfo.startingPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                  BuyPositionInfo.lastPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               }   
               if(PositionGetDouble(POSITION_PRICE_OPEN)<BuyPositionInfo.startingPrice)
                  BuyPositionInfo.startingPrice = PositionGetDouble(POSITION_PRICE_OPEN);  
               if(PositionGetDouble(POSITION_PRICE_OPEN)>BuyPositionInfo.lastPrice) 
                  BuyPositionInfo.lastPrice =  PositionGetDouble(POSITION_PRICE_OPEN);        
            }
         
            if(t_PositionType==POSITION_TYPE_SELL)
            {
               SellPositionInfo.numberOfPositions += 1;
               SellPositionInfo.sizeOfPositions += PositionGetDouble(POSITION_VOLUME);
               if(SellPositionInfo.startingPrice == 0. || SellPositionInfo.lastPrice == 0.)
               { 
                  SellPositionInfo.startingPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                  SellPositionInfo.lastPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               }   
               if(PositionGetDouble(POSITION_PRICE_OPEN)>SellPositionInfo.startingPrice)
                  SellPositionInfo.startingPrice = PositionGetDouble(POSITION_PRICE_OPEN);  
               if(PositionGetDouble(POSITION_PRICE_OPEN)<SellPositionInfo.lastPrice) 
                  SellPositionInfo.lastPrice =  PositionGetDouble(POSITION_PRICE_OPEN);        
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
 
