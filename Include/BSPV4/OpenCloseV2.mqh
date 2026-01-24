//+------------------------------------------------------------------+
//|                                                  OpenCloseV2.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"


//#include <BSPV4/ExternVariables.mqh>
//#include <BSPV4/Common.mqh>
//#include <BSPV4/ReadyCheckV2.mqh>



//+---------------------------------------------------------------------+
bool SignalOpenSell()
  {
   if( SellOpenReady.TrendReady ) return(true);
   else return(false);  
  }

  
//+--------------------------------------------------------------------+ 
bool SignalOpenBuy()
  {
   if( BuyOpenReady.TrendReady ) return(true);         
   else return(false);   
  }


//+----------------------------------------------------------------------+
bool SignalCloseSell()
  {
   if( SellCloseReady.TrendReady ) return(true);
   else return(false);
  }
  
//+----------------------------------------------------------------------+
bool SignalCloseBuy()
  {
   if( BuyCloseReady.TrendReady ) return(true);
   else return(false);   
  }



//+--------------------------------------------------------------------+ 
bool SignalCounterOpenBuy()
{
   if( BuyCOReady.TrendReady ) return(true);         
   else return(false);   
}

//+---------------------------------------------------------------------+
bool SignalCounterOpenSell()
{
   if( SellCOReady.TrendReady ) return(true);
   else return(false);  
}






//-------------------------------------------------------------------------+
//-------------------------------------------------------------------------+
void MyBuyOpen(Open_Mode M_OpenMode)
{
   string mString = EnumToString(M_OpenMode);
   if( OpenPosition(POSITION_TYPE_BUY, mString) )  
     {
      RegisterPosition(POSITION_TYPE_BUY, M_OpenMode);
     } 
     
//   if( M_OpenMode == ModeCounter ) BuyCOReadyReset(); 
    
}

//--------------------------------------------------------------------------+
void MySellOpen(Open_Mode M_OpenMode)
{   
   string mString = EnumToString(M_OpenMode);
   if( OpenPosition(POSITION_TYPE_SELL, mString) ) 
     { 
      RegisterPosition(POSITION_TYPE_SELL, M_OpenMode);
     }    

//   if( M_OpenMode == ModeCounter ) SellCOReadyReset(); 
   
}


//------------------------------------------------------------------------+
void MyBuyClose(void)
{   
   CloseAllPosition(); 
   InitPositionSum();
   
   if(PositionSummary.totalNumPositions == 0)
     { 
      CloseReadyReset();
     }              
}


//-------------------------------------------------------------------------+
void MySellClose(void)
{   
   CloseAllPosition(); 
   InitPositionSum();
   if(PositionSummary.totalNumPositions == 0)
     { 
      CloseReadyReset();
     } 
}

//-------------------------------------------------------------------------+
void InitPositionSum()
{
   PositionSummary.totalNumPositions=0;
   PositionSummary.currentNumPositions=0;
   PositionSummary.totalSize = 0.;
   
   ArrayFree(PositionInfo);   
}

//---------------------------------------------------------------------
void RegisterPosition(ENUM_POSITION_TYPE m_PositionType, Open_Mode M2_OpenMode)
{
   if( PositionSummary.totalNumPositions == 0) 
      {
         PositionSummary.firstPositionType = m_PositionType;
         PositionSummary.OpenMode = M2_OpenMode;
      }   
   PositionSummary.lastPositionType = m_PositionType;
   PositionSummary.totalNumPositions++;
   PositionSummary.currentNumPositions++;
   PositionSummary.totalSize += Trade.ResultVolume();
   
   ArrayResize(PositionInfo, PositionSummary.totalNumPositions, 100 );
   PositionInfo[(PositionSummary.totalNumPositions-1)].openSequence = PositionSummary.totalNumPositions;
   PositionInfo[(PositionSummary.totalNumPositions-1)].isOpenNow = true;
   PositionInfo[(PositionSummary.totalNumPositions-1)].positionType = m_PositionType;
   PositionInfo[(PositionSummary.totalNumPositions-1)].positionTicket = Trade.ResultOrder();
   PositionInfo[(PositionSummary.totalNumPositions-1)].openBar = CurBar;
   PositionInfo[(PositionSummary.totalNumPositions-1)].openVolume = Trade.ResultVolume();
   PositionInfo[(PositionSummary.totalNumPositions-1)].openPrice = Trade.ResultPrice();
   PositionInfo[(PositionSummary.totalNumPositions-1)].openWmaS = WmaSValue;
   PositionInfo[(PositionSummary.totalNumPositions-1)].openLASM = LASMValue;
   
}


//------------------------------------------------------------------------------------
bool OpenPosition(ENUM_POSITION_TYPE m_PositionType, string m_String)
{

   if(!Sym.RefreshRates())return(false);        

   if(!SolveLots(lot))return(false);
   
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
        if(Trade.Buy(lot,_Symbol,0,slv,tpv, m_String)) return(true);               
        else
          { 
           Print("Cannot open a Buy position, nearing the Stop Loss or Take Profit");
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
         if(Trade.Sell(lot,_Symbol,0,slv,tpv, m_String)) return(true);         
         else 
           {
            Print("Cannot open a Sell position, nearing the Stop Loss or Take Profit");
            return(false);
           } 
      }       
   } 

   return(false);        
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

      string position_symbol=PositionGetSymbol(i);

      if(position_symbol==_Symbol && iMagicNumber==PositionGetInteger(POSITION_MAGIC) )
        {
         Trade.SetDeviationInPoints(Sym.Spread()*3);
         Trade.PositionClose(PositionGetInteger(POSITION_TICKET));                 
        }      
      else 
       {
        Alert("Position is not Matching");
        return;
       }     

    }     
      
}


void CloseOnePosition(ulong m_Ticket)
{

   if(!Sym.RefreshRates())return;        

   if(! Pos.SelectByTicket(m_Ticket))
     {
      Alert("Position Selection Error");
      return;
     }

   string position_symbol=PositionGetString(POSITION_SYMBOL);
     
   if( (position_symbol ==_Symbol) && (iMagicNumber==PositionGetInteger(POSITION_MAGIC))  )
     {
      Trade.SetDeviationInPoints(Sym.Spread()*3);
      Trade.PositionClose(m_Ticket);                  
     }
   else 
     {
      Alert("Position is not Matching");
      return;
     }     
      
}
        