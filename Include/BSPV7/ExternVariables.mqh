//+------------------------------------------------------------------+
//|                                                     BSP105V7.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#define IND1 "BSP105V7\\NLR"
#define IND2 "BSP105V7\\LRAVGSTD"
#define IND3 "BSP105V7\\BSPWMA"
#define IND4 "BSP105V7\\BSPBSP2"
#define IND5 "BSP105V7\\BSPNLR"

#define TotalSession 3
#define MaxPosition 200

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

/*
struct open_Ready
{
   bool   LASMReady;
   int    LASMBar;
   bool   TrendReady;
};
*/

struct open_Ready
{
   bool   BuyLASMReady;
   int    BuyLASMBar;
   bool   BuyTrendReady;

   bool   SellLASMReady;
   int    SellLASMBar;
   bool   SellTrendReady;
};

enum position_Mode
{
   MiddleReverse,
   LongReverse,
   LongReverseCon,
   LongReverseEnd,
   LongCounter,
   LongCounterCon,
   LongCounterEnd,
   DoubleLongReverse,
   DLREnd,
   DLRCon,
   DLRCCon,
   End,
   NoAction,
   NoMode,
};

enum position_ID
{
   Buy_MR,
   Sell_MR,
   Buy_LR,
   Sell_LR,
   Buy_LC,
   Sell_LC,
   Buy_DLR,
   Sell_DLR,
   Buy_DLRCC,
   Sell_DLRCC,
   No_Signal,
   AllID,
   NoID,  
};

struct position_IDMN
{
   int Buy_MR;
   int Sell_MR;
   int Buy_LR;
   int Sell_LR;
   int Buy_LC;
   int Sell_LC;
   int Buy_DLR;
   int Sell_DLR;
   int Buy_DLRCC;
   int Sell_DLRCC;
};

struct reOpen_Constants
{
   int         MaxBar;
   double      MaxBSP;
   int         MinBar;
   double      MinBSP;
   int         MaxMinBar;
   int         MRBar;
   double      MRWmaS;
   int         LRBar;
   double      LRWmaS;
   int         LREndBar;
   double      LREndWmaS; 
   int         LRConBar;
   double      LRConWmaS;
   int         LCBar;
   double      LCWmaS;
   int         LCEndBar;
   double      LCEndWmaS;
   int         LCConBar;  
   double      LCConWmaS;
   int         DLRBar;
   double      DLRWmaS;
   int         DLREndBar;
   double      DLREndWmaS;
   int         DLRConBar;
   double      DLRConWmaS;
   int         DLRCConBar;
   double      DLRCConWmaS;
   int         EndBar;
   double      EndWmaS;
};

struct session_Man
{
   int   LastSession;
   int   CurSession;
   bool  CanGoBand;
   bool  CanGoTrend;
   
};

struct pyramid_GloConst
{
   double       pyramidThMulti;
   double       pyramidIncMulti;
   double       pydStartSizeMulti;
   double       coneDecMulti;
};

struct position_Infomation
{
   int    openSequence;
   bool   isOpenNow;
   trend  positionTrend;
   position_ID positionID;
   int    pMagicNumber;
   int    openBar;
   double openVolume;
   double openPrice;
   double openWmaS;
};

struct position_Sum
{
   int                totalNumPositions;
   int                currentNumPositions;
   int                startingBar;
   trend              firstPositionTrend;
   trend              lastPositionTrend;
   double             totalSize;
   double             currentSize;
   double             evenSize;
   double             evenProfit;
   bool               pyramidStarted;
   position_ID        pyramidPID;
   trend              pyramidTrend;
   int                lastStackNum;
   double             lastWmaS;
};

enum bSP_Value
{
   STD,
   Wma,
}; 

enum EMyCapitalCalc 
{
   FREEMARGIN = 2,
   BALANCE = 4,
   EQUITY = 8,
};

//--------------------------------------------------------------------------------
input group               "EA Parameter"
input int                 BaseMagicNumber      = 200000;       // Magic Number

input group               "Lot Size Constance"
input EMyCapitalCalc      iRisk_AvailableCapital = BALANCE;  // Capital calculation mechanism
input double              iRisk_FractionOfCapital = 0.001;    // Risk fraction of the capital ,ex: 0.01 = 1%
input double              MinLotSizeMulti         = 0.1;     //When pyramiding least size multiplier
input string              iCommon_CurrencyPairAppendix = "";              // Currency Pair Appendix

input group               "Stop Loss"
input bool                SLStart             = true;
input double              SLBSPSTDMulti       = 3.0;
input bool                VirtualSL           = true;       /*VirtualSLTP*/     // Stop Loss, Take Profit setting.
input double              SLPercent             = 0.02;           /*StopLoss*/            // Stop Loss in percent

input group               "Pyramid Constants"
input double              t_PyramidThMulti=3.;
input double              t_PyramidIncMulti=1.;
input double              t_PydStartSizeMulti=1.;
input double              t_ConeDecMulti=0.7;
input bSP_Value           ThBSP=STD;
input bSP_Value           IncBSP=STD;

input group               "Main Program Constants"
input int                 FindMinMaxShift = 40;
input int                 EndBars=60;
input int                 PMBars=20; 
input int                 ReadyBars=20;
input double              DLRCConMulti=2.0;
input BandState           BuyLRELASLBand=BandP0;
input BandState           SellLRELASLBand=BandM0;
input BandState           BuyLCLASLBand=BandM0;
input BandState           SellLCLASLBand=BandP0;
input BandState           BuyStiffEndBand=BandP2;
input BandState           SellStiffEndBand=BandM2;

input group               "LRAVGSTDM"
input int                 LwmaPeriodM    = 25;          // WmaPeriodM
input int                 AvgPeriodM    =30;          //AvgPeriodM
input int                 StdPeriodLM    = 3000;        // StdPeriodLM
input int                 StdPeriodSM    = 1;        // StdPeriodSM
input double              MultiFactorL1M  = 1.0;         // StdMultiFactorL1M
input double              MultiFactorL2M  = 2.0;         // StdMultiFactorL2M
input double              MultiFactorL3M  = 3.0;         // StdMultiFactorL3M
input double              MaxBSPMultM     = 20.0;         // MaxBSPmultfactorM

input group               "LRAVGSTDL"
input int                 LwmaPeriodL    = 25;          // WmaPeriodL
input int                 AvgPeriodL    = 60;          //AvgPeriodL
input int                 StdPeriodLL    = 3000;        // StdPeriodLL
input int                 StdPeriodSL    = 1;        // StdPeriodSL
input double              MultiFactorL1L  = 1.0;         // StdMultiFactorL1L
input double              MultiFactorL2L  = 2.0;         // StdMultiFactorL2L
input double              MultiFactorL3L  = 3.0;         // StdMultiFactorL3L
input double              MaxBSPMultL     = 20.0;         // MaxBSPmultfactorL

input group               "NonLR"
input int                 NLRLPeriod          = 60;          // NLRMPeriod

input group               "Wma"
input int                 WmaPeriodS    = 1;          // BspWmaPeriod
input int                 WmaPeriodL    = 25;          // BspWmaPeriod

input group               "Bsp"
input int                 WmaBSP           = 10;          // BSPWmaPeriod
input int                 BSPStdPeriodL    = 5000;        // BSPStdPeriodL
input double              BSPMultiFactorL1  = 1.0;         // BSPStdMultiFactorL1
input double              BSPMultiFactorL2  = 2.0;         // BSPStdMultiFactorL2
input double              BSPMultiFactorL3  = 3.0;         // BSPStdMultiFactorL3
input double              BSPCutOff         = 20.0;         // BSPStdMultiFactorL3

input group               "BspNlrS"
input int                 BSPNlrPeriodS    =  10;         //BspNrlPeriod
input int                 BSPWmaPeriodS    =  10;         //BspWmaPeriod

input group               "BspNlrL"
input int                 BSPNlrPeriodL    =  20;         //BspNrlPeriod
input int                 BSPWmaPeriodL    =  20;         //BspWmaPeriod


input group               "Trading Time parameter"
input    int              StartTime            = 2;            // Starting Time (Server Time)
input    int              EndTime              = 23;           // Ending Time (Server Time)
input    int              CloseHour            = 23;           //AllPosition Closing Time(Server Time)
input    int              CloseMin             = 30;           //AllPosition Closing Time(Server Time)
//--------------------------------------------------------------------------------              

int NLRLHandleL      = INVALID_HANDLE,
    LASHandleM       = INVALID_HANDLE,
    LASHandleL       = INVALID_HANDLE,
    WmaHandleS       = INVALID_HANDLE,
    WmaHandleL       = INVALID_HANDLE, 
    BSPNlrWmaHandleS = INVALID_HANDLE,
    BSPNlrWmaHandleL = INVALID_HANDLE,
    BSPHandle        = INVALID_HANDLE;

double NLRLBuffer[], NLRLColorBuffer[],

       LASMBuffer[], LASMColorBuffer[],
       LASMP3Band[], LASMP2Band[], LASMP1Band[], LASMM1Band[],  LASMM2Band[],  LASMM3Band[], 

       LASLBuffer[], LASLColorBuffer[],
       LASLP3Band[], LASLP2Band[], LASLP1Band[], LASLM1Band[],  LASLM2Band[],  LASLM3Band[], 

       WmaSBuffer[], WmaSColorBuffer[], 
       WmaLBuffer[], WmaLColorBuffer[], 
       
       BSPNlrWmaBufferS[], BSPNlrWmaColorBufferS[],
       BSPNlrWmaBufferL[], BSPNlrWmaColorBufferL[],
       
       BSPBuffer[], BSPWmaBuffer[],
       BSP1Band[];
        

double NLRLValue, LASMValue, LASLValue, WmaSValue, WmaLValue, BSPWmaValue, BSPNlrWmaValueS, BSPNlrWmaValueL, CurPrice,
       lot,slv=0,msl,tpv=0, mtp,
       BSPSTD, ThBSPValue, IncBSPValue, SLBSPValue, BSPValue, DLRCConThValue;

bool StartTrading=false, isClosingTime=false, _VirtualSLTP, isPyramidStarted=false, isIndicationError=false, 
     isStopLossUpTrend=false, isStopLossDownTrend=false;

int   LASMTrendN, LASLTrendN, TrendSN, TrendMN, TrendLN,
      CurBar, FindMinMaxSize=200 ;                

const int MN_IncNumber=200, SessionIncNumber=5000, Shift= 1;

BandState LASMBand, LASLBand, BSPWmaBand;

trend    NLRLTrend, LASMTrend,  LASLTrend, WmaSTrend, WmaLTrend, BSPNlrWmaTrendS, BSPNlrWmaTrendL,
         NLRLTrend1, LASMTrend1, LASLTrend1, WmaSTrend1, WmaLTrend1, BSPNlrWmaTrendS1, BSPNlrWmaTrendL1,
         TrendL, TrendL1, TrendL2, TrendLL ;          

//open_Ready        BuyOpenReady, SellOpenReady;

open_Ready        OpenReady[];
position_Infomation PositionInfo[TotalSession][MaxPosition];

position_Sum      PositionSummary[];
position_Mode     BeforePM[], CurPM[];
reOpen_Constants  ReOC[];
session_Man       SessionMan;
position_IDMN     BasePositionMN[], CurrPositionMN[];
pyramid_GloConst  PyramidGloConst;
//----------------------------------------------------------------------------------------------
