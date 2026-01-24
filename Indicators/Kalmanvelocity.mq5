#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_label1  "Kalman velocity"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrMediumSeaGreen,clrOrangeRed
#property indicator_width1  2

//
//---
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
input enTimeFrames       inpTimeFrame = tf_cu;       // Time frame
input double             inpPeriod    = 1;           // Period/smoothing ratio
input ENUM_APPLIED_PRICE inpPrice     = PRICE_CLOSE; // Price
enum enIterpolate
{
   interolate_yes=(int)true, // Interpolate data when in multi time frame
   interolate_no =(int)false // Do not interpolate data when in multi time frame
};
input enIterpolate inpInterpolate = interolate_yes; // Interpolation

//
//--- indicator buffers
//

double val[],valc[],count[];
ENUM_TIMEFRAMES _indicatorTimeFrame; string _indicatorName; int  _indicatorMtfHandle;
#define _mtfCall iCustom(_Symbol,_indicatorTimeFrame,_indicatorName,0,inpPeriod,inpPrice)

//------------------------------------------------------------------
// Custom indicator initialization function
//------------------------------------------------------------------
//
//
//

int OnInit()
{
   //
   //--- indicator buffers mapping
   //
      SetIndexBuffer(0,val  ,INDICATOR_DATA);
      SetIndexBuffer(1,valc ,INDICATOR_COLOR_INDEX);
      SetIndexBuffer(2,count,INDICATOR_CALCULATIONS);
            _indicatorTimeFrame  = MathMax(_Period,timeFrameGet(inpTimeFrame));
            if (_indicatorTimeFrame != _Period)
               {
                  _indicatorName = getIndicatorName();
                  _indicatorMtfHandle = _mtfCall; if (!_checkHandle(_indicatorMtfHandle,"Target time frame instance")) return(INIT_FAILED);
               }
            else iKalmanFilter.init(inpPeriod);
   //      
   //--- indicator short name assignment
   //
   IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(_indicatorTimeFrame)+" Kalman velocity ("+(string)inpPeriod+")");
   return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason) { }

//------------------------------------------------------------------
// Custom indicator iteration function
//------------------------------------------------------------------
//
//---
//

#define _setPrice(_priceType,_where,_index) { \
   switch(_priceType) \
   { \
      case PRICE_CLOSE:    _where = close[_index];                                              break; \
      case PRICE_OPEN:     _where = open[_index];                                               break; \
      case PRICE_HIGH:     _where = high[_index];                                               break; \
      case PRICE_LOW:      _where = low[_index];                                                break; \
      case PRICE_MEDIAN:   _where = (high[_index]+low[_index])/2.0;                             break; \
      case PRICE_TYPICAL:  _where = (high[_index]+low[_index]+close[_index])/3.0;               break; \
      case PRICE_WEIGHTED: _where = (high[_index]+low[_index]+close[_index]+close[_index])/4.0; break; \
      default : _where = 0; \
   }}

//
//---
//

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   //
   //---
   //
         if(_indicatorTimeFrame!=_Period)
         {
            double result[1]; if (CopyBuffer(_indicatorMtfHandle,2,0,1,result)<0) result[0] = rates_total;

            //
            //---
            //
      
            #define _mtfRatio (double)PeriodSeconds((ENUM_TIMEFRAMES)_indicatorTimeFrame)/PeriodSeconds(_Period)
            int  n,k,i=MathMin(MathMax(prev_calculated-1,0),MathMax(rates_total-int(result[0]*_mtfRatio)-1,0)),_prevMark=-99; datetime _prevTime;
            for(; i<rates_total && !_StopFlag; i++)
            {
               int _currMark = iBarShift(_Symbol,_indicatorTimeFrame,time[i]); if (_currMark<0) continue;
               if (_currMark!=_prevMark)
               {
                  _prevMark =_currMark;
                  _prevTime = time[i];
                  #define _mtfCopy(_buff,_buffNo) { if(CopyBuffer(_indicatorMtfHandle,_buffNo,_currMark,1,result)<1) break; _buff[i]=result[0]; }
                          _mtfCopy(val ,0);
                          _mtfCopy(valc,1);
               }
               else
               {
                  #define _mtfCopyValue(_buff) _buff[i] = _buff[i-1];
                          _mtfCopyValue(val);
                          _mtfCopyValue(valc);
               }                  
              
               //
               //---
               //

               if(!inpInterpolate) continue;
                  int _nextMark = (i<rates_total-1) ? iBarShift(_Symbol,_indicatorTimeFrame,time[i+1]) : _prevMark+1; if(_nextMark==_prevMark) continue;              
                  for (n=1; (i-n)> 0 && time[i-n] >= _prevTime; n++) continue;
                  for (k=1; (i-k)>=0 && k<n; k++)
                  {
                     #define _mtfInterpolate(_buff) _buff[i-k]=_buff[i]+(_buff[i-n]-_buff[i])*k/n
                             _mtfInterpolate(val);
                  }              
            }
            return(i);
         }
  
   //
   //
   //----------------------------------------
   //
   //
  
   int i= prev_calculated-1; if (i<0) i=0; for (; i<rates_total && !_StopFlag; i++)
   {
      double _price,_velocity; _setPrice(inpPrice,_price,i);
      iKalmanFilter.calculate(_price,_velocity,i,rates_total);
      val[i]  = _velocity;
      valc[i] = (_velocity>0) ?  1 :(_velocity<0) ? 2 : 0;
   }
   count[rates_total-1]=MathMax(i-prev_calculated+1,1);
   return(i);
}

//------------------------------------------------------------------
// Custom functions
//------------------------------------------------------------------
//
//---
//

class CKalmanFilter
{
   private :
      double m_period;
      double m_coeff;
      struct sKalmanFilter
      {
         double filter;
         double velocity;
      };
      sKalmanFilter m_array[];
      int           m_arraySize;
      
   public :      
      CKalmanFilter() : m_arraySize(-1) {};
     ~CKalmanFilter()                   {};
    
      //
      //
      //
      
      void init (double period)
      {
         m_coeff  = (period>0 ? period : 1.0)/100.0;
         m_period = MathSqrt(m_coeff);
      }
      double calculate(double value,double& velocity, int i, int bars)
      {
         if (m_arraySize<bars) m_arraySize = ArrayResize(m_array,bars+500);
        
         if (i>0)
         {
            double _distance = value-m_array[i-1].filter;
            double _error    = m_array[i-1].filter+_distance*m_period;
                               m_array[i].velocity = m_array[i-1].velocity+_distance*m_coeff;
                               m_array[i].filter   = _error+m_array[i].velocity;
         }
         else { m_array[i].filter = value; m_array[i].velocity = 0; }
         velocity = m_array[i].velocity;
             return(m_array[i].filter);
      }
};
CKalmanFilter iKalmanFilter;

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
   int _shift = (period<0 ? MathAbs(period) : 0); if (period<=0) period=_Period;
   int i; for(i=0;i<ArraySize(_tfsPer);i++) if(period==_tfsPer[i]) break;
      return(_tfsPer[(int)MathMin(i+_shift,ArraySize(_tfsPer)-1)]);
}

//
//---
//

string getIndicatorName()
{
   string _path=MQL5InfoString(MQL5_PROGRAM_PATH); StringToLower(_path);
   string _partsA[];
   int    _partsN = StringSplit(_path,StringGetCharacter("\\",0),_partsA);
   string name=_partsA[_partsN-1]; for(int n=_partsN-2; n>=0 && _partsA[n]!="indicators"; n--) name=_partsA[n]+"\\"+name;
   return(name);
}

//
//---
//  

bool _checkHandle(int _handle, string _description)
{
   static int  _chandles[];
          int  _size   = ArraySize(_chandles);
          bool _answer = (_handle!=INVALID_HANDLE);
          if  (_answer)
               { ArrayResize(_chandles,_size+1); _chandles[_size]=_handle; }
          else { for (int i=_size-1; i>=0; i--) IndicatorRelease(_chandles[i]); ArrayResize(_chandles,0); Alert(_description+" initialization failed"); }
   return(_answer);
}

//------------------------------------------------------------------
