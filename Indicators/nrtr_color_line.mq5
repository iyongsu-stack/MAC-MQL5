//+------------------------------------------------------------------+
//|                                              NRTR_color_line.mq5 |
//|                                Copyright © 2013, TrendLaboratory |
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |
//|                                   E-mail: igorad2003@yahoo.co.uk |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2013, TrendLaboratory"
#property link      "http://finance.groups.yahoo.com/group/TrendLaboratory"

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

#property indicator_label1  "UpTrend Line"
#property indicator_type1   DRAW_LINE
#property indicator_color1  SkyBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "DnTrend Line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  OrangeRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "UpTrend Signal"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  SkyBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

#property indicator_label4  "DnTrend Signal"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  OrangeRed
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2



input int    ATRPeriod     =  14;   //	
input double Coefficient   = 4.0;   //	
input int    SignalMode=1;          //SignalMode: Display signals mode: 0-only Stops,1-Signals & Stops,2-only Signals;

//--- indicator buffers
double UpLine[];
double DnLine[];
double UpSignal[];
double DnSignal[];
bool   TrendUP[2];

double Extremum[2],TR,Values[100],ATR,ChannelWidth;
int    Head[2],Weight,Curr;
datetime prevTime;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping

   SetIndexBuffer(0,UpLine,INDICATOR_DATA);
   SetIndexBuffer(1,DnLine,INDICATOR_DATA);
   SetIndexBuffer(2,UpSignal,INDICATOR_DATA); PlotIndexSetInteger(4,PLOT_ARROW,108);
   SetIndexBuffer(3,DnSignal,INDICATOR_DATA); PlotIndexSetInteger(5,PLOT_ARROW,108);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- 
   string params="("+(string)ATRPeriod+","+(string)Coefficient+")";
   IndicatorSetString(INDICATOR_SHORTNAME,"NRTR_color_line"+params);
   PlotIndexSetString(0,PLOT_LABEL,"Buy stop line"+params);
   PlotIndexSetString(1,PLOT_LABEL,"Sell stop line"+params);
   PlotIndexSetString(2,PLOT_LABEL,"Buy signal"+params);
   PlotIndexSetString(3,PLOT_LABEL,"Sell signal"+params);
//--- initialization done
  }
//+------------------------------------------------------------------+
//| NRTR_color_line                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double   &Open[],
                const double   &High[],
                const double   &Low[],
                const double   &Close[],
                const long     &TickVolume[],
                const long     &Volume[],
                const int      &Spread[])
  {
   int shift,j,limit,copied=0;

//--- preliminary calculations
   if(prev_calculated==0)
     {
      limit=1;

      ArrayInitialize(UpSignal,EMPTY_VALUE);
      ArrayInitialize(DnSignal,EMPTY_VALUE);
      ArrayInitialize(UpLine,EMPTY_VALUE);
      ArrayInitialize(DnLine,EMPTY_VALUE);
     }
   else limit=prev_calculated-1;

//--- the main loop of calculations
   for(shift=limit;shift<rates_total;shift++)
     {
      if(Time[shift]!=prevTime)
        {
         TrendUP[1]  = TrendUP[0];
         Extremum[1] = Extremum[0];
         Head[1]     = Head[0];
         prevTime    = Time[shift];
        }

      if(shift==2)
        {
         if(Close[shift]>Close[shift-1]) TrendUP[0]=true; else TrendUP[0]=false;
         Extremum[0]=Close[shift];

        }
      else
      if(shift>2)
        {
         TR=High[shift]-Low[shift];
         if( MathAbs( High[shift] - Close[shift-1]) > TR) TR = MathAbs(High[shift] - Close[shift-1]);
         if( MathAbs( Low [shift] - Close[shift-1]) > TR) TR = MathAbs(Low [shift] - Close[shift-1]);

         if(shift == 3)
            for(j = 0; j<ATRPeriod; j++) Values[j] = TR;

         Head[0]=Head[1];

         Values[Head[0]]=TR;
         ATR=0;
         Weight=ATRPeriod;
         Curr=Head[0];
         for(j=0; j<ATRPeriod; j++)
           {
            ATR+=Values[Curr]*Weight;
            Weight -= 1;
            Curr   -= 1;
            if(Curr == -1) Curr = ATRPeriod - 1;
           }

         ATR=2.0*ATR/(ATRPeriod*(ATRPeriod+1.0));

         Head[0]+=1;
         if(Head[0]==ATRPeriod) Head[0]=0;

         ChannelWidth=Coefficient*ATR;

         TrendUP[0]  = TrendUP[1];
         Extremum[0] = Extremum[1];

         if(TrendUP[0] && (Low[shift]<(Extremum[0]-ChannelWidth)))
           {
            TrendUP[0]  = false;
            Extremum[0] = High[shift];
           }

         if(!TrendUP[0] && (High[shift]>(Extremum[0]+ChannelWidth)))
           {
            TrendUP[0]  = true;
            Extremum[0] = Low[ shift ];
           }

         if(TrendUP[0]  && (Low [shift] > Extremum[0])) Extremum[0] = Low [shift];
         if(!TrendUP[0] && (High[shift] < Extremum[0])) Extremum[0] = High[shift];

         UpLine[shift] = EMPTY_VALUE;
         DnLine[shift] = EMPTY_VALUE;
         UpSignal[shift]=EMPTY_VALUE;
         DnSignal[shift]=EMPTY_VALUE;

         if(TrendUP[0])
           {
            if(SignalMode<2) UpLine[shift]=Extremum[0]-ChannelWidth;
            if(SignalMode>0 && TrendUP[0]!=TrendUP[1]) UpSignal[shift]=Extremum[0]-ChannelWidth;
           }
         else
           {
            if(SignalMode<2) DnLine[shift]=Extremum[0]+ChannelWidth;
            if(SignalMode>0 && TrendUP[0]!=TrendUP[1]) DnSignal[shift]=Extremum[0]+ChannelWidth;
           }
        }
     }

//--- done
   return(rates_total);
  }
//+------------------------------------------------------------------+
