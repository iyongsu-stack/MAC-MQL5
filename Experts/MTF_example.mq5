//+------------------------------------------------------------------+
//|                                                  MTF_example.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|             Multi Time Frame Trader(barabashkakvn's edition).mq5 |
//|                                       korostelev.andre@gmail.com |
//+------------------------------------------------------------------+
#property copyright ""
#property link      "korostelev.andre@gmail.com"
#property version   "1.001"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
//---
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//+------------------------------------------------------------------+
//| Type of Regression Channel                                       |
//+------------------------------------------------------------------+
enum ENUM_Polynomial
  {
   linear=1,      // linear
   parabolic=2,   // parabolic
   Third_power=3, // third-power
  };
//--- input parameters
input ENUM_Polynomial   Inp_degree     = linear;   // i-Regr parameter "degree"
input double            Inp_kstd       = 2.0;      // i-Regr parameter "kstd"
input int               Inp_bars       = 250;      // i-Regr parameter "bars"
input int               Inp_shift      = 0;        // i-Regr parameter "shift"
input bool              InpUseTrading  = true;     // Use trading
input double            InpLots        = 0.1;      // Lots
input ulong             m_magic        = 15489;    // magic number
ulong                   m_slippage     = 30;       // slippage
//---
int            handle_iCustom_M1;            // variable for storing the handle of the iCustom indicator
int            handle_iCustom_M5;            // variable for storing the handle of the iCustom indicator
int            handle_iCustom_H1;            // variable for storing the handle of the iCustom indicator
double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(InpLots,err_text))
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

//--- create handle of the indicator iCustom
   handle_iCustom_M1=iCustom(m_symbol.Name(),PERIOD_M1,"i-Regr",Inp_degree,Inp_kstd,Inp_bars,Inp_shift);
//--- if the handle is not created
   if(handle_iCustom_M1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iCustom indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//--- create handle of the indicator iCustom
   handle_iCustom_M5=iCustom(m_symbol.Name(),PERIOD_M5,"i-Regr",Inp_degree,Inp_kstd,Inp_bars,Inp_shift);
//--- if the handle is not created
   if(handle_iCustom_M5==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iCustom indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//--- create handle of the indicator iCustom
   handle_iCustom_H1=iCustom(m_symbol.Name(),PERIOD_H1,"i-Regr",Inp_degree,Inp_kstd,Inp_bars,Inp_shift);
//--- if the handle is not created
   if(handle_iCustom_H1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iCustom indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
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
/*static ulong counter=0;
   counter++;
   if((counter%15)!=0)
      return;*/
//---
   if(InpUseTrading==true)
     {
      //--- M1
      double M1_resistance=iCustomGet(handle_iCustom_M1,0,0);
      double M1_resistance_p=iCustomGet(handle_iCustom_M1,0,Inp_bars);
      double M1_support=iCustomGet(handle_iCustom_M1,2,0);
      double slopeM1=M1_resistance-M1_resistance_p;
      //--- M5
      double M5_resistance=iCustomGet(handle_iCustom_M5,0,0);
      double M5_resistance_p=iCustomGet(handle_iCustom_M5,0,Inp_bars);
      double M5_line=iCustomGet(handle_iCustom_M5,1,0);
      double M5_support=iCustomGet(handle_iCustom_M5,2,0);
      double slopeM5=M5_resistance-M5_resistance_p;
      //--- H1
      double H1_resistance=iCustomGet(handle_iCustom_H1,0,0);
      double H1_resistance_p=iCustomGet(handle_iCustom_H1,0,Inp_bars);
      double slopeH1=H1_resistance-H1_resistance_p;
/*
      Comment(
              "\n","M1  Slope | ",slopeM1,
              "\n","M5  Slope | ",slopeM5,
              "\n","H1  Slope | ",slopeH1
              );*/
      //---
      int count_buys=0,count_sells=0;
      CalculatePositions(count_buys,count_sells);
      if(count_buys!=0 && count_sells!=0) // error in logic
         return;
      //--- SHORT ENTRY
      if(slopeH1<0)
        {
         if(count_sells==0)
           {
            double M5High=iHigh(0,m_symbol.Name(),PERIOD_M5);
            if(M5High==0.0)
               return;
            if(M5High>=M5_resistance)
              {
               double M1High=iHigh(0,m_symbol.Name(),PERIOD_M1);
               if(M1High==0.0)
                  return;
               if(M1High>=M1_resistance)
                 {
                  double shortSL=(M5_resistance-M5_line)/2.0;
                  if(!RefreshRates())
                     return;
                  OpenSell(m_symbol.Bid()+shortSL,M5_line);
                  return;
                 }
              }
           }
        }

      //--- LONG ENTRY
      if(slopeH1>0)
        {
         if(count_buys==0)
           {
            double M5Low=iLow(0,m_symbol.Name()1,PERIOD_M5);
            if(M5Low==0.0)
               return;
            if(M5Low<=M5_support)
              {
               double M1Low=iLow(0,m_symbol.Name(),PERIOD_M1);
               if(M1Low==0.0)
                  return;
               if(M1Low<=M1_support)
                 {
                  double longSL=(M5_line-M5_support)/2.0;
                  if(!RefreshRates())
                     return;
                  OpenBuy(m_symbol.Ask()-longSL,M5_line);
                  return;
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//---

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
//| Get value of buffers for the iCustom                             |
//|  the buffer numbers are the following:                           |
//+------------------------------------------------------------------+
double iCustomGet(int handle,const int buffer,const int index)
  {
   double Custom[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iCustom array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle,buffer,index,1,Custom)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iCustom indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(Custom[0]);
  }
//+------------------------------------------------------------------+
//| Calculate positions Buy and Sell                                 |
//+------------------------------------------------------------------+
void CalculatePositions(int &count_buys,int &count_sells)
  {
   count_buys=0.0;
   count_sells=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               count_buys++;

            if(m_position.PositionType()==POSITION_TYPE_SELL)
               count_sells++;
           }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Get the High for specified bar index                             |
//+------------------------------------------------------------------+
double iHigh(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   double High[1];
   double high=0;
   int copied=CopyHigh(symbol,timeframe,index,1,High);
   if(copied>0) high=High[0];
   return(high);
  }
//+------------------------------------------------------------------+
//| Get Low for specified bar index                                  |
//+------------------------------------------------------------------+
double iLow(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   double Low[1];
   double low=0;
   int copied=CopyLow(symbol,timeframe,index,1,Low);
   if(copied>0) low=Low[0];
   return(low);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.Buy(InpLots,NULL,m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
            else
              {
               Print("Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
           }
         else
           {
            Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
           }
        }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.Sell(InpLots,NULL,m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
            else
              {
               Print("Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
           }
         else
           {
            Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
           }
        }
//---
  }
//+-------------------------------------