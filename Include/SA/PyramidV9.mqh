//+------------------------------------------------------------------+
//|                                                    PyramidV6.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//-------------------------------------------------------------------------------------------------------------------
void KeepPyramiding(int m_Session)
{
   double m_PyramidWmaS;

   if(PositionSummary[m_Session].lastSizeMulti==0.0) return;

   double m_LotSizeMulti=PositionSummary[m_Session].lastSizeMulti*PyramidGloConst.coneDecMulti;
   if(m_LotSizeMulti<MinLotSizeMulti)  m_LotSizeMulti=MinLotSizeMulti;

   if(PositionSummary[m_Session].pyramidTrend==UpTrend)
     {
      m_PyramidWmaS=PositionSummary[m_Session].lastWmaS+IncBSPValue;

      if(m_PyramidWmaS<=WmaSValue) 
        {            
         if(OpenPositionByPID(POSITION_TYPE_BUY, m_LotSizeMulti, m_Session, PositionSummary[m_Session].pyramidPID))
           {
            PositionSummary[m_Session].lastSizeMulti=m_LotSizeMulti;
            PositionSummary[m_Session].lastWmaS=WmaSValue;
           } 
        }    
     }
   else 
     {
      m_PyramidWmaS=PositionSummary[m_Session].lastWmaS-IncBSPValue;
           
      if(m_PyramidWmaS>=WmaSValue) 
        {
         if(OpenPositionByPID(POSITION_TYPE_SELL, m_LotSizeMulti, m_Session, PositionSummary[m_Session].pyramidPID))
           {
            PositionSummary[m_Session].lastSizeMulti=m_LotSizeMulti;
            PositionSummary[m_Session].lastWmaS=WmaSValue;
           }
        }   
     }                       
}

bool pyramidStarted(void)
{
   for(int m_Session=0;m_Session<TotalSession;m_Session++)
    {
     if(PositionSummary[m_Session].pyramidStarted) 
        return(true);
    }
    
    return(false);

}

///////////////////////////////////////////////////////////////////////////////////////////////////
void FirstFindMax(int m_Session)
{   
   if(ReOC[m_Session].MaxMinBar!=0) return;

   double MaxValue=WmaSBuffer[0];
   int MaxShift=0, FindMinMaxShift=0;
   
   if( CurPM[m_Session]==LongReverse) FindMinMaxShift=FindMinMaxShiftLR;
   else FindMinMaxShift=FindMinMaxShiftETC;

   for(int i=1;i<FindMinMaxShift;i++)
     {
      if(MaxValue<WmaSBuffer[i])
        {
         MaxValue=WmaSBuffer[i];
         MaxShift=i;
        }    
     } 

   ReOC[m_Session].MaxBSP=MaxValue;
   ReOC[m_Session].MaxBar=CurBar-(MaxShift+1);
   ReOC[m_Session].MaxMinBar=ReOC[m_Session].MaxBar;
   ReOC[m_Session].MaxMinWmaS=ReOC[m_Session].MaxBSP;
}

//-------------------------------------------------------------------------------------------------
void FirstFindMin(int m_Session)
{
   if(ReOC[m_Session].MaxMinBar!=0) return;

   double MinValue=WmaSBuffer[0];
   int MinShift=0, FindMinMaxShift=0;
   
   if( CurPM[m_Session]==LongReverse) FindMinMaxShift=FindMinMaxShiftLR;
   else FindMinMaxShift=FindMinMaxShiftETC;

   for(int i=1;i<FindMinMaxShift;i++)
     {
      if(MinValue>WmaSBuffer[i])
        {
         MinValue=WmaSBuffer[i];
         MinShift=i;
        }    
     } 

   ReOC[m_Session].MinBSP=MinValue;
   ReOC[m_Session].MinBar=CurBar-(MinShift+1);
   ReOC[m_Session].MaxMinBar=ReOC[m_Session].MinBar;
   ReOC[m_Session].MaxMinWmaS=ReOC[m_Session].MinBSP;
}

//---------------------------------------------------------------------------------------------------
void FindMinMax(int m_Session)
{
   if(CurPM[m_Session]==NoMode || CurPM[m_Session]==End ) return;
   
   if(ReOC[m_Session].MaxMinBar==0) return;

   int MaxShift=0, MinShift=0, shift=(CurBar-1)-ReOC[m_Session].MaxMinBar;
   double MaxValue=WmaSBuffer[0], MinValue=WmaSBuffer[0];
   
   if(shift>(FindMinMaxSize-1)) shift=FindMinMaxSize-1;
   
   for(int i=1;i<=shift;i++)
     {
      if(MaxValue<WmaSBuffer[i])
        {
         MaxValue=WmaSBuffer[i];
         MaxShift=i;
        } 

      if(MinValue>WmaSBuffer[i])
        {
         MinValue=WmaSBuffer[i];
         MinShift=i;
        }      
     } 
   ReOC[m_Session].MaxBSP=MaxValue;
   ReOC[m_Session].MaxBar=CurBar-(MaxShift+1);
   
   ReOC[m_Session].MinBSP=MinValue;
   ReOC[m_Session].MinBar=CurBar-(MinShift+1);
}

