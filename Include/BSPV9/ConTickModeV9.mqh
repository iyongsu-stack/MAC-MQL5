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
   int m_BarCount=0;

   if(CurPM[m_Session]==NoMode) return(m_ConStart);
   
   if(CurPM[m_Session]!=End) m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;  

   if( PositionSummary[m_Session].firstPositionTrend == DownTrend )
     {   
      //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
      if( (CurPM[m_Session]==LongReverse) &&
          (TrendLL==DownTrend) && 
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue) && ReOC[m_Session].LRConCanGo) )
        {
          if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
            {
              PositionModeSet(m_Session, LongReverseCon);
              m_ConStart=true;
            }
          
          ReOC[m_Session].LRConCanGo=false;
        }  
      //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
      if( (CurPM[m_Session]==LongCounter) &&
          (TrendLL==UpTrend) &&
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue) && ReOC[m_Session].LCConCanGo) )
          {  
          if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
            {
              PositionModeSet(m_Session, LongCounterCon);
              m_ConStart=true;
            }
          
          ReOC[m_Session].LCConCanGo=false;
        }
      //----------------------------------------------------------------- DLRCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==DownTrend) && 
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue) && ReOC[m_Session].DLRConCanGo) )
        {  
          if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
            {
              PositionModeSet(m_Session, DLRCon);
              m_ConStart=true;
            }
          else 
            {
              PositionModeSet(m_Session, End);  
              m_ConStart=true;
            }    

          ReOC[m_Session].DLRConCanGo=false;
        }
      //----------------------------------------------------------------- DLRCCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==UpTrend) && 
          (WmaSValue>=(ReOC[m_Session].MinBSP+DLRCConThValue) && ReOC[m_Session].DLRCConCanGo) )
        {
          if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
            {
              PositionModeSet(m_Session, DLRCCon);
              m_ConStart=true;
            }
          else 
            {
              PositionModeSet(m_Session, End);  
              m_ConStart=true;
            }    

          ReOC[m_Session].DLRCConCanGo=false;
        }   
     }  
           
   if( PositionSummary[m_Session].firstPositionTrend== UpTrend )
     {            
      //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
      if( (CurPM[m_Session]==LongReverse) &&
          (TrendLL==UpTrend) && 
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue) && ReOC[m_Session].LRConCanGo) )
        {
          if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
            {
              PositionModeSet(m_Session, LongReverseCon);
              m_ConStart=true;
            }
          
          ReOC[m_Session].LRConCanGo=false;
        }  
      //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
      if( (CurPM[m_Session]==LongCounter) &&
          (TrendLL==DownTrend) &&
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue) && ReOC[m_Session].LCConCanGo) )
        {
          if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
            {
              PositionModeSet(m_Session, LongCounterCon);
              m_ConStart=true;
            }
          
          ReOC[m_Session].LCConCanGo=false;
        }   
      //----------------------------------------------------------------- DLRCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==UpTrend) && 
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue) && ReOC[m_Session].DLRConCanGo) )
        {
          if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
            {
              PositionModeSet(m_Session, DLRCon);
              m_ConStart=true;
            }
          else 
            {
              PositionModeSet(m_Session, End); 
              m_ConStart=true;
            }     

          ReOC[m_Session].DLRConCanGo=false;
        }   
      //----------------------------------------------------------------- DLRCCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==DownTrend) && 
          (WmaSValue<=(ReOC[m_Session].MaxBSP-DLRCConThValue) && ReOC[m_Session].DLRCConCanGo) )
        {
          if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
            {
              PositionModeSet(m_Session, DLRCCon);
              m_ConStart=true;
            }
          else 
            {
              PositionModeSet(m_Session, End); 
              m_ConStart=true;
            }     

          ReOC[m_Session].DLRCConCanGo=false;
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