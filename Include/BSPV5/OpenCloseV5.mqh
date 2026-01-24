//+------------------------------------------------------------------+
//|                                                  OpenCloseV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV5/ExternVariables.mqh>
//#include <BSPV5/CommonV5.mqh>
//#include <BSPV5/ReadyCheckV5.mqh>
//#include <BSPV5/MagicNumberV5.mqh>


//------------------------------------------------------------------------
position_Mode OpenSignal(int m_Session)
{
   if( CurBar==ReOC[m_Session].MRBar && CurBar!=ReOC[m_Session].LRBar ) return(MiddleReverse);

   else if( CurBar==ReOC[m_Session].MRBar && CurBar==ReOC[m_Session].LRBar )  return(LongReverse);

   else if( CurBar==ReOC[m_Session].LCBar )  return(LongCounter);

   else if( CurBar==ReOC[m_Session].DLRBar)  return(DoubleLongReverse);

   else if( CurBar==ReOC[m_Session].DLRCConBar)  return(DLRCCon);

   else if( CurBar==ReOC[m_Session].RORBar)  return(ReOpenReverse);

   return(NoAction);
}

//------------------------------------------------------------------------
position_Mode CloseSignal(int m_Session)
{
   
   if( CurBar==ReOC[m_Session].DLRBar )  return(DoubleLongReverse);
   
   else if( CurBar==ReOC[m_Session].DLRConBar)  return(DLRCon);

   else if( CurBar==ReOC[m_Session].EndBar) return(End);
   
   else if(CurBar==ReOC[m_Session].NoModeBar) return(NoMode);

   return(NoAction);
}


//-------------------------------------------------------------------------
void MyOpenPosition(int m_Session)
{
   position_ID m_PositionID=No_Signal;
   ENUM_POSITION_TYPE m_PositionType=POSITION_TYPE_BUY;
     
   if(CurPM[m_Session]==MiddleReverse || CurPM[m_Session]==LongReverse)
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
   else if(CurPM[m_Session]==LongCounter)
     {
      if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_BUY) 
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
    else if(CurPM[m_Session]==DLRCCon)
     {
      if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_BUY) 
        {
         m_PositionID=Buy_DLRC;
         m_PositionType=POSITION_TYPE_SELL;
        }
      else 
        {
         m_PositionID=Sell_DLRC;
         m_PositionType=POSITION_TYPE_BUY;
        }     
     }  
     
   if(m_PositionID!=No_Signal)
     {
      if(PositionSummary[m_Session].totalNumPositions<MaxPosition) OpenPositionByPID(m_PositionType, m_Session, m_PositionID);
      else Alert("Oops, Too Many Positions");  
     }    
}


//-----------------------------------------------------------------------
void MyClosePosition(int m_Session)
{
   
   if(CurPM[m_Session]==DoubleLongReverse)
     {
      if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_BUY) 
        {
         ClosePositionByPID(m_Session, Sell_LC);
        }
      else if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_SELL)
        {
         ClosePositionByPID(m_Session, Buy_LC);
        }     
     } 

   else if(CurPM[m_Session]==DLRCCon)
     {
      if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_BUY) 
        {
         ClosePositionByPID(m_Session, Buy_MR);
         ClosePositionByPID(m_Session, Buy_LR);
         ClosePositionByPID(m_Session, Buy_DLR);
        }
      else if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_SELL)
        {
         ClosePositionByPID(m_Session, Sell_MR);
         ClosePositionByPID(m_Session, Sell_LR);
         ClosePositionByPID(m_Session, Sell_DLR);
        }     
     } 

   else if(CurPM[m_Session]==End ||CurPM[m_Session]==NoMode) 
     {
      ClosePositionBySession(m_Session);

      if(CurPM[m_Session]==NoMode)
        {
         MNInitByPID(m_Session, AllPM);
         ReOCReset(m_Session);  
         InitPositionSum(m_Session); 
        } 
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

      int m_PositionMN=int(PositionGetInteger(POSITION_MAGIC));
      string position_symbol=PositionGetSymbol(i);

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
bool OpenPositionByPID(ENUM_POSITION_TYPE m_PositionType, int m_Session, position_ID m_PositionID)
{
   int m_MagicNumber, tempMN;  

   tempMN=NextMNByPID(m_Session, m_PositionID);        
      
   if(tempMN) m_MagicNumber=tempMN;
   else return(false);
      
   if(OpenPosition(m_PositionType, m_Session, m_PositionID, m_MagicNumber)) return(true);
   else return(false);
}

//------------------------------------------------------------------------------------
bool OpenPosition(ENUM_POSITION_TYPE m_PositionType, int m_Session, position_ID m_PositionID, int m_MagicNumber)
{

   if(!Sym.RefreshRates()) return(false);    
   Trade.SetExpertMagicNumber(m_MagicNumber);     
   if(!SolveLots(m_Session, lot)) return(false);
   
   string m_MNstring = string(m_MagicNumber);
   
   if(m_PositionType == POSITION_TYPE_BUY)
   {

      if(!VirtualSLTP)
      {
         slv=SolveBuySL(StopLoss);
         tpv=SolveBuyTP(TakeProfit);
      }
                  
      if(CheckBuySL(slv) && CheckBuyTP(tpv))
      {
        Trade.SetDeviationInPoints(Sym.Spread()*3);
        if(Trade.Buy(lot,_Symbol,0,slv,tpv,m_MNstring))
          {
           RegisterPosition(POSITION_TYPE_BUY, m_Session, m_PositionID, m_MagicNumber);
           return(true);
          }                
        else
          { 
           Alert("Cannot open a Buy position, nearing the Stop Loss or Take Profit");
           return(false);
          }
      }     
   }


   if(m_PositionType == POSITION_TYPE_SELL)
   {
      
      if(!VirtualSLTP)
      {
         slv=SolveSellSL(StopLoss);
         tpv=SolveSellTP(TakeProfit);
      }
   
      if(CheckSellSL(slv) && CheckSellTP(tpv))
      {
         Trade.SetDeviationInPoints(Sym.Spread()*3);
         if(Trade.Sell(lot,_Symbol,0,slv,tpv,m_MNstring)) 
           {
            RegisterPosition(POSITION_TYPE_SELL, m_Session, m_PositionID, m_MagicNumber);
            return(true);   
           }       
         else 
           {
            Alert("Cannot open a Sell position, nearing the Stop Loss or Take Profit");
            return(false);
           } 
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
   PositionInfo[m_Session][(PositionSummary[m_Session].totalNumPositions-1)].openLASM = LASMValue;   
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
         PositionInfo[m_Session][i].isOpenNow=false;
         return(true);
        }    
     }
     
   return(false);
} 

//-------------------------------------------------------------------------+
void InitPositionSum(int m_Session)
{
   for(int i=0;i<PositionSummary[m_Session].totalNumPositions;i++)
     {
      PositionInfo[m_Session][i].openSequence=0;
      PositionInfo[m_Session][i].isOpenNow=false;
      PositionInfo[m_Session][i].positionID=No_Signal;
      PositionInfo[m_Session][i].pMagicNumber=BaseMagicNumber;
      PositionInfo[m_Session][i].openBar=0;
      PositionInfo[m_Session][i].openVolume=0.;
      PositionInfo[m_Session][i].openPrice=0.;
      PositionInfo[m_Session][i].openWmaS=0.;
      PositionInfo[m_Session][i].openLASM=0.;     
     }

   PositionSummary[m_Session].totalNumPositions=0;
   PositionSummary[m_Session].currentNumPositions=0;
   PositionSummary[m_Session].totalSize=0.;
   PositionSummary[m_Session].currentSize=0.;
} 




/*
//-------------------------------------------------------------------------
void MyOpenPosition(int m_Session, position_Mode m_PositionMode)
{
   position_ID m_PositionID;
     
   if( m_PositionMode==MiddleReverse || m_PositionMode==LongReverse)
     {
      if(BuyOpenReady.TrendReady)
        {
         if(CurPM[m_Session].==MiddleReverse) m_PositionID=Buy_MR;
         else                                 m_PositionID=Buy_LR;
         
         OpenPositionByPIDE(POSITION_TYPE_BUY, m_Session, m_PositionID);
        } 
      else if(SellOpenReady.TrendReady) 
        {
         if(CurPM[m_Session]==MiddleReverse) m_PositionID=Sell_MR;
         else                                m_PositionID=Sell_LR;
         
         OpenPositionByPIDE(POSITION_TYPE_SELL, m_Session, m_PositionID);       
        }
     }

   if(m_PositionMode==LongCounter)
     {
      if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_BUY) 
        {
         m_PositionID=Sell_LC;
         OpenPositionByPIDE(POSITION_TYPE_SELL, m_Session, m_PositionID);       
        }
      else 
        {
         m_PositionID=Buy_LC;
         OpenPositionByPIDE(POSITION_TYPE_BUY, m_Session, m_PositionID);      
        }     
     }

   if(m_PositionMode==DoubleLongReverse)
     {
      if(PositionSummary[m_Session].firstPositionType==POSITION_TYPE_BUY) 
        {
         m_PositionID=Buy_DLR;
         OpenPositionByPIDE(POSITION_TYPE_BUY, m_Session, m_PositionID);       
        }
      else 
        {
         m_PositionID=Sell_DLR;
         OpenPositionByPIDE(POSITION_TYPE_SELL, m_Session, m_PositionID);      
        }     
     }
}

//-----------------------------------------------------------------------
void MyClosePosition(position_Mode m_PositionMode)
{
   if(m_PositionMode==DoubleLongReverse)
     {
      if(PositionSummary.firstPositionType==POSITION_TYPE_BUY) 
        {
         ClosePositionByPIDE(Sell_LC);
         ClosePositionByPIDE(Sell_LCP);
        }
      else if(PositionSummary.firstPositionType==POSITION_TYPE_SELL)
        {
         ClosePositionByPIDE(Buy_LC);
         ClosePositionByPIDE(Buy_LCP);
        }     
     } 

   if(m_PositionMode==End ) 
     {
      CloseAllPosition();
      InitPositionSum();       
      OpenReadyReset(); 
      PositionModeSet(NoMode);      
    
     } 
}

//---------------------------------------------------------------------------------------
bool OpenPositionByPIDE(ENUM_POSITION_TYPE m_PositionType, int m_Session, position_ID m_PositionID)
{
   int m_MagicNumber, tempMN;  

   tempMN=NextMNByPID(m_Session, m_PositionID);        
      
   if(tempMN) m_MagicNumber=tempMN;
   else return(false);
      
   if(OpenPosition(m_PositionType, m_Session, m_PositionID, m_MagicNumber)) return(true);
   else return(false);
}

//------------------------------------------------------------------------------------
bool OpenPosition(ENUM_POSITION_TYPE m_PositionType, int m_Session, position_ID m_PositionID, int m_MagicNumber)
{

   if(!Sym.RefreshRates()) return(false);    
   Trade.SetExpertMagicNumber(m_MagicNumber);     
   if(!SolveLots(lot)) return(false);
   
   string m_MNstring = string(m_MagicNumber);
   
   if(m_PositionType == POSITION_TYPE_BUY)
   {

      if(!VirtualSLTP)
      {
         slv=SolveBuySL(StopLoss);
         tpv=SolveBuyTP(TakeProfit);
      }
                  
      if(CheckBuySL(slv) && CheckBuyTP(tpv))
      {
        Trade.SetDeviationInPoints(Sym.Spread()*3);
        if(Trade.Buy(lot,_Symbol,0,slv,tpv,m_MNstring))
          {
           RegisterPosition(POSITION_TYPE_BUY, m_Session, m_PositionID, m_MagicNumber);
           return(true);
          }                
        else
          { 
           Alert("Cannot open a Buy position, nearing the Stop Loss or Take Profit");
           return(false);
          }
      }     
   }


   if(m_PositionType == POSITION_TYPE_SELL)
   {
      
      if(!VirtualSLTP)
      {
         slv=SolveSellSL(StopLoss);
         tpv=SolveSellTP(TakeProfit);
      }
   
      if(CheckSellSL(slv) && CheckSellTP(tpv))
      {
         Trade.SetDeviationInPoints(Sym.Spread()*3);
         if(Trade.Sell(lot,_Symbol,0,slv,tpv,m_MNstring)) 
           {
            RegisterPosition(POSITION_TYPE_SELL, m_Session, m_PositionID, m_MagicNumber);
            return(true);   
           }       
         else 
           {
            Alert("Cannot open a Sell position, nearing the Stop Loss or Take Profit");
            return(false);
           } 
      }       
   } 

   return(true);        
}    

//-------------------------------------------------------------------------+
void CloseAllPosition()
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

      if(position_symbol==_Symbol && BaseMagicNumber==PositionBMN(m_PositionMN) )
        {
         if(!ClosePositionByMN(m_PositionMN) )
           {
            Alert("Position is not Matching");
            return;
           }                 
        }      
    } 
    MNInitByPIDE(AllPM);
}

//------------------------------------------------------------------
void ClosePositionByPIDE(position_ID m_PositionID)
{
   int m_StartingMN=BaseMagicNumberF(m_PositionID);
   int m_EndMN=CurrMagicNumberF(m_PositionID);
    
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

      int m_PositionMN=int(PositionGetInteger(POSITION_MAGIC));
      string position_symbol=PositionGetSymbol(i);

      if(position_symbol==_Symbol && BaseMagicNumber==PositionBMN(m_PositionMN) && m_PositionMN>m_StartingMN &&  
         m_PositionMN<=m_EndMN )
        {
         if(!ClosePositionByMN(m_PositionMN)) 
           {
            Alert("Position is not Matching");
            return;
           }                 
        }             
     }   
   MNInitByPIDE(m_PositionID);      
      
}


//-----------------------------------------------------------------------------
bool ClosePositionByMN(int m_MagicNumber)
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
       DeRegisterPosition(m_MagicNumber);
       return(true);
      } 
    else{ 
         Alert("Position Close Error"); 
         return(false);
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
   
   
   ArrayResize(PositionInfo, PositionSummary[m_Session].totalNumPositions, 400 );
   PositionInfo[(PositionSummary[m_Session].totalNumPositions-1)].openSequence = PositionSummary.totalNumPositions;
   PositionInfo[(PositionSummary[m_Session].totalNumPositions-1)].isOpenNow = true;
   PositionInfo[(PositionSummary[m_Session].totalNumPositions-1)].positionType = m_PositionType;
   PositionInfo[(PositionSummary[m_Session].totalNumPositions-1)].positionID = m_PositionID;
   PositionInfo[(PositionSummary[m_Session].totalNumPositions-1)].pMagicNumber = m_MagicNumber;
   PositionInfo[(PositionSummary[m_Session].totalNumPositions-1)].openBar = CurBar;
   PositionInfo[(PositionSummary[m_Session].totalNumPositions-1)].openVolume = Trade.ResultVolume();
   PositionInfo[(PositionSummary[m_Session].totalNumPositions-1)].openPrice = Trade.ResultPrice();
   PositionInfo[(PositionSummary[m_Session].totalNumPositions-1)].openWmaS = WmaSValue;
   PositionInfo[(PositionSummary[m_Session].totalNumPositions-1)].openLASM = LASMValue;
   
}

//---------------------------------------------------------------------
bool DeRegisterPosition(int m_MagicNumber)
{
   for(int i=0;i<PositionSummary.totalNumPositions;i++)
     {
      if(PositionInfo[i].pMagicNumber==m_MagicNumber)
        {
         PositionSummary.currentSize-=PositionInfo[i].openVolume;
         PositionSummary.currentNumPositions--;
         PositionInfo[i].isOpenNow=false;
         return(true);
        }    
     }
     
     return(false);
}  


//-------------------------------------------------------------------------+
void InitPositionSum()
{
   PositionSummary.totalNumPositions=0;
   PositionSummary.currentNumPositions=0;
   PositionSummary.totalSize=0.;
   PositionSummary.currentSize=0.;
   
   ArrayFree(PositionInfo);   
}         

*/