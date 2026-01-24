//+------------------------------------------------------------------+
//|                                                MagicNumberV3.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV4/ExternVariables.mqh>

//--------------------------------------------------------------------------------
bool MagicNumberInit()
{
   if((BaseMagicNumber%10000!=0) || ( int(BaseMagicNumber/10000) <= 0.))
     {
      Alert("Base MagicNumber should be larger than 10,000, and unit of 10,000" );
      return(false);
     }

   BaseMN_Buy_MR=BaseMagicNumber+Buy_MR;
   CurrMN_Buy_MR=BaseMN_Buy_MR;
   BaseMN_Sell_MR=BaseMagicNumber+Sell_MR;
   CurrMN_Sell_MR=BaseMN_Sell_MR;
   BaseMN_Buy_LR=BaseMagicNumber+Buy_LR;
   CurrMN_Buy_LR=BaseMN_Buy_LR;
   BaseMN_Sell_LR=BaseMagicNumber+Sell_LR;
   CurrMN_Sell_LR=BaseMN_Sell_LR;
   BaseMN_Buy_LRP=BaseMagicNumber+Buy_LRP;
   CurrMN_Buy_LRP=BaseMN_Buy_LRP;
   BaseMN_Sell_LRP=BaseMagicNumber+Sell_LRP;
   CurrMN_Sell_LRP=BaseMN_Sell_LRP;
   BaseMN_Buy_LC=BaseMagicNumber+Buy_LC;
   CurrMN_Buy_LC=BaseMN_Buy_LC;
   BaseMN_Sell_LC=BaseMagicNumber+Sell_LC;
   CurrMN_Sell_LC=BaseMN_Sell_LC;
   BaseMN_Buy_LCP=BaseMagicNumber+Buy_LCP;
   CurrMN_Buy_LCP=BaseMN_Buy_LCP;
   BaseMN_Sell_LCP=BaseMagicNumber+Sell_LCP;
   CurrMN_Sell_LCP=BaseMN_Sell_LCP;
   BaseMN_Buy_DLR=BaseMagicNumber+Buy_DLR;
   CurrMN_Buy_DLR=BaseMN_Buy_DLR;
   BaseMN_Sell_DLR=BaseMagicNumber+Sell_DLR;
   CurrMN_Sell_DLR=BaseMN_Sell_DLR;
   BaseMN_Buy_DLRP=BaseMagicNumber+Buy_DLRP;
   CurrMN_Buy_DLRP=BaseMN_Buy_DLRP;
   BaseMN_Sell_DLRP=BaseMagicNumber+Sell_DLRP;
   CurrMN_Sell_DLRP=BaseMN_Sell_DLRP;
   BaseMN_Buy_ROR=BaseMagicNumber+Buy_ROR;
   CurrMN_Buy_ROR=BaseMN_Buy_ROR;
   BaseMN_Sell_ROR=BaseMagicNumber+Sell_ROR;
   CurrMN_Sell_ROR=BaseMN_Sell_ROR;
   BaseMN_Buy_RORP=BaseMagicNumber+Buy_RORP;
   CurrMN_Buy_RORP=BaseMN_Buy_RORP;
   BaseMN_Sell_RORP=BaseMagicNumber+Sell_RORP;
   CurrMN_Sell_RORP=BaseMN_Sell_RORP;   
     
   return(true);
}


//------------------------------------------------------------------------------
int BaseMagicNumberF(position_IDE m_PositionIDE)
{
   int m_MagicNumber=0;
   
   switch(m_PositionIDE)
     {
      case(Buy_MR):
         m_MagicNumber=BaseMN_Buy_MR; break;
      case(Sell_MR):
         m_MagicNumber=BaseMN_Sell_MR; break;
      case(Buy_LR):
         m_MagicNumber=BaseMN_Buy_LR; break;
      case(Sell_LR):
         m_MagicNumber=BaseMN_Sell_LR; break;
      case(Buy_LRP):
         m_MagicNumber=BaseMN_Buy_LRP; break;
      case(Sell_LRP):
         m_MagicNumber=BaseMN_Sell_LRP; break;
      case(Buy_LC):
         m_MagicNumber=BaseMN_Buy_LC; break;
      case(Sell_LC):
         m_MagicNumber=BaseMN_Sell_LC; break;
      case(Buy_LCP):
         m_MagicNumber=BaseMN_Buy_LCP; break;
      case(Sell_LCP):
         m_MagicNumber=BaseMN_Sell_LCP; break;
      case(Buy_DLR):
         m_MagicNumber=BaseMN_Buy_DLR; break;
      case(Sell_DLR):
         m_MagicNumber=BaseMN_Sell_DLR; break;
      case(Buy_DLRP):
         m_MagicNumber=BaseMN_Buy_DLRP; break;
      case(Sell_DLRP):
         m_MagicNumber=BaseMN_Sell_DLRP; break;
      case(Buy_ROR):
         m_MagicNumber=BaseMN_Buy_ROR; break;
      case(Sell_ROR):
         m_MagicNumber=BaseMN_Sell_ROR; break;
      case(Buy_RORP):
         m_MagicNumber=BaseMN_Buy_RORP; break;
      case(Sell_RORP):
         m_MagicNumber=BaseMN_Sell_RORP;break;     
     }
   return(m_MagicNumber);  
}


//------------------------------------------------------------------------------
int CurrMagicNumberF(position_IDE m_PositionIDE)
{
   int m_MagicNumber=0;
   
   switch(m_PositionIDE)
     {
      case(Buy_MR):
         m_MagicNumber=CurrMN_Buy_MR; break;
      case(Sell_MR):
         m_MagicNumber=CurrMN_Sell_MR; break;
      case(Buy_LR):
         m_MagicNumber=CurrMN_Buy_LR; break;
      case(Sell_LR):
         m_MagicNumber=CurrMN_Sell_LR; break;
      case(Buy_LRP):
         m_MagicNumber=CurrMN_Buy_LRP; break;
      case(Sell_LRP):
         m_MagicNumber=CurrMN_Sell_LRP; break;
      case(Buy_LC):
         m_MagicNumber=CurrMN_Buy_LC; break;
      case(Sell_LC):
         m_MagicNumber=CurrMN_Sell_LC; break;
      case(Buy_LCP):
         m_MagicNumber=CurrMN_Buy_LCP; break;
      case(Sell_LCP):
         m_MagicNumber=CurrMN_Sell_LCP; break;
      case(Buy_DLR):
         m_MagicNumber=CurrMN_Buy_DLR; break;
      case(Sell_DLR):
         m_MagicNumber=CurrMN_Sell_DLR; break;
      case(Buy_DLRP):
         m_MagicNumber=CurrMN_Buy_DLRP; break;
      case(Sell_DLRP):
         m_MagicNumber=CurrMN_Sell_DLRP; break;
      case(Buy_ROR):
         m_MagicNumber=CurrMN_Buy_ROR; break;
      case(Sell_ROR):
         m_MagicNumber=CurrMN_Sell_ROR; break;
      case(Buy_RORP):
         m_MagicNumber=CurrMN_Buy_RORP; break;
      case(Sell_RORP):
         m_MagicNumber=CurrMN_Sell_RORP;break;     
     }
   return(m_MagicNumber);  
}


//------------------------------------------------------------
int NextMagicNumberF(position_IDE m_PositionIDE)
{
   int m_NextMagicNumber=0;
   
   switch(m_PositionIDE)
     {
      case Buy_MR:
             CurrMN_Buy_MR++;
             m_NextMagicNumber=CurrMN_Buy_MR; 
             if(m_NextMagicNumber>=BaseMN_Sell_MR)
               {
                CurrMN_Buy_MR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }
             break;               
      case Sell_MR:
            CurrMN_Sell_MR++;
            m_NextMagicNumber=CurrMN_Sell_MR; 
            if(m_NextMagicNumber>=BaseMN_Buy_LR)
               {
                CurrMN_Sell_MR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;
      case Buy_LR:
            CurrMN_Buy_LR++;
            m_NextMagicNumber=CurrMN_Buy_LR;
            if(m_NextMagicNumber>=BaseMN_Sell_LR)
               {
                CurrMN_Buy_LR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;
      case Sell_LR:
            CurrMN_Sell_LR++;
            m_NextMagicNumber=CurrMN_Sell_LR; 
            if(m_NextMagicNumber>=BaseMN_Buy_LRP)
               {
                CurrMN_Sell_LR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;
      case Buy_LRP: 
            CurrMN_Buy_LRP++;
            m_NextMagicNumber=CurrMN_Buy_LRP;
            if(m_NextMagicNumber>=BaseMN_Sell_LRP)
               {
                CurrMN_Buy_LRP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;            
      case Sell_LRP: 
            CurrMN_Sell_LRP++;
            m_NextMagicNumber=CurrMN_Sell_LRP;
            if(m_NextMagicNumber>=BaseMN_Buy_LC)
               {
                CurrMN_Sell_LRP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                        
      case Buy_LC:
            CurrMN_Buy_LC++;
            m_NextMagicNumber=CurrMN_Buy_LC;
            if(m_NextMagicNumber>=BaseMN_Sell_LC)
               {
                CurrMN_Buy_LC--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                 
      case Sell_LC: 
            CurrMN_Sell_LC++;
            m_NextMagicNumber=CurrMN_Sell_LC;
            if(m_NextMagicNumber>=BaseMN_Buy_LCP)
               {
                CurrMN_Sell_LC--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                       
      case Buy_LCP:
            CurrMN_Buy_LCP++;
            m_NextMagicNumber=CurrMN_Buy_LCP;
            if(m_NextMagicNumber>=BaseMN_Sell_LCP)
               {
                CurrMN_Buy_LCP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                                   
      case Sell_LCP: 
            CurrMN_Sell_LCP++;
            m_NextMagicNumber=CurrMN_Sell_LCP;
            if(m_NextMagicNumber>=BaseMN_Buy_DLR)
               {
                CurrMN_Sell_LCP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                                               
      case Buy_DLR: 
            CurrMN_Buy_DLR++;
            m_NextMagicNumber=CurrMN_Buy_DLR; 
            if(m_NextMagicNumber>=BaseMN_Sell_DLR)
               {
                CurrMN_Buy_DLR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                                           
      case Sell_DLR: 
            CurrMN_Sell_DLR++;
            m_NextMagicNumber=CurrMN_Sell_DLR; 
            if(m_NextMagicNumber>=BaseMN_Buy_DLRP)
               {
                CurrMN_Sell_DLR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                                               
      case Buy_DLRP:
            CurrMN_Buy_DLRP++;
            m_NextMagicNumber=CurrMN_Buy_DLRP; 
            if(m_NextMagicNumber>=BaseMN_Sell_DLRP)
               {
                CurrMN_Buy_DLRP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                                   
      case Sell_DLRP: 
            CurrMN_Sell_DLRP++;
            m_NextMagicNumber=CurrMN_Sell_DLRP; 
            if(m_NextMagicNumber>=BaseMN_Buy_ROR)
               {
                CurrMN_Sell_DLRP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                                   
      case Buy_ROR:
            CurrMN_Buy_ROR++;
            m_NextMagicNumber=CurrMN_Buy_ROR;
            if(m_NextMagicNumber>=BaseMN_Sell_ROR)
               {
                CurrMN_Buy_ROR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                                               
      case Sell_ROR: 
            CurrMN_Sell_ROR++;
            m_NextMagicNumber=CurrMN_Sell_ROR;
            if(m_NextMagicNumber>=BaseMN_Buy_RORP)
               {
                CurrMN_Sell_ROR--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                                               
      case Buy_RORP:
            CurrMN_Buy_RORP++;
            m_NextMagicNumber=CurrMN_Buy_RORP;
            if(m_NextMagicNumber>=BaseMN_Sell_RORP)
               {
                CurrMN_Buy_RORP--;
                Alert("Error: Can not make more MagicNumber");
                return(false);
               }                      
            break;                                                               
      case Sell_RORP:
            CurrMN_Sell_RORP++;
            m_NextMagicNumber=CurrMN_Sell_RORP; 
            break;                                                    
     }
   return(m_NextMagicNumber);    
}


//----------------------------------------------------------------------------------------
position_IDE MakePIDE(ENUM_POSITION_TYPE m_PositionType, position_Mode m_PositionMode)
{
   position_IDE m_PositionIDE=No_Signal;
   
   if(m_PositionType==POSITION_TYPE_BUY)
     {
      switch(m_PositionMode)
        {
         case MiddleReverse:
               m_PositionIDE = Buy_MR; break;
         case LongReverse:
               m_PositionIDE = Buy_LR; break;
         case LongReversePyrimid:
               m_PositionIDE = Buy_LRP; break;
         case LongCounter:
               m_PositionIDE = Buy_LC; break;
         case LongCounterPyrimid:
               m_PositionIDE = Buy_LCP; break;
         case DoubleLongReverse:
               m_PositionIDE = Buy_DLR; break;
         case DoubleLongReversePyrimid:
               m_PositionIDE = Buy_DLRP; break;
         case ReOpenReverse:
               m_PositionIDE = Buy_ROR; break;
         case ReOpenReversePyrimid:
               m_PositionIDE = Buy_RORP; break;
        } 
      }     

   if(m_PositionType==POSITION_TYPE_SELL)
     {
      switch(m_PositionMode)
        {
         case MiddleReverse:
                m_PositionIDE = Sell_MR; break;
         case LongReverse:
                m_PositionIDE = Sell_LR; break;
         case LongReversePyrimid:
               m_PositionIDE = Sell_LRP; break;
         case LongCounter:
                m_PositionIDE = Sell_LC; break;
         case LongCounterPyrimid:
               m_PositionIDE = Sell_LCP; break;
         case DoubleLongReverse:
               m_PositionIDE = Sell_DLR; break;
         case DoubleLongReversePyrimid:
               m_PositionIDE = Sell_DLRP; break;
         case ReOpenReverse:
               m_PositionIDE = Sell_ROR; break;
         case ReOpenReversePyrimid:
               m_PositionIDE = Sell_RORP; break;
        }             
     }

   return(m_PositionIDE);
}

//---------------------------------------------------------
void MNInitByPIDE(position_IDE m_PositionIDE)
{

   switch(m_PositionIDE)
     {
      case(Buy_MR):
         CurrMN_Buy_MR=BaseMN_Buy_MR; break;
      case(Sell_MR):
         CurrMN_Sell_MR=BaseMN_Sell_MR; break;
      case(Buy_LR):
         CurrMN_Buy_LR=BaseMN_Buy_LR; break;
      case(Sell_LR):
         CurrMN_Sell_LR=BaseMN_Sell_LR; break;
      case(Buy_LRP):
         CurrMN_Buy_LRP=BaseMN_Buy_LRP; break;
      case(Sell_LRP):
         CurrMN_Sell_LRP=BaseMN_Sell_LRP; break;
      case(Buy_LC):
         CurrMN_Buy_LC=BaseMN_Buy_LC; break;
      case(Sell_LC):
         CurrMN_Sell_LC=BaseMN_Sell_LC; break;
      case(Buy_LCP):
         CurrMN_Buy_LCP=BaseMN_Buy_LCP; break;
      case(Sell_LCP):
         CurrMN_Sell_LCP=BaseMN_Sell_LCP; break;
      case(Buy_DLR):
         CurrMN_Buy_DLR=BaseMN_Buy_DLR; break;
      case(Sell_DLR):
         CurrMN_Sell_DLR=BaseMN_Sell_DLR; break;
      case(Buy_DLRP):
         CurrMN_Buy_DLRP=BaseMN_Buy_DLRP; break;
      case(Sell_DLRP):
         CurrMN_Sell_DLRP=BaseMN_Sell_DLRP; break;
      case(Buy_ROR):
         CurrMN_Buy_ROR=BaseMN_Buy_ROR; break;
      case(Sell_ROR):
         CurrMN_Sell_ROR=BaseMN_Sell_ROR; break;
      case(Buy_RORP):
         CurrMN_Buy_RORP=BaseMN_Buy_RORP; break;
      case(Sell_RORP):
         CurrMN_Sell_RORP=BaseMN_Sell_RORP;break;      
     }
     
   if(m_PositionIDE==AllPM)
     {
      CurrMN_Buy_MR=BaseMN_Buy_MR; 
      CurrMN_Sell_MR=BaseMN_Sell_MR; 
      CurrMN_Buy_LR=BaseMN_Buy_LR; 
      CurrMN_Sell_LR=BaseMN_Sell_LR;
      CurrMN_Buy_LRP=BaseMN_Buy_LRP;
      CurrMN_Sell_LRP=BaseMN_Sell_LRP;
      CurrMN_Buy_LC=BaseMN_Buy_LC;
      CurrMN_Sell_LC=BaseMN_Sell_LC;
      CurrMN_Buy_LCP=BaseMN_Buy_LCP; 
      CurrMN_Sell_LCP=BaseMN_Sell_LCP;
      CurrMN_Buy_DLR=BaseMN_Buy_DLR; 
      CurrMN_Sell_DLR=BaseMN_Sell_DLR;
      CurrMN_Buy_DLRP=BaseMN_Buy_DLRP;
      CurrMN_Sell_DLRP=BaseMN_Sell_DLRP;
      CurrMN_Buy_ROR=BaseMN_Buy_ROR; 
      CurrMN_Sell_ROR=BaseMN_Sell_ROR;
      CurrMN_Buy_RORP=BaseMN_Buy_RORP;
      CurrMN_Sell_RORP=BaseMN_Sell_RORP; 
     }     
}


//---------------------------------------------------------
int NumOfPositionByPIDE(position_IDE m_PositionIDE)
{
   int NumOfPosition=0;
   
   switch(m_PositionIDE)
     {
      case(Buy_MR):
         NumOfPosition=(CurrMN_Buy_MR-BaseMN_Buy_MR); break;
      case(Sell_MR):
         NumOfPosition=(CurrMN_Sell_MR-BaseMN_Sell_MR); break;
      case(Buy_LR):
         NumOfPosition=(CurrMN_Buy_LR-BaseMN_Buy_LR); break;
      case(Sell_LR):
         NumOfPosition=(CurrMN_Sell_LR-BaseMN_Sell_LR); break;
      case(Buy_LRP):
         NumOfPosition=(CurrMN_Buy_LRP-BaseMN_Buy_LRP); break;
      case(Sell_LRP):
         NumOfPosition=(CurrMN_Sell_LRP-BaseMN_Sell_LRP); break;
      case(Buy_LC):
         NumOfPosition=(CurrMN_Buy_LC-BaseMN_Buy_LC); break;
      case(Sell_LC):
         NumOfPosition=(CurrMN_Sell_LC-BaseMN_Sell_LC); break;
      case(Buy_LCP):
         NumOfPosition=(CurrMN_Buy_LCP-BaseMN_Buy_LCP); break;
      case(Sell_LCP):
         NumOfPosition=(CurrMN_Sell_LCP-BaseMN_Sell_LCP); break;
      case(Buy_DLR):
         NumOfPosition=(CurrMN_Buy_DLR-BaseMN_Buy_DLR); break;
      case(Sell_DLR):
         NumOfPosition=(CurrMN_Sell_DLR-BaseMN_Sell_DLR); break;
      case(Buy_DLRP):
         NumOfPosition=(CurrMN_Buy_DLRP-BaseMN_Buy_DLRP); break;
      case(Sell_DLRP):
         NumOfPosition=(CurrMN_Sell_DLRP-BaseMN_Sell_DLRP); break;
      case(Buy_ROR):
         NumOfPosition=(CurrMN_Buy_ROR-BaseMN_Buy_ROR); break;
      case(Sell_ROR):
         NumOfPosition=(CurrMN_Sell_ROR-BaseMN_Sell_ROR); break;
      case(Buy_RORP):
         NumOfPosition=(CurrMN_Buy_RORP-BaseMN_Buy_RORP); break;
      case(Sell_RORP):
         NumOfPosition=(CurrMN_Sell_RORP-BaseMN_Sell_RORP);break;     
     }
   return(NumOfPosition);  
}

//----------------------------------------------------------------------------------------------
int PositionBMN(int m_PositionMN)
{
   int m_BaseMagicNumber;
   
   m_BaseMagicNumber=int(MathFloor(m_PositionMN/10000)*10000);
   return(m_BaseMagicNumber);
}


/*
   Buy_MR, Sell_MR, Buy_LR, Sell_LR, Buy_LRP, Sell_LRP, Buy_LC, Sell_LC, Buy_LCP, Sell_LCP, 
   Buy_DLR, Sell_DLR, Buy_DLRP, Sell_DLRP, Buy_ROR, Sell_ROR, Buy_RORP, Sell_RORP ;


   BaseMN_Buy_MR, BaseMN_Sell_MR, BaseMN_Buy_LR, BaseMN_Sell_LR, BaseMN_Buy_LRP, BaseMN_Sell_LRP, 
   BaseMN_Buy_LC, BaseMN_Sell_LC, BaseMN_Buy_LCP, BaseMN_Sell_LCP, BaseMN_Buy_DLR, BaseMN_Sell_DLR, 
   BaseMN_Buy_DLRP, BaseMN_Sell_DLRP, BaseMN_Buy_ROR, BaseMN_Sell_ROR, BaseMN_Buy_RORP, BaseMN_Sell_RORP ;


   CurrMN_Buy_MR, BaseMN_Sell_MR, CurrMN_Buy_LR, CurrMN_Sell_LR, CurrMN_Buy_LRP, CurrMN_Sell_LRP, 
   CurrMN_Buy_LC, CurrMN_Sell_LC, CurrMN_Buy_LCP, CurrMN_Sell_LCP, CurrMN_Buy_DLR, CurrMN_Sell_DLR, 
   CurrMN_Buy_DLRP, CurrMN_Sell_DLRP, CurrMN_Buy_ROR, CurrMN_Sell_ROR, CurrMN_Buy_RORP, CurrMN_Sell_RORP ;
*/
//   Trade.SetExpertMagicNumber(iMagicNumber);
