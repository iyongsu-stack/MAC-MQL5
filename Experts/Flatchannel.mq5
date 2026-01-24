//+------------------------------------------------------------------+
//|                                                  Flatchannel.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                        Flat Channel(barabashkakvn's edition).mq5 |
//+------------------------------------------------------------------+
#property copyright "wsforex@list.ru"
#property link      "http://wsforex.ru/"
#property version   "1.001"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Expert\Money\MoneyFixedRisk.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
COrderInfo     m_order;                      // pending orders object
CMoneyFixedRisk m_money;
///+------------------------------------------------------------------+
//| Enum hours                                                       |
//+------------------------------------------------------------------+
enum ENUM_HOURS
  {
   hour_00  =0,   // 00
   hour_01  =1,   // 01
   hour_02  =2,   // 02
   hour_03  =3,   // 03
   hour_04  =4,   // 04
   hour_05  =5,   // 05
   hour_06  =6,   // 06
   hour_07  =7,   // 07
   hour_08  =8,   // 08
   hour_09  =9,   // 09
   hour_10  =10,  // 10
   hour_11  =11,  // 11
   hour_12  =12,  // 12
   hour_13  =13,  // 13
   hour_14  =14,  // 14
   hour_15  =15,  // 15
   hour_16  =16,  // 16
   hour_17  =17,  // 17
   hour_18  =18,  // 18
   hour_19  =19,  // 19
   hour_20  =20,  // 20
   hour_21  =21,  // 21
   hour_22  =22,  // 22
   hour_23  =23,  // 23
  };
//--- input parameters
input bool     ExpertTime     = true;     // Time work (true-> on false -> off)
bool           TradeMonday    = true;     // Trading on Monday (always allowed)
input bool     TradeTuesday   = true;     // Trade on Tuesday
input bool     TradeWednesday = true;     // Trading on Wednesday
input bool     TradeThursday  = true;     // Trading on Thursday
bool           TradeFriday    = true;     // Trade on Friday (always allowed)
input int      HourMondayStart= hour_00;  // Start trading on Monday
input int      HourFridayStops= hour_19;  // Stop trading on Friday
input bool     MM             = false;    // Money management
input double   Risk           = 7;        // Risk in % for a deal from a free margin (only if "Money management"==false)
input double   Lots           = 0.01;     // Lots
input int      Life_time      = 86400;    // Life_time
input ulong    m_magic        = 777;      // magic
input string   Block="  Flat  ";
input int      StdDevPer      = 37;       // StdDev averaging period
input int      FletBars       = 2;        // Flet bars
input ushort   InpCanalMin    = 610;      // Canal min  (in pips)
input ushort   InpCanalMax    = 1860;     // Canal max  (in pips)
input bool     InpBreakeven   = true;     // Breakeven
input double   FiboTral       = 0.873;    // Fibo tral
int tik,dg,lv,sp;
datetime m_expiration;
double pa,pb,po;
string Times;
string com="";
bool flagup,flagdw;
//---
int      Losses=0;
ulong    m_slippage=30;                   // slippage
double   ExtCanalMin=0.0;
double   ExtCanalMax=0.0;
int      handle_iStdDev;                  // variable for storing the handle of the iStdDev indicator
double   m_adjusted_point;                // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(Lots<=0.0)
     {
      Print("The \"Lots\" can't be smaller or equal to zero");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(Lots,err_text))
     {
      Print(err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_trade.SetExpertMagicNumber(m_magic);
//---
   if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
//---
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtCanalMin=InpCanalMin*m_adjusted_point;
   ExtCanalMax=InpCanalMax*m_adjusted_point;
//---
   if(!m_money.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
      return(INIT_FAILED);
   m_money.Percent(Risk);
//--- create handle of the indicator iStdDev  
   handle_iStdDev=iStdDev(m_symbol.Name(),Period(),StdDevPer,0,MODE_SMMA,PRICE_MEDIAN);
//--- if the handle is not created
   if(handle_iStdDev==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iStdDev indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//--- create a trend line by the given coordinates
   ObjectCreate(0,"Max",OBJ_TREND,0,0,0.0,0,0.0);
   ObjectCreate(0,"Min",OBJ_TREND,0,0,0.0,0,0.0);
   ObjectCreate(0,"TPBuy",OBJ_TREND,0,0,0.0,0,0.0);
   ObjectCreate(0,"TPSell",OBJ_TREND,0,0,0.0,0,0.0);
//--- set line color
   ObjectSetInteger(0,"Max",OBJPROP_COLOR,clrBlueViolet);
   ObjectSetInteger(0,"Min",OBJPROP_COLOR,clrBlueViolet);
   ObjectSetInteger(0,"Max",OBJPROP_COLOR,clrRed);
   ObjectSetInteger(0,"Max",OBJPROP_COLOR,clrRed);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(!RefreshRates())
      return;
   Times=TimeToString(TimeGMT(),TIME_DATE|TIME_MINUTES|TIME_SECONDS);
//pb = MarketInfo(symbol,MODE_BID);
//pa = MarketInfo(symbol,MODE_ASK);
//dg = MarketInfo(symbol,MODE_DIGITS);
//po = MarketInfo(symbol,MODE_POINT);
   lv=m_symbol.StopsLevel()+m_symbol.Spread();
//---          
   Comment("\nAdvisor "+__FILE__+" works: - ",
           IIcm(Tradetime(ExpertTime,HourMondayStart,HourFridayStops)),
           "\nDay: - ",DayOfWeek(),
           "\nTrading account: - ",Account(),
           "\nCompany: - ",m_account.Company(),
           "\nEquity: - ",DoubleToString(m_account.Equity(),2),
           "\nStop Out: - ",DoubleToString(m_account.MarginStopOut(),2),
           "\nTime GMT: - "+Times,
           "\nSpread: - ",m_symbol.Spread(),
           "\nStopLevel: - ",m_symbol.StopsLevel(),
           "\nLeverage: - ",m_account.Leverage()
           );
//---
   if(m_account.Equity()<=m_account.MarginStopOut())
     {
      CloseAllPositions();
      DeleteOrders(ORDER_TYPE_CLOSE_BY,true); // true -> delete ALL pending orders
     }
//---
   static datetime BARflag=0;
   datetime now=iTime(m_symbol.Name(),Period(),0);
   if(BARflag<now)
     {
      BARflag=now;
      //---
      int ress=ChecBarsFlet();
      if(ress==0)
         return;
      double Pricemax = PriceMaxBars(ress);
      double Pricemin = PriceMinBars(ress);
      if(Pricemax==0.0 || Pricemin==0.0)
         return;
      double ChCan=Pricemax-Pricemin;
      double TPBuy=Pricemax+ChCan;
      double TPSell=Pricemin-ChCan;
      double SLBuy=Pricemax-ChCan*2;
      double SLSell=Pricemin+ChCan*2;
      //---
      if(ChCan<ExtCanalMax && ChCan>=ExtCanalMin && ress>=FletBars && CalculatePositionsPendingOrders()==0)
        {
         TrendPointChange(0,"Max",0,iTime(m_symbol.Name(),Period(),ress),Pricemax);
         TrendPointChange(0,"Max",0,iTime(m_symbol.Name(),Period(),0),Pricemax);
         TrendPointChange(0,"Min",0,iTime(m_symbol.Name(),Period(),ress),Pricemin);
         TrendPointChange(0,"Min",0,iTime(m_symbol.Name(),Period(),0),Pricemin);
         TrendPointChange(0,"TPBuy",0,iTime(m_symbol.Name(),Period(),ress),TPBuy);
         TrendPointChange(0,"TPBuy",0,iTime(m_symbol.Name(),Period(),0),TPBuy);
         TrendPointChange(0,"TPSell",0,iTime(m_symbol.Name(),Period(),ress),TPSell);
         TrendPointChange(0,"TPSell",0,iTime(m_symbol.Name(),Period(),0),TPSell);
        }
      //---
      m_expiration=TimeCurrent()+Life_time;
      if(InpBreakeven)
         Breakeven();
      //--- open position
      if(ChCan>=ExtCanalMin && ChCan<ExtCanalMax && ress>=FletBars &&
         Tradetime(ExpertTime,HourMondayStart,HourFridayStops))
        {
         double lot_buy=0.0;
         double lot_sell=0.0;
         GetLots(lot_buy,lot_sell);
         if(Losses==1)
            lot_buy=lot_sell=Lots*4.0;
         //---
         if(flagup==true && m_symbol.Ask()>Pricemin && m_symbol.Ask()<Pricemax)
           {
            double op=Pricemax;
            double sl=SLBuy;
            double tp=TPBuy;
            if((op-pa)/m_symbol.Point()>lv && (op-sl)/m_symbol.Point()>lv && (tp-op)/m_symbol.Point()>lv)
              {
               if(m_trade.BuyStop(lot_buy,op,m_symbol.Name(),sl,tp,ORDER_TIME_SPECIFIED,m_expiration))
                  flagup=false;
              }
           }
         if(flagdw==true && pb>Pricemin && pb<Pricemax)
           {
            double op=Pricemin;
            double sl=SLSell;
            double tp=TPSell;
            if((pb-op)/m_symbol.Point()>lv && (sl-op)/m_symbol.Point()>lv && (op-tp)/m_symbol.Point()>lv)
              {
               if(m_trade.SellStop(lot_sell,op,m_symbol.Name(),sl,tp,ORDER_TIME_SPECIFIED,m_expiration))
                  flagdw=false;
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ChecBarsFlet()
  {
   int ress=0;
   int limit=BarsCalculated(handle_iStdDev);
   if(limit>0)
      limit--;
   for(int i=0;i<limit;i++)
     {
      if(iStdDevGet(i)>iStdDevGet(i+1))
         break;
      if(iStdDevGet(i)<iStdDevGet(i+1))
        {
         ress++;
         flagup=true;
         flagdw=true;
        }
     }
//---
   return(ress);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PriceMaxBars(int bar)
  {
//---
   double new_extremum=0.0;
   double arr_high[];
   int res=CopyHigh(m_symbol.Name(),Period(),1,bar,arr_high);
   if(res!=bar)
      return(0.0);

   int max_index=ArrayMaximum(arr_high,0,WHOLE_ARRAY);
   new_extremum=arr_high[max_index];
//---
   return(new_extremum);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PriceMinBars(int bar)
  {
//---
   double new_extremum=0.0;
   double arr_low[];
   int res=CopyLow(m_symbol.Name(),Period(),1,bar,arr_low);
   if(res!=bar)
      return(0.0);

   int min_index=ArrayMinimum(arr_low,0,WHOLE_ARRAY);
   new_extremum=arr_low[min_index];
//---
   return(new_extremum);
  }
//+------------------------------------------------------------------+
//| Move trend line anchor point                                     |
//+------------------------------------------------------------------+
bool TrendPointChange(const long   chart_ID=0,// chart's ID
                      const string name="TrendPointChange",// line name
                      const int    point_index=0,    // anchor point index
                      datetime     time=0,           // anchor point time coordinate
                      double       price=0)          // anchor point price coordinate
  {
//--- if point position is not set, move it to the current bar having Bid price
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move trend line's anchor point
   if(!ObjectMove(chart_ID,name,point_index,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetLots(double &lot_buy,double &lot_sell)
  {
   if(!MM)
     {
      lot_buy=lot_sell=Lots;
      return;
     };
   lot_buy=m_money.CheckOpenLong(m_symbol.Ask(),0.0);
   lot_sell=m_money.CheckOpenShort(m_symbol.Bid(),0.0);
  }
//+------------------------------------------------------------------+
//| Breakeven                                                        |
//+------------------------------------------------------------------+
void Breakeven()
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               double level=m_position.PriceOpen()+
                            m_symbol.NormalizePrice((m_position.TakeProfit()-m_position.PriceOpen())*FiboTral);
               if(m_position.PriceOpen()>m_position.StopLoss() && level<m_position.PriceCurrent())
                 {
                  if(!m_trade.PositionModify(m_position.Ticket(),
                     m_position.PriceOpen(),
                     m_position.TakeProfit()))
                     Print("Breakeven ",m_position.Ticket(),
                           " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                           ", description of result: ",m_trade.ResultRetcodeDescription());
                 }
              }
            else
              {
               double level=m_position.PriceOpen()-
                            m_symbol.NormalizePrice((m_position.PriceOpen()-m_position.TakeProfit())*FiboTral);
               if(m_position.PriceOpen()<m_position.StopLoss() && level>m_position.PriceCurrent())
                 {
                  if(!m_trade.PositionModify(m_position.Ticket(),
                     m_position.PriceOpen(),
                     m_position.TakeProfit()))
                     Print("Modify ",m_position.Ticket(),
                           " Breakeven -> false. Result Retcode: ",m_trade.ResultRetcode(),
                           ", description of result: ",m_trade.ResultRetcodeDescription());
                 }
              }
           }
  }
//+------------------------------------------------------------------+
//| Day of week                                                      |
//+------------------------------------------------------------------+
string DayOfWeek()
  {
   string dd="";
   MqlDateTime str1;
   TimeToStruct(TimeCurrent(),str1);
   switch(str1.day_of_week)
     {
      case 1:
         dd="Monday";
         break;
      case 2:
         dd="Tuesday";
         break;
      case 3:
         dd="Wednesday";
         break;
      case 4:
         dd="Thursday";
         break;
      case 5:
         dd="Friday";
         break;
      case 6:
         dd="Saturday";
         break;
      case 0:
         dd="Sunday";
         break;
     }
   return(dd);
  }
//+------------------------------------------------------------------+
//| Delete Orders                                                    |
//+------------------------------------------------------------------+
void DeleteOrders(const ENUM_ORDER_TYPE order_type,const bool close_all=false)
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i)) // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
           {
            if(!close_all)
               if(m_order.OrderType()==order_type)
                  m_trade.OrderDelete(m_order.Ticket());
            else // close_all == true
            m_trade.OrderDelete(m_order.Ticket());
           }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string IIcm(bool flag)
  {
   if(flag)
      return("yes:");
   else
      return("no:");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Account()
  {
   long trade_mode=m_account.TradeMode();
   string s="";
   switch((int)trade_mode)
     {
      case  ACCOUNT_TRADE_MODE_DEMO:
         s="Demo account";
         break;
      case  ACCOUNT_TRADE_MODE_CONTEST:
         s="Contest account";
         break;
      case  ACCOUNT_TRADE_MODE_REAL:
         s="Real account";
         break;
     }
   return(s);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
color IIFc(bool condition,color iftrue,color iffalse)
  {
   if(condition)
      return(iftrue);
   else
      return(iffalse);
  }
//+------------------------------------------------------------------+
//| Tradetime                                                        |
//+------------------------------------------------------------------+
bool Tradetime(bool exptime,int OpenHour,int  CloseHour)
  {
   if(!exptime) // if the "Time work" is disabled
      return(true);

   MqlDateTime str1;
   TimeToStruct(TimeCurrent(),str1);
   switch(str1.day_of_week)
     {
      case 1:  // Monday;
        {
         if(str1.hour>=OpenHour)
            return(true);
         else
            return(false);
         break;
        }
      case 2:  // Tuesday;
         return(TradeTuesday);
         break;
      case 3:  // Wednesday;
         return(TradeTuesday);
         break;
      case 4:  // Thursday;
         return(TradeThursday);
         break;
      case 5:  // Friday;
        {
         if(str1.hour<=CloseHour)
            return(true);
         else
            return(false);
         break;
        }
     }
// ---
   return(false);
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//--- get transaction type as enumeration value
   ENUM_TRADE_TRANSACTION_TYPE type=trans.type;
//--- if transaction is result of addition of the transaction in history
   if(type==TRADE_TRANSACTION_DEAL_ADD)
     {
      long     deal_entry        =-1;
      long     deal_magic        =0;
      double   deal_commission   =0.0;
      double   deal_swap         =0.0;
      double   deal_profit       =0.0;
      string   deal_symbol="";
      if(HistoryDealSelect(trans.deal))
        {
         deal_entry        =HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
         deal_magic        =HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
         deal_commission   =HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
         deal_swap         =HistoryDealGetDouble(trans.deal,DEAL_SWAP);
         deal_profit       =HistoryDealGetDouble(trans.deal,DEAL_PROFIT);
         deal_symbol       =HistoryDealGetString(trans.deal,DEAL_SYMBOL);
        }
      else
         return;
      if(deal_symbol==m_symbol.Name() && deal_magic==m_magic)
        {
         if(deal_entry==DEAL_ENTRY_IN)
            DeleteOrders(ORDER_TYPE_CLOSE_BY,true); // true -> delete ALL pending orders
         else if(deal_entry==DEAL_ENTRY_OUT)
           {
            if(deal_commission+deal_profit+deal_profit<0.0)
               Losses++;
            else
               Losses=0;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iStdDev                             |
//+------------------------------------------------------------------+
double iStdDevGet(const int index)
  {
   double StdDev[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iStdDev array with values from the indicator buffer that has 0 index
   if(CopyBuffer(
      handle_iStdDev,// indicator handle
      0,             // indicator buffer number
      index,         // start position
      1,             // amount to copy
      StdDev         // target array to copy
      )<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iStdDev indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(StdDev[0]);
  }
//+------------------------------------------------------------------+
//| Calculate all positions and pending orders                       |
//+------------------------------------------------------------------+
int CalculatePositionsPendingOrders()
  {
   int total=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            total++;

   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i)) // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            total++;
//---
   return(total);
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
// double min_volume=m_symbol.LotsMin();
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
// double max_volume=m_symbol.LotsMax();
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
// double volume_step=m_symbol.LotsStep();
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                     volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+
//| Checks if the specified filling mode is allowed                  |
//+------------------------------------------------------------------+
bool IsFillingTypeAllowed(int fill_type)
  {
//--- Obtain the value of the property that describes allowed filling modes
   int filling=m_symbol.TradeFillFlags();
//--- Return true, if mode fill_type is allowed
   return((filling & fill_type)==fill_type);
  }
//+------------------------------------------------------------------+