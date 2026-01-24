//+------------------------------------------------------------------+
//|                                                   StopLossV7.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV7/ExternVariables.mqh>
//#include <BSPV7/OpenCloseV7.mqh>

void StopLossCheck(void)
{
   if( BSPValue>=MathAbs(SLBSPValue) && !isStopLossDownTrend) 
     {
      StopDownTrend();
      isStopLossDownTrend=true;
     } 
   else if( BSPValue<=-MathAbs(SLBSPValue)&& !isStopLossUpTrend) 
     {
      StopUpTrend();
      isStopLossUpTrend=true;
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
