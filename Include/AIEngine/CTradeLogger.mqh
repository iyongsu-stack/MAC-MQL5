//+------------------------------------------------------------------+
//| CTradeLogger.mqh — Trade decision CSV logger                     |
//| Phase 3-2 | AIEngine Module                                      |
//|                                                                  |
//| Logs all trading decisions (entry, addon, close, recovery) to    |
//| a CSV file with MagicNumber separation.                          |
//|                                                                  |
//| Usage:                                                           |
//|   CTradeLogger logger;                                           |
//|   logger.Init(100001, "XAUUSD");                                 |
//|   logger.LogEntry(probE, probA, atr, sl, lot, features);         |
//+------------------------------------------------------------------+
#ifndef __CTRADELOGGER_MQH__
#define __CTRADELOGGER_MQH__

#include "FeatureSchema.mqh"

//+------------------------------------------------------------------+
//| CTradeLogger class                                               |
//+------------------------------------------------------------------+
class CTradeLogger
{
private:
   int            m_fileHandle;       // CSV file handle (-1 = not open)
   int            m_magicNumber;      // EA magic number
   string         m_symbol;           // Symbol name
   string         m_filePath;         // Full file path
   bool           m_headerWritten;    // Header written flag
   int            m_flushCounter;     // Flush every N writes
   bool           m_ready;            // Logger initialized
   
   static const int FLUSH_INTERVAL;   // Flush every N records
   static const int TOP_FEAT_COUNT;   // Top features to log
   
   //--- Internal methods
   void           WriteHeader();
   void           WriteRow(string line);
   string         FormatTime(datetime t);
   string         FormatTopFeatures(const float &features[], int count,
                                    const string &names[]);

public:
                  CTradeLogger();
                 ~CTradeLogger();
   
   //--- Initialization
   bool           Init(int magic, string symbol);
   void           Deinit();
   
   //--- Logging methods
   void           LogEntry(double probEntry, double probAddon,
                           double atr, double sl, double lot,
                           const float &features[]);
   
   void           LogAddon(int addonNum, double probAddon,
                           double lot, double unrealizedATR,
                           const float &features[]);
   
   void           LogClose(string reason, double pnl,
                           int holdBars);
   
   void           LogRecovery(string action, string details);
   
   void           LogSkip(string reason, double probEntry,
                          double probAddon);
   
   //--- Status
   bool           IsReady() const { return m_ready; }
};

//+------------------------------------------------------------------+
//| Static constants                                                 |
//+------------------------------------------------------------------+
const int CTradeLogger::FLUSH_INTERVAL = 10;
const int CTradeLogger::TOP_FEAT_COUNT = 5;

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeLogger::CTradeLogger()
   : m_fileHandle(-1), m_magicNumber(0),
     m_headerWritten(false), m_flushCounter(0), m_ready(false)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeLogger::~CTradeLogger()
{
   Deinit();
}

//+------------------------------------------------------------------+
//| Initialize logger — open or create CSV file                      |
//+------------------------------------------------------------------+
bool CTradeLogger::Init(int magic, string symbol)
{
   m_magicNumber = magic;
   m_symbol      = symbol;
   m_ready       = false;
   
   // Build file path: trade_log_{MagicNumber}.csv
   m_filePath = "trade_log_" + IntegerToString(magic) + ".csv";
   
   // Determine file flags based on environment
   int flags = FILE_CSV | FILE_WRITE | FILE_READ | FILE_SHARE_READ | FILE_ANSI;
   
   // In Strategy Tester, use local Files/ directory
   // In live, use common Files/ directory
   if(!MQLInfoInteger(MQL_TESTER))
      flags |= FILE_COMMON;
   
   m_fileHandle = FileOpen(m_filePath, flags, ',');
   
   if(m_fileHandle == INVALID_HANDLE)
   {
      Print("[CTradeLogger] CRITICAL: FileOpen failed for ", m_filePath,
            " error=", GetLastError());
      return false;
   }
   
   // Check if file is new (empty) or existing (append)
   long fileSize = FileSize(m_fileHandle);
   
   if(fileSize <= 0)
   {
      // New file → write header
      WriteHeader();
   }
   else
   {
      // Existing file → seek to end for append
      FileSeek(m_fileHandle, 0, SEEK_END);
      m_headerWritten = true;
   }
   
   m_ready = true;
   m_flushCounter = 0;
   
   Print("[CTradeLogger] Init: file=", m_filePath,
         " magic=", m_magicNumber,
         " mode=", (MQLInfoInteger(MQL_TESTER) ? "Tester" : "Live"));
   
   return true;
}

//+------------------------------------------------------------------+
//| Cleanup — flush and close file                                   |
//+------------------------------------------------------------------+
void CTradeLogger::Deinit()
{
   if(m_fileHandle != INVALID_HANDLE)
   {
      FileFlush(m_fileHandle);
      FileClose(m_fileHandle);
      m_fileHandle = INVALID_HANDLE;
   }
   m_ready = false;
}

//+------------------------------------------------------------------+
//| Write CSV header row                                             |
//+------------------------------------------------------------------+
void CTradeLogger::WriteHeader()
{
   if(m_fileHandle == INVALID_HANDLE) return;
   
   string header = "Time,MagicNumber,Symbol,Event,Signal,"
                   "ProbEntry,ProbAddon,ATR,SL,CE2,Lot,"
                   "PnL,HoldBars,UnrealizedATR,AddonNum,Reason,"
                   "Feat1_Name,Feat1_Val,Feat2_Name,Feat2_Val,"
                   "Feat3_Name,Feat3_Val,Feat4_Name,Feat4_Val,"
                   "Feat5_Name,Feat5_Val";
   
   FileWriteString(m_fileHandle, header + "\n");
   m_headerWritten = true;
}

//+------------------------------------------------------------------+
//| Write a row and manage flush counter                             |
//+------------------------------------------------------------------+
void CTradeLogger::WriteRow(string line)
{
   if(m_fileHandle == INVALID_HANDLE || !m_ready) return;
   
   FileWriteString(m_fileHandle, line + "\n");
   
   m_flushCounter++;
   if(m_flushCounter >= FLUSH_INTERVAL)
   {
      FileFlush(m_fileHandle);
      m_flushCounter = 0;
   }
}

//+------------------------------------------------------------------+
//| Format datetime to string                                        |
//+------------------------------------------------------------------+
string CTradeLogger::FormatTime(datetime t)
{
   return TimeToString(t, TIME_DATE | TIME_MINUTES);
}

//+------------------------------------------------------------------+
//| Format top N features for logging                                |
//| Uses Entry model feature names by default                        |
//+------------------------------------------------------------------+
string CTradeLogger::FormatTopFeatures(const float &features[], int count,
                                       const string &names[])
{
   string result = "";
   int total = MathMin(count, TOP_FEAT_COUNT);
   int featSize = ArraySize(features);
   int nameSize = ArraySize(names);
   
   for(int i = 0; i < TOP_FEAT_COUNT; i++)
   {
      if(i > 0) result += ",";
      
      if(i < total && i < featSize && i < nameSize)
      {
         result += names[i] + "," + DoubleToString((double)features[i], 4);
      }
      else
      {
         result += ",";  // Empty columns
      }
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Log ENTRY event                                                  |
//+------------------------------------------------------------------+
void CTradeLogger::LogEntry(double probEntry, double probAddon,
                            double atr, double sl, double lot,
                            const float &features[])
{
   if(!m_ready) return;
   
   string line = FormatTime(TimeCurrent()) + ","
               + IntegerToString(m_magicNumber) + ","
               + m_symbol + ","
               + "ENTRY,BUY,"
               + DoubleToString(probEntry, 4) + ","
               + DoubleToString(probAddon, 4) + ","
               + DoubleToString(atr, 2) + ","
               + DoubleToString(sl, 2) + ","
               + "0.00,"   // CE2 not active yet
               + DoubleToString(lot, 2) + ","
               + "0.00,"   // PnL
               + "0,"      // HoldBars
               + "0.00,"   // UnrealizedATR
               + "0,"      // AddonNum
               + "prob>=" + DoubleToString(probEntry, 2) + ","
               + FormatTopFeatures(features, ArraySize(features),
                                   EntryFeatureNames);
   
   WriteRow(line);
}

//+------------------------------------------------------------------+
//| Log ADDON event                                                  |
//+------------------------------------------------------------------+
void CTradeLogger::LogAddon(int addonNum, double probAddon,
                            double lot, double unrealizedATR,
                            const float &features[])
{
   if(!m_ready) return;
   
   string line = FormatTime(TimeCurrent()) + ","
               + IntegerToString(m_magicNumber) + ","
               + m_symbol + ","
               + "ADDON,BUY,"
               + "0.0000,"   // ProbEntry (not relevant for addon)
               + DoubleToString(probAddon, 4) + ","
               + "0.00,"     // ATR (can be added if needed)
               + "0.00,"     // SL (same as 1st entry)
               + "0.00,"     // CE2
               + DoubleToString(lot, 2) + ","
               + "0.00,"     // PnL
               + "0,"        // HoldBars
               + DoubleToString(unrealizedATR, 2) + ","
               + IntegerToString(addonNum) + ","
               + "addon_prob>=" + DoubleToString(probAddon, 2) + ","
               + FormatTopFeatures(features, ArraySize(features),
                                   AddonFeatureNames);
   
   WriteRow(line);
}

//+------------------------------------------------------------------+
//| Log CLOSE event                                                  |
//+------------------------------------------------------------------+
void CTradeLogger::LogClose(string reason, double pnl, int holdBars)
{
   if(!m_ready) return;
   
   string line = FormatTime(TimeCurrent()) + ","
               + IntegerToString(m_magicNumber) + ","
               + m_symbol + ","
               + "CLOSE,NONE,"
               + "0.0000,0.0000,"     // probs
               + "0.00,0.00,0.00,"    // ATR, SL, CE2
               + "0.00,"              // Lot
               + DoubleToString(pnl, 2) + ","
               + IntegerToString(holdBars) + ","
               + "0.00,"              // UnrealizedATR
               + "0,"                 // AddonNum
               + reason + ","
               + ",,,,,,,,,,";        // Empty feature columns
   
   WriteRow(line);
   
   // Force flush on close events
   if(m_fileHandle != INVALID_HANDLE)
      FileFlush(m_fileHandle);
}

//+------------------------------------------------------------------+
//| Log RECOVERY event (EA restart state restore)                    |
//+------------------------------------------------------------------+
void CTradeLogger::LogRecovery(string action, string details)
{
   if(!m_ready) return;
   
   string line = FormatTime(TimeCurrent()) + ","
               + IntegerToString(m_magicNumber) + ","
               + m_symbol + ","
               + "RECOVERY,NONE,"
               + "0.0000,0.0000,"     // probs
               + "0.00,0.00,0.00,"    // ATR, SL, CE2
               + "0.00,"              // Lot
               + "0.00,"              // PnL
               + "0,"                 // HoldBars
               + "0.00,"              // UnrealizedATR
               + "0,"                 // AddonNum
               + action + ": " + details + ","
               + ",,,,,,,,,,";        // Empty feature columns
   
   WriteRow(line);
   
   // Force flush on recovery
   if(m_fileHandle != INVALID_HANDLE)
      FileFlush(m_fileHandle);
}

//+------------------------------------------------------------------+
//| Log SKIP event (optional — only for major skips)                 |
//+------------------------------------------------------------------+
void CTradeLogger::LogSkip(string reason, double probEntry,
                           double probAddon)
{
   if(!m_ready) return;
   
   string line = FormatTime(TimeCurrent()) + ","
               + IntegerToString(m_magicNumber) + ","
               + m_symbol + ","
               + "SKIP,NONE,"
               + DoubleToString(probEntry, 4) + ","
               + DoubleToString(probAddon, 4) + ","
               + "0.00,0.00,0.00,"    // ATR, SL, CE2
               + "0.00,"              // Lot
               + "0.00,"              // PnL
               + "0,"                 // HoldBars
               + "0.00,"              // UnrealizedATR
               + "0,"                 // AddonNum
               + reason + ","
               + ",,,,,,,,,,";        // Empty feature columns
   
   WriteRow(line);
}

#endif // __CTRADELOGGER_MQH__
