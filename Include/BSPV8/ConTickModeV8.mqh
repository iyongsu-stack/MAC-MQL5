//+------------------------------------------------------------------+
//|                                                ConTickModeV8.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//------------------------------------------------------------------------
bool TickPositionModeCheck(int m_Session )
{
   bool m_ConStart=false;

   if(CurPM[m_Session]==NoMode) return(m_ConStart);

   if( PositionSummary[m_Session].firstPositionTrend == DownTrend )
     {   
      //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
      if( (CurPM[m_Session]==LongReverse) &&
          (TrendLL==DownTrend) && 
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue)) )
        {
         PositionModeSet(m_Session, LongReverseCon);
         m_ConStart=true;
        }  
      //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
      if( (CurPM[m_Session]==LongCounter) &&
          (TrendLL==UpTrend) &&
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue)) )
        {  
         PositionModeSet(m_Session, LongCounterCon);
         m_ConStart=true;
        }
      //----------------------------------------------------------------- DLRCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==DownTrend) && 
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue) ) )
        {  
         PositionModeSet(m_Session, DLRCon);
         m_ConStart=true;
        }
      //----------------------------------------------------------------- DLRCCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==UpTrend) && 
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+DLRCConThValue) )  )
        {
         PositionModeSet(m_Session, DLRCCon);
         m_ConStart=true;
        }   
     }  
           
   if( PositionSummary[m_Session].firstPositionTrend== UpTrend )
     {            
      //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
      if( (CurPM[m_Session]==LongReverse) &&
          (TrendLL==UpTrend) && 
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue)) )
        {
         PositionModeSet(m_Session, LongReverseCon);
         m_ConStart=true;
        }  
      //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
      if( (CurPM[m_Session]==LongCounter) &&
          (TrendLL==DownTrend) &&
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue)) )
        {
         PositionModeSet(m_Session, LongCounterCon);
         m_ConStart=true;
        }   
      //----------------------------------------------------------------- DLRCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==UpTrend) && 
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue) ) )
        {
         PositionModeSet(m_Session, DLRCon);
         m_ConStart=true;
        }   
      //----------------------------------------------------------------- DLRCCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==DownTrend) && 
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-DLRCConThValue) )  )
        {
         PositionModeSet(m_Session, DLRCCon);
         m_ConStart=true;
        }   
     }  

   return(m_ConStart);  
}

bool TickCheckRequired(void)
{
   if(ConTickMode==CT_NewBar)
      return(false);

   for(int m_Session=0;m_Session<TotalSession;m_Session++)
     {
      if(CurPM[m_Session]==LongReverse || CurPM[m_Session]==LongCounter || 
         CurPM[m_Session]==DoubleLongReverse )
         return(true);
     }

   return(false);
}