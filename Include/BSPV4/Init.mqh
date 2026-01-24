//+------------------------------------------------------------------+
//|                                                         Init.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

#include <BSPV4/ExternVariables.mqh>
#include <BSPV4/ReadyCheckV3.mqh>

int Initialize(void)
{

   Trade.SetExpertMagicNumber(iMagicNumber);

   _VirtualSLTP=VirtualSLTP;
   if(_VirtualSLTP && StopLoss<=0 && TakeProfit<=0)
   {
      _VirtualSLTP=false;
   }

   // Loading indicators..
   LASHandleS        = iCustom(_Symbol,_Period, IND2, LwmaPeriodS, AvgPeriodS, StdPeriodLS, StdPeriodSS,
                                                        MultiFactorL1S, MultiFactorL2S, MultiFactorL3S, MaxBSPMultS);   
   LASHandleM        = iCustom(_Symbol,_Period, IND2, LwmaPeriodM, AvgPeriodM, StdPeriodLM, StdPeriodSM,
                                                        MultiFactorL1M, MultiFactorL2M, MultiFactorL3M,  MaxBSPMultM );
   LASHandleL        = iCustom(_Symbol,_Period, IND2, LwmaPeriodL, AvgPeriodL, StdPeriodLL, StdPeriodSL,
                                                        MultiFactorL1L, MultiFactorL2L, MultiFactorL3L, MaxBSPMultL);
   NLRSHandle        = iCustom(_Symbol,_Period, IND1, NLRSPeriod );
   WmaHandleS        = iCustom(_Symbol,_Period, IND3, WmaPeriodS); 
   NLRMHandle        = iCustom(_Symbol,_Period, IND1, NLRMPeriod );
   WmaHandleM        = iCustom(_Symbol,_Period, IND3, WmaPeriodM); 
   NLRLHandle        = iCustom(_Symbol,_Period, IND1, NLRLPeriod );
   WmaHandleL        = iCustom(_Symbol,_Period, IND3, WmaPeriodL); 
   BSPHandle         = iCustom(_Symbol,_Period, IND4, WmaBSP, BSPStdPeriodL,  
                                                        BSPMultiFactorL1, BSPMultiFactorL2, BSPMultiFactorL3, BSPCutOff);  


   if( NLRSHandle  == INVALID_HANDLE  || NLRMHandle  == INVALID_HANDLE  || NLRLHandle  == INVALID_HANDLE || LASHandleM   == INVALID_HANDLE || 
       LASHandleL   == INVALID_HANDLE || LASHandleS  == INVALID_HANDLE  || WmaHandleS  == INVALID_HANDLE || WmaHandleM   == INVALID_HANDLE || 
       WmaHandleL  == INVALID_HANDLE  || BSPHandle   == INVALID_HANDLE )
   {
      Alert("Error when loading the indicator, please try again");
      return(-1);
   }  
  
   if(!Sym.Name(_Symbol))
   {
      Alert("CSymbolInfo initialization error, please try again");    
      return(-1);
   }

   ArraySetAsSeries(NLRSBuffer, true);
   ArraySetAsSeries(NLRSColorBuffer, true);
   ArraySetAsSeries(NLRMBuffer, true);
   ArraySetAsSeries(NLRMColorBuffer, true);
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

   ArraySetAsSeries(LASSBuffer, true);
   ArraySetAsSeries(LASSColorBuffer, true);
   ArraySetAsSeries(LASSP3Band, true);
   ArraySetAsSeries(LASSP2Band, true);
   ArraySetAsSeries(LASSP1Band, true);
   ArraySetAsSeries(LASSM1Band, true);
   ArraySetAsSeries(LASSM2Band, true);
   ArraySetAsSeries(LASSM3Band, true);

   ArraySetAsSeries(WmaSBuffer, true);
   ArraySetAsSeries(WmaSColorBuffer, true);
   ArraySetAsSeries(WmaMBuffer, true);
   ArraySetAsSeries(WmaMColorBuffer, true);
   ArraySetAsSeries(WmaLBuffer, true);
   ArraySetAsSeries(WmaLColorBuffer, true);

   ArraySetAsSeries(BSPBuffer, true);
   ArraySetAsSeries(BSPColorBuffer, true);
   ArraySetAsSeries(BSPWmaBuffer, true);
   ArraySetAsSeries(BSP3Band, true);
   ArraySetAsSeries(BSP2Band, true);
   ArraySetAsSeries(BSP1Band, true);
   ArraySetAsSeries(PositionInfo, false);
/*
// If program stopped and Restart again, How to close the opened orphan positions--------
*/


   ReOC.LCBars=20;
   ReOC.BuyLCLASLBand=m_BuyLCLASLBand;
   ReOC.SellLCLASLBand=m_SellLCLASLBand;
   ReOC.DLRBars=m_DLRBars;
   ReOC.BuyDLRLASLBand=m_BuyDLRLASLBand;
   ReOC.SellDLRLASLBand=m_SellDLRLASLBand;
   ReOC.RORBars=m_RORBars;
   ReOC.DLRNoiseTF=m_DLRNoiseTF;

   OpenReadyReset();
   return(0);
}
