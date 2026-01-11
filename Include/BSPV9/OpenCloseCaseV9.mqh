//+------------------------------------------------------------------+
//|                                              OpenCloseCaseV8.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"


//------------------------------------------------------------------------
void MyOpenPosition(int m_Session)
{
   if( (OpenCloseCase==OCCase1) || (OpenCloseCase==OCCase2) )
      MyOpenPositionCase1_2(m_Session);   //PM 바뀔때마다 오픈   
   else if(OpenCloseCase==OCCase3)
      MyOpenPositionCase3(m_Session);     //Con 모드에서만 오픈
}


//------------------------------------------------------------------------
void MyClosePosition(int m_Session)
{
   if( (OpenCloseCase==OCCase1) || (OpenCloseCase==OCCase3) )
      MyClosePositionCase1_3(m_Session);  //PM 바뀔때마다 클로즈
   else if(OpenCloseCase==OCCase2)
      MyClosePositionCase2(m_Session);  //Con 모드시작시 반대 포지션 클로즈 
}


//-------------------------------------------------------------------------
void MyOpenPositionCase1_2(int m_Session)
{
   position_ID m_PositionID=No_Signal;
   ENUM_POSITION_TYPE m_PositionType=POSITION_TYPE_BUY;
   double m_LotSizeMulti=1.0;
   trend m_Trend=NoTrend;

     
   if(CurPM[m_Session]==LongReverse)
     {
      if(OpenReady[m_Session].BuyTrendReady)
        {
         m_PositionID=Buy_LR;
         m_PositionType=POSITION_TYPE_BUY;  
        } 
      else if(OpenReady[m_Session].SellTrendReady)
        {
         m_PositionID=Sell_LR;
         m_PositionType=POSITION_TYPE_SELL;  
        }
     }
/*   else if(CurPM[m_Session]==LongCounter)   //Caution OpenPosition at DLRCCon---
     {
      if(PositionSummary[m_Session].firstPositionTrend==UpTrend) 
        {
         m_PositionID=Sell_LC;
         m_PositionType=POSITION_TYPE_SELL;
        }
      else 
        {
         m_PositionID=Buy_LC;
         m_PositionType=POSITION_TYPE_BUY;
        }     
     }  
   else if(CurPM[m_Session]==DoubleLongReverse)
     {
      if(PositionSummary[m_Session].firstPositionTrend==UpTrend) 
        {
         m_PositionID=Buy_DLR;
         m_PositionType=POSITION_TYPE_BUY;
        }
      else 
        {
         m_PositionID=Sell_DLR;
         m_PositionType=POSITION_TYPE_SELL;
        }     
     }
*/

   if(CurPM[m_Session]==LongReverseCon /*|| CurPM[m_Session]==DLRCon  || 
      CurPM[m_Session]==LongCounterCon || CurPM[m_Session]==DLRCCon*/  )
     {      
      if(PositionSummary[m_Session].firstPositionTrend==UpTrend) 
        {
         if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon)
           { 
            if(CurPM[m_Session]==LongReverseCon)  m_PositionID=Buy_LR;
            else if(CurPM[m_Session]==DLRCon)  m_PositionID=Buy_DLR;
            
            m_PositionType=POSITION_TYPE_BUY;
            m_Trend=UpTrend;
           } 
         else
           {
            if(CurPM[m_Session]==LongCounterCon)  m_PositionID=Sell_LC;
            else if(CurPM[m_Session]==DLRCCon)  m_PositionID=Sell_DLRCC;
            
            m_PositionType=POSITION_TYPE_SELL;
            m_Trend=DownTrend;
           } 
        }
      else 
        {
         if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon )
           {
            if(CurPM[m_Session]==LongReverseCon)  m_PositionID=Sell_LR;
            else if(CurPM[m_Session]==DLRCon)  m_PositionID=Sell_DLR;
            
            m_PositionType=POSITION_TYPE_SELL;
            m_Trend=DownTrend;
           } 
         else
           {
            if(CurPM[m_Session]==LongCounterCon)  m_PositionID=Buy_LC;
            else if(CurPM[m_Session]==DLRCCon)  m_PositionID=Buy_DLRCC;
            
            m_PositionType=POSITION_TYPE_BUY;
            m_Trend=UpTrend;
           } 
        }
      PositionSummary[m_Session].pyramidStarted=true;  
      PositionSummary[m_Session].pyramidPID=m_PositionID;
      PositionSummary[m_Session].pyramidTrend=m_Trend;  
      PositionSummary[m_Session].lastWmaS=WmaSValue;
     }        

   if(CurPM[m_Session]==LongReverse)
      m_LotSizeMulti=m_LotSizeMulti*PM_LR_Multi;
/*   else if(CurPM[m_Session]==LongCounter)
      m_LotSizeMulti=m_LotSizeMulti*PM_LC_Multi;
   else if(CurPM[m_Session]==DoubleLongReverse)
      m_LotSizeMulti=m_LotSizeMulti*PM_DLR_Multi;
*/   else if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon)
      m_LotSizeMulti=m_LotSizeMulti*PM_LRCnDLRC_Multi;
   else if(CurPM[m_Session]==LongCounterCon || CurPM[m_Session]==DLRCCon)
      m_LotSizeMulti=m_LotSizeMulti*PM_LCCnDLRCC_Multi;

   if(PositionSummary[m_Session].pyramidStarted)
      PositionSummary[m_Session].lastSizeMulti=m_LotSizeMulti;

   if(m_PositionID!=No_Signal && m_LotSizeMulti!=0.0) 
      OpenPositionByPID(m_PositionType, m_LotSizeMulti, m_Session, m_PositionID);

   return;     
}


//-------------------------------------------------------------------------
void MyOpenPositionCase3(int m_Session)
{
   position_ID m_PositionID=No_Signal;
   ENUM_POSITION_TYPE m_PositionType=POSITION_TYPE_BUY;
   double m_LotSizeMulti=1.0;
   trend m_Trend=NoTrend;

   if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon  || 
      CurPM[m_Session]==LongCounterCon || CurPM[m_Session]==DLRCCon  )
     {      
      if(PositionSummary[m_Session].firstPositionTrend==UpTrend) 
        {
         if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon)
           { 
            if(CurPM[m_Session]==LongReverseCon)  m_PositionID=Buy_LR;
            else if(CurPM[m_Session]==DLRCon)  m_PositionID=Buy_DLR;
            
            m_PositionType=POSITION_TYPE_BUY;
            m_Trend=UpTrend;
           } 
         else
           {
            if(CurPM[m_Session]==LongCounterCon)  m_PositionID=Sell_LC;
            else if(CurPM[m_Session]==DLRCCon)  m_PositionID=Sell_DLRCC;
            
            m_PositionType=POSITION_TYPE_SELL;
            m_Trend=DownTrend;
           } 
        }
      else 
        {
         if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon )
           {
            if(CurPM[m_Session]==LongReverseCon)  m_PositionID=Sell_LR;
            else if(CurPM[m_Session]==DLRCon)  m_PositionID=Sell_DLR;
            
            m_PositionType=POSITION_TYPE_SELL;
            m_Trend=DownTrend;
           } 
         else
           {
            if(CurPM[m_Session]==LongCounterCon)  m_PositionID=Buy_LC;
            else if(CurPM[m_Session]==DLRCCon)  m_PositionID=Buy_DLRCC;
            
            m_PositionType=POSITION_TYPE_BUY;
            m_Trend=UpTrend;
           } 
        }
      PositionSummary[m_Session].pyramidStarted=true;  
      PositionSummary[m_Session].pyramidPID=m_PositionID;
      PositionSummary[m_Session].pyramidTrend=m_Trend;  
      PositionSummary[m_Session].lastWmaS=WmaSValue;
     }        
   
   if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon)
      m_LotSizeMulti=m_LotSizeMulti*PM_LRCnDLRC_Multi;
   else if(CurPM[m_Session]==LongCounterCon || CurPM[m_Session]==DLRCCon)
      m_LotSizeMulti=m_LotSizeMulti*PM_LCCnDLRCC_Multi;

   if(PositionSummary[m_Session].pyramidStarted)
      PositionSummary[m_Session].lastSizeMulti=m_LotSizeMulti;

   if(m_PositionID!=No_Signal && m_LotSizeMulti!=0.0) 
      OpenPositionByPID(m_PositionType, m_LotSizeMulti, m_Session, m_PositionID);
     
   return;     
}


//-----------------------------------------------------------------------
void MyClosePositionCase1_3(int m_Session)
{
   
   if(CurPM[m_Session]!=End &&
      PositionSummary[m_Session].firstPositionTrend==UpTrend) 
     {
      if( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) )
        {
         ClosePositionByPID(m_Session, Buy_LR);
        }
/*      else if( (CurPM[m_Session]==DoubleLongReverse) || (CurPM[m_Session]==DLRCon) )
        {
         ClosePositionByPID(m_Session, Sell_LC);
        }
      else if(CurPM[m_Session]==DLRCCon)
        {
         ClosePositionByPID(m_Session, Buy_DLR);        
        } 
     }
   else if(CurPM[m_Session]!=End &&
           PositionSummary[m_Session].firstPositionTrend==DownTrend)
     {
      if( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) )
        {
         ClosePositionByPID(m_Session, Sell_LR);
        }
      else if( (CurPM[m_Session]==DoubleLongReverse) || (CurPM[m_Session]==DLRCon) )
        {
         ClosePositionByPID(m_Session, Buy_LC);
        }
      else if(CurPM[m_Session]==DLRCCon)
        {
         ClosePositionByPID(m_Session, Sell_DLR);        
        } 
*/     }              
//   else if(CurPM[m_Session]==End) 
//      ClosePositionBySession(m_Session);
   
   return;     
}


//-----------------------------------------------------------------------
void MyClosePositionCase2(int m_Session)
{
   
   if(CurPM[m_Session]!=End &&
      PositionSummary[m_Session].firstPositionTrend==UpTrend) 
     {
      if( ( (CurPM[m_Session]==LongCounter) && (BeforePM[m_Session]==LongReverseCon) ) || 
          (CurPM[m_Session]==LongCounterCon) )
        {
         ClosePositionByPID(m_Session, Buy_LR, true, UpTrend);
        }
      else if( ( (CurPM[m_Session]==DoubleLongReverse) && (BeforePM[m_Session]==LongCounterCon) ) ||
               (CurPM[m_Session]==DLRCon) ) 
        {
         ClosePositionByPID(m_Session, Sell_LC, true, DownTrend);
        }      
      else if(CurPM[m_Session]==DLRCCon)
        {
         ClosePositionByPID(m_Session, Buy_LR); 
         ClosePositionByPID(m_Session, Buy_DLR);        
        } 
     }
   else if(CurPM[m_Session]!=End &&
           PositionSummary[m_Session].firstPositionTrend==DownTrend)
     {
      if( ( (CurPM[m_Session]==LongCounter) && (BeforePM[m_Session]==LongReverseCon) ) || 
          (CurPM[m_Session]==LongCounterCon) )
        {
         ClosePositionByPID(m_Session, Sell_LR, true, DownTrend);
        }
      else if( ( (CurPM[m_Session]==DoubleLongReverse) && (BeforePM[m_Session]==LongCounterCon) ) ||
               (CurPM[m_Session]==DLRCon) )
        {
         ClosePositionByPID(m_Session, Buy_LC, true, UpTrend );
        }
      else if(CurPM[m_Session]==DLRCCon)
        {
         ClosePositionByPID(m_Session, Sell_LR);
         ClosePositionByPID(m_Session, Sell_DLR);        
        } 
     }              
   else if(CurPM[m_Session]==End) 
      ClosePositionBySession(m_Session);
   
   return;     
}
