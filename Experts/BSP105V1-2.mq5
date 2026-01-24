//+------------------------------------------------------------------+
//|                                                   BSP105V1-2.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


#define IND1 "NonLR"
#define IND2 "BSP105LRSTDV3AVG"
#define IND3 "BSP105WMA"
#define IND4 "BSP105LRAVGSTD"
#define IND5 "BSP105LRSQUARE"
#define IND6 "BSP105BSP"


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
//NonLR
input int                 NonLRPeriodS         = 25;          // NonLRPeriod
input int                 NonLRPeriodL         = 50;          // NonLRPeriod
//LRAvg
input int                 StdAvgLwmaPeriod     = 50;          // StdAvgWmaPeriod1
input int                 StdAvgLRPeriod       = 5;           // StdAvgLRPeriod
input int                 StdAvgStdPeriodL     = 28800;        // StdAvgStdPeriodL
input int                 StdAvgPeriod         = 1;           //StdAvg1AvgPeriod
input double              StdAvgMultiFactorL1  = 0.5;         // StdAvgStdMultiFactorL1
input double              StdAvgMultiFactorL2  = 1.0;         // StdAvgStdMultiFactorL2
input double              StdAvgMultiFactorL3  = 2.5;         // StdAvgStdMultiFactorL3
//LRAvg
input int                 JStdAvgPeriod        = 15;           //StdAvg1AvgPeriod
//Wma
input int                 WmaPeriodS           = 12;          // wmaPeriodS
input int                 WmaPeriodL           = 50;          // wmaPeriodS
input int                 WmaPeriod2           = 200;          // WmaPeriod2
//ASAvg
input int                 ASLwmaPeriod         = 12;          // WmaPeriod1
input int                 ASAvgPeriod          = 7;          //AvgPeriod
input int                 ASStdPeriodL         = 10000;        // StdPeriodL
input int                 ASStdPeriodS         = 10;        // StdPeriodS
input double              ASMultiFactorL1      = 0.5;         // StdMultiFactorL1
input double              ASMultiFactorL2      = 1.0;         // StdMultiFactorL2
input double              ASMultiFactorL3      = 2.0;         // StdMultiFactorL3
//BSPLRSQUARE
input int                 SqLwmaPeriod         = 50;          // WmaPeriod1
input int                 SqLRPeriod           = 10;           // LRPeriod
input int                 SqLRSPeriod          = 20;           // LRSPeriod
input int                 SqStdPeriodL         = 28800;        // Long StdPeriod
input int                 SqStdPeriodS         = 10;          // Short StdPeriod
input double              SqMultiFactorL       = 2.0;         // Long MultiFactor
input double              SqMultiFactorS       = 0.1;         // Short MultiFactor
//BSP
input int                 BSPWmaPeriod         = 30;           // WmaPeriod
input double              BSPMultiRatio        = 1.0;          // MultiRatio




sinput   const string  Message2="";//Trading Time parameter
input    int              StartTime            = 2;            // Starting Time (Server Time)
input    int              EndTime              = 23;           // Ending(Last Open Position) Time (Server Time)

sinput   const string  Message3="";//EA Parameter
input    int              iMagicNumber         = 10000;       // Magic Number
input double              Lots                 = 0.01;        /*Lots*/             // Lot; if 0, MaximumRisk value is used
input double              MaximumRisk          = 1;           /*MaximumRisk*/      // Risk(if Lots=0) 0.01lot/1000$
input int                 StopLoss             = 0;           /*StopLoss*/            // Stop Loss in points
input int                 TakeProfit           = 0;           /*TakeProfit*/       // Take Profit in points
input bool                VirtualSLTP          = false;       /*VirtualSLTP*/     // Stop Loss, Take Profit setting.
input double              SLBSPMultiFactor     = 0.3;                              //SL BSP Multifactor
input double              TPBSPMultiFactor     = 0.5;                              //TP BSP Multifactor
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
BandState ShortLRStdBand, LongLRStdBand, ASBand, SquareBand;

enum trend
  {
   UpTrend,
   DownTrend, 
   NoTrend,       
  };
trend LongWmaTrend, ShortWmaTrend, LongNonLRTrend, ShortNonLRTrend, ShortLRStdTrend, LongLRStdTrend;

struct position_Info
{
   int    numberOfPositions;
   double sizeOfPositions;
   double startingPrice;
   double lastPrice;
   double stopLossPrice;
};
position_Info BuyPositionInfo, SellPositionInfo;


struct open_Ready
{
   bool   ShortLRStdReady;
   bool   ShortWmaReady;
};
open_Ready BuyOpenReady, SellOpenReady;

struct close_Ready
{
   bool    ShortNonLReady;
   bool    ShortWmaReady;
   bool    LongNonLReady;
   bool    LongWmaReady;   
   bool    ReOpenMode;
   long    startingBar;
   double  startingBSP;
   double  baseBSP;
   double  stopLossBSP;
   double  takeProfitBSP;
};
close_Ready BuyCloseReady, SellCloseReady;


int NonLRHandleS     = INVALID_HANDLE,
    NonLRHandleL     = INVALID_HANDLE,
    LRStdAvgHandleS  = INVALID_HANDLE,
    LRStdAvgHandleL  = INVALID_HANDLE,
    WmaHandleS       = INVALID_HANDLE,
    WmaHandleL       = INVALID_HANDLE,
    ASHandle         = INVALID_HANDLE,
    BSPHandle        = INVALID_HANDLE, 
    SquareHandle     = INVALID_HANDLE;

double ShortNonLRBuffer[], ShortNonLRColorBuffer[],
       LongNonLRBuffer[], LongNonLRColorBuffer[],

       ShortLRStdP1Band[], ShortLRStdP2Band[], ShortLRStdP3Band[], ShortLRStdM1Band[], ShortLRStdM2Band[], 
       ShortLRStdM3Band[], ShortLRStdBuffer[], ShortLRStdColorBuffer[],

       LongLRStdP1Band[], LongLRStdP2Band[], LongLRStdP3Band[], LongLRStdM1Band[], LongLRStdM2Band[], 
       LongLRStdM3Band[], LongLRStdBuffer[], LongLRStdColorBuffer[],
       
       LongWmaBuffer[], LongWmaColorBuffer[], 
       ShortWmaBuffer[], ShortWmaColorBuffer[], 

       ASBuffer[], ASP1Band[], ASP2Band[], ASP3Band[], 
       SquareBuffer[], SquareP1Band[], SquareM1Band[], 
       
       BSPBuffer[];
       

double SLTPBSPValue, ShortWmaValue, LongWmaValue;

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
   LRStdAvgHandleS   = iCustom(_Symbol,PERIOD_M1,IND2, StdAvgLwmaPeriod, StdAvgLRPeriod, StdAvgStdPeriodL, StdAvgPeriod, 
                                                       StdAvgMultiFactorL1, StdAvgMultiFactorL2, StdAvgMultiFactorL3);
   LRStdAvgHandleL   = iCustom(_Symbol,PERIOD_M1,IND2, StdAvgLwmaPeriod, StdAvgLRPeriod, StdAvgStdPeriodL, JStdAvgPeriod,
                                                       StdAvgMultiFactorL1, StdAvgMultiFactorL2, StdAvgMultiFactorL3);
   WmaHandleS        = iCustom(_Symbol,PERIOD_M1,IND3, WmaPeriodS, WmaPeriod2);
   WmaHandleL        = iCustom(_Symbol,PERIOD_M1,IND3, WmaPeriodL, WmaPeriod2);
   ASHandle          = iCustom(_Symbol,PERIOD_M1,IND4, ASLwmaPeriod, ASAvgPeriod, ASStdPeriodL, ASStdPeriodS, 
                                                       ASMultiFactorL1, ASMultiFactorL2, ASMultiFactorL3);
   SquareHandle      = iCustom(_Symbol,PERIOD_M1,IND5, SqLwmaPeriod, SqLRPeriod, SqLRSPeriod, SqStdPeriodL, SqStdPeriodS, 
                                                       SqMultiFactorL, SqMultiFactorS);
   BSPHandle         = iCustom(_Symbol,PERIOD_M1,IND6, BSPWmaPeriod, BSPMultiRatio );    


   if(NonLRHandleS    == INVALID_HANDLE  || NonLRHandleL    == INVALID_HANDLE || 
      LRStdAvgHandleS == INVALID_HANDLE  || LRStdAvgHandleL == INVALID_HANDLE || 
      WmaHandleS      == INVALID_HANDLE  || WmaHandleL      == INVALID_HANDLE ||
      BSPHandle       == INVALID_HANDLE  || SquareHandle    == INVALID_HANDLE ||
      ASHandle        == INVALID_HANDLE)
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

   ArraySetAsSeries(ShortLRStdP1Band, true);
   ArraySetAsSeries(ShortLRStdP2Band, true);
   ArraySetAsSeries(ShortLRStdP3Band, true);
   ArraySetAsSeries(ShortLRStdM1Band, true);
   ArraySetAsSeries(ShortLRStdM2Band, true);
   ArraySetAsSeries(ShortLRStdM3Band, true);
   ArraySetAsSeries(ShortLRStdBuffer, true);
   ArraySetAsSeries(ShortLRStdColorBuffer, true);

   ArraySetAsSeries(LongLRStdP1Band, true);
   ArraySetAsSeries(LongLRStdP2Band, true);
   ArraySetAsSeries(LongLRStdP3Band, true);
   ArraySetAsSeries(LongLRStdM1Band, true);
   ArraySetAsSeries(LongLRStdM2Band, true);
   ArraySetAsSeries(LongLRStdM3Band, true);
   ArraySetAsSeries(LongLRStdBuffer, true);
   ArraySetAsSeries(LongLRStdColorBuffer, true);

   ArraySetAsSeries(LongWmaBuffer, true);
   ArraySetAsSeries(LongWmaColorBuffer, true);
   ArraySetAsSeries(ShortWmaBuffer, true);
   ArraySetAsSeries(ShortWmaColorBuffer, true);

   ArraySetAsSeries(ASBuffer, true);
   ArraySetAsSeries(ASP1Band, true);
   ArraySetAsSeries(ASP2Band, true);
   ArraySetAsSeries(ASP3Band, true);

   ArraySetAsSeries(SquareBuffer, true);
   ArraySetAsSeries(SquareP1Band, true);
   ArraySetAsSeries(SquareM1Band, true);

   ArraySetAsSeries(BSPBuffer, true);

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
   if(LRStdAvgHandleS !=  INVALID_HANDLE)  IndicatorRelease(LRStdAvgHandleS);   
   if(LRStdAvgHandleL !=  INVALID_HANDLE)  IndicatorRelease(LRStdAvgHandleL);
   if(WmaHandleS      !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleS);
   if(WmaHandleL      !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleL);   
   if(BSPHandle       !=  INVALID_HANDLE)  IndicatorRelease(BSPHandle);   
   if(SquareHandle    !=  INVALID_HANDLE)  IndicatorRelease(SquareHandle);
   if(ASHandle        !=  INVALID_HANDLE)  IndicatorRelease(ASHandle);  

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

/*      if( TotalNumberOfPositions >= 1)
        {
                     
         CloseReadyCheck();

         CloseBuy = SignalCloseBuy();
         if(CloseBuy)
           {
            MyBuyClose();
            if(StartTrading && ReOpenCheck(POSITION_TYPE_SELL) ) 
              {
               MySellOpen(true);
              }
           }    
            
         CloseSell = SignalCloseSell();
         if(CloseSell)
           {
            MySellClose();
            if(StartTrading && ReOpenCheck(POSITION_TYPE_BUY) ) 
              {
               MyBuyOpen(true);
              } 

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
*/     }   

//   Virtual_SLTP();

}

//+------------------------------------------------------------------+
//|   Function for copying indicator data and price                   |
//+------------------------------------------------------------------+
bool Indicators(){

   double ShortLRStdValue0, ShortLRStdValue1, LongLRStdValue0;
   datetime curTime = TimeCurrent();

   if(CopyBuffer(NonLRHandleS,  0,  Shift,  1, ShortNonLRBuffer)          == -1   ||
      CopyBuffer(NonLRHandleS,  1,  Shift,  1, ShortNonLRColorBuffer)     == -1   ||

      CopyBuffer(NonLRHandleL,  0,  Shift,  1, LongNonLRBuffer)           == -1   ||
      CopyBuffer(NonLRHandleL,  1,  Shift,  1, LongNonLRColorBuffer)      == -1   ||

      CopyBuffer(LRStdAvgHandleS,  0,  Shift,  1, ShortLRStdP1Band)       == -1   ||
      CopyBuffer(LRStdAvgHandleS,  1,  Shift,  1, ShortLRStdM1Band)       == -1   ||
      CopyBuffer(LRStdAvgHandleS,  2,  Shift,  1, ShortLRStdP2Band)       == -1   ||
      CopyBuffer(LRStdAvgHandleS,  3,  Shift,  1, ShortLRStdM2Band)       == -1   ||
      CopyBuffer(LRStdAvgHandleS,  4,  Shift,  1, ShortLRStdP3Band)       == -1   ||
      CopyBuffer(LRStdAvgHandleS,  5,  Shift,  1, ShortLRStdM3Band)       == -1   ||
      CopyBuffer(LRStdAvgHandleS,  6,  Shift,  2, ShortLRStdBuffer)       == -1   ||
      CopyBuffer(LRStdAvgHandleS,  7,  Shift,  1, ShortLRStdColorBuffer)  == -1   ||

      CopyBuffer(LRStdAvgHandleL,  0,  Shift,  1, LongLRStdP1Band)        == -1   ||
      CopyBuffer(LRStdAvgHandleL,  1,  Shift,  1, LongLRStdM1Band)        == -1   ||
      CopyBuffer(LRStdAvgHandleL,  2,  Shift,  1, LongLRStdP2Band)        == -1   ||
      CopyBuffer(LRStdAvgHandleL,  3,  Shift,  1, LongLRStdM2Band)        == -1   ||
      CopyBuffer(LRStdAvgHandleL,  4,  Shift,  1, LongLRStdP3Band)        == -1   ||
      CopyBuffer(LRStdAvgHandleL,  5,  Shift,  1, LongLRStdM3Band)        == -1   ||
      CopyBuffer(LRStdAvgHandleL,  6,  Shift,  1, LongLRStdBuffer)        == -1   ||
      CopyBuffer(LRStdAvgHandleL,  7,  Shift,  1, LongLRStdColorBuffer)   == -1   ||

      CopyBuffer(WmaHandleS,       1,  Shift,  1, ShortWmaBuffer)         == -1   ||
      CopyBuffer(WmaHandleS,       2,  Shift,  1, ShortWmaColorBuffer)    == -1   ||

      CopyBuffer(WmaHandleL,       1,  Shift,  1, LongWmaBuffer)          == -1   ||
      CopyBuffer(WmaHandleL,       2,  Shift,  1, LongWmaColorBuffer)     == -1   ||

      CopyBuffer(ASHandle,        0,  Shift,  1, ASP1Band)                == -1   ||
      CopyBuffer(ASHandle,        1,  Shift,  1, ASP2Band)                == -1   ||
      CopyBuffer(ASHandle,        2,  Shift,  1, ASP3Band)                == -1   ||
      CopyBuffer(ASHandle,        3,  Shift,  1, ASBuffer)                == -1   ||

      CopyBuffer(SquareHandle,  0,  Shift,  1, SquareBuffer)              == -1   ||
      CopyBuffer(SquareHandle,  2,  Shift,  1, SquareP1Band)              == -1   ||
      CopyBuffer(SquareHandle,  3,  Shift,  1, SquareM1Band)              == -1   ||
      
      CopyBuffer(BSPHandle,     1,  Shift,  1, BSPBuffer)                 == -1   )

   {
      return(false);
   }



   SLTPBSPValue = BSPBuffer[0];
   ShortWmaValue = ShortWmaBuffer[0];
   LongWmaValue = LongWmaBuffer[0];
   ShortLRStdValue0 = ShortLRStdBuffer[0];
   ShortLRStdValue1 = ShortLRStdBuffer[1]; 
   LongLRStdValue0 = LongLRStdBuffer[0];


   if( ((ShortLRStdValue1 >= 0.) && (ShortLRStdValue0 <= 0.) ) || ((ShortLRStdValue1 <= 0.) && (ShortLRStdValue0 >= 0.) ) )
     {
      if( Times(curTime) && !StartTrading )  StartTrading = true; 
      
      OpenReadyReset();
     }     

   if( !Times(curTime) && StartTrading )  StartTrading = false;  

   if( (int)NormalizeDouble(ShortNonLRColorBuffer[0], 0) == 1) ShortNonLRTrend = DownTrend;
   else ShortNonLRTrend = UpTrend;

   if( (int)NormalizeDouble(LongNonLRColorBuffer[0], 0) == 1) LongNonLRTrend = DownTrend;
   else LongNonLRTrend = UpTrend;


   if      ( (ShortLRStdValue0 < ShortLRStdP1Band[0]) && (ShortLRStdValue0 >= 0.) ) ShortLRStdBand = BandP0;
   else if ( (ShortLRStdValue0 > ShortLRStdM1Band[0]) && (ShortLRStdValue0 < 0.) )  ShortLRStdBand = BandM0;
   else if (ShortLRStdValue0 >= ShortLRStdP3Band[0])                                ShortLRStdBand = BandP3;
   else if (ShortLRStdValue0 >= ShortLRStdP2Band[0])                                ShortLRStdBand = BandP2;
   else if (ShortLRStdValue0 >= ShortLRStdP1Band[0])                                ShortLRStdBand = BandP1;
   else if (ShortLRStdValue0 <= ShortLRStdM3Band[0])                                ShortLRStdBand = BandM3;
   else if (ShortLRStdValue0 <= ShortLRStdM2Band[0])                                ShortLRStdBand = BandM2;
   else if (ShortLRStdValue0 <= ShortLRStdM1Band[0])                                ShortLRStdBand = BandM1;
   else
     {
      Alert("ShortLRStdBand error");
      return(false);   
     }

   if( (int)NormalizeDouble(ShortLRStdColorBuffer[0], 0) == 1) ShortLRStdTrend = DownTrend;
   else ShortLRStdTrend = UpTrend;

   if      ( (LongLRStdValue0 < LongLRStdP1Band[0]) && (LongLRStdValue0 >= 0.) )  LongLRStdBand = BandP0;
   else if ( (LongLRStdValue0 > LongLRStdM1Band[0]) && (LongLRStdValue0 < 0.) )   LongLRStdBand = BandM0;
   else if (LongLRStdValue0 >= LongLRStdP3Band[0])                                LongLRStdBand = BandP3;
   else if (LongLRStdValue0 >= LongLRStdP2Band[0])                                LongLRStdBand = BandP2;
   else if (LongLRStdValue0 >= LongLRStdP1Band[0])                                LongLRStdBand = BandP1;
   else if (LongLRStdValue0 <= LongLRStdM3Band[0])                                LongLRStdBand = BandM3;
   else if (LongLRStdValue0 <= LongLRStdM2Band[0])                                LongLRStdBand = BandM2;
   else if (LongLRStdValue0 <= LongLRStdM1Band[0])                                LongLRStdBand = BandM1;
   else
     {
      Alert("LongLRStdBand error");
      return(false);   
     }

   if( (int)NormalizeDouble(LongLRStdColorBuffer[0], 0) == 1) LongLRStdTrend = DownTrend;
   else LongLRStdTrend = UpTrend;

     
   if      (ASBuffer[0] >= ASP3Band[0])  ASBand = BandP3;
   else if (ASBuffer[0] >= ASP2Band[0])  ASBand = BandP2;
   else if (ASBuffer[0] >= ASP1Band[0])  ASBand = BandP1; 
   else                                  ASBand = BandP0; 

   if      (SquareBuffer[0] >= SquareP1Band[0])  SquareBand = BandP1;
   else if (SquareBuffer[0] >= 0.)               SquareBand = BandP0;
   else if (SquareBuffer[0] >= SquareM1Band[0])  SquareBand = BandM0; 
   else                                          SquareBand = BandM1; 


   
   if( (int)NormalizeDouble(ShortWmaColorBuffer[0], 0) == 1) ShortWmaTrend = DownTrend;
   else ShortWmaTrend = UpTrend;
   
   if( (int)NormalizeDouble(LongWmaColorBuffer[0], 0) == 1 ) LongWmaTrend = DownTrend;
   else LongWmaTrend = UpTrend;
        
   return(true);   
}

//------------------------------------------------------------------+
void CloseReadyCheck(void)
  {

   if( BuyPositionInfo.numberOfPositions >= 1 )
     {
      if(ShortNonLRTrend == DownTrend) BuyCloseReady.ShortNonLReady = true;
      else BuyCloseReady.ShortNonLReady = false;
      
      if(ShortWmaTrend == DownTrend) BuyCloseReady.ShortWmaReady = true;
      else BuyCloseReady.ShortWmaReady = false;      
      
      if(LongNonLRTrend == DownTrend) BuyCloseReady.LongNonLReady = true;
      else BuyCloseReady.LongNonLReady = false;
      
      if(LongWmaTrend == DownTrend) BuyCloseReady.LongWmaReady = true;
      else BuyCloseReady.LongWmaReady = false;      
      
     }
     
   if( SellPositionInfo.numberOfPositions >= 1)   
     {
      if(ShortNonLRTrend == UpTrend)  SellCloseReady.ShortNonLReady = true;
      else SellCloseReady.ShortNonLReady = false;

      if(ShortWmaTrend == UpTrend)  SellCloseReady.ShortWmaReady = true;
      else SellCloseReady.ShortWmaReady = false;
      
      if(LongNonLRTrend == UpTrend)  SellCloseReady.LongNonLReady = true;
      else SellCloseReady.LongNonLReady = false;

      if(LongWmaTrend == UpTrend)  SellCloseReady.LongWmaReady = true;
      else SellCloseReady.LongWmaReady = false;
      
     }
     
  }



//-------------------------------------------------------------------+
void OpenReadyCheck(void)
  {

   if(BuyPositionInfo.numberOfPositions < 1)
     {
       if( (ShortLRStdBand == BandM2) || (ShortLRStdBand == BandM3)) BuyOpenReady.ShortLRStdReady = true;

       if( BuyOpenReady.ShortLRStdReady && (ShortWmaTrend == UpTrend) ) BuyOpenReady.ShortWmaReady = true;   
       else  BuyOpenReady.ShortWmaReady = false;
     }

   if(SellPositionInfo.numberOfPositions < 1)
     {
      if( (ShortLRStdBand == BandP2) || (ShortLRStdBand == BandP3)) SellOpenReady.ShortLRStdReady = true;

      if( SellOpenReady.ShortLRStdReady && (ShortWmaTrend == DownTrend) ) SellOpenReady.ShortWmaReady = true;   
      else SellOpenReady.ShortWmaReady = false;   
     }

  }


bool ReOpenCheck(ENUM_POSITION_TYPE BuyOrSell)
  {

   long currentBar = SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT);

   if((BuyOrSell  == POSITION_TYPE_BUY) && !SellCloseReady.ReOpenMode)
     {
      if( ( (currentBar - SellCloseReady.startingBar) <= NumBarReOpen ) &&   
          ( (ShortLRStdBand==BandP0) || (ShortLRStdBand==BandP1) || (ShortLRStdBand==BandP2) || (ShortLRStdBand==BandP3) ) )
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
          ( (ShortLRStdBand==BandM0) || (ShortLRStdBand==BandM1) || (ShortLRStdBand==BandM2) || (ShortLRStdBand==BandM3) ) )
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

//+----------------------------------------------------------------------+
bool SignalCloseBuy()
  {

   if( BuyPositionInfo.numberOfPositions >= 1 )
     {
      
      if(!BuyCloseReady.ReOpenMode)
        {
         if(ShortWmaValue < BuyCloseReady.stopLossBSP)
           {
            return(true);
           }
         if( (ShortWmaValue > BuyCloseReady.takeProfitBSP) && BuyCloseReady.ShortWmaReady )
           { 
            return(true);
           }
        }
      else
        {
        
         if(LongWmaValue < BuyCloseReady.stopLossBSP)
           {
            OpenReadyReset();
            return(true);
           }
         if( (LongWmaValue > BuyCloseReady.takeProfitBSP) && BuyCloseReady.LongWmaReady )
           { 
            OpenReadyReset();
            return(true);
           }       
        }  

     }
     
   return(false);
   
  }

//+----------------------------------------------------------------------+
bool SignalCloseSell()
  {

   if( SellPositionInfo.numberOfPositions >= 1)   
     {

      if( !SellCloseReady.ReOpenMode )
        {
         if(ShortWmaValue > SellCloseReady.stopLossBSP)
           {
            return(true);
           }
         if( (ShortWmaValue < SellCloseReady.takeProfitBSP) && SellCloseReady.ShortWmaReady )
           {
            return(true);
           } 
        }
      else
        {
         if(LongWmaValue > SellCloseReady.stopLossBSP)
           {
            OpenReadyReset();
            return(true);
           }
         if( (LongWmaValue < SellCloseReady.takeProfitBSP) && SellCloseReady.LongWmaReady )
           {
            OpenReadyReset();
            return(true);
           }         
        }  
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

//-------------------------------------------------------------------------+
void MyBuyOpen(bool IsReOpen)
  {
      
   if(IsReOpen) 
     {
      OpenPosition(POSITION_TYPE_BUY, "ReOpenBuy");
      BuyCloseReady.startingBSP = LongWmaValue;
      BuyCloseReady.ReOpenMode = true;
     }
   else
    {
      OpenPosition(POSITION_TYPE_BUY, "NormalBuy");
      BuyCloseReady.startingBSP = ShortWmaValue;
      BuyCloseReady.ReOpenMode = false;
    }
    
   BuyCloseReady.startingBar = SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT);
   BuyCloseReady.baseBSP = SLTPBSPValue;
   BuyCloseReady.stopLossBSP = BuyCloseReady.startingBSP - SLTPBSPValue*SLBSPMultiFactor;
   BuyCloseReady.takeProfitBSP = BuyCloseReady.startingBSP + SLTPBSPValue*TPBSPMultiFactor;
    
   PositionInfo(); 
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;    
   OpenReadyReset();

  }

//--------------------------------------------------------------------------+
void MySellOpen(bool IsReOpen)
  {
   
   if(IsReOpen) 
     {
      OpenPosition(POSITION_TYPE_SELL, "ReOpenSell");
      SellCloseReady.startingBSP = LongWmaValue;
      SellCloseReady.ReOpenMode = true;
     }
   else
    {
      OpenPosition(POSITION_TYPE_SELL, "NormalSell");
      SellCloseReady.startingBSP = ShortWmaValue;
      SellCloseReady.ReOpenMode = false;
    }
   
   SellCloseReady.startingBar = SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT);
   SellCloseReady.baseBSP = SLTPBSPValue;
   SellCloseReady.stopLossBSP = SellCloseReady.startingBSP + SLTPBSPValue*SLBSPMultiFactor;
   SellCloseReady.takeProfitBSP = SellCloseReady.startingBSP - SLTPBSPValue*TPBSPMultiFactor;
   
   PositionInfo();
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;   
   OpenReadyReset();

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
   BuyOpenReady.ShortLRStdReady=false;
   BuyOpenReady.ShortWmaReady = false;
   SellOpenReady.ShortLRStdReady = false;
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
      BuyCloseReady.ReOpenMode = false;
      BuyCloseReady.startingBar = 0;
      BuyCloseReady.startingBSP = 0.;
      BuyCloseReady.baseBSP = 0.;
      BuyCloseReady.stopLossBSP = 0.;
      BuyCloseReady.takeProfitBSP = 0.;     
     }

   if( SellPositionInfo.numberOfPositions < 1)
     {
      SellCloseReady.ShortNonLReady=false;
      SellCloseReady.ShortWmaReady = false;
      SellCloseReady.LongNonLReady = false;
      SellCloseReady.LongWmaReady = false;
      SellCloseReady.ReOpenMode = false;
      SellCloseReady.startingBar = 0;
      SellCloseReady.startingBSP = 0.;
      SellCloseReady.baseBSP = 0.;
      SellCloseReady.stopLossBSP = 0.;
      SellCloseReady.takeProfitBSP = 0.;    
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
 
