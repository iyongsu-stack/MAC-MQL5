//+------------------------------------------------------------------+
//|                                                  OpenCloseV3.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"


//#include <BSPV4/ExternVariables.mqh>
//#include <BSPV4/CommonV3.mqh>
//#include <BSPV4/ReadyCheckV3.mqh>
//#include <BSPV4/MagicNumberV3.mqh>


//------------------------------------------------------------------------
position_Mode OpenSignal()
{
   if( (PositionSummary.totalNumPositions==0) && 
       (SellOpenReady.TrendReady || BuyOpenReady.TrendReady) ) 
     {
      if(CurPM==MiddleReverse) return(MiddleReverse);
      else if(CurPM==LongReverse) return(LongReverse);
     }

   if( CurBar==ReOC.LCBar )
     {
      return(LongCounter);
     } 
   if( CurBar==ReOC.DLRBar)
     {
      return(DoubleLongReverse);
     } 

   return(NoMode);
}

//------------------------------------------------------------------------
position_Mode CloseSignal()
{
   
   if( CurBar==ReOC.DLRBar ) 
     {
      return(DoubleLongReverse);
     } 
   if( CurBar==ReOC.LCBar ) 
     {
      return(LongCounter);
     } 
   if( CurBar==ReOC.EndBar) 
     {
      return(End);
     } 

   return(NoMode);
}
//-------------------------------------------------------------------------
void MyOpenPosition(position_Mode m_PositionMode)
{
   position_IDE m_PositionIDE;
     
   if( m_PositionMode==MiddleReverse || m_PositionMode==LongReverse)
     {
      if(BuyOpenReady.TrendReady)
        {
         if(CurPM==MiddleReverse) m_PositionIDE=Buy_MR;
         else                     m_PositionIDE=Buy_LR;
         
         OpenPositionByPIDE(POSITION_TYPE_BUY, m_PositionIDE);
        } 
      else if(SellOpenReady.TrendReady) 
        {
         if(CurPM==MiddleReverse) m_PositionIDE=Sell_MR;
         else                     m_PositionIDE=Sell_LR;
         
         OpenPositionByPIDE(POSITION_TYPE_SELL, m_PositionIDE);       
        }
     }

   if(m_PositionMode==LongCounter)
     {
      if(PositionSummary.firstPositionType==POSITION_TYPE_BUY) 
        {
         m_PositionIDE=Sell_LC;
         OpenPositionByPIDE(POSITION_TYPE_SELL, m_PositionIDE);       
        }
      else 
        {
         m_PositionIDE=Buy_LC;
         OpenPositionByPIDE(POSITION_TYPE_BUY, m_PositionIDE);      
        }     
     }

   if(m_PositionMode==DoubleLongReverse)
     {
      if(PositionSummary.firstPositionType==POSITION_TYPE_BUY) 
        {
         m_PositionIDE=Buy_DLR;
         OpenPositionByPIDE(POSITION_TYPE_BUY, m_PositionIDE);       
        }
      else 
        {
         m_PositionIDE=Sell_DLR;
         OpenPositionByPIDE(POSITION_TYPE_SELL, m_PositionIDE);      
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

//--------------------------------------------------------------------------------------
bool OpenPositionByPIDE(ENUM_POSITION_TYPE m_PositionType, position_IDE m_PositionIDE)
{
   int m_MagicNumber, tempMN;  

   tempMN=NextMagicNumberF(m_PositionIDE);        
      
   if(tempMN) m_MagicNumber=tempMN;
   else return(false);
      
   if(OpenPosition(m_PositionType, m_PositionIDE, m_MagicNumber)) return(true);
   else return(false);
}

//------------------------------------------------------------------------------------
bool OpenPosition(ENUM_POSITION_TYPE m_PositionType, position_IDE m_PositionIDE, int m_MagicNumber)
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
           RegisterPosition(POSITION_TYPE_BUY, m_PositionIDE, m_MagicNumber);
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
            RegisterPosition(POSITION_TYPE_SELL, m_PositionIDE, m_MagicNumber);
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
void ClosePositionByPIDE(position_IDE m_PositionIDE)
{
   int m_StartingMN=BaseMagicNumberF(m_PositionIDE);
   int m_EndMN=CurrMagicNumberF(m_PositionIDE);
    
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
   MNInitByPIDE(m_PositionIDE);      
      
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
void RegisterPosition(ENUM_POSITION_TYPE m_PositionType, position_IDE m_PositionIDE, int m_MagicNumber)
{
   double m_OpenSize=Trade.ResultVolume();

   if( PositionSummary.totalNumPositions == 0) 
      {
         PositionSummary.firstPositionType = m_PositionType;
         PositionSummary.startingBar = CurBar;
      }   
   PositionSummary.lastPositionType = m_PositionType;
   PositionSummary.totalNumPositions++;
   PositionSummary.currentNumPositions++;
   PositionSummary.totalSize += m_OpenSize;
   PositionSummary.currentSize += m_OpenSize;
   
   
   ArrayResize(PositionInfo, PositionSummary.totalNumPositions, 100 );
   PositionInfo[(PositionSummary.totalNumPositions-1)].openSequence = PositionSummary.totalNumPositions;
   PositionInfo[(PositionSummary.totalNumPositions-1)].isOpenNow = true;
   PositionInfo[(PositionSummary.totalNumPositions-1)].positionType = m_PositionType;
   PositionInfo[(PositionSummary.totalNumPositions-1)].positionIDE = m_PositionIDE;
   PositionInfo[(PositionSummary.totalNumPositions-1)].pMagicNumber = m_MagicNumber;
   PositionInfo[(PositionSummary.totalNumPositions-1)].openBar = CurBar;
   PositionInfo[(PositionSummary.totalNumPositions-1)].openVolume = Trade.ResultVolume();
   PositionInfo[(PositionSummary.totalNumPositions-1)].openPrice = Trade.ResultPrice();
   PositionInfo[(PositionSummary.totalNumPositions-1)].openWmaS = WmaSValue;
   PositionInfo[(PositionSummary.totalNumPositions-1)].openLASM = LASMValue;
   
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