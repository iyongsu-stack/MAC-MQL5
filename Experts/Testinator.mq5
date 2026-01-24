//+------------------------------------------------------------------+
//|                                                   Testinator.mq5 |
//|                                                           Savoon |
//|                                           https://www.savoon.com |
//+------------------------------------------------------------------+
// =========================== Change Control ========================
// [Version 1.20] Added Average Bars for Trade to complete to OnTester Results
// [Version 1.20] Moved "SET HANDLE ASSIGNMENTS" for indexed scenarios inside the index loops, not in OnInit, as it will calc all if in OnInit
// [Version 1.30] Added Trading Hour Start and Duration
// Need Stop Loss / Take Profit / Trailing as a Net!

#property copyright "Copyright 2019, Savoon."
#property link      "https://www.savoon.com"
//#property version   "1.30a"

extern int           MagicNum =  123456;

extern double        Lots = 0.01;              // Strictly set amount of lots
extern int           Slip = 3;                 // Slip
extern int           LotsDigits=2;  

input group           "Trade Sequence for Buy and Close Buy"
input int            BuySequence = 256;   // Buy Sequence [Positive Integers 0 or 1..X]
input int            CloseBuySeq = 276;   // Close Buy Sequence [Positive Integers 0 or 1..Y]

input group           "Maximum Concurrent Deals & Step in PIPs"
input int            MaxBuys =     3;    // Max # of Open Buy Positions
input int            steps = 15;         // Steps in PIPs between Buys

input group          "Trading Hours EET - Set to 0 and 23 to trade all hours."
input int            Trade_Start = 16;    // Start of Trading Cycle Eastern European Time
input int            Trade_Duration = 2;  // Duration of Trading Cycle Eastern European Time
  // ====================================    The data in Tester is in Eastern Eropean Time
  // ====================================    Trading Week/Day Starts from 00:00 on Monday to 23:59 on Friday Eastern European Time
  // ====================================    This translates to 17:00 on Sunday to 16:59 on Friday Eastern Standard Time
  // ====================================    This is a Standard in the Forex Industry, and All Bar Data is reported as EET
  //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
input group             "Take Profit, Stop Loss and Trailing"
input bool              TakeAsBasket = false; // Set TakeProfit at level of all open trades
input bool              StopAsBasket = false; // Set StopLoss at level of all open trades
double NewSL, NewTP, AveragePrice;
input double            TakeProfit = -1;  // Take Profit Set to 0 to use Ratio as Set by ATR or -1 to disable
double Take;
input double            StopLoss = -1;   // Stop Loss Set to 0 to use Ratio as Set by ATR or -1 to disable
double Stop;
input double            StartTrail = -1;  // Stop Loss Set to 0 and Start Trailig Set to 0 to use Ratio as Set by ATR or -1 to disable
input double            StopStep = -1;    // Stop Step - Set to 0 to use Ratio Set by ATR or -1 to disable
double Step;
input group             "Take Profit and Stop Loss Ratios to Daily ATR"
input double TakeRatio = 0.0;        // Ratio of Daily ATR to set Take Profit - if TakeProfit = 0
input double StopRatio = 0.0;        // Ratio of Daily ATR to set Stop Loss  -  if StopLoss = 0
input double StartTrailRatio = 0.0;  // Ratio of Daily ATR to set Start Trailing  -  if StopLoss = 0
input double StopStepRatio = 0.0;    // Ratio of Daily ATR to set Trailing SL - if StopStep = 0
  //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  
  
input group             "Individual Indicator Parameters"
input double RSI_X_Entry = 70;      // RSI_X_Entry
input int RSI_P_Entry = 14;      // RSI_P_Entry

input double RSI_X_Close = 40;      // RSI_X_Close
input int RSI_P_Close = 10;      // RSI_P_Close

input int Bol_P_Close = 26;      // Bol_P_Close
input int Bol_Dev_Close = 2;     // Bol_Dev_Close



  //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


double Profit = 0;
double LastPrice = 0.0;
static double dBid_Price;  // The BID price.
static double dAsk_Price;  // The ASK price.  
double BuyLots, SellLots;
int BuyTrades, SellTrades;
double Price;
double Pips;              // === Pips for this Symbol
double MinLot;
string symbol;
int ticket;               // === Ticket #'s for Buy/Sell
datetime LastActiontime;  // === For Bars
int BarCount=0;



//===================================================================================================================
int BolBandsHandle;        // Bollinger Bands handle
double BBUp[];             // dynamic arrays for numerical values of Bollinger Bands
double BBDn[];             // dynamic arrays for numerical values of Bollinger Bands
int MA_handle;           // handle of the indicator iMA
double MA[];                // array for the indicator iMA
int EMA_handle;           // handle of the indicator iMA
double EMA[];                // array for the indicator iMA
int EMALong_handle;           // handle of the indicator iMA
double EMALong[];                // array for the indicator iMA
int ADX_handle;           // handle of the indicator iADX
double ADX[];                // array for the indicator iADX
double ADXPDi[];                // array for the indicator iADX
double ADXMDi[];                // array for the indicator iADX
int RSI_handle;           // handle of the indicator Relative Strength
double RSI[];                // array for the indicator Relative Strength
int STOCH_handle;           // handle of the indicator Stoch
double STOCHk[];                // array for the indicator Stoch
double STOCHd[];                // array for the indicator Stoch
int WPR_handle;           // handle of the indicator WPR
double WPR[];                // array for the indicator WPR
int MACD_handle;          // handle of the indicator WPR
double MACDMain[];           // array for MAIN_LINE of iMACD
double MACDSignal[];         // array for SIGNAL_LINE of iMACD
int Ichimoku_handle;     // handle of the indicator Ichimoku
double Ichimoku_tenkansen[]; // array for tenkansen of iIchimoku
double Ichimoku_kijunsen[];  // array for kijunsen of iIchimoku
double Ichimoku_spanA[];  // array for kijunsen of iIchimoku
double Ichimoku_spanB[];   // array for chikou of iIchimoku
int sth_handle;          // handle for Super Trend Hull
double sth[];              // array for Super Trend Hull
int bqn_handle;          // handle for BPNNMQLPredictor  [VERY PROCESSOR INTENSIVE]
double bqn[];              // array for BPNNMQLPredictor [VERY PROCESSOR INTENSIVE]
int AvgTrend;            // handle for Average Trend
double AvgT[];             // array for Average Trend
int PTL;            // handle for Perfect Trend Line
double PTLb[];             // array for Perfect Trend Line
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(TerminalInfoInteger(TERMINAL_MEMORY_PHYSICAL)<2048)  return(INIT_AGENT_NOT_SUITABLE); // No testing on Cloud Servers less than 2Gb
   if ((BuySequence>511) || (CloseBuySeq>511)) {
       Alert("Sequences Greater that 511, are you sure??"); Print("Sequences Greater that 511, are you sure??");
       ExpertRemove();
   }
   Pips = _Point; // To verify minimum amount required, verify locally with OnDeinit results.
   symbol = Symbol();
   double spread=SymbolInfoDouble(symbol,SYMBOL_ASK)-SymbolInfoDouble(symbol,SYMBOL_BID);
   double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   long digits=SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   string str_spread=DoubleToString(spread/point,0);
   //--- display data
   Print(symbol," spread=",str_spread," points.");
   Print("Running BuySequence ",BuySequence," and CloseBuySequence ",CloseBuySeq);
   MinLot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   if (Lots < MinLot) Lots=MinLot; // Set Min Lots
   if (CheckMoneyForTrade(symbol,Lots,ORDER_TYPE_BUY)!=true) { Print("Not enough money to open trades or Error!"); }

   // Pre Condition Definitions Go Here.
   // If not using an Indicator, you should comment out, as the EA will always process as long as Handle assigned to Indicator.
   //sth_handle=iCustom(NULL,PERIOD_CURRENT,"super_trend_hull.ex5", 12, PRICE_MEDIAN, 12, 0.66);
   //bqn_handle=iCustom(NULL,PERIOD_CURRENT,"BPNNMQLPredictorDemo.ex5", 0,10,6,3,12,5,1,0,0,0,500,1000,-20,2);
   //AvgTrend=iCustom(NULL,PERIOD_CURRENT,"Average trend (mtf).ex5", PERIOD_CURRENT, 35, MODE_EMA, PRICE_CLOSE, 1.05, false);
   //PTL=iCustom(NULL,PERIOD_CURRENT,"PTL (2).ex5", 3, 7);
   ArraySetAsSeries(ADX,true); ArraySetAsSeries(ADXPDi,true); ArraySetAsSeries(ADXMDi,true);
   ArraySetAsSeries(BBDn,true);
   ArraySetAsSeries(BBUp,true);
   ArraySetAsSeries(EMA,true);
   ArraySetAsSeries(EMALong,true);
   ArraySetAsSeries(Ichimoku_tenkansen,true); ArraySetAsSeries(Ichimoku_kijunsen,true); ArraySetAsSeries(Ichimoku_spanA,true);  ArraySetAsSeries(Ichimoku_spanB,true);
   ArraySetAsSeries(MA,true);
   ArraySetAsSeries(MACDMain,true); ArraySetAsSeries(MACDSignal,true);
   ArraySetAsSeries(RSI,true);  
   ArraySetAsSeries(STOCHd,true);
   ArraySetAsSeries(STOCHk,true);
   ArraySetAsSeries(WPR,true);
   //ArraySetAsSeries(sth,true);
   //ArraySetAsSeries(bqn,true);
   //ArraySetAsSeries(AvgT,true);
   //ArraySetAsSeries(PTLb,true);
   //--- Initialize the generator of random numbers
   MathSrand(GetTickCount()^(uint)ChartID());
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  IndicatorRelease(BolBandsHandle);
  IndicatorRelease(MA_handle);
  IndicatorRelease(EMA_handle);
  IndicatorRelease(EMALong_handle);  
  IndicatorRelease(ADX_handle);
  IndicatorRelease(RSI_handle);
  IndicatorRelease(STOCH_handle);
  IndicatorRelease(WPR_handle);
  IndicatorRelease(MACD_handle);
  IndicatorRelease(Ichimoku_handle);
  //IndicatorRelease(sth_handle);
  //IndicatorRelease(bqn_handle);
  //IndicatorRelease(AvgTrend);
  //IndicatorRelease(PTL);
  Print("Used ",TerminalInfoInteger(TERMINAL_MEMORY_USED)," Mb of memory"); // Memory Required for Testing
  }
  
double OnTester() // ================ Return CSTS value ===========
{  // https://www.mql5.com/en/docs/constants/environment_state/statistics
   //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   // *If the CSTS value is less than 1, the trading system is in the zone of high trade risk; even smaller values
   // *indicate the zone of unprofitable trading. The greater is the value of CSTS, the better the trade system fits the market and the profitable it is.
   // =============================================================================================================================================
   //if (TesterStatistics(STAT_PROFIT_TRADES)==0 || TesterStatistics(STAT_LOSS_TRADES)==0 || TesterStatistics(STAT_TRADES)==0) { return(0); }
   //double  avg_win = TesterStatistics(STAT_GROSS_PROFIT) / TesterStatistics(STAT_PROFIT_TRADES);
   //double  avg_loss = -TesterStatistics(STAT_GROSS_LOSS) / TesterStatistics(STAT_LOSS_TRADES);
   //double  win_perc = 100.0 * TesterStatistics(STAT_PROFIT_TRADES) / TesterStatistics(STAT_TRADES);
   // * Calculated safe ratio for this percentage of profitable deals:
   //if ((win_perc - 10.0)==0) { return(0); }
   //double  teor = (110.0 - win_perc) / (win_perc - 10.0) + 1.0;
   // * Calculate real ratio:
   //double  real = avg_win / avg_loss;
   // * CSTS:
   //double  tssf = real / teor;
   //return(NormalizeDouble(tssf,2));
   // ================================================================================================================================================

   // * Return average Bars to Close a Trade - 1 to 60 Hours is average Range, with 24 hours being about Normal.
   double tot_trades = TesterStatistics(STAT_TRADES);
   if (tot_trades>0)  { return(NormalizeDouble(BarCount/tot_trades,1)); } // Return avg Bar Count length for a Trade!
     else { return(0); }
}  
  
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(Bars(_Symbol,_Period)<200) // if total bars is less than 60 bars
     {
      Alert("We have less than 200 bars, EA will now exit!!");
      return;
     }  
  MqlDateTime dt_struct;
  TimeToStruct(TimeCurrent(), dt_struct);
  
  if (StopStep >=0) // We're processing Trailing on every tick
  {
     if (StopStep==0 && StopStepRatio>0) { Step = ATR_Daily() * StopStepRatio; } else { Step=StopStep; } // Setup Trailing Step
     double stop_level=(int)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL); // Minimal SL/TP in Points that can be set according to Broker
     if (Step < stop_level) { Step = stop_level; } // Our StopStep is larger than minimum allowed, else use minimum allowed
     Step = MathRound(Step/2)*2;
     Trailing(); // With Step in PIPs
   }
  
  
  if((LastActiontime!=iTime(symbol,Period(),0))){ // =========================== Begin OF BAR, Not Processed Yet======================

  //if (CheckMoneyForTrade(symbol,Lots,ORDER_TYPE_BUY)==false) ExpertRemove();
  CheckOpenTrades();
  //================================== Trade in Trading Hours for Duration
  if ((dt_struct.hour<Trade_Start) || (dt_struct.hour > Trade_Start+Trade_Duration-1)) {  
        //Print("Time outside of trading window. Current Hour is ",dt_struct.hour," EET.");
        if (Profit>0) CloseAll(ORDER_TYPE_SELL); // Close out baskets if profitable
        if (Profit>0) CloseAll(ORDER_TYPE_BUY);
        LastActiontime=iTime(symbol,Period(),0); // Set that this Bar has been Processed :-)
        return;   // Don't trade anymore if out of trade time, and close profitable trades.
      }
      else
      {
       //Print("Time inside of trading window. Current Hour is ",dt_struct.hour," EET.");
      }
      
  //Print("Profit = ",Profit," Open Buys = ",BuyTrades, " Lots = ",BuyLots);
  if(BuyTrades==0) { LastPrice=0.0;  } // Used for Trailing Step
  if(BuyTrades!=0) { BarCount=BarCount+BuyTrades; } // Used for Average Bars to Close Calculation


  //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  if (StopLoss>=0)  // We're Processing a Stop Loss
  {
     if (StopLoss==0) { Stop = ATR_Daily() * StopRatio; } else { Stop = StopLoss; }
     if (StopLoss==-1) Stop=0;
  }
  if (TakeProfit>=0) // We're Processing a Take Profit
  {
     if (TakeProfit==0) { Take = ATR_Daily() * TakeRatio; } else { Take = TakeProfit; }
     if (TakeProfit==-1) Take=0;
  }
  //Print("ATR Daily Levels: Take Profit= ",TakeProfit," and Stop Loss=",Stop," and StopStep =",StopStep );  
  //=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  
  if ( (BuyTrades < MaxBuys) && ((Price-LastPrice)/Pips >= steps) && (DoBuy(BuySequence) == true) && (CheckMoneyForTrade(symbol,Lots,ORDER_TYPE_BUY)==true)) {  // =========== Begin of Do Buy Sequence ==========
      //Print("Price - LastPRice = ",(Price-LastPrice)/Pips);
      MqlTradeRequest request; ZeroMemory(request);
      MqlTradeResult result; ZeroMemory(result);
      request.action = TRADE_ACTION_DEAL;
      request.type = ORDER_TYPE_BUY;
      request.symbol = _Symbol;
      request.volume = Lots;
      request.type_filling = ORDER_FILLING_FOK;
      request.tp = 0;
      request.sl = 0;      
      request.comment = IntegerToString(BuySequence,0,0)+"|"+IntegerToString(CloseBuySeq,0,0);
      bool buyPositionIsOpen = false;
      request.magic = MagicNum;
      request.price = NormalizeDouble(dAsk_Price,_Digits);
      Print("============= StartBuy =================");
      ticket=OrderSend(request,result);

      if(result.retcode==10009 || result.retcode==10008) //Request is completed or order placed
           {
            Print("============== EndBuy now has Ticket:",result.deal," =============");
            buyPositionIsOpen = true;  LastPrice = NormalizeDouble(dAsk_Price,_Digits); CheckOpenTrades();  SetLimits();
           }
         else
           {
            Print("The Buy order request could not be completed -error:",GetLastError());
            ResetLastError();          
            return;
           }
      
      } // ================================== End of DoBuySequence ================================================
if ( (BuyTrades > 0) && (DoBuyClose(CloseBuySeq) == true) )
     {
      CloseAll(POSITION_TYPE_BUY);
      //Print("Closing all ",BuyTrades," trades on Signal!");
     } // Simple Close Sequence

  
  //Print("Current Time is ",TimeToString(TimeCurrent(),TIME_SECONDS)," and Min = ",dt_struct.min," Ticks = ",MinutesData[dt_struct.min]," Price = ",Price);  
  LastActiontime=iTime(symbol,Period(),0);
  } // ========================================================================== End OF BAR =======================
  
  
  }
//+------------------------------------------------------------------+

void Drop_Dot(string name, string Col, double area) // For Visual Testing
  {

   name = name + ":" + TimeToString(TimeCurrent(),TIME_SECONDS);
   ObjectCreate(0,name,OBJ_TEXT,0,iTime(symbol,Period(),0),area);
   ObjectSetString(0,name,OBJPROP_TEXT,CharToString(108));
   ObjectSetString(0,name,OBJPROP_FONT,"WingDings");
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,16);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ChartRedraw(0);
   //Print("Dropping Dot :",area," at ",iTime(symbol,Period(),0));
  }


bool DoBuy(int type) // 4 will count 1,2,3,4
{  
   bool GoAhead = true; // Assume true, unless proved false by only 1 (turn the lightbulb on!)
   MqlRates rates[]; // Needed detailed Bar Info
   ArraySetAsSeries(rates,true);
   CopyRates(Symbol(),PERIOD_CURRENT,0,100,rates); //  rates[1].close = bar 1 close price
   // DO NOT SET HANDLE ASSIGNMENTS TO PRE-CONDITIONS HERE!!! SET THE ASSIGNMENTS IN THE OnInit
   //if(CopyBuffer(sth_handle,1,0,1,sth)<0) { Print("Fing Error copying indicator Buffers - error:",GetLastError(),"!!"); }
   //if (!( sth[0]==0   ))  { GoAhead = false; Print("|Woops, didn't meet pre-condition"); } else { Print("|Pre-Condition met."); } // Didn't meet Base Pre-Condition!!!
   //if(CopyBuffer(bqn_handle,0,0,1,bqn)<0) { Print("Fing Error copying indicator Buffers - error:",GetLastError(),"!!"); }
   //if (!( bqn[0]>rates[1].high   ))  { GoAhead = false; Print("|Woops, didn't meet pre-condition"); } else { Print("|Pre-Condition met."); } // Didn't meet Base Pre-Condition!!!
   //if(CopyBuffer(AvgTrend,3,1,1,AvgT)<0) { Print("Fing Error copying indicator Buffers - error:",GetLastError(),"!!"); }
   //if (!( AvgT[0]>0   ))  { GoAhead = false; Print("|Woops, didn't meet pre-condition"); } else { Print("|Pre-Condition met."); } // Didn't meet Base Pre-Condition!!!
   //CopyBuffer(PTL,buffer,start,count,array);


   //if(CopyBuffer(PTL,8,0,1,PTLb)<0) { Print("Fing Error copying indicator Buffers - error:",GetLastError(),"!!"); }
   //if (!( PTLb[0]==0   ))  GoAhead = false;  // Didn't meet Base Pre-Condition!!!
   //if (!( MathRand()>=13684   ))  GoAhead = false;  // Didn't meet Base Pre-Condition!!!
   //if (GoAhead == true) Drop_Dot("Ha","0,0,255",rates[1].high);
  
  
  
   if (GoAhead==false) return(false); // If Failed Pre-Conditions, return
   for(int c=1;c<=type;c++)
   {
     int A = c; int B = type;
     int result = A&B;
     if (c==result) { //AND the two and it's a match... for Binary !!!
      switch(c)
         {
           case 1: { // Test 0 or 1 to 1
              //Print("|Trying 1");
              MA_handle=iMA(NULL,0,14,0,MODE_SMA,PRICE_CLOSE); // Red
              EMA_handle=iMA(NULL,0,12,0,MODE_EMA,PRICE_CLOSE); // Yellow
              if(CopyBuffer(MA_handle,0,0,100,MA)<=0) { Print("Error copying MA indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(EMA_handle,0,0,100,EMA)<=0) { Print("Error copying MA indicator Buffers - error:",GetLastError(),"!!"); }
              if (!(EMA[0]>MA[0] )  )  { GoAhead = false;  }
              //if (!(EMA[0]>MA[0] )  )  { GoAhead = false; Print("Failed"); } else {  Drop_Dot("MA","255,0,255",rates[1].low); Print("Passed"); }
              }
              break;
           case 2: { // Test 0 or 1 to 3
              //Print("|Trying 2");
              EMALong_handle=iMA(NULL,0,50,0,MODE_EMA,PRICE_CLOSE); // Green
              if(CopyBuffer(EMALong_handle,0,0,100,EMALong)<=0) { Print("Error copying MA indicator Buffers - error:",GetLastError(),"!!"); }
              if (!( (EMALong[0]<rates[1].low) && (EMALong[0]<rates[2].low) && (EMALong[0]<rates[3].low)  ))   { GoAhead = false;  }
              }
              break;
           case 4: { // Test 0 or 1 to 7
              //Print("|Trying 4");
              BolBandsHandle=iBands(NULL,PERIOD_CURRENT,20,0,2,PRICE_CLOSE);
              if(CopyBuffer(BolBandsHandle,1,0,3,BBUp)<0) { Print("Error copying Bollinger Bands indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(BolBandsHandle,2,0,3,BBDn)<0) { Print("Error copying Bollinger Bands indicator Buffers - error:",GetLastError(),"!!"); }
              if (!(rates[1].low < BBDn[1] )  )  { GoAhead = false;  }      
              }
              break;
           case 8: { // Test 0 or 1 to 15
              //Print("|Trying 8");
              ADX_handle=iADX(NULL,PERIOD_CURRENT,14);
              if(CopyBuffer(ADX_handle,0,0,3,ADX)<=0) { Print("Fing Error copying ADX indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(ADX_handle,1,0,3,ADXPDi)<=0) { Print("Fing Error copying ADX indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(ADX_handle,2,0,3,ADXMDi)<=0) { Print("Fing Error copying ADX indicator Buffers - error:",GetLastError(),"!!"); }
              if (!( (ADX[0]>ADXMDi[0]) && (ADXPDi[0] > ADXMDi[0])  ) )   { GoAhead = false;  }
              }
              break;
           case 16: { // Test 0 or 1 to 31
              //Print("|Trying 16");
              STOCH_handle=iStochastic(NULL,PERIOD_CURRENT,16,4,8,MODE_SMA,1);
              if(CopyBuffer(STOCH_handle,MAIN_LINE,0,3,STOCHk)<=0) { Print("Fing Error copying STOCH indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(STOCH_handle,SIGNAL_LINE,0,3,STOCHd)<=0) { Print("Fing Error copying STOCH indicator Buffers - error:",GetLastError(),"!!"); }
              if (!(   (STOCHk[0] > STOCHd[0]) && (STOCHd[0]>80)    ))   { GoAhead = false;  }  
              }
              break;
           case 32: { // Test 0 or 1 to 63
              //Print("|Trying 32");
              WPR_handle=iWPR(NULL,PERIOD_CURRENT,14);
              if(CopyBuffer(WPR_handle,0,0,3,WPR)<=0) { Print("Fing Error copying WPR indicator Buffers - error:",GetLastError(),"!!"); }
              if (!(WPR[0]>-20.0 )  )   { GoAhead = false;  }
              }
              break;
           case 64: { // Test 0 or 1 to 127
              //Print("|Trying 64");
              MACD_handle=iMACD(NULL,PERIOD_CURRENT,12, 26,9,PRICE_CLOSE);
              if(CopyBuffer(MACD_handle,0,0,1,MACDMain)<0) { Print("Fing Error copying MACD Main indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(MACD_handle,1,0,1,MACDSignal)<0) { Print("Fing Error copying MACD Signal indicator Buffers - error:",GetLastError(),"!!"); }              
              if (!(MACDMain[0]>MACDSignal[0] )  )   { GoAhead = false;  }
              }
              break;
           case 128: { // Test 0 or 1 to 255
              //Print("|Trying 128");  
              Ichimoku_handle = iIchimoku(NULL,PERIOD_CURRENT,9,26,52);
              if(CopyBuffer(Ichimoku_handle,0,0,1,Ichimoku_tenkansen)<0) { Print("Fing Error copying Ichimoku_tenkansen indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(Ichimoku_handle,1,0,1,Ichimoku_kijunsen)<0) { Print("Fing Error copying Ichimoku_kijunsen indicator Buffers - error:",GetLastError(),"!!"); }              
              if(CopyBuffer(Ichimoku_handle,2,0,1,Ichimoku_spanA)<0) { Print("Fing Error copying Ichimoku_kijunsen indicator Buffers - error:",GetLastError(),"!!"); }          
              if(CopyBuffer(Ichimoku_handle,3,0,1,Ichimoku_spanB)<0) { Print("Fing Error copying Ichimoku_kijunsen indicator Buffers - error:",GetLastError(),"!!"); }              
              if (!( (Ichimoku_spanA[0] > Ichimoku_spanB[0]) && (Ichimoku_tenkansen[0]>Ichimoku_kijunsen[0]) && (rates[1].low> Ichimoku_spanA[0]) ))  { GoAhead = false;  }  
              }
              break;
           case 256: { // Test 0 or 1 to 511
              //Print("|Trying 256");
              RSI_handle = iRSI(NULL,PERIOD_CURRENT,RSI_P_Entry,PRICE_CLOSE); // iRSI(NULL,PERIOD_CURRENT,14,PRICE_CLOSE);
              if(CopyBuffer(RSI_handle,0,0,2,RSI)<0) { Print("Fing Error copying RSI indicator Buffers - error:",GetLastError(),"!!"); }              
              if (!( (RSI[0]>RSI_X_Entry) && (RSI[0]>RSI[1])  ))   { GoAhead = false;  }
              }
              break;

         }    
       }
     if (GoAhead == false ) break; // Fuse Already Blown :-(
   }
   return(GoAhead);
}



bool DoBuyClose(int type) // 4 will count 1,2,3,4
{  
   bool GoAhead = true; // Assume true, unless proved false by only 1 (turn the lightbulb on!)
   MqlRates rates[]; // Needed detailed Bar Info
   ArraySetAsSeries(rates,true);
   CopyRates(Symbol(),PERIOD_CURRENT,0,100,rates); //  rates[1].close = bar 1 close price, rates[0].high = current bar high
   // DO NOT SET HANDLE ASSIGNMENTS TO PRE-CONDITIONS HERE!!! SET THE ASSIGNMENTS IN THE OnInit
   //Print("|Trying Pre-Condition for Close of Buys");
   //if(CopyBuffer(Ichimoku_handle,0,0,1,Ichimoku_tenkansen)<0) { Print("Fing Error copying Ichimoku_tenkansen indicator Buffers - error:",GetLastError(),"!!"); }
   //if(CopyBuffer(Ichimoku_handle,1,0,1,Ichimoku_kijunsen)<0) { Print("Fing Error copying Ichimoku_kijunsen indicator Buffers - error:",GetLastError(),"!!"); }              
   //if(CopyBuffer(Ichimoku_handle,2,0,1,Ichimoku_spanA)<0) { Print("Fing Error copying Ichimoku_kijunsen indicator Buffers - error:",GetLastError(),"!!"); }          
   //if(CopyBuffer(Ichimoku_handle,3,0,1,Ichimoku_spanB)<0) { Print("Fing Error copying Ichimoku_kijunsen indicator Buffers - error:",GetLastError(),"!!"); }              
   //if (!( (Ichimoku_spanA[0] < Ichimoku_spanB[0]) && (Ichimoku_tenkansen[0] < Ichimoku_kijunsen[0]) && (rates[98].low > Ichimoku_kijunsen[0]) )  )  { GoAhead = false; Print("|Woops, didn't meet pre-condition"); } else { Print("|Pre-Condition met."); } // Didn't meet Base Pre-Condition!!!

   //if(CopyBuffer(sth_handle,1,0,1,sth)<0) { Print("Fing Error copying indicator Buffers - error:",GetLastError(),"!!"); }
   //if (!( sth[0]==1   ))  { GoAhead = false; Print("|Woops, didn't meet pre-condition"); } else { Print("|Pre-Condition met."); } // Didn't meet Base Pre-Condition!!!
   //if(CopyBuffer(bqn_handle,0,0,1,bqn)<0) { Print("Fing Error copying indicator Buffers - error:",GetLastError(),"!!"); }
   //if (!( bqn[0]<rates[0].low   ))  { GoAhead = false; Print("|Woops, didn't meet pre-condition"); } else { Print("|Pre-Condition met."); } // Didn't meet Base Pre-Condition!!!
   //if(CopyBuffer(AvgTrend,3,0,1,AvgT)<0) { Print("Fing Error copying indicator Buffers - error:",GetLastError(),"!!"); }
   //if (!( AvgT[0]<0   ))  { GoAhead = false; Print("|Woops, didn't meet pre-condition"); } else { Print("|Pre-Condition met."); } // Didn't meet Base Pre-Condition!!!


   if (GoAhead==false) return(false); // If Failed Pre-Conditions, return

   for(int c=1;c<=type;c++)
   {
     int A = c; int B = type;
     int result = A&B;
     if (c==result) { //AND the two and it's a match... for Binary !!!
      switch(c)
         {
           case 1: {
              //Print("|Trying Close 1");
              MA_handle=iMA(NULL,0,14,0,MODE_SMA,PRICE_CLOSE); // Red
              EMA_handle=iMA(NULL,0,12,0,MODE_EMA,PRICE_CLOSE); // Yellow
              if(CopyBuffer(MA_handle,0,0,100,MA)<=0) { Print("Error copying MA indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(EMA_handle,0,0,100,EMA)<=0) { Print("Error copying MA indicator Buffers - error:",GetLastError(),"!!"); }
              if (!(MA[0] > EMA[0] )  )   { GoAhead = false;  }
              }
              break;
           case 2: { // HERE = 1
              //Print("|Trying 2");
              EMALong_handle=iMA(NULL,0,50,0,MODE_EMA,PRICE_CLOSE); // iMA(NULL,0,50,0,MODE_EMA,PRICE_CLOSE);
              if(CopyBuffer(EMALong_handle,0,0,100,EMALong)<=0) { Print("Error copying MA indicator Buffers - error:",GetLastError(),"!!"); }
              if (!( (EMALong[0]>rates[1].high) && (EMALong[0]>rates[2].high) && (EMALong[0]>rates[3].high)  ))   { GoAhead = false;  }
              }
              break;
           case 4: { // HERE = 2
              //Print("|Trying Close 4");
              BolBandsHandle=iBands(NULL,PERIOD_CURRENT,Bol_P_Close,0,Bol_Dev_Close,PRICE_CLOSE); //iBands(NULL,PERIOD_CURRENT,20,0,2,PRICE_CLOSE);
              if(CopyBuffer(BolBandsHandle,1,0,3,BBUp)<0) { Print("Error copying Bollinger Bands indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(BolBandsHandle,2,0,3,BBDn)<0) { Print("Error copying Bollinger Bands indicator Buffers - error:",GetLastError(),"!!"); }
              if (!(rates[1].high > BBUp[1] )  )   { GoAhead = false;  }      
              }
              break;
           case 8: {
              //Print("|Trying Close 8");
              ADX_handle=iADX(NULL,PERIOD_CURRENT,14);
              if(CopyBuffer(ADX_handle,0,0,3,ADX)<=0) { Print("Fing Error copying ADX indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(ADX_handle,1,0,3,ADXPDi)<=0) { Print("Fing Error copying ADX indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(ADX_handle,2,0,3,ADXMDi)<=0) { Print("Fing Error copying ADX indicator Buffers - error:",GetLastError(),"!!"); }
              if (!( ADXMDi[0]>ADXPDi[0] ) )  { GoAhead = false;  }
              }
              break;
           case 16: { // Here = 3
              //Print("|Trying Close 16");
              STOCH_handle=iStochastic(NULL,PERIOD_CURRENT,16,4,8,MODE_SMA,1);
              if(CopyBuffer(STOCH_handle,MAIN_LINE,0,3,STOCHk)<=0) { Print("Fing Error copying STOCH indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(STOCH_handle,SIGNAL_LINE,0,3,STOCHd)<=0) { Print("Fing Error copying STOCH indicator Buffers - error:",GetLastError(),"!!"); }
              if (!( STOCHd[0]<80  ))   { GoAhead = false;  }  
              }
              break;
           case 32: {
              //Print("|Trying Close 32");
              WPR_handle=iWPR(NULL,PERIOD_CURRENT,14);
              if(CopyBuffer(WPR_handle,0,0,3,WPR)<=0) { Print("Fing Error copying WPR indicator Buffers - error:",GetLastError(),"!!"); }
              if (!(WPR[0]<-80.0 )  )  { GoAhead = false;  }
              }
              break;
           case 64: {
              //Print("|Trying Close 64");
              MACD_handle=iMACD(NULL,PERIOD_CURRENT,12, 26,9,PRICE_CLOSE);
              if(CopyBuffer(MACD_handle,0,0,1,MACDMain)<0) { Print("Fing Error copying MACD Main indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(MACD_handle,1,0,1,MACDSignal)<0) { Print("Fing Error copying MACD Signal indicator Buffers - error:",GetLastError(),"!!"); }              
              if (!(MACDMain[0]<MACDSignal[0] )  )   { GoAhead = false;  }  
              }
              break;
           case 128: { // Here = 3
              //Print("|Trying Close 128");
              Ichimoku_handle = iIchimoku(NULL,PERIOD_CURRENT,9,26,52); //iIchimoku(NULL,PERIOD_CURRENT,9,26,52);
              if(CopyBuffer(Ichimoku_handle,0,0,1,Ichimoku_tenkansen)<0) { Print("Fing Error copying Ichimoku_tenkansen indicator Buffers - error:",GetLastError(),"!!"); }
              if(CopyBuffer(Ichimoku_handle,1,0,1,Ichimoku_kijunsen)<0) { Print("Fing Error copying Ichimoku_kijunsen indicator Buffers - error:",GetLastError(),"!!"); }              
              if(CopyBuffer(Ichimoku_handle,2,0,1,Ichimoku_spanA)<0) { Print("Fing Error copying Ichimoku_kijunsen indicator Buffers - error:",GetLastError(),"!!"); }          
              if(CopyBuffer(Ichimoku_handle,3,0,1,Ichimoku_spanB)<0) { Print("Fing Error copying Ichimoku_kijunsen indicator Buffers - error:",GetLastError(),"!!"); }              
              if (!( Ichimoku_spanB[0] > Ichimoku_spanA[0]  ))  { GoAhead = false;  }  
              }
              break;
           case 256: { // Here = 1
              //Print("|Trying 256");
              RSI_handle = iRSI(NULL,PERIOD_CURRENT,RSI_P_Close,PRICE_CLOSE); //iRSI(NULL,PERIOD_CURRENT,14,PRICE_CLOSE);
              ArraySetAsSeries(RSI,true);  
              if(CopyBuffer(RSI_handle,0,0,2,RSI)<0) { Print("Fing Error copying RSI indicator Buffers - error:",GetLastError(),"!!"); }              
              if (!( (RSI[0]<RSI_X_Close)  ))   { GoAhead = false;  }   // RSI_X_Close = 40
              }
              break;
         }    
       }
     if (GoAhead == false ) break; // Fuse Already Blown :-(
   }
   return(GoAhead);
}


void CloseAll(int TypeOfTrade)
   {
   MqlTradeRequest request;
   MqlTradeResult  result;  
   int             total = PositionsTotal();
   for (  int i = total - 1; i >= 0; i-- )
    {
          ulong  position_ticket  = PositionGetTicket(       i );                               //  - ticket of the position
          string position_symbol  = PositionGetString(       POSITION_SYMBOL );                 //  - symbol
          int    digits           = (int) SymbolInfoInteger( position_symbol, SYMBOL_DIGITS );  //  - number of decimal places
          ulong  magic            = PositionGetInteger(      POSITION_MAGIC );                  //  - MagicNumber of the position
          double volume           = PositionGetDouble(       POSITION_VOLUME );                 //  - volume of the position
          ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE) PositionGetInteger( POSITION_TYPE );   //  - type of the position
          if (  magic == MagicNum && type == TypeOfTrade) {
            ZeroMemory( request );                                  //     .CLR data
            ZeroMemory( result  );                                  //     .CLR data
            request.action    = TRADE_ACTION_DEAL;                  //          - type of trade operation
            request.position  = position_ticket;                    //          - ticket of the position
            request.symbol    = position_symbol;                    //          - symbol
            request.volume    = volume;                             //          - volume of the position
            request.deviation = 5;                                  //          - allowed deviation from the price
            request.magic     = MagicNum;                           //          - MagicNumber of the position
            
            Print("============= Start Close =================");    
            PrintFormat( "Tkt[#%I64u] %s  %s  %.2f  %s MagNUM[%I64d] %s",    // .GUI:    print details about the position    
                       position_ticket,
                       position_symbol,
                       EnumToString(type),
                       volume,
                       DoubleToString( PositionGetDouble( POSITION_PRICE_OPEN ), digits ),
                       magic,
                       "Fuckin Close"
                       );
            
                if (  type == POSITION_TYPE_BUY  )
                {     request.price = SymbolInfoDouble( position_symbol, SYMBOL_BID );
                      request.type  = ORDER_TYPE_SELL;
                      }
                else
                {
                      request.price = SymbolInfoDouble( position_symbol, SYMBOL_ASK );
                      request.type  = ORDER_TYPE_BUY;
                      }

               // PrintFormat(       "WILL TRY: Close Tkt[#%I64d] %s %s",                      position_ticket,
               //                                                                              position_symbol,
               //                                                                              EnumToString( type )
               //                                                                                                 );
              
                                                    
                if ( !OrderSend( request,result ) )
                      PrintFormat( "INF:  OrderSend(Tkt[#%I64d], ... ) call ret'd error %d", position_ticket,
                                                                                             GetLastError()
                                                                                             );
                PrintFormat(       "INF:            Tkt[#%I64d] retcode=%u  deal=%I64u  order=%I64u", position_ticket,
                                                                                                      result.retcode,
                                                                                                      result.deal,
                                                                                                      result.order
                                                                                                         );
                Print("============== EndClose of Ticket:",position_ticket," as a result of Order:",result.order," ",PositionGetString(POSITION_COMMENT)," =============");
                

          } // End of Match for Magic Numbers
    } // ======= End of looping through trades
   } // ======== End of Close All Procedure
  
void  CheckOpenTrades() // Check all open orders
   {
    Profit = 0.0;
    AveragePrice = 0.0;
    SellTrades = 0; SellLots = 0.0;
    BuyTrades = 0; BuyLots = 0.0;
    MqlTick Latest_Price; // Structure to quickly get the latest bid/ask/volume      
    SymbolInfoTick(symbol ,Latest_Price); // Assign current prices to structure  
    dBid_Price = Latest_Price.bid;  // Current Bid price.
    dAsk_Price = Latest_Price.ask;  // Current Ask price.
    Price = ((dAsk_Price-dBid_Price)/2)+dBid_Price;
    for(int cnt=PositionsTotal()-1;cnt>=0;cnt--)
       {
          ulong  position_ticket  = PositionGetTicket(       cnt );                               //  - ticket of the position          
          string position_symbol  = PositionGetString(       POSITION_SYMBOL );                 //  - symbol
          ulong  magic            = PositionGetInteger(      POSITION_MAGIC );                  //  - MagicNumber of the position
          double volume           = PositionGetDouble(       POSITION_VOLUME );                 //  - volume of the position
          double OpPrice          = PositionGetDouble(       POSITION_PRICE_OPEN);
          double win              = PositionGetDouble(       POSITION_PROFIT);
          double swap             = PositionGetDouble(       POSITION_SWAP);
          //double comm             = PositionGetDouble(       POSITION_COMMISSION);          
          ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE) PositionGetInteger( POSITION_TYPE );   //  - type of the position
          if(position_symbol!=Symbol()||magic!=MagicNum) continue;
          if(position_symbol==Symbol() && magic==MagicNum) // This is our Ticket
              {
          
               Profit=Profit + win + swap; // What about Commission???
               AveragePrice=AveragePrice+OpPrice*volume;
               if(type==POSITION_TYPE_BUY) {

                      BuyTrades++; BuyLots=BuyLots+volume;  
                      }
               if (type==POSITION_TYPE_SELL) {
                      SellTrades++; SellLots=SellLots+volume;
                      }
              }
        }
     Profit = NormalizeDouble(Profit,2);
     SellLots = NormalizeDouble(SellLots,LotsDigits);
     BuyLots = NormalizeDouble(BuyLots,LotsDigits);
     if(BuyLots+SellLots > 0) AveragePrice=NormalizeDouble(AveragePrice/(BuyLots+SellLots), _Digits); // Lot Weighted Average Price of Positions
   }  

void SetLimits() // Set initial Take Profit and Stop Loss
  {
   //--- declare and initialize the trade request and result of trade request
   bool chg = false; double NewStop = 0.0; double NewTake = 0.0;
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // number of open positions  
//--- iterate over all open positions
   for(int i=0; i<total; i++)
     {
      //--- parameters of the order
      ulong  position_ticket=PositionGetTicket(i);// ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL); // symbol
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS); // number of decimal places
      ulong  magic=PositionGetInteger(POSITION_MAGIC); // MagicNumber of the position
      double volume=PositionGetDouble(POSITION_VOLUME);    // volume of the position
      double sl=PositionGetDouble(POSITION_SL);  // Stop Loss of the position
      double tp=PositionGetDouble(POSITION_TP);  // Take Profit of the position
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // type of the position
      if (magic!=MagicNum) continue;  
        
      //--- if the MagicNumber matches and requested Take Profit / Stop Loss is not yet defined
      if(magic==MagicNum && ((sl==0 && Stop!=0) || (tp==0 && Take!=0))) // Need to set initial Stop Loss
        {
         //--- calculate the current price levels
         //Print("|Modifying Stop Loss on Zero for ticket |",position_ticket,"|",i);
         double price=PositionGetDouble(POSITION_PRICE_CURRENT); // Current Price
         double price_o=PositionGetDouble(POSITION_PRICE_OPEN);  // Deal Open Price
         double bid=SymbolInfoDouble(position_symbol,SYMBOL_BID);
         double ask=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
         double  stop_level=(int)SymbolInfoInteger(position_symbol,SYMBOL_TRADE_STOPS_LEVEL); // Minimal SL/TP in Points that can be set according to Broker
         double  take_level=stop_level;
         //--- if the minimum allowed offset distance in points from the current close price is not set
         if (Stop > stop_level && Stop!=0) { stop_level=Stop; } else { Print("Minimum initial Stop Level Set or StopLoss=0!"); }  // set the intitial Stop Loss offset distance of x points from the current close price
         if (Take > take_level && Take!=0) { take_level=Take; } else { Print("Minimum initial Take Profit Level Set or TakeProfit=0!"); }
         //--- calculation and rounding of the Stop Loss values
         NewTake=take_level*SymbolInfoDouble(position_symbol,SYMBOL_POINT);
         NewStop=stop_level*SymbolInfoDouble(position_symbol,SYMBOL_POINT);
         if(type==POSITION_TYPE_BUY)
           {
             if (Stop!=0 ) { NewStop=NormalizeDouble(AveragePrice-NewStop,digits); chg = true; };
             if (Take!=0 ) { NewTake=NormalizeDouble(AveragePrice+NewTake,digits); chg = true; };            
            
           }
        }      
        
      if (magic==MagicNum && chg==true) // Change is needed, so modify the order
       {  
         //--- zeroing the request and result values
         //Print("New Stop = ",NewStop," and StopLoss = ",sl);
         ZeroMemory(request);
         ZeroMemory(result);
         //--- setting the operation parameters
         request.action  =TRADE_ACTION_SLTP; // type of trade operation
         request.position=position_ticket;   // ticket of the position
         request.symbol=position_symbol;     // symbol
         request.sl      =NewStop;           // Stop Loss of the position
         request.tp      =NewTake;           // Take Profit of the position
         request.magic=MagicNum;         // MagicNumber of the position
         //--- output information about the modification
         //PrintFormat("|SL Modify #%I64d %s %s",position_ticket,position_symbol,EnumToString(type),"|",i);
         //--- send the request
         if(!OrderSend(request,result))
            {
            PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
             //--- information about the operation  
            PrintFormat("|retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order,"|",i);
            }
       }
     } // End of Tickets
  }

void  Trailing() // Trail
  {
   //--- declare and initialize the trade request and result of trade request
   bool chg = false; double NewStop = 0.0; double NewTake = 0.0;
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // number of open positions  
   //--- iterate over all open positions
   for(int i=0; i<total; i++)
     {
      //--- parameters of the order
      ulong  position_ticket=PositionGetTicket(i);// ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL); // symbol
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS); // number of decimal places
      ulong  magic=PositionGetInteger(POSITION_MAGIC); // MagicNumber of the position
      double volume=PositionGetDouble(POSITION_VOLUME);    // volume of the position
      double sl=PositionGetDouble(POSITION_SL);  // Stop Loss of the position
      double tp=PositionGetDouble(POSITION_TP);  // Take Profit of the position
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // type of the position
      if (magic!=MagicNum) continue;
      if(magic==MagicNum && sl!=0 && Step!=0) // Stop Loss Set, adjust Traling Stop... but it does it for all Positions at the same level...
        {
         double price=PositionGetDouble(POSITION_PRICE_CURRENT); // Current Price
         double bid=SymbolInfoDouble(position_symbol,SYMBOL_BID); // Current Bid
         double ask=SymbolInfoDouble(position_symbol,SYMBOL_ASK); // Current Ask
         double price_level=bid-(Stop*SymbolInfoDouble(position_symbol,SYMBOL_POINT)); // What the Current Stop would be
         //Print("Trying to Adjust Trailing...... Current Stop = ",sl," Target = ",price_level," Step = ",Step );
         if(type==POSITION_TYPE_BUY && price_level>sl+Step*SymbolInfoDouble(position_symbol,SYMBOL_POINT))
           { //Print("|Modifying Stop Loss on trailing for ticket |",position_ticket,"|",i);
             //Print("Informational... |",price,"|",bid,"|",ask,"|",price_level,"|",sl,"|");
             NewStop=NormalizeDouble(price_level,digits); chg=true; } // For Buy Orders
        }        
        
      if (magic==MagicNum && chg==true && NewStop !=sl) // Change is needed, so modify the order
       {  
         //--- zeroing the request and result values
         //Print("New Stop = ",NewStop," and StopLoss = ",sl);
         ZeroMemory(request);
         ZeroMemory(result);
         //--- setting the operation parameters
         request.action  =TRADE_ACTION_SLTP; // type of trade operation
         request.position=position_ticket;   // ticket of the position
         request.symbol=position_symbol;     // symbol
         request.sl      =NewStop;           // New Stop Loss of the position
         request.tp      =tp;                // Original Take Profit of the position
         request.magic=MagicNum;             // MagicNumber of the position
         //--- output information about the modification
         //PrintFormat("|SL Modify #%I64d %s %s",position_ticket,position_symbol,EnumToString(type),"|",i);
         //--- send the request
         if(!OrderSend(request,result))
            {
            PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
             //--- information about the operation  
            PrintFormat("|retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order,"|",i);
            }
       }
     } // End of Tickets
  }
  
bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)
  {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   //--- call of the checking function
   if(!OrderCalcMargin(type,symb,lots,price,margin))
     {
      //--- something went wrong, report and return false
      Print("Error in ",__FUNCTION__," code=",GetLastError());
      return(false);
     }
   //--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
      return(false);
     }
//--- checking successful
   return(true);
  }

double ATR_Daily() //========================================================================================================
  {
  int      MA_Period = 15;               // The value of the averaging period for the indicator calculation
  int      Count = 7;                    // Amount to copy
  int      ATRHandle;                    // Variable to store the handle of ATR
  double   ATRValue[];                   // Variable to store the value of ATR    
  ATRHandle = iATR(_Symbol,PERIOD_D1,MA_Period); // returns a handle for ATR for last two weeks
  ArraySetAsSeries( ATRValue,true );     // Set the ATRValue to timeseries, 0 is the oldest.
  if( CopyBuffer( ATRHandle,0,0,Count,ATRValue ) > 0 )  
    {
      double y[];
      ArraySort(ATRValue);
      ArrayCopy(y, ATRValue, 0, 2, ArraySize(ATRValue) - 4); // Three of Seven Average, removing two highest and two lowest
      double AvgVal = (y[0]+y[1]+y[2])/3;
      double ATR_Pips = AvgVal / SymbolInfoDouble(symbol,SYMBOL_POINT); // ATRValue[ATRShift]/SymbolInfoDouble(symbol,SYMBOL_POINT);
      return(ATR_Pips); } else { return(0); }// Copy value of ATR to ATRValue  
  }  