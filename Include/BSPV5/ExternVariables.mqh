//+------------------------------------------------------------------+
//|                                              ExternVariables.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

#define IND1 "BSP105V4\\BSP105NLR"
#define IND2 "BSP105V4\\BSP105LRAVGSTD"
#define IND3 "BSP105V4\\BSP105WMA"
#define IND4 "BSP105V4\\BSP105BSP"

#define TotalSession 10
#define TotalPyramid 10
#define MaxPosition 100

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/PositionInfo.mqh>

CTrade Trade;
CDealInfo Deal;
CSymbolInfo Sym;
CPositionInfo Pos;

//---------------------------------------------------------------------------------------
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

enum trend
{
   UpTrend,
   DownTrend, 
   NoTrend,       
};

struct open_Ready
{
   bool   LASMReady;
   bool   TrendReady;
};

enum position_Mode
{
   NoMode,
   MiddleReverse,
   LongReverse,
   LongReverseCon,
   LongReversePyrimid,
   LongCounter,
   LongCounterCon,
   LongCounterPyrimid,
   DoubleLongReverse,
   DLRCon,
   DLRCPyrimid,
   DLRCCon,
   DLRCCPyrimid,
   End,
   ReOpenReverse,
   ReOpenReverseCon,   
   ReOpenReversePyrimid,
   NoAction,
};


enum position_ID
{
   Buy_MR,
   Sell_MR,
   Buy_LR,
   Sell_LR,
   Buy_LRP,
   Sell_LRP,
   Buy_LC,
   Sell_LC,
   Buy_LCP,
   Sell_LCP,
   Buy_DLR,
   Sell_DLR,
   Buy_DLRC,
   Sell_DLRC,
   Buy_DLRCP,
   Sell_DLRCP,
   Buy_DLRCC,
   Sell_DLRCC,
   Buy_DLRCCP,
   Sell_DLRCCP,
   Buy_ROR,
   Sell_ROR,
   Buy_RORC,
   Sell_RORC,
   Buy_RORCP,
   Sell_RORCP,
//-------------------------
   No_Signal,
   AllPM,
};

struct position_IDMN
{
   int Buy_MR;
   int Sell_MR;
   int Buy_LR;
   int Sell_LR;
   int Buy_LRP;
   int Sell_LRP;
   int Buy_LC;
   int Sell_LC;
   int Buy_LCP;
   int Sell_LCP;
   int Buy_DLR;
   int Sell_DLR;
   int Buy_DLRC;
   int Sell_DLRC;
   int Buy_DLRCP;
   int Sell_DLRCP;
   int Buy_DLRCC;
   int Sell_DLRCC;
   int Buy_DLRCCP;
   int Sell_DLRCCP;
   int Buy_ROR;
   int Sell_ROR;
   int Buy_RORC;
   int Sell_RORC;
   int Buy_RORCP;
   int Sell_RORCP;
};

struct position_Infomation
{
   int    openSequence;
   bool   isOpenNow;
   ENUM_POSITION_TYPE positionType;
   position_ID positionID;
   int    pMagicNumber;
   int    openBar;
   double openVolume;
   double openPrice;
   double openWmaS;
   double openLASM;
};

struct position_Sum
{
   int                totalNumPositions;
   int                currentNumPositions;
   int                startingBar;
   ENUM_POSITION_TYPE firstPositionType;
   ENUM_POSITION_TYPE lastPositionType;
   double             totalSize;
   double             currentSize;
};

struct reOpen_Constants
{
   int         MRBar;
   int         LRBar;
   int         LRConBar;
   int         LCBar;
   int         LCConBar;   
   int         DLRBar;
   int         DLRConBar;
   int         DLRCConBar;
   int         EndBar;
   BandState   EndLASMBand; 
   int         RORBar;
   int         NoModeBar;
   int         ReOpenTime;
};

struct session_Man
{
   int   CurSession;
   bool  NoMoreSession;
   bool  CanGo;
   
};

enum pyramid_Type
{
   Cylinder,
   Cone,
};

struct pyramid_GloConst
{
   pyramid_Type PyramidType,
   double       PyramidThMulti,
   double       PyramidIncMulti,
   double       ConeDecMulti,
};

struct pyramid_Constant
{
   int Session,
   position_ID PositionID,
   int StackNum,
   double LastWmaM,
};


//--------------------------------------------------------------------------------
input group               "ReOpenConstants"
input int                 LRConBars=20;     //
input int                 DLRBars=15; //
input int                 ReOpenBars=4; //
input int                 ReOpenTimes=2; //

input group               "ETC Constants"
input BandState           BuyLRConLASLBand=BandP0;   //
input BandState           SellLRConLASLBand=BandM0;  //
input BandState           BuyLCLASLBand=BandM0;    //
input BandState           SellLCLASLBand=BandP0;  //
input BandState           BuyROLASMBand=BandP1;    //
input BandState           SellROLASMBand=BandM1;  //
input bool                DLRNoiseTF=true;  //
input double              NoiseUpMultiFactor=4.0;   //
input double              NoiseDownMultiFactor=4.0;   //

input group               "LRAVGSTDS"
input int                 LwmaPeriodS    = 5;          // WmaPeriodS
input int                 AvgPeriodS    = 7;          //AvgPeriodS
input int                 StdPeriodLS    = 5000;        // StdPeriodLS
input int                 StdPeriodSS    = 1;        // StdPeriodSS
input double              MultiFactorL1S  = 1.0;         // StdMultiFactorL1S
input double              MultiFactorL2S  = 2.0;         // StdMultiFactorL2S
input double              MultiFactorL3S  = 4.0;         // StdMultiFactorL3S
input double              MaxBSPMultS     = 20.0;        // MaxBSPmultfactorS

input group               "LRAVGSTDM"
input int                 LwmaPeriodM    = 10;          // WmaPeriodM
input int                 AvgPeriodM    =30;          //AvgPeriodM
input int                 StdPeriodLM    = 5000;        // StdPeriodLM
input int                 StdPeriodSM    = 1;        // StdPeriodSM
input double              MultiFactorL1M  = 1.0;         // StdMultiFactorL1M
input double              MultiFactorL2M  = 2.0;         // StdMultiFactorL2M
input double              MultiFactorL3M  = 3.0;         // StdMultiFactorL3M
input double              MaxBSPMultM     = 20.0;         // MaxBSPmultfactorM

input group               "LRAVGSTDL"
input int                 LwmaPeriodL    = 15;          // WmaPeriodL
input int                 AvgPeriodL    = 60;          //AvgPeriodL
input int                 StdPeriodLL    = 5000;        // StdPeriodLL
input int                 StdPeriodSL    = 1;        // StdPeriodSL
input double              MultiFactorL1L  = 1.0;         // StdMultiFactorL1L
input double              MultiFactorL2L  = 2.0;         // StdMultiFactorL2L
input double              MultiFactorL3L  = 3.0;         // StdMultiFactorL3L
input double              MaxBSPMultL     = 20.0;         // MaxBSPmultfactorL

input group               "NonLR"
input int                 NLRSPeriod          = 15;          // NLRSPeriod
input int                 NLRMPeriod          = 30;          // NLRMPeriod
input int                 NLRLPeriod          = 60;          // NLRMPeriod

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
input double              BSPCutOff         = 10.0;         // BSPStdMultiFactorL3

input group               "Trading Time parameter"
input    int              StartTime            = 2;            // Starting Time (Server Time)
input    int              EndTime              = 23;           // Ending Time (Server Time)
input    int              CloseHour            = 23;           //AllPosition Closing Time(Server Time)
input    int              CloseMin             = 30;           //AllPosition Closing Time(Server Time)

input group               "EA Parameter"
input int                 BaseMagicNumber      = 200000;       // Magic Number
input double              NoNcMultiFactor      = 1.5;          // NoNc  Multifactor
input double              Lots                 = 0.1;        /*Lots*/             // Lot; if 0, MaximumRisk value is used
input double              LotsMultiFactor      = 1.0;         /*LotsMultiFactor*/  // Lot Size MultiFactor
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
 

//--------------------------------------------------------------------------------              

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
        

double NLRSValue, NLRMValue, NLRLValue, LASMValue, LASLValue, LASSValue, WmaSValue, WmaMValue, WmaLValue, BSPValue, BSPWmaValue, CurPrice,
       lot,slv=0,msl,tpv=0, mtp,
       NoiseDownLimit[], NoiseUpLimit[];

bool StartTrading = false, CloseAllTrading=false, _VirtualSLTP ;

int   LASSTrendN, LASMTrendN, LASLTrendN, TrendSN, TrendMN, TrendLN,
      CurBar;                

const int MN_IncNumber=100, SessionIncNumber=5000, RORBars=10, Shift= 1;

BandState LASMBand, LASLBand, LASSBand, BSPBand, BSPWmaBand;

trend    NLRSTrend,  NLRMTrend, NLRLTrend, LASMTrend,  LASLTrend,  LASSTrend,  WmaSTrend,  WmaMTrend,  WmaLTrend,  BSPTrend, 
         NLRSTrend1, NLRMTrend1, NLRLTrend1, LASMTrend1, LASLTrend1, LASSTrend1, WmaSTrend1, WmaMTrend1, WmaLTrend1, BSPTrend1,
         TrendS, TrendM, TrendL,
         TrendS1, TrendM1, TrendL1, 
         TrendS2, TrendM2, TrendL2 ;          

open_Ready        BuyOpenReady, SellOpenReady;

position_Infomation PositionInfo[TotalSession][MaxPosition];

position_Sum      PositionSummary[];
position_Mode     BeforePM[], CurPM[];
reOpen_Constants  ReOC[];
session_Man       SessionMan;
position_IDMN     BasePositionMN[], CurrPositionMN[];
pyramid_GloConst  PyramidGloConst;
pyramid_Constant  PyramidConst[TotalPyramid];
//----------------------------------------------------------------------------------------------
