//+------------------------------------------------------------------+
//|                                            SSLchannelMTF_ATR.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_chart_window 
#property indicator_buffers 2 
#property indicator_plots   2
#property indicator_label1  "Bears"
#property indicator_color1 clrOrange
#property indicator_type1   DRAW_LINE
#property indicator_width1  2
#property indicator_label2  "Bulls"
#property indicator_color2 clrAqua
#property indicator_type2   DRAW_LINE
#property indicator_width2  2

                           
#define INDICATOR_NAME "SSLchannel"     

//#property indicator_color1 clrDodgerBlue,clrDeepPink
//#property indicator_label1  "MACD_ANGLE_HTF"

///+----------------------------------------------+ 

input ENUM_TIMEFRAMES      TimeFrame = PERIOD_H1;
input ENUM_MA_METHOD MA_Method = MODE_SMA;  // Method
input int Lb = 10;
input double Mult_Factor1= 1.5;


int ATRPeriod = 14;

double UpIndBuffer[], DnIndBuffer[], ATR;
int LTHandle, UpBuffNumb=0, DnBuffNumb=1, ATR_Handle;

int OnInit()
{
   //
   //--- indicator buffers mapping
   //
         SetIndexBuffer(0,UpIndBuffer, INDICATOR_DATA);
         SetIndexBuffer(1,DnIndBuffer, INDICATOR_DATA);
//         SetIndexBuffer(2, ATRBuffer, INDICATOR_CALCULATIONS);

         
//         SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
   //
//         string shortname;
//         StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame),")");
//         fisherHandle=iCustom(Symbol(),TimeFrame,"FisherTransform",10,0);

         LTHandle = iCustom(_Symbol, TimeFrame, "SSLchannel", MA_Method, Lb ); 
         Sleep(3000);
         
//         ArraySetAsSeries(ATRBuffer, true);
         ATR_Handle=iATR(NULL,PERIOD_CURRENT,ATRPeriod);
         Sleep(3000);
         if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");


         return (INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{


   if(BarsCalculated(LTHandle)<Bars(Symbol(),TimeFrame))
   {
      int j = BarsCalculated(LTHandle);
      int k = Bars(Symbol(),TimeFrame);
      Print(j, k);
    return(prev_calculated);
   }

   datetime IndTime[1];
   double TempUpInd, TempDnInd;

   int i= prev_calculated-1; if (i<0) i=0; for (; i<rates_total && !_StopFlag; i++)
   {

      double ATRBuffer[1]; 
      CopyBuffer(ATR_Handle,0,time[i],time[i],ATRBuffer);
      ATR = ATRBuffer[0];
 
      CopyTime(_Symbol,TimeFrame,time[i],1,IndTime);

      if(i == 0)
      {
         UpIndBuffer[i]=0.;
         DnIndBuffer[i]=0.;
      }
      else if(time[i]>=IndTime[0] && time[i-1]<IndTime[0])
      {
         double UpInd[1], DnInd[1];
         CopyBuffer(LTHandle,UpBuffNumb,time[i],1,UpInd);
         CopyBuffer(LTHandle,DnBuffNumb,time[i],1,DnInd);
         
         UpIndBuffer[i]=UpInd[0]; 
         DnIndBuffer[i] = DnInd[0];
         TempUpInd = UpInd[0];
         TempDnInd = DnInd[0];

      }
      else
      {
         UpIndBuffer[i]=TempUpInd;
         DnIndBuffer[i]=TempDnInd;

      }
      
      
         if(UpIndBuffer[i] >= DnIndBuffer[i])
         {
            UpIndBuffer[i] += ATR*Mult_Factor1;
            DnIndBuffer[i] -= ATR*Mult_Factor1;
         }
        else
        {
            UpIndBuffer[i] -= ATR*Mult_Factor1;
            DnIndBuffer[i] += ATR*Mult_Factor1;
      
        }


      
      
     
    }


   return (i);
}



string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
