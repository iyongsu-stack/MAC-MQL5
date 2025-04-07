//+------------------------------------------------------------------+
//|                                                MagicNumberV5.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV5/ExternVariables.mqh>

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
      BasePositionMN[m_Session].Buy_LRP     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 4;    
      CurrPositionMN[m_Session].Buy_LRP     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 4;
      BasePositionMN[m_Session].Sell_LRP    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 5;    
      CurrPositionMN[m_Session].Sell_LRP    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 5;
      BasePositionMN[m_Session].Buy_LC      =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 6;    
      CurrPositionMN[m_Session].Buy_LC      =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 6;
      BasePositionMN[m_Session].Sell_LC     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 7;    
      CurrPositionMN[m_Session].Sell_LC     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 7;
      BasePositionMN[m_Session].Buy_LCP     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 8;    
      CurrPositionMN[m_Session].Buy_LCP     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 8;
      BasePositionMN[m_Session].Sell_LCP    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 9;    
      CurrPositionMN[m_Session].Sell_LCP    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber* 9;
      BasePositionMN[m_Session].Buy_DLR     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*10;    
      CurrPositionMN[m_Session].Buy_DLR     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*10;
      BasePositionMN[m_Session].Sell_DLR    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*11;    
      CurrPositionMN[m_Session].Sell_DLR    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*11;
      BasePositionMN[m_Session].Buy_DLRC    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*12;    
      CurrPositionMN[m_Session].Buy_DLRC    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*12;
      BasePositionMN[m_Session].Sell_DLRC   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*13;    
      CurrPositionMN[m_Session].Sell_DLRC   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*13;
      BasePositionMN[m_Session].Buy_DLRCP   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*14;    
      CurrPositionMN[m_Session].Buy_DLRCP   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*14;
      BasePositionMN[m_Session].Sell_DLRCP  =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*15;    
      CurrPositionMN[m_Session].Sell_DLRCP  =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*15;
      BasePositionMN[m_Session].Buy_DLRCC   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*16;    
      CurrPositionMN[m_Session].Buy_DLRCC   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*16;
      BasePositionMN[m_Session].Sell_DLRCC  =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*17;    
      CurrPositionMN[m_Session].Sell_DLRCC  =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*17;
      BasePositionMN[m_Session].Buy_DLRCCP  =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*18;    
      CurrPositionMN[m_Session].Buy_DLRCCP  =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*18;
      BasePositionMN[m_Session].Sell_DLRCCP =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*19;    
      CurrPositionMN[m_Session].Sell_DLRCCP =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*19;
      BasePositionMN[m_Session].Buy_ROR     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*20;    
      CurrPositionMN[m_Session].Buy_ROR     =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*20;
      BasePositionMN[m_Session].Sell_ROR    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*21;    
      CurrPositionMN[m_Session].Sell_ROR    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*21;
      BasePositionMN[m_Session].Buy_RORC    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*22;    
      CurrPositionMN[m_Session].Buy_RORC    =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*22;
      BasePositionMN[m_Session].Sell_RORC   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*23;    
      CurrPositionMN[m_Session].Sell_RORC   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*23;    
      BasePositionMN[m_Session].Buy_RORCP   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*24;    
      CurrPositionMN[m_Session].Buy_RORCP   =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*24;
      BasePositionMN[m_Session].Sell_RORCP  =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*25;    
      CurrPositionMN[m_Session].Sell_RORCP  =  BaseMagicNumber + SessionIncNumber*m_Session + MN_IncNumber*25;    




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
      case(Buy_LRP):
         m_MagicNumber=BasePositionMN[m_Session].Buy_LRP; break;
      case(Sell_LRP):
         m_MagicNumber=BasePositionMN[m_Session].Sell_LRP; break;
      case(Buy_LC):
         m_MagicNumber=BasePositionMN[m_Session].Buy_LC; break;
      case(Sell_LC):
         m_MagicNumber=BasePositionMN[m_Session].Sell_LC; break;
      case(Buy_LCP):
         m_MagicNumber=BasePositionMN[m_Session].Buy_LCP; break;
      case(Sell_LCP):
         m_MagicNumber=BasePositionMN[m_Session].Sell_LCP; break;
      case(Buy_DLR):
         m_MagicNumber=BasePositionMN[m_Session].Buy_DLR; break;
      case(Sell_DLR):
         m_MagicNumber=BasePositionMN[m_Session].Sell_DLR; break;
      case(Buy_DLRC):
         m_MagicNumber=BasePositionMN[m_Session].Buy_DLRC; break;
      case(Sell_DLRC):
         m_MagicNumber=BasePositionMN[m_Session].Sell_DLRC; break;
      case(Buy_DLRCP):
         m_MagicNumber=BasePositionMN[m_Session].Buy_DLRCP; break;
      case(Sell_DLRCP):
         m_MagicNumber=BasePositionMN[m_Session].Sell_DLRCP; break;
      case(Buy_DLRCC):
         m_MagicNumber=BasePositionMN[m_Session].Buy_DLRCC; break;
      case(Sell_DLRCC):
         m_MagicNumber=BasePositionMN[m_Session].Sell_DLRCC; break;
      case(Buy_DLRCCP):
         m_MagicNumber=BasePositionMN[m_Session].Buy_DLRCCP; break;
      case(Sell_DLRCCP):
         m_MagicNumber=BasePositionMN[m_Session].Sell_DLRCCP; break;
      case(Buy_ROR):
         m_MagicNumber=BasePositionMN[m_Session].Buy_ROR; break;
      case(Sell_ROR):
         m_MagicNumber=BasePositionMN[m_Session].Sell_ROR; break;
      case(Buy_RORC):
         m_MagicNumber=BasePositionMN[m_Session].Buy_RORC; break;
      case(Sell_RORC):
         m_MagicNumber=BasePositionMN[m_Session].Sell_RORC;break;     
      case(Buy_RORCP):
         m_MagicNumber=BasePositionMN[m_Session].Buy_RORCP; break;
      case(Sell_RORCP):
         m_MagicNumber=BasePositionMN[m_Session].Sell_RORCP;break;     

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
      case(Buy_LRP):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_LRP; break;
      case(Sell_LRP):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_LRP; break;
      case(Buy_LC):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_LC; break;
      case(Sell_LC):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_LC; break;
      case(Buy_LCP):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_LCP; break;
      case(Sell_LCP):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_LCP; break;
      case(Buy_DLR):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_DLR; break;
      case(Sell_DLR):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_DLR; break;
      case(Buy_DLRC):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_DLRC; break;
      case(Sell_DLRC):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_DLRC; break;
      case(Buy_DLRCP):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_DLRCP; break;
      case(Sell_DLRCP):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_DLRCP; break;
      case(Buy_DLRCC):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_DLRCC; break;
      case(Sell_DLRCC):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_DLRCC; break;
      case(Buy_DLRCCP):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_DLRCCP; break;
      case(Sell_DLRCCP):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_DLRCCP; break;
      case(Buy_ROR):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_ROR; break;
      case(Sell_ROR):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_ROR; break;
      case(Buy_RORC):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_ROR; break;
      case(Sell_RORC):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_ROR; break;
      case(Buy_RORCP):
         m_MagicNumber=CurrPositionMN[m_Session].Buy_RORCP; break;
      case(Sell_RORCP):
         m_MagicNumber=CurrPositionMN[m_Session].Sell_RORCP;break;     
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
      case Buy_LRP: 
            CurrPositionMN[m_Session].Buy_LRP++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_LRP; 
            if((CurrPositionMN[m_Session].Buy_LRP-BasePositionMN[m_Session].Buy_LRP) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_LRP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;            
      case Sell_LRP: 
            CurrPositionMN[m_Session].Sell_LRP++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_LRP; 
            if((CurrPositionMN[m_Session].Sell_LRP-BasePositionMN[m_Session].Sell_LRP) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_LRP--;
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
      case Buy_LCP:
            CurrPositionMN[m_Session].Buy_LCP++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_LCP; 
            if((CurrPositionMN[m_Session].Buy_LCP-BasePositionMN[m_Session].Buy_LCP) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_LCP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                   
      case Sell_LCP: 
            CurrPositionMN[m_Session].Sell_LCP++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_LCP; 
            if((CurrPositionMN[m_Session].Sell_LCP-BasePositionMN[m_Session].Sell_LCP) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_LCP--;
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

      case Buy_DLRC: 
            CurrPositionMN[m_Session].Buy_DLRC++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_DLRC; 
            if((CurrPositionMN[m_Session].Buy_DLRC-BasePositionMN[m_Session].Buy_DLRC) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_DLRC--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                           
      case Sell_DLRC: 
            CurrPositionMN[m_Session].Sell_DLRC++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_DLRC; 
            if((CurrPositionMN[m_Session].Sell_DLRC-BasePositionMN[m_Session].Sell_DLRC) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_DLRC--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                               

      case Buy_DLRCP: 
            CurrPositionMN[m_Session].Buy_DLRCP++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_DLRCP; 
            if((CurrPositionMN[m_Session].Buy_DLRCP-BasePositionMN[m_Session].Buy_DLRCP) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_DLRCP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                           
      case Sell_DLRCP: 
            CurrPositionMN[m_Session].Sell_DLRCP++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_DLRCP; 
            if((CurrPositionMN[m_Session].Sell_DLRCP-BasePositionMN[m_Session].Sell_DLRCP) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_DLRCP--;
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
      case Buy_DLRCCP: 
            CurrPositionMN[m_Session].Buy_DLRCCP++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_DLRCCP; 
            if((CurrPositionMN[m_Session].Buy_DLRCCP-BasePositionMN[m_Session].Buy_DLRCCP) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_DLRCCP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                           
      case Sell_DLRCCP: 
            CurrPositionMN[m_Session].Sell_DLRCCP++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_DLRCCP; 
            if((CurrPositionMN[m_Session].Sell_DLRCCP-BasePositionMN[m_Session].Sell_DLRCCP) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_DLRCCP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                               
      case Buy_ROR:
            CurrPositionMN[m_Session].Buy_ROR++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_ROR; 
            if((CurrPositionMN[m_Session].Buy_ROR-BasePositionMN[m_Session].Buy_ROR) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_ROR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                               
      case Sell_ROR: 
            CurrPositionMN[m_Session].Sell_ROR++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_ROR; 
            if((CurrPositionMN[m_Session].Sell_ROR-BasePositionMN[m_Session].Sell_ROR) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_ROR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                               
      case Buy_RORC:
            CurrPositionMN[m_Session].Buy_RORC++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_RORC; 
            if((CurrPositionMN[m_Session].Buy_RORC-BasePositionMN[m_Session].Buy_RORC) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_RORC--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                               
      case Sell_RORC: 
            CurrPositionMN[m_Session].Sell_RORC++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_RORC; 
            if((CurrPositionMN[m_Session].Sell_RORC-BasePositionMN[m_Session].Sell_RORC) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Sell_RORC--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                               
      case Buy_RORCP:
            CurrPositionMN[m_Session].Buy_RORCP++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Buy_RORCP; 
            if((CurrPositionMN[m_Session].Buy_RORCP-BasePositionMN[m_Session].Buy_RORCP) >= MN_IncNumber)
               {
                CurrPositionMN[m_Session].Buy_RORCP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                  
            break;                                                               
      case Sell_RORCP:
            CurrPositionMN[m_Session].Sell_RORCP++;
            m_NextMagicNumber=CurrPositionMN[m_Session].Sell_RORCP; 
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
      case(Buy_LRP):
         CurrPositionMN[m_Session].Buy_LRP=BasePositionMN[m_Session].Buy_LRP; break;
      case(Sell_LRP):
         CurrPositionMN[m_Session].Sell_LRP=BasePositionMN[m_Session].Sell_LRP; break;
      case(Buy_LC):
         CurrPositionMN[m_Session].Buy_LC=BasePositionMN[m_Session].Buy_LC; break;
      case(Sell_LC):
         CurrPositionMN[m_Session].Sell_LC=BasePositionMN[m_Session].Sell_LC; break;
      case(Buy_LCP):
         CurrPositionMN[m_Session].Buy_LCP=BasePositionMN[m_Session].Buy_LCP; break;
      case(Sell_LCP):
         CurrPositionMN[m_Session].Sell_LCP=BasePositionMN[m_Session].Sell_LCP; break;
      case(Buy_DLR):
         CurrPositionMN[m_Session].Buy_DLR=BasePositionMN[m_Session].Buy_DLR; break;
      case(Sell_DLR):
         CurrPositionMN[m_Session].Sell_DLR=BasePositionMN[m_Session].Sell_DLR; break;
      case(Buy_DLRC):
         CurrPositionMN[m_Session].Buy_DLRC=BasePositionMN[m_Session].Buy_DLRC; break;
      case(Sell_DLRC):
         CurrPositionMN[m_Session].Sell_DLRC=BasePositionMN[m_Session].Sell_DLRC; break;
      case(Buy_DLRCP):
         CurrPositionMN[m_Session].Buy_DLRCP=BasePositionMN[m_Session].Buy_DLRCP; break;
      case(Sell_DLRCP):
         CurrPositionMN[m_Session].Sell_DLRCP=BasePositionMN[m_Session].Sell_DLRCP; break;
      case(Buy_DLRCC):
         CurrPositionMN[m_Session].Buy_DLRCC=BasePositionMN[m_Session].Buy_DLRCC; break;
      case(Sell_DLRCC):
         CurrPositionMN[m_Session].Sell_DLRCC=BasePositionMN[m_Session].Sell_DLRCC; break;
      case(Buy_DLRCCP):
         CurrPositionMN[m_Session].Buy_DLRCCP=BasePositionMN[m_Session].Buy_DLRCCP; break;
      case(Sell_DLRCCP):
         CurrPositionMN[m_Session].Sell_DLRCCP=BasePositionMN[m_Session].Sell_DLRCCP; break;
      case(Buy_ROR):
         CurrPositionMN[m_Session].Buy_ROR=BasePositionMN[m_Session].Buy_ROR; break;
      case(Sell_ROR):
         CurrPositionMN[m_Session].Sell_ROR=BasePositionMN[m_Session].Sell_ROR; break;
      case(Buy_RORC):
         CurrPositionMN[m_Session].Buy_RORC=BasePositionMN[m_Session].Buy_RORC; break;
      case(Sell_RORC):
         CurrPositionMN[m_Session].Sell_RORC=BasePositionMN[m_Session].Sell_RORC; break;
      case(Buy_RORCP):
         CurrPositionMN[m_Session].Buy_RORCP=BasePositionMN[m_Session].Buy_RORCP; break;
      case(Sell_RORCP):
         CurrPositionMN[m_Session].Sell_RORCP=BasePositionMN[m_Session].Sell_RORCP;break;      
     }
     
   if(m_PositionID==AllPM)
     {
      CurrPositionMN[m_Session].Buy_MR=BasePositionMN[m_Session].Buy_MR; 
      CurrPositionMN[m_Session].Sell_MR=BasePositionMN[m_Session].Sell_MR; 
      CurrPositionMN[m_Session].Buy_LR=BasePositionMN[m_Session].Buy_LR; 
      CurrPositionMN[m_Session].Sell_LR=BasePositionMN[m_Session].Sell_LR;
      CurrPositionMN[m_Session].Buy_LRP=BasePositionMN[m_Session].Buy_LRP;
      CurrPositionMN[m_Session].Sell_LRP=BasePositionMN[m_Session].Sell_LRP;
      CurrPositionMN[m_Session].Buy_LC=BasePositionMN[m_Session].Buy_LC;
      CurrPositionMN[m_Session].Sell_LC=BasePositionMN[m_Session].Sell_LC;
      CurrPositionMN[m_Session].Buy_LCP=BasePositionMN[m_Session].Buy_LCP; 
      CurrPositionMN[m_Session].Sell_LCP=BasePositionMN[m_Session].Sell_LCP;
      CurrPositionMN[m_Session].Buy_DLR=BasePositionMN[m_Session].Buy_DLR; 
      CurrPositionMN[m_Session].Sell_DLR=BasePositionMN[m_Session].Sell_DLR;
      CurrPositionMN[m_Session].Buy_DLRC=BasePositionMN[m_Session].Buy_DLRC; 
      CurrPositionMN[m_Session].Sell_DLRC=BasePositionMN[m_Session].Sell_DLRC;
      CurrPositionMN[m_Session].Buy_DLRCP=BasePositionMN[m_Session].Buy_DLRCP; 
      CurrPositionMN[m_Session].Sell_DLRCP=BasePositionMN[m_Session].Sell_DLRCP;
      CurrPositionMN[m_Session].Buy_DLRCC=BasePositionMN[m_Session].Buy_DLRCC; 
      CurrPositionMN[m_Session].Sell_DLRCC=BasePositionMN[m_Session].Sell_DLRCC;
      CurrPositionMN[m_Session].Buy_DLRCCP=BasePositionMN[m_Session].Buy_DLRCCP; 
      CurrPositionMN[m_Session].Sell_DLRCCP=BasePositionMN[m_Session].Sell_DLRCCP;
      CurrPositionMN[m_Session].Buy_ROR=BasePositionMN[m_Session].Buy_ROR; 
      CurrPositionMN[m_Session].Sell_ROR=BasePositionMN[m_Session].Sell_ROR;
      CurrPositionMN[m_Session].Buy_RORC=BasePositionMN[m_Session].Buy_RORC; 
      CurrPositionMN[m_Session].Sell_RORC=BasePositionMN[m_Session].Sell_RORC;
      CurrPositionMN[m_Session].Buy_RORCP=BasePositionMN[m_Session].Buy_RORCP;
      CurrPositionMN[m_Session].Sell_RORCP=BasePositionMN[m_Session].Sell_RORCP; 
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
