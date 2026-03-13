//+------------------------------------------------------------------+
//| CSignalGenerator.mqh — Entry/Addon/None signal decision engine   |
//| Phase 2-2 | AIEngine Module                                      |
//|                                                                  |
//| Evaluates AI model probabilities against thresholds and          |
//| pyramiding conditions to generate trading signals.               |
//|                                                                  |
//| Usage:                                                           |
//|   CSignalGenerator sig;                                          |
//|   sig.Init(0.20, 0.40, 3, 5, 1.5);                             |
//|   ENUM_SIGNAL s = sig.Evaluate(probEntry, probAddon, ...);      |
//+------------------------------------------------------------------+
#ifndef __CSIGNALGENERATOR_MQH__
#define __CSIGNALGENERATOR_MQH__

//+------------------------------------------------------------------+
//| Signal types                                                     |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL
{
   SIGNAL_NONE   = 0,     // No action
   SIGNAL_ENTRY  = 1,     // New 1st entry (long)
   SIGNAL_ADDON  = 2      // Pyramiding add-on
};

//+------------------------------------------------------------------+
//| CSignalGenerator class                                           |
//+------------------------------------------------------------------+
class CSignalGenerator
{
private:
   //--- Thresholds
   double         m_entryThreshold;     // prob >= this → entry  (default: 0.20)
   double         m_addonThreshold;     // prob >= this → addon  (default: 0.40)
   
   //--- Pyramiding limits
   int            m_maxPyramiding;      // Max addon count (default: 3)
   int            m_minBarsGap;         // Min bars between addons (default: 5)
   double         m_minProfitATR;       // Min unrealized profit in ATR (default: 1.5)
   
   //--- Last evaluation state
   string         m_lastReason;         // Why this signal was generated
   ENUM_SIGNAL    m_lastSignal;         // Last generated signal
   
public:
                  CSignalGenerator();
                 ~CSignalGenerator();
   
   //--- Initialization
   void           Init(double entryThr = 0.20, double addonThr = 0.40,
                       int maxPyramid = 3, int minBarsGap = 5,
                       double minProfitATR = 1.5);
   
   //--- Core evaluation
   ENUM_SIGNAL    Evaluate(double probEntry, double probAddon,
                           bool hasPosition, int addonCount,
                           double unrealizedATR, int barsSinceLastEntry,
                           bool isBlackout, bool isWarmupReady);
   
   //--- Accessors
   string         GetLastReason() const    { return m_lastReason; }
   ENUM_SIGNAL    GetLastSignal() const    { return m_lastSignal; }
   
   //--- Settings accessors
   double         GetEntryThreshold() const  { return m_entryThreshold; }
   double         GetAddonThreshold() const  { return m_addonThreshold; }
   int            GetMaxPyramiding() const   { return m_maxPyramiding; }
   
   //--- Reset (call when position fully closed)
   void           Reset();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalGenerator::CSignalGenerator()
   : m_entryThreshold(0.20), m_addonThreshold(0.40),
     m_maxPyramiding(3), m_minBarsGap(5), m_minProfitATR(1.5),
     m_lastSignal(SIGNAL_NONE), m_lastReason("Not evaluated")
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalGenerator::~CSignalGenerator()
{
}

//+------------------------------------------------------------------+
//| Initialize with configurable parameters                          |
//+------------------------------------------------------------------+
void CSignalGenerator::Init(double entryThr, double addonThr,
                            int maxPyramid, int minBarsGap,
                            double minProfitATR)
{
   m_entryThreshold = entryThr;
   m_addonThreshold = addonThr;
   m_maxPyramiding  = maxPyramid;
   m_minBarsGap     = minBarsGap;
   m_minProfitATR   = minProfitATR;
   
   Print("[CSignalGenerator] Init: entry>=", m_entryThreshold,
         " addon>=", m_addonThreshold,
         " maxPyramid=", m_maxPyramiding,
         " minBars=", m_minBarsGap,
         " minProfitATR=", DoubleToString(m_minProfitATR, 1));
}

//+------------------------------------------------------------------+
//| Evaluate signals — the core decision engine                      |
//|                                                                  |
//| probEntry:          Entry model probability (0~1, -1=invalid)    |
//| probAddon:          Addon model probability (0~1, -1=invalid)    |
//| hasPosition:        true if long position exists                 |
//| addonCount:         current number of addon entries              |
//| unrealizedATR:      unrealized PnL in ATR units (vs 1st entry)  |
//| barsSinceLastEntry: bars elapsed since last entry/addon          |
//| isBlackout:         true if in event blackout window             |
//| isWarmupReady:      true if CRITICAL warmup (240 bars) complete  |
//+------------------------------------------------------------------+
ENUM_SIGNAL CSignalGenerator::Evaluate(double probEntry, double probAddon,
                                       bool hasPosition, int addonCount,
                                       double unrealizedATR, int barsSinceLastEntry,
                                       bool isBlackout, bool isWarmupReady)
{
   m_lastSignal = SIGNAL_NONE;
   
   //--- Gate 1: Warmup check (CRITICAL — must have 240+ bars)
   if(!isWarmupReady)
   {
      m_lastReason = "NONE: Warm-up not complete";
      return SIGNAL_NONE;
   }
   
   //--- Gate 2: Event blackout check
   if(isBlackout)
   {
      m_lastReason = "NONE: Event blackout active";
      return SIGNAL_NONE;
   }
   
   //--- Gate 3: ONNX inference failure (prob = -1.0)
   if(probEntry < 0.0 && probAddon < 0.0)
   {
      m_lastReason = "NONE: ONNX inference failed (prob=-1)";
      return SIGNAL_NONE;
   }
   
   //--- Case A: No position → evaluate ENTRY
   if(!hasPosition)
   {
      if(probEntry < 0.0)
      {
         m_lastReason = "NONE: Entry prob invalid (-1)";
         return SIGNAL_NONE;
      }
      
      if(probEntry >= m_entryThreshold)
      {
         m_lastSignal = SIGNAL_ENTRY;
         m_lastReason = StringFormat("ENTRY: prob=%.4f >= %.2f", 
                                     probEntry, m_entryThreshold);
         return SIGNAL_ENTRY;
      }
      else
      {
         m_lastReason = StringFormat("NONE: prob=%.4f < %.2f (threshold)",
                                     probEntry, m_entryThreshold);
         return SIGNAL_NONE;
      }
   }
   
   //--- Case B: Has position → evaluate ADDON
   if(probAddon < 0.0)
   {
      m_lastReason = "NONE: Addon prob invalid (-1)";
      return SIGNAL_NONE;
   }
   
   // Check all pyramiding conditions
   if(probAddon < m_addonThreshold)
   {
      m_lastReason = StringFormat("NONE: addon_prob=%.4f < %.2f",
                                  probAddon, m_addonThreshold);
      return SIGNAL_NONE;
   }
   
   if(addonCount >= m_maxPyramiding)
   {
      m_lastReason = StringFormat("NONE: addon_count=%d >= max=%d",
                                  addonCount, m_maxPyramiding);
      return SIGNAL_NONE;
   }
   
   if(unrealizedATR < m_minProfitATR)
   {
      m_lastReason = StringFormat("NONE: unrealized=%.1fATR < min=%.1f",
                                  unrealizedATR, m_minProfitATR);
      return SIGNAL_NONE;
   }
   
   if(barsSinceLastEntry < m_minBarsGap)
   {
      m_lastReason = StringFormat("NONE: bars_since=%d < min=%d",
                                  barsSinceLastEntry, m_minBarsGap);
      return SIGNAL_NONE;
   }
   
   // All conditions met → ADDON
   m_lastSignal = SIGNAL_ADDON;
   m_lastReason = StringFormat("ADDON: prob=%.4f, count=%d, profit=%.1fATR, gap=%d bars",
                               probAddon, addonCount + 1, unrealizedATR, barsSinceLastEntry);
   return SIGNAL_ADDON;
}

//+------------------------------------------------------------------+
//| Reset state when position fully closed                           |
//+------------------------------------------------------------------+
void CSignalGenerator::Reset()
{
   m_lastSignal = SIGNAL_NONE;
   m_lastReason = "Reset: position closed";
}

#endif // __CSIGNALGENERATOR_MQH__
