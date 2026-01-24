//+------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property description "Ultra trend"
//+------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   3
#property indicator_label1  "Filling"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrLightGreen,clrWheat
#property indicator_label2  "Ultra trend +"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrDarkGray,clrLimeGreen,clrOrange
#property indicator_width2  3
#property indicator_label3  "Ultra trend -"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrDarkGray,clrLimeGreen,clrOrange
#property indicator_width3  1

//+------------------------------------------------------------------+
//| Custom classes                                                   |
//+------------------------------------------------------------------+
class CJurikSmooth
  {
private:
   int               m_size;
   double            m_wrk[][10];

   //
   //---
   //

public :

                     CJurikSmooth(void) : m_size(0) { return; }
                    ~CJurikSmooth(void)             { return; }

   double CalculateValue(double price,double length,double phase,int r,int bars)
     {
      #define bsmax  5
      #define bsmin  6
      #define volty  7
      #define vsum   8
      #define avolty 9

      if (m_size!=bars) ArrayResize(m_wrk,bars); if (ArrayRange(m_wrk,0)!=bars) return(price); m_size=bars;
      if(r==0 || length<=1) { int k=0; for(; k<7; k++) m_wrk[r][k]=price; for(; k<10; k++) m_wrk[r][k]=0; return(price); }

      //
      //---
      //

      double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
      double pow1   = MathMax(len1-2.0,0.5);
      double del1   = price - m_wrk[r-1][bsmax];
      double del2   = price - m_wrk[r-1][bsmin];
      int    forBar = MathMin(r,10);

      m_wrk[r][volty]=0;
      if(MathAbs(del1) > MathAbs(del2)) m_wrk[r][volty] = MathAbs(del1);
      if(MathAbs(del1) < MathAbs(del2)) m_wrk[r][volty] = MathAbs(del2);
      m_wrk[r][vsum]=m_wrk[r-1][vsum]+(m_wrk[r][volty]-m_wrk[r-forBar][volty])*0.1;

      //
      //---
      //

      m_wrk[r][avolty]=m_wrk[r-1][avolty]+(2.0/(MathMax(4.0*length,30)+1.0))*(m_wrk[r][vsum]-m_wrk[r-1][avolty]);
      double dVolty=(m_wrk[r][avolty]>0) ? m_wrk[r][volty]/m_wrk[r][avolty]: 0;
      if(dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
      if(dVolty < 1)                      dVolty = 1.0;

      //
      //---
      //

      double pow2 = MathPow(dVolty, pow1);
      double len2 = MathSqrt(0.5*(length-1))*len1;
      double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

      if(del1 > 0) m_wrk[r][bsmax] = price; else m_wrk[r][bsmax] = price - Kv*del1;
      if(del2 < 0) m_wrk[r][bsmin] = price; else m_wrk[r][bsmin] = price - Kv*del2;

      //
      //---
      //

      double corr  = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
      double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
      double alpha = MathPow(beta,pow2);

      m_wrk[r][0] = price + alpha*(m_wrk[r-1][0]-price);
      m_wrk[r][1] = (price - m_wrk[r][0])*(1-beta) + beta*m_wrk[r-1][1];
      m_wrk[r][2] = (m_wrk[r][0] + corr*m_wrk[r][1]);
      m_wrk[r][3] = (m_wrk[r][2] - m_wrk[r-1][4])*MathPow((1-alpha),2) + MathPow(alpha,2)*m_wrk[r-1][3];
      m_wrk[r][4] = (m_wrk[r-1][4] + m_wrk[r][3]);

      //
      //---
      //

      return(m_wrk[r][4]);

      #undef bsmax
      #undef bsmin
      #undef volty
      #undef vsum
      #undef avolty
     }
  };
//
//--- input parameters
//
enum enTimeFrames
  {
   tf_cu  = PERIOD_CURRENT, // Current time frame
   tf_m1  = PERIOD_M1,      // 1 minute
   tf_m2  = PERIOD_M2,      // 2 minutes
   tf_m3  = PERIOD_M3,      // 3 minutes
   tf_m4  = PERIOD_M4,      // 4 minutes
   tf_m5  = PERIOD_M5,      // 5 minutes
   tf_m6  = PERIOD_M6,      // 6 minutes
   tf_m10 = PERIOD_M10,     // 10 minutes
   tf_m12 = PERIOD_M12,     // 12 minutes
   tf_m15 = PERIOD_M15,     // 15 minutes
   tf_m20 = PERIOD_M20,     // 20 minutes
   tf_m30 = PERIOD_M30,     // 30 minutes
   tf_h1  = PERIOD_H1,      // 1 hour
   tf_h2  = PERIOD_H2,      // 2 hours
   tf_h3  = PERIOD_H3,      // 3 hours
   tf_h4  = PERIOD_H4,      // 4 hours
   tf_h6  = PERIOD_H6,      // 6 hours
   tf_h8  = PERIOD_H8,      // 8 hours
   tf_h12 = PERIOD_H12,     // 12 hours
   tf_d1  = PERIOD_D1,      // daily
   tf_w1  = PERIOD_W1,      // weekly
   tf_mn  = PERIOD_MN1,     // monthly
   tf_cp1 = -1,             // Next higher time frame
   tf_cp2 = -2,             // Second higher time frame
   tf_cp3 = -3              // Third higher time frame
  };
input enTimeFrames inpTimeFrame   = tf_cu; // Time frame
input int          inpUtrPeriod   = 3;     // Start period
input int          inpProgression = 5;     // Step
input int          inpInstances   = 30;    // Instances
input int          inpSmooth      = 5;     // Ultra trend smoothing period
input int          inpSmoothPhase = 100;   // Ultra trend smoothing phase
input bool         inpInterpolate = true;  // Interpolate in multi time frame mode?
//--- buffers declarations
double fillu[],filld[],valp[],valpc[],valm[],valmc[],count[];
CJurikSmooth _iSmooth[];
int     _mtfHandle=INVALID_HANDLE; ENUM_TIMEFRAMES timeFrame;
#define _mtfCall iCustom(_Symbol,timeFrame,getIndicatorName(),0,inpUtrPeriod,inpProgression,inpInstances,inpSmooth,inpSmoothPhase)
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,fillu,INDICATOR_DATA);
   SetIndexBuffer(1,filld,INDICATOR_DATA);
   SetIndexBuffer(2,valp,INDICATOR_DATA);
   SetIndexBuffer(3,valpc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,valm,INDICATOR_DATA);
   SetIndexBuffer(5,valmc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,count,INDICATOR_CALCULATIONS);
   ArrayResize(_iSmooth,inpInstances+3);
   PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
//---  
   timeFrame=MathMax(timeFrameGet((int)inpTimeFrame),_Period);
   if(timeFrame!=_Period)
     {
      _mtfHandle = _mtfCall; if(_mtfHandle==INVALID_HANDLE) return(INIT_FAILED);
     }
//--- indicator short name
   IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(timeFrame)+" Ultra trend ("+(string)inpUtrPeriod+","+(string)inpProgression+","+(string)inpInstances+")");
//---
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(Bars(_Symbol,_Period)<rates_total) return(prev_calculated);
   if(timeFrame!=_Period)
     {
      double result[];
      if(BarsCalculated(_mtfHandle)<0)                     return(prev_calculated);
      if(!timeFrameCheck((ENUM_TIMEFRAMES)timeFrame,time)) return(prev_calculated);
      if(CopyBuffer(_mtfHandle,6,0,1,result)==-1)          return(prev_calculated);

      //
      //---
      //

      #define _mtfRatio PeriodSeconds((ENUM_TIMEFRAMES)timeFrame)/PeriodSeconds(_Period)
      int k,n,i=MathMin(MathMax(prev_calculated-1,0),MathMax(rates_total-(int)result[0]*_mtfRatio-1,0)),_prevMark=0,_seconds=PeriodSeconds(timeFrame);
      for(; i<rates_total && !_StopFlag; i++)
        {
         int _currMark = int(time[i]/_seconds);
         if (_currMark!=_prevMark)
         {
            _prevMark = _currMark;
            #define _mtfCopy(_buff,_buffNo) if(CopyBuffer(_mtfHandle,_buffNo,time[i],1,result)==-1) break; _buff[i]=result[0]
                    _mtfCopy(fillu,0);
                    _mtfCopy(filld,1);
                    _mtfCopy(valp ,2);
                    _mtfCopy(valpc,3);
                    _mtfCopy(valm ,4);
                    _mtfCopy(valmc,5);
         }
         else
         {
            fillu[i] = fillu[i-1];
            filld[i] = filld[i-1];
            valp[i]  = valp[i-1];
            valpc[i] = valpc[i-1];
            valm[i]  = valm[i-1];
            valmc[i] = valmc[i-1];
         }            

         //
         //---
         //

         if (!inpInterpolate)  continue;
            int _nextMark = (i<rates_total-1) ? int(time[i+1]/_seconds) : _prevMark+1; if (_nextMark == _prevMark) continue;
            for(n=1; (i-n)> 0 && time[i-n] >= (_prevMark)*_seconds; n++) continue;
            for(k=1; (i-k)>=0 && k<n; k++)
            {
               #define _mtfInterpolate(_buff) _buff[i-k]=_buff[i]+(_buff[i-n]-_buff[i])*k/n
                       _mtfInterpolate(fillu);
                       _mtfInterpolate(filld);
                       _mtfInterpolate(valp);
                       _mtfInterpolate(valm);
            }
        }
      return(i);
     }
   //
   //---
   //
   int endLength=inpUtrPeriod+inpProgression*inpInstances;
   int i=(int)MathMax(prev_calculated-1,0); for(; i<rates_total && !_StopFlag; i++)
     {
      double valueUp=0;
      double valueDn=0;

      for(int k=inpUtrPeriod,instance=2; k<=endLength && i>0; k+=inpProgression,instance++)
         if(_iSmooth[instance].CalculateValue(close[i-1],k,inpSmoothPhase,i-1,rates_total)<_iSmooth[instance].CalculateValue(close[i],k,inpSmoothPhase,i,rates_total))
              valueUp++;
         else valueDn++;
      valp[i]  = _iSmooth[0].CalculateValue(valueUp,inpSmooth,inpSmoothPhase,i,rates_total);
      valm[i]  = _iSmooth[1].CalculateValue(valueDn,inpSmooth,inpSmoothPhase,i,rates_total);
      valpc[i] = (valp[i]>valm[i]) ? 1 : 2;
      valmc[i] = valpc[i];
      fillu[i] = valp[i];
      filld[i] = valm[i];
     }
   count[rates_total-1]=MathMax(rates_total-prev_calculated+1,1);
   return (i);
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
//
//---
//  
ENUM_TIMEFRAMES _tfsPer[]={PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
string          _tfsStr[]={"1 minute","2 minutes","3 minutes","4 minutes","5 minutes","6 minutes","10 minutes","12 minutes","15 minutes","20 minutes","30 minutes","1 hour","2 hours","3 hours","4 hours","6 hours","8 hours","12 hours","daily","weekly","monthly"};
//
//---
//
string timeFrameToString(int period)
  {
   if(period==PERIOD_CURRENT)
      period=_Period;
   int i; for(i=0;i<ArraySize(_tfsPer);i++) if(period==_tfsPer[i]) break;
   return(_tfsStr[i]);
  }
//
//---
//
ENUM_TIMEFRAMES timeFrameGet(int period)
  {
   int _shift=(period<0?MathAbs(period):0);
   if(_shift>0 || period==tf_cu) period=_Period;
   int i; for(i=0;i<ArraySize(_tfsPer);i++) if(period==_tfsPer[i]) break;

   return(_tfsPer[(int)MathMin(i+_shift,ArraySize(_tfsPer)-1)]);
  }
//
//---
//
string getIndicatorName()
  {
   string _path=MQL5InfoString(MQL5_PROGRAM_PATH);
   string _partsA[];
   ushort _partsS=StringGetCharacter("\\",0);
   int _partsN = StringSplit(_path,_partsS,_partsA);
   string name = _partsA[_partsN-1]; for(int n=_partsN-2; n>=0 && _toLower(_partsA[n])!="indicators"; n--) name = _partsA[n]+"\\"+name;
   return(name);
  }
string _toLower(string _toConvert) { StringToLower(_toConvert); return(_toConvert); }
//
//---
//
bool timeFrameCheck(ENUM_TIMEFRAMES _timeFrame,const datetime &time[])
  {
   static bool warned=false;
   if(time[0]<SeriesInfoInteger(_Symbol,_timeFrame,SERIES_FIRSTDATE))
     {
      datetime startTime,testTime[];
      if(SeriesInfoInteger(_Symbol,PERIOD_M1,SERIES_TERMINAL_FIRSTDATE,startTime))
      if(startTime>0)                       { CopyTime(_Symbol,_timeFrame,time[0],1,testTime); SeriesInfoInteger(_Symbol,_timeFrame,SERIES_FIRSTDATE,startTime); }
      if(startTime<=0 || startTime>time[0]) { Comment(MQL5InfoString(MQL5_PROGRAM_NAME)+"\nMissing data for "+timeFrameToString(_timeFrame)+" time frame\nRe-trying on next tick"); warned=true; return(false); }
     }
   if(warned) { Comment(""); warned=false; }
   return(true);
  }
//+--------------