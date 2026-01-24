//+------------------------------------------------------------------+
//|                                                     CommonV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV7/ExternVariables.mqh>


bool Times(datetime currTime)
{
   MqlDateTime strTime;
   TimeToStruct(currTime, strTime);
   int hour0 = strTime.hour;

   if(StartTime < EndTime)
      if(hour0 < StartTime || hour0 >= EndTime)
         return (false);
   if(StartTime > EndTime)
      if(hour0 >= EndTime || hour0 < StartTime)
         return(false);

   return (true);
}

bool CloseTimes(datetime currTime)
{
   MqlDateTime strTime;
   TimeToStruct(currTime, strTime);
   int hour0 = strTime.hour;
   int minute0=strTime.min;
   static bool m_FlagTime=false;
   static bool m_FlagOne=false;

   if(m_FlagOne==false && hour0>=CloseHour && minute0>=CloseMin ) 
     {
      m_FlagTime=true; 
      m_FlagOne=true;
     }
   else if(m_FlagOne=true && hour0>=CloseHour && minute0>=CloseMin)
     {
      m_FlagTime=false;
      m_FlagOne=true;
     } 
   else 
     {
      m_FlagTime=false;
      m_FlagOne=false;      
     }  

   return(m_FlagTime);   
}


 
 
bool isNewBar(string sym)
{
   static datetime dtBarCurrent=WRONG_VALUE;
   datetime dtBarPrevious=dtBarCurrent;
   dtBarCurrent=(datetime) SeriesInfoInteger(sym,Period(),SERIES_LASTBAR_DATE);
   bool NewBarFlag=(dtBarCurrent!=dtBarPrevious);
   if(NewBarFlag)
      return(true);
   else
      return (false);

   return (false);
}
