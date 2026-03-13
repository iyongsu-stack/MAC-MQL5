//+------------------------------------------------------------------+
//| CFeatureEngine.mqh — Real-time feature calculation engine        |
//| Phase 2-1 | AIEngine Module  (★ Most complex)                   |
//|                                                                  |
//| Manages 22 iCustom indicator handles, ~30 CRollingStats          |
//| instances, and produces float[] feature vectors aligned with     |
//| FeatureSchema.mqh for Entry (80) and Addon (77) models.          |
//|                                                                  |
//| Architecture:                                                    |
//|   OnInit → CreateHandles() → PreloadHistory()                    |
//|   OnNewBar → UpdateRawValues() → ComputeDerived()                |
//|             → AssembleFeatures()                                 |
//+------------------------------------------------------------------+
#ifndef __CFEATUREENGINE_MQH__
#define __CFEATUREENGINE_MQH__

#include <AIEngine/CRollingStats.mqh>
#include <AIEngine/CMacroLoader.mqh>
#include <AIEngine/FeatureSchema.mqh>

//--- Maximum raw indicator values tracked
#define FE_MAX_RAW       60
#define FE_MAX_ROLLING   40

//+------------------------------------------------------------------+
//| Indicator handle IDs (index into m_handles[])                    |
//+------------------------------------------------------------------+
enum ENUM_IND_HANDLE
{
   IH_ADXS_14 = 0,      // ADXSmooth period=14
   IH_ADXS_80,           // ADXSmooth period=80
   IH_ADXMTF_M5,         // ADXSmooth MTF on M5
   IH_ADXMTF_H4,         // ADXSmooth MTF on H4
   IH_ATR14,              // iATR(14)
   IH_BOP,                // BOPAvgStd
   IH_BSP_10_3,           // BSPWmaSmooth(10,3)
   IH_BSP_30_5,           // BSPWmaSmooth(30,5)
   IH_BWMTF_M5,           // BWMFI MTF on M5
   IH_BWMTF_H4,           // BWMFI MTF on H4
   IH_CE,                 // ChandelierExit
   IH_CHV_10_10,          // Chaikin Volatility(10,10)
   IH_CHV_30_30,          // Chaikin Volatility(30,30)
   IH_CHOP_14_14,         // ChoppingIndex(14,14)
   IH_CHOP_120_40,        // ChoppingIndex(120,40)
   IH_LRAVG_60,           // LRAVGSTD avg=60
   IH_LRAVG_180,          // LRAVGSTD avg=180
   IH_LRAVG_240,          // LRAVGSTD avg=240
   IH_QQE_5_14,           // QQE SF=5, RSI=14
   IH_QQE_12_32,          // QQE SF=12, RSI=32
   IH_TDI_13,             // TDI RSI=13, Smooth=2, Sig=7
   IH_TDI_14,             // TDI RSI=14, Smooth=90, Sig=35
   IH_COUNT               // Total handle count = 22
};

//+------------------------------------------------------------------+
//| Raw value slot names — for CRollingStats mapping                 |
//+------------------------------------------------------------------+
enum ENUM_RAW_SLOT
{
   RS_ADXS14_DIPLUS = 0, RS_ADXS14_DIMINUS, RS_ADXS14_ADX,
   RS_ADXS80_DIPLUS, RS_ADXS80_DIMINUS, RS_ADXS80_ADX,
   RS_ADXMTF_M5_DIPLUS, RS_ADXMTF_M5_ADX,
   RS_ADXMTF_H4_DIPLUS, RS_ADXMTF_H4_ADX,
   RS_ATR14,
   RS_BOP_SCALE, RS_BOP_DIFF,
   RS_BSP_10_3, RS_BSP_30_5,
   RS_BWMTF_M5, RS_BWMTF_H4,
   RS_CE_DIST1, RS_CE_DIST2, RS_CE_SL1, RS_CE_SL2,
   RS_CHV_10_STDDEV, RS_CHV_10_CHV, RS_CHV_30_STDDEV, RS_CHV_30_CHV,
   RS_CHOP_14_SCALE, RS_CHOP_14_CSI, RS_CHOP_120_SCALE, RS_CHOP_120_CSI,
   RS_LRAVG60_STDS, RS_LRAVG60_BSPSCALE, RS_LRAVG180_STDS, RS_LRAVG180_BSPSCALE,
   RS_LRAVG240_STDS,
   RS_TICKVOL,
   RS_CLOSE,   // For regime calculations
   RS_COUNT
};

//+------------------------------------------------------------------+
//| CFeatureEngine class                                             |
//+------------------------------------------------------------------+
class CFeatureEngine
{
private:
   //--- Indicator handles
   int            m_handles[IH_COUNT];
   
   //--- Raw indicator values (current bar)
   double         m_raw[RS_COUNT];
   
   //--- CRollingStats instances for derived features
   CRollingStats  m_rs[RS_COUNT];   // One per raw slot, used for z/slope/pct
   CRollingStats  m_rsTick60;       // TickVolume MA60
   CRollingStats  m_rsTick240;      // TickVolume MA240
   CRollingStats  m_rsTick1440;     // TickVolume MA1440
   
   //--- MA accumulators for TickVolume ratio
   double         m_tickMA60Sum;
   double         m_tickMA240Sum;
   double         m_tickMA1440Sum;
   int            m_barCount;
   double         m_tickHistory[];   // Ring buffer for tick volume
   
   //--- Regime calculations
   double         m_weeklyCloses[];  // Last 4 weeks
   int            m_weeklyIdx;
   
   //--- Macro loader reference
   CMacroLoader  *m_macroLoader;
   
   //--- Warmup tracking
   int            m_warmupBars;
   bool           m_isReady;
   
   //--- Previous bar close for momentum
   double         m_close10BarsAgo;
   double         m_closeHistory[];  // Ring buffer for price mom
   int            m_closeHistIdx;
   
   //--- Internal helpers
   bool           CreateHandles();
   void           ReadRawValues();
   double         ReadBuffer(int handleIdx, int bufferIdx, int shift = 0);
   double         SafeDiv(double num, double den);
   bool           PreloadHistory();  // Fast-forward warmup on startup
   
public:
                  CFeatureEngine();
                 ~CFeatureEngine();
   
   //--- Initialization
   bool           Init(CMacroLoader *macroLoader);
   
   //--- Update (call every new M1 bar)
   void           Update();
   
   //--- Get feature vectors
   void           GetEntryFeatures(float &out[]);
   void           GetAddonFeatures(float &out[],
                                   int addonCount,
                                   double unrealizedATR,
                                   int barsSinceEntry,
                                   double atrExpansion,
                                   double bspScaleDelta,
                                   double trendAccel);
   
   //--- Status
   bool           IsReady() const       { return m_isReady; }
   int            GetWarmupBars() const  { return m_warmupBars; }
   int            GetWarmupPct() const   { return MathMin(100, m_warmupBars * 100 / 240); }
   
   //--- Accessors for other modules
   double         GetATR14() const      { return m_raw[RS_ATR14]; }
   double         GetCE2Value() const;  // Returns CE2 line (SL2 = ATR*4.5 trailing)
   double         GetRaw(ENUM_RAW_SLOT slot) const { return m_raw[slot]; }
   
   //--- Addon dynamic feature accessors (Issue #2)
   double         GetBSPScale() const       { return m_raw[RS_LRAVG60_BSPSCALE]; }
   double         GetBSPScaleSlope5() const { return m_rs[RS_LRAVG60_BSPSCALE].GetSlope(5); }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CFeatureEngine::CFeatureEngine()
   : m_macroLoader(NULL), m_warmupBars(0), m_isReady(false),
     m_barCount(0), m_close10BarsAgo(0), m_closeHistIdx(0),
     m_tickMA60Sum(0), m_tickMA240Sum(0), m_tickMA1440Sum(0),
     m_weeklyIdx(0)
{
   ArrayInitialize(m_raw, 0);
   for(int i = 0; i < IH_COUNT; i++)
      m_handles[i] = INVALID_HANDLE;
   
   ArrayResize(m_closeHistory, 1440);
   ArrayInitialize(m_closeHistory, 0);
   ArrayResize(m_tickHistory, 1440);
   ArrayInitialize(m_tickHistory, 0);
   ArrayResize(m_weeklyCloses, 4);
   ArrayInitialize(m_weeklyCloses, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CFeatureEngine::~CFeatureEngine()
{
   for(int i = 0; i < IH_COUNT; i++)
   {
      if(m_handles[i] != INVALID_HANDLE)
         IndicatorRelease(m_handles[i]);
   }
}

//+------------------------------------------------------------------+
//| Initialize feature engine                                        |
//+------------------------------------------------------------------+
bool CFeatureEngine::Init(CMacroLoader *macroLoader)
{
   m_macroLoader = macroLoader;
   
   if(!CreateHandles())
   {
      Print("[CFeatureEngine] CRITICAL: Handle creation failed!");
      return false;
   }
   
   // Initialize CRollingStats with appropriate windows
   // Z-score/slope/pct calculations need at least 240 bars
   for(int i = 0; i < RS_COUNT; i++)
      m_rs[i].Init(240);
   
   // Special windows for tick volume
   m_rsTick60.Init(60);
   m_rsTick240.Init(240);
   m_rsTick1440.Init(1440);
   
   Print("[CFeatureEngine] Init complete: ", IH_COUNT, " handles, ",
         RS_COUNT, " raw slots, CRollingStats ready");
   
   // Fast-forward warmup: preload 1440 bars of history
   if(!PreloadHistory())
      Print("[CFeatureEngine] PreloadHistory failed → fallback to incremental warm-up");
   
   return true;
}

//+------------------------------------------------------------------+
//| Create all iCustom/iATR handles                                  |
//| Returns false if any handle creation fails                       |
//+------------------------------------------------------------------+
bool CFeatureEngine::CreateHandles()
{
   bool ok = true;
   string sym = _Symbol;
   
   // ADXS (period=14): inputs: period, alpha1, alpha2, PriceType, AvgPeriod, StdPeriod
   m_handles[IH_ADXS_14] = iCustom(sym, PERIOD_M1, "AIEngine\\ADXSmooth",
                                     14, 0.25, 0.33, 0, 1000, 4000);
   
   m_handles[IH_ADXS_80] = iCustom(sym, PERIOD_M1, "AIEngine\\ADXSmooth",
                                     80, 0.25, 0.33, 0, 1000, 4000);
   
   // ADXMTF: same indicator on different timeframes
   m_handles[IH_ADXMTF_M5] = iCustom(sym, PERIOD_M5, "AIEngine\\ADXSmoothMTF");
   m_handles[IH_ADXMTF_H4] = iCustom(sym, PERIOD_H4, "AIEngine\\ADXSmoothMTF");
   
   // ATR14: standard indicator
   m_handles[IH_ATR14] = iATR(sym, PERIOD_M1, 14);
   
   // BOP: inputs: SmoothPeriod, AvgPeriod, StdPeriod, StdMulti1/2/3
   m_handles[IH_BOP] = iCustom(sym, PERIOD_M1, "AIEngine\\BOPAvgStd",
                                50, 50, 5000, 1.0, 2.0, 3.0);
   
   // BSPWmaSmooth: inputs: WmaPeriod, SmoothPeriod
   m_handles[IH_BSP_10_3] = iCustom(sym, PERIOD_M1, "AIEngine\\BSPWmaSmooth",
                                      10, 3);
   m_handles[IH_BSP_30_5] = iCustom(sym, PERIOD_M1, "AIEngine\\BSPWmaSmooth",
                                      30, 5);
   
   // BWMTF: BWMFI on different timeframes
   m_handles[IH_BWMTF_M5] = iCustom(sym, PERIOD_M5, "AIEngine\\BWMFI_MTF");
   m_handles[IH_BWMTF_H4] = iCustom(sym, PERIOD_H4, "AIEngine\\BWMFI_MTF");
   
   // Chandelier Exit: inputs: AtrPeriod, AtrMultiplier1, AtrMultiplier2, LookBackPeriod
   m_handles[IH_CE] = iCustom(sym, PERIOD_M1, "AIEngine\\ChandelierExit",
                               22, 3.0, 4.5, 22);
   
   // Chaikin Volatility: inputs: SmoothPeriod, CHVPeriod, SmoothType, StdDevPeriod, Multi1/2/3
   m_handles[IH_CHV_10_10] = iCustom(sym, PERIOD_M1, "AIEngine\\ChaikinVolatility",
                                       10, 10, 2, 5000, 1.0, 2.0, 3.0);
   m_handles[IH_CHV_30_30] = iCustom(sym, PERIOD_M1, "AIEngine\\ChaikinVolatility",
                                       30, 30, 2, 5000, 1.0, 2.0, 3.0);
   
   // Chopping Index: inputs: ChoPeriod, SmoothPeriod, AvgPeriod, StdPeriod, SmoothPhase
   m_handles[IH_CHOP_14_14] = iCustom(sym, PERIOD_M1, "AIEngine\\ChoppingIndex",
                                        14, 14, 1000, 4000, 0);
   m_handles[IH_CHOP_120_40] = iCustom(sym, PERIOD_M1, "AIEngine\\ChoppingIndex",
                                         120, 40, 1000, 4000, 0);
   
   // LRAVGSTD: inputs: LwmaPeriod, AvgPeriod, StdPeriodL, StdPeriodS, Multi1/2/3
   //           + TimeFilter inputs (6 more): StartH, StartM, EndH, EndM, MaxBSPMult
   m_handles[IH_LRAVG_60] = iCustom(sym, PERIOD_M1, "AIEngine\\LRAVGSTD",
                                      25, 60, 5000, 2, 1.0, 2.0, 3.0, 1, 30, 23, 30, 20.0);
   m_handles[IH_LRAVG_180] = iCustom(sym, PERIOD_M1, "AIEngine\\LRAVGSTD",
                                       25, 180, 5000, 2, 1.0, 2.0, 3.0, 1, 30, 23, 30, 20.0);
   m_handles[IH_LRAVG_240] = iCustom(sym, PERIOD_M1, "AIEngine\\LRAVGSTD",
                                       25, 240, 5000, 2, 1.0, 2.0, 3.0, 1, 30, 23, 30, 20.0);
   
   // QQE: inputs: SF, RSI_Period
   m_handles[IH_QQE_5_14] = iCustom(sym, PERIOD_M1, "AIEngine\\QQE", 5, 14);
   m_handles[IH_QQE_12_32] = iCustom(sym, PERIOD_M1, "AIEngine\\QQE", 12, 32);
   
   // TDI: inputs: RSI, AppliedPrice, VolBandPeriod, SmRSI, SmMethod, SmSig, SigMethod, OB, OS, ShowBase, ShowVBL
   m_handles[IH_TDI_13] = iCustom(sym, PERIOD_M1, "AIEngine\\TDI",
                                    13, 0, 34, 2, 0, 7, 0, 68, 32, 0, 0);
   m_handles[IH_TDI_14] = iCustom(sym, PERIOD_M1, "AIEngine\\TDI",
                                    14, 0, 90, 35, 0, 35, 0, 68, 32, 0, 0);
   
   // Validate all handles
   for(int i = 0; i < IH_COUNT; i++)
   {
      if(m_handles[i] == INVALID_HANDLE)
      {
         Print("[CFeatureEngine] FAILED to create handle #", i, " error=", GetLastError());
         ok = false;
      }
   }
   
   if(ok)
      Print("[CFeatureEngine] All ", IH_COUNT, " handles created successfully");
   
   return ok;
}

//+------------------------------------------------------------------+
//| PreloadHistory — Fast-forward CRollingStats with past 1440 bars  |
//| Reads historical data via CopyBuffer and pushes in chronological |
//| order so EA starts with IsReady()=true immediately.              |
//+------------------------------------------------------------------+
bool CFeatureEngine::PreloadHistory()
{
   const int PRELOAD_BARS = 1440;  // 24 hours of M1
   
   Print("[CFeatureEngine] PreloadHistory: loading ", PRELOAD_BARS, " bars...");
   
   // --- Load Close and TickVolume from standard functions ---
   double closeBuf[];
   long   volLong[];
   ArrayResize(closeBuf, PRELOAD_BARS);
   ArrayResize(volLong,  PRELOAD_BARS);
   
   if(CopyClose(_Symbol, PERIOD_M1, 1, PRELOAD_BARS, closeBuf) != PRELOAD_BARS)
   {
      Print("[CFeatureEngine] PreloadHistory: CopyClose failed");
      return false;
   }
   if(CopyTickVolume(_Symbol, PERIOD_M1, 1, PRELOAD_BARS, volLong) != PRELOAD_BARS)
   {
      Print("[CFeatureEngine] PreloadHistory: CopyTickVolume failed");
      return false;
   }
   
   // --- Load indicator buffers into temp arrays ---
   // Each indicator's buffers are loaded for PRELOAD_BARS in one call.
   // CopyBuffer returns oldest-first: arr[0]=oldest, arr[N-1]=newest
   
   // Temp struct for handle+buffer → rawSlot mapping
   struct BufMap { int hIdx; int bufIdx; int rsSlot; };
   BufMap maps[] =
   {
      { IH_ADXS_14,    0, RS_ADXS14_DIPLUS },
      { IH_ADXS_14,    1, RS_ADXS14_DIMINUS },
      { IH_ADXS_14,    2, RS_ADXS14_ADX },
      { IH_ADXS_80,    0, RS_ADXS80_DIPLUS },
      { IH_ADXS_80,    1, RS_ADXS80_DIMINUS },
      { IH_ADXS_80,    2, RS_ADXS80_ADX },
      { IH_ADXMTF_M5,  0, RS_ADXMTF_M5_DIPLUS },
      { IH_ADXMTF_M5,  2, RS_ADXMTF_M5_ADX },
      { IH_ADXMTF_H4,  0, RS_ADXMTF_H4_DIPLUS },
      { IH_ADXMTF_H4,  2, RS_ADXMTF_H4_ADX },
      { IH_ATR14,       0, RS_ATR14 },
      { IH_BOP,         6, RS_BOP_DIFF },
      { IH_BOP,        10, RS_BOP_SCALE },
      { IH_BSP_10_3,    0, RS_BSP_10_3 },
      { IH_BSP_30_5,    0, RS_BSP_30_5 },
      { IH_BWMTF_M5,    0, RS_BWMTF_M5 },
      { IH_BWMTF_H4,    0, RS_BWMTF_H4 },
      { IH_CE,           0, RS_CE_SL1 },
      { IH_CE,           2, RS_CE_SL2 },
      { IH_CHV_10_10,    4, RS_CHV_10_CHV },
      { IH_CHV_10_10,    9, RS_CHV_10_STDDEV },
      { IH_CHV_30_30,    4, RS_CHV_30_CHV },
      { IH_CHV_30_30,    9, RS_CHV_30_STDDEV },
      { IH_CHOP_14_14,   3, RS_CHOP_14_CSI },
      { IH_CHOP_14_14,   5, RS_CHOP_14_SCALE },
      { IH_CHOP_120_40,  3, RS_CHOP_120_CSI },
      { IH_CHOP_120_40,  5, RS_CHOP_120_SCALE },
      { IH_LRAVG_60,     6, RS_LRAVG60_STDS },
      { IH_LRAVG_60,    11, RS_LRAVG60_BSPSCALE },
      { IH_LRAVG_180,    6, RS_LRAVG180_STDS },
      { IH_LRAVG_180,   11, RS_LRAVG180_BSPSCALE },
      { IH_LRAVG_240,    6, RS_LRAVG240_STDS }
   };
   int mapCount = ArraySize(maps);
   
   // histData[slot][bar] — store per-slot historical arrays
   double histData[];
   ArrayResize(histData, (int)RS_COUNT * PRELOAD_BARS);
   ArrayInitialize(histData, 0);
   
   double tmpBuf[];
   ArrayResize(tmpBuf, PRELOAD_BARS);
   
   for(int m = 0; m < mapCount; m++)
   {
      int hIdx  = maps[m].hIdx;
      int bIdx  = maps[m].bufIdx;
      int slot  = maps[m].rsSlot;
      
      if(m_handles[hIdx] == INVALID_HANDLE) continue;
      
      int copied = CopyBuffer(m_handles[hIdx], bIdx, 1, PRELOAD_BARS, tmpBuf);
      if(copied <= 0)
      {
         Print("[CFeatureEngine] PreloadHistory: CopyBuffer failed for handle=", hIdx,
               " buf=", bIdx, " error=", GetLastError());
         return false;
      }
      
      // Pad if less than PRELOAD_BARS returned (partial history)
      int startIdx = PRELOAD_BARS - copied;
      for(int b = 0; b < copied; b++)
      {
         double val = tmpBuf[b];
         if(val == EMPTY_VALUE || !MathIsValidNumber(val)) val = 0;
         histData[(startIdx + b) * (int)RS_COUNT + slot] = val;
      }
   }
   
   // Fill Close, TickVolume, CE_DIST into histData
   for(int b = 0; b < PRELOAD_BARS; b++)
   {
      histData[b * (int)RS_COUNT + (int)RS_CLOSE]   = closeBuf[b];
      histData[b * (int)RS_COUNT + (int)RS_TICKVOL]  = (double)volLong[b];
      
      double sl1 = histData[b * (int)RS_COUNT + (int)RS_CE_SL1];
      double sl2 = histData[b * (int)RS_COUNT + (int)RS_CE_SL2];
      histData[b * (int)RS_COUNT + (int)RS_CE_DIST1] = (sl1 > 0) ? closeBuf[b] - sl1 : 0;
      histData[b * (int)RS_COUNT + (int)RS_CE_DIST2] = (sl2 > 0) ? closeBuf[b] - sl2 : 0;
   }
   
   // --- Push all historical values into CRollingStats (oldest → newest) ---
   for(int b = 0; b < PRELOAD_BARS; b++)
   {
      for(int s = 0; s < (int)RS_COUNT; s++)
         m_rs[s].Push(histData[b * (int)RS_COUNT + s]);
      
      // TickVolume special stats
      double tv = histData[b * (int)RS_COUNT + (int)RS_TICKVOL];
      m_rsTick60.Push(tv);
      m_rsTick240.Push(tv);
      m_rsTick1440.Push(tv);
      
      // Close history ring buffer
      m_closeHistory[m_closeHistIdx % 1440] = closeBuf[b];
      m_closeHistIdx++;
      if(m_closeHistIdx >= 11)
         m_close10BarsAgo = m_closeHistory[(m_closeHistIdx - 10) % 1440];
      
      m_warmupBars++;
      m_barCount++;
   }
   
   // Store latest raw values for current state
   for(int s = 0; s < (int)RS_COUNT; s++)
      m_raw[s] = histData[(PRELOAD_BARS - 1) * (int)RS_COUNT + s];
   
   // Mark ready
   if(m_warmupBars >= 240)
   {
      m_isReady = true;
      Print("[CFeatureEngine] PreloadHistory SUCCESS: ", m_warmupBars,
            " bars loaded, IsReady=true (immediate)");
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Read a single buffer value from indicator handle                 |
//+------------------------------------------------------------------+
double CFeatureEngine::ReadBuffer(int handleIdx, int bufferIdx, int shift)
{
   if(handleIdx < 0 || handleIdx >= IH_COUNT || m_handles[handleIdx] == INVALID_HANDLE)
      return 0;
   
   double val[1];
   if(CopyBuffer(m_handles[handleIdx], bufferIdx, shift, 1, val) <= 0)
      return 0;
   
   // Filter EMPTY_VALUE (used by many indicators)
   if(val[0] == EMPTY_VALUE || !MathIsValidNumber(val[0]))
      return 0;
   
   return val[0];
}

//+------------------------------------------------------------------+
//| Read all raw indicator values for current completed bar (Shift=1)|
//+------------------------------------------------------------------+
void CFeatureEngine::ReadRawValues()
{
   // *** All reads use shift=1 (completed bar) per Rule_Shift+1 ***
   
   // ADXS 14: buf 0=DiPlus, 1=DiMinus, 2=ADX, 6=Scale(CALCULATIONS)
   m_raw[RS_ADXS14_DIPLUS]  = ReadBuffer(IH_ADXS_14, 0, 1);
   m_raw[RS_ADXS14_DIMINUS] = ReadBuffer(IH_ADXS_14, 1, 1);
   m_raw[RS_ADXS14_ADX]     = ReadBuffer(IH_ADXS_14, 2, 1);
   
   // ADXS 80
   m_raw[RS_ADXS80_DIPLUS]  = ReadBuffer(IH_ADXS_80, 0, 1);
   m_raw[RS_ADXS80_DIMINUS] = ReadBuffer(IH_ADXS_80, 1, 1);
   m_raw[RS_ADXS80_ADX]     = ReadBuffer(IH_ADXS_80, 2, 1);
   
   // ADXMTF (M5/H4): buf 0=DiPlus, 2=ADX
   m_raw[RS_ADXMTF_M5_DIPLUS] = ReadBuffer(IH_ADXMTF_M5, 0, 1);
   m_raw[RS_ADXMTF_M5_ADX]    = ReadBuffer(IH_ADXMTF_M5, 2, 1);
   m_raw[RS_ADXMTF_H4_DIPLUS] = ReadBuffer(IH_ADXMTF_H4, 0, 1);
   m_raw[RS_ADXMTF_H4_ADX]    = ReadBuffer(IH_ADXMTF_H4, 2, 1);
   
   // ATR14
   m_raw[RS_ATR14] = ReadBuffer(IH_ATR14, 0, 1);
   
   // BOP: buf 6=Diff, 10=Scale(CALC)
   m_raw[RS_BOP_DIFF]  = ReadBuffer(IH_BOP, 6, 1);
   m_raw[RS_BOP_SCALE] = ReadBuffer(IH_BOP, 10, 1);
   
   // BSP: buf 0=SmoothDiffRatio
   m_raw[RS_BSP_10_3] = ReadBuffer(IH_BSP_10_3, 0, 1);
   m_raw[RS_BSP_30_5] = ReadBuffer(IH_BSP_30_5, 0, 1);
   
   // BWMTF: buf 0=BWMFI
   m_raw[RS_BWMTF_M5] = ReadBuffer(IH_BWMTF_M5, 0, 1);
   m_raw[RS_BWMTF_H4] = ReadBuffer(IH_BWMTF_H4, 0, 1);
   
   // CE: buf 0=Upl1(SL1), 1=Dnl1, 2=Upl2(SL2), 3=Dnl2
   m_raw[RS_CE_SL1]  = ReadBuffer(IH_CE, 0, 1);
   m_raw[RS_CE_SL2]  = ReadBuffer(IH_CE, 2, 1);
   // Dist = Close - CEline
   double close = iClose(_Symbol, PERIOD_M1, 1);
   m_raw[RS_CE_DIST1] = (m_raw[RS_CE_SL1] > 0) ? close - m_raw[RS_CE_SL1] : 0;
   m_raw[RS_CE_DIST2] = (m_raw[RS_CE_SL2] > 0) ? close - m_raw[RS_CE_SL2] : 0;
   
   // CHV: buf 4=CHV, 8=CVScale(CALC), 9=StdDev(CALC)
   m_raw[RS_CHV_10_CHV]    = ReadBuffer(IH_CHV_10_10, 4, 1);
   m_raw[RS_CHV_10_STDDEV] = ReadBuffer(IH_CHV_10_10, 9, 1);
   m_raw[RS_CHV_30_CHV]    = ReadBuffer(IH_CHV_30_30, 4, 1);
   m_raw[RS_CHV_30_STDDEV] = ReadBuffer(IH_CHV_30_30, 9, 1);
   
   // CHOP: buf 3=CSI, 5=ChoppingScale(CALC)
   m_raw[RS_CHOP_14_CSI]   = ReadBuffer(IH_CHOP_14_14, 3, 1);
   m_raw[RS_CHOP_14_SCALE] = ReadBuffer(IH_CHOP_14_14, 5, 1);
   m_raw[RS_CHOP_120_CSI]   = ReadBuffer(IH_CHOP_120_40, 3, 1);
   m_raw[RS_CHOP_120_SCALE] = ReadBuffer(IH_CHOP_120_40, 5, 1);
   
   // LRAVGST: buf 6=StdS, 11=BSPScale(CALC)
   m_raw[RS_LRAVG60_STDS]     = ReadBuffer(IH_LRAVG_60, 6, 1);
   m_raw[RS_LRAVG60_BSPSCALE] = ReadBuffer(IH_LRAVG_60, 11, 1);
   m_raw[RS_LRAVG180_STDS]    = ReadBuffer(IH_LRAVG_180, 6, 1);
   m_raw[RS_LRAVG180_BSPSCALE]= ReadBuffer(IH_LRAVG_180, 11, 1);
   m_raw[RS_LRAVG240_STDS]    = ReadBuffer(IH_LRAVG_240, 6, 1);
   
   // TickVolume + Close
   m_raw[RS_TICKVOL] = (double)iVolume(_Symbol, PERIOD_M1, 1);
   m_raw[RS_CLOSE]   = close;
}

//+------------------------------------------------------------------+
//| Update — call once per new M1 bar                                |
//+------------------------------------------------------------------+
void CFeatureEngine::Update()
{
   // 1. Read raw values
   ReadRawValues();
   
   // 2. Push raw values into CRollingStats
   for(int i = 0; i < RS_COUNT; i++)
      m_rs[i].Push(m_raw[i]);
   
   // 3. TickVolume special stats
   m_rsTick60.Push(m_raw[RS_TICKVOL]);
   m_rsTick240.Push(m_raw[RS_TICKVOL]);
   m_rsTick1440.Push(m_raw[RS_TICKVOL]);
   
   // 4. Close history for price momentum
   m_closeHistory[m_closeHistIdx % 1440] = m_raw[RS_CLOSE];
   m_closeHistIdx++;
   if(m_closeHistIdx >= 11)
      m_close10BarsAgo = m_closeHistory[(m_closeHistIdx - 10) % 1440];
   
   // 5. Warmup counter
   m_warmupBars++;
   if(m_warmupBars >= 240 && !m_isReady)
   {
      m_isReady = true;
      Print("[CFeatureEngine] Warm-up complete: ", m_warmupBars, " bars");
   }
   
   m_barCount++;
}

//+------------------------------------------------------------------+
//| Safe division                                                    |
//+------------------------------------------------------------------+
double CFeatureEngine::SafeDiv(double num, double den)
{
   if(den == 0 || !MathIsValidNumber(den)) return 0;
   double result = num / den;
   if(!MathIsValidNumber(result)) return 0;
   return result;
}

//+------------------------------------------------------------------+
//| Get CE2 value (for CTradeExecutor)                               |
//+------------------------------------------------------------------+
double CFeatureEngine::GetCE2Value() const
{
   return m_raw[RS_CE_SL2];  // UplBuffer2 = ATR*4.5 chandelier
}

//+------------------------------------------------------------------+
//| Assemble Entry feature vector (80 elements)                      |
//| Output must match FeatureSchema.mqh ENTRY_FEATURE_NAMES order    |
//+------------------------------------------------------------------+
void CFeatureEngine::GetEntryFeatures(float &out[])
{
   ArrayResize(out, ENTRY_FEATURE_COUNT);
   ArrayInitialize(out, 0);
   
   if(!m_isReady) return;
   
   int idx = 0;
   
   // The feature order MUST match FeatureSchema.mqh ENTRY_FEATURE_INDICES
   // Each feature is computed from raw values + CRollingStats derived values
   // Pattern: zscore = m_rs[slot].ZScore()
   //          slope  = m_rs[slot].Slope(14)
   //          pct    = m_rs[slot].PctRank()
   //          accel  = m_rs[slot].Accel(14)
   
   // Build features in FeatureSchema order.
   // NOTE: The exact mapping depends on FeatureSchema.mqh which is auto-generated
   // from export_feature_schema.py. Here we populate based on the known 80 features.
   
   // --- Technical indicators ---
   // Z-scores, slopes, pct_ranks, passthrough values per FeatureSchema order
   // This array will be populated according to the exact order from FeatureSchema
   
   // For now: build a comprehensive feature dictionary approach
   // Feature values mapped by name pattern
   
   // ADXS (14) DiPlus
   out[idx++] = (float)m_rs[RS_ADXS14_DIPLUS].ZScore();     // zscore
   out[idx++] = (float)m_rs[RS_ADXS14_DIPLUS].PctRank();    // pct240
   // ADXS (14) DiMinus
   out[idx++] = (float)m_rs[RS_ADXS14_DIMINUS].ZScore();
   out[idx++] = (float)m_rs[RS_ADXS14_DIMINUS].PctRank();
   // ADXS (80) DiPlus
   out[idx++] = (float)m_rs[RS_ADXS80_DIPLUS].ZScore();
   out[idx++] = (float)m_rs[RS_ADXS80_DIPLUS].PctRank();
   // ADXS (80) DiMinus
   out[idx++] = (float)m_rs[RS_ADXS80_DIMINUS].ZScore();
   out[idx++] = (float)m_rs[RS_ADXS80_DIMINUS].PctRank();
   
   // ADXMTF M5 DiPlus slope
   out[idx++] = (float)m_rs[RS_ADXMTF_M5_DIPLUS].Slope(5);
   out[idx++] = (float)m_rs[RS_ADXMTF_M5_ADX].Slope(5);
   // ADXMTF H4 DiPlus slope/pct
   out[idx++] = (float)m_rs[RS_ADXMTF_H4_DIPLUS].Slope(5);
   out[idx++] = (float)m_rs[RS_ADXMTF_H4_DIPLUS].PctRank();
   
   // ATR14
   out[idx++] = (float)m_rs[RS_ATR14].ZScore();
   out[idx++] = (float)m_rs[RS_ATR14].PctRank();
   
   // BOP Scale (passthrough) + Diff slope
   out[idx++] = (float)m_raw[RS_BOP_SCALE];
   out[idx++] = (float)m_rs[RS_BOP_DIFF].Slope(14);
   out[idx++] = (float)m_rs[RS_BOP_DIFF].PctRank();
   
   // BSP (10-3) accel + slope
   out[idx++] = (float)m_rs[RS_BSP_10_3].Slope(14);
   out[idx++] = (float)m_rs[RS_BSP_10_3].Accel(14);
   // BSP (30-5)
   out[idx++] = (float)m_rs[RS_BSP_30_5].Slope(14);
   out[idx++] = (float)m_rs[RS_BSP_30_5].Accel(14);
   
   // BWMTF M5/H4 slope
   out[idx++] = (float)m_rs[RS_BWMTF_M5].Slope(5);
   out[idx++] = (float)m_rs[RS_BWMTF_M5].ZScore();
   out[idx++] = (float)m_rs[RS_BWMTF_H4].Slope(5);
   out[idx++] = (float)m_rs[RS_BWMTF_H4].ZScore();
   
   // CE Dist1/Dist2 zscore, slope, squeeze
   out[idx++] = (float)m_rs[RS_CE_DIST1].ZScore();
   out[idx++] = (float)m_rs[RS_CE_DIST1].Slope(14);
   out[idx++] = (float)m_rs[RS_CE_DIST1].PctRank();
   out[idx++] = (float)((m_raw[RS_CE_SL1] > 0) ? 0.0 : 1.0);  // CE_SL1_squeeze
   out[idx++] = (float)m_rs[RS_CE_DIST2].ZScore();
   out[idx++] = (float)m_rs[RS_CE_DIST2].Slope(14);
   out[idx++] = (float)m_rs[RS_CE_DIST2].PctRank();
   out[idx++] = (float)((m_raw[RS_CE_SL2] > 0) ? 0.0 : 1.0);  // CE_SL2_squeeze
   // CE dist_ATR
   out[idx++] = (float)SafeDiv(m_raw[RS_CE_DIST1], m_raw[RS_ATR14]);
   out[idx++] = (float)SafeDiv(m_raw[RS_CE_DIST2], m_raw[RS_ATR14]);
   
   // CHV (10,10) StdDev zscore + CHV zscore
   out[idx++] = (float)m_rs[RS_CHV_10_STDDEV].ZScore();
   out[idx++] = (float)m_rs[RS_CHV_10_CHV].ZScore();
   out[idx++] = (float)m_rs[RS_CHV_10_CHV].PctRank();
   // CHV (30,30)
   out[idx++] = (float)m_rs[RS_CHV_30_STDDEV].ZScore();
   out[idx++] = (float)m_rs[RS_CHV_30_CHV].ZScore();
   out[idx++] = (float)m_rs[RS_CHV_30_CHV].PctRank();
   
   // CHOP (14,14) Scale passthrough + CSI slope
   out[idx++] = (float)m_raw[RS_CHOP_14_SCALE];
   out[idx++] = (float)m_rs[RS_CHOP_14_CSI].Slope(14);
   // CHOP (120,40) Scale passthrough + CSI slope
   out[idx++] = (float)m_raw[RS_CHOP_120_SCALE];
   out[idx++] = (float)m_rs[RS_CHOP_120_CSI].Slope(14);
   
   // LRAVGST (60) StdS zscore/slope + BSPScale passthrough
   out[idx++] = (float)m_rs[RS_LRAVG60_STDS].ZScore();
   out[idx++] = (float)m_rs[RS_LRAVG60_STDS].Slope(14);
   out[idx++] = (float)m_raw[RS_LRAVG60_BSPSCALE];
   // LRAVGST (180) StdS zscore/slope + BSPScale passthrough
   out[idx++] = (float)m_rs[RS_LRAVG180_STDS].ZScore();
   out[idx++] = (float)m_rs[RS_LRAVG180_STDS].Slope(14);
   out[idx++] = (float)m_raw[RS_LRAVG180_BSPSCALE];
   
   // QQE (5,14): RSI + RsiMa + TrLevel passthrough
   double qqe_rsi_5  = ReadBuffer(IH_QQE_5_14, 0, 1);  // RsiMa
   double qqe_tr_5   = ReadBuffer(IH_QQE_5_14, 1, 1);  // TrLevel
   out[idx++] = (float)qqe_rsi_5;
   out[idx++] = (float)qqe_tr_5;
   // QQE (12,32)
   double qqe_rsi_12 = ReadBuffer(IH_QQE_12_32, 0, 1);
   double qqe_tr_12  = ReadBuffer(IH_QQE_12_32, 1, 1);
   out[idx++] = (float)qqe_rsi_12;
   out[idx++] = (float)qqe_tr_12;
   
   // TDI (13-34-2-7): TrSi passthrough + Signal passthrough
   out[idx++] = (float)ReadBuffer(IH_TDI_13, 0, 1);  // TRSI
   out[idx++] = (float)ReadBuffer(IH_TDI_13, 1, 1);  // Signal
   // TDI (14-90-35)
   out[idx++] = (float)ReadBuffer(IH_TDI_14, 0, 1);
   out[idx++] = (float)ReadBuffer(IH_TDI_14, 1, 1);
   
   // TickVolume features: ratio_MA60/240/1440, zscore60/240, pct240
   double tickMean60  = m_rsTick60.Mean();
   double tickMean240 = m_rsTick240.Mean();
   double tickMean1440= m_rsTick1440.Mean();
   out[idx++] = (float)SafeDiv(m_raw[RS_TICKVOL], tickMean60);
   out[idx++] = (float)SafeDiv(m_raw[RS_TICKVOL], tickMean240);
   out[idx++] = (float)SafeDiv(m_raw[RS_TICKVOL], tickMean1440);
   out[idx++] = (float)m_rsTick60.ZScore();
   out[idx++] = (float)m_rsTick240.ZScore();
   out[idx++] = (float)m_rsTick240.PctRank();
   
   // price_mom_10 = Close / Close[10] - 1
   out[idx++] = (float)(m_close10BarsAgo > 0 ? m_raw[RS_CLOSE] / m_close10BarsAgo - 1.0 : 0);
   
   // Regime features (4)
   // These need weekly/monthly aggregation — simplified for real-time
   out[idx++] = (float)m_rs[RS_CLOSE].PctRank();  // regime_monthly_pct proxy
   out[idx++] = (float)0.5;  // regime_weekly_up_ratio (placeholder, updated periodically)
   out[idx++] = (float)1.0;  // regime_above_ma20w (placeholder)
   out[idx++] = (float)1.0;  // regime_bull_flag (placeholder)
   
   // Macro features from CMacroLoader (remaining slots)
   if(m_macroLoader != NULL)
   {
      datetime dt = iTime(_Symbol, PERIOD_M1, 1);
      while(idx < ENTRY_FEATURE_COUNT)
      {
         // Macro features fill remaining slots
         // Order determined by FeatureSchema.mqh
         out[idx] = (float)m_macroLoader.GetFeatureByDate(idx, dt);
         idx++;
      }
   }
   
   // Ensure exactly ENTRY_FEATURE_COUNT features
   if(idx < ENTRY_FEATURE_COUNT)
   {
      Print("[CFeatureEngine] WARNING: Only ", idx, "/", ENTRY_FEATURE_COUNT, " features populated");
   }
}

//+------------------------------------------------------------------+
//| Assemble Addon feature vector (77 elements)                      |
//| Shares most features with Entry + adds dynamic position features |
//+------------------------------------------------------------------+
void CFeatureEngine::GetAddonFeatures(float &out[],
                                      int addonCount,
                                      double unrealizedATR,
                                      int barsSinceEntry,
                                      double atrExpansion,
                                      double bspScaleDelta,
                                      double trendAccel)
{
   // Start with entry features
   float entryFeats[];
   GetEntryFeatures(entryFeats);
   
   ArrayResize(out, ADDON_FEATURE_COUNT);
   ArrayInitialize(out, 0);
   
   // Copy shared features (first ~71 are shared, last 6 are dynamic)
   int shared = ADDON_FEATURE_COUNT - 6;
   for(int i = 0; i < shared && i < ENTRY_FEATURE_COUNT; i++)
      out[i] = entryFeats[i];
   
   // Dynamic position features (Addon-only)
   int di = shared;
   out[di++] = (float)addonCount;
   out[di++] = (float)unrealizedATR;
   out[di++] = (float)barsSinceEntry;
   out[di++] = (float)atrExpansion;
   out[di++] = (float)bspScaleDelta;
   out[di++] = (float)trendAccel;
}

#endif // __CFEATUREENGINE_MQH__
