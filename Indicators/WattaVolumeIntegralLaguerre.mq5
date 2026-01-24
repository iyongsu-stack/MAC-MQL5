//+------------------------------------------------------------------+
//|                                  WattaVolumeIntegralLaguerre.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"


#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   1



//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
#property indicator_type1 DRAW_COLOR_LINE
#property indicator_color1 CLR_NONE,Lime,Red
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2
#property indicator_label1  "Signal Line"
#property indicator_levelcolor Blue
#property indicator_levelstyle STYLE_DASHDOTDOT







//+-----------------------------------+
//| Indicator input parameters        |
//+-----------------------------------+
input double gamma=0.7;
input int HighLevel=85;
input int MiddleLevel=50;
input int LowLevel=15;


input ENUM_APPLIED_VOLUME VolumeType    = VOLUME_REAL;  // Volume Type
input int                 AsiaTime      = 3;            // AsiaSession Time
input int                 EuroTime      = 7;            // EuroSession Time
input int                 AmericaTime   = 14;           // AmericaSession Time
input int                 NoTradingTime = 22;           // NoTradingSession Time
input bool                ResetEverySession = false;    // Reset per Session


double ColorBuffer[],ExtLineBuffer[];
double p1Buffer[], p2Buffer[], p3Buffer[], p3SumBuffer[];




enum Session
{
   AsiaSession,
   EuroSession,
   AmericaSession,
   NoTradingSession,
};

Session LastSession=NoTradingSession, CurSession=NoTradingSession;




//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {


   string shortname;
   StringConcatenate(shortname,"BuySellPowerLaguerre(",gamma, ")" );
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);


   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,p3SumBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,p1Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,p2Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,p3Buffer,INDICATOR_CALCULATIONS);

   ArrayInitialize(ExtLineBuffer, 0.);
   ArrayInitialize(ColorBuffer, 0.);
   ArrayInitialize(p3SumBuffer, 0.);
   ArrayInitialize(p1Buffer, 0.);
   ArrayInitialize(p2Buffer, 0.);
   ArrayInitialize(p3Buffer, 0.);

   IndicatorSetInteger(INDICATOR_LEVELS,3);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,HighLevel);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,MiddleLevel);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,LowLevel);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,Magenta);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,Gray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,Magenta);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,STYLE_DASHDOTDOT);
 
//----
  }
  
  


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+


int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of price maximums for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   int first, second ;

   double L0,L1,L2,L3,L0A,L1A,L2A,L3A,LRSI=0,CU,CD;
   static double L0_,L1_,L2_,L3_,L0A_,L1A_,L2A_,L3A_;


   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      int smallBar=iBars(_Symbol, PERIOD_M1);
      datetime smallTime = iTime(_Symbol, PERIOD_M1, smallBar-1);
      int start = iBarShift(_Symbol, _Period, smallTime);
      first = start - 1;              
     }
   else
     {     
       first=rates_total-prev_calculated; // starting number for calculation of new bars 
     } 
     
     
   L0 = L0_;
   L1 = L1_;
   L2 = L2_;
   L3 = L3_;
   L0A = L0A_;
   L1A = L1A_;
   L2A = L2A_;
   L3A = L3A_;
     



   for(int bar=first; bar>=0; bar--)
     {
      int smallNextBar, smallCurBar;
      datetime bigCurTime, bigNextTime;
      double P1=0, P2=0;

      bigCurTime = iTime(_Symbol, _Period, bar); 
      smallCurBar = iBarShift(_Symbol, PERIOD_M1, bigCurTime);

      if(bar == 0)
        {
          smallNextBar = -1;        
        }
      else if(bar > 0)
        {
          bigNextTime = iTime(_Symbol, _Period, bar-1);
          smallNextBar = iBarShift(_Symbol, PERIOD_M1, bigNextTime);        
        } 
  

      for(int i = smallCurBar; i > smallNextBar; i--)
        {
         
           long mVolume;
           if(VolumeType == VOLUME_TICK) mVolume = iTickVolume(Symbol(),PERIOD_M1,i);
           else mVolume = iVolume(Symbol(),PERIOD_M1,i);
 
           double highest_m1aa = iHigh(Symbol(), PERIOD_M1, iHighest(Symbol(), PERIOD_M1, MODE_HIGH, 2, i));
           double lowest_m1aa  = iLow(Symbol(), PERIOD_M1, iLowest(Symbol(), PERIOD_M1, MODE_LOW, 2, i)); 
           if((highest_m1aa-lowest_m1aa)==0.) continue;
           P1 = mVolume*(iClose(Symbol(),PERIOD_M1,i)-lowest_m1aa )/(highest_m1aa-lowest_m1aa);
         
           P2 = mVolume - P1;
/*
         
           P1 = mVolume *(  (iClose(Symbol(),PERIOD_M1,i)-iLow(Symbol(),PERIOD_M1,i))/
                            (iHigh(Symbol(),PERIOD_M1,i)-iLow(Symbol(),PERIOD_M1,i))  );
           P2 = mVolume *(  (iHigh(Symbol(),PERIOD_M1,i)-iClose(Symbol(),PERIOD_M1,i))/
                            (iHigh(Symbol(),PERIOD_M1,i)-iLow(Symbol(),PERIOD_M1,i))  );
*/
        } 
                
       p1Buffer[(rates_total-1-bar)]=P1;
       p2Buffer[(rates_total-1-bar)]=-P2;
       p3Buffer[(rates_total-1-bar)]=P1-P2;
       
       CurSession = WhatIsSession(bigCurTime);
       
       if( (LastSession != CurSession) && (ResetEverySession || (CurSession == AsiaSession)) )
            p3SumBuffer[(rates_total-1-bar)] = p3Buffer[(rates_total-1-bar)];
       else p3SumBuffer[(rates_total-1-bar)] = p3SumBuffer[(rates_total-1-bar-1)]
                                               + p3Buffer[(rates_total-1-bar)];
      
       LastSession = CurSession;  
                                
       
     }

   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {

      second =  rates_total-first + 1;        
      L0_ = p3SumBuffer[second];
      L1_ = p3SumBuffer[second];
      L2_ = p3SumBuffer[second];
      L3_ = p3SumBuffer[second];
      L0A_ = p3SumBuffer[second];
      L1A_ = p3SumBuffer[second];
      L2A_ = p3SumBuffer[second];
      L3A_ = p3SumBuffer[second];      
             
     }
   else
     {     
       second = prev_calculated-1; 
     } 
     
     
   L0 = L0_;
   L1 = L1_;
   L2 = L2_;
   L3 = L3_;
   L0A = L0A_;
   L1A = L1A_;
   L2A = L2A_;
   L3A = L3A_;







//--- main calculation
   for(int bar=second; bar<rates_total; bar++)
     {
      //--- memorize values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==rates_total-1)
        {
         L0_ = L0;
         L1_ = L1;
         L2_ = L2;
         L3_ = L3;
         L0A_ = L0A;
         L1A_ = L1A;
         L2A_ = L2A;
         L3A_ = L3A;
        }

      L0A = L0;
      L1A = L1;
      L2A = L2;
      L3A = L3;
      //---
      L0 = (1 - gamma) * p3SumBuffer[bar] + gamma * L0A;
      L1 = - gamma * L0 + L0A + gamma * L1A;
      L2 = - gamma * L1 + L1A + gamma * L2A;
      L3 = - gamma * L2 + L2A + gamma * L3A;
      //---
      CU = 0;
      CD = 0;
      //---
      if(L0 >= L1) CU  = L0 - L1; else CD  = L1 - L0;
      if(L1 >= L2) CU += L1 - L2; else CD += L2 - L1;
      if(L2 >= L3) CU += L2 - L3; else CD += L3 - L2;
      //---
      if(CU+CD!=0) LRSI=CU/(CU+CD);

      LRSI*=100;
      //--- set value to ExtLineBuffer[]
      ExtLineBuffer[bar]=LRSI;
      //--- indicator coloring
      PointIndicator(31,ExtLineBuffer,ColorBuffer,HighLevel,MiddleLevel,LowLevel,bar);
     }


   return(rates_total);
  }
//+-------------------------------------










//+------------------------------------------------------------------+
//| Painting the indicator in two colors                             |
//+------------------------------------------------------------------+
void PointIndicator(int Min_rates_total,
                    double &IndBuffer[],
                    double &ColorIndBuffer[],
                    double HighLevel_,
                    double MiddleLevel_,
                    double LowLevel_,
                    int bar)
  {
//---
   if(bar<Min_rates_total+1) return;

   enum LEVEL
     {
      EMPTY,
      HighLev,
      HighLevMiddle,
      LowLevMiddle,
      LowLev
     };

   LEVEL Level0=EMPTY,Level1=EMPTY;
   double IndVelue;

//--- indicator coloring
   IndVelue=IndBuffer[bar];
   if(IndVelue>HighLevel_) Level0=HighLev; else if(IndVelue>MiddleLevel_)Level0=HighLevMiddle;
   if(IndVelue<LowLevel_) Level0=LowLev;  else if(IndVelue<=MiddleLevel_)Level0=LowLevMiddle;

   IndVelue=IndBuffer[bar-1];
   if(IndVelue>HighLevel_) Level1=HighLev; else if(IndVelue>MiddleLevel_)Level1=HighLevMiddle;
   if(IndVelue<LowLevel_) Level1=LowLev;  else if(IndVelue<=MiddleLevel_)Level1=LowLevMiddle;

   switch(Level0)
     {
      case HighLev: ColorIndBuffer[bar]=1; break;

      case HighLevMiddle:
         switch(Level1)
           {
            case  HighLev: ColorIndBuffer[bar]=2; break;
            case  HighLevMiddle: ColorIndBuffer[bar]=ColorIndBuffer[bar-1]; break;
            case  LowLevMiddle: ColorIndBuffer[bar]=1; break;
            case  LowLev: ColorIndBuffer[bar]=1; break;
           }
         break;

      case  LowLevMiddle:
         switch(Level1)
           {
            case  HighLev: ColorIndBuffer[bar]=2; break;
            case  HighLevMiddle: ColorIndBuffer[bar]=2; break;
            case  LowLevMiddle: ColorIndBuffer[bar]=ColorIndBuffer[bar-1]; break;
            case  LowLev: ColorIndBuffer[bar]=1; break;
           }
         break;

      case LowLev: ColorIndBuffer[bar]=2; break;
     }
//---  
  }     













//+------------------------------------------------------------------+
//| Non-Linear Regression Function : 2'nd order regression           |
//+------------------------------------------------------------------+
double workNlr[][1];
double nlrYValue[];
double nlrXValue[];
//
//---
//
double iNlr(double price,int Length,int shift,int desiredBar,int bars,int instanceNo=0)
  {
   if(ArrayRange(workNlr,0)!=bars) ArrayResize(workNlr,bars);
   if(ArraySize(nlrYValue)!=Length) ArrayResize(nlrYValue,Length);
   if(ArraySize(nlrXValue)!=Length) ArrayResize(nlrXValue,Length);
//
//---
//
   double AvgX = 0;
   double AvgY = 0;
   int r=shift;
   workNlr[r][instanceNo]=price;
   ArrayInitialize(nlrXValue,0);
   ArrayInitialize(nlrYValue,0);
   for(int i=0;i<Length && (r-i)>=0;i++)
     {
      nlrXValue[i] = i;
      nlrYValue[i] = workNlr[r-i][instanceNo];
      AvgX  += nlrXValue[i];
      AvgY  += nlrYValue[i];
     }
   AvgX /= Length;
   AvgY /= Length;
//
//---
//
   double SXX   = 0;
   double SXY   = 0;
   double SYY   = 0;
   double SXX2  = 0;
   double SX2X2 = 0;
   double SYX2  = 0;

   for(int i=0;i<Length;i++)
     {
      double XM  = nlrXValue[i] - AvgX;
      double YM  = nlrYValue[i] - AvgY;
      double XM2 = nlrXValue[i] * nlrXValue[i] - AvgX*AvgX;
      SXX   += XM*XM;
      SXY   += XM*YM;
      SYY   += YM*YM;
      SXX2  += XM*XM2;
      SX2X2 += XM2*XM2;
      SYX2  += YM*XM2;
     }
//
//---
//
   double tmp;
   double ACoeff=0;
   double BCoeff=0;
   double CCoeff=0;

   tmp=SXX*SX2X2-SXX2*SXX2;
   if(tmp!=0)
     {
      BCoeff = ( SXY*SX2X2 - SYX2*SXX2 ) / tmp;
      CCoeff = ( SXX*SYX2  - SXX2*SXY )  / tmp;
     }
   ACoeff = AvgY   - BCoeff*AvgX       - CCoeff*AvgX*AvgX;
   tmp    = ACoeff + BCoeff*desiredBar + CCoeff*desiredBar*desiredBar;
   return(tmp);
  }



Session WhatIsSession(datetime m_Time)
{

   MqlDateTime currTime;
   TimeToStruct(m_Time, currTime);
   int hour0 = currTime.hour;
   
   if( (hour0>=AsiaTime) && (hour0<EuroTime) ) return(AsiaSession);
   if( (hour0>=EuroTime) && (hour0<AmericaTime)) return(EuroSession);
   if( (hour0>=AmericaTime) && (hour0<NoTradingTime)) return(AmericaSession);
   return(NoTradingSession);
}

/*
double iEma(const double &t2_Array[], const double &t1_Array[], int r)
{
   return(t2_Array[r-1]+alpha*(t1_Array[r]-t2_Array[r-1]));
}

*/

double Average(int end, int avgPeriod, const double &S_Array[])
{
    double sum;
    sum=0.0;
      
    for(int i=end+1-avgPeriod;i<=end;i++)
    {
          sum+=S_Array[i];
    }
       
    return(sum/avgPeriod);

}



double LinearRegression(int end, int exPeriod, const double &S_Array[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=end+1-exPeriod;i<=end;i++)
         {
          sumX+=X;
          sumY+=S_Array[i];
          sumXY+=X*S_Array[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-exPeriod*sumXY)/(MathPow(sumX,2)-exPeriod*sumX2);
       b=(sumY-a*sumX)/exPeriod;


      return(a);

}

