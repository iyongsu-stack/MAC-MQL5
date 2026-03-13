//+------------------------------------------------------------------+
//|                                                          QQE.mq5 |
//|                                     Original © 2006 Roman Ignatov|
//| AIEngine clean version — file writing logic removed              |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006 Roman Ignatov (MQL5 Port)"
#property link      "mailto:roman.ignatov@gmail.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   2

#property indicator_label1  "RSI MA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "QQE Line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_DOT
#property indicator_width2  2

input int SF = 12;
input int RSI_Period = 32;

double RsiMaBuffer[];
double TrLevelSlowBuffer[];
double RsiBuffer[];
double AtrRsiBuffer[];
double MaAtrRsiBuffer[];
double DarBuffer[];

int Wilders_Period;
int handle_RSI;

int OnInit()
  {
   Wilders_Period = RSI_Period * 2 - 1;

   SetIndexBuffer(0, RsiMaBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, TrLevelSlowBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, RsiBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, AtrRsiBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, MaAtrRsiBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, DarBuffer, INDICATOR_CALCULATIONS);

   string short_name = StringFormat("QQE(%d, %d)", RSI_Period, SF);
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);

   handle_RSI = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE);
   if(handle_RSI == INVALID_HANDLE)
     {
      Print("Failed to create RSI handle");
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total < Wilders_Period) return(0);

   int copy_count = CopyBuffer(handle_RSI, 0, 0, rates_total, RsiBuffer);
   if(copy_count <= 0) return(0);

   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      ArrayInitialize(RsiMaBuffer,0.0);
      ArrayInitialize(AtrRsiBuffer,0.0);
      ArrayInitialize(MaAtrRsiBuffer,0.0);
      ArrayInitialize(DarBuffer,0.0);
      ArrayInitialize(TrLevelSlowBuffer,0.0);
     }

   int start = prev_calculated - 1;
   if(start < 0) start = 0;

   for(int i = start; i < rates_total; i++)
     {
      if(RsiBuffer[i] == EMPTY_VALUE)
        {
         RsiMaBuffer[i] = 0.0;
         AtrRsiBuffer[i] = 0.0;
         MaAtrRsiBuffer[i] = 0.0;
         DarBuffer[i] = 0.0;
         TrLevelSlowBuffer[i] = 0.0;
         continue;
        }

      if(i == 0 || RsiMaBuffer[i-1] == 0.0)
        {
         RsiMaBuffer[i] = RsiBuffer[i];
         AtrRsiBuffer[i] = 0;
         MaAtrRsiBuffer[i] = 0;
         DarBuffer[i] = 0;
         TrLevelSlowBuffer[i] = RsiMaBuffer[i];
         continue;
        }

      double alpha_sf = 2.0 / (SF + 1.0);
      RsiMaBuffer[i] = RsiBuffer[i] * alpha_sf + RsiMaBuffer[i-1] * (1.0 - alpha_sf);

      AtrRsiBuffer[i] = MathAbs(RsiMaBuffer[i] - RsiMaBuffer[i-1]);

      double alpha_wilder = 2.0 / (Wilders_Period + 1.0);
      MaAtrRsiBuffer[i] = AtrRsiBuffer[i] * alpha_wilder + MaAtrRsiBuffer[i-1] * (1.0 - alpha_wilder);

      DarBuffer[i] = MaAtrRsiBuffer[i] * alpha_wilder + DarBuffer[i-1] * (1.0 - alpha_wilder);
      
      double dar = DarBuffer[i] * 4.236;

      double rsi0 = RsiMaBuffer[i];
      double rsi1 = RsiMaBuffer[i-1];
      double tr   = TrLevelSlowBuffer[i-1];
      double dv   = tr;

      if(rsi0 < tr)
        {
         tr = rsi0 + dar;
         if(rsi1 < dv)
           {
            if(tr > dv) tr = dv;
           }
        }
      else if(rsi0 > tr)
        {
         tr = rsi0 - dar;
         if(rsi1 > dv)
           {
            if(tr < dv) tr = dv;
           }
        }

      TrLevelSlowBuffer[i] = tr;
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
