//+------------------------------------------------------------------+
//|                                         DKSimplestCSVReader1.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayString.mqh>
#include <Generic\HashMap.mqh>

//+------------------------------------------------------------------+
//| Simplest class for CSV file reading and parsing values as string |
//+------------------------------------------------------------------+
class CDKSimplestCSVReader
 {
private:
  CArrayObj          Rows;

  string             HeaderString;
  CHashMap           <string, uint> Columns;

public:
                    ~CDKSimplestCSVReader(void);

  uint               ReadCSV(const string aFilename,
                             const int aAdditionalFileFlags,
                             const string aSeparator = ";",
                             const bool aHasHeader = true);                                      // Read CSV file

  uint               ColumnCount();                                                              // Return numbers of columns
  string             GetColumn(uint aColumnIndex, string aErrorValue = "");                      // Get column name by index.

  uint               RowCount();                                                                 // Return numbers of data rows without header
  string             GetValue(uint aRowNumber, string aColumnName, string aErrorValue = "");     // Put value of aColumnName from aRowNumber
  string             GetValue(uint aRowNumber, int aColumnIndex, string aErrorValue = "");       // Put value of aColumnIndex from aRowNumber
 };

//+------------------------------------------------------------------+
//| Class destructor                                                                  |
//+------------------------------------------------------------------+
void CDKSimplestCSVReader::~CDKSimplestCSVReader(void)
 {
  for(int i = 0; i < Rows.Total(); i++)
   {
    CArrayString *Row = Rows.At(i);
    if(Row != NULL)
      delete Row;
   }
 }

//+------------------------------------------------------------------+
//| Main method to read and parse CSV file                           |
//+------------------------------------------------------------------+
uint CDKSimplestCSVReader::ReadCSV(const string aFilename, const int aAdditionalFileFlags, const string aSeparator = ";", const bool aHasHeader = true)
 {
  int fileHandle = FileOpen(aFilename, FILE_READ|FILE_TXT|aAdditionalFileFlags);
  if(fileHandle == INVALID_HANDLE)
    return 0;

  Columns.Clear();
  HeaderString = "";
  Rows.Clear();

  string fileLine;
  while(!FileIsEnding(fileHandle))
   {
    fileLine = FileReadString(fileHandle);

    string lineFields[];
    StringSplit(fileLine, StringGetCharacter(aSeparator, 0), lineFields);
    if (ArraySize(lineFields) <= 0) continue;


    if(!(aHasHeader && HeaderString == ""))
     {
      CArrayString* Row = new CArrayString;
      for(int i = 0; i < ArraySize(lineFields); i++)
        Row.Add(lineFields[i]);
      Rows.Add(Row);
     }
    else
     {
      HeaderString = fileLine;
      for(int i = 0; i < ArraySize(lineFields); i++)
        Columns.Add(lineFields[i], i);
     }
   }
  FileClose(fileHandle);

  return Rows.Total();
 }

//+------------------------------------------------------------------+
//| Return number of columns from 1st line of the file               |
//+------------------------------------------------------------------+
uint CDKSimplestCSVReader::ColumnCount()
 {
  return Columns.Count();
 }

//+------------------------------------------------------------------+
//| Return column name from 1st line of the file by index            |
//+------------------------------------------------------------------+
string CDKSimplestCSVReader::GetColumn(uint aColumnIndex, string aErrorValue = "")
 {
  string keys[];
  uint values[];
  Columns.CopyTo(keys, values);

  if(aColumnIndex < (uint)ArraySize(keys))
    return keys[aColumnIndex];
  return aErrorValue;
 }


//+------------------------------------------------------------------+
//| Return number of data rows without header                        |
//+------------------------------------------------------------------+
uint CDKSimplestCSVReader::RowCount()
 {
  return Rows.Total();
 }

//+------------------------------------------------------------------+
//| Return value of aColumnName from aRowNumber line of the file     |
//+------------------------------------------------------------------+
string CDKSimplestCSVReader::GetValue(uint aRowNumber, string aColumnName, string aErrorValue = "")
 {
  if(HeaderString != "")
   {
    uint ColumnIndex;
    if(Columns.TryGetValue(aColumnName, ColumnIndex))
     {
      CArrayString *Row = Rows.At(aRowNumber);
      if(Row == NULL)
        return aErrorValue;

      string Value = Row.At(ColumnIndex);
      if(Value == "")
        return aErrorValue; // Here you must check GetLastError(). See next line comment
      // if (aValue == "" && GetLastError() == ERR_OUT_OF_RANGE) return false; #todo ERR_OUT_OF_RANGE is undeclared identifier

      return Value;
     }
   }

  return aErrorValue;
 }

//+------------------------------------------------------------------+
//| Return value of column by index from aRowNumber line of the file |
//+------------------------------------------------------------------+
string CDKSimplestCSVReader::GetValue(uint aRowNumber, int aColumnIndex, string aErrorValue = "")
 {
  CArrayString *Row = Rows.At(aRowNumber);
  if(Row == NULL)
    return aErrorValue;

  string Value = Row.At(aColumnIndex);
  if(Value == "")
    return aErrorValue; // Here you must check GetLastError(). See next line comment
// if (aValue == "" && GetLastError() == ERR_OUT_OF_RANGE) return false; #todo ERR_OUT_OF_RANGE is undeclared identifier

  return Value;
 }
//+------------------------------------------------------------------+
