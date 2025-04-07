//+------------------------------------------------------------------+
//|                                                  IndicatorV3.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV6/ExternVariables.mqh>
//#include <BSPV6/ReadyCheckV6.mqh>


//+------------------------------------------------------------------+
//|   Function for copying indicator data and price                   |
//+------------------------------------------------------------------+
bool Indicators()
{

   datetime curTime = TimeCurrent();
   CurBar = (int)SeriesInfoInteger(_Symbol,_Period,SERIES_BARS_COUNT); 


   if(CopyBuffer(NLRSHandle,     0,  Shift,  1, NLRSBuffer)           == -1   ||
      CopyBuffer(NLRSHandle,     1,  Shift,  1, NLRSColorBuffer)      == -1   ||

      CopyBuffer(NLRMHandle,     0,  Shift,  1, NLRMBuffer)           == -1   ||
      CopyBuffer(NLRMHandle,     1,  Shift,  1, NLRMColorBuffer)      == -1   ||

      CopyBuffer(NLRLHandle,     0,  Shift,  1, NLRLBuffer)           == -1   ||
      CopyBuffer(NLRLHandle,     1,  Shift,  1, NLRLColorBuffer)      == -1   ||
      
      CopyBuffer(LASHandleM,     6,  Shift,  2, LASMBuffer)           == -1   ||
      CopyBuffer(LASHandleM,     7,  Shift,  1, LASMColorBuffer)      == -1   ||
      CopyBuffer(LASHandleM,     0,  Shift,  1, LASMP3Band)           == -1   ||
      CopyBuffer(LASHandleM,     1,  Shift,  1, LASMP2Band)           == -1   ||
      CopyBuffer(LASHandleM,     2,  Shift,  1, LASMP1Band)           == -1   ||
      CopyBuffer(LASHandleM,     3,  Shift,  1, LASMM1Band)           == -1   ||
      CopyBuffer(LASHandleM,     4,  Shift,  1, LASMM2Band)           == -1   ||
      CopyBuffer(LASHandleM,     5,  Shift,  1, LASMM3Band)           == -1   ||

      CopyBuffer(LASHandleL,     6,  Shift,  1, LASLBuffer)           == -1   ||
      CopyBuffer(LASHandleL,     7,  Shift,  1, LASLColorBuffer)      == -1   ||
      CopyBuffer(LASHandleL,     0,  Shift,  1, LASLP3Band)           == -1   ||
      CopyBuffer(LASHandleL,     1,  Shift,  1, LASLP2Band)           == -1   ||
      CopyBuffer(LASHandleL,     2,  Shift,  1, LASLP1Band)           == -1   ||
      CopyBuffer(LASHandleL,     3,  Shift,  1, LASLM1Band)           == -1   ||
      CopyBuffer(LASHandleL,     4,  Shift,  1, LASLM2Band)           == -1   ||
      CopyBuffer(LASHandleL,     5,  Shift,  1, LASLM3Band)           == -1   ||

      CopyBuffer(LASHandleS,     6,  Shift,  2, LASSBuffer)           == -1   ||
      CopyBuffer(LASHandleS,     7,  Shift,  1, LASSColorBuffer)      == -1   ||
      CopyBuffer(LASHandleS,     0,  Shift,  1, LASSP3Band)           == -1   ||
      CopyBuffer(LASHandleS,     1,  Shift,  1, LASSP2Band)           == -1   ||
      CopyBuffer(LASHandleS,     2,  Shift,  1, LASSP1Band)           == -1   ||
      CopyBuffer(LASHandleS,     3,  Shift,  1, LASSM1Band)           == -1   ||
      CopyBuffer(LASHandleS,     4,  Shift,  1, LASSM2Band)           == -1   ||
      CopyBuffer(LASHandleS,     5,  Shift,  1, LASSM3Band)           == -1   ||

      CopyBuffer(WmaHandleS,     0,  Shift,  1, WmaSBuffer)           == -1   ||
      CopyBuffer(WmaHandleS,     1,  Shift,  1, WmaSColorBuffer)      == -1   ||
      
      CopyBuffer(WmaHandleM,     0,  Shift,  1, WmaMBuffer)           == -1   ||
      CopyBuffer(WmaHandleM,     1,  Shift,  1, WmaMColorBuffer)      == -1   ||
      
      CopyBuffer(WmaHandleL,     0,  Shift,  1, WmaLBuffer)           == -1   ||
      CopyBuffer(WmaHandleL,     1,  Shift,  1, WmaLColorBuffer)      == -1   ||
      
      CopyBuffer(BSPHandle,     0,  Shift,  1, BSPBuffer)             == -1   ||
      CopyBuffer(BSPHandle,     1,  Shift,  1, BSPColorBuffer)        == -1   ||
      CopyBuffer(BSPHandle,     2,  Shift,  1, BSPWmaBuffer)          == -1   ||
      CopyBuffer(BSPHandle,     3,  Shift,  1, BSP3Band)              == -1   ||
      CopyBuffer(BSPHandle,     4,  Shift,  1, BSP2Band)              == -1   ||
      CopyBuffer(BSPHandle,     5,  Shift,  1, BSP1Band)         == -1           )  { return(false);}

   NLRSValue   = NLRSBuffer[0];
   NLRMValue   = NLRMBuffer[0];
   NLRLValue   = NLRLBuffer[0];
   LASMValue   = LASMBuffer[0];
   LASLValue   = LASLBuffer[0];
   LASSValue   = LASSBuffer[0];
   WmaSValue   = WmaSBuffer[0];
   WmaMValue   = WmaMBuffer[0];
   WmaLValue   = WmaLBuffer[0];
   BSPValue    = BSPBuffer[0];
   BSPWmaValue = BSPWmaBuffer[0];
   BSPSTD      = BSP1Band[0];
   
   NLRSTrend1 = NLRSTrend; if( (int)NormalizeDouble(NLRSColorBuffer[0], 0) == 1) NLRSTrend = DownTrend;  else NLRSTrend = UpTrend;
   NLRMTrend1 = NLRMTrend; if( (int)NormalizeDouble(NLRMColorBuffer[0], 0) == 1) NLRMTrend = DownTrend;  else NLRMTrend = UpTrend;
   NLRLTrend1 = NLRLTrend; if( (int)NormalizeDouble(NLRLColorBuffer[0], 0) == 1) NLRLTrend = DownTrend;  else NLRLTrend = UpTrend;
   LASMTrend1 = LASMTrend; if( (int)NormalizeDouble(LASMColorBuffer[0], 0) == 1) LASMTrend = DownTrend;  else LASMTrend = UpTrend;
   LASLTrend1 = LASLTrend; if( (int)NormalizeDouble(LASLColorBuffer[0], 0) == 1) LASLTrend = DownTrend;  else LASLTrend = UpTrend;
   LASSTrend1 = LASSTrend; if( (int)NormalizeDouble(LASSColorBuffer[0], 0) == 1) LASSTrend = DownTrend;  else LASSTrend = UpTrend;
   WmaSTrend1 = WmaSTrend; if( (int)NormalizeDouble(WmaSColorBuffer[0], 0) == 1) WmaSTrend = DownTrend;  else WmaSTrend = UpTrend;
   WmaMTrend1 = WmaMTrend; if( (int)NormalizeDouble(WmaMColorBuffer[0], 0) == 1) WmaMTrend = DownTrend;  else WmaMTrend = UpTrend;
   WmaLTrend1 = WmaLTrend; if( (int)NormalizeDouble(WmaLColorBuffer[0], 0) == 1) WmaLTrend = DownTrend;  else WmaLTrend = UpTrend;  
   BSPTrend1  = BSPTrend;  if( (int)NormalizeDouble(BSPColorBuffer[0], 0) == 1) BSPTrend = DownTrend;    else BSPTrend = UpTrend;

   if( (LASSTrend == LASSTrend1) || (LASSTrend == NoTrend) ) LASSTrendN++;    else LASSTrendN = 1;
   if( (LASMTrend == LASMTrend1) || (LASMTrend == NoTrend) ) LASMTrendN++;    else LASMTrendN = 1;
   if( (LASLTrend == LASLTrend1) || (LASLTrend == NoTrend) ) LASLTrendN++;    else LASLTrendN = 1;
   
   if(TrendS1!=NoTrend) TrendS2=TrendS1; 
   TrendS1=TrendS;
   if( (NLRSTrend == DownTrend) && (WmaSTrend == DownTrend) ) TrendS = DownTrend;
   else if ( (NLRSTrend == UpTrend) && (WmaSTrend == UpTrend) ) TrendS = UpTrend;
   else TrendS = NoTrend;
   
   if(TrendM1!=NoTrend) TrendM2=TrendM1; 
   TrendM1 = TrendM;
   if( (NLRMTrend == DownTrend) && (WmaMTrend == DownTrend) ) TrendM = DownTrend;
   else if ( (NLRMTrend == UpTrend) && (WmaMTrend == UpTrend) ) TrendM = UpTrend;
   else TrendM = NoTrend;
       
   if(TrendL1!=NoTrend) TrendL2=TrendL1; 
   TrendL1 = TrendL;
   if( (NLRLTrend == DownTrend) && (WmaLTrend == DownTrend) ) TrendL = DownTrend;
   else if ( (NLRLTrend == UpTrend) && (WmaLTrend == UpTrend) ) TrendL = UpTrend;
   else TrendL = NoTrend;

   if( (TrendS==TrendS1)||(TrendS==NoTrend)||((TrendS1==NoTrend)&&(TrendS==TrendS2)) ) TrendSN++;    else TrendSN = 1;
   if( (TrendM==TrendM1)||(TrendM==NoTrend)||((TrendM1==NoTrend)&&(TrendM==TrendM2)) ) TrendMN++;    else TrendMN = 1;
   if( (TrendL==TrendL1)||(TrendL==NoTrend)||((TrendL1==NoTrend)&&(TrendL==TrendL2)) ) TrendLN++;    else TrendLN = 1;
   
   
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

   if      (LASSValue > LASSP3Band[0])         LASSBand = BandP3;
   else if (LASSValue > LASSP2Band[0])         LASSBand = BandP2;
   else if (LASSValue > LASSP1Band[0])         LASSBand = BandP1; 
   else if (LASSValue > 0. )                   LASSBand = BandP0;
   else if (LASSValue > LASSM1Band[0])         LASSBand = BandM0;
   else if (LASSValue > LASSM2Band[0])         LASSBand = BandM1;
   else if (LASSValue > LASSM3Band[0])         LASSBand = BandM2;
   else                                        LASSBand = BandM3; 

   if      (BSPValue > BSP3Band[0])            BSPBand = BandP3;
   else if (BSPValue > BSP2Band[0])            BSPBand = BandP2;
   else if (BSPValue > BSP1Band[0])            BSPBand = BandP1;
   else                                        BSPBand = BandP0; 

   if      (BSPWmaValue > BSP3Band[0])         BSPWmaBand = BandP3;
   else if (BSPWmaValue > BSP2Band[0])         BSPWmaBand = BandP2;
   else if (BSPWmaValue > BSP1Band[0])         BSPWmaBand = BandP1;
   else                                        BSPWmaBand = BandP0;

   if(ThBSP==STD)  ThBSPValue=MathAbs(BSPSTD*PyramidGloConst.pyramidThMulti);
   else            ThBSPValue=MathAbs(BSPWmaValue*PyramidGloConst.pyramidThMulti);
   
   if(IncBSP==STD) IncBSPValue=MathAbs(BSPSTD*PyramidGloConst.pyramidIncMulti);
   else            IncBSPValue=MathAbs(BSPWmaValue*PyramidGloConst.pyramidIncMulti);
   
      
   if( ((LASMBuffer[1]>=0.) && (LASMBuffer[0]<=0. )) || ((LASMBuffer[1]<=0.) && (LASMBuffer[0]>=0.)) )
     {
      if( Times(curTime) && !StartTrading )  StartTrading = true;  
     }     
   else if( !Times(curTime) && StartTrading )  StartTrading = false;  

   if(CloseTimes(curTime)) CloseAllTrading=true;
   else CloseAllTrading = false;

   return(true);  

}
