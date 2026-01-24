//+------------------------------------------------------------------+
//|                                                 ReadyCheckV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

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
   