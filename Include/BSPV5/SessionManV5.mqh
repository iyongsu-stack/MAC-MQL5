//+------------------------------------------------------------------+
//|                                                 SessionManV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"


//#include <BSPV5/ExternVariables.mqh>
//#include <BSPV5/ReadyCheckV5.mqh>

void SessionManage(int m_Session)
{
   bool m_ReadyCheck=false;
   
   if( CurBar==ReOC[m_Session].MRBar || CurBar==ReOC[m_Session].LRBar )
     {
      StopReadyCheck(m_Session);     
     }
   else if( CurBar==ReOC[m_Session].LRConBar  || CurBar==ReOC[m_Session].LCConBar   ||
            CurBar==ReOC[m_Session].DLRConBar || CurBar==ReOC[m_Session].DLRCConBar ||
            CurBar==ReOC[m_Session].EndBar    || CurBar==ReOC[m_Session].RORBar       )
     {
      m_ReadyCheck=NextSession(m_Session);     
     }
   else if(CurBar==ReOC[m_Session].NoModeBar)           
     { 
      m_ReadyCheck=NextSession(m_Session);
     }

   if(StartTrading && m_ReadyCheck) OpenReadyCheck(SessionMan.CurSession);
     
}

//-------------------------------------------------------------------------------
bool NextSession(int m_Session)
{

   int t_Session;
   
   if(SessionMan.CurSession==m_Session && SessionMan.CanGo==false)
     {
      for(t_Session=0;t_Session<TotalSession;t_Session++)
        {
         if(CurPM[t_Session]==NoMode)
           {
            SessionMan.CurSession=t_Session;
            SessionMan.CanGo=true;  
            OpenReadyReset();
            return(true);
           } 
        }
     }
      
   return(false);
}

//---------------------------------------------------------------------------------
void StopReadyCheck(int m_Session)
{
     if(SessionMan.CurSession==m_Session) SessionMan.CanGo=false;  
}