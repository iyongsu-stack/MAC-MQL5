//+------------------------------------------------------------------+
//| CDashboard.mqh — Chart dashboard panel (Comment-based)           |
//| Phase 3-1 | AIEngine Module                                      |
//|                                                                  |
//| Displays EA status, position, AI, performance, and settings      |
//| on chart using Comment(). MagicNumber shown in header.           |
//|                                                                  |
//| Usage:                                                           |
//|   CDashboard dash;                                               |
//|   dash.Init(100001, "XAUUSD");                                   |
//|   dash.SetSystemState(...);                                      |
//|   dash.Render();                                                 |
//+------------------------------------------------------------------+
#ifndef __CDASHBOARD_MQH__
#define __CDASHBOARD_MQH__

//+------------------------------------------------------------------+
//| CDashboard class                                                 |
//+------------------------------------------------------------------+
class CDashboard
{
private:
   int            m_magicNumber;
   string         m_symbol;
   
   //--- System section
   string         m_eaState;           // "Active" / "Warm-up" / "Stopped"
   string         m_pythonState;       // "Alive" / "Down"
   string         m_brokerState;       // "Connected" / "Disconnected"
   string         m_macroInfo;         // "✅ 2h전" / "⚠️ 3일"
   string         m_eventInfo;         // "✅ 정상" / "🚫 NFP 2h후"
   
   //--- Position section
   bool           m_hasPosition;
   double         m_entryPrice;
   double         m_totalLot;
   int            m_addonCount;
   double         m_unrealizedPnL;     // $ amount
   double         m_unrealizedATR;     // ATR multiplier
   double         m_virtualSL;
   double         m_virtualCE2;
   
   //--- AI section
   double         m_probEntry;
   double         m_probAddon;
   int            m_warmupCurrent;
   int            m_warmupTotal;
   bool           m_warmupReady;
   
   //--- Performance section
   double         m_pnlToday;
   double         m_pnlMonth;
   int            m_totalTrades;
   int            m_winTrades;
   double         m_profitFactor;
   double         m_maxDD;
   
   //--- Config section
   double         m_riskPercent;
   double         m_riskAmount;
   int            m_maxPyramiding;
   bool           m_useEventFilter;
   
   //--- Internal helpers
   string         BuildSystemSection();
   string         BuildPositionSection();
   string         BuildAISection();
   string         BuildPerformanceSection();
   string         BuildConfigSection();
   string         BuildWarmupBar(int current, int total);
   string         StateEmoji(string state);
   
public:
                  CDashboard();
                 ~CDashboard();
   
   //--- Initialization
   bool           Init(int magic, string symbol);
   void           Deinit();
   
   //--- Data setters (called by EA before Render)
   void           SetSystemState(string ea, string python,
                                 string broker, string macro,
                                 string eventInfo);
   
   void           SetPosition(bool has, double entry, double lot,
                              int addon, double pnl, double atrMult,
                              double sl, double ce2);
   
   void           SetAI(double probE, double probA,
                        int wCur, int wTotal, bool ready);
   
   void           SetPerformance(double today, double month,
                                 int total, int wins,
                                 double pf, double mdd);
   
   void           SetConfig(double riskPct, double riskAmt,
                            int maxPyr, bool eventFilter);
   
   //--- Render to chart
   void           Render();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDashboard::CDashboard()
   : m_magicNumber(0), m_hasPosition(false),
     m_entryPrice(0), m_totalLot(0), m_addonCount(0),
     m_unrealizedPnL(0), m_unrealizedATR(0),
     m_virtualSL(0), m_virtualCE2(0),
     m_probEntry(0), m_probAddon(0),
     m_warmupCurrent(0), m_warmupTotal(240), m_warmupReady(false),
     m_pnlToday(0), m_pnlMonth(0),
     m_totalTrades(0), m_winTrades(0),
     m_profitFactor(0), m_maxDD(0),
     m_riskPercent(1.0), m_riskAmount(0),
     m_maxPyramiding(3), m_useEventFilter(false)
{
   m_eaState      = "Init";
   m_pythonState  = "---";
   m_brokerState  = "---";
   m_macroInfo    = "---";
   m_eventInfo    = "---";
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDashboard::~CDashboard()
{
   Deinit();
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CDashboard::Init(int magic, string symbol)
{
   m_magicNumber = magic;
   m_symbol      = symbol;
   
   Print("[CDashboard] Init: MN=", m_magicNumber, " symbol=", m_symbol);
   return true;
}

//+------------------------------------------------------------------+
//| Cleanup — clear Comment                                          |
//+------------------------------------------------------------------+
void CDashboard::Deinit()
{
   Comment("");
}

//+------------------------------------------------------------------+
//| Set system status data                                           |
//+------------------------------------------------------------------+
void CDashboard::SetSystemState(string ea, string python,
                                string broker, string macro,
                                string eventInfo)
{
   m_eaState     = ea;
   m_pythonState = python;
   m_brokerState = broker;
   m_macroInfo   = macro;
   m_eventInfo   = eventInfo;
}

//+------------------------------------------------------------------+
//| Set position data                                                |
//+------------------------------------------------------------------+
void CDashboard::SetPosition(bool has, double entry, double lot,
                             int addon, double pnl, double atrMult,
                             double sl, double ce2)
{
   m_hasPosition    = has;
   m_entryPrice     = entry;
   m_totalLot       = lot;
   m_addonCount     = addon;
   m_unrealizedPnL  = pnl;
   m_unrealizedATR  = atrMult;
   m_virtualSL      = sl;
   m_virtualCE2     = ce2;
}

//+------------------------------------------------------------------+
//| Set AI model data                                                |
//+------------------------------------------------------------------+
void CDashboard::SetAI(double probE, double probA,
                       int wCur, int wTotal, bool ready)
{
   m_probEntry     = probE;
   m_probAddon     = probA;
   m_warmupCurrent = wCur;
   m_warmupTotal   = wTotal;
   m_warmupReady   = ready;
}

//+------------------------------------------------------------------+
//| Set performance data                                             |
//+------------------------------------------------------------------+
void CDashboard::SetPerformance(double today, double month,
                                int total, int wins,
                                double pf, double mdd)
{
   m_pnlToday     = today;
   m_pnlMonth     = month;
   m_totalTrades  = total;
   m_winTrades    = wins;
   m_profitFactor = pf;
   m_maxDD        = mdd;
}

//+------------------------------------------------------------------+
//| Set configuration data                                           |
//+------------------------------------------------------------------+
void CDashboard::SetConfig(double riskPct, double riskAmt,
                           int maxPyr, bool eventFilter)
{
   m_riskPercent    = riskPct;
   m_riskAmount     = riskAmt;
   m_maxPyramiding  = maxPyr;
   m_useEventFilter = eventFilter;
}

//+------------------------------------------------------------------+
//| Render dashboard to chart via Comment()                          |
//+------------------------------------------------------------------+
void CDashboard::Render()
{
   string sep = "----------------------------------------";
   
   string text = "";
   text += "    BSP Long v1.0 [MN:" + IntegerToString(m_magicNumber) + "]\n";
   text += sep + "\n";
   text += BuildSystemSection();
   text += sep + "\n";
   text += BuildPositionSection();
   text += sep + "\n";
   text += BuildAISection();
   text += sep + "\n";
   text += BuildPerformanceSection();
   text += sep + "\n";
   text += BuildConfigSection();
   
   Comment(text);
}

//+------------------------------------------------------------------+
//| Build system status section                                      |
//+------------------------------------------------------------------+
string CDashboard::BuildSystemSection()
{
   string s = " [System]\n";
   s += "  EA: " + StateEmoji(m_eaState) + " " + m_eaState;
   s += "  Python: " + StateEmoji(m_pythonState);
   s += "  Broker: " + StateEmoji(m_brokerState) + "\n";
   s += "  Macro: " + m_macroInfo + "\n";
   s += "  Event: " + m_eventInfo + "\n";
   return s;
}

//+------------------------------------------------------------------+
//| Build position section                                           |
//+------------------------------------------------------------------+
string CDashboard::BuildPositionSection()
{
   string s = " [Position]\n";
   
   if(!m_hasPosition)
   {
      s += "  -- No Position -- Waiting for signal\n";
      return s;
   }
   
   s += "  LONG  $" + DoubleToString(m_entryPrice, 2)
      + "  Lot " + DoubleToString(m_totalLot, 2)
      + " (AddOn " + IntegerToString(m_addonCount) + "/3)\n";
   
   string pnlSign = (m_unrealizedPnL >= 0) ? "+" : "";
   s += "  Unrealized: " + pnlSign + "$" + DoubleToString(m_unrealizedPnL, 2)
      + " (" + pnlSign + DoubleToString(m_unrealizedATR, 1) + " ATR)\n";
   
   s += "  SL: $" + DoubleToString(m_virtualSL, 2);
   if(m_virtualCE2 > 0)
      s += "  CE2: $" + DoubleToString(m_virtualCE2, 2);
   s += "\n";
   
   return s;
}

//+------------------------------------------------------------------+
//| Build AI model section                                           |
//+------------------------------------------------------------------+
string CDashboard::BuildAISection()
{
   string s = " [AI Model]\n";
   
   if(m_warmupReady)
   {
      s += "  Entry: prob=" + DoubleToString(m_probEntry, 4)
         + "   AddOn: prob=" + DoubleToString(m_probAddon, 4) + "\n";
      s += "  Warm-up: " + BuildWarmupBar(m_warmupCurrent, m_warmupTotal)
         + " READY\n";
   }
   else
   {
      s += "  Entry: ---    AddOn: ---\n";
      s += "  Warm-up: " + BuildWarmupBar(m_warmupCurrent, m_warmupTotal);
      
      int remaining = m_warmupTotal - m_warmupCurrent;
      if(remaining > 0)
         s += " ~" + IntegerToString(remaining) + " bars left";
      s += "\n";
   }
   
   return s;
}

//+------------------------------------------------------------------+
//| Build performance section                                        |
//+------------------------------------------------------------------+
string CDashboard::BuildPerformanceSection()
{
   string s = " [Performance]\n";
   
   string todaySign = (m_pnlToday >= 0) ? "+" : "";
   string monthSign = (m_pnlMonth >= 0) ? "+" : "";
   
   s += "  Today: " + todaySign + "$" + DoubleToString(m_pnlToday, 2)
      + "  Month: " + monthSign + "$" + DoubleToString(m_pnlMonth, 2) + "\n";
   
   if(m_totalTrades > 0)
   {
      double winRate = (m_totalTrades > 0)
                       ? ((double)m_winTrades / m_totalTrades * 100.0)
                       : 0;
      s += "  WinRate " + DoubleToString(winRate, 1) + "%"
         + " (" + IntegerToString(m_winTrades) + "/" + IntegerToString(m_totalTrades) + ")"
         + "  PF " + DoubleToString(m_profitFactor, 2)
         + "  MDD -" + DoubleToString(m_maxDD, 1) + "%\n";
   }
   else
   {
      s += "  WinRate ---% (0/0)  PF ---  MDD ---\n";
   }
   
   return s;
}

//+------------------------------------------------------------------+
//| Build config section                                             |
//+------------------------------------------------------------------+
string CDashboard::BuildConfigSection()
{
   string s = " [Config]\n";
   s += "  Risk: " + DoubleToString(m_riskPercent, 1) + "%"
      + " ($" + DoubleToString(m_riskAmount, 2) + ")"
      + "  Pyramid: " + IntegerToString(m_maxPyramiding) + "x\n";
   s += "  EventFilter: " + (m_useEventFilter ? "ON" : "OFF") + "\n";
   return s;
}

//+------------------------------------------------------------------+
//| Build progress bar: ████████░░ 192/240 (80%)                    |
//+------------------------------------------------------------------+
string CDashboard::BuildWarmupBar(int current, int total)
{
   if(total <= 0) total = 240;
   
   int pct = (int)MathRound((double)current / total * 100.0);
   pct = MathMin(pct, 100);
   
   // Build text bar (10 segments)
   int filled = pct / 10;
   string bar = "";
   for(int i = 0; i < 10; i++)
   {
      bar += (i < filled) ? "|" : ".";
   }
   
   return "[" + bar + "] "
        + IntegerToString(current) + "/" + IntegerToString(total)
        + " (" + IntegerToString(pct) + "%)";
}

//+------------------------------------------------------------------+
//| Get emoji/marker for state                                       |
//+------------------------------------------------------------------+
string CDashboard::StateEmoji(string state)
{
   // Comment() has limited Unicode support, use text markers
   if(state == "Active" || state == "Alive" || state == "Connected")
      return "[OK]";
   if(state == "Warm-up")
      return "[~~]";
   if(state == "Stopped" || state == "Down" || state == "Disconnected")
      return "[!!]";
   return "[??]";
}

#endif // __CDASHBOARD_MQH__
