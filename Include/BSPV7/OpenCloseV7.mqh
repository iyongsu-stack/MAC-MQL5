//+------------------------------------------------------------------+
//|                                                  OpenCloseV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV7/ExternVariables.mqh>
//#include <BSPV7/CommonV7.mqh>
//#include <BSPV7/ReadyCheckV7.mqh>
//#include <BSPV7/MagicNumberV7.mqh>
//#include <BSPV7/MoneyManageV7.mqh>


//------------------------------------------------------------------------
position_Mode OpenSignal(int m_Session)
{
   position_Mode m_PositionMode=NoAction;
   
   if( CurBar==ReOC[m_Session].LRBar )      m_PositionMode=LongReverse;  
   if( CurBar==ReOC[m_Session].LRConBar )   m_PositionMode=LongReverseCon;
   if( CurBar==ReOC[m_Session].LCBar )      m_PositionMode=LongCounter;   
   if( CurBar==ReOC[m_Session].LCConBar )   m_PositionMode=LongCounterCon;   
   if( CurBar==ReOC[m_Session].DLRBar)      m_PositionMode=DoubleLongReverse;   
   if( CurBar==ReOC[m_Session].DLRConBar )  m_PositionMode=DLRCon;
   if( CurBar==ReOC[m_Session].DLRCConBar ) m_PositionMode=DLRCCon;
   
   return(m_PositionMode);
}

//------------------------------------------------------------------------
position_Mode CloseSignal(int m_Session)
{  
   position_Mode m_PositionMode=NoAction;
   
   if( CurBar==ReOC[m_Session].LCBar )     m_PositionMode=LongCounter;
   if( CurBar==ReOC[m_Session].DLRBar )    m_PositionMode=DoubleLongReverse;
   if( CurBar==ReOC[m_Session].DLRCConBar) m_PositionMode=DLRCCon;
   if( CurBar==ReOC[m_Session].EndBar)     m_PositionMode=End;

   return(m_PositionMode);
}


//-------------------------------------------------------------------------
void MyOpenPosition(int m_Session)
{
   position_ID m_PositionID=No_Signal;
   ENUM_POSITION_TYPE m_PositionType=POSITION_TYPE_BUY;
   double m_LotSizeMulti=1.0;
   trend m_Trend=NoTrend;

     
   if(CurPM[m_Session]==LongReverse)
     {
      if(OpenReady[m_Session].BuyTrendReady)
        {
         m_PositionID=Buy_LR;
         m_PositionType=POSITION_TYPE_BUY;  
        } 
      else if(OpenReady[m_Session].SellTrendReady)
        {
         m_PositionID=Sell_LR;
         m_PositionType=POSITION_TYPE_SELL;  
        }
     }
   else if(CurPM[m_Session]==LongCounter)   //Caution OpenPosition at DLRCCon---
     {
      if(PositionSummary[m_Session].firstPositionTrend==UpTrend) 
        {
         m_PositionID=Sell_LC;
         m_PositionType=POSITION_TYPE_SELL;
        }
      else 
        {
         m_PositionID=Buy_LC;
         m_PositionType=POSITION_TYPE_BUY;
        }     
     }  
   else if(CurPM[m_Session]==DoubleLongReverse)
     {
      if(PositionSummary[m_Session].firstPositionTrend==UpTrend) 
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


   if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon  || 
      CurPM[m_Session]==LongCounterCon || CurPM[m_Session]==DLRCCon  )
     {      
      if(PositionSummary[m_Session].firstPositionTrend==UpTrend) 
        {
         if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon)
           { 
            if(CurPM[m_Session]==LongReverseCon)  m_PositionID=Buy_LR;
            else if(CurPM[m_Session]==DLRCon)  m_PositionID=Buy_DLR;
            
            m_PositionType=POSITION_TYPE_BUY;
            m_Trend=UpTrend;
           } 
         else
           {
            if(CurPM[m_Session]==LongCounterCon)  m_PositionID=Sell_LC;
            else if(CurPM[m_Session]==DLRCCon)  m_PositionID=Sell_DLRCC;
            
            m_PositionType=POSITION_TYPE_SELL;
            m_Trend=DownTrend;
           } 
        }
      else 
        {
         if(CurPM[m_Session]==LongReverseCon || CurPM[m_Session]==DLRCon )
           {
            if(CurPM[m_Session]==LongReverseCon)  m_PositionID=Sell_LR;
            else if(CurPM[m_Session]==DLRCon)  m_PositionID=Sell_DLR;
            
            m_PositionType=POSITION_TYPE_SELL;
            m_Trend=DownTrend;
           } 
         else
           {
            if(CurPM[m_Session]==LongCounterCon)  m_PositionID=Buy_LC;
            else if(CurPM[m_Session]==DLRCCon)  m_PositionID=Buy_DLRCC;
            
            m_PositionType=POSITION_TYPE_BUY;
            m_Trend=UpTrend;
           } 
        }
      PositionSummary[m_Session].pyramidStarted=true;  
      m_LotSizeMulti=m_LotSizeMulti*PyramidGloConst.pydStartSizeMulti;
      PositionSummary[m_Session].pyramidPID=m_PositionID;
      PositionSummary[m_Session].pyramidTrend=m_Trend;  
      PositionSummary[m_Session].lastWmaS=WmaSValue;
     }        
   
   if(m_Trend==NoTrend)
      m_LotSizeMulti = m_LotSizeMulti*t_NonPyramidMulti;
   
   if(m_PositionID!=No_Signal)
     {
      OpenPositionByPID(m_PositionType, m_LotSizeMulti, m_Session, m_PositionID);
     }    
     
   return;     
}


//-----------------------------------------------------------------------
void MyClosePosition(int m_Session)
{
   
   if(CurPM[m_Session]!=End &&
      PositionSummary[m_Session].firstPositionTrend==UpTrend) 
     {
      if( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) )
        {
         ClosePositionByPID(m_Session, Buy_LR);
        }
      else if( (CurPM[m_Session]==DoubleLongReverse) || (CurPM[m_Session]==DLRCon) )
        {
         ClosePositionByPID(m_Session, Sell_LC);
        }
      else if(CurPM[m_Session]==DLRCCon)
        {
         ClosePositionByPID(m_Session, Buy_DLR);        
        } 
     }
   else if(CurPM[m_Session]!=End &&
           PositionSummary[m_Session].firstPositionTrend==DownTrend)
     {
      if( (CurPM[m_Session]==LongCounter) || (CurPM[m_Session]==LongCounterCon) )
        {
         ClosePositionByPID(m_Session, Sell_LR);
        }
      else if( (CurPM[m_Session]==DoubleLongReverse) || (CurPM[m_Session]==DLRCon) )
        {
         ClosePositionByPID(m_Session, Buy_LC);
        }
      else if(CurPM[m_Session]==DLRCCon)
        {
         ClosePositionByPID(m_Session, Sell_DLR);        
        } 
     }              
   else if(CurPM[m_Session]==End) 
     {
      ClosePositionBySession(m_Session);
     } 
   
   return;     
}

//--------------------------------------------------------------------------
void CloseAllPositions(void)
{
    if(PositionsTotal()>=1)
     {
      for(int m_Session=0;m_Session<TotalSession;m_Session++)
        {
         if(PositionSummary[m_Session].currentNumPositions!=0) 
            ClosePositionBySession(m_Session);

         OpenReadyReset(m_Session);
        }
     }   
   SessionMan.LastSession=0;
   SessionMan.CurSession=0;
   SessionMan.CanGoBand=true;
   SessionMan.CanGoTrend=true;
   
   return;
}


//-------------------------------------------------------------------------+
void ClosePositionBySession(int m_Session)
{
   if(!Sym.RefreshRates())return;        

   int total=PositionsTotal();
   
   for(int i=(total -1); i>=0; i--)
     {
      if(! Pos.SelectByIndex(i)) Alert("Position Selection Error");
 
      int m_PositionMN = int(PositionGetInteger(POSITION_MAGIC));
      string position_symbol=PositionGetSymbol(i);

      if(position_symbol==_Symbol && BaseMagicNumber==PositionBMN(m_PositionMN) && 
         m_Session==SessionByMN(m_PositionMN) )
        {
         if(!ClosePositionByMN(m_Session, m_PositionMN) ) Alert("Position is not Matching");
        }      
     }
   MNInitByPID(m_Session, AllID);  
   ReOCReset(m_Session);  
   InitPositionSum(m_Session); 
   CurPM[m_Session]=NoMode;
   BeforePM[m_Session]=NoMode;
   
   return;
}


//------------------------------------------------------------------
void ClosePositionByPID(int m_Session, position_ID m_PositionID, bool isStopLoss=false, trend m_StopTrend=NoTrend)
{
   int m_StartingMN=BaseMNByPID(m_Session, m_PositionID);
   int m_EndMN=CurrMNByPID(m_Session, m_PositionID);
    
   if(!Sym.RefreshRates())return;        

   int total=PositionsTotal();
   
   for(int i=(total -1); i>=0; i--)
     {
      if(! Pos.SelectByIndex(i)) Alert("Position Selection Error");

      int m_PositionMN=(int)Pos.Magic();
      string position_symbol=Pos.Symbol();

      if(position_symbol==_Symbol && BaseMagicNumber==PositionBMN(m_PositionMN) &&
         m_PositionMN>m_StartingMN &&  m_PositionMN<=m_EndMN )
        {
         if(!ClosePositionByMN(m_Session, m_PositionMN)) Alert("Position is not Matching");
        }             
     } 

   MNInitByPID(m_Session, m_PositionID); 

   if(!isStopLoss)
     {
      if( (BeforePM[m_Session]==LongReverseCon || BeforePM[m_Session]==LongCounterCon || 
            BeforePM[m_Session]==DLRCon         || BeforePM[m_Session]==DLRCCon ) && 
           PositionSummary[m_Session].pyramidStarted==true )
          InitPyramidData(m_Session);
      
      if( CurPM[m_Session]==End )
       {
         ReOCReset(m_Session);  
         InitPositionSum(m_Session); 
         CurPM[m_Session]=NoMode;
         BeforePM[m_Session]=NoMode;
       } 
     }

   if(isStopLoss && PositionSummary[m_Session].pyramidStarted==true && PositionSummary[m_Session].pyramidTrend==m_StopTrend)
     InitPyramidData(m_Session);
                      
   return;
}

//-----------------------------------------------------------------------------
bool ClosePositionByMN(int m_Session, int m_MagicNumber)
{

   if(!Sym.RefreshRates()) return(false);        

   if(! Pos.SelectByMagic(_Symbol, m_MagicNumber)) Alert("Position Selection Error");

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
   else
     {
      
      if(Trade.Sell(m_LotSize,_Symbol,0,slv,tpv,m_MNstring)) return(true); 
      else 
        {
         Alert("Cannot open a Sell position, nearing the Stop Loss or Take Profit");
         return(false);
        } 
     } 
}    


 //---------------------------------------------------------------------
void RegisterPosition(ENUM_POSITION_TYPE m_PositionType, int m_Session, position_ID m_PositionID, int m_MagicNumber)
{
   double m_OpenSize=Trade.ResultVolume();
   trend m_Trend;
   
   if(m_PositionType==POSITION_TYPE_BUY) m_Trend=UpTrend;
   else if(m_PositionType==POSITION_TYPE_SELL) m_Trend=DownTrend;
   else
     {
      Alert("Position Type Error");
      return;
     }

   if( PositionSummary[m_Session].totalNumPositions == 0) 
      {
         PositionSummary[m_Session].firstPositionTrend = m_Trend;
         PositionSummary[m_Session].startingBar = CurBar;
      }   
   PositionSummary[m_Session].lastPositionTrend = m_Trend;
   PositionSummary[m_Session].totalNumPositions++;
   PositionSummary[m_Session].currentNumPositions++;
   PositionSummary[m_Session].totalSize += m_OpenSize;
   PositionSummary[m_Session].currentSize += m_OpenSize;
   
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].openSequence = PositionSummary[m_Session].totalNumPositions;
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].isOpenNow = true;
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].positionTrend = m_Trend;
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
         PositionInfo[m_Session][i].positionTrend=NoTrend;
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

