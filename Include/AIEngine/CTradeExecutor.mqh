//+------------------------------------------------------------------+
//| CTradeExecutor.mqh — Trade execution with Virtual Stop           |
//| Phase 2-3 | AIEngine Module                                      |
//|                                                                  |
//| Handles order execution, pyramiding lot sizing, virtual SL/CE2,  |
//| and position management for AI-driven trading strategy.          |
//| Base class: Long logic. Override virtual methods for Short.      |
//|                                                                  |
//| Virtual Stop Design:                                             |
//|   - Broker SL = ATR*12 (emergency, far away → anti-hunting)     |
//|   - Internal  = ATR*7  (virtual, checked every tick)             |
//|   - CE2 trailing = checked every tick, ratchet mechanism          |
//|                                                                  |
//| Usage:                                                           |
//|   CTradeExecutor exec;                                           |
//|   exec.Init(MAGIC, 0.01, 7.0, 12.0);                           |
//|   exec.ExecuteEntry(atr, price);                                 |
//|   exec.CheckVirtualStops(bid);  // every tick                   |
//+------------------------------------------------------------------+
#ifndef __CTRADEEXECUTOR_MQH__
#define __CTRADEEXECUTOR_MQH__

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>

//--- Maximum positions managed by this executor
#define EXEC_MAX_POSITIONS  10

//+------------------------------------------------------------------+
//| Position tracking structure                                      |
//+------------------------------------------------------------------+
struct PositionEntry
{
   ulong          ticket;            // Position ticket
   double         openPrice;         // Entry price
   double         lots;              // Lot size
   int            type;              // 0=first entry, 1~3=addon
   int            openBar;           // Bar index at open time
   datetime       openTime;          // Open datetime
};

//+------------------------------------------------------------------+
//| CTradeExecutor class                                             |
//+------------------------------------------------------------------+
class CTradeExecutor
{
private:
   //--- Trade objects
   CTrade         m_trade;
   CPositionInfo  m_posInfo;
   CSymbolInfo    m_symInfo;
   
   //--- Configuration
   ulong          m_magic;
   double         m_riskPercent;       // 1% = 0.01
   double         m_slATRMult;         // Virtual SL multiplier (7.0)
   double         m_emergencySLMult;   // Broker SL multiplier (12.0)
   int            m_maxAddon;          // Max addon count (3)
   double         m_lotRatio;          // Pyramid lot ratio (0.50)
   double         m_spacingATR;        // SL spacing per addon (1.5 ATR)
   string         m_symbol;
   
   //--- Position tracking
   PositionEntry  m_positions[];       // All managed positions
   int            m_posCount;          // Number of positions
   int            m_addonCount;        // Number of addons (0~3)
   double         m_firstEntryPrice;   // Price of 1st entry
   double         m_firstEntryATR;     // ATR at 1st entry
   double         m_firstEntryBSPScale;// BSPScale at 1st entry (for addon delta)
   int            m_firstEntryBar;     // Bar count at 1st entry
   int            m_lastEntryBar;      // Bar count at last entry/addon
   
   //--- Virtual Stop levels
   double         m_virtualSL;         // Virtual SL price (ATR*7)
   double         m_virtualCE2;        // Virtual CE2 trailing price
   bool           m_ce2Active;         // CE2 ratchet activated
   
   //--- State
   bool           m_hasPosition;       // Any position open?
   int            m_currentBar;        // Current bar count (set externally)
   
   //--- Internal helpers
   double         CalcLotSize(double slPoints);
   double         CalcPyramidBaseLot(double atr);
   double         NormalizeLots(double lots);
   void           RecordPosition(ulong ticket, double price, double lots, int type);
   
   //--- GlobalVariable state persistence
   string         GVKey(string suffix);  // Build key: "AI_<Magic>_<Symbol>_<suffix>"
   void           SaveState();           // Backup to GlobalVariable
   void           ClearState();          // Delete GlobalVariables on close
   
   //--- CE2 indicator handle (for recovery check)
   int            m_ceHandle;            // ChandelierExit handle (set externally)
   
public:
                  CTradeExecutor();
                 ~CTradeExecutor();
   
   //--- Initialization
   bool           Init(ulong magic, double riskPercent = 0.01,
                       double slATRMult = 7.0, double emergencySLMult = 12.0,
                       int maxAddon = 3, double lotRatio = 0.50,
                       double spacingATR = 1.5);
   
   //--- Trade execution (virtual — override for Short)
   virtual bool   ExecuteEntry(double atr, double price);
   virtual bool   ExecuteAddon(double atr, double price);
   
   //--- Virtual Stop management (call every tick) — override for Short
   virtual bool   CheckVirtualStops(double currentPrice);
   
   //--- CE2 update (call every M1 bar) — override for Short
   virtual void   UpdateCE2(double ce2Value, double unrealizedATR,
                            double minTPATR = 4.0);
   
   //--- Position info
   bool           HasPosition() const        { return m_hasPosition; }
   int            GetAddonCount() const      { return m_addonCount; }
   double         GetEntryPrice() const      { return m_firstEntryPrice; }
   double         GetFirstATR() const        { return m_firstEntryATR; }
   double         GetEntryATR() const        { return m_firstEntryATR; }
   double         GetEntryBSPScale() const   { return m_firstEntryBSPScale; }
   void           SetEntryBSPScale(double v) { m_firstEntryBSPScale = v; }
   double         GetVirtualSL() const       { return m_virtualSL; }
   double         GetVirtualCE2() const      { return m_virtualCE2; }
   bool           IsCE2Active() const        { return m_ce2Active; }
   int            GetPositionCount() const   { return m_posCount; }
   
   //--- Dynamic feature helpers (for CFeatureEngine) — override for Short
   virtual double GetUnrealizedATR() const;
   int            GetBarsSinceEntry() const;
   int            GetBarsSinceLastEntry() const;
   
   //--- Bar counter (must be called by EA each new bar)
   void           SetCurrentBar(int barNum) { m_currentBar = barNum; }
   int            GetCurrentBar() const     { return m_currentBar; }
   
   //--- Order sending (virtual — override for Short)
   virtual bool   SendOrder(double lots, double sl, string comment);
   
   //--- Close all positions
   bool           CloseAll(string reason = "");
   
   //--- Reset state
   void           Reset();
   
   //--- Resilience: EA restart recovery — override for Short
   //--- Call from OnInit() AFTER Init(). ceHandle = ChandelierExit indicator handle.
   virtual bool   RestoreAndRecover(int ceHandle);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeExecutor::CTradeExecutor()
   : m_magic(0), m_riskPercent(0.01),
     m_slATRMult(7.0), m_emergencySLMult(12.0),
     m_maxAddon(3), m_lotRatio(0.50), m_spacingATR(1.5),
     m_posCount(0), m_addonCount(0),
     m_firstEntryPrice(0), m_firstEntryATR(0),
     m_firstEntryBSPScale(0),
     m_firstEntryBar(0), m_lastEntryBar(0),
     m_virtualSL(0), m_virtualCE2(0), m_ce2Active(false),
     m_hasPosition(false), m_currentBar(0),
     m_ceHandle(INVALID_HANDLE)
{
   ArrayResize(m_positions, EXEC_MAX_POSITIONS);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeExecutor::~CTradeExecutor()
{
}

//+------------------------------------------------------------------+
//| Initialize trade executor                                        |
//+------------------------------------------------------------------+
bool CTradeExecutor::Init(ulong magic, double riskPercent,
                          double slATRMult, double emergencySLMult,
                          int maxAddon, double lotRatio,
                          double spacingATR)
{
   m_magic           = magic;
   m_riskPercent     = riskPercent;
   m_slATRMult       = slATRMult;
   m_emergencySLMult = emergencySLMult;
   m_maxAddon        = maxAddon;
   m_lotRatio        = lotRatio;
   m_spacingATR      = spacingATR;
   m_symbol          = _Symbol;
   
   m_trade.SetExpertMagicNumber(magic);
   m_trade.SetDeviationInPoints(30);  // 30 points slippage for XAUUSD
   m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   m_symInfo.Name(m_symbol);
   
   Reset();
   
   Print("[CTradeExecutor] Init: magic=", m_magic,
         " risk=", DoubleToString(m_riskPercent * 100, 1), "%",
         " SL=ATR*", DoubleToString(m_slATRMult, 1),
         " emergencySL=ATR*", DoubleToString(m_emergencySLMult, 1));
   return true;
}

//+------------------------------------------------------------------+
//| Execute first entry (long)                                       |
//+------------------------------------------------------------------+
bool CTradeExecutor::ExecuteEntry(double atr, double price)
{
   if(m_hasPosition)
   {
      Print("[CTradeExecutor] Entry rejected: position already exists");
      return false;
   }
   
   if(atr <= 0)
   {
      Print("[CTradeExecutor] Entry rejected: invalid ATR=", atr);
      return false;
   }
   
   m_symInfo.RefreshRates();
   double ask = m_symInfo.Ask();
   if(ask <= 0) ask = price;
   
   // Calculate virtual SL and emergency SL
   double virtualSLPrice   = ask - atr * m_slATRMult;
   double emergencySLPrice = ask - atr * m_emergencySLMult;
   double slPoints         = (ask - emergencySLPrice) / m_symInfo.Point();
   
   // Calculate lot size using pyramid worst-case formula
   // Ensures total group risk = exactly 1% even if all addons hit SL
   double lots = CalcPyramidBaseLot(atr);
   if(lots <= 0)
   {
      Print("[CTradeExecutor] Entry rejected: lot calculation failed");
      return false;
   }
   
   // Send order with emergency SL (wide, anti-hunting)
   string comment = StringFormat("AI_Entry|ATR=%.2f", atr);
   if(!SendOrder(lots, emergencySLPrice, comment))
      return false;
   
   // Set virtual stops
   m_virtualSL       = virtualSLPrice;
   m_virtualCE2      = 0;
   m_ce2Active       = false;
   m_firstEntryPrice = ask;
   m_firstEntryATR   = atr;
   m_firstEntryBar   = m_currentBar;
   m_lastEntryBar    = m_currentBar;
   m_addonCount      = 0;
   m_hasPosition     = true;
   
   Print("[CTradeExecutor] ENTRY executed: price=", DoubleToString(ask, 2),
         " lots=", DoubleToString(lots, 2),
         " virtualSL=", DoubleToString(m_virtualSL, 2),
         " emergencySL=", DoubleToString(emergencySLPrice, 2));
   
   // Persist state for crash recovery
   SaveState();
   
   return true;
}

//+------------------------------------------------------------------+
//| Execute pyramiding addon                                         |
//| Lot sizing: decreasing pyramid (1.0 → 0.50 → 0.25)             |
//+------------------------------------------------------------------+
bool CTradeExecutor::ExecuteAddon(double atr, double price)
{
   if(!m_hasPosition)
   {
      Print("[CTradeExecutor] Addon rejected: no position exists");
      return false;
   }
   
   if(m_addonCount >= 3)
   {
      Print("[CTradeExecutor] Addon rejected: max 3 reached");
      return false;
   }
   
   m_symInfo.RefreshRates();
   double ask = m_symInfo.Ask();
   if(ask <= 0) ask = price;
   
   // Calculate base lot using pyramid worst-case formula
   double baseLots = CalcPyramidBaseLot(m_firstEntryATR);
   
   // Decreasing pyramid: lot_ratio^n (0.50^1, 0.50^2, 0.50^3)
   double addonMult = MathPow(m_lotRatio, m_addonCount + 1);
   double addonLots = NormalizeLots(baseLots * addonMult);
   
   // Minimum lot check
   double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   if(addonLots < minLot) addonLots = minLot;
   
   // Use 1st entry's emergency SL for all addons
   double emergencySLPrice = m_firstEntryPrice - m_firstEntryATR * m_emergencySLMult;
   
   string comment = StringFormat("AI_Addon%d|ATR=%.2f", m_addonCount + 1, atr);
   if(!SendOrder(addonLots, emergencySLPrice, comment))
      return false;
   
   m_addonCount++;
   m_lastEntryBar = m_currentBar;
   
   Print("[CTradeExecutor] ADDON ", m_addonCount, " executed: price=",
         DoubleToString(ask, 2),
         " lots=", DoubleToString(addonLots, 2),
         " (", DoubleToString(multipliers[m_addonCount - 1] * 100, 0), "% of base)");
   
   // Update persisted state
   SaveState();
   
   return true;
}

//+------------------------------------------------------------------+
//| Check virtual stops — call EVERY TICK                            |
//| Returns true if positions were closed                            |
//| Long: uses Bid for evaluation. Override for Short (use Ask).     |
//+------------------------------------------------------------------+
bool CTradeExecutor::CheckVirtualStops(double currentPrice)
{
   if(!m_hasPosition)
      return false;
   
   // Check Virtual SL (loss cut)
   if(m_virtualSL > 0 && currentPrice <= m_virtualSL)
   {
      Print("[CTradeExecutor] VIRTUAL SL HIT: price=", DoubleToString(currentPrice, 2),
            " <= SL=", DoubleToString(m_virtualSL, 2));
      CloseAll("Virtual SL hit");
      return true;
   }
   
   // Check CE2 trailing (profit protection)
   if(m_ce2Active && m_virtualCE2 > 0 && currentPrice <= m_virtualCE2)
   {
      Print("[CTradeExecutor] CE2 TRAILING HIT: price=", DoubleToString(currentPrice, 2),
            " <= CE2=", DoubleToString(m_virtualCE2, 2));
      CloseAll("CE2 trailing hit");
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Update CE2 trailing stop value                                   |
//| ce2Value: Chandelier Exit level from indicator                   |
//| unrealizedATR: current profit in ATR units                       |
//| minTPATR: minimum profit to activate CE2 (default: 4.0)         |
//+------------------------------------------------------------------+
void CTradeExecutor::UpdateCE2(double ce2Value, double unrealizedATR,
                               double minTPATR)
{
   if(!m_hasPosition)
      return;
   
   if(unrealizedATR < minTPATR)
   {
      // Profit too small → reset CE2 (wait for next wave)
      if(m_ce2Active)
      {
         Print("[CTradeExecutor] CE2 reset: profit=", 
               DoubleToString(unrealizedATR, 1), "ATR < min=",
               DoubleToString(minTPATR, 1));
      }
      m_ce2Active = false;
      m_virtualCE2 = 0;
      return;
   }
   
   // Activate or update CE2 (ratchet — only moves up)
   if(!m_ce2Active)
   {
      m_ce2Active = true;
      m_virtualCE2 = ce2Value;
      Print("[CTradeExecutor] CE2 activated: level=", 
            DoubleToString(m_virtualCE2, 2),
            " profit=", DoubleToString(unrealizedATR, 1), "ATR");
   }
   else if(ce2Value > m_virtualCE2)
   {
      m_virtualCE2 = ce2Value;  // Ratchet up only
   }
}

//+------------------------------------------------------------------+
//| Get unrealized PnL in ATR units                                  |
//| Long: (Bid - entryPrice) / ATR. Override for Short.              |
//+------------------------------------------------------------------+
double CTradeExecutor::GetUnrealizedATR() const
{
   if(!m_hasPosition || m_firstEntryATR <= 0)
      return 0;
   
   double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   return (bid - m_firstEntryPrice) / m_firstEntryATR;
}

//+------------------------------------------------------------------+
//| Get bars since first entry                                       |
//+------------------------------------------------------------------+
int CTradeExecutor::GetBarsSinceEntry() const
{
   if(!m_hasPosition)
      return 0;
   return m_currentBar - m_firstEntryBar;
}

//+------------------------------------------------------------------+
//| Get bars since last entry/addon                                  |
//+------------------------------------------------------------------+
int CTradeExecutor::GetBarsSinceLastEntry() const
{
   if(!m_hasPosition)
      return 0;
   return m_currentBar - m_lastEntryBar;
}

//+------------------------------------------------------------------+
//| Close all positions managed by this executor                     |
//+------------------------------------------------------------------+
bool CTradeExecutor::CloseAll(string reason)
{
   bool allClosed = true;
   int total = PositionsTotal();
   
   for(int i = total - 1; i >= 0; i--)
   {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      
      if(m_posInfo.Magic() != (long)m_magic)
         continue;
      
      if(m_posInfo.Symbol() != m_symbol)
         continue;
      
      ulong ticket = m_posInfo.Ticket();
      if(!m_trade.PositionClose(ticket, 30))
      {
         Print("[CTradeExecutor] Close failed: ticket=", ticket,
               " error=", GetLastError());
         allClosed = false;
      }
      else
      {
         Print("[CTradeExecutor] Closed: ticket=", ticket,
               " reason=", reason);
      }
   }
   
   if(allClosed)
   {
      ClearState();  // Remove persisted GlobalVariables
      Reset();
   }
   
   return allClosed;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk and SL points (legacy)          |
//| Adapted from MoneyManageV9.CalculateLotSize()                    |
//+------------------------------------------------------------------+
double CTradeExecutor::CalcLotSize(double slPoints)
{
   if(slPoints <= 0) return 0;
   
   double capital = AccountInfoDouble(ACCOUNT_BALANCE);
   double moneyRisk = m_riskPercent * capital;
   
   double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   double point     = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   
   if(tickValue <= 0 || point <= 0)
   {
      Print("[CTradeExecutor] CalcLotSize error: tickValue=", tickValue,
            " point=", point);
      return 0;
   }
   
   // Convert SL from points to ticks
   double slInTicks = slPoints * point / tickSize;
   
   // Lot = risk_money / (SL_ticks * tick_value)
   double lots = moneyRisk / (slInTicks * tickValue);
   
   // Margin check
   double marginForOne = 0;
   if(OrderCalcMargin(ORDER_TYPE_BUY, m_symbol, 1,
                      SymbolInfoDouble(m_symbol, SYMBOL_ASK), marginForOne))
   {
      double maxByMargin = capital * 0.98 / marginForOne;
      lots = MathMin(lots, maxByMargin);
   }
   
   lots = NormalizeLots(lots);
   lots = MathMax(lots, SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN));
   lots = MathMin(lots, SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX));
   
   return lots;
}

//+------------------------------------------------------------------+
//| Calculate base lot for pyramiding with worst-case 1% risk        |
//| Formula from Pyramiding.md §랏사이즈 공식:                       |
//|                                                                  |
//|   worst_case_ATR_lots = SL_mult × 1.0                           |
//|     + Σ (SL_mult + spacing × n) × lot_ratio^n  (n=1..maxAddon)  |
//|                                                                  |
//|   base_lot = (Balance × risk%) /                                 |
//|              (worst_case_ATR_lots × ATR14 × contract_size)       |
//|                                                                  |
//| With defaults (SL=7, addon=3, ratio=0.50, spacing=1.5):         |
//|   worst_case = 7×1 + 8.5×0.5 + 10×0.25 + 11.5×0.125 = 15.188  |
//|                                                                  |
//| This ensures total group loss = exactly risk% when ALL positions |
//| (base + all addons) hit the original SL simultaneously.          |
//+------------------------------------------------------------------+
double CTradeExecutor::CalcPyramidBaseLot(double atr)
{
   if(atr <= 0)
   {
      Print("[CTradeExecutor] CalcPyramidBaseLot: invalid ATR=", atr);
      return 0;
   }
   
   //--- Step 1: Calculate worst-case ATR-lots
   double worstCase = m_slATRMult * 1.0;  // Base position
   for(int n = 1; n <= m_maxAddon; n++)
   {
      double slDistance = m_slATRMult + m_spacingATR * n;
      double lotMult    = MathPow(m_lotRatio, n);
      worstCase        += slDistance * lotMult;
   }
   
   //--- Step 2: Calculate base lot
   double balance      = AccountInfoDouble(ACCOUNT_BALANCE);
   double contractSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   
   if(contractSize <= 0)
   {
      Print("[CTradeExecutor] CalcPyramidBaseLot: contractSize=", contractSize);
      return 0;
   }
   
   double rawLot = (balance * m_riskPercent) / (worstCase * atr * contractSize);
   
   //--- Step 3: Margin check
   double marginForOne = 0;
   if(OrderCalcMargin(ORDER_TYPE_BUY, m_symbol, 1,
                      SymbolInfoDouble(m_symbol, SYMBOL_ASK), marginForOne))
   {
      if(marginForOne > 0)
      {
         double maxByMargin = balance * 0.98 / marginForOne;
         rawLot = MathMin(rawLot, maxByMargin);
      }
   }
   
   //--- Step 4: Broker constraints
   rawLot = NormalizeLots(rawLot);
   rawLot = MathMax(rawLot, SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN));
   rawLot = MathMin(rawLot, SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX));
   
   Print("[CTradeExecutor] PyramidLot: ATR=", DoubleToString(atr, 2),
         " worstCase=", DoubleToString(worstCase, 3),
         " baseLot=", DoubleToString(rawLot, 2),
         " bal=", DoubleToString(balance, 0));
   
   return rawLot;
}

//+------------------------------------------------------------------+
//| Normalize lots to broker step                                    |
//+------------------------------------------------------------------+
double CTradeExecutor::NormalizeLots(double lots)
{
   double step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   return MathFloor(lots / step) * step;
}

//+------------------------------------------------------------------+
//| Send order with SL (Long: Buy). Override for Short (Sell).       |
//+------------------------------------------------------------------+
bool CTradeExecutor::SendOrder(double lots, double sl, string comment)
{
   m_symInfo.RefreshRates();
   double ask = m_symInfo.Ask();
   
   // Normalize SL to tick size
   double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   sl = MathFloor(sl / tickSize) * tickSize;
   
   if(!m_trade.Buy(lots, m_symbol, ask, sl, 0, comment))
   {
      Print("[CTradeExecutor] OrderSend FAILED: error=", GetLastError(),
            " lots=", DoubleToString(lots, 2),
            " ask=", DoubleToString(ask, 2),
            " sl=", DoubleToString(sl, 2));
      
      // Retry once
      Sleep(500);
      m_symInfo.RefreshRates();
      ask = m_symInfo.Ask();
      
      if(!m_trade.Buy(lots, m_symbol, ask, sl, 0, comment + " [retry]"))
      {
         Print("[CTradeExecutor] OrderSend RETRY FAILED: error=", GetLastError());
         return false;
      }
   }
   
   // Record position
   ulong ticket = m_trade.ResultDeal();
   if(ticket == 0) ticket = m_trade.ResultOrder();
   
   RecordPosition(ticket, ask, lots, m_hasPosition ? (m_addonCount + 1) : 0);
   
   return true;
}

//+------------------------------------------------------------------+
//| Record position in internal tracking array                       |
//+------------------------------------------------------------------+
void CTradeExecutor::RecordPosition(ulong ticket, double price,
                                    double lots, int type)
{
   if(m_posCount >= EXEC_MAX_POSITIONS)
   {
      Print("[CTradeExecutor] CRITICAL: position tracking array full!");
      return;
   }
   
   m_positions[m_posCount].ticket    = ticket;
   m_positions[m_posCount].openPrice = price;
   m_positions[m_posCount].lots      = lots;
   m_positions[m_posCount].type      = type;
   m_positions[m_posCount].openBar   = m_currentBar;
   m_positions[m_posCount].openTime  = TimeCurrent();
   m_posCount++;
}

//+------------------------------------------------------------------+
//| Reset all state — call when all positions closed                 |
//+------------------------------------------------------------------+
void CTradeExecutor::Reset()
{
   m_posCount        = 0;
   m_addonCount      = 0;
   m_firstEntryPrice = 0;
   m_firstEntryATR   = 0;
   m_firstEntryBar   = 0;
   m_lastEntryBar    = 0;
   m_virtualSL       = 0;
   m_virtualCE2      = 0;
   m_ce2Active       = false;
   m_hasPosition     = false;
}

//+------------------------------------------------------------------+
//| Build GlobalVariable key name                                    |
//+------------------------------------------------------------------+
string CTradeExecutor::GVKey(string suffix)
{
   return StringFormat("AI_%d_%s_%s", (int)m_magic, m_symbol, suffix);
}

//+------------------------------------------------------------------+
//| Save critical state to GlobalVariable (disk persistent)          |
//| Called after ExecuteEntry() and ExecuteAddon()                   |
//+------------------------------------------------------------------+
void CTradeExecutor::SaveState()
{
   GlobalVariableSet(GVKey("EntryATR"),   m_firstEntryATR);
   GlobalVariableSet(GVKey("EntryPrice"), m_firstEntryPrice);
   GlobalVariableSet(GVKey("VirtualSL"),  m_virtualSL);
   GlobalVariableSet(GVKey("AddonCount"), (double)m_addonCount);
   GlobalVariableSet(GVKey("BSPScale"),   m_firstEntryBSPScale);
   
   Print("[CTradeExecutor] State saved to GV: ATR=",
         DoubleToString(m_firstEntryATR, 2),
         " Price=", DoubleToString(m_firstEntryPrice, 2),
         " SL=", DoubleToString(m_virtualSL, 2),
         " Addons=", m_addonCount,
         " BSPScale=", DoubleToString(m_firstEntryBSPScale, 2));
}

//+------------------------------------------------------------------+
//| Clear GlobalVariable state (called on CloseAll)                  |
//+------------------------------------------------------------------+
void CTradeExecutor::ClearState()
{
   GlobalVariableDel(GVKey("EntryATR"));
   GlobalVariableDel(GVKey("EntryPrice"));
   GlobalVariableDel(GVKey("VirtualSL"));
   GlobalVariableDel(GVKey("AddonCount"));
   GlobalVariableDel(GVKey("BSPScale"));
   
   Print("[CTradeExecutor] GV state cleared");
}

//+------------------------------------------------------------------+
//| RestoreAndRecover — EA 재시작 시 포지션 복구 + CE2 즉시 판단     |
//| ★ 이 함수는 웜업 완료를 기다리지 않고 즉시 실행됨               |
//| Returns true if recovery was performed (position found)          |
//+------------------------------------------------------------------+
bool CTradeExecutor::RestoreAndRecover(int ceHandle)
{
   m_ceHandle = ceHandle;
   
   //--- 1. Scan for existing positions with same Magic+Symbol
   bool posFound = false;
   int total = PositionsTotal();
   
   for(int i = 0; i < total; i++)
   {
      if(!m_posInfo.SelectByIndex(i)) continue;
      if(m_posInfo.Magic() != (long)m_magic) continue;
      if(m_posInfo.Symbol() != m_symbol) continue;
      
      posFound = true;
      break;
   }
   
   if(!posFound)
   {
      // No position → clean start
      ClearState();  // Remove any orphaned GV keys
      Reset();
      Print("[CTradeExecutor] Recovery: No position found → clean start");
      return false;
   }
   
   //--- 2. Position exists → restore state from GlobalVariable
   Print("[CTradeExecutor] Recovery: Position found, restoring state...");
   
   if(!GlobalVariableCheck(GVKey("EntryATR")))
   {
      Print("[CTradeExecutor] CRITICAL: Position exists but no GV state!",
            " Using emergency SL only.");
      m_hasPosition = true;
      // Cannot restore — rely on broker emergency SL
      return true;
   }
   
   m_firstEntryATR      = GlobalVariableGet(GVKey("EntryATR"));
   m_firstEntryPrice    = GlobalVariableGet(GVKey("EntryPrice"));
   m_virtualSL          = GlobalVariableGet(GVKey("VirtualSL"));
   m_addonCount         = (int)GlobalVariableGet(GVKey("AddonCount"));
   
   if(GlobalVariableCheck(GVKey("BSPScale")))
      m_firstEntryBSPScale = GlobalVariableGet(GVKey("BSPScale"));
   else
      m_firstEntryBSPScale = 0;
      
   m_hasPosition        = true;
   
   Print("[CTradeExecutor] GV restored: ATR=",
         DoubleToString(m_firstEntryATR, 2),
         " Price=", DoubleToString(m_firstEntryPrice, 2),
         " SL=", DoubleToString(m_virtualSL, 2),
         " Addons=", m_addonCount,
         " BSPScale=", DoubleToString(m_firstEntryBSPScale, 2));
   
   //--- 3. Immediate CE2 judgment (웜업 불필요 — CE2는 가격 OHLC 기반)
   m_symInfo.RefreshRates();
   double bid = m_symInfo.Bid();
   
   // Read CE2 value (UplBuffer2 = ATR*4.5 trailing) from indicator
   double ce2 = 0;
   if(m_ceHandle != INVALID_HANDLE)
   {
      double buf[1];
      if(CopyBuffer(m_ceHandle, 2, 1, 1, buf) > 0)  // buf 2 = Upl2 (SL2)
      {
         if(buf[0] != EMPTY_VALUE && MathIsValidNumber(buf[0]))
            ce2 = buf[0];
      }
   }
   
   //--- CASE 1: bid ≤ virtualSL → 즉시 전체 청산 (손절)
   if(m_virtualSL > 0 && bid <= m_virtualSL)
   {
      Print("[CTradeExecutor] Recovery CASE 1: bid=", DoubleToString(bid, 2),
            " ≤ SL=", DoubleToString(m_virtualSL, 2), " → CloseAll");
      CloseAll("Recovery: below Virtual SL");
      return true;
   }
   
   //--- CASE 2: bid ≤ ce2 → 추세 이탈, 즉시 전체 청산
   if(ce2 > 0 && bid <= ce2)
   {
      Print("[CTradeExecutor] Recovery CASE 2: bid=", DoubleToString(bid, 2),
            " ≤ CE2=", DoubleToString(ce2, 2), " → CloseAll (trend broken)");
      CloseAll("Recovery: price below CE2");
      return true;
   }
   
   //--- CASE 3: bid > ce2 → 상승추세 유지, CE2를 새 래칫 기준으로 설정
   if(ce2 > 0)
   {
      m_virtualCE2 = ce2;
      m_ce2Active  = true;
      Print("[CTradeExecutor] Recovery CASE 3: bid=", DoubleToString(bid, 2),
            " > CE2=", DoubleToString(ce2, 2), " → HOLD, CE2 ratchet set");
   }
   else
   {
      Print("[CTradeExecutor] Recovery: CE2 not available, relying on Virtual SL only");
   }
   
   // Rebuild position tracking array
   m_posCount = 0;
   for(int i = 0; i < total; i++)
   {
      if(!m_posInfo.SelectByIndex(i)) continue;
      if(m_posInfo.Magic() != (long)m_magic) continue;
      if(m_posInfo.Symbol() != m_symbol) continue;
      
      if(m_posCount < EXEC_MAX_POSITIONS)
      {
         m_positions[m_posCount].ticket    = m_posInfo.Ticket();
         m_positions[m_posCount].openPrice = m_posInfo.PriceOpen();
         m_positions[m_posCount].lots      = m_posInfo.Volume();
         m_positions[m_posCount].type      = m_posCount;  // approximate
         m_positions[m_posCount].openBar   = 0;            // unknown after restart
         m_positions[m_posCount].openTime  = m_posInfo.Time();
         m_posCount++;
      }
   }
   
   Print("[CTradeExecutor] Recovery complete: ", m_posCount,
         " positions tracked, CE2Active=", m_ce2Active);
   
   return true;
}

#endif // __CTRADEEXECUTOR_MQH__
