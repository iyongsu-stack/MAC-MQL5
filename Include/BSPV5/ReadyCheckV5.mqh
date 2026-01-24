//+------------------------------------------------------------------+
//|                                                 ReadyCheckV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV5/ExternVariables.mqh>
//#include <BSPV5/SessionManV5.mqh>
//#include <BSPV5/OpenCloseV5.mqh>



//------------------------------------------------------------------------
void PositionModeCheck(int m_Session )
{

   if(CurPM[m_Session]==NoMode) return;

   int m_BarCount=0;
      
   if(CurPM[m_Session]==MiddleReverse)               m_BarCount=CurBar-ReOC[m_Session].MRBar;
   else if(CurPM[m_Session]==LongReverse)            m_BarCount=CurBar-ReOC[m_Session].LRBar;
   else if(CurPM[m_Session]==LongCounter)            m_BarCount=CurBar-ReOC[m_Session].LCBar; 
   else if(CurPM[m_Session]==DoubleLongReverse)      m_BarCount=CurBar-ReOC[m_Session].DLRBar; 
   else if(CurPM[m_Session]==End)                    m_BarCount=CurBar-ReOC[m_Session].EndBar;  
   else if(CurPM[m_Session]==ReOpenReverse)          m_BarCount=CurBar-ReOC[m_Session].RORBar;

   if( PositionSummary[m_Session].firstPositionType == POSITION_TYPE_SELL )
     {

      //-----------------------------------------------------------------LongReverse Start
      if( CurPM[m_Session]==MiddleReverse && 
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) &&
          (LASLTrend==DownTrend) )
           PositionModeSet(m_Session, LongReverse);
      
      //-----------------------------------------------------------------LongReverseCon Start
      if( (CurPM[m_Session]==MiddleReverse || CurPM[m_Session]==LongReverse) &&
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) && 
          (LASLBand<=SellLRConLASLBand || m_BarCount>=LRConBars) )
           PositionModeSet(m_Session, LongReverseCon);           
      
      //-----------------------------------------------------------------LongCounter Start    
      if( (CurPM[m_Session]==MiddleReverse || CurPM[m_Session]==LongReverse) && 
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) && 
          (LASSTrend==UpTrend && LASLTrend==UpTrend) &&
          (LASLBand>=SellLCLASLBand) )
           PositionModeSet(m_Session, LongCounter);
           
      //-----------------------------------------------------------------LongCounterCon Start
      if( CurPM[m_Session]==LongCounter &&
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) &&
          (m_BarCount>DLRBars) )
           PositionModeSet(m_Session, LongCounterCon);
           
      //-----------------------------------------------------------------DLR Start and Noise Setting
      if( CurPM[m_Session]==LongCounter &&
          (TrendS==DownTrend && TrendL==DownTrend && TrendL==DownTrend) && 
          (LASSTrend==DownTrend) && (LASLTrend==DownTrend) &&
          (m_BarCount<=DLRBars) ) 
            {
             PositionModeSet(m_Session, DoubleLongReverse);  
             if(DLRNoiseTF==true) NoiseSet(m_Session);         
            }

      //-----------------------------------------------------------------DLR Noise Endure -> DLRCon 
      if( CurPM[m_Session]==DoubleLongReverse &&
          (LASSTrend==DownTrend && LASMTrend==DownTrend && LASLTrend==DownTrend) &&
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) && 
          (DLRNoiseTF==true && WmaLValue<NoiseDownLimit[m_Session]) )
            PositionModeSet(m_Session, DLRCon);  

      //-----------------------------------------------------------------DLR Noise Endure -> DLRCCon
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) && 
          (DLRNoiseTF==true && WmaLValue>NoiseUpLimit[m_Session]) ) 
            PositionModeSet(m_Session, DLRCCon);  
 
      //-----------------------------------------------------------------LongCounterCon, DLRCCon End     
      if( (CurPM[m_Session]==LongCounterCon || CurPM[m_Session]==DLRCCon) &&      
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) )
           PositionModeSet(m_Session, End);      
      
      //-----------------------------------------------------------------Too Stiff and End
      if( LASMBand<=BandM2 &&
          (TrendS==UpTrend && TrendM==UpTrend) &&
          (LASSTrend==UpTrend && LASMTrend==UpTrend && LASLTrend==UpTrend) )
            PositionModeSet(m_Session, End);                      

      //-----------------------------------------------------------------DLRCon, LongReverseCon End-> ReOpen
      if( CurPM[m_Session]==End && 
          ReOC[m_Session].EndLASMBand<=(SellROLASMBand-ReOC[m_Session].ReOpenTime) &&
          (m_BarCount<=ReOpenBars && ReOC[m_Session].ReOpenTime<=ReOpenTimes) && 
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) &&
          (LASSTrend==DownTrend && LASLTrend==DownTrend) ) 
            PositionModeSet(m_Session, ReOpenReverse);

      //-----------------------------------------------------------------LongReverseCon, DLRCon End
      if( ( CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon || CurPM[m_Session]==ReOpenReverse) && 
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) &&
          (LASSTrend==UpTrend && LASMTrend==UpTrend && LASLTrend==UpTrend) )
            PositionModeSet(m_Session, End);
     }  
     
      
   if( PositionSummary[m_Session].firstPositionType== POSITION_TYPE_BUY )
     {       
            
      //-----------------------------------------------------------------LongReverse Start
      if( CurPM[m_Session]==MiddleReverse && 
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) &&
          (LASLTrend==UpTrend) )
           PositionModeSet(m_Session, LongReverse);
      
      //-----------------------------------------------------------------LongReverseCon Start
      if( (CurPM[m_Session]==MiddleReverse || CurPM[m_Session]==LongReverse) &&
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) && 
          (LASLBand>=BuyLRConLASLBand || m_BarCount>=LRConBars) )
           PositionModeSet(m_Session, LongReverseCon);           
      
      //-----------------------------------------------------------------LongCounter Start    
      if( (CurPM[m_Session]==MiddleReverse || CurPM[m_Session]==LongReverse) && 
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) && 
          (LASSTrend==DownTrend && LASLTrend==DownTrend) &&
          (LASLBand<=BuyLCLASLBand) )
           PositionModeSet(m_Session, LongCounter);
           
      //-----------------------------------------------------------------LongCounterCon Start
      if( CurPM[m_Session]==LongCounter &&
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) &&
          (m_BarCount>DLRBars) )
           PositionModeSet(m_Session, LongCounterCon);
           
      //-----------------------------------------------------------------DLR Start and Noise Setting
      if( CurPM[m_Session]==LongCounter &&
          (TrendS==UpTrend && TrendL==UpTrend && TrendL==UpTrend) && 
          (LASSTrend==UpTrend) && (LASLTrend==UpTrend) &&
          (m_BarCount<=DLRBars) ) 
            {
             PositionModeSet(m_Session, DoubleLongReverse);  
             if(DLRNoiseTF==true) NoiseSet(m_Session);         
            }

      //-----------------------------------------------------------------DLR Noise Endure -> DLRCon 
      if( CurPM[m_Session]==DoubleLongReverse &&
          (LASSTrend==UpTrend && LASMTrend==UpTrend && LASLTrend==UpTrend) &&
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) && 
          (DLRNoiseTF==true && WmaLValue>NoiseUpLimit[m_Session]) )
            PositionModeSet(m_Session, DLRCon);  

      //-----------------------------------------------------------------DLR Noise Endure -> DLRCCon
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) && 
          (DLRNoiseTF==true && WmaLValue<NoiseDownLimit[m_Session]) ) 
            PositionModeSet(m_Session, DLRCCon);  
 
      //-----------------------------------------------------------------LongCounterCon, DLRCCon End     
      if( (CurPM[m_Session]==LongCounterCon || CurPM[m_Session]==DLRCCon) &&      
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) )
           PositionModeSet(m_Session, End);      
      
      //-----------------------------------------------------------------Too Stiff and End
      if( LASMBand>=BandP2 &&
          (TrendS==DownTrend && TrendM==DownTrend) &&
          (LASSTrend==DownTrend && LASMTrend==DownTrend && LASLTrend==DownTrend) )
            PositionModeSet(m_Session, End);         

      //-----------------------------------------------------------------DLRCon, LongReverseCon End-> ReOpen
      if( CurPM[m_Session]==End && 
          ReOC[m_Session].EndLASMBand>=(BuyROLASMBand+ReOC[m_Session].ReOpenTime) &&
          (m_BarCount<=ReOpenBars && ReOC[m_Session].ReOpenTime<=ReOpenTimes) && 
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) &&
          (LASSTrend==UpTrend && LASLTrend==UpTrend) ) 
            PositionModeSet(m_Session, ReOpenReverse);

      //-----------------------------------------------------------------LongReverseCon, ReOpen, DLRCon End
      if( ( CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon || CurPM[m_Session]==ReOpenReverse) && 
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) &&
          (LASSTrend==DownTrend && LASMTrend==DownTrend && LASLTrend==DownTrend) )
            PositionModeSet(m_Session, End);
     }  
     
     if( (CurPM[m_Session]==End) && m_BarCount>ReOpenBars)
            PositionModeSet(m_Session, NoMode);
}


//------------------------------------------------------------------------
void PositionModeSet(int m_Session, position_Mode m_PositionMode)
{
   BeforePM[m_Session] = CurPM[m_Session];
   CurPM[m_Session] = m_PositionMode;

   if(CurPM[m_Session] == MiddleReverse)           ReOC[m_Session].MRBar=CurBar;
   else if(CurPM[m_Session] == LongReverse)        ReOC[m_Session].LRBar = CurBar;
   else if(CurPM[m_Session] == LongReverseCon)     ReOC[m_Session].LRConBar = CurBar;
   else if(CurPM[m_Session] == LongCounter)        ReOC[m_Session].LCBar = CurBar;
   else if(CurPM[m_Session] == LongCounterCon)     ReOC[m_Session].LCConBar = CurBar;
   else if(CurPM[m_Session] == DoubleLongReverse)  ReOC[m_Session].DLRBar = CurBar;
   else if(CurPM[m_Session] == DLRCon)             ReOC[m_Session].DLRConBar = CurBar;
   else if(CurPM[m_Session] == DLRCCon)            ReOC[m_Session].DLRCConBar = CurBar;
   else if(CurPM[m_Session] == End)              
     { 
      ReOC[m_Session].EndBar = CurBar; 
      ReOC[m_Session].EndLASMBand=LASMBand; 
     }
   else if(CurPM[m_Session] == ReOpenReverse)    
     { 
      ReOC[m_Session].RORBar = CurBar;
      ReOC[m_Session].ReOpenTime++;         
     }
   else if(CurPM[m_Session] == NoMode)             ReOC[m_Session].NoModeBar = CurBar;
   
   return;
}


void NoiseSet(int m_Session)
{
   double m_Friction=MathAbs(BSPWmaValue)/WmaPeriodL;
   
   if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_SELL)
     {
      NoiseUpLimit[m_Session] =  WmaLValue + m_Friction*NoiseUpMultiFactor;
      NoiseDownLimit[m_Session] = WmaLValue - m_Friction*NoiseDownMultiFactor;     
     }
   else
     {
      NoiseUpLimit[m_Session] =  WmaLValue + m_Friction*NoiseDownMultiFactor;
      NoiseDownLimit[m_Session] = WmaLValue - m_Friction*NoiseUpMultiFactor;        
     }  
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
   ReOC[m_Session].EndLASMBand=BandM0; 
   ReOC[m_Session].RORBar=0;
   ReOC[m_Session].NoModeBar=0;
   ReOC[m_Session].ReOpenTime=0;

}
/*
//--------------------------------------------------------------------+
void BuyAble(void)
{
   BuyOpenReady.Able = true;
}

void SellAble(void)
{
   SellOpenReady.Able = true;
}

void BuyDisable(void)
{
   BuyOpenReady.Able = false;
}

void SellDisable(void)
{
   SellOpenReady.Able = false;
}

bool BuyAbled(void)
{
   if(BuyOpenReady.Able == true) return(true);
   return(false);
}

bool SellAbled(void)
{
   if(SellOpenReady.Able == true) return(true);
   return(false);
}
  
*/
