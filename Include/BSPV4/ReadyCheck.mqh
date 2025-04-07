//+------------------------------------------------------------------+
//|                                                   ReadyCheck.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV4/ExternVariables.mqh>


//-------------------------------------------------------------------+
void OpenReadyCheck(void)
{

//  Sell Open Ready Check
   if( !SellOpenReady.LASSReady && (LASSBand >= BandP2) ) 
      SellOpenReady.LASSReady = true;  

   if( SellOpenReady.LASSReady && (NLRSTrend == DownTrend) && (WmaSTrend == DownTrend) ) SellOpenReady.TrendReady = true; 
   else SellOpenReady.TrendReady = false; 

   
// Counter Buy Open Ready Check
   if(!BuyCOReady.LASSReady && (LASSBand >= BandP2) ) 
      BuyCOReady.LASSReady = true;
       
   if( SellOpenReady.LASSReady && !BuyCOReady.LASSChangedDown && ( (LASSTrend1 == UpTrend) && (LASSTrend == DownTrend) ) )
      {
         BuyCOReady.LASSChangedDown = true;
         BuyCOReady.LASSBar1 = CurBar;        
      }
   
   if( BuyCOReady.LASSChangedDown && !BuyCOReady.TrendChanged && 
       ((NLRSTrend == DownTrend) || (WmaSTrend == DownTrend)) && (LASSTrend == DownTrend) )  
         BuyCOReady.TrendChanged = true;

   if( BuyCOReady.LASSChangedDown && !BuyCOReady.LASSChangedUp && ( (LASSTrend1 == DownTrend) && (LASSTrend == UpTrend) )  ) 
      {
         BuyCOReady.LASSChangedUp = true;
         BuyCOReady.LASSBar2 = CurBar;
      }
      
   if( BuyCOReady.LASSChangedDown && BuyCOReady.LASSChangedUp &&  !BuyCOReady.TrendChanged ) BuyCOReadyReset();         

   if( BuyCOReady.TrendChanged && BuyCOReady.LASSChangedUp && !BuyCOReady.LASMReady )
     {
      if( ( MathAbs(BuyCOReady.LASSBar2-BuyCOReady.LASSBar1) <= CounterOpenMaxBar ) && (LASMBand >= BandP1)  )
         BuyCOReady.LASMReady = true;
      else BuyCOReadyReset();
     }
      
   if( BuyCOReady.LASMReady && (NLRSTrend == UpTrend) && (WmaSTrend == UpTrend) && 
       (LASSTrend == UpTrend) && (NLRMTrend == UpTrend) && (WmaMTrend == UpTrend) )
     {   
       if( MathAbs(CurBar-BuyCOReady.LASSBar1) <= CounterOpenMaxBar ) BuyCOReady.TrendReady = true;
       else BuyCOReadyReset();
     } 
   else BuyCOReady.TrendReady = false;           
  
      

//  Buy Open Ready Check      
   if( !BuyOpenReady.LASSReady && (LASSBand <= BandM2) ) 
      BuyOpenReady.LASSReady = true;

   if( BuyOpenReady.LASSReady && (NLRSTrend == UpTrend) && (WmaSTrend == UpTrend) ) BuyOpenReady.TrendReady = true;   
   else BuyOpenReady.TrendReady = false; 
   
//Counter Sell Open Ready Check
   if(!SellCOReady.LASSReady && (LASSBand <= BandM2) ) 
      SellCOReady.LASSReady = true;

   if( BuyOpenReady.LASSReady && !SellCOReady.LASSChangedUp && ( (LASSTrend1 == DownTrend) && (LASSTrend == UpTrend) ) ) 
      {
         SellCOReady.LASSChangedUp = true;
         SellCOReady.LASSBar1 = CurBar;
      }   

   if( SellCOReady.LASSChangedUp && !SellCOReady.TrendChanged &&
       ((NLRSTrend == UpTrend) || (WmaSTrend == UpTrend)) && (LASSTrend == UpTrend) )
        SellCOReady.TrendChanged = true;
        
   if( SellCOReady.TrendChanged && !SellCOReady.LASSChangedDown && ( (LASSTrend1 == UpTrend) && (LASSTrend == DownTrend) ) )
       {
         SellCOReady.LASSChangedDown = true;
         SellCOReady.LASSBar2 = CurBar;
       }

   if( SellCOReady.LASSChangedUp && SellCOReady.LASSChangedDown &&  !SellCOReady.TrendChanged ) 
      SellCOReadyReset();         

   
   if( SellCOReady.LASSChangedDown && !SellCOReady.LASMReady )        
     {
       if( ( MathAbs(SellCOReady.LASSBar2-SellCOReady.LASSBar1) <= CounterOpenMaxBar ) && (LASMBand <= BandM1)  )
          SellCOReady.LASMReady = true; 
       else SellCOReadyReset();
     } 
      
   if( SellCOReady.LASMReady && (NLRSTrend == DownTrend) && (WmaSTrend == DownTrend) && 
       (LASSTrend == DownTrend) && (NLRMTrend == DownTrend) && (WmaMTrend == DownTrend) )
     {  
       if(MathAbs(SellCOReady.LASSBar2-SellCOReady.LASSBar1) <= CounterOpenMaxBar ) SellCOReady.TrendReady = true;
       else SellCOReadyReset();
     } 
   else SellCOReady.TrendReady = false;           
           

}   


//----------------------------------------------------------------------------
void CloseReadyCheck(void)
 {

   if( PositionSummary.firstPositionType == POSITION_TYPE_BUY )
     {
       if(PositionSummary.OpenMode == ModeReversal)
        { 
         if( (NLRSTrend == DownTrend) && (WmaSTrend == DownTrend) && (LASSTrend == DownTrend) && (LASLTrend == DownTrend) )
            BuyCloseReady.TrendReady = true;  
         else BuyCloseReady.TrendReady = false;  
        }    
       else if(PositionSummary.OpenMode == ModeCounter)
        {
         if( (NLRSTrend == DownTrend) && (WmaSTrend == DownTrend) && (LASSTrend == DownTrend) && (LASLTrend == DownTrend) &&
             (NLRMTrend == DownTrend) && (WmaMTrend == DownTrend) && (LASMTrend == DownTrend) )
            BuyCloseReady.TrendReady = true;  
         else BuyCloseReady.TrendReady = false;          
        }
     }  
     
      
   if( PositionSummary.firstPositionType== POSITION_TYPE_SELL )
     {       
       if(PositionSummary.OpenMode == ModeReversal)
        { 
         if( (NLRSTrend == UpTrend) && (WmaSTrend == UpTrend) && (LASSTrend == UpTrend) && (LASLTrend == UpTrend)  )  
            SellCloseReady.TrendReady = true;
         else SellCloseReady.TrendReady = false;  
        }    
       else if(PositionSummary.OpenMode == ModeCounter)
        {
         if( (NLRSTrend == UpTrend) && (WmaSTrend == UpTrend) && (LASSTrend == UpTrend) && (LASLTrend == UpTrend) &&
             (NLRMTrend == UpTrend) && (WmaMTrend == UpTrend) && (LASMTrend == UpTrend)  )  
            SellCloseReady.TrendReady = true;
         else SellCloseReady.TrendReady = false;  
        }
     }    
 
 }


/*
//-------------------------------------------------------------------+
void OpenReadyCheck(void)
{

//  Sell Open Ready Check
   if( (SellOpenReady.LASSReady == false) && ((LASSBand == BandP2)||(LASSBand == BandP3)) ) 
      SellOpenReady.LASSReady = true;
         
   if( (SellOpenReady.LASSReady == true) && (PositionSummary.LASSChanged == false) && (LASSTrend1 == UpTrend) && (LASSTrend == DownTrend) )  
       PositionSummary.LASSChanged = true;

   if( SellAbled() && SellOpenReady.LASSReady && (NLRSTrend == DownTrend) && (WmaSTrend == DownTrend) ) 
      SellOpenReady.TrendReady = true; 
   else SellOpenReady.TrendReady = false;      

         
//   if( SellOpenReady.LASMReady && (NLRSTrend == DownTrend) && (WmaSTrend == DownTrend) && (LASLTrend == DownTrend) ) 
//      SellOpenReady.TrendReady = true;   
      
      

//  Buy Open Ready Check      
   if( (BuyOpenReady.LASSReady == false) && ((LASSBand == BandM2)||(LASSBand == BandM3)) ) 
      BuyOpenReady.LASSReady = true;

   if( (BuyOpenReady.LASSReady == true) && (PositionSummary.LASSChanged == false) && (LASSTrend1 == DownTrend) && (LASSTrend == UpTrend) ) 
      PositionSummary.LASSChanged = true;

   if( BuyAbled() && BuyOpenReady.LASSReady && (NLRSTrend == UpTrend) && (WmaSTrend == UpTrend) )  
      BuyOpenReady.TrendReady = true;   
   else BuyOpenReady.TrendReady = false;    

    
//   if( BuyOpenReady.LASMReady && (NLRSTrend == UpTrend) && (WmaSTrend == UpTrend) && (LASLTrend == UpTrend) )  
//      BuyOpenReady.TrendReady = true;         

}   


//----------------------------------------------------------------------------
void CloseReadyCheck(void)
{

   if( PositionSummary.firstPositionType== POSITION_TYPE_SELL )
     {
      if( (PositionSummary.LASSChanged == false) && (LASSTrend1 == UpTrend) && (LASSTrend == DownTrend) )  
         PositionSummary.LASSChanged = true; 
         
      if( (PositionSummary.LASSChanged == true) && (LASSTrend1 == DownTrend) && (LASSTrend == UpTrend) )  
         PositionSummary.LASSReChanged = true;       

      if( (NLRSTrend == UpTrend) && (WmaSTrend == UpTrend) && (LASSTrend == UpTrend)  )  
         SellCloseReady.TrendReady = true; 

 // Ver1       
//      if( (PositionSummary.LASMChanged == true) && (NLRSTrend == UpTrend) && (WmaSTrend == UpTrend) && (LASLTrend == UpTrend) &&
//          ( (LASMBand == BandM1) || (LASMBand == BandM2) || (LASMBand == BandM3) ) )  
//         SellCloseReady.TrendReady = true; 
//
//      if( (PositionSummary.LASMReChanged == true) && (NLRSTrend == DownTrend) && (WmaSTrend == DownTrend) && (LASLTrend == DownTrend) )
//         SellCloseReady.TrendReady = true;


     }    


   if( PositionSummary.firstPositionType == POSITION_TYPE_BUY )
     {
      if( (PositionSummary.LASSChanged == false) && (LASSTrend1 == DownTrend) && (LASSTrend == UpTrend) ) 
         PositionSummary.LASSChanged = true;

      if( (PositionSummary.LASSChanged == true) && (LASSTrend1 == UpTrend) && (LASSTrend == DownTrend) ) 
         PositionSummary.LASSReChanged = true;

      if( (NLRSTrend == DownTrend) && (WmaSTrend == DownTrend) && (LASSTrend == DownTrend) )
         BuyCloseReady.TrendReady = true;  

      
//      if( (PositionSummary.LASMChanged == true) && (NLRSTrend == DownTrend) && (WmaSTrend == DownTrend) && (LASLTrend == DownTrend) &&
//           ( (LASMBand == BandP1) || (LASMBand == BandP2) || (LASMBand == BandP3) ) )
//         BuyCloseReady.TrendReady = true;       
//
//      if( (PositionSummary.LASMReChanged == true) && (NLRSTrend == UpTrend) && (WmaSTrend == UpTrend) && (LASLTrend == UpTrend) )
//         BuyCloseReady.TrendReady = true;       

     }  
 
}
*/



//Ready Parameter Reset
//-------------------------------------------------------------------+
void OpenReadyReset(void)
{
   BuyOpenReady.LASSReady=false;
   BuyOpenReady.TrendReady = false;
   SellOpenReady.LASSReady = false;
   SellOpenReady.TrendReady = false;
}

//-------------------------------------------------------------------+
void BuyCOReadyReset(void)
{
   BuyCOReady.LASSReady = false;
   BuyCOReady.LASSChangedDown = false;
   BuyCOReady.LASSChangedUp = false;
   BuyCOReady.TrendChanged = false; 
   BuyCOReady.LASSBar1 = 0;
   BuyCOReady.LASSBar2 = 0;
   BuyCOReady.LASMReady = false;
   BuyCOReady.TrendReady = false;
}

void SellCOReadyReset(void)
{   
   SellCOReady.LASSReady = false;
   SellCOReady.LASSChangedDown = false;
   SellCOReady.LASSChangedUp = false;
   SellCOReady.TrendChanged = false; 
   SellCOReady.LASSBar1 = 0;
   SellCOReady.LASSBar2 = 0;
   SellCOReady.LASMReady = false;
   SellCOReady.TrendReady = false;
}


//-------------------------------------------------------------------+
void CloseReadyReset(void)
{
   BuyCloseReady.TrendReady = false;
   SellCloseReady.TrendReady = false;
}

//--------------------------------------------------------------------+
void BuyAble(void)
{
   BuyOpenReady.Able = true;
}

void SellAble(void)
{
   SellOpenReady.Able = true;
}

void BuyDisable(void)
{
   BuyOpenReady.Able = false;
}

void SellDisable(void)
{
   SellOpenReady.Able = false;
}

bool BuyAbled(void)
{
   if(BuyOpenReady.Able == true) return(true);
   return(false);
}

bool SellAbled(void)
{
   if(SellOpenReady.Able == true) return(true);
   return(false);
}
  
  

//-------------------------------------------
// Manage Trend after first position opened

M_BuySellNo ManageTrend(void)
{ 

   if(PositionSummary.totalNumPositions >= 1)
     {
      if( CurBar != PositionInfo[PositionSummary.totalNumPositions - 1].openBar )
        {
         if( PositionInfo[PositionSummary.totalNumPositions - 1].positionType == POSITION_TYPE_BUY )
           {
            if( (LASLTrend1 == UpTrend) && (LASLTrend == DownTrend) ) 
               return(M_Sell);
            else return(M_Nothing); 
           }
        
         if( PositionInfo[PositionSummary.totalNumPositions - 1].positionType == POSITION_TYPE_SELL )
           {
            if( (LASLTrend1 == DownTrend) && (LASLTrend == UpTrend) ) 
               return(M_Buy);
            else return(M_Nothing); 
           }     
        }   
     }

   return(M_Nothing);
}

  