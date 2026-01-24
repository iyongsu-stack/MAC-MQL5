//+------------------------------------------------------------------+
//|                                                   BSP105V2-1.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//WMA20-WMA50, 

#define IND1 "NonLR"
#define IND3 "BSP105WMA"
#define IND4 "BSP105LRAVGSTDV2"
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

sinput   const string  Message1="";// NonLR
input int                 NonLRPeriod          = 40;          // NonLRPeriodS
sinput   const string  Message3="";// Wma
input int                 WmaPeriodS           = 12;          // wmaPeriodS
input int                 WmaPeriodL           = 20;          // wmaPeriodL
input int                 WmaPeriodLL          = 50;          // WmaPeriodLL
input int                 WmaPeriod2           = 200;         // WmaPeriod2
sinput   const string  Message4="";// WmaStd
input int                 WmaStdPeriod         = 10000;       // WmaPeriod
input double              WmaMultiFactor1      = 0.5;         // MultiFactor1
input double              WmaMultiFactor2      = 1.0;         // MultiFactor2
input double              WmaMultiFactor3      = 2.0;         // MultiFactor3                 
sinput   const string  Message5="";// AvgStd
input int                 ASLwmaPeriod         = 6;           // ASWmaPeriod1
input int                 ASAvgPeriod          = 50;          // ASAvgPeriod
input int                 ASStdPeriodL         = 10000;       // ASStdPeriodL
input int                 ASStdPeriodS         = 8;          // ASStdPeriodS
input double              ASMultiFactorL1      = 0.5;         // ASStdMultiFactorL1
input double              ASMultiFactorL2      = 1.5;         // ASStdMultiFactorL2
input double              ASMultiFactorL3      = 2.5;         // ASStdMultiFactorL3
sinput   const string  Message7="";// BSPAvg
input int                 BSPWmaPeriod         = 120;         // BSPWmaPeriod
input double              BSPMultiRatio        = 1.0;         // BSPMultiRatio
sinput   const string  Message8="";// HLAvg
input int                 HLWmaPeriod         = 120;          // HLWmaPeriod
input double              HLMultiRatio        = 1.0;          // HLMultiRatio




sinput   const string  Message9="";//Trading Time parameter
input    int              StartTime            = 3;            // Starting Time (Server Time)
input    int              EndTime              = 22;           // Ending(Last Open Position) Time (Server Time)

sinput   const string  Message10="";//EA Parameter
input    int              iMagicNumber         = 10000;       // Magic Number
input double              Lots                 = 0.01;        /*Lots*/             // Lot; if 0, MaximumRisk value is used
input double              MaximumRisk          = 1;           /*MaximumRisk*/      // Risk(if Lots=0) 0.01lot/1000$
input int                 StopLoss             = 0;           /*StopLoss*/            // Stop Loss in points
input int                 TakeProfit           = 0;           /*TakeProfit*/       // Take Profit in points
input bool                VirtualSLTP          = false;       /*VirtualSLTP*/     // Stop Loss, Take Profit setting.
input double              SLBSPMultiFactor     = 0.1;                              //SL BSP Multifactor
input double              TPBSPMultiFactor     = 0.3;                              //TP BSP Multifactor
input double              SLPriceMultiFactor   = 1.0;                              //SL Price Multifactor
input double              TPPriceMultiFactor   = 0.3;                              //TP Price Multifactor
input int                 MaxASRNumberOfBar    = 10;                                //Max ARS Number Of Bar
input int                 MinASRNumberOfBar    = 2;                                //Min ARS Number Of Bar
input int                 MaxGap               = 3;                                //Max Gap


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
BandState ASBand, WmaBand;

enum trend
{
   UpTrend,
   DownTrend, 
   NoTrend,       
};
trend ShortWmaTrend, LongWmaTrend, LLongWmaTrend, ASTrend, NonLRTrend,
      ShortWmaTrend1, LongWmaTrend1, LLongWmaTrend1, ASTrend1, ASTrend2, NonLRTrend1, NonLRTrend2;

enum ASR_Status
{
   NotReady,
   Original,
   Back, 
   Retro,       
};


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


enum open_Mode
{
   OppositeDirection,
   SameDirection,
   LongDirection,
   NotOpen,
   ShortOpenMode,
   ShortCloseMode,
};

struct open_Ready
{
   bool       ASReady;
   bool       ShortWmaReady;
   bool       ShortWmaChanged;
   bool       LongWmaReady;
   bool       LongWmaChanged;
   bool       SD2ShortWmaReady;
   BandState  MaxASBand;
   ASR_Status ASRStatus;
   int        ASRStartingBar;
   int        ASREndingBar;
   open_Mode OpenMode;
};
open_Ready BuyOpenReady, SellOpenReady;


struct close_Ready
{
   bool      ShortWmaReady;
   bool      LongWmaReady;  
   int       startingBar;
   open_Mode OpenMode;
   double    baseBSP;
   double    ShortStartingBSP;
   double    ShortStopLossBSP;
   double    ShortTakeProfitBSP;
   double    LongStartingBSP;
   double    LongStopLossBSP;
   double    LongTakeProfitBSP;
   
};
close_Ready BuyCloseReady, SellCloseReady;


int NonLRHandle      = INVALID_HANDLE,
    WmaHandleS       = INVALID_HANDLE,
    WmaHandleL       = INVALID_HANDLE,
    WmaHandleLL      = INVALID_HANDLE,
    ASHandle         = INVALID_HANDLE,
    BSPHandle        = INVALID_HANDLE, 
    HLHandle         = INVALID_HANDLE;

double NonLRBuffer[], NonLRColorBuffer[],

       ShortWmaBuffer[], ShortWmaColorBuffer[], AvgWmaBuffer[],
       WmaP3Band[], WmaP2Band[], WmaP1Band[], WmaM1Band[],  WmaM2Band[],  WmaM3Band[], 
       LongWmaBuffer[], LongWmaColorBuffer[], 
       LLongWmaBuffer[], LLongWmaColorBuffer[],

       ASBuffer[], ASColorBuffer[], 
       ASP1Band[], ASP2Band[], ASP3Band[], ASM1Band[], ASM2Band[], ASM3Band[],
       
       BSPBuffer[], HLBuffer[];
       

double NonLRValue, SLTPBSPValue, ShortWmaValue, LongWmaValue, LLongWmaValue, HLValue, CurPrice;

double lot,slv=0,msl,tpv=0,mtp;

bool _VirtualSLTP;

int TotalNumberOfPositions = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

   Trade.SetExpertMagicNumber(iMagicNumber);

   _VirtualSLTP=VirtualSLTP;
   if(_VirtualSLTP && StopLoss<=0 && TakeProfit<=0){
      _VirtualSLTP=false;
   }

   // Loading indicators..
   NonLRHandle       = iCustom(_Symbol,PERIOD_M1,IND1, NonLRPeriod );
   WmaHandleS        = iCustom(_Symbol,PERIOD_M1,IND7, WmaPeriodS, WmaPeriod2, WmaStdPeriod, WmaMultiFactor1, 
                                                       WmaMultiFactor2, WmaMultiFactor3 );
   WmaHandleL        = iCustom(_Symbol,PERIOD_M1,IND3, WmaPeriodL, WmaPeriod2);
   WmaHandleLL       = iCustom(_Symbol,PERIOD_M1,IND3, WmaPeriodLL, WmaPeriod2);   
   ASHandle          = iCustom(_Symbol,PERIOD_M1,IND4, ASLwmaPeriod, ASAvgPeriod, ASStdPeriodL, ASStdPeriodS, 
                                                       ASMultiFactorL1, ASMultiFactorL2, ASMultiFactorL3);
   BSPHandle         = iCustom(_Symbol,PERIOD_M1,IND6, BSPWmaPeriod, BSPMultiRatio );  
   HLHandle          = iCustom(_Symbol,PERIOD_M1,IND8, HLWmaPeriod, HLMultiRatio );  


   if( NonLRHandle     == INVALID_HANDLE  || WmaHandleS      == INVALID_HANDLE || WmaHandleL      == INVALID_HANDLE || WmaHandleLL     == INVALID_HANDLE || 
       ASHandle        == INVALID_HANDLE  || BSPHandle       == INVALID_HANDLE || HLHandle        == INVALID_HANDLE )
   {
      Alert("Error when loading the indicator, please try again");
      return(-1);
   }  
  
   if(!Sym.Name(_Symbol)){
      Alert("CSymbolInfo initialization error, please try again");    
      return(-1);
   }

   ArraySetAsSeries(NonLRBuffer, true);
   ArraySetAsSeries(NonLRColorBuffer, true);

   ArraySetAsSeries(ShortWmaBuffer, true);
   ArraySetAsSeries(ShortWmaColorBuffer, true);
   ArraySetAsSeries(AvgWmaBuffer, true);
   ArraySetAsSeries(WmaP3Band, true);
   ArraySetAsSeries(WmaP2Band, true);
   ArraySetAsSeries(WmaP1Band, true);
   ArraySetAsSeries(WmaM1Band, true);
   ArraySetAsSeries(WmaM2Band, true);
   ArraySetAsSeries(WmaM3Band, true);

   ArraySetAsSeries(LongWmaBuffer, true);
   ArraySetAsSeries(LongWmaColorBuffer, true);

   ArraySetAsSeries(LLongWmaBuffer, true);
   ArraySetAsSeries(LLongWmaColorBuffer, true);

   ArraySetAsSeries(ASBuffer, true);
   ArraySetAsSeries(ASColorBuffer, true);
   ArraySetAsSeries(ASP1Band, true);
   ArraySetAsSeries(ASP2Band, true);
   ArraySetAsSeries(ASP3Band, true);
   ArraySetAsSeries(ASM1Band, true);
   ArraySetAsSeries(ASM2Band, true);
   ArraySetAsSeries(ASM3Band, true);

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

   if(NonLRHandle     !=  INVALID_HANDLE)  IndicatorRelease(NonLRHandle);
   if(WmaHandleS      !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleS);
   if(WmaHandleL      !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleL);   
   if(WmaHandleLL     !=  INVALID_HANDLE)  IndicatorRelease(WmaHandleLL);   
   if(ASHandle        !=  INVALID_HANDLE)  IndicatorRelease(ASHandle);  
   if(BSPHandle       !=  INVALID_HANDLE)  IndicatorRelease(BSPHandle);   
   if(HLHandle        !=  INVALID_HANDLE)  IndicatorRelease(HLHandle);  

}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

   if(_Period != PERIOD_M1){
      Alert("TimeFrame should be 1 Minute!");
      return;
   }
     
   
   datetime curTime = TimeCurrent();
      

   if( isNewBar(_Symbol) ) 
     {

      bool   OpenBuy   = false,
             OpenSell  = false,   
             CloseBuy  = false,
             CloseSell = false;

      if(!Indicators()) 
        {
         Alert("Indicator Allocation error!");
         return;
        }     
      

      if(StartTrading)
        {

         OpenReadyCheck();

         OpenBuy = SignalOpenBuy();
         if(OpenBuy)
           {
            MyBuyOpen(BuyOpenReady.OpenMode);    
           }    
   
         OpenSell = SignalOpenSell();      
         if(OpenSell)
           {
            MySellOpen(SellOpenReady.OpenMode);
           }        
         }          

      if( TotalNumberOfPositions >= 1)
        {

         CloseReadyCheck();
                     
         CloseBuy = SignalCloseBuy();
         if(CloseBuy)
           {
            MyBuyClose();
           }    
            
         CloseSell = SignalCloseSell();
         if(CloseSell)
           {
            MySellClose();
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

       double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

       if( (askPrice < BuyPositionInfo.stopLossPrice) )
         {
          return(true);
         }

       if( (BuyCloseReady.OpenMode == SameDirection) )  
         {
          if(BuyCloseReady.LongWmaReady )
            { 
             return(true);
            }
         }


/*
       if( (BuyCloseReady.OpenMode == OppositeDirection) || (BuyCloseReady.OpenMode == ShortCloseMode) ||
           (BuyCloseReady.OpenMode == SameDirection) )  
         {
          if(BuyCloseReady.ShortWmaReady )
            { 
             return(true);
            }
         }
       else if(BuyCloseReady.OpenMode == LongDirection)
         {
          if(BuyCloseReady.LongWmaReady)
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

      double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      if( (bidPrice > SellPositionInfo.stopLossPrice)) 
        {
         return(true);
        }

       if( (SellCloseReady.OpenMode == SameDirection) )  
         {
          if(SellCloseReady.LongWmaReady )
            { 
             return(true);
            }
         }


/*        
       if( (SellCloseReady.OpenMode == OppositeDirection) || (SellCloseReady.OpenMode == ShortCloseMode) ||
           (SellCloseReady.OpenMode == SameDirection) )  
         {
          if(SellCloseReady.ShortWmaReady )
            { 
             return(true);
            }
         }
       else if(SellCloseReady.OpenMode == LongDirection)
         {
          if(SellCloseReady.LongWmaReady)
            { 
             return(true);
            }
         
         }
*/        
     }

   return(false);
   

  }

  
//+--------------------------------------------------------------------+ 
bool SignalOpenBuy()
  {
/*
// Short Open Mode
   if((TotalNumberOfPositions <= 0) && BuyOpenReady.MaxASBand == BandM3 &&  BuyOpenReady.ShortWmaReady)
     {
       BuyOpenReady.OpenMode = ShortOpenMode;
       return(true);
     }

// Oppossite Direction
   if( (TotalNumberOfPositions <= 0) && BuyOpenReady.LongWmaChanged && BuyOpenReady.ShortWmaReady )
     {
       BuyOpenReady.OpenMode = OppositeDirection;
       return(true);         
     } 
*/     
// Same Direction, LongDirection-Case1
   if( (TotalNumberOfPositions <= 0) && BuyOpenReady.SD2ShortWmaReady)
     {
       BuyOpenReady.OpenMode = SameDirection;
       return(true);         
     } 

   return(false);
   
  }

//+---------------------------------------------------------------------+
bool SignalOpenSell()
  {
/*
// Short Open Mode
   if((TotalNumberOfPositions <= 0) && SellOpenReady.MaxASBand == BandP3 &&  BuyOpenReady.ShortWmaReady)
     {
       SellOpenReady.OpenMode = ShortOpenMode;
       return(true);
     }

// Opposite Direction
   if( (TotalNumberOfPositions <= 0) && SellOpenReady.ShortWmaReady && SellOpenReady.LongWmaChanged )
     {
      SellOpenReady.OpenMode = OppositeDirection;
      return(true);
     }   
*/
// Same Direction, LongDirection-CASE1
   if( (TotalNumberOfPositions <= 0) && SellOpenReady.SD2ShortWmaReady)
     {
       SellOpenReady.OpenMode = SameDirection;
       return(true);         
     } 

   return(false);
   
  }



  

//-------------------------------------------------------------------+
void OpenReadyCheck(void)
  {

   if(TotalNumberOfPositions < 1)
     {

      int curBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT); 

//  Opposite Direction Buy Open Ready Check
      if( ASBand == BandM2 || ASBand == BandM3  ) 
        {
         BuyOpenReady.ASReady = true;

         if( (ASBand==BandM3) ) BuyOpenReady.MaxASBand = BandM3;
         else if( BuyOpenReady.MaxASBand != BandM3)  BuyOpenReady.MaxASBand = BandM2;
        }
        
      if( BuyOpenReady.ASReady && (ShortWmaTrend == UpTrend) && (BuyOpenReady.ShortWmaChanged == false) ) 
        {
         BuyOpenReady.ShortWmaReady = true;
         BuyOpenReady.ShortWmaChanged = true; 
        }   
      else if (BuyOpenReady.ASReady && (ShortWmaTrend == UpTrend) && (BuyOpenReady.ShortWmaChanged == true) ) BuyOpenReady.ShortWmaReady = true;
      else  BuyOpenReady.ShortWmaReady = false;      

      if( BuyOpenReady.ASReady && (LongWmaTrend == UpTrend) && (BuyOpenReady.LongWmaChanged == false) ) 
        {
         BuyOpenReady.LongWmaReady = true; 
         BuyOpenReady.LongWmaChanged = true;

         BuyCloseReady.LongStartingBSP = LongWmaValue;
         BuyCloseReady.LongStopLossBSP = BuyCloseReady.LongStartingBSP - SLTPBSPValue*SLBSPMultiFactor;
         BuyCloseReady.LongTakeProfitBSP = BuyCloseReady.LongStartingBSP  + SLTPBSPValue*TPBSPMultiFactor;       
        }  
      else if(BuyOpenReady.ASReady && (LongWmaTrend == UpTrend) && (BuyOpenReady.LongWmaChanged == true) ) BuyOpenReady.LongWmaReady = true;  
      else  BuyOpenReady.LongWmaReady = false;

// Same Direction Sell Check       
      if( BuyOpenReady.ASReady && (ASTrend == DownTrend) && (SellOpenReady.ASRStatus == NotReady)) SellOpenReady.ASRStatus=Original;
      else if( BuyOpenReady.ASReady && (SellOpenReady.ASRStatus == Original) && (ASTrend == UpTrend) && 
              (ASBand == BandM2 || ASBand == BandM3))
        {
         SellOpenReady.ASRStatus=Back;
         if( SellOpenReady.ASRStartingBar == 0) SellOpenReady.ASRStartingBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT); 
        }
      else if( BuyOpenReady.ASReady && (ASTrend2 == UpTrend) && (ASTrend1 == UpTrend) && (ASTrend == DownTrend) &&
               (SellOpenReady.ASRStatus == Back) && (ASBand == BandM1 || ASBand == BandM2 || ASBand == BandM3))
        {
         SellOpenReady.ASRStatus=Retro;
         if( SellOpenReady.ASREndingBar == 0) SellOpenReady.ASREndingBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT); 
        }
            
      if( (SellOpenReady.ASRStatus == Retro) && ((SellOpenReady.ASREndingBar-SellOpenReady.ASRStartingBar) <= MaxASRNumberOfBar ) &&
          ((SellOpenReady.ASREndingBar-SellOpenReady.ASRStartingBar) >= MinASRNumberOfBar ) && 
          ((curBar-SellOpenReady.ASREndingBar) <= MaxGap ) && 
          (ShortWmaTrend == DownTrend) && (LongWmaTrend == DownTrend) && (LLongWmaTrend == DownTrend)  )
        {
         SellOpenReady.SD2ShortWmaReady = true;
        }    
      
       

//  Opposite Direction Sell Ready Check
      if( ASBand == BandP2 || ASBand == BandP3 )
        {
         SellOpenReady.ASReady = true;

         if( (ASBand==BandP3) ) SellOpenReady.MaxASBand = BandP3;
         else if( SellOpenReady.MaxASBand != BandP3)  SellOpenReady.MaxASBand = BandP2;

        } 

      if( SellOpenReady.ASReady && (ShortWmaTrend == DownTrend) && (SellOpenReady.ShortWmaChanged == false)) 
        {
         SellOpenReady.ShortWmaReady = true;
         SellOpenReady.ShortWmaChanged = true;  
        } 
      else if( SellOpenReady.ASReady && (ShortWmaTrend == DownTrend) && (SellOpenReady.ShortWmaChanged == true)) SellOpenReady.ShortWmaReady = true;
      else   SellOpenReady.ShortWmaReady = false;   

      if( SellOpenReady.ASReady && (LongWmaTrend == DownTrend) && (SellOpenReady.LongWmaChanged == false)) 
        {
         SellOpenReady.LongWmaReady = true;
         SellOpenReady.LongWmaChanged = true;  

         SellCloseReady.LongStartingBSP = LongWmaValue;
         SellCloseReady.LongStopLossBSP = SellCloseReady.LongStartingBSP + SLTPBSPValue*SLBSPMultiFactor;   
         SellCloseReady.LongTakeProfitBSP = SellCloseReady.LongStartingBSP - SLTPBSPValue*TPBSPMultiFactor;
        } 
      else if( SellOpenReady.ASReady && (LongWmaTrend == DownTrend) && (SellOpenReady.LongWmaChanged == true)) SellOpenReady.LongWmaReady = true;
      else   SellOpenReady.LongWmaReady = false;   

// Same Direction Buy Check
      if( SellOpenReady.ASReady && (BuyOpenReady.ASRStatus == NotReady) && (ASTrend == UpTrend)  ) BuyOpenReady.ASRStatus=Original;
      else if( SellOpenReady.ASReady && (BuyOpenReady.ASRStatus == Original) && (ASTrend == DownTrend) && 
              (ASBand == BandP2 || ASBand == BandP3))
        {
         BuyOpenReady.ASRStatus=Back;
         if( BuyOpenReady.ASRStartingBar == 0) BuyOpenReady.ASRStartingBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT); 
        }
      else if( SellOpenReady.ASReady && (ASTrend2 == DownTrend) && (ASTrend1 == DownTrend) && (ASTrend == UpTrend) &&
               (BuyOpenReady.ASRStatus == Back) && (ASBand == BandP1 || ASBand == BandP2 || ASBand == BandP3))
        {
         BuyOpenReady.ASRStatus=Retro;
         if( BuyOpenReady.ASREndingBar == 0) BuyOpenReady.ASREndingBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT); 
        }
            
      if( (BuyOpenReady.ASRStatus == Retro) && ((BuyOpenReady.ASREndingBar-BuyOpenReady.ASRStartingBar) <= MaxASRNumberOfBar ) &&
          ((BuyOpenReady.ASREndingBar-BuyOpenReady.ASRStartingBar) >= MinASRNumberOfBar ) && 
          ((curBar-BuyOpenReady.ASREndingBar) <= MaxGap ) && 
          (ShortWmaTrend == UpTrend) && (LongWmaTrend == UpTrend) && (LLongWmaTrend == UpTrend)  )
        {
         BuyOpenReady.SD2ShortWmaReady = true;
        }   




/*
      if(SellOpenReady.ShortWmaChanged && !SellOpenReady.LongWmaChanged && (ShortWmaTrend1 == UpTrend) && (ShortWmaTrend == UpTrend)) 
        {
          BuyOpenReady.SD2ShortWmaReady = true;

          BuyCloseReady.LongStartingBSP = LongWmaValue;
          BuyCloseReady.LongStopLossBSP = BuyCloseReady.LongStartingBSP - SLTPBSPValue*SLBSPMultiFactor;
          BuyCloseReady.LongTakeProfitBSP = BuyCloseReady.LongStartingBSP  + SLTPBSPValue*TPBSPMultiFactor;       
        } 
*/
     }    
  }   


//------------------------------------------------------------------+
void CloseReadyCheck(void)
  {


   if( BuyPositionInfo.numberOfPositions >= 1 )
     {

      if(ShortWmaTrend == DownTrend) BuyCloseReady.ShortWmaReady = true; 
      else BuyCloseReady.ShortWmaReady = false;
      
      if( LongWmaTrend == DownTrend) BuyCloseReady.LongWmaReady = true; 
      else BuyCloseReady.LongWmaReady = false;      
/*      
// Change to LongDircetion Case-2
      if( (BuyCloseReady.OpenMode == SameDirection) && ( (WmaBand == BandP2) || (WmaBand == BandP3) ) &&
          (BuyCloseReady.OpenMode != LongDirection) )
        {
         BuyCloseReady.OpenMode = LongDirection;
        }

// if AS bigger than P3, change to ShortCloseMode        
      if( ASBand == BandP3 )
        {
         BuyCloseReady.OpenMode = ShortCloseMode;
        }
*/
     }

     
   if( SellPositionInfo.numberOfPositions >= 1)   
     {

      if((ShortWmaTrend1 == UpTrend) && (ShortWmaTrend == UpTrend))  SellCloseReady.ShortWmaReady = true;
      else SellCloseReady.ShortWmaReady = false;
      
      if((LongWmaTrend1 == UpTrend) && (LongWmaTrend == UpTrend))  SellCloseReady.LongWmaReady = true;
      else SellCloseReady.LongWmaReady = false;

/*
// Change to LongDircetion Case-2
      if( (SellCloseReady.OpenMode == SameDirection) && ( (WmaBand == BandM2) || (WmaBand == BandM3) ) &&
          (BuyCloseReady.OpenMode != LongDirection) )
        {
         BuyCloseReady.OpenMode = LongDirection;
        }

// if AS smaller than M3, change to ShortCloseMode        
      if( ASBand == BandM3 )
        {
         BuyCloseReady.OpenMode = ShortCloseMode;
        }
*/
     }
     
  }
  

//+------------------------------------------------------------------+
//|   Function for copying indicator data and price                   |
//+------------------------------------------------------------------+
bool Indicators()
{

   datetime curTime = TimeCurrent();

   if(CopyBuffer(NonLRHandle,      0,  Shift,  1, NonLRBuffer)            == -1   ||
      CopyBuffer(NonLRHandle,      1,  Shift,  1, NonLRColorBuffer)       == -1   ||
      
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

      CopyBuffer(BSPHandle,        1,  Shift,  1, BSPBuffer)              == -1   ||
      
      CopyBuffer(HLHandle,         1,  Shift,  1, HLBuffer)               == -1   )

   {
      return(false);
   }


   NonLRValue = NonLRBuffer[0];
   SLTPBSPValue = BSPBuffer[0];
   ShortWmaValue = ShortWmaBuffer[0];
   LongWmaValue = LongWmaBuffer[0];
   LLongWmaValue = LLongWmaBuffer[0];
   HLValue = HLBuffer[0];   

   NonLRTrend2 = NonLRTrend1;
   NonLRTrend1 = NonLRTrend;;
   if( (int)NormalizeDouble(NonLRColorBuffer[0], 0) == 1) NonLRTrend = DownTrend;
   else NonLRTrend = UpTrend;

   ShortWmaTrend1 = ShortWmaTrend;
   if( (int)NormalizeDouble(ShortWmaColorBuffer[0], 0) == 1) ShortWmaTrend = DownTrend;
   else ShortWmaTrend = UpTrend;
   
   LongWmaTrend1 = LongWmaTrend;
   if( (int)NormalizeDouble(LongWmaColorBuffer[0], 0) == 1 ) LongWmaTrend = DownTrend;
   else LongWmaTrend = UpTrend;

   LLongWmaTrend1 = LLongWmaTrend;
   if( (int)NormalizeDouble(LLongWmaColorBuffer[0], 0) == 1 ) LLongWmaTrend = DownTrend;
   else LLongWmaTrend = UpTrend;

   if      (ASBuffer[0] > ASP3Band[0])         ASBand = BandP3;
   else if (ASBuffer[0] > ASP2Band[0])         ASBand = BandP2;
   else if (ASBuffer[0] > ASP1Band[0])         ASBand = BandP1; 
   else if (ASBuffer[0] > 0. )                 ASBand = BandP0;
   else if (ASBuffer[0] > ASM1Band[0])         ASBand = BandM0;
   else if (ASBuffer[0] > ASM2Band[0])         ASBand = BandM1;
   else if (ASBuffer[0] > ASM3Band[0])         ASBand = BandM2;
   else                                        ASBand = BandM3; 
   
   ASTrend2 = ASTrend1;
   ASTrend1 = ASTrend;
   if( (int)NormalizeDouble(ASColorBuffer[0], 0) == 1) ASTrend = DownTrend;
   else ASTrend = UpTrend;   
 
   if      (ShortWmaValue > WmaP3Band[0])       WmaBand = BandP3;
   else if (ShortWmaValue > WmaP2Band[0])       WmaBand = BandP2;
   else if (ShortWmaValue > WmaP1Band[0])       WmaBand = BandP1;
   else if (ShortWmaValue > AvgWmaBuffer[0])    WmaBand = BandP0;
   else if (ShortWmaValue > WmaM1Band[0])       WmaBand = BandM0;
   else if (ShortWmaValue > WmaM2Band[0])       WmaBand = BandM1;
   else if (ShortWmaValue > WmaM3Band[0])       WmaBand = BandM2;
   else                                         WmaBand = BandM3;
   
   if( (ASBuffer[1]>=0. && ASBuffer[0]<=0. ) || (ASBuffer[1]<=0. && ASBuffer[0]>=0.) )
     {
      if( Times(curTime) && !StartTrading )  StartTrading = true;       
      OpenReadyReset();
     }     

   if( !Times(curTime) && StartTrading )  StartTrading = false;  

   return(true);   
}


//-------------------------------------------------------------------------+
void MyBuyOpen(open_Mode t_OpenMode)
{
      
   OpenPosition(POSITION_TYPE_BUY, EnumToString(t_OpenMode));
   BuyCloseReady.OpenMode = t_OpenMode;
    
   BuyCloseReady.startingBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT);
   BuyCloseReady.baseBSP = SLTPBSPValue;
   BuyCloseReady.ShortStartingBSP = ShortWmaValue;
   BuyCloseReady.ShortStopLossBSP = BuyCloseReady.ShortStartingBSP - SLTPBSPValue*SLBSPMultiFactor;
   BuyCloseReady.ShortTakeProfitBSP = BuyCloseReady.ShortStartingBSP + SLTPBSPValue*TPBSPMultiFactor;
    
   PositionInfo(); 
   BuyPositionInfo.stopLossPrice = BuyPositionInfo.startingPrice -  HLValue * SLPriceMultiFactor;
   BuyPositionInfo.takeProfitPrice = BuyPositionInfo.startingPrice + HLValue * TPPriceMultiFactor;
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;    
   OpenReadyReset();

}

//--------------------------------------------------------------------------+
void MySellOpen(open_Mode t_OpenMode)
{
   
   OpenPosition(POSITION_TYPE_SELL, EnumToString(t_OpenMode));
   SellCloseReady.OpenMode = t_OpenMode;
   
   SellCloseReady.startingBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT);
   SellCloseReady.baseBSP = SLTPBSPValue;
   SellCloseReady.ShortStartingBSP = ShortWmaValue;
   SellCloseReady.ShortStopLossBSP = SellCloseReady.ShortStartingBSP + SLTPBSPValue*SLBSPMultiFactor;
   SellCloseReady.ShortTakeProfitBSP = SellCloseReady.ShortStartingBSP - SLTPBSPValue*TPBSPMultiFactor;
   
   PositionInfo();
   SellPositionInfo.stopLossPrice = SellPositionInfo.startingPrice + HLValue * SLPriceMultiFactor;
   SellPositionInfo.takeProfitPrice = SellPositionInfo.startingPrice - HLValue * TPPriceMultiFactor;
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;   
   OpenReadyReset();

}



//------------------------------------------------------------------------+
void MyBuyClose(void)
{
   
   ClosePosition(POSITION_TYPE_BUY);
   PositionInfo();  
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;
   CloseReadyReset();
}

//-------------------------------------------------------------------------+
void MySellClose(void)
{
   
   ClosePosition(POSITION_TYPE_SELL);
   PositionInfo();  
   TotalNumberOfPositions = BuyPositionInfo.numberOfPositions + SellPositionInfo.numberOfPositions;
   CloseReadyReset();
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
   BuyOpenReady.ShortWmaChanged = false;
   BuyOpenReady.LongWmaReady = false;
   BuyOpenReady.LongWmaChanged = false;
   BuyOpenReady.SD2ShortWmaReady = false;
   BuyOpenReady.MaxASBand = BandM0;
   BuyOpenReady.ASRStatus = NotReady;
   BuyOpenReady.ASRStartingBar = 0;
   BuyOpenReady.ASREndingBar = 0;
   BuyOpenReady.OpenMode = NotOpen;
   SellOpenReady.ASReady = false;
   SellOpenReady.ShortWmaReady = false;
   SellOpenReady.ShortWmaChanged = false;
   SellOpenReady.LongWmaReady = false;
   SellOpenReady.LongWmaChanged = false;
   SellOpenReady.SD2ShortWmaReady = false;
   SellOpenReady.ASRStatus = NotReady;
   SellOpenReady.ASRStartingBar = 0;
   SellOpenReady.ASREndingBar = 0;
   SellOpenReady.MaxASBand = BandP0;
   SellOpenReady.OpenMode = NotOpen;
}

//-------------------------------------------------------------------+
void CloseReadyReset(void)
{

   if( BuyPositionInfo.numberOfPositions < 1 )
     {
      BuyCloseReady.ShortWmaReady = false;
      BuyCloseReady.LongWmaReady = false;
      BuyCloseReady.OpenMode = NotOpen;
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
      SellCloseReady.ShortWmaReady = false;
      SellCloseReady.LongWmaReady = false;
      SellCloseReady.OpenMode = NotOpen;
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
 
