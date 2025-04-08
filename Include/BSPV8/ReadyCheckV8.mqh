//+------------------------------------------------------------------+
//|                                                 ReadyCheckV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV7/ExternVariables.mqh>
//#include <BSPV7/SessionManV7.mqh>
//#include <BSPV7/OpenCloseV7.mqh>
//#include <BSPV7/PyramidV7.mqh>



//------------------------------------------------------------------------
void PositionModeCheck(int m_Session )
{

   if(CurPM[m_Session]==NoMode) return;

   int m_BarCount=0;
   
   if(CurPM[m_Session]!=End) m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;  


   if( PositionSummary[m_Session].firstPositionTrend == DownTrend )
     {
           
      //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
      if( (CurPM[m_Session]==LongReverse) &&
          (TrendLL==DownTrend) && 
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue)) )
           PositionModeSet(m_Session, LongReverseCon);
      //-----------------------------------------------------------------LongReverse, LongReverseCon End    
      if( ( (CurPM[m_Session]==LongReverse) || (CurPM[m_Session]==LongReverseCon) ) &&
          (TrendLL==UpTrend) && 
          ( (m_BarCount>PMBars)||(LASLBand<SellLCLASLBand) ) )
           PositionModeSet(m_Session, End);
      //-----------------------------------------------------------------LongCounter Start    
      if( ( (CurPM[m_Session]==LongReverse) || (CurPM[m_Session]==LongReverseCon) ) &&
          (TrendLL==UpTrend) && 
          (m_BarCount<=PMBars) && 
          (LASLBand>=SellLCLASLBand) )
           PositionModeSet(m_Session, LongCounter);
      //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
      if( (CurPM[m_Session]==LongCounter) &&
          (TrendLL==UpTrend) &&
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue)) )
           PositionModeSet(m_Session, LongCounterCon);
      //-----------------------------------------------------------------LongCounter, LongCounterCon End
      if( ( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) ) &&
          (TrendLL==DownTrend) &&
          (m_BarCount>PMBars) )
           PositionModeSet(m_Session, End);
      //-----------------------------------------------------------------DLR Start
      if( (CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon) &&
          (TrendLL==DownTrend) && 
          (m_BarCount<=PMBars) ) 
           PositionModeSet(m_Session, DoubleLongReverse);  
      //----------------------------------------------------------------- DLRCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==DownTrend) && 
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue) ) )
           PositionModeSet(m_Session, DLRCon);
      //----------------------------------------------------------------- DLRCCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==UpTrend) && 
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+DLRCConThValue) )  )
           PositionModeSet(m_Session, DLRCCon);
      //----------------------------------------------------------------- DLRCon End
      if(  CurPM[m_Session]==DLRCon && 
          (TrendLL==UpTrend) &&
          (LASMTrend==UpTrend) )
           PositionModeSet(m_Session, End);
      //----------------------------------------------------------------- DLRCCon End     
      if(  CurPM[m_Session]==DLRCCon &&      
          (TrendLL==DownTrend) &&
          (LASMTrend==DownTrend) )
           PositionModeSet(m_Session, End);      
     }  
           
   if( PositionSummary[m_Session].firstPositionTrend== UpTrend )
     {       
            
      //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
      if( (CurPM[m_Session]==LongReverse) &&
          (TrendLL==UpTrend) && 
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue)) )
           PositionModeSet(m_Session, LongReverseCon);
      //-----------------------------------------------------------------LongReverse, LongReverseCon End    
      if( ( (CurPM[m_Session]==LongReverse) || (CurPM[m_Session]==LongReverseCon) ) &&
          (TrendLL==DownTrend) &&
          ( (m_BarCount>PMBars)||(LASLBand>BuyLCLASLBand) ) )
           PositionModeSet(m_Session, End);
      //-----------------------------------------------------------------LongCounter Start    
      if( ( (CurPM[m_Session]==LongReverse) || (CurPM[m_Session]==LongReverseCon) ) &&
          (TrendLL==DownTrend) && 
          (m_BarCount<=PMBars) && 
          (LASLBand<=BuyLCLASLBand) )
           PositionModeSet(m_Session, LongCounter);
      //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
      if( (CurPM[m_Session]==LongCounter) &&
          (TrendLL==DownTrend) &&
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue)) )
           PositionModeSet(m_Session, LongCounterCon);
      //-----------------------------------------------------------------LongCounter, LongCounterCon End
      if( ( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) ) &&
          (TrendLL==UpTrend) &&
          (m_BarCount>PMBars) )
           PositionModeSet(m_Session, End);
      //-----------------------------------------------------------------DLR Start
      if( (CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon) &&
          (TrendLL==UpTrend) && 
          (m_BarCount<=PMBars) ) 
           PositionModeSet(m_Session, DoubleLongReverse);  
      //----------------------------------------------------------------- DLRCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==UpTrend) && 
          (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue) ) )
           PositionModeSet(m_Session, DLRCon);
      //----------------------------------------------------------------- DLRCCon, Pyramiding Start
      if( CurPM[m_Session]==DoubleLongReverse &&
          (TrendLL==DownTrend) && 
          (WmaSValue<=(PositionSummary[m_Session].lastWmaS-DLRCConThValue) )  )
           PositionModeSet(m_Session, DLRCCon);
      //----------------------------------------------------------------- DLRCon End
      if(  CurPM[m_Session]==DLRCon && 
          (TrendLL==DownTrend) &&
          (LASMTrend==DownTrend) )
           PositionModeSet(m_Session, End);
      //----------------------------------------------------------------- DLRCCon End     
      if(  CurPM[m_Session]==DLRCCon &&      
          (TrendLL==UpTrend) &&
          (LASMTrend==UpTrend) )
           PositionModeSet(m_Session, End);      
     }  

}


//------------------------------------------------------------------------
void PositionModeSet(int m_Session, position_Mode m_PositionMode)
{
   BeforePM2[m_Session] = BeforePM[m_Session];
   BeforePM[m_Session] = CurPM[m_Session];
   CurPM[m_Session] = m_PositionMode;
            
   if(CurPM[m_Session] == LongReverse) 
     {
      ReOC[m_Session].LRBar=CurBar;
      ReOC[m_Session].LRWmaS=WmaSValue;

      if(OpenReady[m_Session].BuyTrendReady)
        {
         InitPyramidData(m_Session);         
         InitMinMax(m_Session);
         FirstFindMin(m_Session);
         PositionSummary[m_Session].lastWmaS=ReOC[m_Session].MinBSP;
         PositionSummary[m_Session].firstPositionTrend=UpTrend;
         FindMinMax(m_Session);
        } 
      else if(OpenReady[m_Session].SellTrendReady)
        {
         InitPyramidData(m_Session);         
         InitMinMax(m_Session);
         FirstFindMax(m_Session);
         PositionSummary[m_Session].lastWmaS=ReOC[m_Session].MaxBSP;
         PositionSummary[m_Session].firstPositionTrend=DownTrend;
         FindMinMax(m_Session);
        }           
     }       

   if(CurPM[m_Session] == LongReverseCon)
     {
      ReOC[m_Session].LRConBar=CurBar;
      ReOC[m_Session].LRConWmaS=WmaSValue;
     }
   
   if(CurPM[m_Session] == LongCounter)
     {
      ReOC[m_Session].LCBar=CurBar;
      ReOC[m_Session].LCWmaS=WmaSValue;

      if(PositionSummary[m_Session].firstPositionTrend==UpTrend)
        {
         InitPyramidData(m_Session);         
         InitMinMax(m_Session);
         FirstFindMax(m_Session);
         PositionSummary[m_Session].lastWmaS=ReOC[m_Session].MaxBSP;
         FindMinMax(m_Session);
        } 
      else if(PositionSummary[m_Session].firstPositionTrend==DownTrend)
        {
         InitPyramidData(m_Session);         
         InitMinMax(m_Session);
         FirstFindMin(m_Session);
         PositionSummary[m_Session].lastWmaS=ReOC[m_Session].MinBSP;
         FindMinMax(m_Session);
        }
     }   
          
   if(CurPM[m_Session] == LongCounterCon)     
     {
      ReOC[m_Session].LCConBar=CurBar;
      ReOC[m_Session].LCConWmaS=WmaSValue;              
     } 
     
   if(CurPM[m_Session] == DoubleLongReverse)  
     {
      ReOC[m_Session].DLRBar=CurBar;
      ReOC[m_Session].DLRWmaS=WmaSValue;

      if(PositionSummary[m_Session].firstPositionTrend==UpTrend)
        {
         InitPyramidData(m_Session);         
         InitMinMax(m_Session);
         FirstFindMin(m_Session);
         PositionSummary[m_Session].lastWmaS=ReOC[m_Session].MinBSP;
         FindMinMax(m_Session);
        } 
      else if(PositionSummary[m_Session].firstPositionTrend==DownTrend)
        {
         InitPyramidData(m_Session);         
         InitMinMax(m_Session);
         FirstFindMax(m_Session);
         PositionSummary[m_Session].lastWmaS=ReOC[m_Session].MaxBSP;
         FindMinMax(m_Session);
        }            
     } 
     
   if(CurPM[m_Session] == DLRCon)
     {             
      ReOC[m_Session].DLRConBar=CurBar;
      ReOC[m_Session].DLRConWmaS=WmaSValue;
     } 
     
   if(CurPM[m_Session] == DLRCCon)            
     {
      ReOC[m_Session].DLRCConBar=CurBar;
      ReOC[m_Session].DLRCConWmaS=WmaSValue;
     } 
     
   if(CurPM[m_Session] == End)              
     { 
      ReOC[m_Session].EndBar=CurBar; 
      ReOC[m_Session].EndWmaS=WmaSValue;
     }

   return;
}

//-------------------------------------------------------------------+
bool OpenReadyCheck(int m_Session)
{

   if(CurPM[m_Session]!=NoMode || SessionMan.CurSession!=m_Session) return(false);

//  Sell Open Ready Check
   if( SessionMan.CanGoBand && !OpenReady[m_Session].SellLASMReady && (LASMBand>=BandP2) ) 
     {
      OpenReady[m_Session].SellLASMReady = true;  
      OpenReady[m_Session].SellLASMBar=CurBar;
      OpenReady[m_Session].BuyLASMReady = false;
      OpenReady[m_Session].BuyLASMBar=0;
     }
   if( OpenReady[m_Session].SellLASMReady && ( (CurBar-OpenReady[m_Session].SellLASMBar)>ReadyBars ) )
     {
      SessionMan.CanGoBand=true;
      SessionMan.CanGoTrend=true;
      OpenReadyReset(m_Session);
      return(false);
     }   
   if( SessionMan.CanGoTrend && OpenReady[m_Session].SellLASMReady && (LASMTrend==DownTrend) && (TrendL==DownTrend) ) 
     {
      OpenReady[m_Session].SellTrendReady = true; 
      PositionModeSet(m_Session, LongReverse);
     } 

//  Buy Open Ready Check      
   if( SessionMan.CanGoBand && !OpenReady[m_Session].BuyLASMReady && (LASMBand<=BandM2) ) 
     { 
      OpenReady[m_Session].BuyLASMReady = true;      
      OpenReady[m_Session].BuyLASMBar=CurBar;
      OpenReady[m_Session].SellLASMReady=false;
      OpenReady[m_Session].SellLASMBar=0;
     } 
   if( OpenReady[m_Session].BuyLASMReady && ( (CurBar-OpenReady[m_Session].BuyLASMBar)>ReadyBars ) )
     {
      SessionMan.CanGoBand=true;
      SessionMan.CanGoTrend=true;
      OpenReadyReset(m_Session);
      return(false);
     } 
   if( SessionMan.CanGoTrend && OpenReady[m_Session].BuyLASMReady && (LASMTrend==UpTrend) && (TrendL==UpTrend) ) 
     {
      OpenReady[m_Session].BuyTrendReady = true;
      PositionModeSet(m_Session, LongReverse);
     }

   return(true);
}   
   