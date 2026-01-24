//+------------------------------------------------------------------+
//|                                                       InitV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV7/ExternVariables.mqh>
//#include <BSPV7/ReadyCheckV7.mqh>
//#include <BSPV7/MagicNumberV7.mqh>


bool Initialize(void)
{

   // Loading indicators..
   LASHandleM        = iCustom(_Symbol,_Period, IND2, LwmaPeriodM, AvgPeriodM, StdPeriodLM, StdPeriodSM,
                                                        MultiFactorL1M, MultiFactorL2M, MultiFactorL3M,  MaxBSPMultM );
   LASHandleL        = iCustom(_Symbol,_Period, IND2, LwmaPeriodL, AvgPeriodL, StdPeriodLL, StdPeriodSL,
                                                        MultiFactorL1L, MultiFactorL2L, MultiFactorL3L, MaxBSPMultL);
   WmaHandleS        = iCustom(_Symbol,_Period, IND3, WmaPeriodS); 
   BSPNlrWmaHandleS  = iCustom(_Symbol,_Period, IND5, BSPNlrPeriodS, BSPWmaPeriodS);
   BSPNlrWmaHandleL  = iCustom(_Symbol,_Period, IND5, BSPNlrPeriodL, BSPWmaPeriodL);   
   NLRLHandleL       = iCustom(_Symbol,_Period, IND1, NLRLPeriod );
   WmaHandleL        = iCustom(_Symbol,_Period, IND3, WmaPeriodL); 
   BSPHandle         = iCustom(_Symbol,_Period, IND4, WmaBSP, BSPStdPeriodL,  
                                                        BSPMultiFactorL1, BSPMultiFactorL2, BSPMultiFactorL3, BSPCutOff);  


   if( LASHandleM       == INVALID_HANDLE || LASHandleL       == INVALID_HANDLE || WmaHandleS  == INVALID_HANDLE ||
       BSPNlrWmaHandleS == INVALID_HANDLE || BSPNlrWmaHandleL == INVALID_HANDLE || NLRLHandleL == INVALID_HANDLE || 
       WmaHandleL  == INVALID_HANDLE      || BSPHandle   == INVALID_HANDLE )
     {
      Alert("Error when loading the indicator, please try again");
      return(false);
     }  
  
   if(!Sym.Name(_Symbol))
     {
      Alert("CSymbolInfo initialization error, please try again");    
      return(false);
     }

   ArraySetAsSeries(NLRLBuffer, true);
   ArraySetAsSeries(NLRLColorBuffer, true);

   ArraySetAsSeries(LASMBuffer, true);
   ArraySetAsSeries(LASMColorBuffer, true);
   ArraySetAsSeries(LASMP3Band, true);
   ArraySetAsSeries(LASMP2Band, true);
   ArraySetAsSeries(LASMP1Band, true);
   ArraySetAsSeries(LASMM1Band, true);
   ArraySetAsSeries(LASMM2Band, true);
   ArraySetAsSeries(LASMM3Band, true);

   ArraySetAsSeries(LASLBuffer, true);
   ArraySetAsSeries(LASLColorBuffer, true);
   ArraySetAsSeries(LASLP3Band, true);
   ArraySetAsSeries(LASLP2Band, true);
   ArraySetAsSeries(LASLP1Band, true);
   ArraySetAsSeries(LASLM1Band, true);
   ArraySetAsSeries(LASLM2Band, true);
   ArraySetAsSeries(LASLM3Band, true);

   ArraySetAsSeries(WmaSBuffer, true);
   ArraySetAsSeries(WmaSColorBuffer, true);
   ArraySetAsSeries(WmaLBuffer, true);
   ArraySetAsSeries(WmaLColorBuffer, true);

   ArraySetAsSeries(BSPNlrWmaBufferS, true);
   ArraySetAsSeries(BSPNlrWmaColorBufferS, true);
   ArraySetAsSeries(BSPNlrWmaBufferL, true);
   ArraySetAsSeries(BSPNlrWmaColorBufferL, true);
 
   ArraySetAsSeries(BSPBuffer, true);
   ArraySetAsSeries(BSPWmaBuffer, true);
   ArraySetAsSeries(BSP1Band, true);

/*
// If program stopped and Restart again, How to close the opened orphan positions?--------
*/

   ArrayResize(PositionSummary, TotalSession);
   ArrayResize(BeforePM, TotalSession);
   ArrayResize(CurPM, TotalSession);
   ArrayResize(BasePositionMN, TotalSession);
   ArrayResize(CurrPositionMN, TotalSession);
   ArrayResize(ReOC, TotalSession);
   ArrayResize(OpenReady, TotalSession);  
   
   if(!MagicNumberInit()) return(false);
      
   SessionMan.LastSession=0;
   SessionMan.CurSession=0;
   SessionMan.CanGoBand=true;
   SessionMan.CanGoTrend=true;
   
   PyramidGloConst.pyramidThMulti=t_PyramidThMulti;
   PyramidGloConst.pyramidIncMulti=t_PyramidIncMulti;
   PyramidGloConst.pydStartSizeMulti=t_PydStartSizeMulti;
   PyramidGloConst.coneDecMulti=t_ConeDecMulti;
    
   for(int m_Session=0; m_Session<TotalSession;m_Session++)
     {
      InitPositionSum(m_Session);            
      ReOCReset(m_Session);
      BeforePM[m_Session]=NoMode;
      CurPM[m_Session]=NoMode;
      OpenReadyReset(m_Session);
     }
     

   return(true);
}


//-------------------------------------------------------------------------+
void InitPositionSum(int m_Session)
{
   PositionSummary[m_Session].totalNumPositions=0;
   PositionSummary[m_Session].currentNumPositions=0;
   PositionSummary[m_Session].startingBar=0;
   PositionSummary[m_Session].firstPositionTrend=NoTrend;
   PositionSummary[m_Session].lastPositionTrend=NoTrend;
   PositionSummary[m_Session].totalSize=0;
   PositionSummary[m_Session].currentSize=0;
   PositionSummary[m_Session].pyramidStarted=false;
   PositionSummary[m_Session].pyramidTrend=NoTrend;
   PositionSummary[m_Session].pyramidPID=NoID;
   PositionSummary[m_Session].lastStackNum=0;
   PositionSummary[m_Session].lastWmaS=0.;
} 

//-------------------------------------------------------------------------+
void InitPyramidData(int m_Session)
{
   PositionSummary[m_Session].pyramidStarted=false;
   PositionSummary[m_Session].pyramidTrend=NoTrend;
   PositionSummary[m_Session].pyramidPID=NoID;
   PositionSummary[m_Session].lastStackNum=0;
   PositionSummary[m_Session].lastWmaS=0.;
} 

//--------------------------------------------------------------------+
void ReOCReset(int m_Session)
{
   ReOC[m_Session].MaxBar=0;
   ReOC[m_Session].MaxBSP=0.;
   ReOC[m_Session].MinBar=0;   
   ReOC[m_Session].MinBSP=0.;
   ReOC[m_Session].MaxMinBar=0;
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

void InitMinMax(int m_Session)
{
   ReOC[m_Session].MaxBar=0;
   ReOC[m_Session].MaxBSP=0.;
   ReOC[m_Session].MinBar=0;   
   ReOC[m_Session].MinBSP=0.;
   ReOC[m_Session].MaxMinBar=0;
}

//-------------------------------------------------------------------+
void OpenReadyReset(int m_Session)
{
   OpenReady[m_Session].BuyLASMReady = false;
   OpenReady[m_Session].BuyLASMBar=0;
   OpenReady[m_Session].BuyTrendReady = false;

   OpenReady[m_Session].SellLASMReady = false;
   OpenReady[m_Session].SellLASMBar=0;
   OpenReady[m_Session].SellTrendReady = false;
}
