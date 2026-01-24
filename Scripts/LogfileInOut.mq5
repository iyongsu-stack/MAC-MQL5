//+------------------------------------------------------------------+
//|                                                      AllTest.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
//---
   datetime currentTime = TimeCurrent();
   MqlDateTime logTime;
   TimeToStruct(currentTime, logTime);
   string logFileName = "log"+logTime.mon+"-"+logTime.day_of_week+".csv";
   int logFileHandle = FileOpen( logFileName, FILE_READ|FILE_WRITE|FILE_CSV, ",");
   FileSeek(logFileHandle, 0, SEEK_END);
   FileWrite(logFileHandle, "Testing.......", "Testing.....");
   FileClose(logFileHandle);
         
}
//+------------------------------------------------------------------+
