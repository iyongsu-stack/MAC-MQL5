//+------------------------------------------------------------------+
//|                                                 ReadyCheckV2.mqh |
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
   if( !SellOpenReady.LASMReady && (LASMBand >= BandP2) ) 
      SellOpenReady.LASMReady = true;  

   if( SellOpenReady.LASMReady && (NLRMTrend == DownTrend) && (WmaMTrend == DownTrend) && 
       (LASMTrend == DownTrend) ) SellOpenReady.TrendReady = true; 
   else SellOpenReady.TrendReady = false; 
 

//  Buy Open Ready Check      
   if( !BuyOpenReady.LASMReady && (LASSBand <= BandM2) ) 
      BuyOpenReady.LASMReady = true;

   if( BuyOpenReady.LASMReady && (NLRMTrend == UpTrend) && (WmaMTrend == UpTrend) &&
       (LASMTrend == UpTrend) ) BuyOpenReady.TrendReady = true;   
   else BuyOpenReady.TrendReady = false; 
  
           
}   


//----------------------------------------------------------------------------
void CloseReadyCheck(void)
 {

   if( PositionSummary.firstPositionType == POSITION_TYPE_SELL )
     {
       if(PositionSummary.OpenMode == ModeReversal)
        { 
         if( (NLRMTrend == UpTrend) && (WmaSTrend == UpTrend) && (WmaMTrend == UpTrend) &&
             (LASMTrend == UpTrend) && (LASSTrend == UpTrend) ) 
             SellCloseReady.TrendReady = true; 
         else SellCloseReady.TrendReady = false; 
        }    
     }  
     
      
   if( PositionSummary.firstPositionType== POSITION_TYPE_BUY )
     {       
       if(PositionSummary.OpenMode == ModeReversal)
        { 
         if( (NLRMTrend == DownTrend) && (WmaSTrend == DownTrend) && (WmaMTrend == DownTrend) &&
             (LASMTrend == DownTrend) && (LASSTrend == DownTrend) ) 
             BuyCloseReady.TrendReady = true;   
         else BuyCloseReady.TrendReady = false; 
        }    
     }  

 }


//Ready Parameter Reset
//-------------------------------------------------------------------+
void OpenReadyReset(void)
{
   BuyOpenReady.Able = false;
   BuyOpenReady.LASSReady=false;
   BuyOpenReady.LASMReady = false;
   BuyOpenReady.TrendReady = false;

   SellOpenReady.Able = false;
   SellOpenReady.LASSReady = false;   
   SellOpenReady.LASMReady = false;
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
  
  
/*

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

*/  