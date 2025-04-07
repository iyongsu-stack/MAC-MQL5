//+------------------------------------------------------------------+
//|                                                      BSPV1-1.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"


#define IND1 "BSP105LRSQUARE"
#define IND2 "BSP105LR2STD"
#define IND3 "BSP105WMA"
#define IND4 "BSP105BSP"
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
//LRSQUARE
input int                 SquareLwmaPeriod    = 50;          // SquareWmaPeriod1
input int                 SquareLRPeriod     = 25;           // SquareLRPeriod
input int                 SquareLRSPeriod    = 5;           // SquareLRSPeriod
input int                 SquareStdPeriodL    = 28800;        // SquareLong StdPeriod
input int                 SquareStdPeriodS    = 30;          // SquareShort StdPeriod
input double              SquareMultiFactorL  = 1.3;         // SquareLong MultiFactor
input double              SquareMultiFactorS  = 0.01;         // SquareShort MultiFactor
//StopLRSQUARE
input int                 SSquareLwmaPeriod    = 50;          // SSquareWmaPeriod1
input int                 SSquareLRPeriod     = 35;           // SSquareLRPeriod
input int                 SSquareLRSPeriod    = 5;           // SSquareLRSPeriod
input int                 SSquareStdPeriodL    = 28800;        // SSquareLong StdPeriod
input int                 SSquareStdPeriodS    = 30;          // SSquareShort StdPeriod
input double              SSquareMultiFactorL  = 1.3;         // SSquareLong MultiFactor
input double              SSquareMultiFactorS  = 0.01;         // SSquareShort MultiFactor
//LR2STD
input int                 LR2StdLwmaPeriod    = 30;          // LR2StdWmaPeriod1
input int                 LR2StdLRPeriod     = 5;           // LR2StdLRPeriod
input int                 LR2StdStdPeriodL    = 2880;        // LR2StdStdPeriodL
input int                 LR2StdStdPeriodS    = 30;        // LR2StdStdPeriodS
input double              LR2StdMultiFactorL1  = 1.5;         // LR2StdStdMultiFactorL1
input double              LR2StdMultiFactorL2  = 1.6;         // LR2StdStdMultiFactorL2
input double              LR2StdMultiFactorL3  = 2.0;         // LR2StdStdMultiFactorL3
input double              LR2StdMultiFactorS1  = 0.1;        // LR2StdStdMultiFactorS1
input double              LR2StdMultiFactorS2  = 0.1;         // LR2StdStdMultiFactorS2
input double              LR2StdMultiFactorS3  = 0.1;         // LR2StdStdMultiFactorS3
//LongWMA
input int                 LongWmaWmaPeriod    = 30;          // LongWmaPeriod
input int                 LongWmaWmaPeriod2   = 200;          // LongWmaPeriod2
//ShortWMA
input int                 ShortWmaWmaPeriod    = 6;          // ShortWmaPeriod
input int                 ShortWmaWmaPeriod2   = 200;          // ShortWmaPeriod2
//BSP
input int                 BspWmaPeriod     = 30;           // BSPWmaPeriod
input double              BspMultiRatio    = 1.0;          // BSPMultiRatio
//NonLR
input int                 NonLRinpPeriod = 30;          // NonLRPeriod

sinput   const string  Message2="";//Trading Time parameter
input    int               StartTime           = 2;            // Starting Time (Server Time)
input    int               EndTime             = 23;           // Ending(Last Open Position) Time (Server Time)

sinput   const string  Message3="";//EA Parameter
input    int               iMagicNumber        =  10000;       // Magic Number
input double               Lots                =  0.01;        /*Lots*/             // Lot; if 0, MaximumRisk value is used
input double               MaximumRisk         =  1;           /*MaximumRisk*/      // Risk(if Lots=0) 0.01lot/1000$
input int                  StopLoss            =  0;           /*StopLoss*/            // Stop Loss in points
input int                  TakeProfit          =  0;           /*TakeProfit*/       // Take Profit in points
input bool                 VirtualSLTP         =  false;       /*VirtualSLTP*/     // Stop Loss, Take Profit setting.
input double               SLBSPMultiFactor    = 1.0;                              //SL BSP Multifactor
input double               TPBSPMultiFactor    = 2.0;                              //TP BSP Multifactor

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
BandState LRBand, LRSquareBand, SLRSquareBand;

enum trend
  {
   UpTrend,
   DownTrend, 
   NoTrend,       
  };
trend LongWmaTrend, ShortWmaTrend, NonLRTrend, SLRSquareTrend ;

struct position_Info
{
   int    numberOfPositions;
   double sizeOfPositions;
   double startingPrice;
   double lastPrice;
   double stopLossPrice;
};
position_Info LongPositionInfo, ShortPositionInfo;


struct open_Ready
{
   bool   LRSquareReady;
   bool   LReady;
   bool   NonLReady;
   bool   WmaReady;
};
open_Ready LongOpenReady, ShortOpenReady;

struct close_Ready
{
   bool    LReady;
   bool    SLRSquareReady;
   bool    NonLReady;
   bool    WmaReady;
   double  startingBSP;
   double  stopLossBSP;
   double  takeProfitBSP;
};
close_Ready LongCloseReady, ShortCloseReady;


int LRSquareHandle   = INVALID_HANDLE,
    SLRSquareHandle  = INVALID_HANDLE,
    LR2StdHandle     = INVALID_HANDLE,
    LongWmaHandle    = INVALID_HANDLE,
    ShortWmaHandle   = INVALID_HANDLE,
    BSPHandle        = INVALID_HANDLE, 
    NonLRHandle      = INVALID_HANDLE;

double LRSquareUpBand[], LRSquareDownBand[], LRSquareBuffer[], 
       SLRSquareUpBand[], SLRSquareDownBand[], SLRSquareBuffer[], SLRSquareColorBuffer[],
       LR2StdP1Band[], LR2StdP2Band[], LR2StdP3Band[], LR2StdM1Band[], LR2StdM2Band[], LR2StdM3Band[], LR2StdBuffer[],LR2StdColorBuffer[],
       LongWmaBuffer[], LongWmaColorBuffer[], 
       ShortWmaBuffer[], ShortWmaColorBuffer[], 
       BSPBuffer[],        
       NonLRBuffer[], NonLRColorBuffer[];

double BSPValue, ShortWmaValue;

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


   // Loading indicators..
   LRSquareHandle  = iCustom(_Symbol,PERIOD_M1,IND1, SquareLwmaPeriod, SquareLRPeriod, SquareLRSPeriod, SquareStdPeriodL, SquareStdPeriodS,
                                                     SquareMultiFactorL, SquareMultiFactorS );
   SLRSquareHandle = iCustom(_Symbol,PERIOD_M1,IND1, SSquareLwmaPeriod, SSquareLRPeriod, SSquareLRSPeriod, SSquareStdPeriodL, SSquareStdPeriodS,
                                                     SSquareMultiFactorL, SSquareMultiFactorS );
   LR2StdHandle    = iCustom(_Symbol,PERIOD_M1,IND2, LR2StdLwmaPeriod, LR2StdLRPeriod, LR2StdStdPeriodL, LR2StdStdPeriodS, LR2StdMultiFactorL1,
                                                     LR2StdMultiFactorL2, LR2StdMultiFactorL3, LR2StdMultiFactorS1, LR2StdMultiFactorS2, 
                                                     LR2StdMultiFactorS3 );
   LongWmaHandle   = iCustom(_Symbol,PERIOD_M1,IND3, LongWmaWmaPeriod, LongWmaWmaPeriod2 );
   ShortWmaHandle  = iCustom(_Symbol,PERIOD_M1,IND3, ShortWmaWmaPeriod, ShortWmaWmaPeriod2 );
   BSPHandle       = iCustom(_Symbol,PERIOD_M1,IND4, BspWmaPeriod, BspMultiRatio );
   NonLRHandle     = iCustom(_Symbol,PERIOD_M1,IND5, NonLRinpPeriod);

   if(LRSquareHandle==INVALID_HANDLE || SLRSquareHandle==INVALID_HANDLE ||
      LR2StdHandle==INVALID_HANDLE   || LongWmaHandle==INVALID_HANDLE   || 
      ShortWmaHandle==INVALID_HANDLE || BSPHandle == INVALID_HANDLE     || NonLRHandle==INVALID_HANDLE      )
   {
      Alert("Error when loading the indicator, please try again");
      return(-1);
   }  
  
   if(!Sym.Name(_Symbol)){
      Alert("CSymbolInfo initialization error, please try again");    
      return(-1);
   }


   ArraySetAsSeries(LRSquareUpBand, true);
   ArraySetAsSeries(LRSquareDownBand, true);
   ArraySetAsSeries(LRSquareBuffer, true);
   ArraySetAsSeries(SLRSquareUpBand, true);
   ArraySetAsSeries(SLRSquareDownBand, true);
   ArraySetAsSeries(SLRSquareBuffer, true);
   ArraySetAsSeries(SLRSquareColorBuffer, true);
   ArraySetAsSeries(LR2StdP3Band, true);
   ArraySetAsSeries(LR2StdP2Band, true);
   ArraySetAsSeries(LR2StdP1Band, true);
   ArraySetAsSeries(LR2StdM1Band, true);
   ArraySetAsSeries(LR2StdM2Band, true);
   ArraySetAsSeries(LR2StdM2Band, true);   
   ArraySetAsSeries(LR2StdBuffer, true);
   ArraySetAsSeries(LR2StdColorBuffer, true);   
   ArraySetAsSeries(LongWmaBuffer, true);
   ArraySetAsSeries(LongWmaColorBuffer, true);
   ArraySetAsSeries(ShortWmaBuffer, true);
   ArraySetAsSeries(ShortWmaColorBuffer, true);
   ArraySetAsSeries(BSPBuffer, true);
   ArraySetAsSeries(NonLRBuffer, true);
   ArraySetAsSeries(NonLRColorBuffer, true);

   PositionInfo();
   OpenReadyReset();
   CloseReadyReset();
        
   return(0);
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

   if(PositionsTotal() >= 1)
     {
      ClosePosition(POSITION_TYPE_BUY);
      ClosePosition(POSITION_TYPE_SELL);  
     }


   if(LRSquareHandle  != INVALID_HANDLE)  IndicatorRelease(LRSquareHandle);
   if(SLRSquareHandle != INVALID_HANDLE)  IndicatorRelease(SLRSquareHandle);
   if(LR2StdHandle    != INVALID_HANDLE)  IndicatorRelease(LR2StdHandle);
   if(LongWmaHandle   != INVALID_HANDLE)  IndicatorRelease(LongWmaHandle);   
   if(ShortWmaHandle  != INVALID_HANDLE)  IndicatorRelease(ShortWmaHandle);
   if(BSPHandle       != INVALID_HANDLE)  IndicatorRelease(BSPHandle);
   if(NonLRHandle     != INVALID_HANDLE)  IndicatorRelease(NonLRHandle);   

}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){

   if(_Period != PERIOD_M1){
      Alert("TimeFrame should be 1 Minute");
      return;
   }
     
   bool OpenBuy=false,
        OpenSell=false,   
        CloseBuy=false,
        CloseSell=false;
   
   datetime curTime = TimeCurrent();
      


   if( isNewBar(_Symbol) ) {

      if(!Indicators()) return;     

      if(PositionsTotal() >= 1)
      {
                     
         CloseBuy = SignalCloseBuy();
         if(CloseBuy)
           {
            MyLongClose();
           }    
            
         CloseSell = SignalCloseSell();
         if(CloseSell)
           {
            MyShortClose();
           }       
      }
      

      if(StartTrading)
      {

         OpenBuy = SignalOpenBuy();
         if(OpenBuy)
           {
            MyLongOpen();    
           }    
   
         OpenSell = SignalOpenSell();      
         if(OpenSell)
           {
            MyShortOpen();
           }
         
      }
      
     
   }   

//   Virtual_SLTP();

}



//+------------------------------------------------------------------+
bool SignalOpenBuy(){

   if( LongOpenReady.NonLReady)
     {
       return(true);         
     } 
   else return(false);
   
}

//+------------------------------------------------------------------+
bool SignalOpenSell(){

   if( ShortOpenReady.NonLReady)
     {
      return(true);
     }   
   else return(false);
   
}

//+------------------------------------------------------------------+
bool SignalCloseBuy(){

// Case1 : LRSquare or LRSTD is above the level, Do not check of trend of SLSSquare 
   if( LongCloseReady.LReady && LongCloseReady.NonLReady )
     {
      return(true);
     }  
   
// Case2 : LRSquare or LRSTD is below the level, and if trend of SLSSquare is Downtrend -> Close the positions 
   else if( LongCloseReady.SLRSquareReady && LongCloseReady.NonLReady )
     {
      return(true);
     }
   
    
   return(false);
}

//+------------------------------------------------------------------+
bool SignalCloseSell(){

//   if( ShortCloseReady.LReady && ShortCloseReady.WmaReady ){


   if(ShortCloseReady.NonLReady ){
    return(true);
   } 
   return(false);
   
}



void CloseReadyCheck(void)
  {

   if( LongPositionInfo.numberOfPositions >= 1 )
     {
      if((LRBand==BandP1) || (LRBand==BandP2) || (LRBand==BandP3) ) LongCloseReady.LReady = true;

      if(SLRSquareTrend == DownTrend) LongCloseReady.SLRSquareReady = true;
      else LongCloseReady.SLRSquareReady = false;

      if(ShortWmaTrend == DownTrend) LongCloseReady.WmaReady = true;
      else LongCloseReady.WmaReady = false;
 
      if(NonLRTrend == DownTrend) LongCloseReady.NonLReady = true;
      else LongCloseReady.NonLReady = false;
     }
 
    
   if( ShortPositionInfo.numberOfPositions >= 1)   
     {
      if((LRBand==BandM1) || (LRBand==BandM2) || (LRBand==BandM3)) ShortCloseReady.LReady = true;
  
      if(SLRSquareTrend == UpTrend)  ShortCloseReady.SLRSquareReady = true;
      else ShortCloseReady.SLRSquareReady = false;

      if(ShortWmaTrend == UpTrend)  ShortCloseReady.WmaReady = true;
      else ShortCloseReady.WmaReady = false;
      
      if(NonLRTrend == UpTrend)  ShortCloseReady.NonLReady = true;
      else ShortCloseReady.NonLReady = false;
     }
     
  }


void OpenReadyCheck(void)
  {

   if( LongPositionInfo.numberOfPositions <= 0 )
     {
      if(LRSquareBand == BandM1) LongOpenReady.LRSquareReady = true;
      
      if((LRBand==BandM1) || (LRBand==BandM2) || (LRBand==BandM3) ) LongOpenReady.LReady = true;
      
      if( LongOpenReady.LRSquareReady && LongOpenReady.LReady &&
          (ShortWmaTrend == UpTrend) ) LongOpenReady.WmaReady = true;
   
      if( LongOpenReady.LRSquareReady && LongOpenReady.LReady &&
          (NonLRTrend == UpTrend) ) LongOpenReady.NonLReady = true;
     }

   if( ShortPositionInfo.numberOfPositions <= 0 )
     {
      if(LRSquareBand == BandP1) ShortOpenReady.LRSquareReady = true;
      
      if((LRBand==BandP1) || (LRBand==BandP2) || (LRBand==BandP3) ) ShortOpenReady.LReady = true;
      
      if( ShortOpenReady.LRSquareReady && ShortOpenReady.LReady &&
          (ShortWmaTrend == DownTrend) ) ShortOpenReady.WmaReady = true;
         
      if( LongOpenReady.LRSquareReady && LongOpenReady.LReady &&
          (NonLRTrend == UpTrend) ) LongOpenReady.NonLReady = true;
     }

  }




//+------------------------------------------------------------------+
//|   Function for copying indicator data and price                   |
//+------------------------------------------------------------------+
bool Indicators(){

   double LRValue0, LRValue1, LRSquare0, LRSquare1;
   datetime curTime = TimeCurrent();

   if(CopyBuffer(LRSquareHandle,  0,  Shift,  2,  LRSquareBuffer     )     == -1   ||
      CopyBuffer(LRSquareHandle,  2,  Shift,  1,  LRSquareUpBand     )     == -1   ||
      CopyBuffer(LRSquareHandle,  3,  Shift,  1,  LRSquareDownBand   )     == -1   ||

      CopyBuffer(SLRSquareHandle,  0,  Shift,  2,  SLRSquareBuffer     )   == -1   ||
      CopyBuffer(SLRSquareHandle,  1,  Shift,  1,  SLRSquareColorBuffer)   == -1   ||
      CopyBuffer(SLRSquareHandle,  2,  Shift,  1,  SLRSquareUpBand     )   == -1   ||
      CopyBuffer(SLRSquareHandle,  3,  Shift,  1,  SLRSquareDownBand   )   == -1   ||

      CopyBuffer(LR2StdHandle,    0,  Shift,  2,  LR2StdBuffer       )     == -1   ||
      CopyBuffer(LR2StdHandle,    1,  Shift,  1,  LR2StdColorBuffer  )     == -1   ||
      CopyBuffer(LR2StdHandle,    2,  Shift,  1,  LR2StdP1Band       )     == -1   ||
      CopyBuffer(LR2StdHandle,    3,  Shift,  1,  LR2StdM1Band       )     == -1   ||
      CopyBuffer(LR2StdHandle,    4,  Shift,  1,  LR2StdP2Band       )     == -1   ||
      CopyBuffer(LR2StdHandle,    5,  Shift,  1,  LR2StdM2Band       )     == -1   ||
      CopyBuffer(LR2StdHandle,    6,  Shift,  1,  LR2StdP3Band       )     == -1   ||
      CopyBuffer(LR2StdHandle,    7,  Shift,  1,  LR2StdM3Band       )     == -1   ||

      CopyBuffer(LongWmaHandle,   1,  Shift,  1,  LongWmaBuffer      )     == -1   ||
      CopyBuffer(LongWmaHandle,   2,  Shift,  1,  LongWmaColorBuffer )     == -1   ||

      CopyBuffer(ShortWmaHandle,  1,  Shift,  1,  ShortWmaBuffer     )     == -1   ||
      CopyBuffer(ShortWmaHandle,  2,  Shift,  1,  ShortWmaColorBuffer)     == -1   ||

      CopyBuffer(BSPHandle,       1,  Shift,  1,  BSPBuffer          )     == -1   ||

      CopyBuffer(NonLRHandle,     0,  Shift,  1,  NonLRBuffer        )     == -1   ||
      CopyBuffer(NonLRHandle,     1,  Shift,  1,  NonLRColorBuffer   )     == -1   )   
   {
      return(false);
   }

   BSPValue = BSPBuffer[0];
   ShortWmaValue = ShortWmaBuffer[0];
   LRValue0 = LR2StdBuffer[0];
   LRValue1 = LR2StdBuffer[1]; 
   LRSquare0 = LRSquareBuffer[0]; 
   LRSquare1 = LRSquareBuffer[1]; 

   if( ((LRValue1 >= 0.) && (LRValue0 <= 0.) ) || ((LRValue1 <= 0.) && (LRValue0 >= 0.) ) )
     {
      if( Times(curTime) && !StartTrading ) StartTrading = true; 
      OpenReadyReset();
     } 

     
   if( !Times(curTime) && StartTrading ) StartTrading = false;     

   if      (LRSquareBuffer[0]>=LRSquareUpBand[0])                                    LRSquareBand = BandP1;
   else if (LRSquareBuffer[0]<=LRSquareDownBand[0])                                  LRSquareBand = BandM1;
   else if ( (LRSquareBuffer[0]<LRSquareUpBand[0]) && (LRSquareBuffer[0]>=0.) )      LRSquareBand = BandP0; 
   else if ( (LRSquareBuffer[0]>LRSquareDownBand[0]) && (LRSquareBuffer[0]<0.) )     LRSquareBand = BandM0; 
   else
     {
      Alert("LRSquareBand error");
      return(false);   
     }

   if      (SLRSquareBuffer[0]>=SLRSquareUpBand[0])                                  SLRSquareBand = BandP1;
   else if (SLRSquareBuffer[0]<=SLRSquareDownBand[0])                                SLRSquareBand = BandM1;
   else if ( (SLRSquareBuffer[0]<SLRSquareUpBand[0]) && (SLRSquareBuffer[0]>=0.) )   SLRSquareBand = BandP0; 
   else if ( (SLRSquareBuffer[0]>SLRSquareDownBand[0]) && (SLRSquareBuffer[0]<0.) )  SLRSquareBand = BandM0; 
   else
     {
      Alert("SLRSquareBand error");
      return(false);   
     }

   
   if      ( (LRValue0 < LR2StdP1Band[0]) && (LRValue0 >= 0.) ) LRBand = BandP0;
   else if ( (LRValue0 > LR2StdM1Band[0]) && (LRValue0 < 0.) )  LRBand = BandM0;
   else if (LRValue0 >=LR2StdP3Band[0])                         LRBand = BandP3;
   else if (LRValue0 >=LR2StdP2Band[0])                         LRBand = BandP2;
   else if (LRValue0 >=LR2StdP1Band[0])                         LRBand = BandP1;
   else if (LRValue0 <=LR2StdM3Band[0])                         LRBand = BandM3;
   else if (LRValue0 <=LR2StdM2Band[0])                         LRBand = BandM2;
   else if (LRValue0 <=LR2StdM1Band[0])                         LRBand = BandM1;
   else
     {
      Alert("LRBand error");
      return(false);   
     }
   
   if( (int)NormalizeDouble(SLRSquareColorBuffer[0], 0) == 1) SLRSquareTrend = DownTrend;
   else SLRSquareTrend = UpTrend;

   if( (int)NormalizeDouble(LongWmaColorBuffer[0], 0) == 1) LongWmaTrend = DownTrend;
   else LongWmaTrend = UpTrend;
   
   if( (int)NormalizeDouble(ShortWmaColorBuffer[0], 0) == 1 ) ShortWmaTrend = DownTrend;
   else ShortWmaTrend = UpTrend;
   
   if((int)NormalizeDouble(NonLRColorBuffer[0], 0) == 1) NonLRTrend = DownTrend;
   else NonLRTrend = UpTrend;

   if( ( (LongPositionInfo.numberOfPositions < 1) || (ShortPositionInfo.numberOfPositions < 1) )
          && StartTrading ) OpenReadyCheck();
   
   if( (LongPositionInfo.numberOfPositions >= 1) || ( ShortPositionInfo.numberOfPositions >= 1) ) CloseReadyCheck();
   
   return(true);   
}



void OpenReadyReset(void)
  {
   LongOpenReady.LRSquareReady    = false;
   LongOpenReady.LReady           = false;
   LongOpenReady.NonLReady        = false;
   LongOpenReady.WmaReady         = false;
   ShortOpenReady.LRSquareReady   = false;
   ShortOpenReady.LReady          = false;
   ShortOpenReady.NonLReady       = false;
   ShortOpenReady.WmaReady        = false;

  }


void CloseReadyReset(void)
  {
   LongCloseReady.LReady          = false;
   LongCloseReady.CLRSquareReady  = false;
   LongCloseReady.NonLReady       = false;
   LongCloseReady.WmaReady        = false;
   LongCloseReady.startingBSP     = 0.;
   LongCloseReady.stopLossBSP     = 0.;
   LongCloseReady.takeProfitBSP   = 0.;
   ShortCloseReady.LReady         = false;
   ShortCloseReady.CLRSquareReady = false;
   ShortCloseReady.NonLReady      = false;
   ShortCloseReady.WmaReady       = false;
   ShortCloseReady.startingBSP    = 0.;
   ShortCloseReady.stopLossBSP    = 0.;
   ShortCloseReady.takeProfitBSP  = 0.;
  }

void MyLongClose(void)
  {
   
   ClosePosition(POSITION_TYPE_BUY);
   PositionInfo();  
   CloseReadyReset();
  }

void MyShortClose(void)
  {
   
   ClosePosition(POSITION_TYPE_SELL);
   PositionInfo();  
   CloseReadyReset();
  }


void MyLongOpen(void)
  {
   
   OpenPosition(POSITION_TYPE_BUY);
   LongCloseReady.startingBSP = ShortWmaValue;
   LongCloseReady.stopLossBSP = LongCloseReady.startingBSP - BSPValue*SLBSPMultiFactor;
   LongCloseReady.takeProfitBSP = LongCloseReady.startingBSP + BSPValue*TPBSPMultiFactor;
    
   PositionInfo();  
   OpenReadyReset();
  }

void MyShortOpen(void)
  {

   OpenPosition(POSITION_TYPE_SELL);
   ShortCloseReady.startingBSP = ShortWmaValue;
   ShortCloseReady.stopLossBSP = ShortCloseReady.startingBSP + BSPValue*SLBSPMultiFactor;
   ShortCloseReady.takeProfitBSP = ShortCloseReady.startingBSP - BSPValue*TPBSPMultiFactor;
   
   PositionInfo();
   OpenReadyReset();
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