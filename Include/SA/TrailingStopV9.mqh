//+------------------------------------------------------------------+
//|                                                  OpenCloseV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

void TrailingStop(int m_Session)
  {
   if(TrailingStopMode==TS_None) return;

   int m_Total=PositionsTotal();
   double m_TrailingStopLimit=0.0, m_TrailingStopStart=0.0;

   if(PositionSummary[m_Session].pyramidStarted)
    {
      if(PositionSummary[m_Session].firstPositionTrend==UpTrend)
        {
          if( CurPM[m_Session]==LongReverseCon )
            { 
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

              if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Buy_LR, true, UpTrend);
            }
          else if( CurPM[m_Session]==LongCounterCon )
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

              if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Sell_LC, true, DownTrend);
            }
          else if( CurPM[m_Session]==DLRCon )
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

              if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                {
                  ClosePositionByPID(m_Session, Buy_LR);
                  ClosePositionByPID(m_Session, Buy_DLR, true, UpTrend);
                }
            }
          else if( CurPM[m_Session]==DLRCCon )
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

              if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                {
                  ClosePositionByPID(m_Session, Sell_LC);
                  ClosePositionByPID(m_Session, Sell_DLRCC, true, DownTrend);
                }
            }
        }
      else if(PositionSummary[m_Session].firstPositionTrend==DownTrend)
        {
          if( CurPM[m_Session]==LongReverseCon )
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;  
              m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

              if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Sell_LR, true, DownTrend);
            }
          else if(CurPM[m_Session]==LongCounterCon)
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

              if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Buy_LC, true, UpTrend);
            }
          else if(CurPM[m_Session]==DLRCon)
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

              if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                {
                  ClosePositionByPID(m_Session, Sell_LR);
                  ClosePositionByPID(m_Session, Sell_DLR, true, DownTrend);
                }
            }
          else if(CurPM[m_Session]==DLRCCon)
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

              if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                {
                  ClosePositionByPID(m_Session, Buy_LC);
                  ClosePositionByPID(m_Session, Buy_DLRCC, true, UpTrend);
                }
            }
        }
    }

/*
   if( (OpenCloseCase==OCCase1 || OpenCloseCase==OCCase3) && m_Total>=1)
     {
      if(PositionSummary[m_Session].firstPositionTrend==UpTrend) 
        {
          if( (CurPM[m_Session]==LongReverse) || (CurPM[m_Session]==LongReverseCon) )
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

              if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Buy_LR, true, UpTrend);
            }
          else if( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) )
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

              if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Sell_LC, true, DownTrend);
            }
          else if( (CurPM[m_Session]==DoubleLongReverse) || (CurPM[m_Session]==DLRCon) )
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

              if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Buy_DLR, true, UpTrend);
            }
          else if(CurPM[m_Session]==DLRCCon)
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

              if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Sell_DLRCC, true, DownTrend); 
            }
        }
      else if(PositionSummary[m_Session].firstPositionTrend==DownTrend)
        {
          if( (CurPM[m_Session]==LongReverse) || (CurPM[m_Session]==LongReverseCon) )
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

              if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Sell_LR, true, DownTrend);
            }
          else if( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) )
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

              if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Buy_LC, true, UpTrend);
            }
          else if( (CurPM[m_Session]==DoubleLongReverse) || (CurPM[m_Session]==DLRCon) )
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

              if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Sell_DLR, true, DownTrend);
            }
          else if(CurPM[m_Session]==DLRCCon)
            {
              m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
              m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

              if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                  ClosePositionByPID(m_Session, Buy_DLRCC, true, UpTrend); 
            }
        }
     }  */

   return;
  }
