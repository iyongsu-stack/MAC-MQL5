//+------------------------------------------------------------------+
//|                                                  IndicatorV3.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV7/ExternVariables.mqh>
//#include <BSPV7/ReadyCheckV7.mqh>


//+------------------------------------------------------------------+
//|   Function for copying indicator data and price                   |
//+------------------------------------------------------------------+
bool Indicators()
{

   datetime curTime = TimeCurrent();
   CurBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT); 


   if(CopyBuffer(NLRLHandleL,     0,  Shift,  1, NLRLBuffer)                   == -1   ||
      CopyBuffer(NLRLHandleL,     1,  Shift,  1, NLRLColorBuffer)              == -1   ||
      
      CopyBuffer(LASHandleM,     6,  Shift,  2, LASMBuffer)                    == -1   ||
      CopyBuffer(LASHandleM,     7,  Shift,  1, LASMColorBuffer)               == -1   ||
      CopyBuffer(LASHandleM,     0,  Shift,  1, LASMP3Band)                    == -1   ||
      CopyBuffer(LASHandleM,     1,  Shift,  1, LASMP2Band)                    == -1   ||
      CopyBuffer(LASHandleM,     2,  Shift,  1, LASMP1Band)                    == -1   ||
      CopyBuffer(LASHandleM,     3,  Shift,  1, LASMM1Band)                    == -1   ||
      CopyBuffer(LASHandleM,     4,  Shift,  1, LASMM2Band)                    == -1   ||
      CopyBuffer(LASHandleM,     5,  Shift,  1, LASMM3Band)                    == -1   ||

      CopyBuffer(LASHandleL,     6,  Shift,  1, LASLBuffer)                    == -1   ||
      CopyBuffer(LASHandleL,     7,  Shift,  1, LASLColorBuffer)               == -1   ||
      CopyBuffer(LASHandleL,     0,  Shift,  1, LASLP3Band)                    == -1   ||
      CopyBuffer(LASHandleL,     1,  Shift,  1, LASLP2Band)                    == -1   ||
      CopyBuffer(LASHandleL,     2,  Shift,  1, LASLP1Band)                    == -1   ||
      CopyBuffer(LASHandleL,     3,  Shift,  1, LASLM1Band)                    == -1   ||
      CopyBuffer(LASHandleL,     4,  Shift,  1, LASLM2Band)                    == -1   ||
      CopyBuffer(LASHandleL,     5,  Shift,  1, LASLM3Band)                    == -1   ||

      CopyBuffer(LASHandleT,     6,  Shift,  1, LASTBuffer)                    == -1   ||
      CopyBuffer(LASHandleT,     7,  Shift,  1, LASTColorBuffer)               == -1   ||

      CopyBuffer(WmaHandleS,     0,  Shift, FindMinMaxSize, WmaSBuffer)       == -1    ||
      CopyBuffer(WmaHandleS,     1,  Shift,  1, WmaSColorBuffer)               == -1   ||

      CopyBuffer(WmaHandleL,     0,  Shift,  1, WmaLBuffer)                    == -1   ||
      CopyBuffer(WmaHandleL,     1,  Shift,  1, WmaLColorBuffer)               == -1   ||

      CopyBuffer(BSPNlrWmaHandleS,   0,  Shift, 1, BSPNlrWmaBufferS)           == -1   ||
      CopyBuffer(BSPNlrWmaHandleS,   1,  Shift, 1, BSPNlrWmaColorBufferS)      == -1   ||

      CopyBuffer(BSPNlrWmaHandleL,   0,  Shift, 1, BSPNlrWmaBufferL)           == -1   ||
      CopyBuffer(BSPNlrWmaHandleL,   1,  Shift, 1, BSPNlrWmaColorBufferL)      == -1   ||

      CopyBuffer(BSPHandle,     7,      0,  1, BSPBuffer)                      == -1   ||
      CopyBuffer(BSPHandle,     0,  Shift,  1, BSPWmaBuffer)                   == -1   ||
      CopyBuffer(BSPHandle,     3,  Shift,  1, BSP1Band)                       == -1    )  return(false);

   NLRLValue       = NLRLBuffer[0];
   LASMValue       = LASMBuffer[0];
   LASLValue       = LASLBuffer[0];
   LASTValue       = LASTBuffer[0];
   WmaSValue       = WmaSBuffer[0];
   WmaLValue       = WmaLBuffer[0];
   BSPNlrWmaValueS = BSPNlrWmaBufferS[0];
   BSPNlrWmaValueL = BSPNlrWmaBufferL[0]; 
   BSPValue        = BSPBuffer[0];
   BSPWmaValue     = BSPWmaBuffer[0];
   BSPSTD          = BSP1Band[0];
   
   NLRLTrend1       = NLRLTrend;        if( (int)NormalizeDouble(NLRLColorBuffer[0], 0) == 1) NLRLTrend = DownTrend;  
                                         else NLRLTrend = UpTrend;
   LASMTrend1       = LASMTrend;        if( (int)NormalizeDouble(LASMColorBuffer[0], 0) == 1) LASMTrend = DownTrend;  
                                         else LASMTrend = UpTrend;
   LASLTrend1       = LASLTrend;        if( (int)NormalizeDouble(LASLColorBuffer[0], 0) == 1) LASLTrend = DownTrend;  
                                         else LASLTrend = UpTrend;
   LASTTrend1       = LASTTrend;        if( (int)NormalizeDouble(LASTColorBuffer[0], 0) == 1) LASTTrend = DownTrend;  
                                         else LASTTrend = UpTrend;
   WmaSTrend1       = WmaSTrend;        if( (int)NormalizeDouble(WmaSColorBuffer[0], 0) == 1) WmaSTrend = DownTrend;  
                                         else WmaSTrend = UpTrend;
   WmaLTrend1       = WmaLTrend;        if( (int)NormalizeDouble(WmaLColorBuffer[0], 0) == 1) WmaLTrend = DownTrend;  
                                         else WmaLTrend = UpTrend;  
   BSPNlrWmaTrendS1 = BSPNlrWmaTrendS;  if( (int)NormalizeDouble(BSPNlrWmaColorBufferS[0], 0) == 1) BSPNlrWmaTrendS = DownTrend;
                                         else BSPNlrWmaTrendS = UpTrend;
   BSPNlrWmaTrendL1 = BSPNlrWmaTrendL;  if( (int)NormalizeDouble(BSPNlrWmaColorBufferL[0], 0) == 1) BSPNlrWmaTrendL = DownTrend;
                                         else BSPNlrWmaTrendL = UpTrend;                                        

   TrendCase();

   if      (LASMValue > LASMP3Band[0])         LASMBand = BandP3;
   else if (LASMValue > LASMP2Band[0])         LASMBand = BandP2;
   else if (LASMValue > LASMP1Band[0])         LASMBand = BandP1; 
   else if (LASMValue > 0. )                   LASMBand = BandP0;
   else if (LASMValue > LASMM1Band[0])         LASMBand = BandM0;
   else if (LASMValue > LASMM2Band[0])         LASMBand = BandM1;
   else if (LASMValue > LASMM3Band[0])         LASMBand = BandM2;
   else                                        LASMBand = BandM3; 

   if      (LASLValue > LASLP3Band[0])         LASLBand = BandP3;
   else if (LASLValue > LASLP2Band[0])         LASLBand = BandP2;
   else if (LASLValue > LASLP1Band[0])         LASLBand = BandP1; 
   else if (LASLValue > 0. )                   LASLBand = BandP0;
   else if (LASLValue > LASLM1Band[0])         LASLBand = BandM0;
   else if (LASLValue > LASLM2Band[0])         LASLBand = BandM1;
   else if (LASLValue > LASLM3Band[0])         LASLBand = BandM2;
   else                                        LASLBand = BandM3; 

   ThBSPValue=MathAbs(BSPSTD*PyramidGloConst.pyramidThMulti);
   IncBSPValue=MathAbs(BSPSTD*PyramidGloConst.pyramidIncMulti);
   DLRCConThValue=MathAbs(BSPSTD*DLRCConMulti);  
   SLBSPValue=MathAbs(BSPSTD*SLBSPSTDMulti);
   TSThValue=MathAbs(BSPSTD*TSBSPSTDMulti);
    
   if( Times(curTime) && !StartTrading )  StartTrading = true;  
   else if( !Times(curTime) && StartTrading )  StartTrading = false;  

   isClosingTime=CloseTimes(curTime);
   
   return(true);  

}

void TrendCase(void)
{
   trend m_Trend=NoTrend;

   switch(TrendCase)
   {
      case TrendCase1:
         if(BSPNlrWmaTrendL == DownTrend) TrendL = DownTrend;
         else if (BSPNlrWmaTrendL == UpTrend) TrendL = UpTrend;
         else TrendL = NoTrend;
         
         if( (WmaLTrend == DownTrend) && (BSPNlrWmaTrendL == DownTrend) && (NLRLTrend == DownTrend) ) 
            TrendLL = DownTrend;
         else if ( (WmaLTrend == UpTrend) && (BSPNlrWmaTrendL == UpTrend) && (NLRLTrend == UpTrend)) 
            TrendLL = UpTrend;
         else TrendLL = NoTrend;
         break;
 
      case TrendCase2:
         if( (WmaLTrend == DownTrend) && (BSPNlrWmaTrendS == DownTrend) && (NLRLTrend == DownTrend) )
           {
            TrendL = DownTrend;
            TrendLL = DownTrend;
           }
         else if ( (WmaLTrend == UpTrend) && (BSPNlrWmaTrendS == UpTrend) && (NLRLTrend == UpTrend) )
           {
            TrendL = UpTrend;
            TrendLL = UpTrend;
           }
         else 
           {
            TrendL = NoTrend;
            TrendLL = NoTrend;
           }
         break;   

      case TrendCase3:
         if( (LASTTrend == DownTrend) && ( BSPNlrWmaTrendS == DownTrend ) )
           {
            TrendL = DownTrend;
            TrendLL = DownTrend;
           }
         else if ( (LASTTrend == UpTrend) && (BSPNlrWmaTrendS == UpTrend) )
           {
            TrendL = UpTrend;
            TrendLL = UpTrend;
           }
         else 
           {
            TrendL = NoTrend;
            TrendLL = NoTrend;
           }
         break;   
  
      default:
         break;
   }
 
   return;
}



//-----------------------------------------------------------------------------------------------------------++++
bool tickIndicators()
{
   
   if(CopyBuffer(WmaHandleS,    0,  0, 1, WmaSBuffer)       == -1   ||
      CopyBuffer(BSPHandle,     7,  0, 1, BSPBuffer)        == -1   )  return(false);

   WmaSValue  = WmaSBuffer[0];
   BSPValue   = BSPBuffer[0];

   return(true);  
}