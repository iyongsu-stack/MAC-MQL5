void PositionModeCheck(int m_Session )
{

   if(CurPM[m_Session]==NoMode) return;

   int m_BarCount=0;
   
   if(CurPM[m_Session]!=End) m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;  

   if(TrailingStopMode==TS_None)
    {
        if( PositionSummary[m_Session].firstPositionTrend == DownTrend )
          {   
            //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
            if( (CurPM[m_Session]==LongReverse) &&
                (TrendLL==DownTrend) && 
                (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue)) && ReOC[m_Session].LRConCanGo )
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, LongReverseCon);
                
                ReOC[m_Session].LRConCanGo=false;
              }   
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
              {
                  PositionModeSet(m_Session, LongCounter);
                  m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;
              }
            //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
            if( (CurPM[m_Session]==LongCounter) &&
                (TrendLL==UpTrend) &&
                (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue)) && ReOC[m_Session].LCConCanGo )   
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, LongCounterCon);
                
                ReOC[m_Session].LCConCanGo=false;
              }
            //-----------------------------------------------------------------LongCounter, LongCounterCon End
            if( ( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) ) &&
                (TrendLL==DownTrend) &&
                (m_BarCount>PMBars) )
                PositionModeSet(m_Session, End);
            //-----------------------------------------------------------------DLR Start
            if( (CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon) &&
                (TrendLL==DownTrend) && 
                (m_BarCount<=PMBars) )  
              {
                PositionModeSet(m_Session, DoubleLongReverse);  
                m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;
              }
            //----------------------------------------------------------------- DLRCon, Pyramiding Start
            if( CurPM[m_Session]==DoubleLongReverse &&
                (TrendLL==DownTrend) && 
                (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue)) && ReOC[m_Session].DLRConCanGo )
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, DLRCon);
                else PositionModeSet(m_Session, End);    
                
                ReOC[m_Session].DLRConCanGo=false;
              }
            //----------------------------------------------------------------- DLRCCon, Pyramiding Start
            if( CurPM[m_Session]==DoubleLongReverse &&
                (TrendLL==UpTrend) && 
                (WmaSValue>=(ReOC[m_Session].MinBSP+DLRCConThValue)) && ReOC[m_Session].DLRCConCanGo )
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, DLRCCon);
                else PositionModeSet(m_Session, End);    

                ReOC[m_Session].DLRCConCanGo=false;
              }
            //----------------------------------------------------------------- DLRCon End
            if(  CurPM[m_Session]==DLRCon && 
                (TrendLL==UpTrend) )
                PositionModeSet(m_Session, End);
            //----------------------------------------------------------------- DLRCCon End     
            if(  CurPM[m_Session]==DLRCCon &&      
                (TrendLL==DownTrend) )
                PositionModeSet(m_Session, End);      
            }  
                
        if( PositionSummary[m_Session].firstPositionTrend== UpTrend )
          {                         
            //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
            if( (CurPM[m_Session]==LongReverse) &&
                (TrendLL==UpTrend) && 
                (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue)) && ReOC[m_Session].LRConCanGo )   
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, LongReverseCon);
                
                ReOC[m_Session].LRConCanGo=false;
              }
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
              {  
                PositionModeSet(m_Session, LongCounter);
                m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;
              }
            //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
            if( (CurPM[m_Session]==LongCounter) &&
                (TrendLL==DownTrend) &&
                (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue)) && ReOC[m_Session].LCConCanGo )   
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, LongCounterCon);
                  
                ReOC[m_Session].LCConCanGo=false;
              }
            //-----------------------------------------------------------------LongCounter, LongCounterCon End
            if( ( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) ) &&
                (TrendLL==UpTrend) &&
                (m_BarCount>PMBars) )
                PositionModeSet(m_Session, End);
            //-----------------------------------------------------------------DLR Start
            if( (CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon) &&
                (TrendLL==UpTrend) && 
                (m_BarCount<=PMBars) )  
              {
                PositionModeSet(m_Session, DoubleLongReverse);  
                m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;
              }
            //----------------------------------------------------------------- DLRCon, Pyramiding Start
            if( CurPM[m_Session]==DoubleLongReverse &&
                (TrendLL==UpTrend) && 
                (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue) ) && ReOC[m_Session].DLRConCanGo ) 
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, DLRCon);
                else PositionModeSet(m_Session, End);    

                ReOC[m_Session].DLRConCanGo=false;
              }
            //----------------------------------------------------------------- DLRCCon, Pyramiding Start
            if( CurPM[m_Session]==DoubleLongReverse &&
                (TrendLL==DownTrend) && 
                (WmaSValue<=(ReOC[m_Session].MaxBSP-DLRCConThValue) ) && ReOC[m_Session].DLRCConCanGo )
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, DLRCCon);
                else PositionModeSet(m_Session, End);    

                ReOC[m_Session].DLRCConCanGo=false;
              }
            //----------------------------------------------------------------- DLRCon End
            if(  CurPM[m_Session]==DLRCon && 
                (TrendLL==DownTrend) )
                PositionModeSet(m_Session, End);
            //----------------------------------------------------------------- DLRCCon End     
            if(  CurPM[m_Session]==DLRCCon &&      
                (TrendLL==UpTrend) )
                PositionModeSet(m_Session, End);      
          }  
    }
   else if(TrailingStopMode==TS_Tick || TrailingStopMode==TS_NewBar)
    {
        double m_TrailingStopLimit=0.0, m_TrailingStopStart=0.0;

        if( PositionSummary[m_Session].firstPositionTrend == DownTrend )
          {             
            //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
            if( (CurPM[m_Session]==LongReverse) &&
                (TrendLL==DownTrend) && 
                (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue)) && ReOC[m_Session].LRConCanGo )   
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, LongReverseCon);
                
                ReOC[m_Session].LRConCanGo=false;
              }
            //-----------------------------------------------------------------LongReverse, LongReverseCon End    
            if( ( (CurPM[m_Session]==LongReverse) || (CurPM[m_Session]==LongReverseCon) ) &&
                ( (m_BarCount>PMBars)||(LASLBand<SellLCLASLBand) ) )
               {     
                    m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
                    m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

                    if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                      PositionModeSet(m_Session, End);
               }  
            //-----------------------------------------------------------------LongCounter Start    
            if( ( (CurPM[m_Session]==LongReverse) || (CurPM[m_Session]==LongReverseCon) ) &&
                (TrendLL==UpTrend) && 
                (m_BarCount<=PMBars) && 
                (LASLBand>=SellLCLASLBand) )
              {
                PositionModeSet(m_Session, LongCounter);
                m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;
              }
            //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
            if( (CurPM[m_Session]==LongCounter) &&
                (TrendLL==UpTrend) &&
                (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue)) && ReOC[m_Session].LCConCanGo )
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, LongCounterCon);
                
                ReOC[m_Session].LCConCanGo=false;
              }
            //-----------------------------------------------------------------LongCounter, LongCounterCon End
            if( ( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) ) &&
                (m_BarCount>PMBars) ) 
                {
                    m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
                    m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

                    if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                        PositionModeSet(m_Session, End);
                }
            //-----------------------------------------------------------------DLR Start
            if( (CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon) &&
                (TrendLL==DownTrend) && 
                (m_BarCount<=PMBars) )  
              {
                PositionModeSet(m_Session, DoubleLongReverse);  
                m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;
              }
            //----------------------------------------------------------------- DLRCon, Pyramiding Start
            if( CurPM[m_Session]==DoubleLongReverse &&
                (TrendLL==DownTrend) && 
                (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue) ) && ReOC[m_Session].DLRConCanGo )
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, DLRCon);
                else PositionModeSet(m_Session, End);    

                ReOC[m_Session].DLRConCanGo=false;
              }
            //----------------------------------------------------------------- DLRCCon, Pyramiding Start
            if( CurPM[m_Session]==DoubleLongReverse &&
                (TrendLL==UpTrend) && 
                (WmaSValue>=(ReOC[m_Session].MinBSP+DLRCConThValue) ) && ReOC[m_Session].DLRCConCanGo )
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, DLRCCon);
                else PositionModeSet(m_Session, End);  
                  
                ReOC[m_Session].DLRCConCanGo=false;
              }
            //----------------------------------------------------------------- DLRCon End
            if(  CurPM[m_Session]==DLRCon )
                {
                    m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
                    m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

                    if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                        PositionModeSet(m_Session, End);
                }
            //----------------------------------------------------------------- DLRCCon End     
            if(  CurPM[m_Session]==DLRCCon   )
                {
                    m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
                    m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

                    if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                        PositionModeSet(m_Session, End);
                }
          }  
                
        if( PositionSummary[m_Session].firstPositionTrend== UpTrend )
          {       
                    
            //-----------------------------------------------------------------LongReverseCon, Pyramiding Start
            if( (CurPM[m_Session]==LongReverse) &&
                (TrendLL==UpTrend) && 
                (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue)) && ReOC[m_Session].LRConCanGo )   
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, LongReverseCon);
                
                ReOC[m_Session].LRConCanGo=false;
              }
            //-----------------------------------------------------------------LongReverse, LongReverseCon End    
            if( ( (CurPM[m_Session]==LongReverse) || (CurPM[m_Session]==LongReverseCon) ) &&
                ( (m_BarCount>PMBars)||(LASLBand>BuyLCLASLBand) ) )
                {
                    m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
                    m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

                    if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                        PositionModeSet(m_Session, End);
                }
            //-----------------------------------------------------------------LongCounter Start    
            if( ( (CurPM[m_Session]==LongReverse) || (CurPM[m_Session]==LongReverseCon) ) &&
                (TrendLL==DownTrend) && 
                (m_BarCount<=PMBars) && 
                (LASLBand<=BuyLCLASLBand) )
              {
                PositionModeSet(m_Session, LongCounter);
                m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;
              }
            //-----------------------------------------------------------------LongCounterCon, Pyramiding Start
            if( (CurPM[m_Session]==LongCounter) &&
                (TrendLL==DownTrend) &&
                (WmaSValue<=(PositionSummary[m_Session].lastWmaS-ThBSPValue)) && ReOC[m_Session].LCConCanGo )
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, LongCounterCon);
                
                ReOC[m_Session].LCConCanGo=false;
              }
            //-----------------------------------------------------------------LongCounter, LongCounterCon End
            if( ( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) ) &&
                (m_BarCount>PMBars) )
                {
                    m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
                    m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

                    if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                        PositionModeSet(m_Session, End);
                }
            //-----------------------------------------------------------------DLR Start
            if( (CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon) &&
                (TrendLL==UpTrend) && 
                (m_BarCount<=PMBars) )  
              {
                PositionModeSet(m_Session, DoubleLongReverse);  
                m_BarCount=CurBar-ReOC[m_Session].MaxMinBar;
              }
            //----------------------------------------------------------------- DLRCon, Pyramiding Start
            if( CurPM[m_Session]==DoubleLongReverse &&
                (TrendLL==UpTrend) && 
                (WmaSValue>=(PositionSummary[m_Session].lastWmaS+ThBSPValue) ) && ReOC[m_Session].DLRConCanGo ) 
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, DLRCon);
                else PositionModeSet(m_Session, End);    
                
                ReOC[m_Session].DLRConCanGo=false;
              }
            //----------------------------------------------------------------- DLRCCon, Pyramiding Start
            if( CurPM[m_Session]==DoubleLongReverse &&
                (TrendLL==DownTrend) && 
                (WmaSValue<=(ReOC[m_Session].MaxBSP-DLRCConThValue) ) && ReOC[m_Session].DLRCConCanGo )
              {
                if(m_BarCount>=ConBarStart && m_BarCount<=ConBarLimit)
                    PositionModeSet(m_Session, DLRCCon);
                else PositionModeSet(m_Session, End);    

                ReOC[m_Session].DLRCConCanGo=false;
              }
            //----------------------------------------------------------------- DLRCon End
            if(  CurPM[m_Session]==DLRCon )
                {
                    m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
                    m_TrailingStopLimit=ReOC[m_Session].MaxBSP-TSThValue;

                    if( (WmaSValue<=m_TrailingStopLimit) && (WmaSValue>=m_TrailingStopStart) )
                        PositionModeSet(m_Session, End);
                }
            //----------------------------------------------------------------- DLRCCon End     
            if(  CurPM[m_Session]==DLRCCon )
                {
                    m_TrailingStopStart=ReOC[m_Session].MaxMinWmaS;
                    m_TrailingStopLimit=ReOC[m_Session].MinBSP+TSThValue;

                    if( (WmaSValue>=m_TrailingStopLimit) && (WmaSValue<=m_TrailingStopStart) )
                        PositionModeSet(m_Session, End);
                }      
          }  
    }

}

/*
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
          (TrendLL==UpTrend) )
           PositionModeSet(m_Session, End);
      //----------------------------------------------------------------- DLRCCon End     
      if(  CurPM[m_Session]==DLRCCon &&      
          (TrendLL==DownTrend) )
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
          (TrendLL==DownTrend) )
           PositionModeSet(m_Session, End);
      //----------------------------------------------------------------- DLRCCon End     
      if(  CurPM[m_Session]==DLRCCon &&      
          (TrendLL==UpTrend) )
           PositionModeSet(m_Session, End);      
     }  

}
*/