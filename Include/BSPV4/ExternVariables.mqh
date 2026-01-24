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
   bool   Able;
   bool   LASSReady;
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
   LongCounterPyrimid,
   LongCounterCon,
   DoubleLongReverse,
   DoubleLongReversePyrimid,
   End,
   ReOpenReverse,
   ReOpenReversePyrimid,
};

enum position_IDE
{
   Buy_MR    =1100,
   Sell_MR   =1200,
   Buy_LR    =1300,
   Sell_LR   =1400,
   Buy_LRP   =1500,
   Sell_LRP  =1600,
   Buy_LC    =1700,
   Sell_LC   =1800,
   Buy_LCP   =1900,
   Sell_LCP  =2000,
   Buy_DLR   =2100,
   Sell_DLR  =2200,
   Buy_DLRP  =2300,
   Sell_DLRP =2400,
   Buy_ROR   =2500,
   Sell_ROR  =2600,
   Buy_RORP  =2700,
   Sell_RORP =2800, 
   No_Signal,
   AllPM,
};

struct position_Infomation
{
   int    openSequence;
   bool   isOpenNow;
   ENUM_POSITION_TYPE positionType;
   position_IDE positionIDE;
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
   int                MRBar;
   int                LRBar;
   int                LCBar;
   int                LRConBar;
   int                LRConBars;  
   int                DLRBar;
   int                DLRBars;

   BandState          BuyLRConLASSBand;
   BandState          BuyLRConLASLBand;
   BandState          SellLRConLASSBand;
   BandState          SellLRConLASLBand; 

   BandState          BuyLCLASSBand;
   BandState          BuyLCLASLBand;
   BandState          SellLCLASSBand;
   BandState          SellLCLASLBand;

   BandState          BuyLCConLASSBand;
   BandState          BuyLCConLASLBand;
   BandState          SellLCConLASSBand;
   BandState          SellLCConLASLBand;
   
   BandState          BuyDLRLASABand;
   BandState          BuyDLRLASLBand;
   BandState          SellDLRLASSBand;
   BandState          SellDLRLASLBand; 

   int                EndBar;
   int                RORBar;
   int                RORBars;  
   int                NoModeBar;
   bool               DLRNoiseTF;
   double             NoiseUpMultiFactor;
   double             NoiseDownMultiFactor;
};

reOpen_Constants ReOC;

BandState LASMBand, LASLBand, LASSBand, BSPBand, BSPWmaBand;

position_Mode BeforePM=NoMode, CurPM=NoMode;

trend    NLRSTrend,  NLRMTrend, NLRLTrend, LASMTrend,  LASLTrend,  LASSTrend,  WmaSTrend,  WmaMTrend,  WmaLTrend,  BSPTrend, 
         NLRSTrend1, NLRMTrend1, NLRLTrend1, LASMTrend1, LASLTrend1, LASSTrend1, WmaSTrend1, WmaMTrend1, WmaLTrend1, BSPTrend1,
         TrendS, TrendM, TrendL,
         TrendS1, TrendM1, TrendL1, 
         TrendS2, TrendM2, TrendL2 ; 
         
position_Sum PositionSummary;

position_Infomation PositionInfo[];

open_Ready BuyOpenReady, SellOpenReady;

//--------------------------------------------------------------------------------
input group               "ReOpenConstants"

input int                m_LRConBars=20;     //
input int                m_DLRBars=15; //

//input BandState          m_BuyLRConLASSBand;
input BandState          m_BuyLRConLASLBand=BandP0;   //
//input BandState          m_SellLRConLASSBand;
input BandState          m_SellLRConLASLBand=BandM0;  //

//input BandState          m_BuyLCLASSBand;
input BandState          m_BuyLCLASLBand=BandM0;    //
//input BandState          m_SellLCLASSBand;
input BandState          m_SellLCLASLBand=BandP0;  //

//input BandState          m_BuyLCConLASSBand;
//input BandState          m_BuyLCConLASLBand;
//input BandState          m_SellLCConLASSBand;
//input BandState          m_SellLCConLASLBand;
   
//input BandState          m_BuyDLRLASABand;
//input BandState          m_BuyDLRLASLBand;
//input BandState          m_SellDLRLASSBand;
//input BandState          m_SellDLRLASLBand; 

//input int                m_RORBars;  
input bool               m_DLRNoiseTF=true;  //
input double             m_NoiseUpMultiFactor=2.0;   //
input double             m_NoiseDownMultiFactor=1.0;   //

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
input int                 NLRLPeriod          = 70;          // NLRMPeriod

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
input    int              BaseMagicNumber      = 10000;       // Magic Number
input double              NoNcMultiFactor      = 1.5;          // NoNc  Multifactor
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
       

double NLRSValue, NLRMValue, NLRLValue, LASMValue, LASLValue, LASSValue, WmaSValue, WmaMValue, WmaLValue, BSPValue, BSPWmaValue, CurPrice;

double lot,slv=0,msl,tpv=0,mtp, NoiseUpLimit, NoiseDownLimit;

bool _VirtualSLTP;

int Shift= 1, CurBar;             /*Shift*/            // The bar on which the indicator values are checked: 0 - new forming bar, 1 - first completed bar

int   LASSTrendN, LASMTrendN, LASLTrendN, TrendSN, TrendMN, TrendLN ;                 

bool StartTrading = false, CloseAllTrading=false;               // At starting time not to trade.

int   MagicNumber, 
      BaseMN_Buy_MR, BaseMN_Sell_MR, BaseMN_Buy_LR, BaseMN_Sell_LR, BaseMN_Buy_LRP, BaseMN_Sell_LRP, 
      BaseMN_Buy_LC, BaseMN_Sell_LC, BaseMN_Buy_LCP, BaseMN_Sell_LCP, BaseMN_Buy_DLR, BaseMN_Sell_DLR, 
      BaseMN_Buy_DLRP, BaseMN_Sell_DLRP, BaseMN_Buy_ROR, BaseMN_Sell_ROR, BaseMN_Buy_RORP, BaseMN_Sell_RORP,
      CurrMN_Buy_MR, CurrMN_Sell_MR, CurrMN_Buy_LR, CurrMN_Sell_LR, CurrMN_Buy_LRP, CurrMN_Sell_LRP, 
      CurrMN_Buy_LC, CurrMN_Sell_LC, CurrMN_Buy_LCP, CurrMN_Sell_LCP, CurrMN_Buy_DLR, CurrMN_Sell_DLR, 
      CurrMN_Buy_DLRP, CurrMN_Sell_DLRP, CurrMN_Buy_ROR, CurrMN_Sell_ROR, CurrMN_Buy_RORP, CurrMN_Sell_RORP ;


//----------------------------------------------------------------------------------------------
