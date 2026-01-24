//+------------------------------------------------------------------+
//|                                            FisherStratage_V3.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"


// Trade
#include <TradeHedge.mqh>
CTradeHedge Trade;
CPositions Positions;

// Price
#include <Price.mqh>
CBars Price;

// Timer
#include <Timer.mqh>
CTimer Timer;
CNewBar NewBar;



//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
sinput string Trading; 	// Trading
input ulong Slippage = 3;
input ulong MagicNumber = 10507;
input double FixedVolume = 0.1;

sinput string TI; 	// Timer
input bool TradeOnNewBar = true;
input bool UseTimer = true;
input int MyStartDay = MONDAY;
input int MyStartHour = 8; 
input int MyEndDay = FRIDAY;
input int MyEndHour = 16;
input bool UseLocalTime = false;

//Fisher transform signal input data
enum enCalcMode
{
   calc_hl, // Include current high and low in calculation
   calc_no  // Don't include current high and low in calculation
};

sinput string Fisher; 	// Fisher
input ENUM_TIMEFRAMES    TrendTimeFrame = PERIOD_H1; 
input int                fisherInpPeriod   = 20;        
input int                fisherSignalPeriod = 5;
input enCalcMode         fisherInpCalcMode = calc_no;      
input ENUM_APPLIED_PRICE fisherInpPrice    = PRICE_WEIGHTED; 
input ENUM_TIMEFRAMES    SignalTimeFrame = PERIOD_M3; 


//ADX_DIFF input parameters
sinput string ADX; 	// ADX
input ENUM_TIMEFRAMES ADXTimeFrame=PERIOD_M10; 
input double level1 = 12.;
input int adx_period = 7;

//ATR channel parameter
sinput string ATR; 	//ATR
input int      VWAPeriod =2;
input double Mult_Factor1= 1.5;
input ENUM_MA_METHOD MA_METHOD = MODE_EMA;
input ENUM_APPLIED_PRICE inpPrice    = PRICE_WEIGHTED; 
input int ATRPeriod = 14;


enum FisherTrend
{
   AscTrend,
   SideTrend,
   DesTrend,
};
FisherTrend Trend;


enum FisherSignal
{
   BuySignal,
   SellSignal,
};
FisherSignal TradeSignal, PrevTradeSignal;




//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
bool timerOn, lastTimerOn = false;
int TrendHandle, SignalHandle, ADXHandle, ATRHandle, numBuyTickets, numSellTickets, numTickets;
       
//Trailing Stop Variable
ulong buyTickets[], sellTickets[], Tickets[];
double shortTrailPrice=100000., longTrailPrice=0., currentPrice;



//==============================================================================
int OnInit()
//==============================================================================
{
	
	Trade.MagicNumber(MagicNumber);
	Trade.Deviation(Slippage);


      //Fisher Trend indicator setup
      TrendHandle = iCustom(Symbol(), Period(), "Examples\\FisherHTM", TrendTimeFrame,
                                     fisherInpPeriod, fisherSignalPeriod, fisherInpCalcMode, fisherInpPrice);  
      if(TrendHandle==INVALID_HANDLE)
      {
         Print(" Fisher Trend indicator initialization error.");
         return(INIT_FAILED);
      }
      
     //Fisher Signal indicator setup
      SignalHandle = iCustom(Symbol(), Period(), "FisherHTM2", SignalTimeFrame,
                                        fisherInpPeriod, fisherSignalPeriod, fisherInpCalcMode, fisherInpPrice); 
      if(SignalHandle==INVALID_HANDLE)
      {
         Print(" Fisher Signal indicator initialization error.");
         return(INIT_FAILED);
      } 
      //ADX_DIFF indicator setup
      ADXHandle = iCustom(Symbol(), Period(), "ADX_DIFF", ADXTimeFrame, level1, adx_period);
      if(ADXHandle==INVALID_HANDLE)
      {
         Print("ADX_DIFF Signal indicator initialization error.");
         return(INIT_FAILED);
      }

      //ATR indicator setup
      ATRHandle = iCustom(_Symbol, Period(), "VWAP+ATR CHANNEL", VWAPeriod, Mult_Factor1, MA_METHOD, inpPrice, ATRPeriod );
      if(ATRHandle==INVALID_HANDLE)
      {
         Print("ATR indicator initialization error.");
         return(INIT_FAILED);
      }
      

      
   return(INIT_SUCCEEDED);

}


//==============================================================================
void OnTick()
{

	// Check for new bar
	bool newBar = true;	
	if(TradeOnNewBar == true) newBar = NewBar.CheckNewBar(_Symbol,_Period);
		
	// weeklyTimer
	if(UseTimer == true) timerOn = Timer.WeeklyTimer(MyStartDay,MyStartHour,MyEndDay,MyEndHour,UseLocalTime);
		
	//Start trading
	if(newBar == true && timerOn == true)
   {
      int bar = Bars(Symbol(),0);

//      if( BarsCalculated(TrendHandle)<bar ) return;
//      if( BarsCalculated(SignalHandle)<bar ) return;
//      if( BarsCalculated(ADXHandle)< (bar-1) ) return;
//      if( BarsCalculated(ATRHandle)<bar) return;

      
      Print(TimeToString(TimeCurrent()));
      My_IndicatorSet();
      

      //Close Long position if trade signal is changed
      if( (PrevTradeSignal == BuySignal) && (TradeSignal == SellSignal) && (numBuyTickets >= 1) )
      {
         //Close all Long positions
		   for(int i = 0; i < numBuyTickets; i++) {Trade.Close(buyTickets[i]);}
		   
         GetPositionTickets();      
      }

      //Close Short position if trade signal is changed
      if( (PrevTradeSignal == SellSignal) && (TradeSignal == BuySignal) && (numSellTickets >= 1) )
      {
         //Close all Long positions
		   for(int i = 0; i < numSellTickets; i++) {Trade.Close(sellTickets[i]);}

         GetPositionTickets();      
      }

 
      //Long Buy order placement
      if( (Trend == AscTrend) && (TradeSignal == BuySignal)  && (numBuyTickets <= 0) )
      {
         //Close all Short positions
		   for(int i = 0; i < numSellTickets; i++) {Trade.Close(sellTickets[i]);}

         //Open Long Buy position
         Trade.Buy(_Symbol, FixedVolume);
         
         GetPositionTickets();
      }


      //Short Sell order placement
      if((Trend == DesTrend) && (TradeSignal == SellSignal)  && (numSellTickets <= 0))
      {
         //Close all Long positions
		   for(int i = 0; i < numBuyTickets; i++) { Trade.Close(buyTickets[i]);}
		   
         //Open Short Sell
         Trade.Sell(_Symbol, FixedVolume);
         
         GetPositionTickets();
      }
      
      SetTrailingStop();

      PrevTradeSignal = TradeSignal;
    }

   //My Trailing-Stop
   CheckTrailingStop();       
 
	// Time-Out, Close all positions
	if(lastTimerOn == true  &&  timerOn == false)
	{
		for(int i = 0; i < numTickets; i++) Trade.Close(Tickets[i]);  
		GetPositionTickets();      
	}
   lastTimerOn = timerOn;

}


//==============================================================================
void My_IndicatorSet()
{
 
   //Fisher Trend indicator
   double TrendHigh[], TrendLow[];
   ArraySetAsSeries(TrendHigh, true);
   ArraySetAsSeries(TrendLow, true);
   CopyBuffer(TrendHandle, 0, 0, 3, TrendHigh );
   CopyBuffer(TrendHandle, 1, 0, 3, TrendLow );

   double ADXDiff[];
   ArraySetAsSeries(ADXDiff, true);
   double level2 = level1 * (-1.);
   CopyBuffer(ADXHandle, 0, 0, 3, ADXDiff );
   
   if( (TrendHigh[1] > TrendLow[1]) && (ADXDiff[1] > level1 ) ) Trend = AscTrend;
   else if((TrendHigh[1] < TrendLow[1]) && (ADXDiff[1] < level2 )) Trend = DesTrend;
   else Trend = SideTrend;
        
   double SignalHigh[], SignalLow[];
   ArraySetAsSeries(SignalHigh, true);
   ArraySetAsSeries(SignalLow, true);
   CopyBuffer(SignalHandle, 0, 0, 3, SignalHigh );
   CopyBuffer(SignalHandle, 1, 0, 3, SignalLow );
   
   if(SignalHigh[1] > SignalLow[1]) TradeSignal = BuySignal;
   else TradeSignal = SellSignal;
   
}

//==============================================================================
void GetPositionTickets()
{
	Positions.GetBuyTickets(MagicNumber, buyTickets);
	Positions.GetSellTickets(MagicNumber, sellTickets);
	Positions.GetTickets(MagicNumber, Tickets);

	if(buyTickets[0] == 0 ) numBuyTickets = 0;
	else numBuyTickets = ArraySize(buyTickets);

	if(sellTickets[0] == 0 ) numSellTickets = 0;
	else numSellTickets = ArraySize(sellTickets);

	if(Tickets[0] == 0 ) numTickets = 0;
	else numTickets = ArraySize(Tickets);

}


//==============================================================================
void SetTrailingStop()
{
   
   //ATR channel indicator
   double highATR[], lowATR[];
   ArraySetAsSeries(highATR, true);
   ArraySetAsSeries(lowATR, true);
   CopyBuffer(ATRHandle, 1, 0, 3, highATR);
   CopyBuffer(ATRHandle, 2, 0, 3, lowATR);
   double tempShortTrailPrice = highATR[1];
   double tempLongTrailPrice = lowATR[1];
   
   // Long position Trailing Stop reset
   if(numBuyTickets >=1){ if(tempLongTrailPrice > longTrailPrice) longTrailPrice = tempLongTrailPrice; }
   else longTrailPrice = 0.;
   
   // Short position Trailing stop reset
   if(numSellTickets >= 1) { if(tempShortTrailPrice < shortTrailPrice) shortTrailPrice = tempShortTrailPrice; }
   else shortTrailPrice = 10000.;
   
}


//==============================================================================
void CheckTrailingStop()
{

   GetPositionTickets();
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   //Long Position Trailing-Stop
   if(numBuyTickets>=1 && bid < longTrailPrice) 
   { 
      for(int i = 0; i < numBuyTickets; i++) { Trade.Close(buyTickets[i]);} 
   }
   
   //Short Position Trailing-Stop
   if(numSellTickets>=1 && ask > shortTrailPrice) 
   { 
      for(int i = 0; i < numSellTickets; i++) { Trade.Close(sellTickets[i]); } 
   }

   GetPositionTickets();
   
}



