//+------------------------------------------------------------------+
//|                                             VWAP+ATR CHANNEL.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   4
//--- plot vwap
#property indicator_label1  "VWAP"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//+--------------------------------------------------+
//|  Envelope levels indicator drawing parameters    |
//+--------------------------------------------------+
//---- drawing the levels as lines
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE

//---- selection of levels colors
#property indicator_color2  Purple
#property indicator_color3  Red
#property indicator_color4  Yellow

//---- levels are dott-dash curves
#property indicator_style2 STYLE_DASHDOTDOT
#property indicator_style3 STYLE_DASHDOTDOT
#property indicator_style4 STYLE_SOLID

//---- levels width is equal to 1
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2

//---- display levels labels
#property indicator_label2  "+ Envelope"
#property indicator_label3  "- Envelope"
#property indicator_label4  "Short VWAP"







//--- input parameters
input int      VWAPeriod2 =3;
input int      VWAPeriod =20;
input double Mult_Factor1= 1.5;


ENUM_MA_METHOD MA_METHOD = MODE_EMA;
ENUM_APPLIED_PRICE inpPrice    = PRICE_CLOSE; // Price
int ATRPeriod = 14;

//--- indicator buffers
double VWAPBuffer[], VWAPBuffer2[];
double price[], ATR;
double ExtLineBuffer1[],ExtLineBuffer2[];

int ATR_Handle;

#define _setPrice(_priceType,_target,_index) \
   { \
   switch(_priceType) \
   { \
      case PRICE_CLOSE:    _target = close[_index];                                              break; \
      case PRICE_OPEN:     _target = open[_index];                                               break; \
      case PRICE_HIGH:     _target = high[_index];                                               break; \
      case PRICE_LOW:      _target = low[_index];                                                break; \
      case PRICE_MEDIAN:   _target = (high[_index]+low[_index])/2.0;                             break; \
      case PRICE_TYPICAL:  _target = (high[_index]+low[_index]+close[_index])/3.0;               break; \
      case PRICE_WEIGHTED: _target = (high[_index]+low[_index]+close[_index]+close[_index])/4.0; break; \
      default : _target = 0; \
   }}


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- indicator buffers mapping
   SetIndexBuffer(0,VWAPBuffer);
   SetIndexBuffer(1,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLineBuffer2,INDICATOR_DATA);
   SetIndexBuffer(3,VWAPBuffer2,INDICATOR_DATA);
   SetIndexBuffer(4, price, INDICATOR_CALCULATIONS);
   

//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"VWAP-ATR channel("+string(VWAPeriod)+"," +string(ATRPeriod)+ ")");
   PlotIndexSetString(1,PLOT_LABEL,"+ Envelope");
   PlotIndexSetString(2,PLOT_LABEL,"- Envelope");
   PlotIndexSetString(3,PLOT_LABEL,"Short VWAP");


//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   
//---- set the position, from which the levels drawing starts
   PlotIndexGetInteger(0, PLOT_DRAW_BEGIN,VWAPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ATRPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ATRPeriod);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,ATRPeriod);

//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);


   ATR_Handle=iATR(NULL,PERIOD_CURRENT,ATRPeriod);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");

   
//---
   return(INIT_SUCCEEDED);
}



//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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


   if(rates_total <= VWAPeriod) return(0);

   int pos;
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;


   datetime indtime;
//--- main cycle
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {

         if(i==0) indtime = time[i];
         else indtime = time[i-1];
         // Calculate VWAP 
         _setPrice(inpPrice,price[i],i);
         switch(MA_METHOD)
         {
            case  MODE_SMA :
               VWAPBuffer[i]=VWAP_SMA_Func(i, price, tick_volume, VWAPeriod);
               VWAPBuffer2[i]=VWAP_SMA_Func(i, price, tick_volume, VWAPeriod2);
               break;

            default :
               VWAPBuffer[i]=VWAP_EMA_Func(i, price, tick_volume, VWAPeriod, indtime);
               VWAPBuffer2[i]=VWAP_EMA_Func2(i, price, tick_volume, VWAPeriod2, indtime);
               break;
          }
         double ATRBuffer[1]; 
         CopyBuffer(ATR_Handle,0,time[i],time[i],ATRBuffer);
         ATR = ATRBuffer[0];


          ExtLineBuffer1[i]=VWAPBuffer[i]+ATR*Mult_Factor1;
          ExtLineBuffer2[i]=VWAPBuffer[i]-ATR*Mult_Factor1;
             
      }

//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
}



//+------------------------------------------------------------------+
//| Calculate VWAP                                                   |
//+------------------------------------------------------------------+
double VWAP_SMA_Func(const int pPosition, const double &pPrice[], const long &pVolume[], const int pPeriods)
  {

      double tempPV = 0.;
      double tempVolume = 0.;
      double VWAP = 0;
 
 //     Print("pPosition: ", pPosition, " Time: ", pTime[pPosition]);
           
      if(pPosition>=pPeriods)
      {
         for(int i=0; i<pPeriods; i++)
         {
            tempPV += pPrice[pPosition - i] * (double)pVolume[pPosition - i];
            tempVolume += (double)pVolume[pPosition - i]; 
         }
         VWAP = tempPV / tempVolume;               
      }
   return(VWAP);
  }
  
double VWAP_EMA_Func(const int pPosition, const double &pPrice[], const long &pVolume[], const int pPeriods, datetime pIndTime)
  {

      static datetime calTime;
      double currentEnum = 0.;
      static double prevEnum = 0.;
      double currentNum = 0.;
      static double prevNum = 0.;
      double VWAP = 0.;
      double smoothingFactor = 2./((double)pPeriods +1.);
      
      if(pPosition == 0)
      {
         VWAP = pPrice[pPosition];
         prevEnum = 0.;
         prevNum = 0.;
         calTime = pIndTime;
      }
      else
      {
         currentEnum = smoothingFactor * pPrice[pPosition] * (double)pVolume[pPosition] +
                        (1. - smoothingFactor) * prevEnum ;
         currentNum = smoothingFactor * (double)pVolume[pPosition] + (1. - smoothingFactor) * prevNum ; 
         
         VWAP = currentEnum / currentNum;
         if(pIndTime > calTime)
         {
            prevEnum = currentEnum;
            prevNum = currentNum;
            calTime = pIndTime;
         }     
      } 
   return(VWAP);
  }  
  


double VWAP_EMA_Func2(const int pPosition, const double &pPrice[], const long &pVolume[], const int pPeriods, datetime pIndTime)
  {

      static datetime calTime;
      double currentEnum = 0.;
      static double prevEnum = 0.;
      double currentNum = 0.;
      static double prevNum = 0.;
      double VWAP = 0.;
      double smoothingFactor = 2./((double)pPeriods +1.);

      
      if(pPosition == 0)
      {
         VWAP = pPrice[pPosition];
         prevEnum = 0.;
         prevNum = 0.;
         calTime = pIndTime;

      }
      else
      {
         currentEnum = smoothingFactor * pPrice[pPosition] * (double)pVolume[pPosition] +
                        (1. - smoothingFactor) * prevEnum ;
         currentNum = smoothingFactor * (double)pVolume[pPosition] + (1. - smoothingFactor) * prevNum ; 
         
         VWAP = currentEnum / currentNum;
         if(pIndTime > calTime)
         {
            prevEnum = currentEnum;
            prevNum = currentNum;
            calTime = pIndTime;
         }     
       }  
   return(VWAP);
  }  
