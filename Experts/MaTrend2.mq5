//+------------------------------------------------------------------+
//|                                    Raymond Cloudy Day for EA.mq5 |
//|                                        Copyright 2024, Shi Xiong |
//|                   https://www.mql5.com/en/users/thehung21/seller |
//+------------------------------------------------------------------+
#define propLink        "https://www.mql5.com/en/users/thehung21/seller"
#define propVersion     "1.00"
#property copyright "Fully Coded By Shi Xiong"
#property link      propLink
#property description "Donation (USDT TRC20): TKM5RMSoaT38ctyF4obtf9ECErfVpGeabu"
#property description "Telegram : @ShiXiongScalpingTrader"
#property description "Copyright, RayMond Bui"
#property description "The Raymond Cloudy Day indicator is an enhanced Pivot Point tool, optimized for pinpointing precise reversal points in Stocks, Gold, Forex, and Cryptocurrencies trading. Its advanced algorithm provides reliable strategies for diverse market conditions."
#property version       propVersion
#include <Trade\Trade.mqh> // Include the trading functions library
CTrade         trade;      // Create an instance of CTrade for trading operations
CPositionInfo  pos;        // Create an instance of CPositionInfo for position information
input string INFO1 = "======== Inputs For Raymond Cloudy Day ======="; // ===========================
      input ENUM_TIMEFRAMES RayMondTimeframe = PERIOD_D1;  // Timeframe for Raymond Cloudy Day
      input color TLColor = clrChartreuse; // Color for Raymond Cloudy Day
input string INFO2 = "======== Trade Management ========"; // ===========================
      input string Comment = "Comment";  // Comment
      input ulong MagicNumber = 20240712; // Magic number
input string INFO3 = "====== Contact ======"; // ===========================
      input string Author = "Shi Xiong";  // Author

double High[];  // Array to store high prices
double Low[];   // Array to store low prices
double Open[];  // Array to store open prices
double Close[]; // Array to store close prices
datetime Time[];// Array to store time values

// Initialization function
int OnInit()
{  
    ObjectsDeleteAll(0);
    Start();
    EventSetTimer(60); // Set a timer event to trigger every 60 seconds
    return INIT_SUCCEEDED; // Return success code
}

// Deinitialization function
void OnDeinit(const int reason)
{    
    ObjectsDeleteAll(0);
    EventKillTimer(); // Kill the timer event
}

// OnTick function is called for every new tick
void OnTick()
{
   CalculateRaymond(); // Call the CalculateRaymond function
}
void Start() {
    ulong fontsize = 11;
    ulong largefontsize = 13;
    //-- Create text objects on the chart
    ObjectCreate(0, "MyText1", OBJ_LABEL, 0, 0, 0);
    ObjectCreate(0, "MyText2", OBJ_LABEL, 0, 0, 0);
    ObjectCreate(0, "MyText3", OBJ_LABEL, 0, 0, 0);
    ObjectCreate(0, "MyText4", OBJ_LABEL, 0, 0, 0);
    ObjectCreate(0, "MyText5", OBJ_LABEL, 0, 0, 0);
    
    //-- Create and set the position of text objects
    ObjectSetInteger(0, "MyText1", OBJPROP_XDISTANCE, 30);
    ObjectSetInteger(0, "MyText1", OBJPROP_YDISTANCE, 40);
    
    ObjectSetInteger(0, "MyText2", OBJPROP_XDISTANCE, 30);
    ObjectSetInteger(0, "MyText2", OBJPROP_YDISTANCE, 65);
    
    ObjectSetInteger(0, "MyText3", OBJPROP_XDISTANCE, 30);
    ObjectSetInteger(0, "MyText3", OBJPROP_YDISTANCE, 90);
    
    ObjectSetInteger(0, "MyText4", OBJPROP_XDISTANCE, 30);
    ObjectSetInteger(0, "MyText4", OBJPROP_YDISTANCE, 115);
    
    ObjectSetInteger(0, "MyText5", OBJPROP_XDISTANCE, 30);
    ObjectSetInteger(0, "MyText5", OBJPROP_YDISTANCE, 140);

    //-- Set content and properties of text 1
    ObjectSetString(0, "MyText1", OBJPROP_TEXT, "Raymond Cloudy Day for EA " + propVersion);
    ObjectSetInteger(0, "MyText1", OBJPROP_FONTSIZE, fontsize);
    ObjectSetInteger(0, "MyText1", OBJPROP_COLOR, clrCyan);

    ObjectSetString(0, "MyText2", OBJPROP_TEXT, "© 2024 Shi Xiong - Telegram: t.me/ShiXiong_RTTAinstitute");
    ObjectSetInteger(0, "MyText2", OBJPROP_FONTSIZE, fontsize);
    ObjectSetInteger(0, "MyText2", OBJPROP_COLOR, clrCyan);

    ObjectSetString(0, "MyText3", OBJPROP_TEXT, "Phone Number: +84396342088");
    ObjectSetInteger(0, "MyText3", OBJPROP_FONTSIZE, fontsize);
    ObjectSetInteger(0, "MyText3", OBJPROP_COLOR, clrCyan);

    ObjectSetString(0, "MyText4", OBJPROP_TEXT, "Buy premium EAs to diversify your portfolio:");
    ObjectSetInteger(0, "MyText4", OBJPROP_FONTSIZE, fontsize);
    ObjectSetInteger(0, "MyText4", OBJPROP_COLOR, clrCyan);

    ObjectSetString(0, "MyText5", OBJPROP_TEXT, "==>> https://www.mql5.com/en/users/thehung21/seller <<==");
    ObjectSetInteger(0, "MyText5", OBJPROP_FONTSIZE, largefontsize);
    ObjectSetInteger(0, "MyText5", OBJPROP_COLOR, clrCyan);
    
    // Left align text
    ObjectSetInteger(0, "MyText1", OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, "MyText2", OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, "MyText3", OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, "MyText4", OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, "MyText5", OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
}
// Function to calculate the Raymond Cloudy Day levels
void CalculateRaymond()
{
    //-- Get the high, low, open, and close prices for the current symbol and timeframe
    double high = iHigh(_Symbol,RayMondTimeframe,1);
    double low = iLow(_Symbol,RayMondTimeframe,1);
    double open = iOpen(_Symbol,RayMondTimeframe,1);
    double close = iClose(_Symbol,RayMondTimeframe,1);

    //-- Calculate the trading session level and pivot range
    double TradeSS = (high + low + open + close) / 4;
    double PivotRange = high - low;

    //-- Calculate the extended buy/sell levels and take profit levels
    double ETB = TradeSS + 0.382 * PivotRange;
    double ETS = TradeSS - 0.382 * PivotRange;
    double TPB1 = TradeSS + 0.618 * PivotRange;
    double TPS1 = TradeSS - 0.618 * PivotRange;
    double TPB2 = TradeSS + 1 * PivotRange;
    double TPS2 = TradeSS - 1 * PivotRange;
    
    //-- Draw the Raymond Cloudy Day levels on the chart
    DrawRaymondCloudyDay(TradeSS,ETB,ETS,TPB1,TPS1,TPB2,TPS2);
    //-- Open trades based on the calculated levels
    OpenTrade(TradeSS,ETB,ETS,TPB1,TPS1,TPB2,TPS2);
}

// Function to draw Raymond Cloudy Day levels on the chart
void DrawRaymondCloudyDay(double TradeSS,double ETB,double ETS, double TPB1, double TPS1, double TPB2, double TPS2){    

    //-- Create and customize objects for trading session level and text
    ObjectCreate(0,"TradeSS",OBJ_TREND,0,iTime(_Symbol,RayMondTimeframe,0),TradeSS,iTime(_Symbol,RayMondTimeframe,0)+PeriodSeconds(RayMondTimeframe),TradeSS);
    ObjectSetInteger(0,"TradeSS",OBJPROP_COLOR,TLColor);
    ObjectCreate(0,"TradeSStext",OBJ_TEXT,0,iTime(_Symbol,RayMondTimeframe,0),TradeSS);
    ObjectSetString(0,"TradeSStext",OBJPROP_TEXT,"Trading Session");
    ObjectSetInteger(0,"TradeSStext",OBJPROP_COLOR,TLColor);

    // Create and customize objects for extended buy level and text
    ObjectCreate(0,"ETB",OBJ_TREND,0,iTime(_Symbol,RayMondTimeframe,0),ETB,iTime(_Symbol,RayMondTimeframe,0)+PeriodSeconds(RayMondTimeframe),ETB);
    ObjectSetInteger(0,"ETB",OBJPROP_COLOR,TLColor);
    ObjectCreate(0,"ETBtext",OBJ_TEXT,0,iTime(_Symbol,RayMondTimeframe,0),ETB);
    ObjectSetString(0,"ETBtext",OBJPROP_TEXT,"Extended for Buy");
    ObjectSetInteger(0,"ETBtext",OBJPROP_COLOR,TLColor);
    
    //-- Create and customize objects for extended sell level and text
    ObjectCreate(0,"ETS",OBJ_TREND,0,iTime(_Symbol,RayMondTimeframe,0),ETS,iTime(_Symbol,RayMondTimeframe,0)+PeriodSeconds(RayMondTimeframe),ETS);
    ObjectSetInteger(0,"ETS",OBJPROP_COLOR,TLColor);
    ObjectCreate(0,"ETStext",OBJ_TEXT,0,iTime(_Symbol,RayMondTimeframe,0),ETS);
    ObjectSetString(0,"ETStext",OBJPROP_TEXT,"Extended for Sell");
    ObjectSetInteger(0,"ETStext",OBJPROP_COLOR,TLColor);
    
    //-- Create and customize objects for take profit buy level 1 and text
    ObjectCreate(0,"TPB1",OBJ_TREND,0,iTime(_Symbol,RayMondTimeframe,0),TPB1,iTime(_Symbol,RayMondTimeframe,0)+PeriodSeconds(RayMondTimeframe),TPB1);
    ObjectSetInteger(0,"TPB1",OBJPROP_COLOR,TLColor);
    ObjectCreate(0,"TPB1text",OBJ_TEXT,0,iTime(_Symbol,RayMondTimeframe,0),TPB1);
    ObjectSetString(0,"TPB1text",OBJPROP_TEXT,"TP 1 for Buy");
    ObjectSetInteger(0,"TPB1text",OBJPROP_COLOR,TLColor);

    //-- Create and customize objects for take profit sell level 1 and text
    ObjectCreate(0,"TPS1",OBJ_TREND,0,iTime(_Symbol,RayMondTimeframe,0),TPS1,iTime(_Symbol,RayMondTimeframe,0)+PeriodSeconds(RayMondTimeframe),TPS1);
    ObjectSetInteger(0,"TPS1",OBJPROP_COLOR,TLColor);
    ObjectCreate(0,"TPS1text",OBJ_TEXT,0,iTime(_Symbol,RayMondTimeframe,0),TPS1);
    ObjectSetString(0,"TPS1text",OBJPROP_TEXT,"TP 1 for Sell");
    ObjectSetInteger(0,"TPS1text",OBJPROP_COLOR,TLColor);

    //-- Create and customize objects for take profit buy level 2 and text
    ObjectCreate(0,"TPB2",OBJ_TREND,0,iTime(_Symbol,RayMondTimeframe,0),TPB2,iTime(_Symbol,RayMondTimeframe,0)+PeriodSeconds(RayMondTimeframe),TPB2);
    ObjectSetInteger(0,"TPB2",OBJPROP_COLOR,TLColor);
    ObjectCreate(0,"TPB2text",OBJ_TEXT,0,iTime(_Symbol,RayMondTimeframe,0),TPB2);
    ObjectSetString(0,"TPB2text",OBJPROP_TEXT,"TP 2 for Buy");
    ObjectSetInteger(0,"TPB2text",OBJPROP_COLOR,TLColor);
    
    //-- Create and customize objects for take profit sell level 2 and text
    ObjectCreate(0,"TPS2",OBJ_TREND,0,iTime(_Symbol,RayMondTimeframe,0),TPS2,iTime(_Symbol,RayMondTimeframe,0)+PeriodSeconds(RayMondTimeframe),TPS2);
    ObjectSetInteger(0,"TPS2",OBJPROP_COLOR,TLColor);
    ObjectCreate(0,"TPS2text",OBJ_TEXT,0,iTime(_Symbol,RayMondTimeframe,0),TPS2);
    ObjectSetString(0,"TPS2text",OBJPROP_TEXT,"TP 2 for Sell");
    ObjectSetInteger(0,"TPS2text",OBJPROP_COLOR,TLColor);
}

// Function to open trades based on the calculated levels (implementation needed)
datetime lastOrderTime = 0;
void OpenTrade(double TradeSS,double ETB,double ETS, double TPB1, double TPS1, double TPB2, double TPS2){
    int candleTime = PeriodSeconds(ChartPeriod());
    if (TimeTradeServer() - lastOrderTime < candleTime) return;
    double Lowx1 = iLow(_Symbol,PERIOD_CURRENT,1);
    double Closex1 = iClose(_Symbol,PERIOD_CURRENT,1);
    double lots = 0.01;
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point;

    if(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_LIMIT) != 0) {
      if(lots > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_LIMIT)) return;
    }
    //-- Check volume
    double min_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double max_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double volume_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    int ratio = (int)MathRound(lots/volume_step);

    if (lots < min_volume || lots > max_volume || MathAbs(ratio*volume_step - lots) > 0.0000001) {
        Print("Invalid volume");
        return;
    }

    //-- BUY
       if(Lowx1<TPS1 && Closex1>TPS1){
           double tp=500*_Point+Closex1;
           double sl=Closex1-500*_Point;
           trade.Buy(lots,_Symbol,0,sl,tp, Comment);
           lastOrderTime = TimeTradeServer();
       }
    //-- SELL
       if(Lowx1>TPS1 && Closex1<TPS1){
           double tp=Closex1-500*_Point;
           double sl=Closex1+500*_Point;
           trade.Sell(lots,_Symbol,0,sl,tp, Comment);
           lastOrderTime = TimeTradeServer();
       }
}