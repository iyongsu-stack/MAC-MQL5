//+------------------------------------------------------------------+
//|                                                  OpenCloseV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV6/ExternVariables.mqh>
//#include <BSPV6/CommonV6.mqh>
//#include <BSPV6/ReadyCheckV6.mqh>
//#include <BSPV6/MagicNumberV6.mqh>
//#include <BSPV6/MoneyManageV6.mqh>



//------------------------------------------------------------------------
position_Mode OpenSignal(int m_Session)
{
   if( CurBar==ReOC[m_Session].MRBar && CurBar!=ReOC[m_Session].LRBar ) return(MiddleReverse);
   else if( CurBar==ReOC[m_Session].MRBar && CurBar==ReOC[m_Session].LRBar )  return(LongReverse);  
   else if( CurBar==ReOC[m_Session].LRConBar )  return(LongReverseCon);
   else if( CurBar==ReOC[m_Session].LCBar )  return(LongCounter);   
   else if( CurBar==ReOC[m_Session].LCConBar )  return(LongCounterCon);   
   else if( CurBar==ReOC[m_Session].DLRBar)  return(DoubleLongReverse);   
   else if( CurBar==ReOC[m_Session].DLRConBar )  return(DLRCon);
   else if( CurBar==ReOC[m_Session].DLRCConBar )  return(DLRCCon);
   return(NoAction);
}

//------------------------------------------------------------------------
position_Mode CloseSignal(int m_Session)
{  
   if( CurBar==ReOC[m_Session].LCBar )  return(LongCounter);
   else if( CurBar==ReOC[m_Session].DLRBar )  return(DoubleLongReverse);
   else if( CurBar==ReOC[m_Session].DLRCConBar) return(DLRCCon);
   else if( CurBar==ReOC[m_Session].EndBar) return(End);
   return(NoAction);
}


//-------------------------------------------------------------------------
void MyOpenPosition(int m_Session)
{
   position_ID m_PositionID=No_Signal;
   ENUM_POSITION_TYPE m_PositionType=POSITION_TYPE_BUY;
   double m_LotSizeMulti=1.0;
   trend m_Trend=NoTrend;
     
   if(CurPM[m_Session]==MiddleReverse || CurPM[m_Session]==LongReverse ||
      CurPM[m_Session]==LongReverseCon)
     {
      if(BuyOpenReady.TrendReady)
        {
         if(CurPM[m_Session]==MiddleReverse) m_PositionID=Buy_MR;
         else                                m_PositionID=Buy_LR;  

         m_PositionType=POSITION_TYPE_BUY;  
        } 
      else if(SellOpenReady.TrendReady) 
        {
         if(CurPM[m_Session]==MiddleReverse) m_PositionID=Sell_MR;
         else                                m_PositionID=Sell_LR; 

         m_PositionType=POSITION_TYPE_SELL;  
        }
     }
   else if(CurPM[m_Session]==DoubleLongReverse||CurPM[m_Session]==DLRCon)
     {
      if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_BUY) 
        {
         m_PositionID=Buy_DLR;
         m_PositionType=POSITION_TYPE_BUY;
        }
      else 
        {
         m_PositionID=Sell_DLR;
         m_PositionType=POSITION_TYPE_SELL;
        }     
     }
   else if(CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon ||
           CurPM[m_Session]==DLRCCon)   
     {
      if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_BUY) 
        {
         if(CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon) m_PositionID=Sell_LC;
         else if(CurPM[m_Session]==DLRCCon) m_PositionID=Sell_DLRCC;
         m_PositionType=POSITION_TYPE_SELL;
        }
      else 
        {
         if(CurPM[m_Session]==LongCounter || CurPM[m_Session]==LongCounterCon) m_PositionID=Buy_LC;
         else if(CurPM[m_Session]==DLRCCon) m_PositionID=Buy_DLRCC;
         m_PositionType=POSITION_TYPE_BUY;
        }     
     }  

   if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon  ||
        CurPM[m_Session]==LongCounterCon || CurPM[m_Session]==DLRCCon  )
     {

      if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_BUY) 
        {
         if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon)
            m_Trend=UpTrend;
         else m_Trend=DownTrend;
        }
      else 
        {
         if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon)
            m_Trend=DownTrend;
         else m_Trend=UpTrend;
        }

      PositionSummary[m_Session].pyramidStarted=true;  
      PositionSummary[m_Session].pyramidTrend=m_Trend; 
      PositionSummary[m_Session].pyramidPID=m_PositionID;
      PositionSummary[m_Session].lastStackNum++;
      PositionSummary[m_Session].lastWmaS=WmaSValue;     
      m_LotSizeMulti=PyramidGloConst.pydStartSizeMulti;       
     }        
      
   if(BeforePM[m_Session]==LongCounterCon && CurPM[m_Session]==DoubleLongReverse)
     {
      PositionSummary[m_Session].pyramidStarted=false;  
      PositionSummary[m_Session].pyramidTrend=NoTrend; 
     }


   if(m_PositionID!=No_Signal)
      OpenPositionByPID(m_PositionType, m_LotSizeMulti, m_Session, m_PositionID);
}


//-----------------------------------------------------------------------
void MyClosePosition(int m_Session)
{
   
   if(CurPM[m_Session]!=End && PositionSummary[m_Session].firstPositionType==POSITION_TYPE_BUY) 
     {
      if(CurPM[m_Session]==LongCounter)
       {
         ClosePositionByPID(m_Session, Buy_MR);         
         ClosePositionByPID(m_Session, Buy_LR);
       }

      if(CurPM[m_Session]==DoubleLongReverse)
         ClosePositionByPID(m_Session, Sell_LC);

      if(CurPM[m_Session]==DLRCCon)
         ClosePositionByPID(m_Session, Buy_DLR);        
     }
   else if(CurPM[m_Session]!=End && PositionSummary[m_Session].firstPositionType==POSITION_TYPE_SELL)
     {
      if(CurPM[m_Session]==LongCounter)
       {
         ClosePositionByPID(m_Session, Sell_MR);         
         ClosePositionByPID(m_Session, Sell_LR);
       }

      if(CurPM[m_Session]==DoubleLongReverse)
         ClosePositionByPID(m_Session, Buy_LC);

      if(CurPM[m_Session]==DLRCCon)
         ClosePositionByPID(m_Session, Sell_DLR);        
     }      
        
      
   else if(CurPM[m_Session]==End) 
     {
      ClosePositionBySession(m_Session);
      InitPositionSum(m_Session); 
     }    
}




//-------------------------------------------------------------------------+
void ClosePositionBySession(int m_Session)
{
   if(!Sym.RefreshRates())return;        

   int total=PositionsTotal();
   if(total<=0) return;
   
   for(int i=(total -1); i>=0; i--)
     {
      if(! Pos.SelectByIndex(i))
        {
         Alert("Position Selection Error");
         return;
        }

      int m_PositionMN = int(PositionGetInteger(POSITION_MAGIC));
      string position_symbol=PositionGetSymbol(i);

      if(position_symbol==_Symbol && BaseMagicNumber==PositionBMN(m_PositionMN) && 
         m_Session==SessionByMN(m_PositionMN) )
        {
         if(!ClosePositionByMN(m_Session, m_PositionMN) )
           {
            Alert("Position is not Matching");
            return;
           }                 
        }      
     }
   MNInitByPID(m_Session, AllID);  
}


//------------------------------------------------------------------
void ClosePositionByPID(int m_Session, position_ID m_PositionID)
{
   int m_StartingMN=BaseMNByPID(m_Session, m_PositionID);
   int m_EndMN=CurrMNByPID(m_Session, m_PositionID);
    
   if(!Sym.RefreshRates())return;        

   int total=PositionsTotal();
   if(total<=0) return;
   
   for(int i=(total -1); i>=0; i--)
     {
      if(! Pos.SelectByIndex(i))
        {
         Alert("Position Selection Error");
         return;
        }

      int m_PositionMN=(int)Pos.Magic();
      string position_symbol=Pos.Symbol();

      if(position_symbol==_Symbol && BaseMagicNumber==PositionBMN(m_PositionMN) &&
         m_PositionMN>m_StartingMN &&  m_PositionMN<=m_EndMN )
        {
         if(!ClosePositionByMN(m_Session, m_PositionMN)) 
           {
            Alert("Position is not Matching");
            return;
           }                 
        }             
     }   
   MNInitByPID(m_Session, m_PositionID);           
}

//-----------------------------------------------------------------------------
bool ClosePositionByMN(int m_Session, int m_MagicNumber)
{

   if(!Sym.RefreshRates()) return(false);        

   if(! Pos.SelectByMagic(_Symbol, m_MagicNumber))
     {
      Alert("Position Selection Error");
      return(false);
     }

    Trade.SetDeviationInPoints(Sym.Spread()*3);
    Trade.SetExpertMagicNumber(m_MagicNumber);

    if(Trade.PositionClose(PositionGetInteger(POSITION_TICKET)))
      {
       DeRegisterPosition(m_Session, m_MagicNumber);
       return(true);
      } 
    else{ 
         Alert("Position Close Error"); 
         return(false);
        }
                      
    return(true);   
}

//---------------------------------------------------------------------------------------
bool OpenPositionByPID(ENUM_POSITION_TYPE m_PositionType, double m_LotSizeMulti, int m_Session, 
                       position_ID m_PositionID)
{
   int m_MagicNumber, tempMN, StopLossPoints; 
   double m_LotSize, m_RiskMulti; 

   int m_Total=PositionsTotal();
   if(m_Total>MaxPosition) return(false);
   tempMN=NextMNByPID(m_Session, m_PositionID);        
      
   if(tempMN) m_MagicNumber=tempMN;
   else return(false);
   
   StopLossPoints=(int)ThBSPValue;
   m_RiskMulti=iRisk_FractionOfCapital*m_LotSizeMulti;
   m_LotSize=CalculateLotSize(m_RiskMulti, StopLossPoints);
      
   if(OpenPosition(m_PositionType, m_MagicNumber, m_LotSize)) 
     {
      RegisterPosition(m_PositionType, m_Session, m_PositionID, m_MagicNumber);
      return(true);
     } 
   else return(false);
}

//------------------------------------------------------------------------------------
bool OpenPosition(ENUM_POSITION_TYPE m_PositionType, int m_MagicNumber, double m_LotSize)
{
   if(!Sym.RefreshRates()) return(false);    
   Trade.SetExpertMagicNumber(m_MagicNumber);        
   string m_MNstring = string(m_MagicNumber);   
   Trade.SetDeviationInPoints(Sym.Spread()*3);
 

   if(m_PositionType == POSITION_TYPE_BUY)
     {
      if(Trade.Buy(m_LotSize,_Symbol,0,0,0,m_MNstring)) return(true);
      else
        { 
         Alert("Cannot open a Buy position, nearing the Stop Loss or Take Profit");
         return(false);
        }
     }   

   if(m_PositionType == POSITION_TYPE_SELL)
     {
      
      if(Trade.Sell(m_LotSize,_Symbol,0,slv,tpv,m_MNstring)) return(true); 
      else 
        {
         Alert("Cannot open a Sell position, nearing the Stop Loss or Take Profit");
         return(false);
        } 
     } 
   return(true);        
}    


 //---------------------------------------------------------------------
void RegisterPosition(ENUM_POSITION_TYPE m_PositionType, int m_Session, position_ID m_PositionID, int m_MagicNumber)
{
   double m_OpenSize=Trade.ResultVolume();

   if( PositionSummary[m_Session].totalNumPositions == 0) 
      {
         PositionSummary[m_Session].firstPositionType = m_PositionType;
         PositionSummary[m_Session].startingBar = CurBar;
      }   
   PositionSummary[m_Session].lastPositionType = m_PositionType;
   PositionSummary[m_Session].totalNumPositions++;
   PositionSummary[m_Session].currentNumPositions++;
   PositionSummary[m_Session].totalSize += m_OpenSize;
   PositionSummary[m_Session].currentSize += m_OpenSize;
   
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].openSequence = PositionSummary[m_Session].totalNumPositions;
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].isOpenNow = true;
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].positionType = m_PositionType;
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].positionID = m_PositionID;
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].pMagicNumber = m_MagicNumber;
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].openBar = CurBar;
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].openVolume = Trade.ResultVolume();
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].openPrice = Trade.ResultPrice();
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].openWmaS = WmaSValue;   
}

//---------------------------------------------------------------------
bool DeRegisterPosition(int m_Session, int m_MagicNumber)
{
   int totalPosition = PositionSummary[m_Session].totalNumPositions;
   for(int i=0;i<totalPosition;i++)
     {
      if(PositionInfo[m_Session][i].pMagicNumber==m_MagicNumber)
        {
         PositionSummary[m_Session].currentSize-=PositionInfo[m_Session][i].openVolume;
         PositionSummary[m_Session].currentNumPositions--;
         PositionInfo[m_Session][i].openSequence=0;
         PositionInfo[m_Session][i].isOpenNow=false;
         PositionInfo[m_Session][i].positionID=NoID;
         PositionInfo[m_Session][i].pMagicNumber=0;
         PositionInfo[m_Session][i].openBar=0;
         PositionInfo[m_Session][i].openVolume=0.;
         PositionInfo[m_Session][i].openPrice=0.;
         PositionInfo[m_Session][i].openWmaS=0.;

         return(true);
        }    
     }
     
   return(false);
} 

//-------------------------------------------------------------------------+
void InitPositionSum(int m_Session)
{
   PositionSummary[m_Session].totalNumPositions=0;
   PositionSummary[m_Session].currentNumPositions=0;
   PositionSummary[m_Session].startingBar=0;
   PositionSummary[m_Session].totalSize=0;
   PositionSummary[m_Session].currentSize=0;
   PositionSummary[m_Session].pyramidStarted=false;
   PositionSummary[m_Session].pyramidTrend=NoTrend;
   PositionSummary[m_Session].pyramidPID=NoID;
   PositionSummary[m_Session].lastStackNum=0;
   PositionSummary[m_Session].lastWmaS=0.;
} 
