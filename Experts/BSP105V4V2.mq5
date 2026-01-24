//+------------------------------------------------------------------+
//|                                                   BSP105V4V2.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#define IND1 "BSP105V4\\BSP105NLR"
#define IND2 "BSP105V4\\BSP105LRAVGSTD"
#define IND3 "BSP105V4\\BSP105WMA"
#define IND4 "BSP105V4\\BSP105BSP"

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/PositionInfo.mqh>

CTrade Trade;
CDealInfo Deal;
CSymbolInfo Sym;
CPositionInfo Pos;

input group               "LRAVGSTDS"
input int                 LwmaPeriodS    = 20;          // WmaPeriodS
input int                 AvgPeriodS    = 30;          //AvgPeriodS
input int                 StdPeriodLS    = 5000;        // StdPeriodLS
input int                 StdPeriodSS    = 1;        // StdPeriodSS
input double              MultiFactorL1S  = 1.0;         // StdMultiFactorL1S
input double              MultiFactorL2S  = 2.0;         // StdMultiFactorL2S
input double              MultiFactorL3S  = 3.0;         // StdMultiFactorL3S
input double              MaxBSPMultS     = 20.0;        // MaxBSPmultfactorS

input group               "LRAVGSTDM"
input int                 LwmaPeriodM    = 20;          // WmaPeriodM
input int                 AvgPeriodM    =60;          //AvgPeriodM
input int                 StdPeriodLM    = 5000;        // StdPeriodLM
input int                 StdPeriodSM    = 1;        // StdPeriodSM
input double              MultiFactorL1M  = 1.0;         // StdMultiFactorL1M
input double              MultiFactorL2M  = 2.0;         // StdMultiFactorL2M
input double              MultiFactorL3M  = 3.0;         // StdMultiFactorL3M
input double              MaxBSPMultM     = 20.0;         // MaxBSPmultfactorM

input group               "LRAVGSTDL"
input int                 LwmaPeriodL    = 5;          // WmaPeriodL
input int                 AvgPeriodL    = 7;          //AvgPeriodL
input int                 StdPeriodLL    = 5000;        // StdPeriodLL
input int                 StdPeriodSL    = 2;        // StdPeriodSL
input double              MultiFactorL1L  = 1.0;         // StdMultiFactorL1L
input double              MultiFactorL2L  = 2.0;         // StdMultiFactorL2L
input double              MultiFactorL3L  = 5.0;         // StdMultiFactorL3L
input double              MaxBSPMultL     = 20.0;         // MaxBSPmultfactorL

input group               "NonLR"
input int                 NLRSPeriod          = 15;          // NLRSPeriod
input int                 NLRMPeriod          = 30;          // NLRMPeriod
input int                 NLRLPeriod          = 80;          // NLRMPeriod

input group               "Wma"
input int                 WmaPeriodS    = 5;          // BspWmaPeriod
input int                 WmaPeriodM    = 10;          // BspWmaPeriod
input int                 WmaPeriodL    = 25;          // BspWmaPeriod

input group               "Bsp"
input int                 WmaBSP           = 10;          // BSPWmaPeriod
input int                 BSPStdPeriodL    = 5000;        // BSPStdPeriodL
input double              BSPMultiFactorL1  = 1.0;         // BSPStdMultiFactorL1
input double              BSPMultiFactorL2  = 2.0;         // BSPStdMultiFactorL2
input double              BSPMultiFactorL3  = 3.0;         // BSPStdMultiFactorL3
input double              BSPCutOff         = 5.0;         // BSPStdMultiFactorL3

input group               "Trading Time parameter"
input    int              StartTime            = 2;            // Starting Time (Server Time)
input    int              EndTime              = 23;           // Ending Time (Server Time)

input group               "EA Parameter"
input    int              iMagicNumber         = 10000;       // Magic Number
input double              Lots                 = 1.;        /*Lots*/             // Lot; if 0, MaximumRisk value is used
input double              LotsMultiFactor      = 2.0;         /*LotsMultiFactor*/  // Lot Size MultiFactor
input double              MaximumRisk          = 1;           /*MaximumRisk*/      // Risk(if Lots=0) 0.01lot/1000$
input int                 StopLoss             = 0;           /*StopLoss*/            // Stop Loss in points
input int                 TakeProfit           = 0;           /*TakeProfit*/       // Take Profit in points
input bool                VirtualSLTP          = false;       /*VirtualSLTP*/     // Stop Loss, Take Profit setting.
input double              SLBSPMultiFactor     = 0.1;                              //SL BSP Multifactor
input double              TPBSPMultiFactor     = 0.3;                              //TP BSP Multifactor
input double              SLPriceMultiFactor   = 1.0;                              //SL Price Multifactor
input double              TPPriceMultiFactor   = 0.3;                              //TP Price Multifactor
input int                 MaxASRNumberOfBar    = 10;                                //Max ARS Number Of Bar
input int                 MinASRNumberOfBar    = 1;                                //Min ARS Number Of Bar
input int                 MaxGap               = 3;                                //Max Gap
input ulong               CounterOpenMaxBar    = 15;                               //CounterOpen Maximum Bar Gap                 

int NLRSHandle       = INVALID_HANDLE,
    NLRMHandle       = INVALID_HANDLE,
    NLRLHandle       = INVALID_HANDLE,
    LASHandleM       = INVALID_HANDLE,
    LASHandleL       = INVALID_HANDLE,
    LASHandleS       = INVALID_HANDLE,
    WmaHandleS       = INVALID_HANDLE,
    WmaHandleM       = INVALID_HANDLE,
    WmaHandleL       = INVALID_HANDLE,    
    BSPHandle        = INVALID_HANDLE;

double NLRSBuffer[], NLRSColorBuffer[],
       NLRMBuffer[], NLRMColorBuffer[],
       NLRLBuffer[], NLRLColorBuffer[],

       LASMBuffer[], LASMColorBuffer[],
       LASMP3Band[], LASMP2Band[], LASMP1Band[], LASMM1Band[],  LASMM2Band[],  LASMM3Band[], 

       LASLBuffer[], LASLColorBuffer[],
       LASLP3Band[], LASLP2Band[], LASLP1Band[], LASLM1Band[],  LASLM2Band[],  LASLM3Band[], 

       LASSBuffer[], LASSColorBuffer[],
       LASSP3Band[], LASSP2Band[], LASSP1Band[], LASSM1Band[],  LASSM2Band[],  LASSM3Band[], 

       WmaSBuffer[], WmaSColorBuffer[], 
       WmaMBuffer[], WmaMColorBuffer[], 
       WmaLBuffer[], WmaLColorBuffer[], 

       BSPBuffer[], BSPColorBuffer[], BSPWmaBuffer[],
       BSP3Band[], BSP2Band[], BSP1Band[];
       

double NLRSValue, NLRMValue, NLRLValue, LASMValue, LASLValue, LASSValue, WmaSValue, WmaMValue, WmaLValue, BSPValue, BSPWmaValue, CurPrice;

double lot,slv=0,msl,tpv=0,mtp;

bool _VirtualSLTP;

int Shift= 1, CurBar;             /*Shift*/            // The bar on which the indicator values are checked: 0 - new forming bar, 1 - first completed bar

bool StartTrading = false;               // At starting time not to trade.


enum BandState
  {
   BandM3,          
   BandM2,
   BandM1,
   BandM0,      
   BandP0,      
   BandP1,
   BandP2,
   BandP3,
  };
BandState LASMBand, LASLBand, LASSBand, BSPBand, BSPWmaBand;

enum Open_Mode
{ 
  ModeReversal,
  ModeCounter,
};

enum trend
{
   UpTrend,
   DownTrend, 
   NoTrend,       
};
trend    NLRSTrend,  NLRMTrend, NLRLTrend, LASMTrend,  LASLTrend,  LASSTrend,  WmaSTrend,  WmaMTrend,  WmaLTrend,  BSPTrend, 
         NLRSTrend1, NLRMTrend1, NLRLTrend1, LASMTrend1, LASLTrend1, LASSTrend1, WmaSTrend1, WmaMTrend1, WmaLTrend1, BSPTrend1 ; 

enum M_BuySellNo
{
   M_Buy,
   M_Sell,
   M_Nothing,
};
M_BuySellNo M_Result;

struct position_Sum
{
   int                totalNumPositions;
   int                currentNumPositions;
   Open_Mode          OpenMode;
   ENUM_POSITION_TYPE firstPositionType;
   ENUM_POSITION_TYPE lastPositionType;
   double totalSize;
};
position_Sum PositionSummary;


struct position_Infomation
{
   int    openSequence;
   bool   isOpenNow;
   ENUM_POSITION_TYPE positionType;
   ulong  positionTicket;
   int    openBar;
   double openVolume;
   double openPrice;
   double openWmaS;
   double openLASM;
};
position_Infomation PositionInfo[];


struct open_Ready
{
   bool   Able;
   bool   LASSReady;
   bool   LASMReady;
   bool   TrendReady;
};
open_Ready BuyOpenReady, SellOpenReady;

struct Counter_Open_Ready
{
   bool  LASSReady;
   bool  LASSChangedDown;
   bool  LASSChangedUp;
   bool  TrendChanged;
   ulong LASSBar1;
   ulong LASSBar2;
   bool  LASMReady;
   bool  TrendReady;
};
Counter_Open_Ready BuyCOReady, SellCOReady;

struct close_Ready
{
   bool      TrendReady;
     
};
close_Ready BuyCloseReady, SellCloseReady;


#include <BSPV4/Init.mqh>
#include <BSPV4/Deinit.mqh>
#include <BSPV4/Indicators.mqh>
#include <BSPV4/ReadyCheckV2.mqh>
#include <BSPV4/OpenCloseV2.mqh>
#include <BSPV4/Common.mqh>







//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

   Initialize();
        
   return(0);
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

   MyIndicatorRelease();
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
           
   if( isNewBar(_Symbol) ) 
     {


      if(!Indicators()) 
        {
         Alert("Indicator Allocation error!");
         return;
        }     
      
      if( PositionSummary.totalNumPositions >= 1)
        {
         CloseReadyCheck();
                     
         if(SignalCloseBuy())  
            MyBuyClose();               
         if(SignalCloseSell()) 
            MySellClose(); 
/*         
         M_Result = ManageTrend();
         
         switch(M_Result) 
          { 
            case M_Buy: 
             MyBuyOpen();
             break; 

            case M_Sell: 
             MySellOpen();
             break; 

            case M_Nothing: 
             break; 
          } 
*/
        }    


      if(StartTrading)
        {

         OpenReadyCheck();

         if(PositionSummary.totalNumPositions==0)  
           {
            if(SignalOpenBuy())          
               MyBuyOpen(ModeReversal);                    
//            if(SignalCounterOpenBuy())   
//               MyBuyOpen(ModeCounter);
            if(SignalOpenSell())         
               MySellOpen(ModeReversal);                    
//            if(SignalCounterOpenSell())  
//               MySellOpen(ModeCounter);              
           }     
        }          

     }
        
//   Virtual_SLTP();

}

