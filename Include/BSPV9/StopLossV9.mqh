//+------------------------------------------------------------------+
//|                                                   StopLossV7.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

void StopLossCheck(void)
{
   static int m_StopDownBar=0, m_StopUpBar=0;

   if( (BSPValue>=MathAbs(SLBSPValue)) && (CurBar!=m_StopDownBar) ) 
   {
      StopDownTrend();
      m_StopDownBar=CurBar;
   }

   else if( (BSPValue<=-MathAbs(SLBSPValue)) && (CurBar!=m_StopUpBar) ) 
   {
      StopUpTrend();
      m_StopUpBar=CurBar;
   }

   return; 
}

///-----------------------------------------------------------------------+++
void StopDownTrend(void)
{
   for(int m_Session=0;m_Session<TotalSession;m_Session++)
     {
      if(PositionSummary[m_Session].currentNumPositions!=0) 
        {
         ClosePositionByPID(m_Session, Sell_MR, true, DownTrend);
         ClosePositionByPID(m_Session, Sell_LR, true, DownTrend);
         ClosePositionByPID(m_Session, Sell_LC, true, DownTrend);
         ClosePositionByPID(m_Session, Sell_DLR, true, DownTrend );
         ClosePositionByPID(m_Session, Sell_DLRCC, true, DownTrend);
        }
     }    
}

///-----------------------------------------------------------------------+++
void StopUpTrend(void)
{
   for(int m_Session=0;m_Session<TotalSession;m_Session++)
     {
      if(PositionSummary[m_Session].currentNumPositions!=0) 
        {
         ClosePositionByPID(m_Session, Buy_MR, true, UpTrend);
         ClosePositionByPID(m_Session, Buy_LR, true, UpTrend);
         ClosePositionByPID(m_Session, Buy_LC, true, UpTrend);
         ClosePositionByPID(m_Session, Buy_DLR, true, UpTrend);
         ClosePositionByPID(m_Session, Buy_DLRCC, true, UpTrend);
        }
     }    

}
