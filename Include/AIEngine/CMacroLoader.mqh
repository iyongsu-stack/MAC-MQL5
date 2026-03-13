//+------------------------------------------------------------------+
//| CMacroLoader.mqh — CSV-based macro feature loader with caching   |
//| Phase 1-2 | AIEngine Module                                      |
//|                                                                  |
//| Loads macro features from a CSV file generated daily by Python.  |
//| Implements ffill (forward-fill) for weekends/holidays.           |
//| Caches loaded data to avoid redundant file I/O.                  |
//|                                                                  |
//| CSV Format:                                                      |
//|   date,feature1,feature2,...                                     |
//|   2026-03-12,0.1234,-0.5678,...                                  |
//|                                                                  |
//| Usage:                                                           |
//|   CMacroLoader loader;                                           |
//|   loader.Init("macro_latest.csv", 652);                          |
//|   loader.LoadForDate(TimeCurrent());                             |
//|   double val = loader.GetFeature("SP500_zscore_60");             |
//+------------------------------------------------------------------+
#ifndef __CMACROLOADER_MQH__
#define __CMACROLOADER_MQH__

//--- Maximum supported features and rows (여유율 50% 이상 확보)
#define MACRO_MAX_FEATURES  1000
#define MACRO_MAX_ROWS       200

//+------------------------------------------------------------------+
//| Internal structure for one row of macro data                     |
//+------------------------------------------------------------------+
struct MacroRow
{
   datetime       date;
   double         values[MACRO_MAX_FEATURES];
};

//+------------------------------------------------------------------+
//| CMacroLoader class                                               |
//+------------------------------------------------------------------+
class CMacroLoader
{
private:
   string         m_csvPath;                    // CSV file path (relative to Files/)
   string         m_featureNames[];             // Column names from header
   int            m_featureCount;               // Number of feature columns
   
   MacroRow       m_rows[];                     // All loaded rows
   int            m_rowCount;                   // Number of rows loaded
   
   int            m_cachedRowIdx;               // Index of currently selected row
   datetime       m_lastLoadDate;               // Date of last successful load
   datetime       m_fileModTime;                // File modification time at last load
   bool           m_loaded;                     // Whether CSV has been loaded
   
   //--- Internal helpers
   bool           ParseCSV();
   datetime       ParseDate(string dateStr) const;
   int            FindRowForDate(datetime date) const;
   
public:
                  CMacroLoader();
                 ~CMacroLoader();
   
   //--- Initialization
   bool           Init(string csvPath, int expectedFeatures = 0);
   
   //--- Data loading
   bool           LoadForDate(datetime date);
   bool           Reload();                      // Force re-read CSV
   
   //--- Feature access
   double         GetFeature(string name) const;
   double         GetFeatureByIndex(int idx) const;
   int            GetFeatureIndex(string name) const;
   
   //--- Status
   datetime       GetLastLoadDate() const       { return m_lastLoadDate; }
   bool           IsLoaded() const              { return m_loaded; }
   bool           IsStale(int maxDays) const;
   int            GetFeatureCount() const        { return m_featureCount; }
   int            GetRowCount() const            { return m_rowCount; }
   void           GetFeatureNames(string &out[]) const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMacroLoader::CMacroLoader()
   : m_featureCount(0), m_rowCount(0), m_cachedRowIdx(-1),
     m_lastLoadDate(0), m_fileModTime(0), m_loaded(false)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMacroLoader::~CMacroLoader()
{
}

//+------------------------------------------------------------------+
//| Initialize with CSV path                                         |
//| csvPath: relative to MQL5/Files/ directory                       |
//+------------------------------------------------------------------+
bool CMacroLoader::Init(string csvPath, int expectedFeatures)
{
   m_csvPath = csvPath;
   m_loaded  = false;
   m_rowCount = 0;
   m_cachedRowIdx = -1;
   
   // Attempt initial CSV load
   if(!ParseCSV())
   {
      Print("[CMacroLoader] Init warning: CSV load failed for ", csvPath);
      return false;
   }
   
   if(expectedFeatures > 0 && m_featureCount != expectedFeatures)
   {
      Print("[CMacroLoader] Warning: expected ", expectedFeatures,
            " features, got ", m_featureCount);
   }
   
   Print("[CMacroLoader] Loaded: ", m_featureCount, " features, ",
         m_rowCount, " rows from ", csvPath);
   return true;
}

//+------------------------------------------------------------------+
//| Parse the CSV file                                               |
//+------------------------------------------------------------------+
bool CMacroLoader::ParseCSV()
{
   int handle = FileOpen(m_csvPath, FILE_READ | FILE_CSV | FILE_ANSI, ',');
   if(handle == INVALID_HANDLE)
   {
      Print("[CMacroLoader] Cannot open: ", m_csvPath,
            " Error=", GetLastError());
      return false;
   }
   
   m_rowCount = 0;
   ArrayResize(m_rows, MACRO_MAX_ROWS);
   
   // Read header line
   if(FileIsEnding(handle))
   {
      FileClose(handle);
      Print("[CMacroLoader] Empty file: ", m_csvPath);
      return false;
   }
   
   // Parse header: first column is "date", rest are feature names
   // Read entire first line to count columns
   string headerFields[];
   string headerLine = "";
   
   // Read header columns one by one until end of line
   int colCount = 0;
   // FileOpen with CSV mode automatically splits by delimiter
   // We need to read all fields of the first row
   
   // First, read the "date" column header
   string firstCol = FileReadString(handle);
   if(firstCol != "date" && firstCol != "Date")
   {
      Print("[CMacroLoader] Warning: first column is '", firstCol,
            "', expected 'date'");
   }
   
   // Read remaining header columns until we hit a new line or EOF
   // In CSV mode, FileReadString reads one field at a time
   // We detect new record by checking FileIsLineEnding
   ArrayResize(m_featureNames, MACRO_MAX_FEATURES);
   m_featureCount = 0;
   
   int skippedFeatures = 0;
   while(!FileIsLineEnding(handle) && !FileIsEnding(handle))
   {
      string name = FileReadString(handle);
      if(StringLen(name) > 0)
      {
         if(m_featureCount < MACRO_MAX_FEATURES)
         {
            m_featureNames[m_featureCount] = name;
            m_featureCount++;
         }
         else
            skippedFeatures++;
      }
   }
   
   if(skippedFeatures > 0)
      Print("[CMacroLoader] CRITICAL: ", skippedFeatures,
            " features truncated! MAX=", MACRO_MAX_FEATURES,
            " — increase MACRO_MAX_FEATURES");
   
   if(m_featureCount == 0)
   {
      FileClose(handle);
      Print("[CMacroLoader] No feature columns found");
      return false;
   }
   
   ArrayResize(m_featureNames, m_featureCount);
   
   // Read data rows
   int skippedRows = 0;
   while(!FileIsEnding(handle))
   {
      // Read date column
      string dateStr = FileReadString(handle);
      if(StringLen(dateStr) < 8)  // minimum "YYYY-MM-DD" = 10 chars
         continue;
      
      datetime rowDate = ParseDate(dateStr);
      if(rowDate == 0)
         continue;
      
      if(m_rowCount >= MACRO_MAX_ROWS)
      {
         skippedRows++;
         // Skip remaining fields on this line
         while(!FileIsLineEnding(handle) && !FileIsEnding(handle))
            FileReadString(handle);
         continue;
      }
      
      m_rows[m_rowCount].date = rowDate;
      
      // Read feature values
      for(int i = 0; i < m_featureCount; i++)
      {
         if(FileIsEnding(handle))
         {
            m_rows[m_rowCount].values[i] = 0.0;
         }
         else
         {
            string valStr = FileReadString(handle);
            m_rows[m_rowCount].values[i] = StringToDouble(valStr);
         }
      }
      
      // Skip any remaining fields on this line
      while(!FileIsLineEnding(handle) && !FileIsEnding(handle))
         FileReadString(handle);
      
      m_rowCount++;
   }
   
   if(skippedRows > 0)
      Print("[CMacroLoader] CRITICAL: ", skippedRows,
            " rows truncated! MAX=", MACRO_MAX_ROWS,
            " — increase MACRO_MAX_ROWS");
   
   FileClose(handle);
   ArrayResize(m_rows, m_rowCount);
   
   m_loaded = true;
   m_fileModTime = (datetime)TimeCurrent();
   
   return (m_rowCount > 0);
}

//+------------------------------------------------------------------+
//| Parse date string "YYYY-MM-DD" → datetime                       |
//+------------------------------------------------------------------+
datetime CMacroLoader::ParseDate(string dateStr) const
{
   // Expected format: "2026-03-12"
   if(StringLen(dateStr) < 10)
      return 0;
   
   string parts[];
   int n = StringSplit(dateStr, '-', parts);
   if(n < 3)
      return 0;
   
   MqlDateTime dt;
   dt.year  = (int)StringToInteger(parts[0]);
   dt.mon   = (int)StringToInteger(parts[1]);
   dt.day   = (int)StringToInteger(parts[2]);
   dt.hour  = 0;
   dt.min   = 0;
   dt.sec   = 0;
   
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Find the best matching row for a given date (ffill)              |
//| Returns index of the row with the largest date ≤ target date     |
//| Returns -1 if no valid row found                                 |
//+------------------------------------------------------------------+
int CMacroLoader::FindRowForDate(datetime date) const
{
   if(m_rowCount == 0)
      return -1;
   
   // Extract date-only (strip time component)
   MqlDateTime dtTarget;
   TimeToStruct(date, dtTarget);
   dtTarget.hour = 0; dtTarget.min = 0; dtTarget.sec = 0;
   datetime targetDate = StructToTime(dtTarget);
   
   int bestIdx = -1;
   datetime bestDate = 0;
   
   for(int i = 0; i < m_rowCount; i++)
   {
      if(m_rows[i].date <= targetDate && m_rows[i].date > bestDate)
      {
         bestDate = m_rows[i].date;
         bestIdx  = i;
      }
   }
   
   return bestIdx;
}

//+------------------------------------------------------------------+
//| Load (select) data for a given date                              |
//| Uses ffill: picks the most recent row ≤ date                    |
//| Returns true if a valid row was found                            |
//+------------------------------------------------------------------+
bool CMacroLoader::LoadForDate(datetime date)
{
   if(!m_loaded)
   {
      // Try to load CSV if not yet loaded
      if(!ParseCSV())
         return false;
   }
   
   int idx = FindRowForDate(date);
   if(idx < 0)
   {
      Print("[CMacroLoader] No data found for date: ",
            TimeToString(date, TIME_DATE));
      return false;
   }
   
   m_cachedRowIdx = idx;
   m_lastLoadDate = m_rows[idx].date;
   
   return true;
}

//+------------------------------------------------------------------+
//| Force re-read CSV from disk                                      |
//+------------------------------------------------------------------+
bool CMacroLoader::Reload()
{
   m_loaded = false;
   return ParseCSV();
}

//+------------------------------------------------------------------+
//| Get feature value by name                                        |
//| Returns 0.0 if not found or not loaded                           |
//+------------------------------------------------------------------+
double CMacroLoader::GetFeature(string name) const
{
   int idx = GetFeatureIndex(name);
   if(idx < 0)
      return 0.0;
   
   return GetFeatureByIndex(idx);
}

//+------------------------------------------------------------------+
//| Get feature value by column index                                |
//+------------------------------------------------------------------+
double CMacroLoader::GetFeatureByIndex(int idx) const
{
   if(m_cachedRowIdx < 0 || idx < 0 || idx >= m_featureCount)
      return 0.0;
   
   return m_rows[m_cachedRowIdx].values[idx];
}

//+------------------------------------------------------------------+
//| Find column index by feature name                                |
//| Returns -1 if not found                                          |
//+------------------------------------------------------------------+
int CMacroLoader::GetFeatureIndex(string name) const
{
   for(int i = 0; i < m_featureCount; i++)
   {
      if(m_featureNames[i] == name)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Check if data is stale (not updated for N days)                  |
//+------------------------------------------------------------------+
bool CMacroLoader::IsStale(int maxDays) const
{
   if(!m_loaded || m_lastLoadDate == 0)
      return true;
   
   datetime now = TimeCurrent();
   int daysDiff = (int)((now - m_lastLoadDate) / 86400);
   
   return (daysDiff > maxDays);
}

//+------------------------------------------------------------------+
//| Copy feature names to output array                               |
//+------------------------------------------------------------------+
void CMacroLoader::GetFeatureNames(string &out[]) const
{
   ArrayResize(out, m_featureCount);
   for(int i = 0; i < m_featureCount; i++)
      out[i] = m_featureNames[i];
}

#endif // __CMACROLOADER_MQH__
