//+------------------------------------------------------------------+
//|                                                     BSP105V5.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#define IND1 "BSP105V6\\NLR"
#define IND2 "BSP105V6\\LRAVGSTD"
#define IND3 "BSP105V6\\BSPWMA"
#define IND4 "BSP105V6\\BSPBSP"

#define TotalSession 5
#define TotalPyramid 15
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
   LongCounter,
   LongCounterCon,
   DoubleLongReverse,
   DLRCon,
   DLRCCon,
   End,
   ReOpenReverse,
   ReOpenReverseCon,   
   NoAction,
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
   Buy_ROR,
   Sell_ROR,
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
   int Buy_ROR;
   int Sell_ROR;
};

struct reOpen_Constants
{
   int         MRBar;
   double      MRWma;
   int         LRBar;
   double      LRWma;
   int         LRConBar;
   double      LRConWma;
   int         LCBar;
   double      LCWma;
   int         LCConBar;  
   double      LCConWma;
   int         DLRBar;
   double      DLRWma;
   int         DLRConBar;
   double      DLRConWma;
   int         DLRCConBar;
   double      DLRCConWma;
   int         EndBar;
   double      EndWma;
   int         RORBar;
   double      RORWma;
   int         RORCBar;
   double      RORCWma;
   int         NoModeBar;
   double      NoModeWma;
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
   None,
   Original,
   Cone,
};

struct pyramid_GloConst
{
   pyramid_Type pyramidType;
   double       pyramidThMulti;
   double       pyramidIncMulti;
   double       pydStartSizeMulti;
   double       coneDecMulti;
};

struct pyramid_Instance
{
   int session;
   position_ID positionID;
   trend pyramidTrend;
   int   orignalMN;
   int lastStackNum;
   double lastWmaM;
};

struct position_Infomation
{
   int    openSequence;
   bool   isOpenNow;
   pyramid_Type pyramidType;
   bool pyramidStarted;
   ENUM_POSITION_TYPE positionType;
   position_ID positionID;
   int    pMagicNumber;
   int    openBar;
   double openVolume;
   double openPrice;
   double openWmaM;
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
   bool               pyramidStarted;
   trend              pyramidTrend;
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
input group               "Pyramid Constants"
input pyramid_Type        t_PyramidType=Cone;
input double              t_PyramidThMulti=4.;
input double              t_PyramidIncMulti=1.;
input double              t_PydStartSizeMulti=1.;
input double              t_ConeDecMulti=0.9;
input bSP_Value           ThBSP=STD;
input bSP_Value           IncBSP=STD;

input group               "ReOpenConstants"
input int                 LRConBars=3;     //
input int                 LCConBars=3;
input int                 DLRBars=15; //
input int                 ReOpenBars=5; //
input int                 ReOpenTimes=1; //+1Times Reopen

input group               "ETC Constants"
input BandState           BuyLCLASLBand=BandM0;
input BandState           SellLCLASLBand=BandP0;
input BandState           BuyStiffEndBand=BandP2;
input BandState           SellStiffEndBand=BandM2;

input group               "LRAVGSTDS"
input int                 LwmaPeriodS    = 5;          // WmaPeriodS
input int                 AvgPeriodS    = 7;          //AvgPeriodS
input int                 StdPeriodLS    = 3500;        // StdPeriodLS
input int                 StdPeriodSS    = 1;        // StdPeriodSS
input double              MultiFactorL1S  = 1.0;         // StdMultiFactorL1S
input double              MultiFactorL2S  = 2.0;         // StdMultiFactorL2S
input double              MultiFactorL3S  = 4.0;         // StdMultiFactorL3S
input double              MaxBSPMultS     = 20.0;        // MaxBSPmultfactorS

input group               "LRAVGSTDM"
input int                 LwmaPeriodM    = 10;          // WmaPeriodM
input int                 AvgPeriodM    =30;          //AvgPeriodM
input int                 StdPeriodLM    = 3500;        // StdPeriodLM
input int                 StdPeriodSM    = 1;        // StdPeriodSM
input double              MultiFactorL1M  = 1.0;         // StdMultiFactorL1M
input double              MultiFactorL2M  = 2.0;         // StdMultiFactorL2M
input double              MultiFactorL3M  = 3.0;         // StdMultiFactorL3M
input double              MaxBSPMultM     = 20.0;         // MaxBSPmultfactorM

input group               "LRAVGSTDL"
input int                 LwmaPeriodL    = 15;          // WmaPeriodL
input int                 AvgPeriodL    = 60;          //AvgPeriodL
input int                 StdPeriodLL    = 3500;        // StdPeriodLL
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
input int                 WmaPeriodL    = 20;          // BspWmaPeriod

input group               "Bsp"
input int                 WmaBSP           = 10;          // BSPWmaPeriod
input int                 BSPStdPeriodL    = 5000;        // BSPStdPeriodL
input double              BSPMultiFactorL1  = 1.0;         // BSPStdMultiFactorL1
input double              BSPMultiFactorL2  = 2.0;         // BSPStdMultiFactorL2
input double              BSPMultiFactorL3  = 3.0;         // BSPStdMultiFactorL3
input double              BSPCutOff         = 20.0;         // BSPStdMultiFactorL3

input group               "Trading Time parameter"
input    int              StartTime            = 2;            // Starting Time (Server Time)
input    int              EndTime              = 23;           // Ending Time (Server Time)
input    int              CloseHour            = 23;           //AllPosition Closing Time(Server Time)
input    int              CloseMin             = 30;           //AllPosition Closing Time(Server Time)

input group               "EA Parameter"
input int                 BaseMagicNumber      = 200000;       // Magic Number

input group               "Lot Size Calculation"
input EMyCapitalCalc      iRisk_AvailableCapital = BALANCE;  // Capital calculation mechanism
input double              iRisk_FractionOfCapital = 0.01;    // Risk fraction of the capital ,ex: 0.01 = 1%
input string              iCommon_CurrencyPairAppendix = "";              // Currency Pair Appendix


input int                 StopLoss             = 0;           /*StopLoss*/            // Stop Loss in points
input int                 TakeProfit           = 0;           /*TakeProfit*/       // Take Profit in points
input bool                VirtualSLTP          = false;       /*VirtualSLTP*/     // Stop Loss, Take Profit setting.
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
       BSPSTD, ThBSPValue, IncBSPValue;

bool StartTrading = false, CloseAllTrading=false, _VirtualSLTP ;

int   LASSTrendN, LASMTrendN, LASLTrendN, TrendSN, TrendMN, TrendLN,
      CurBar;                

const int MN_IncNumber=200, SessionIncNumber=5000, Shift= 1;

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
pyramid_Instance  PyramidInstance[TotalPyramid];
//----------------------------------------------------------------------------------------------


#include <BSPV6/InitV6.mqh>
#include <BSPV6/DeinitV6.mqh>
#include <BSPV6/IndicatorV6.mqh>
#include <BSPV6/ReadyCheckV6.mqh>
#include <BSPV6/OpenCloseV6.mqh>
#include <BSPV6/CommonV6.mqh>
#include <BSPV6/MagicNumberV6.mqh>
#include <BSPV6/SessionManV6.mqh>
#include <BSPV6/PyramidV6.mqh>
#include <BSPV6/MoneyManageV6.mqh>


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!Initialize())
     {
      Alert("Initialization Error Occur");
      TerminalClose(false);
     }
     
        
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
      
      if(CloseAllTrading)
        {
         Alert("Heck");
         for(int m_Session=0;m_Session<TotalSession;m_Session++)
           {
            if(PositionSummary[m_Session].currentNumPositions!=0) ClosePositionBySession(m_Session);
           }
        } 
     }

}
