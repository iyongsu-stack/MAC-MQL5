//+------------------------------------------------------------------+
//|                                                SSLchannelMTF.mq5 |
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


double UpIndBuffer[], DnIndBuffer[];
int LTHandle, UpBuffNumb=0, DnBuffNumb=1;

int OnInit()
{
   //
   //--- indicator buffers mapping
   //
         SetIndexBuffer(0,UpIndBuffer, INDICATOR_DATA);
         SetIndexBuffer(1,DnIndBuffer, INDICATOR_DATA);
         
//         SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
   //
//         string shortname;
//         StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame),")");
//         fisherHandle=iCustom(Symbol(),TimeFrame,"FisherTransform",10,0);

         LTHandle = iCustom(_Symbol, TimeFrame, "SSLchannel", MA_Method, Lb ); 
         Sleep(3000);

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

   int i= prev_calculated-1; if (i<0) i=0; for (; i<rates_total && !_StopFlag; i++)
   {
 
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

      }
      else
      {
         UpIndBuffer[i]=UpIndBuffer[i-1];
         DnIndBuffer[i]=DnIndBuffer[i-1];

      }
      
//      valc[i]   = (angleBuffer[i] > 0.0) ? 1 :(angleBuffer[i]<0.0) ? 2 :(i>0) ? valc[i-1]: 0;
     
    }


   return (i);
}



string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
