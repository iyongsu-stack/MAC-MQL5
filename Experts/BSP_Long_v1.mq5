//+------------------------------------------------------------------+
//| BSP_Long_v1.mq5 — AI Long Strategy Main EA                      |
//| Phase 3-3 | Integration EA                                       |
//|                                                                  |
//| Integrates all AIEngine modules:                                 |
//|   Phase 0: FeatureSchema                                         |
//|   Phase 1: CRollingStats, CMacroLoader, COnnxPredictor,          |
//|            CEventFilter                                          |
//|   Phase 2: CFeatureEngine, CSignalGenerator, CTradeExecutor      |
//|   Phase 3: CTradeLogger, CDashboard                              |
//|                                                                  |
//| Architecture:                                                    |
//|   OnInit  → Module init → MagicNumber lock → Recovery            |
//|   OnTick  → New bar check → Feature update → Signal →            |
//|             Trade → Log → Dashboard                              |
//|   OnDeinit → Cleanup                                             |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "BSP Long v1.0 — AI-driven XAUUSD Long Strategy"
#property description "Entry: AI A+B+C model | Pyramiding: AI Addon model"
#property description "Exit: CE2 Trailing Stop (Chandelier Exit)"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
//--- Identity
input int      InpMagicNumber   = 100001;    // MagicNumber (Long: 10000x)

//--- Risk Management
input double   InpRiskPercent   = 1.0;       // Risk % per trade
input double   InpSLMultiplier  = 7.0;       // SL = ATR × N (virtual)
input double   InpEmergencySL   = 12.0;      // Emergency SL = ATR × N (broker)

//--- AI Model Thresholds
input double   InpEntryThreshold = 0.20;     // Entry model threshold
input double   InpAddonThreshold = 0.40;     // Addon model threshold

//--- Pyramiding
input int      InpMaxPyramiding  = 3;        // Max addon count
input int      InpMinBarsGap     = 5;        // Min bars between addons
input double   InpMinProfitATR   = 1.5;      // Min unrealized profit (ATR)

//--- CE2 Trailing Stop
input double   InpCE2MinTPATR   = 4.0;       // CE2 activation threshold (ATR)

//--- Model Paths
input string   InpEntryModel    = "models/model_long_ABC.onnx";   // Entry ONNX
input string   InpAddonModel    = "models/model_addon_ABC.onnx";  // Addon ONNX

//--- Data Paths
input string   InpMacroCSV      = "live/macro_latest.csv";     // Macro features CSV
input string   InpEventCSV      = "live/event_calendar.csv";   // Event calendar CSV

//--- Server Settings
input int      InpServerGMT     = 2;         // Broker server GMT offset

//--- Event Filter Toggle
input bool     InpUseEventFilter = true;     // Enable event blackout filter

//+------------------------------------------------------------------+
//| Include Modules                                                   |
//+------------------------------------------------------------------+
#include <AIEngine/FeatureSchema.mqh>
#include <AIEngine/CRollingStats.mqh>
#include <AIEngine/CMacroLoader.mqh>
#include <AIEngine/COnnxPredictor.mqh>
#include <AIEngine/CEventFilter.mqh>
#include <AIEngine/CFeatureEngine.mqh>
#include <AIEngine/CSignalGenerator.mqh>
#include <AIEngine/CTradeExecutor.mqh>
#include <AIEngine/CTradeLogger.mqh>
#include <AIEngine/CDashboard.mqh>

//+------------------------------------------------------------------+
//| Global Module Instances                                           |
//+------------------------------------------------------------------+
CMacroLoader      g_macro;
COnnxPredictor    g_entryModel;
COnnxPredictor    g_addonModel;
CEventFilter      g_events;
CFeatureEngine    g_features;
CSignalGenerator  g_signal;
CTradeExecutor    g_executor;
CTradeLogger      g_logger;
CDashboard        g_dashboard;

//--- Bar change detection
datetime          g_lastBarTime = 0;
int               g_barCount   = 0;

//--- Macro reload timer
datetime          g_lastMacroCheck = 0;

//--- Performance tracking (simple)
double            g_pnlToday   = 0;
double            g_pnlMonth   = 0;
int               g_totalTrades = 0;
int               g_winTrades   = 0;
double            g_grossProfit = 0;
double            g_grossLoss   = 0;
double            g_peakBalance = 0;
double            g_maxDD       = 0;

//--- Python heartbeat
datetime          g_lastPythonHB = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== BSP_Long_v1 INIT ===");
   Print("  MagicNumber: ", InpMagicNumber);
   Print("  Symbol: ", _Symbol);
   Print("  Period: ", EnumToString(Period()));
   
   //--- Step 1: MagicNumber duplicate lock
   string lockKey = "EA_LOCK_" + IntegerToString(InpMagicNumber) + "_" + _Symbol;
   if(GlobalVariableCheck(lockKey))
   {
      double lockVal = GlobalVariableGet(lockKey);
      if(lockVal > 0)
      {
         Alert("[BSP_Long_v1] MagicNumber ", InpMagicNumber,
               " already in use! Stopping EA.");
         return INIT_FAILED;
      }
   }
   GlobalVariableSet(lockKey, 1.0);
   
   //--- Step 2: Init Macro Loader
   if(!g_macro.Init(InpMacroCSV))
   {
      Print("[BSP_Long_v1] WARNING: Macro CSV not loaded (non-fatal)");
      // Non-fatal — macro features will be 0
   }
   
   //--- Step 3: Init ONNX Models
   if(!g_entryModel.Init(InpEntryModel, ENTRY_FEATURE_COUNT))
   {
      Print("[BSP_Long_v1] CRITICAL: Entry model load failed!");
      return INIT_FAILED;
   }
   
   if(!g_addonModel.Init(InpAddonModel, ADDON_FEATURE_COUNT))
   {
      Print("[BSP_Long_v1] CRITICAL: Addon model load failed!");
      return INIT_FAILED;
   }
   
   //--- Step 4: Init Event Filter
   if(InpUseEventFilter)
   {
      if(!g_events.Init(InpEventCSV, InpServerGMT))
         Print("[BSP_Long_v1] WARNING: Event filter not loaded");
   }
   
   //--- Step 5: Init Feature Engine (creates 22+ indicator handles)
   if(!g_features.Init(&g_macro))
   {
      Print("[BSP_Long_v1] CRITICAL: Feature engine init failed!");
      return INIT_FAILED;
   }
   
   //--- Step 6: Init Signal Generator
   g_signal.Init(InpEntryThreshold, InpAddonThreshold,
                 InpMaxPyramiding, InpMinBarsGap, InpMinProfitATR);
   
   //--- Step 7: Init Trade Executor
   if(!g_executor.Init((ulong)InpMagicNumber,
                       InpRiskPercent / 100.0,  // 1.0% → 0.01
                       InpSLMultiplier,
                       InpEmergencySL,
                       InpMaxPyramiding,         // maxAddon (3)
                       0.50,                     // lotRatio (정피라미드)
                       InpMinProfitATR))         // spacingATR (1.5)
   {
      Print("[BSP_Long_v1] CRITICAL: Trade executor init failed!");
      return INIT_FAILED;
   }
   
   //--- Step 8: Init Trade Logger
   if(!g_logger.Init(InpMagicNumber, _Symbol))
      Print("[BSP_Long_v1] WARNING: Trade logger init failed");
   
   //--- Step 9: Init Dashboard
   g_dashboard.Init(InpMagicNumber, _Symbol);
   
   //--- Step 10: EA Restart Recovery (BEFORE warm-up)
   //    Uses ChandelierExit indicator handle from CFeatureEngine
   if(g_executor.RestoreAndRecover(INVALID_HANDLE))
   {
      g_logger.LogRecovery("RESTORED",
         "Addons=" + IntegerToString(g_executor.GetAddonCount()) +
         " SL=" + DoubleToString(g_executor.GetVirtualSL(), 2));
      Print("[BSP_Long_v1] Position recovered from previous session");
   }
   
   //--- Step 11: Init performance baseline
   g_peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   //--- Step 12: Load macro for today
   g_macro.LoadForDate(TimeCurrent());
   g_lastMacroCheck = TimeCurrent();
   
   Print("=== BSP_Long_v1 INIT COMPLETE ===");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release MagicNumber lock
   string lockKey = "EA_LOCK_" + IntegerToString(InpMagicNumber) + "_" + _Symbol;
   GlobalVariableDel(lockKey);
   
   //--- Cleanup modules
   g_entryModel.Deinit();
   g_addonModel.Deinit();
   g_logger.Deinit();
   g_dashboard.Deinit();
   
   Print("=== BSP_Long_v1 DEINIT reason=", reason, " ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   //====================================================================
   // PHASE A: Every tick — Virtual Stop check (safety first)
   //====================================================================
   if(g_executor.HasPosition())
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(g_executor.CheckVirtualStops(bid))
      {
         // Position closed by SL or CE2
         OnPositionClosed("VirtualStop");
         return;
      }
   }
   
   //====================================================================
   // PHASE B: New bar processing (M1 only)
   //====================================================================
   datetime currentBarTime = iTime(_Symbol, PERIOD_M1, 0);
   if(currentBarTime == g_lastBarTime)
      return;  // Same bar — no new calculation needed
   
   g_lastBarTime = currentBarTime;
   g_barCount++;
   g_executor.SetCurrentBar(g_barCount);
   
   //--- B1: Update Feature Engine (push new bar data)
   g_features.Update();
   
   //--- B2: Periodic macro reload (every 4 hours)
   if(TimeCurrent() - g_lastMacroCheck > 4 * 3600)
   {
      g_macro.LoadForDate(TimeCurrent());
      g_lastMacroCheck = TimeCurrent();
   }
   
   //--- B3: CE2 update (every bar, if position exists)
   if(g_executor.HasPosition())
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ce2Val = g_features.GetCE2Value();
      double unrealATR = g_executor.GetUnrealizedATR();
      g_executor.UpdateCE2(ce2Val, unrealATR, InpCE2MinTPATR);
   }
   
   //====================================================================
   // PHASE C: Signal evaluation (requires warm-up complete)
   //====================================================================
   if(!g_features.IsReady())
   {
      // Still warming up — update dashboard only
      UpdateDashboard();
      return;
   }
   
   //--- C1: Build feature vectors
   float entryFeats[];
   g_features.GetEntryFeatures(entryFeats);
   
   float addonFeats[];
   if(g_executor.HasPosition())
   {
      double unrealATR = g_executor.GetUnrealizedATR();
      int barsSince = g_executor.GetBarsSinceEntry();
      
      // Dynamic features for Addon model
      double atrExpansion  = (g_executor.GetEntryATR() > 0)
                             ? g_features.GetATR14() / g_executor.GetEntryATR()
                             : 1.0;
      double bspScaleDelta = g_features.GetBSPScale() - g_executor.GetEntryBSPScale();
      double trendAccel    = g_features.GetBSPScaleSlope5();
      
      g_features.GetAddonFeatures(addonFeats,
                                   g_executor.GetAddonCount(),
                                   unrealATR, barsSince,
                                   atrExpansion, bspScaleDelta, trendAccel);
   }
   
   //--- C2: Run ONNX inference
   double probEntry = g_entryModel.Predict(entryFeats);
   double probAddon = (g_executor.HasPosition() && ArraySize(addonFeats) > 0)
                      ? g_addonModel.Predict(addonFeats)
                      : -1.0;
   
   //--- C3: Check event blackout
   bool isBlackout = false;
   if(InpUseEventFilter && g_events.IsLoaded())
      isBlackout = g_events.IsBlackout(TimeCurrent());
   
   //--- C4: Generate signal
   ENUM_SIGNAL signal = g_signal.Evaluate(
      probEntry, probAddon,
      g_executor.HasPosition(),
      g_executor.GetAddonCount(),
      g_executor.HasPosition()
         ? g_executor.GetUnrealizedATR()
         : 0.0,
      g_executor.GetBarsSinceLastEntry(),
      isBlackout,
      g_features.IsReady()
   );
   
   //====================================================================
   // PHASE D: Trade execution
   //====================================================================
   double atr = g_features.GetATR14();
   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   if(signal == SIGNAL_ENTRY)
   {
      if(g_executor.ExecuteEntry(atr, price))
      {
         // Store BSPScale at entry for addon delta calculation
         g_executor.SetEntryBSPScale(g_features.GetBSPScale());
         
         g_logger.LogEntry(probEntry, probAddon, atr,
                           g_executor.GetVirtualSL(),
                           0.01, // Actual lot is calculated inside executor
                           entryFeats);
         
         Print("[BSP_Long_v1] ★ ENTRY EXECUTED | prob=",
               DoubleToString(probEntry, 4));
      }
   }
   else if(signal == SIGNAL_ADDON)
   {
      int prevAddons = g_executor.GetAddonCount();
      if(g_executor.ExecuteAddon(atr, price))
      {
         double unrealATR = g_executor.GetUnrealizedATR();
         
         g_logger.LogAddon(prevAddons + 1, probAddon,
                           0.01, unrealATR, addonFeats);
         
         Print("[BSP_Long_v1] ★ ADDON ", prevAddons + 1,
               " EXECUTED | prob=", DoubleToString(probAddon, 4));
      }
   }
   
   //====================================================================
   // PHASE E: Dashboard update (every bar)
   //====================================================================
   UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Handle position close event                                      |
//+------------------------------------------------------------------+
void OnPositionClosed(string reason)
{
   // Calculate PnL from history
   double pnl = CalculateLastTradePnL();
   int holdBars = g_executor.GetBarsSinceEntry();
   
   g_logger.LogClose(reason, pnl, holdBars);
   
   // Update performance
   g_totalTrades++;
   if(pnl > 0)
   {
      g_winTrades++;
      g_grossProfit += pnl;
   }
   else
   {
      g_grossLoss += MathAbs(pnl);
   }
   
   g_pnlToday += pnl;
   g_pnlMonth += pnl;
   
   // MDD tracking
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance > g_peakBalance)
      g_peakBalance = balance;
   double dd = (g_peakBalance > 0)
               ? (g_peakBalance - balance) / g_peakBalance * 100.0
               : 0;
   if(dd > g_maxDD)
      g_maxDD = dd;
   
   // Reset signal generator
   g_signal.Reset();
   
   Print("[BSP_Long_v1] Position closed: reason=", reason,
         " PnL=", DoubleToString(pnl, 2),
         " bars=", holdBars,
         " WR=", (g_totalTrades > 0
                  ? DoubleToString((double)g_winTrades / g_totalTrades * 100, 1)
                  : "---"), "%");
}

//+------------------------------------------------------------------+
//| Calculate PnL of last closed trade(s)                            |
//+------------------------------------------------------------------+
double CalculateLastTradePnL()
{
   double pnl = 0;
   
   // Select history for today
   datetime dayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   HistorySelect(dayStart, TimeCurrent());
   
   int total = HistoryDealsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber)
         continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol)
         continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT)
         continue;
      
      pnl += HistoryDealGetDouble(ticket, DEAL_PROFIT)
           + HistoryDealGetDouble(ticket, DEAL_SWAP)
           + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
   }
   
   return pnl;
}

//+------------------------------------------------------------------+
//| Update dashboard display                                          |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   //--- System state
   string pythonState = "---";
   if(g_lastPythonHB > 0)
      pythonState = (TimeCurrent() - g_lastPythonHB < 300) ? "Alive" : "Down";
   
   string brokerState = TerminalInfoInteger(TERMINAL_CONNECTED)
                        ? "Connected" : "Disconnected";
   
   string eaState = g_features.IsReady() ? "Active" : "Warm-up";
   
   string macroInfo = g_macro.IsLoaded()
                      ? (g_macro.IsStale(3)
                         ? "Warning: " + IntegerToString(
                              (int)((TimeCurrent() - g_macro.GetLastLoadDate()) / 86400))
                           + "d stale"
                         : "OK")
                      : "Not loaded";
   
   string eventInfo = "Disabled";
   if(InpUseEventFilter && g_events.IsLoaded())
      eventInfo = g_events.GetBlackoutStatus(TimeCurrent());
   
   g_dashboard.SetSystemState(eaState, pythonState, brokerState,
                               macroInfo, eventInfo);
   
   //--- Position
   if(g_executor.HasPosition())
   {
      double unrealATR = g_executor.GetUnrealizedATR();
      
      g_dashboard.SetPosition(true,
                               g_executor.GetEntryPrice(),
                               0,  // Total lot (simplified)
                               g_executor.GetAddonCount(),
                               unrealPnL,
                               unrealATR,
                               g_executor.GetVirtualSL(),
                               g_executor.GetVirtualCE2());
   }
   else
   {
      g_dashboard.SetPosition(false, 0, 0, 0, 0, 0, 0, 0);
   }
   
   //--- AI
   double probE = g_entryModel.IsReady() ? 0 : -1;  // Will be updated after inference
   g_dashboard.SetAI(probE, -1,
                      g_features.GetWarmupBars(), 240,
                      g_features.IsReady());
   
   //--- Performance
   double pf = (g_grossLoss > 0) ? g_grossProfit / g_grossLoss : 0;
   g_dashboard.SetPerformance(g_pnlToday, g_pnlMonth,
                               g_totalTrades, g_winTrades,
                               pf, g_maxDD);
   
   //--- Config
   double riskAmt = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   g_dashboard.SetConfig(InpRiskPercent, riskAmt,
                          InpMaxPyramiding, InpUseEventFilter);
   
   //--- Render
   g_dashboard.Render();
}
//+------------------------------------------------------------------+
