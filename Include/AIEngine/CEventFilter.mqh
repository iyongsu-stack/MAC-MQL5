//+------------------------------------------------------------------+
//| CEventFilter.mqh — Economic event blackout filter                |
//| Phase 1-4 | AIEngine Module                                      |
//|                                                                  |
//| Loads economic event schedule from CSV and blocks new entries     |
//| during blackout windows around high-impact events.               |
//|                                                                  |
//| CSV Format (event_calendar.csv):                                 |
//|   date,time_et,event_type,tier,before_hours,after_hours          |
//|   2026-03-19,14:00,FOMC,1,4,2                                   |
//|                                                                  |
//| Usage:                                                           |
//|   CEventFilter filter;                                           |
//|   filter.Init("processed/event_calendar.csv");                   |
//|   if(filter.IsBlackout(TimeCurrent())) { /* skip entry */ }      |
//+------------------------------------------------------------------+
#ifndef __CEVENTFILTER_MQH__
#define __CEVENTFILTER_MQH__

//--- Maximum number of events to load
#define EVENT_MAX_COUNT  500

//+------------------------------------------------------------------+
//| Event data structure                                             |
//+------------------------------------------------------------------+
struct EventInfo
{
   datetime       eventTime;         // Event time in server timezone
   string         eventType;         // "FOMC", "NFP", "CPI", "PCE"
   int            tier;              // 1=high, 2=medium
   int            beforeHours;       // Blackout hours before event
   int            afterHours;        // Blackout hours after event
   datetime       blackoutStart;     // Pre-computed: eventTime - before
   datetime       blackoutEnd;       // Pre-computed: eventTime + after
};

//+------------------------------------------------------------------+
//| CEventFilter class                                               |
//+------------------------------------------------------------------+
class CEventFilter
{
private:
   EventInfo      m_events[];        // All loaded events
   int            m_eventCount;      // Number of events
   bool           m_loaded;          // CSV loaded successfully
   string         m_csvPath;         // CSV file path
   
   int            m_gmtOffsetET;     // ET → GMT offset in seconds
   int            m_serverGmtOffset; // Server → GMT offset in seconds
   
   //--- Internal helpers
   bool           ParseCSV();
   datetime       ConvertETToServer(string dateStr, string timeStr) const;
   int            FindNextEventIdx(datetime now) const;
   
public:
                  CEventFilter();
                 ~CEventFilter();
   
   //--- Initialization
   bool           Init(string csvPath, int serverGmtOffset = 2);
   void           SetServerGmtOffset(int hours) { m_serverGmtOffset = hours * 3600; }
   
   //--- Blackout check
   bool           IsBlackout(datetime now) const;
   
   //--- Event info
   string         GetNextEvent(datetime now) const;
   datetime       GetNextEventTime(datetime now) const;
   datetime       GetBlackoutEnd(datetime now) const;
   string         GetBlackoutStatus(datetime now) const;
   
   //--- Status
   bool           IsLoaded() const          { return m_loaded; }
   int            GetEventCount() const     { return m_eventCount; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CEventFilter::CEventFilter()
   : m_eventCount(0), m_loaded(false),
     m_gmtOffsetET(-5 * 3600),     // Eastern Time = UTC-5 (EST)
     m_serverGmtOffset(2 * 3600)   // Default: GMT+2 (common MT5 broker)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CEventFilter::~CEventFilter()
{
}

//+------------------------------------------------------------------+
//| Initialize with CSV path                                         |
//| csvPath: relative to MQL5/Files/                                 |
//| serverGmtOffset: broker server timezone offset (hours from GMT)  |
//|   e.g., 2 for GMT+2 (standard), 3 for GMT+3 (DST)               |
//+------------------------------------------------------------------+
bool CEventFilter::Init(string csvPath, int serverGmtOffset)
{
   m_csvPath = csvPath;
   m_serverGmtOffset = serverGmtOffset * 3600;
   m_loaded  = false;
   
   if(!ParseCSV())
   {
      Print("[CEventFilter] Init failed: cannot load ", csvPath);
      return false;
   }
   
   Print("[CEventFilter] Loaded: ", m_eventCount, " events from ", csvPath);
   return true;
}

//+------------------------------------------------------------------+
//| Parse event_calendar.csv                                         |
//| Format: date,time_et,event_type,tier,before_hours,after_hours    |
//+------------------------------------------------------------------+
bool CEventFilter::ParseCSV()
{
   int handle = FileOpen(m_csvPath, FILE_READ | FILE_CSV | FILE_ANSI, ',');
   if(handle == INVALID_HANDLE)
   {
      Print("[CEventFilter] Cannot open: ", m_csvPath,
            " Error=", GetLastError());
      return false;
   }
   
   m_eventCount = 0;
   ArrayResize(m_events, EVENT_MAX_COUNT);
   
   // Skip header line
   while(!FileIsLineEnding(handle) && !FileIsEnding(handle))
      FileReadString(handle);
   
   // Read data rows
   int skippedEvents = 0;
   while(!FileIsEnding(handle))
   {
      // date
      string dateStr = FileReadString(handle);
      if(StringLen(dateStr) < 8)
         continue;
      
      // time_et (HH:MM)
      string timeStr = FileReadString(handle);
      
      // event_type
      string eventType = FileReadString(handle);
      
      // tier
      string tierStr = FileReadString(handle);
      int tier = (int)StringToInteger(tierStr);
      
      // before_hours
      string beforeStr = FileReadString(handle);
      int beforeHours = (int)StringToInteger(beforeStr);
      
      // after_hours
      string afterStr = FileReadString(handle);
      int afterHours = (int)StringToInteger(afterStr);
      
      // Skip remaining fields on line
      while(!FileIsLineEnding(handle) && !FileIsEnding(handle))
         FileReadString(handle);
      
      // Convert ET time to server time
      datetime eventTime = ConvertETToServer(dateStr, timeStr);
      if(eventTime == 0)
         continue;
      
      if(m_eventCount >= EVENT_MAX_COUNT)
      {
         skippedEvents++;
         continue;
      }
      
      // Fill event info
      m_events[m_eventCount].eventTime    = eventTime;
      m_events[m_eventCount].eventType    = eventType;
      m_events[m_eventCount].tier         = tier;
      m_events[m_eventCount].beforeHours  = beforeHours;
      m_events[m_eventCount].afterHours   = afterHours;
      m_events[m_eventCount].blackoutStart = eventTime - beforeHours * 3600;
      m_events[m_eventCount].blackoutEnd   = eventTime + afterHours * 3600;
      
      m_eventCount++;
   }
   
   if(skippedEvents > 0)
      Print("[CEventFilter] CRITICAL: ", skippedEvents,
            " events truncated! MAX=", EVENT_MAX_COUNT,
            " — increase EVENT_MAX_COUNT");
   
   FileClose(handle);
   ArrayResize(m_events, m_eventCount);
   m_loaded = (m_eventCount > 0);
   
   return m_loaded;
}

//+------------------------------------------------------------------+
//| Convert Eastern Time date+time to server time                    |
//| dateStr: "YYYY-MM-DD", timeStr: "HH:MM"                         |
//+------------------------------------------------------------------+
datetime CEventFilter::ConvertETToServer(string dateStr, string timeStr) const
{
   // Parse date
   string dateParts[];
   if(StringSplit(dateStr, '-', dateParts) < 3)
      return 0;
   
   // Parse time
   string timeParts[];
   if(StringSplit(timeStr, ':', timeParts) < 2)
      return 0;
   
   MqlDateTime dt;
   dt.year  = (int)StringToInteger(dateParts[0]);
   dt.mon   = (int)StringToInteger(dateParts[1]);
   dt.day   = (int)StringToInteger(dateParts[2]);
   dt.hour  = (int)StringToInteger(timeParts[0]);
   dt.min   = (int)StringToInteger(timeParts[1]);
   dt.sec   = 0;
   
   datetime etTime = StructToTime(dt);
   
   // Convert: ET → UTC → Server
   // etTime is in ET (UTC-5 standard / UTC-4 DST)
   // UTC = etTime - m_gmtOffsetET  (subtract negative = add 5h)
   // Server = UTC + m_serverGmtOffset
   datetime utcTime    = etTime - m_gmtOffsetET;
   datetime serverTime = utcTime + m_serverGmtOffset;
   
   return serverTime;
}

//+------------------------------------------------------------------+
//| Find index of next event at or after 'now'                       |
//| Returns -1 if no future events exist                             |
//+------------------------------------------------------------------+
int CEventFilter::FindNextEventIdx(datetime now) const
{
   int bestIdx = -1;
   datetime bestTime = D'2099.01.01';
   
   for(int i = 0; i < m_eventCount; i++)
   {
      if(m_events[i].eventTime >= now && m_events[i].eventTime < bestTime)
      {
         bestTime = m_events[i].eventTime;
         bestIdx  = i;
      }
   }
   
   return bestIdx;
}

//+------------------------------------------------------------------+
//| Check if current time falls within any event's blackout window   |
//| Only checks Tier 1 events (as per simulation results)            |
//| Returns true = entry should be blocked                           |
//+------------------------------------------------------------------+
bool CEventFilter::IsBlackout(datetime now) const
{
   if(!m_loaded)
      return false;
   
   for(int i = 0; i < m_eventCount; i++)
   {
      // Only Tier 1 events trigger blackout (simulation confirmed)
      if(m_events[i].tier != 1)
         continue;
      
      if(now >= m_events[i].blackoutStart && now <= m_events[i].blackoutEnd)
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get the name of the next scheduled event                         |
//+------------------------------------------------------------------+
string CEventFilter::GetNextEvent(datetime now) const
{
   int idx = FindNextEventIdx(now);
   if(idx < 0)
      return "None";
   
   return m_events[idx].eventType;
}

//+------------------------------------------------------------------+
//| Get the server time of the next scheduled event                  |
//+------------------------------------------------------------------+
datetime CEventFilter::GetNextEventTime(datetime now) const
{
   int idx = FindNextEventIdx(now);
   if(idx < 0)
      return 0;
   
   return m_events[idx].eventTime;
}

//+------------------------------------------------------------------+
//| Get blackout end time for the current blackout (if active)       |
//| Returns 0 if not in blackout                                     |
//+------------------------------------------------------------------+
datetime CEventFilter::GetBlackoutEnd(datetime now) const
{
   if(!m_loaded)
      return 0;
   
   datetime latestEnd = 0;
   
   for(int i = 0; i < m_eventCount; i++)
   {
      if(m_events[i].tier != 1)
         continue;
      
      if(now >= m_events[i].blackoutStart && now <= m_events[i].blackoutEnd)
      {
         if(m_events[i].blackoutEnd > latestEnd)
            latestEnd = m_events[i].blackoutEnd;
      }
   }
   
   return latestEnd;
}

//+------------------------------------------------------------------+
//| Get human-readable blackout status for dashboard                  |
//| Returns: "🚫 FOMC 2h 후" or "✅ 정상 (NFP: 3일 후)"             |
//+------------------------------------------------------------------+
string CEventFilter::GetBlackoutStatus(datetime now) const
{
   if(!m_loaded)
      return "⚠️ 이벤트 데이터 미로드";
   
   // Check if currently in blackout
   for(int i = 0; i < m_eventCount; i++)
   {
      if(m_events[i].tier != 1)
         continue;
      
      if(now >= m_events[i].blackoutStart && now <= m_events[i].blackoutEnd)
      {
         int remainMin = (int)((m_events[i].blackoutEnd - now) / 60);
         if(remainMin < 60)
            return "🚫 " + m_events[i].eventType + " " +
                   IntegerToString(remainMin) + "분 후 해제";
         else
            return "🚫 " + m_events[i].eventType + " " +
                   IntegerToString(remainMin / 60) + "h " +
                   IntegerToString(remainMin % 60) + "m 후 해제";
      }
   }
   
   // Not in blackout — find next event
   int nextIdx = FindNextEventIdx(now);
   if(nextIdx < 0)
      return "✅ 정상 (예정 이벤트 없음)";
   
   int hoursUntil = (int)((m_events[nextIdx].eventTime - now) / 3600);
   if(hoursUntil < 24)
      return "✅ 정상 (" + m_events[nextIdx].eventType + ": " +
             IntegerToString(hoursUntil) + "시간 후)";
   else
      return "✅ 정상 (" + m_events[nextIdx].eventType + ": " +
             IntegerToString(hoursUntil / 24) + "일 후)";
}

#endif // __CEVENTFILTER_MQH__
