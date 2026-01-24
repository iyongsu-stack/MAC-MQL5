//+------------------------------------------------------------------+
//|                                                    PyramidV6.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV6/ExternVariables.mqh>
//#include <BSPV6/OpenCloseV6.mqh>

//-------------------------------------------------------------------------------------------------------------------
void KeepPyramiding(int m_Session)
{
   double m_PyramidWmaS;
   double m_LotSizeMulti=PyramidGloConst.pydStartSizeMulti*MathPow(PyramidGloConst.coneDecMulti, PositionSummary[m_Session].lastStackNum);
          if(m_LotSizeMulti<=0.1)  m_LotSizeMulti=0.1;

   if(PositionSummary[m_Session].pyramidTrend==UpTrend)
     {
      m_PyramidWmaS=PositionSummary[m_Session].lastWmaS+IncBSPValue;

      if(m_PyramidWmaS<=WmaSValue) 
        {            
         if(OpenPositionByPID(POSITION_TYPE_BUY, m_LotSizeMulti, m_Session, PositionSummary[m_Session].pyramidPID))
           {
            PositionSummary[m_Session].lastStackNum++;
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
            PositionSummary[m_Session].lastStackNum++;
            PositionSummary[m_Session].lastWmaS=WmaSValue;
           }
        }   
     }                       
}

