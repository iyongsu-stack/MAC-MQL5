//+------------------------------------------------------------------+
//|                                                MagicNumberV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV7/ExternVariables.mqh>

//--------------------------------------------------------------------------------
bool MagicNumberInit()
{
   if((BaseMagicNumber%100000!=0) || ( MathFloor(BaseMagicNumber/100000) <= 0.))
   {
      Alert("Base MagicNumber should be larger than 100,000, and unit of 100,000" );
      return(false);
   }

   for(int m_Session=0;m_Session<TotalSession;m_Session++)
   {          
      BasePositionMN[m_Session].Buy_MR      =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 0;    
      CurrPositionMN[m_Session].Buy_MR      =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 0;
      BasePositionMN[m_Session].Sell_MR     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 1;    
      CurrPositionMN[m_Session].Sell_MR     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 1;
      BasePositionMN[m_Session].Buy_LR      =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 2;    
      CurrPositionMN[m_Session].Buy_LR      =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 2;
      BasePositionMN[m_Session].Sell_LR     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 3;    
      CurrPositionMN[m_Session].Sell_LR     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 3;
      BasePositionMN[m_Session].Buy_LC      =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 4;    
      CurrPositionMN[m_Session].Buy_LC      =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 4;
      BasePositionMN[m_Session].Sell_LC     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 5;    
      CurrPositionMN[m_Session].Sell_LC     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 5;
      BasePositionMN[m_Session].Buy_DLR     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 6;    
      CurrPositionMN[m_Session].Buy_DLR     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 6;
      BasePositionMN[m_Session].Sell_DLR    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 7;    
      CurrPositionMN[m_Session].Sell_DLR    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 7;
      BasePositionMN[m_Session].Buy_DLRCC   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 8;    
      CurrPositionMN[m_Session].Buy_DLRCC   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 8;
      BasePositionMN[m_Session].Sell_DLRCC  =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 9;    
      CurrPositionMN[m_Session].Sell_DLRCC  =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 9;
   }
   
   return(true);
}

//------------------------------------------------------------------------------
int BaseMNByPID(int m_Session, position_ID m_PositionID)
{
   int m_MagicNumber=0;
   
   switch(m_PositionID)
   {
      case(Buy_MR):
         m_MagicNumber=BasePositionMN[m_Session].Buy_MR; break;
      case(Sell_MR):
         m_MagicNumber=BasePositionMN[m_Session].Sell_MR; break;
      case(Buy_LR):
         m_MagicNumber=BasePositionMN[m_Session].Buy_LR; break;
      case(Sell_LR):
         m_MagicNumber=BasePositionMN[m_Session].Sell_LR; break;
      case(Buy_LC):
         m_MagicNumber=BasePositionMN[m_Session].Buy_LC; break;
      case(Sell_LC):
         m_MagicNumber=BasePositionMN[m_Session].Sell_LC; break;
      case(Buy_DLR):
         m_MagicNumber=BasePositionMN[m_Session].Buy_DLR; break;
      case(Sell_DLR):
         m_MagicNumber=BasePositionMN[m_Session].Sell_DLR; break;
      case(Buy_DLRCC):
         m_MagicNumber=BasePositionMN[m_Session].Buy_DLRCC; break;
      case(Sell_DLRCC):
         m_MagicNumber=BasePositionMN[m_Session].Sell_DLRCC; break;
    }
    
    return(m_MagicNumber);  
}

//------------------------------------------------------------------------------
int CurrMNByPID(int m_Session, position_ID m_PositionID)
{
   int m_MagicNumber=0;
   
   switch(m_PositionID)
   {
      case(Buy_MR):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_MR; break;
      case(Sell_MR):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_MR; break;
      case(Buy_LR):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_LR; break;
      case(Sell_LR):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_LR; break;
      case(Buy_LC):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_LC; break;
      case(Sell_LC):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_LC; break;
      case(Buy_DLR):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_DLR; break;
      case(Sell_DLR):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_DLR; break;
      case(Buy_DLRCC):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_DLRCC; break;
      case(Sell_DLRCC):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_DLRCC; break;
   }
   
   return(m_MagicNumber);  
}


//------------------------------------------------------------
int NextMNByPID(int m_Session, position_ID m_PositionID)
{
   int m_NextMagicNumber=0;
   
   switch(m_PositionID)
     {
      case Buy_MR:
            CurrPositionMN[m_Session].Buy_MR++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_MR; 
            if((CurrPositionMN[m_Session].Buy_MR-BasePositionMN[m_Session].Buy_MR) >= MN_IncNumber)
            {
                CurrPositionMN[m_Session].Buy_MR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
            }
            break;               
      case Sell_MR:
            CurrPositionMN[m_Session].Sell_MR++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_MR; 
            if((CurrPositionMN[m_Session].Sell_MR-BasePositionMN[m_Session].Sell_MR) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_MR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                    
            break;
      case Buy_LR:
            CurrPositionMN[m_Session].Buy_LR++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_LR; 
            if((CurrPositionMN[m_Session].Buy_LR-BasePositionMN[m_Session].Buy_LR) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_LR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                     
            break;
      case Sell_LR:
            CurrPositionMN[m_Session].Sell_LR++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_LR; 
            if((CurrPositionMN[m_Session].Sell_LR-BasePositionMN[m_Session].Sell_LR) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_LR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;
      case Buy_LC:
            CurrPositionMN[m_Session].Buy_LC++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_LC; 
            if((CurrPositionMN[m_Session].Buy_LC-BasePositionMN[m_Session].Buy_LC) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_LC--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                 
      case Sell_LC: 
            CurrPositionMN[m_Session].Sell_LC++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_LC; 
            if((CurrPositionMN[m_Session].Sell_LC-BasePositionMN[m_Session].Sell_LC) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_LC--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                       
    case Buy_DLR: 
            CurrPositionMN[m_Session].Buy_DLR++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_DLR; 
            if((CurrPositionMN[m_Session].Buy_DLR-BasePositionMN[m_Session].Buy_DLR) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_DLR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                           
      case Sell_DLR: 
            CurrPositionMN[m_Session].Sell_DLR++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_DLR; 
            if((CurrPositionMN[m_Session].Sell_DLR-BasePositionMN[m_Session].Sell_DLR) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_DLR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                               

      case Buy_DLRCC: 
            CurrPositionMN[m_Session].Buy_DLRCC++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_DLRCC; 
            if((CurrPositionMN[m_Session].Buy_DLRCC-BasePositionMN[m_Session].Buy_DLRCC) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_DLRCC--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                           
      case Sell_DLRCC: 
            CurrPositionMN[m_Session].Sell_DLRCC++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_DLRCC; 
            if((CurrPositionMN[m_Session].Sell_DLRCC-BasePositionMN[m_Session].Sell_DLRCC) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_DLRCC--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                               
     }
   return(m_NextMagicNumber);    
}


//---------------------------------------------------------
void MNInitByPID(int m_Session, position_ID m_PositionID)
{

   switch(m_PositionID)
     {
      case(Buy_MR):
         CurrPositionMN[m_Session].Buy_MR=BasePositionMN[m_Session].Buy_MR; break;
      case(Sell_MR):
         CurrPositionMN[m_Session].Sell_MR=BasePositionMN[m_Session].Sell_MR; break;
      case(Buy_LR):
         CurrPositionMN[m_Session].Buy_LR=BasePositionMN[m_Session].Buy_LR; break;
      case(Sell_LR):
         CurrPositionMN[m_Session].Sell_LR=BasePositionMN[m_Session].Sell_LR; break;
      case(Buy_LC):
         CurrPositionMN[m_Session].Buy_LC=BasePositionMN[m_Session].Buy_LC; break;
      case(Sell_LC):
         CurrPositionMN[m_Session].Sell_LC=BasePositionMN[m_Session].Sell_LC; break;
      case(Buy_DLR):
         CurrPositionMN[m_Session].Buy_DLR=BasePositionMN[m_Session].Buy_DLR; break;
      case(Sell_DLR):
         CurrPositionMN[m_Session].Sell_DLR=BasePositionMN[m_Session].Sell_DLR; break;
      case(Buy_DLRCC):
         CurrPositionMN[m_Session].Buy_DLRCC=BasePositionMN[m_Session].Buy_DLRCC; break;
      case(Sell_DLRCC):
         CurrPositionMN[m_Session].Sell_DLRCC=BasePositionMN[m_Session].Sell_DLRCC; break;
     }
     
   if(m_PositionID==AllID)
     {
      CurrPositionMN[m_Session].Buy_MR=BasePositionMN[m_Session].Buy_MR; 
      CurrPositionMN[m_Session].Sell_MR=BasePositionMN[m_Session].Sell_MR; 
      CurrPositionMN[m_Session].Buy_LR=BasePositionMN[m_Session].Buy_LR; 
      CurrPositionMN[m_Session].Sell_LR=BasePositionMN[m_Session].Sell_LR;
      CurrPositionMN[m_Session].Buy_LC=BasePositionMN[m_Session].Buy_LC;
      CurrPositionMN[m_Session].Sell_LC=BasePositionMN[m_Session].Sell_LC;
      CurrPositionMN[m_Session].Buy_DLR=BasePositionMN[m_Session].Buy_DLR; 
      CurrPositionMN[m_Session].Sell_DLR=BasePositionMN[m_Session].Sell_DLR;
      CurrPositionMN[m_Session].Buy_DLRCC=BasePositionMN[m_Session].Buy_DLRCC; 
      CurrPositionMN[m_Session].Sell_DLRCC=BasePositionMN[m_Session].Sell_DLRCC;
     }     
}


//----------------------------------------------------------------------------------------------
int PositionBMN(int m_PositionMN)
{
   int m_BaseMagicNumber;
   
   m_BaseMagicNumber=int(MathFloor(m_PositionMN/100000)*100000);
   return(m_BaseMagicNumber);
}


//-----------------------------------------------------------------------------------------------
int SessionByMN(int m_MagicNumber)
{   
   int m_Session=int(MathFloor((m_MagicNumber-BaseMagicNumber)/SessionIncNumber));
   return(m_Session);
}
