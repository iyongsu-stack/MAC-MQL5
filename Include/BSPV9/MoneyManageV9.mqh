//+------------------------------------------------------------------+
//|                                                MoneyManageV6.mqh |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"

//#include <BSPV7/ExternVariables.mqh>
//#include <BSPV7/MagicNumberV7.mqh>
//#include <BSPV7/SessionManV7.mqh>

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

//+------------------------------------------------------------------+
//| CalculatePyramidLotSize — 피라미딩 포함 총 리스크 제한 랏 계산     |
//| =============================================================     |
//| 핵심: worst-case (base + 모든 addon이 SL 히트) 총 손실을          |
//|       계좌 잔고의 pRiskDecimal%로 제한하는 base lot 계산           |
//|                                                                    |
//| 공식:                                                              |
//|   worst_ATR_lots = SL_mult × 1.0                                  |
//|     + Σ (SL_mult + spacing×n) × lot_ratio^n  (n=1..max_addon)     |
//|                                                                    |
//|   base_lot = (Capital × Risk) / (worst_ATR_lots × ATR × TickValue)|
//|                                                                    |
//| 기본값 (SL=7, addon 3회, ratio=0.50, spacing=1.5ATR):             |
//|   worst = 7.0 + 4.25 + 2.50 + 1.4375 = 15.1875 ATR-lots          |
//+------------------------------------------------------------------+
double CalculatePyramidLotSize(double pRiskDecimal,     // 리스크 비율 (0.01 = 1%)
                               double pATR14,           // ATR14 (가격 단위, 포인트 아님)
                               int    pMaxAddon    = 3, // 최대 피라미딩 횟수
                               double pSLMult      = 7.0,  // SL = SL_mult × ATR
                               double pLotRatio    = 0.50, // 정피라미드 비율
                               double pAddonSpacing= 1.5)  // addon 최소 간격 (ATR 단위)
{
   // 1. Worst-case ATR-lots 계산
   double worstTotal = pSLMult * 1.0;  // base position
   double lotMult = 1.0;
   for(int n = 1; n <= pMaxAddon; n++)
   {
      lotMult *= pLotRatio;
      double addonSLDist = pSLMult + pAddonSpacing * n;
      worstTotal += addonSLDist * lotMult;
   }

   // 2. 가용 자본 결정
   double moneyCapital;
   switch(iRisk_AvailableCapital)
   {
      case FREEMARGIN: moneyCapital = AccountInfoDouble(ACCOUNT_MARGIN_FREE); break;
      case BALANCE:    moneyCapital = AccountInfoDouble(ACCOUNT_BALANCE);     break;
      case EQUITY:     moneyCapital = AccountInfoDouble(ACCOUNT_EQUITY);      break;
      default:         moneyCapital = AccountInfoDouble(ACCOUNT_BALANCE);     break;
   }

   // 3. ATR를 포인트로 변환
   double onePoint  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   if(onePoint <= 0 || tickValue <= 0 || tickSize <= 0 || pATR14 <= 0)
      return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   // worstTotal은 ATR 단위 → 가격 단위로 변환 후 tick 수 계산
   double worstPriceDistance = worstTotal * pATR14;  // 가격 단위
   double worstTicks = worstPriceDistance / tickSize;

   // 4. base lot 계산
   double moneyRisk = pRiskDecimal * moneyCapital;
   double baseLot = moneyRisk / (worstTicks * tickValue);
   baseLot *= _CurrencyMultiplicator(iCommon_CurrencyPairAppendix);

   // 5. 마진 상한 체크
   double marginForOneLot;
   double lotsByMargin;
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1, SymbolInfoDouble(_Symbol, SYMBOL_ASK), marginForOneLot))
   {
      lotsByMargin = moneyCapital * 0.98 / marginForOneLot;
      lotsByMargin = NormalizeLots(lotsByMargin);
   }
   else
   {
      lotsByMargin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   }

   baseLot = NormalizeLots(baseLot);
   baseLot = MathMax(MathMin(baseLot, lotsByMargin), SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));

   // 6. lot 자릿수 정규화
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int lotDigit = 2;
   if(lotStep == 1) lotDigit = 0;
   else if(lotStep == 0.1) lotDigit = 1;
   else if(lotStep == 0.01) lotDigit = 2;

   baseLot = NormalizeDouble(baseLot, lotDigit);

   PrintFormat("[PyramidLot] Capital=%.0f, ATR=%.2f, Worst=%.3f ATR-lots, baseLot=%.2f",
               moneyCapital, pATR14, worstTotal, baseLot);

   return baseLot;
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

/*
void StopLossFunction()
{
   double m_Balance, m_LossPercent, m_SLPercent;
   if(!SLStart) return;

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
*/

