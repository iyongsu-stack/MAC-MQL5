//+------------------------------------------------------------------+
//|                                                 SessionManV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

void SessionManage(int m_Session)
{
   bool m_ReadyCheck=false;
   
   if( (CurBar==ReOC[m_Session].MRBar || CurBar==ReOC[m_Session].LRBar) &&
       SessionMan.CurSession==m_Session  )
             StopReadyCheck(m_Session);     

   if( ( CurBar==ReOC[m_Session].LRConBar  || CurBar==ReOC[m_Session].LCConBar || 
         CurBar==ReOC[m_Session].DLRConBar || CurBar==ReOC[m_Session].DLRCConBar ) &&
         SessionMan.LastSession==m_Session )
             SessionMan.CanGoBand=true;   

   if( CurBar==ReOC[m_Session].EndBar && m_Session==SessionMan.LastSession )
     {  
       SessionMan.CanGoBand=true;
       SessionMan.CanGoTrend=true; 
       OpenReadyReset(SessionMan.LastSession);
                  
     }
}


//---------------------------------------------------------------------------------
void StopReadyCheck(int m_Session)
{
   for(int t_Session=0;t_Session<TotalSession;t_Session++)
     {
      if( t_Session!=m_Session && PositionSummary[t_Session].totalNumPositions==0)
        {
         SessionMan.LastSession=m_Session;
         SessionMan.CurSession=t_Session;
         SessionMan.CanGoBand=false;  
         SessionMan.CanGoTrend=false; 
                  
         return;
        } 
     }
}