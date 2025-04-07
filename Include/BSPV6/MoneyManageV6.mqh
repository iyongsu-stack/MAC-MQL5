//+------------------------------------------------------------------+
//|                                                MoneyManageV6.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV6/ExternVariables.mqh>
//#include <BSPV6/MagicNumberV6.mqh>
//#include <BSPV6/SessionManV6.mqh>

void StopLossFunction()
{
   double m_Balance, m_LossPercent, m_SLPercent;
   if(!VirtualSL) return;

   m_SLPercent=1.-SLPercent;   
   m_Balance=AccountInfoDouble(ACCOUNT_BALANCE);
   for(int m_Session=1;m_Session<TotalSession;m_Session++)
     {
      m_LossPercent=(m_Balance+PositionSummary[m_Session].evenProfit)/m_Balance;
      if(m_LossPercent<m_SLPercent)
        {
          ClosePositionBySession(m_Session);
          ReOCReset(m_Session);  
          InitPositionSum(m_Session); 
          CurPM[m_Session]=End;
          SessionManage(m_Session);
        }
     }
}

//------------------------------------------------------------------------------------------------------------------
void CalcProfit()
{
   int m_Session, m_PositionMN;
   ENUM_POSITION_TYPE m_PositionType;
   double m_Volume, m_Profit;
   string m_PositionSymbol;

   if(!Sym.RefreshRates())return;        

   int total=PositionsTotal();
   if(total<=0)
      return;
      
   for(int i=0;i<TotalSession;i++)
     {
      PositionSummary[i].evenSize=0.;
      PositionSummary[i].evenProfit=0.;
     }

   for(int i=(total -1); i>=0; i--)
     {
      if(! Pos.SelectByIndex(i))
        {
         Alert("Position Selection Error");
         return;
        }

      m_PositionMN = (int)Pos.Magic();
      m_PositionSymbol=Pos.Symbol();

      if(m_PositionSymbol==_Symbol && BaseMagicNumber==PositionBMN(m_PositionMN) )
        {
         m_Session=SessionByMN(m_PositionMN);
         m_PositionType=Pos.PositionType();
         m_Volume=Pos.Volume();
         m_Profit=Pos.Profit();
         
         if(m_PositionType==POSITION_TYPE_BUY) PositionSummary[m_Session].evenSize+=m_Volume;
         else PositionSummary[m_Session].evenSize-=m_Volume;
         
         PositionSummary[m_Session].evenProfit+=m_Profit;
        }      
     }
   return;
}



//-------------------------------------------------------------------------------------------------------------------
double CalculateLotSize(double pRiskDecimal, int pStoplossPoints) 
{
   // Calculate LotSize based on Equity, Risk in decimal and StopLoss in points
   double _moneyRisk, _lotsByRequiredMargin, _lotsByRisk, _lotSize, _marginForOneLot, _MoneyCapital;
   int _lotdigit = 2, _totalSLPoints, _totalTickCount, _ExtraPriceGapPoints;

   // Get available money
   switch (iRisk_AvailableCapital) 
   {
      case FREEMARGIN:
         _MoneyCapital = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         break;
      case BALANCE:
         _MoneyCapital = AccountInfoDouble(ACCOUNT_BALANCE);
         break;
      case EQUITY:
         _MoneyCapital = AccountInfoDouble(ACCOUNT_EQUITY);
         break;
      default:
         _MoneyCapital = AccountInfoDouble(ACCOUNT_BALANCE);
         break;
   }

   // Calculate Lot size according to Equity.
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1, SymbolInfoDouble(_Symbol, SYMBOL_ASK), _marginForOneLot) ) 
   { // Calculate margin required for 1 lot
      _lotsByRequiredMargin = _MoneyCapital * 0.98 / _marginForOneLot;
      _lotsByRequiredMargin = MathMin(_lotsByRequiredMargin, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
      _lotsByRequiredMargin = NormalizeLots(_lotsByRequiredMargin);
   } 
   else
   {
      _lotsByRequiredMargin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   }

   double _oneTickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE); // Tick value of the asset

   _moneyRisk = pRiskDecimal * _MoneyCapital;
   _ExtraPriceGapPoints=(int)SymbolInfoInteger(NULL, SYMBOL_SPREAD);
   _totalSLPoints = pStoplossPoints + _ExtraPriceGapPoints;
   _totalTickCount = ToTicksCount(_totalSLPoints);

   // Calculate the Lot size according to Risk.
   _lotsByRisk = _moneyRisk / (_totalTickCount * _oneTickValue);
   _lotsByRisk = _lotsByRisk * _CurrencyMultiplicator(iCommon_CurrencyPairAppendix);
   _lotsByRisk = NormalizeLots( _lotsByRisk);

   _lotSize = MathMax(MathMin(_lotsByRisk, _lotsByRequiredMargin), SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));

   double _lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP); // Step in lot size changing
   if(_lotStep ==  1) _lotdigit = 0;
   else if(_lotStep == 0.1) _lotdigit = 1;
   else if(_lotStep == 0.01) _lotdigit = 2;

   _lotSize = NormalizeDouble(_lotSize, _lotdigit);
   return (_lotSize);
}

//---------------------------------------------------------------------------------------------------------
double NormalizeLots(double pLots) 
{
   double uvolumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double ulots = round(pLots / uvolumeStep) * uvolumeStep; //-- normallize to a multiple of lotstep accepted by the broker
   return ulots;
}

//------------------------------------------------------------------------------------------------------------
int ToTicksCount(int pPointsCount) 
{
      // https://forum.mql4.com/43064#515262 for non-currency DE30:
      // SymbolInfoDouble(chart.symbol, SYMBOL_TRADE_TICK_SIZE) returns 0.5
      // SymbolInfoInteger(chart.symbol,SYMBOL_DIGITS) returns 1
      // SymbolInfoInteger(chart.symbol,SYMBOL_POINT) returns 0.1
      // Prices to open must be a multiple of ticksize
   double uticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   int utickscount = int(round(pPointsCount / uticksize) * uticksize); //-- fix prices by ticksize
   return utickscount;
}

//--------------------------------------------------------------------------------------------------------------
double _CurrencyMultiplicator(string pCurrencyPairAppendix = "") 
{
   double _multiplicator = 1.0;
   string xCurrency = AccountInfoString(ACCOUNT_CURRENCY);
   StringToUpper(xCurrency);

   if(xCurrency == "USD")
      return (_multiplicator);
   if(xCurrency == "EUR")
      _multiplicator = 1.0 / SymbolInfoDouble("EURUSD" + pCurrencyPairAppendix, SYMBOL_BID);
   if(xCurrency == "GBP")
      _multiplicator = 1.0 / SymbolInfoDouble("GBPUSD" + pCurrencyPairAppendix, SYMBOL_BID);
   if(xCurrency == "AUD")
      _multiplicator = 1.0 / SymbolInfoDouble("AUDUSD" + pCurrencyPairAppendix, SYMBOL_BID);
   if(xCurrency == "NZD")
      _multiplicator = 1.0 / SymbolInfoDouble("NZDUSD" + pCurrencyPairAppendix, SYMBOL_BID);
   if(xCurrency == "CHF")
      _multiplicator = SymbolInfoDouble("USDCHF" + pCurrencyPairAppendix, SYMBOL_BID);
   if(xCurrency == "JPY")
      _multiplicator = SymbolInfoDouble("USDJPY" + pCurrencyPairAppendix, SYMBOL_BID);
   if(xCurrency == "CAD")
      _multiplicator = SymbolInfoDouble("USDCAD" + pCurrencyPairAppendix, SYMBOL_BID);
   if(_multiplicator == 0)
      _multiplicator = 1.0; // If account currency is neither of EUR, GBP, AUD, NZD, CHF, JPY or CAD we assumes that it is USD
   return (_multiplicator);
}
