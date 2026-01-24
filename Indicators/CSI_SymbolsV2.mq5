//+------------------------------------------------------------------+
//|                                                  CSI_Symbols.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 38
#property indicator_plots   28
//---
#property indicator_color1  clrBlack
#property indicator_color2  clrBlack
#property indicator_color3  clrBlack
#property indicator_color4  clrBlack
#property indicator_color5  clrBlack
#property indicator_color6  clrBlack
#property indicator_color7  clrBlack
#property indicator_color8  clrBlack
#property indicator_color9  clrBlack
#property indicator_color10 clrBlack
#property indicator_color11 clrBlack
#property indicator_color12 clrBlack
#property indicator_color13 clrBlack
#property indicator_color14 clrBlack
#property indicator_color15 clrBlack
#property indicator_color16 clrBlack
#property indicator_color17 clrBlack
#property indicator_color18 clrBlack
#property indicator_color19 clrBlack
#property indicator_color20 clrBlack
#property indicator_color21 clrBlack
#property indicator_color22 clrBlack
#property indicator_color23 clrBlack
#property indicator_color24 clrBlack
#property indicator_color25 clrBlack
#property indicator_color26 clrBlack
#property indicator_color27 clrYellow
#property indicator_color28 clrBlack



#property indicator_label1   "AUDCAD"
#property indicator_label2   "AUDCHF"
#property indicator_label3   "AUDJPY"
#property indicator_label4   "AUDNZD"
#property indicator_label5   "AUDUSD"
#property indicator_label6   "CADCHF"
#property indicator_label7   "CADJPY"
#property indicator_label8   "CHFJPY"
#property indicator_label9   "EURAUD"
#property indicator_label10  "EURCAD"
#property indicator_label11  "EURCHF"
#property indicator_label12  "EURGBP"
#property indicator_label13  "EURJPY"
#property indicator_label14  "EURNZD"
#property indicator_label15  "EURUSD"
#property indicator_label16  "GBPAUD"
#property indicator_label17  "GBPCAD"
#property indicator_label18  "GBPCHF"
#property indicator_label19  "GBPJPY"
#property indicator_label20  "GBPNZD"
#property indicator_label21  "GBPUSD"
#property indicator_label22  "NZDCAD"
#property indicator_label23  "NZDCHF"
#property indicator_label24  "NZDJPY"
#property indicator_label25  "NZDUSD"
#property indicator_label26  "USDCAD"
#property indicator_label27  "USDCHF"
#property indicator_label28  "USDJPY"


//---
#property indicator_level1 0.0
//+------------------------------------------------------------------+
//--- input variables
input int ma_period_   = 20;
input int ma_delta     = 1;
input int EmaPeriod    = 20;             // EMA period   

/*
input int           XLength1     =5;            //Depth of the first averaging
input int           XLength2     =5;            //Depth of the second averaging
input int           XLength3     =5;            //Depth of the third averaging                   
input int           XPhase       =15;           //Smoothing parameter
*/


//+------------------------------------------------------------------+
//--- indicator buffers for drawing
double    EURx[], // indexes
          GBPx[],
          AUDx[],
          NZDx[],
          USDx[],
          CADx[],
          CHFx[],
          JPYx[];
          
          
          
double   AUDCADx[],
         AUDCHFx[],
         AUDJPYx[],
         AUDNZDx[],
         AUDUSDx[],
         CADCHFx[],
         CADJPYx[],
         CHFJPYx[],
         EURAUDx[],
         EURCADx[],
         EURCHFx[],
         EURGBPx[],
         EURJPYx[],
         EURNZDx[],
         EURUSDx[],
         GBPAUDx[],
         GBPCADx[],
         GBPCHFx[],
         GBPJPYx[],
         GBPNZDx[],
         GBPUSDx[],
         NZDCADx[],
         NZDCHFx[],
         NZDJPYx[],
         NZDUSDx[],
         USDCADx[],
         USDCHFx[],
         USDJPYx[],
         t1_USDCHFx[],
         t2_USDCHFx[];
//         t3_USDCHFx[];
          

//--- currency rates for calculation
double EUR,GBP,AUD,NZD,USD,CAD,CHF,JPY,A1,A2,A3,A4,A5,A6,A7;

//--- Currency names and colors
string Currencies[]= {"EUR","GBP","AUD","NZD","USD","CAD","CHF","JPY"};
int Colors[]= {indicator_color1,  indicator_color2,  indicator_color3,  indicator_color4,
               indicator_color5,  indicator_color6,  indicator_color7,  indicator_color8,
               indicator_color9,  indicator_color10, indicator_color11, indicator_color12,
               indicator_color13, indicator_color14, indicator_color15, indicator_color16,
               indicator_color17, indicator_color18, indicator_color19, indicator_color20,
               indicator_color21, indicator_color22, indicator_color23, indicator_color24,
               indicator_color25, indicator_color26, indicator_color27, indicator_color28               
              };

//--- Class of the "Moving Average" indicator
#include <Indicators\Trend.mqh>
CiMA ma[28];
/*
#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3;
CXMA::Smooth_Method XMA_Method=(int)MODE_EMA; // Averaging method
*/

//---
string symbols[28] =
  {
   "AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD","CADCHF","CADJPY",
   "CHFJPY","EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD",
   "EURUSD","GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD",
   "NZDCAD","NZDCHF","NZDJPY","NZDUSD","USDCAD","USDCHF","USDJPY"
  };
#define AUDCAD 0
#define AUDCHF 1
#define AUDJPY 2
#define AUDNZD 3
#define AUDUSD 4
#define CADCHF 5
#define CADJPY 6
#define CHFJPY 7
#define EURAUD 8
#define EURCAD 9
#define EURCHF 10
#define EURGBP 11
#define EURJPY 12
#define EURNZD 13
#define EURUSD 14
#define GBPAUD 15
#define GBPCAD 16
#define GBPCHF 17
#define GBPJPY 18
#define GBPNZD 19
#define GBPUSD 20
#define NZDCAD 21
#define NZDCHF 22
#define NZDJPY 23
#define NZDUSD 24
#define USDCAD 26
#define USDCHF 26
#define USDJPY 27

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set name to be displayed
   string ShortName="CSI Symbols R-Strength("+(string)ma_period_+"/"+(string)ma_delta+") >>";
   IndicatorSetString(INDICATOR_SHORTNAME,ShortName);

//--- assignment of array to indicator buffer
   SetIndexBuffer(0,AUDCADx,INDICATOR_DATA);
   SetIndexBuffer(1,AUDCHFx,INDICATOR_DATA);
   SetIndexBuffer(2,AUDJPYx,INDICATOR_DATA);
   SetIndexBuffer(3,AUDNZDx,INDICATOR_DATA);
   SetIndexBuffer(4,AUDUSDx,INDICATOR_DATA);
   SetIndexBuffer(5,CADCHFx,INDICATOR_DATA);
   SetIndexBuffer(6,CADJPYx,INDICATOR_DATA);
   SetIndexBuffer(7,CHFJPYx,INDICATOR_DATA);
   SetIndexBuffer(8,EURAUDx,INDICATOR_DATA);
   SetIndexBuffer(9,EURCADx,INDICATOR_DATA);
   SetIndexBuffer(10,EURCHFx,INDICATOR_DATA);
   SetIndexBuffer(11,EURGBPx,INDICATOR_DATA);
   SetIndexBuffer(12,EURJPYx,INDICATOR_DATA);
   SetIndexBuffer(13,EURNZDx,INDICATOR_DATA);
   SetIndexBuffer(14,EURUSDx,INDICATOR_DATA);
   SetIndexBuffer(15,GBPAUDx,INDICATOR_DATA);
   SetIndexBuffer(16,GBPCADx,INDICATOR_DATA);
   SetIndexBuffer(17,GBPCHFx,INDICATOR_DATA);
   SetIndexBuffer(18,GBPJPYx,INDICATOR_DATA);
   SetIndexBuffer(19,GBPNZDx,INDICATOR_DATA);
   SetIndexBuffer(20,GBPUSDx,INDICATOR_DATA);
   SetIndexBuffer(21,NZDCADx,INDICATOR_DATA);
   SetIndexBuffer(22,NZDCHFx,INDICATOR_DATA);
   SetIndexBuffer(23,NZDJPYx,INDICATOR_DATA);
   SetIndexBuffer(24,NZDUSDx,INDICATOR_DATA);
   SetIndexBuffer(25,USDCADx,INDICATOR_DATA);
   SetIndexBuffer(26,USDCHFx,INDICATOR_DATA);
   SetIndexBuffer(27,USDJPYx,INDICATOR_DATA);

   SetIndexBuffer(28,EURx,INDICATOR_CALCULATIONS);
   SetIndexBuffer(29,GBPx,INDICATOR_CALCULATIONS);
   SetIndexBuffer(30,AUDx,INDICATOR_CALCULATIONS);
   SetIndexBuffer(31,NZDx,INDICATOR_CALCULATIONS);
   SetIndexBuffer(32,USDx,INDICATOR_CALCULATIONS);
   SetIndexBuffer(33,CADx,INDICATOR_CALCULATIONS);
   SetIndexBuffer(34,CHFx,INDICATOR_CALCULATIONS);
   SetIndexBuffer(35,JPYx,INDICATOR_CALCULATIONS);

   SetIndexBuffer(36,t1_USDCHFx,INDICATOR_CALCULATIONS);
   SetIndexBuffer(37,t2_USDCHFx,INDICATOR_CALCULATIONS);
//   SetIndexBuffer(38,t3_USDCHFx,INDICATOR_CALCULATIONS);

   

//--- set up indicator buffers
   for(int i=0; i < ArraySize(symbols); i++)
     {
      PlotIndexSetInteger(i,PLOT_DRAW_TYPE,DRAW_LINE);
      PlotIndexSetInteger(i,PLOT_LINE_STYLE,STYLE_SOLID);
      PlotIndexSetInteger(i,PLOT_LINE_WIDTH,1);
      PlotIndexSetDouble(i,PLOT_EMPTY_VALUE,0);
      PlotIndexSetString(i,PLOT_LABEL,symbols[i]);
     }

//--- set AsSeries
   ArraySetAsSeries(AUDCADx,true);
   ArraySetAsSeries(AUDCHFx,true);
   ArraySetAsSeries(AUDJPYx,true);
   ArraySetAsSeries(AUDNZDx,true);
   ArraySetAsSeries(AUDUSDx,true);
   ArraySetAsSeries(CADCHFx,true);
   ArraySetAsSeries(CADJPYx,true);
   ArraySetAsSeries(CHFJPYx,true);
   ArraySetAsSeries(EURAUDx,true);
   ArraySetAsSeries(EURCADx,true);
   ArraySetAsSeries(EURCHFx,true);
   ArraySetAsSeries(EURGBPx,true);
   ArraySetAsSeries(EURJPYx,true);
   ArraySetAsSeries(EURNZDx,true);
   ArraySetAsSeries(EURUSDx,true);
   ArraySetAsSeries(GBPAUDx,true);
   ArraySetAsSeries(GBPCADx,true);
   ArraySetAsSeries(GBPCHFx,true);
   ArraySetAsSeries(GBPJPYx,true);
   ArraySetAsSeries(GBPNZDx,true);
   ArraySetAsSeries(GBPUSDx,true);
   ArraySetAsSeries(NZDCADx,true);
   ArraySetAsSeries(NZDCHFx,true);
   ArraySetAsSeries(NZDJPYx,true);
   ArraySetAsSeries(NZDUSDx,true);
   ArraySetAsSeries(USDCADx,true);
   ArraySetAsSeries(USDCHFx,true);
   ArraySetAsSeries(USDJPYx,true);

   ArraySetAsSeries(t1_USDCHFx,true);
   ArraySetAsSeries(t2_USDCHFx,true);
//   ArraySetAsSeries(t3_USDCHFx,true);

   ArrayInitialize(t1_USDCHFx,0.);
   ArrayInitialize(t2_USDCHFx,0.);
//   ArrayInitialize(t3_USDCHFx,0.);



   ArraySetAsSeries(EURx,true);
   ArraySetAsSeries(GBPx,true);
   ArraySetAsSeries(AUDx,true);
   ArraySetAsSeries(NZDx,true);
   ArraySetAsSeries(USDx,true);
   ArraySetAsSeries(CADx,true);
   ArraySetAsSeries(CHFx,true);
   ArraySetAsSeries(JPYx,true);



   if(!CreateHandles())
      //--- the indicator is stopped early
      return(INIT_FAILED);

//--- normal initialization of the indicator
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- delete all objects we created
   ObjectsDeleteAll(0,"obj_csi_");
  }


//+-------------------------------------------------------------------+
//| Create handles of the moving average indicators                   |
//+-------------------------------------------------------------------+
bool CreateHandles()
  {
//--- symbol suffix of the current chart symbol
   string SymbolSuffix=StringSubstr(Symbol(),6,StringLen(Symbol())-6);

//--- create handles of the indicator
   for(int i=0; i < ArraySize(symbols); i++)
     {
      string symbol=symbols[i]+SymbolSuffix;
      //---
      if(!CheckMarketWatch(symbol))
        {
         //--- if symbol is not in the market watch
         return(false);
        }
      //---
      if(!ma[i].Create(symbol,PERIOD_CURRENT,ma_period_,0,MODE_LWMA,PRICE_CLOSE))
        {
         //--- if the handle is not created
         Print(__FUNCTION__,
               ": failed to create handle of iMA indicator for symbol ",symbol);
         return(false);
        }
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Checks if symbol is selected in the MarketWatch                  |
//| and adds symbol to the MarketWatch, if necessary                 |
//+------------------------------------------------------------------+
bool CheckMarketWatch(string symbol)
  {
//--- check if symbol is selected in the MarketWatch
   if(!SymbolInfoInteger(symbol,SYMBOL_SELECT))
     {
      if(GetLastError()==ERR_MARKET_UNKNOWN_SYMBOL)
        {
         printf(__FUNCTION__+": Unknown symbol '%s'",symbol);
         return(false);
        }
      if(!SymbolSelect(symbol,true))
        {
         printf(__FUNCTION__+": Error adding symbol %d",GetLastError());
         return(false);
        }
     }
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Checks terminal history for specified symbol's timeframe and     |
//| downloads it from server, if necessary                           |
//+------------------------------------------------------------------+
void CheckLoadHistory(string symbol,ENUM_TIMEFRAMES period,const int size)
  {
//--- ask for built bars
   if(Bars(symbol,period)<size)
     {
      //--- copying of next part forces data loading
      datetime times[1];
      CopyTime(symbol,period,size-1,1,times);
     }
  }
  
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
double alpha = 2.0 / (1.0+MathSqrt(EmaPeriod));
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
//--- the necessary amount of data to be calculated
   int limit=rates_total;
//---
   for(int i=0; i < ArraySize(ma); i++)
     {
      //--- check if all data is calculated
      if(ma[i].BarsCalculated()<0)
        {
         Print(__FUNCTION__+": ",symbols[i]," not ready.");
         CheckLoadHistory(symbols[i],PERIOD_CURRENT,1000);
         return(0);
        }
      //--- update the ma indicator data
      ma[i].Refresh();

      //--- the amount of calculated data for the ma indicator
      limit=(int)MathMin(limit,ma[i].BarsCalculated());
     }

//--- checking for the first start of the indicator calculation
   if(prev_calculated>rates_total || prev_calculated<=0)
     {
      limit=limit-ma_delta;
     }
   else
      limit=rates_total-prev_calculated+1;

//--- https://www.tradingview.com/chart/GBPUSD/CjY0z8cG-Trading-the-STRONG-against-the-weak-currency-strength-calc/
//--- https://www.mql5.com/en/articles/83
//--- http://fxcorrelator.wixsite.com/nvp100
   for(int i=0; i<limit; i++)
     {
         A1=ma[EURGBP].Main(i)/ma[EURGBP].Main(i+ma_delta);  //EURGBP
         A2=ma[EURAUD].Main(i)/ma[EURAUD].Main(i+ma_delta);  //EURAUD
         A3=ma[EURNZD].Main(i)/ma[EURNZD].Main(i+ma_delta);  //EURNZD
         A4=ma[EURUSD].Main(i)/ma[EURUSD].Main(i+ma_delta);  //EURUSD
         A5=ma[EURCAD].Main(i)/ma[EURCAD].Main(i+ma_delta);  //EURCAD
         A6=ma[EURCHF].Main(i)/ma[EURCHF].Main(i+ma_delta);  //EURCHF
         A7=ma[EURJPY].Main(i)/ma[EURJPY].Main(i+ma_delta);  //EURJPY
         EUR=(A1*A2*A3*A4*A5*A6*A7)-1;
         EURx[i]=EUR;

         A1=ma[EURGBP].Main(i)/ma[EURGBP].Main(i+ma_delta);  //EURGBP*
         A2=ma[GBPAUD].Main(i)/ma[GBPAUD].Main(i+ma_delta);  //GBPAUD
         A3=ma[GBPNZD].Main(i)/ma[GBPNZD].Main(i+ma_delta);  //GBPNZD
         A4=ma[GBPUSD].Main(i)/ma[GBPUSD].Main(i+ma_delta);  //GBPUSD
         A5=ma[GBPCAD].Main(i)/ma[GBPCAD].Main(i+ma_delta);  //GBPCAD
         A6=ma[GBPCHF].Main(i)/ma[GBPCHF].Main(i+ma_delta);  //GBPCHF
         A7=ma[GBPJPY].Main(i)/ma[GBPJPY].Main(i+ma_delta);  //GBPJPY
         GBP=(1/A1*A2*A3*A4*A5*A6*A7)-1;
         GBPx[i]=GBP;

         A1=ma[EURAUD].Main(i)/ma[EURAUD].Main(i+ma_delta);  //EURAUD*
         A2=ma[GBPAUD].Main(i)/ma[GBPAUD].Main(i+ma_delta);  //GBPAUD*
         A3=ma[AUDNZD].Main(i)/ma[AUDNZD].Main(i+ma_delta);  //AUDNZD
         A4=ma[AUDUSD].Main(i)/ma[AUDUSD].Main(i+ma_delta);  //AUDUSD
         A5=ma[AUDCAD].Main(i)/ma[AUDCAD].Main(i+ma_delta);  //AUDCAD
         A6=ma[AUDCHF].Main(i)/ma[AUDCHF].Main(i+ma_delta);  //AUDCHF
         A7=ma[AUDJPY].Main(i)/ma[AUDJPY].Main(i+ma_delta);  //AUDJPY
         AUD=(1/A1*1/A2*A3*A4*A5*A6*A7)-1;
         AUDx[i]=AUD;

         A1=ma[EURNZD].Main(i)/ma[EURNZD].Main(i+ma_delta);  //EURNZD*
         A2=ma[GBPNZD].Main(i)/ma[GBPNZD].Main(i+ma_delta);  //GBPNZD*
         A3=ma[AUDNZD].Main(i)/ma[AUDNZD].Main(i+ma_delta);  //AUDNZD*
         A4=ma[NZDUSD].Main(i)/ma[NZDUSD].Main(i+ma_delta);  //NZDUSD
         A5=ma[NZDCAD].Main(i)/ma[NZDCAD].Main(i+ma_delta);  //NZDCAD
         A6=ma[NZDCHF].Main(i)/ma[NZDCHF].Main(i+ma_delta);  //NZDCHF
         A7=ma[NZDJPY].Main(i)/ma[NZDJPY].Main(i+ma_delta);  //NZDJPY
         NZD=(1/A1*1/A2*1/A3*A4*A5*A6*A7)-1;
         NZDx[i]=NZD;

         A1=ma[EURUSD].Main(i)/ma[EURUSD].Main(i+ma_delta);  //EURUSD*
         A2=ma[GBPUSD].Main(i)/ma[GBPUSD].Main(i+ma_delta);  //GBPUSD*
         A3=ma[AUDUSD].Main(i)/ma[AUDUSD].Main(i+ma_delta);  //AUDUSD*
         A4=ma[NZDUSD].Main(i)/ma[NZDUSD].Main(i+ma_delta);  //NZDUSD*
         A5=ma[USDCAD].Main(i)/ma[USDCAD].Main(i+ma_delta);  //USDCAD
         A6=ma[USDCHF].Main(i)/ma[USDCHF].Main(i+ma_delta);  //USDCHF
         A7=ma[USDJPY].Main(i)/ma[USDJPY].Main(i+ma_delta);  //USDJPY
         USD=(1/A1*1/A2*1/A3*1/A4*A5*A6*A7)-1;
         USDx[i]=USD;

         A1=ma[EURCAD].Main(i)/ma[EURCAD].Main(i+ma_delta);  //EURCAD*
         A2=ma[GBPCAD].Main(i)/ma[GBPCAD].Main(i+ma_delta);  //GBPCAD*
         A3=ma[AUDCAD].Main(i)/ma[AUDCAD].Main(i+ma_delta);  //AUDCAD*
         A4=ma[NZDCAD].Main(i)/ma[NZDCAD].Main(i+ma_delta);  //NZDCAD*
         A5=ma[USDCAD].Main(i)/ma[USDCAD].Main(i+ma_delta);  //USDCAD*
         A6=ma[CADCHF].Main(i)/ma[CADCHF].Main(i+ma_delta);  //CADCHF
         A7=ma[CADJPY].Main(i)/ma[CADJPY].Main(i+ma_delta);  //CADJPY
         CAD=(1/A1*1/A2*1/A3*1/A4*1/A5*A6*A7)-1;
         CADx[i]=CAD;

         A1=ma[EURCHF].Main(i)/ma[EURCHF].Main(i+ma_delta);  //EURCHF*
         A2=ma[GBPCHF].Main(i)/ma[GBPCHF].Main(i+ma_delta);  //GBPCHF*
         A3=ma[AUDCHF].Main(i)/ma[AUDCHF].Main(i+ma_delta);  //AUDCHF*
         A4=ma[NZDCHF].Main(i)/ma[NZDCHF].Main(i+ma_delta);  //NZDCHF*
         A5=ma[USDCHF].Main(i)/ma[USDCHF].Main(i+ma_delta);  //USDCHF*
         A6=ma[CADCHF].Main(i)/ma[CADCHF].Main(i+ma_delta);  //CADCHF*
         A7=ma[CHFJPY].Main(i)/ma[CHFJPY].Main(i+ma_delta);  //CHFJPY
         CHF=(1/A1*1/A2*1/A3*1/A4*1/A5*1/A6*A7)-1;
         CHFx[i]=CHF;

         A1=ma[EURJPY].Main(i)/ma[EURJPY].Main(i+ma_delta);  //EURJPY*
         A2=ma[GBPJPY].Main(i)/ma[GBPJPY].Main(i+ma_delta);  //GBPJPY*
         A3=ma[AUDJPY].Main(i)/ma[AUDJPY].Main(i+ma_delta);  //AUDJPY*
         A4=ma[NZDJPY].Main(i)/ma[NZDJPY].Main(i+ma_delta);  //NZDJPY*
         A5=ma[USDJPY].Main(i)/ma[USDJPY].Main(i+ma_delta);  //USDJPY*
         A6=ma[CADJPY].Main(i)/ma[CADJPY].Main(i+ma_delta);  //CADJPY*
         A7=ma[CHFJPY].Main(i)/ma[CHFJPY].Main(i+ma_delta);  //CHFJPY*
         JPY=(1/A1*1/A2*1/A3*1/A4*1/A5*1/A6*1/A7)-1;
         JPYx[i]=JPY;
       
// relative strength of symbols
         AUDCADx[i]=AUD-CAD;
         AUDCHFx[i]=AUD-CHF;
         AUDJPYx[i]=AUD-JPY;
         AUDNZDx[i]=AUD-NZD;
         AUDUSDx[i]=AUD-USD;
         CADCHFx[i]=CAD-CHF;
         CADJPYx[i]=CAD-JPY;
         CHFJPYx[i]=CHF-JPY;
         EURAUDx[i]=EUR-AUD;
         EURCADx[i]=EUR-CAD;
         EURCHFx[i]=EUR-CHF;
         EURGBPx[i]=EUR-GBP;
         EURJPYx[i]=EUR-JPY;
         EURNZDx[i]=EUR-NZD;
         EURUSDx[i]=EUR-USD;
         GBPAUDx[i]=GBP-AUD;
         GBPCADx[i]=GBP-CAD;
         GBPCHFx[i]=GBP-CHF;
         GBPJPYx[i]=GBP-JPY;
         GBPNZDx[i]=GBP-NZD;
         GBPUSDx[i]=GBP-USD;
         NZDCADx[i]=NZD-CAD;
         NZDCHFx[i]=NZD-CHF;
         NZDJPYx[i]=NZD-JPY;
         NZDUSDx[i]=NZD-USD;
         USDCADx[i]=USD-CAD;
         t1_USDCHFx[i]=(USD-CHF);
         USDJPYx[i]=USD-JPY;           
     }
//--- return the prev_calculated value for the next call
   if(prev_calculated>rates_total || prev_calculated<=0)
     {
      limit=limit-1;
     }
   else
      limit=rates_total-prev_calculated;

   for(int i=limit; i>=0; i--)
     {

      if(!MathIsValidNumber(t1_USDCHFx[i])) continue;
      
      t2_USDCHFx[i] = t2_USDCHFx[i+1]+alpha*(t1_USDCHFx[i]-t2_USDCHFx[i+1]);
      USDCHFx[i] = USDCHFx[i+1]+alpha*(t2_USDCHFx[i]-USDCHFx[i+1]);
      
     }

   return(rates_total);
  }
//+--------------------------
