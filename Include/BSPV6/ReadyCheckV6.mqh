//+------------------------------------------------------------------+
//|                                                 ReadyCheckV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV6/ExternVariables.mqh>
//#include <BSPV6/SessionManV6.mqh>
//#include <BSPV6/OpenCloseV6.mqh>
//#include <BSPV6/PyramidV6.mqh>



//------------------------------------------------------------------------
void PositionModeCheck(int m_Session )
{

   int m_BarCount=0;
   if(CurPM[m_Session]==LongReverse )                                           m_BarCount=CurBar-ReOC[m_Session].LRBar;
   else if(CurPM[m_Session]==LongCounter||CurPM[m_Session]==LongCounterCon )    m_BarCount=CurBar-ReOC[m_Session].LCBar; 
   else if(CurPM[m_Session]==DoubleLongReverse )                                m_BarCount=CurBar-ReOC[m_Session].DLRBar;

   if( PositionSummary[m_Session].firstPositionType == POSITION_TYPE_SELL )
     {
      //-----------------------------------------------------------------LongReverse Start
      if(  CurPM[m_Session]==MiddleReverse && 
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) &&
          (LASSTrend==DownTrend && LASLTrend==DownTrend) )
           PositionModeSet(m_Session, LongReverse);
           
      //-----------------------------------------------------------------LongReverseEnd Start
      if(  CurPM[m_Session]==LongReverse && 
          (TrendM==DownTrend && TrendL==DownTrend) &&
          (LASLTrend==DownTrend) &&
          (m_BarCount>EndBars || LASLBand<=SellLRELASLBand ) )
           PositionModeSet(m_Session, LongReverseEnd);
                     
      //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
      if( (CurPM[m_Session]==MiddleReverse || CurPM[m_Session]==LongReverse || CurPM[m_Session]==LongReverseEnd) &&
          (TrendM==DownTrend && TrendL==DownTrend) && 
          (LASLTrend==DownTrend) &&
          (WmaSValue<=(ReOC[m_Session].MRWmaS-ThBSPValue)) )
           PositionModeSet(m_Session, LongReverseCon);
      
      //-----------------------------------------------------------------LongCounter Start    
      if( (CurPM[m_Session]==MiddleReverse || CurPM[m_Session]==LongReverse ) && 
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) && 
          (LASSTrend==UpTrend && LASLTrend==UpTrend) )
           PositionModeSet(m_Session, LongCounter);
           
      //-----------------------------------------------------------------LongCounterEnd Start    
      if( (CurPM[m_Session]==LongCounter) && 
          (TrendM==UpTrend && TrendL==UpTrend) && 
          (m_BarCount>DLRBars) )
           PositionModeSet(m_Session, LongCounterEnd);
                      
      //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
      if( (CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterEnd) &&
          (TrendM==UpTrend && TrendL==UpTrend) &&
          (WmaSValue>=(ReOC[m_Session].LCWmaS+ThBSPValue)) )
           PositionModeSet(m_Session, LongCounterCon);
                 
      //-----------------------------------------------------------------DLR Start
      if( (CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon) &&
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) && 
          (LASSTrend==DownTrend && LASLTrend==DownTrend) &&
          (m_BarCount<=DLRBars) ) 
           PositionModeSet(m_Session, DoubleLongReverse);  

      //-----------------------------------------------------------------DLREnd Start
      if(  CurPM[m_Session]==DoubleLongReverse &&
          (TrendM==DownTrend && TrendL==DownTrend) && 
          (LASSTrend==DownTrend && LASLTrend==DownTrend) &&
          (m_BarCount>EndBars) ) 
           PositionModeSet(m_Session, DLREnd);  
                        
      //----------------------------------------------------------------- DLRCon, Pyramiding Start
      if(  CurPM[m_Session]==DoubleLongReverse &&
          (TrendM==DownTrend && TrendL==DownTrend) && 
          (LASLTrend==DownTrend) &&
          (WmaSValue<=(ReOC[m_Session].DLRWmaS-ThBSPValue) ) )
           PositionModeSet(m_Session, DLRCon);

      //----------------------------------------------------------------- DLRCCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendM==UpTrend && TrendL==UpTrend) && 
          (LASLTrend==UpTrend) &&
          (WmaSValue>=(ReOC[m_Session].DLRWmaS+ThBSPValue) )  )
           PositionModeSet(m_Session, DLRCCon);

      //----------------------------------------------------------------- LREnd, LRCon, DLRCon End
      if( ( CurPM[m_Session]==LongReverseEnd || CurPM[m_Session]==LongReverseCon || 
            CurPM[m_Session]==DLREnd         || CurPM[m_Session]==DLRCon ) && 
           (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) )
            PositionModeSet(m_Session, End);

      //-----------------------------------------------------------------LongCounterEnd, LongCounterCon, DLRCCon End     
      if( (CurPM[m_Session]==LongCounterEnd || CurPM[m_Session]==LongCounterCon || CurPM[m_Session]==DLRCCon) &&      
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) )
           PositionModeSet(m_Session, End);      
      
      //-----------------------------------------------------------------Too Stiff and End
      if( LASMBand<=SellStiffEndBand &&
          (TrendS==UpTrend && TrendM==UpTrend) &&
          (LASSTrend==UpTrend && LASLTrend==UpTrend) )
           PositionModeSet(m_Session, End);            
     }  
     
      
   if( PositionSummary[m_Session].firstPositionType== POSITION_TYPE_BUY )
     {                  
      //-----------------------------------------------------------------LongReverse Start
      if(  CurPM[m_Session]==MiddleReverse && 
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) &&
          (LASSTrend==UpTrend && LASLTrend==UpTrend) )
           PositionModeSet(m_Session, LongReverse);
           
      //-----------------------------------------------------------------LongReverseEnd Start
      if(  CurPM[m_Session]==LongReverse && 
          (TrendM==DownTrend && TrendL==UpTrend) &&
          (LASLTrend==UpTrend) &&
          (m_BarCount>EndBars || LASLBand>=BuyLRELASLBand ) )
           PositionModeSet(m_Session, LongReverseEnd);
                    
      //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
      if( (CurPM[m_Session]==MiddleReverse || CurPM[m_Session]==LongReverse || CurPM[m_Session]==LongReverseEnd) &&
          (TrendM==DownTrend && TrendL==UpTrend) && 
          (LASLTrend==UpTrend) &&
          (WmaSValue>=(ReOC[m_Session].MRWmaS+ThBSPValue)) )
           PositionModeSet(m_Session, LongReverseCon);
      
      //-----------------------------------------------------------------LongCounter Start    
      if( (CurPM[m_Session]==MiddleReverse || CurPM[m_Session]==LongReverse ) && 
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) && 
          (LASSTrend==DownTrend && LASLTrend==DownTrend) )
           PositionModeSet(m_Session, LongCounter);
           
      //-----------------------------------------------------------------LongCounterEnd Start    
      if( (CurPM[m_Session]==LongCounter) && 
          (TrendM==DownTrend && TrendL==DownTrend) && 
          (m_BarCount>DLRBars) )
           PositionModeSet(m_Session, LongCounterEnd);
                      
      //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
      if( (CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterEnd) &&
          (TrendM==DownTrend && TrendL==DownTrend) &&
          (WmaSValue<=(ReOC[m_Session].LCWmaS-ThBSPValue)) )
           PositionModeSet(m_Session, LongCounterCon);
                 
      //-----------------------------------------------------------------DLR Start
      if( (CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon) &&
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) && 
          (LASSTrend==UpTrend && LASLTrend==UpTrend) &&
          (m_BarCount<=DLRBars) ) 
           PositionModeSet(m_Session, DoubleLongReverse);  

      //-----------------------------------------------------------------DLREnd Start
      if(  CurPM[m_Session]==DoubleLongReverse &&
          (TrendM==UpTrend && TrendL==UpTrend) && 
          (LASSTrend==UpTrend && LASLTrend==UpTrend) &&
          (m_BarCount>EndBars) ) 
           PositionModeSet(m_Session, DLREnd);  
            
      //----------------------------------------------------------------- DLRCon, Pyramiding Start
      if( (CurPM[m_Session]==DoubleLongReverse || CurPM[m_Session]==DLREnd) &&
          (TrendM==UpTrend && TrendL==UpTrend) && 
          (LASLTrend==UpTrend) &&
          (WmaSValue>=(ReOC[m_Session].DLRWmaS+ThBSPValue) ) )
           PositionModeSet(m_Session, DLRCon);

      //----------------------------------------------------------------- DLRCCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendM==DownTrend && TrendL==DownTrend) && 
          (LASLTrend==DownTrend) &&
          (WmaSValue<=(ReOC[m_Session].DLRWmaS-ThBSPValue) )  )
           PositionModeSet(m_Session, DLRCCon);

      //----------------------------------------------------------------- LREnd, LRCon, DLREnd, DLRCon End
      if( ( CurPM[m_Session]==LongReverseEnd || CurPM[m_Session]==LongReverseCon || 
            CurPM[m_Session]==DLREnd         || CurPM[m_Session]==DLRCon ) && 
           (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) )
            PositionModeSet(m_Session, End);

      //-----------------------------------------------------------------LongCounterEnd, LongCounterCon, DLRCCon End     
      if( (CurPM[m_Session]==LongCounterEnd || CurPM[m_Session]==LongCounterCon || CurPM[m_Session]==DLRCCon) &&      
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) )
           PositionModeSet(m_Session, End);      
      
      //-----------------------------------------------------------------Too Stiff and End
      if( LASMBand>=BuyStiffEndBand &&
          (TrendS==DownTrend && TrendM==DownTrend) &&
          (LASSTrend==DownTrend && LASLTrend==DownTrend) )
           PositionModeSet(m_Session, End);         
     }  
}


//------------------------------------------------------------------------
void PositionModeSet(int m_Session, position_Mode m_PositionMode)
{
   BeforePM[m_Session] = CurPM[m_Session];
   CurPM[m_Session] = m_PositionMode;

   if(CurPM[m_Session] == MiddleReverse)
     {
      ReOC[m_Session].MRBar=CurBar;
      ReOC[m_Session].MRWmaS=WmaSValue;
     }           
   else if(CurPM[m_Session] == LongReverse) 
     {
      ReOC[m_Session].LRBar=CurBar;
      ReOC[m_Session].LRWmaS=WmaSValue;
     }  
   else if(CurPM[m_Session] == LongReverseEnd) 
     {
      ReOC[m_Session].LREndBar=CurBar;
      ReOC[m_Session].LREndWmaS=WmaSValue;
     }          
   else if(CurPM[m_Session] == LongReverseCon)
     {
      ReOC[m_Session].LRConBar=CurBar;
      ReOC[m_Session].LRConWmaS=WmaSValue;
     }
   else if(CurPM[m_Session] == LongCounter)
     {
      ReOC[m_Session].LCBar=CurBar;
      ReOC[m_Session].LCWmaS=WmaSValue;
     }        
   else if(CurPM[m_Session] == LongCounterEnd)
     {
      ReOC[m_Session].LCEndBar=CurBar;
      ReOC[m_Session].LCEndWmaS=WmaSValue;
     }        
   else if(CurPM[m_Session] == LongCounterCon)     
     {
      ReOC[m_Session].LCConBar=CurBar;
      ReOC[m_Session].LCConWmaS=WmaSValue;
     } 
   else if(CurPM[m_Session] == DoubleLongReverse)  
     {
      ReOC[m_Session].DLRBar=CurBar;
      ReOC[m_Session].DLRWmaS=WmaSValue;
     } 
   else if(CurPM[m_Session] == DLREnd)  
     {
      ReOC[m_Session].DLREndBar=CurBar;
      ReOC[m_Session].DLREndWmaS=WmaSValue;
     }   
   else if(CurPM[m_Session] == DLRCon)
     {             
      ReOC[m_Session].DLRConBar=CurBar;
      ReOC[m_Session].DLRConWmaS=WmaSValue;
     } 
   else if(CurPM[m_Session] == DLRCCon)            
     {
      ReOC[m_Session].DLRCConBar=CurBar;
      ReOC[m_Session].DLRCConWmaS=WmaSValue;
     } 
   else if(CurPM[m_Session] == End)              
     { 
      ReOC[m_Session].EndBar=CurBar; 
      ReOC[m_Session].EndWmaS=WmaSValue;
     }
   
   return;
}

//-------------------------------------------------------------------+
void OpenReadyCheck(int m_Session)
{

//   if(CurPM[m_Session]!=NoMode) return;

//  Sell Open Ready Check
   if( !SellOpenReady.LASMReady && (LASMBand>=BandP2) ) 
      SellOpenReady.LASMReady = true;  

   if( SellOpenReady.LASMReady && (TrendS==DownTrend) && (TrendM==DownTrend) && 
       (LASSTrend==DownTrend) && (LASMTrend==DownTrend) && (LASLTrend==DownTrend) ) 
     {
      SellOpenReady.TrendReady = true; 
      PositionModeSet(m_Session, MiddleReverse);
      if(TrendL==DownTrend) PositionModeSet(m_Session, LongReverse);
     } 
   else SellOpenReady.TrendReady = false; 

//  Buy Open Ready Check      
   if( !BuyOpenReady.LASMReady && (LASMBand<=BandM2) ) 
      BuyOpenReady.LASMReady = true;

   if( BuyOpenReady.LASMReady && (TrendS==UpTrend) && (TrendM==UpTrend) && 
       (LASSTrend==UpTrend) && (LASMTrend==UpTrend) && (LASLTrend==UpTrend)) 
     {
      BuyOpenReady.TrendReady = true;
      PositionModeSet(m_Session, MiddleReverse);
      if(TrendL==UpTrend) PositionModeSet(m_Session, LongReverse);
     }
   else BuyOpenReady.TrendReady = false;        
}   



//-------------------------------------------------------------------+
void OpenReadyReset(void)
{
   BuyOpenReady.LASMReady = false;
   BuyOpenReady.TrendReady = false;

   SellOpenReady.LASMReady = false;
   SellOpenReady.TrendReady = false;
}

//--------------------------------------------------------------------+
void ReOCReset(int m_Session)
{
   ReOC[m_Session].MRBar=0;
   ReOC[m_Session].LRBar=0;
   ReOC[m_Session].LRConBar=0;
   ReOC[m_Session].LCBar=0;
   ReOC[m_Session].LCConBar=0;   
   ReOC[m_Session].DLRBar=0;
   ReOC[m_Session].DLRConBar=0;
   ReOC[m_Session].DLRCConBar=0;
   ReOC[m_Session].EndBar=0;

}
