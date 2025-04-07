//+------------------------------------------------------------------+
//|                                                     My_first.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//|  Include header file, Class                                      |
//+------------------------------------------------------------------+

//Trade
#include <Trade.mqh>
CTrade Trade;

//Price
#include <Price.mqh>
CBars Price;

//Money Management
#include <MoneyManagement.mqh>

//Trailing stops
#include <TrailingStops.mqh>
CTrailing Trail;

//Timer
#include <Timer.mqh>
CTimer Timer;
CNewBar NewBar;

//Indicator
#include <Indicators.mqh>

//+------------------------------------------------------------------+
//|  Input variables                                                 |
//+------------------------------------------------------------------+

input ulong Slippage = 3;
input bool TradeOnNewBar = true;

sinput string MM; //Money Management
input bool UseMoneyManagement = false;
input double RiskPercent = 2.;
input double FixedVolume = 0.1;

sinput string SL;  // Stop Loss & Take Profit
input int StopLoss = 20;
input int TakeProfit = 0;

sinput string TS; //Trailing Stop
input bool UseTrailingStop = false;
input int TrailingStop = 0;
input int MinimumProfit = 0;
input int Step = 0;

sinput string BE; //Brake Even
input bool UseBreakEven = false;
input int BrakeEvenProfit = 0;
input int LockProfit = 0;

sinput string TI;  //Timer
input bool UseTimer = true;
input datetime StartTime = 0;
input datetime EndTime = 0;
input bool UseLocalTime = true;

//+------------------------------------------------------------------+
//|  Global variables                                                |
//+------------------------------------------------------------------+

bool glBuyPlaced, glSellPlaced;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Trade.Deviation(Slippage);
   return(0);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //Check for new bar
   bool newBar = true;
   int barShift = 0;
   
   if(TradeOnNewBar == true)
   {
      newBar = NewBar.CheckNewBar(_Symbol, _Period);
      barShift = 1;
   }
   
   //Timer
   bool timerOn = true;
   if(UseTimer == true)
   {
      timerOn = Timer.CheckTimer(StartTime, EndTime, UseLocalTime);
   }
   
   // Update prices
   Price.Update(_Symbol, _Period);
   
   //Order placement
   if(newBar == true && timerOn == true)
   {
      //Money management
      double tradeSize;
      if(UseMoneyManagement == true)
         tradeSize = MoneyManagement(_Symbol, FixedVolume, RiskPercent, StopLoss);
      else tradeSize = VerifyVolume(_Symbol, FixedVolume);
      
      
      //Open buy order
      if(PositionTypeNetting(_Symbol) != POSITION_TYPE_BUY && glBuyPlaced == false)
      {
         glBuyPlaced = Trade.Buy(_Symbol, tradeSize);
         
         if(glBuyPlaced == true)
         {
            do Sleep(100); while(PositionSelect(_Symbol) == false);
            double openPrice = PositionOpenPrice(_Symbol);
            
            double buyStop = BuyStopLoss(_Symbol, StopLoss, openPrice);
            if(buyStop > 0) AdjustBelowStopLevel(_Symbol, buyStop);
            
            double buyProfit = BuyTakeProfit(_Symbol, TakeProfit, openPrice);
            if(buyProfit > 0) AdjustAboveStopLevel(_Symbol, buyProfit);
            
            if(buyStop > 0  || buyProfit > 0)
               Trade.ModifyPosition(_Symbol, buyStop, buyProfit);
            glSellPlaced =false;
         }
      }
      
      
      //Open sell order
      if(PositionTypeNetting(_Symbol) != POSITION_TYPE_SELL && glSellPlaced == false)
      {
         glSellPlaced = Trade.Sell(_Symbol, tradeSize);
         
         if(glSellPlaced  == true)
         {
            do Sleep(100); while(PositionSelect(_Symbol) == false);
            double openPrice = PositionOpenPrice(_Symbol);
            
            double sellStop = SellStopLoss(_Symbol, StopLoss, openPrice);
            if(sellStop > 0) sellStop = AdjustAboveStopLevel(_Symbol, sellStop);
            
            
            double sellProfit = SellTakeProfit(_Symbol, TakeProfit, openPrice);
            if(sellProfit > 0) sellProfit = AdjustBelowStopLevel(_Symbol, sellProfit);
            
            if(sellStop > 0 || sellProfit > 0)
               Trade.ModifyPosition(_Symbol, sellStop, sellProfit);
            glBuyPlaced = false; 
         }
      }
      
      //Brake even
      if(UseBreakEven == true && PositionTypeNetting(_Symbol) != -1)
      {
         Trail.BreakEven(_Symbol, BrakeEvenProfit, LockProfit);
      }
      
      //Trailing stop
      if(UseTrailingStop == true && PositionTypeNetting(_Symbol) != -1)
      {
         Trail.TrailingStop(_Symbol, TrailingStop, MinimumProfit, Step);
      }
   }
   
   
   
   
   
   
   
}


