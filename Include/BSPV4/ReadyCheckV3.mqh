//+------------------------------------------------------------------+
//|                                                 ReadyCheckV3.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV4/ExternVariables.mqh>


//------------------------------------------------------------------------
void PositionModeCheck(void)
{

   if(PositionSummary.totalNumPositions == 0) return;

   int m_BarCount=0;
      
   if(CurPM==MiddleReverse) m_BarCount=CurBar-ReOC.MRBar;
   else if(CurPM==LongReverse) m_BarCount=CurBar-ReOC.LRBar;
   else if(CurPM==LongCounter) m_BarCount=CurBar-ReOC.LCBar; 
   else if(CurPM==DoubleLongReverse) m_BarCount=CurBar-ReOC.DLRBar;   


   if( PositionSummary.firstPositionType == POSITION_TYPE_SELL )
     {

      //-----------------------------------------------------------------LongReverse Start
      if( (CurPM==MiddleReverse) && 
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) &&
          (LASLTrend==DownTrend) )
           PositionModeSet(LongReverse);
      
      //-----------------------------------------------------------------LongReverseCon Start
      if( (CurPM==MiddleReverse || CurPM==LongReverse) &&
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) && 
          (LASLBand<=ReOC.SellLRConLASLBand || m_BarCount>=ReOC.LRConBars) )
           PositionModeSet(LongReverseCon);

      //-----------------------------------------------------------------LongReverseCon End
      if( (CurPM==LongReverseCon) && 
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) &&
          (LASSTrend==UpTrend && LASMTrend==UpTrend && LASLTrend==UpTrend) )
            PositionModeSet(End);
           
      
      //-----------------------------------------------------------------LongCounter Start    
      if( (CurPM==MiddleReverse || CurPM==LongReverse) && 
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) && 
          (LASSTrend==UpTrend && LASLTrend==UpTrend) &&
          (LASLBand>=ReOC.SellLCLASLBand) )
           PositionModeSet(LongCounter);

      //-----------------------------------------------------------------DoubleLongReverse Start and Noise Setting
      if( (CurPM==LongCounter ) &&
          (TrendS==DownTrend && TrendL==DownTrend && TrendL==DownTrend) && 
          (LASSTrend==DownTrend) && (LASLTrend==DownTrend) &&
          (m_BarCount<=ReOC.DLRBars) ) 
            {
             PositionModeSet(DoubleLongReverse);  
             if(ReOC.DLRNoiseTF=true) NoiseSet();         
            }

      //-----------------------------------------------------------------DoubleLongReverse Noise Endure and End
      if( (CurPM==DoubleLongReverse ) &&
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) && 
          (LASSTrend==UpTrend && LASMTrend==UpTrend && LASLTrend==UpTrend) &&
          (ReOC.DLRNoiseTF==true && (WmaLValue>NoiseUpLimit || WmaLValue<NoiseDownLimit)) ) 
            PositionModeSet(End);  


      //-----------------------------------------------------------------LongCounterCon Start
      if( (CurPM==LongCounter) &&
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) &&
          (m_BarCount>ReOC.DLRBars) )
           PositionModeSet(LongCounterCon);
 
      //-----------------------------------------------------------------LongCounterCon End     
      if( (CurPM==LongCounterCon) &&      
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) )
           PositionModeSet(End);      
      
      //-----------------------------------------------------------------Too Stiff and End
      if( (LASMBand<=BandM2) &&
          (TrendS==UpTrend && TrendM==UpTrend) &&
          (LASSTrend==UpTrend && LASMTrend==UpTrend) )
            PositionModeSet(End);         

             
     }  
     
      
   if( PositionSummary.firstPositionType== POSITION_TYPE_BUY )
     {       
            
      //-----------------------------------------------------------------LongReverse Start
      if( (CurPM==MiddleReverse) && 
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) &&
          (LASLTrend==UpTrend) )
           PositionModeSet(LongReverse);
      
      //-----------------------------------------------------------------LongReverseCon Start
      if( (CurPM==MiddleReverse || CurPM==LongReverse) &&
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) && 
          (LASLBand>=ReOC.BuyLRConLASLBand || m_BarCount>=ReOC.LRConBars) )
           PositionModeSet(LongReverseCon);

      //-----------------------------------------------------------------LongReverseCon End
      if( (CurPM==LongReverseCon) && 
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) &&
          (LASSTrend==DownTrend && LASMTrend==DownTrend && LASLTrend==DownTrend) )
            PositionModeSet(End);
           
      
      //-----------------------------------------------------------------LongCounter Start    
      if( (CurPM==MiddleReverse || CurPM==LongReverse) && 
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) && 
          (LASSTrend==DownTrend && LASLTrend==DownTrend) &&
          (LASLBand<=ReOC.BuyLCLASLBand) )
           PositionModeSet(LongCounter);

      //-----------------------------------------------------------------DoubleLongReverse Start and Noise Setting
      if( (CurPM==LongCounter ) &&
          (TrendS==UpTrend && TrendL==UpTrend && TrendL==UpTrend) && 
          (LASSTrend==UpTrend) && (LASLTrend==UpTrend) &&
          (m_BarCount<=ReOC.DLRBars) ) 
            {
             PositionModeSet(DoubleLongReverse);  
             if(ReOC.DLRNoiseTF=true) NoiseSet();         
            }

      //-----------------------------------------------------------------DoubleLongReverse Noise Endure and End
      if( (CurPM==DoubleLongReverse ) &&
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) && 
          (LASSTrend==DownTrend && LASMTrend==DownTrend && LASLTrend==DownTrend) &&
          (ReOC.DLRNoiseTF==true && (WmaLValue>NoiseUpLimit || WmaLValue<NoiseDownLimit)) ) 
            PositionModeSet(End);  


      //-----------------------------------------------------------------LongCounterCon Start
      if( (CurPM==LongCounter) &&
          (TrendS==DownTrend && TrendM==DownTrend && TrendL==DownTrend) &&
          (m_BarCount>ReOC.DLRBars) )
           PositionModeSet(LongCounterCon);
 
      //-----------------------------------------------------------------LongCounterCon End     
      if( (CurPM==LongCounterCon) &&      
          (TrendS==UpTrend && TrendM==UpTrend && TrendL==UpTrend) )
           PositionModeSet(End);      
      
      //-----------------------------------------------------------------Too Stiff and End
      if( (LASMBand>=BandP2) &&
          (TrendS==DownTrend && TrendM==DownTrend) &&
          (LASSTrend==DownTrend && LASMTrend==DownTrend) )
            PositionModeSet(End);         

     }  

}


void NoiseSet()
{
   double m_Friction=BSPWmaValue/WmaBSP;
   
   if(PositionSummary.firstPositionType==POSITION_TYPE_SELL)
     {
      NoiseUpLimit =  WmaLValue + m_Friction*ReOC.NoiseUpMultiFactor;
      NoiseDownLimit = WmaLValue - m_Friction*ReOC.NoiseDownMultiFactor;     
     }
   else
     {
      NoiseUpLimit =  WmaLValue + m_Friction*ReOC.NoiseDownMultiFactor;
      NoiseDownLimit = WmaLValue - m_Friction*ReOC.NoiseUpMultiFactor;        
     }  
}

//-------------------------------------------------------------------+
void OpenReadyCheck(void)
{

   if(CurPM!=NoMode) return;

//  Sell Open Ready Check
   if( !SellOpenReady.LASMReady && (LASMBand>=BandP2) ) 
      SellOpenReady.LASMReady = true;  

   if( SellOpenReady.LASMReady && (TrendS==DownTrend) && (TrendM==DownTrend) && 
       (LASSTrend==DownTrend) && (LASMTrend==DownTrend) && (LASLTrend==DownTrend) ) 
     {
      SellOpenReady.TrendReady = true; 
      PositionModeSet(MiddleReverse);
      if(TrendL==DownTrend) PositionModeSet(LongReverse);
     } 
   else SellOpenReady.TrendReady = false; 

//  Buy Open Ready Check      
   if( !BuyOpenReady.LASMReady && (LASMBand<=BandM2) ) 
      BuyOpenReady.LASMReady = true;

   if( BuyOpenReady.LASMReady && (TrendS==UpTrend) && (TrendM==UpTrend) && 
       (LASSTrend==UpTrend) && (LASMTrend==UpTrend) && (LASLTrend==UpTrend)) 
     {
      BuyOpenReady.TrendReady = true;
      PositionModeSet(MiddleReverse);
      if(TrendL==UpTrend) PositionModeSet(LongReverse);
     }
   else BuyOpenReady.TrendReady = false; 
  
           
}   



//------------------------------------------------------------------------
void PositionModeSet(position_Mode m_PositionMode)
{
   BeforePM = CurPM;
   CurPM = m_PositionMode;
   if(CurPM == MiddleReverse)     ReOC.MRBar=CurBar;
   else if(CurPM == LongReverse)       ReOC.LRBar = CurBar;
   else if(CurPM == LongReverseCon)    ReOC.LRConBar = CurBar;
   else if(CurPM == LongCounter)       ReOC.LCBar = CurBar;
   else if(CurPM == DoubleLongReverse) ReOC.DLRBar = CurBar;
   else if(CurPM == End)               ReOC.EndBar = CurBar;
   else if(CurPM == NoMode)            ReOC.NoModeBar = CurBar;
   
   return;
}


//Ready Parameter Reset
//-------------------------------------------------------------------+
void OpenReadyReset(void)
{
   BuyOpenReady.Able = false;
   BuyOpenReady.LASSReady=false;
   BuyOpenReady.LASMReady = false;
   BuyOpenReady.TrendReady = false;

   SellOpenReady.Able = false;
   SellOpenReady.LASSReady = false;   
   SellOpenReady.LASMReady = false;
   SellOpenReady.TrendReady = false;
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