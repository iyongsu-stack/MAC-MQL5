//+------------------------------------------------------------------+
//|                                        mySmoothingAlgorithms.mqh |
//|                                                     Yong-su, Kim |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property version   "1.00"

// Smoothing Function
#define _smoothInstances     2
#define _smoothInstancesSize 10
double m_wrk[][_smoothInstances*_smoothInstancesSize];
//Example of this Function : SmoothSellRatio[bar] = iSmooth(SumSellRatio[bar], inpSmoothPeriod, 0, bar, rates_total);
double iSmooth(double price,double length,double phase,int r,int bars,int instanceNo=0)
  {
   #define bsmax  5
   #define bsmin  6
   #define volty  7
   #define vsum   8
   #define avolty 9

   if(ArrayRange(m_wrk,0)!=bars) ArrayResize(m_wrk,bars); if(ArrayRange(m_wrk,0)!=bars) return(price); instanceNo*=_smoothInstancesSize;
   if(r==0 || length<=1) { int k=0; for(; k<7; k++) m_wrk[r][instanceNo+k]=price; for(; k<10; k++) m_wrk[r][instanceNo+k]=0; return(price); }

//
//---
//

   double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
   double pow1   = MathMax(len1-2.0,0.5);
   double del1   = price - m_wrk[r-1][instanceNo+bsmax];
   double del2   = price - m_wrk[r-1][instanceNo+bsmin];
   int    forBar = MathMin(r,10);

   m_wrk[r][instanceNo+volty]=0;
   if(MathAbs(del1) > MathAbs(del2)) m_wrk[r][instanceNo+volty] = MathAbs(del1);
   if(MathAbs(del1) < MathAbs(del2)) m_wrk[r][instanceNo+volty] = MathAbs(del2);
   m_wrk[r][instanceNo+vsum]=m_wrk[r-1][instanceNo+vsum]+(m_wrk[r][instanceNo+volty]-m_wrk[r-forBar][instanceNo+volty])*0.1;

//
//---
//

   m_wrk[r][instanceNo+avolty]=m_wrk[r-1][instanceNo+avolty]+(2.0/(MathMax(4.0*length,30)+1.0))*(m_wrk[r][instanceNo+vsum]-m_wrk[r-1][instanceNo+avolty]);
   double dVolty=(m_wrk[r][instanceNo+avolty]>0) ? m_wrk[r][instanceNo+volty]/m_wrk[r][instanceNo+avolty]: 0;
   if(dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
   if(dVolty < 1)                      dVolty = 1.0;

//
//---
//

   double pow2 = MathPow(dVolty, pow1);
   double len2 = MathSqrt(0.5*(length-1))*len1;
   double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

   if(del1 > 0) m_wrk[r][instanceNo+bsmax] = price; else m_wrk[r][instanceNo+bsmax] = price - Kv*del1;
   if(del2 < 0) m_wrk[r][instanceNo+bsmin] = price; else m_wrk[r][instanceNo+bsmin] = price - Kv*del2;

//
//---
//

   double corr  = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
   double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
   double alpha = MathPow(beta,pow2);

   m_wrk[r][instanceNo+0] = price + alpha*(m_wrk[r-1][instanceNo+0]-price);
   m_wrk[r][instanceNo+1] = (price - m_wrk[r][instanceNo+0])*(1-beta) + beta*m_wrk[r-1][instanceNo+1];
   m_wrk[r][instanceNo+2] = (m_wrk[r][instanceNo+0] + corr*m_wrk[r][instanceNo+1]);
   m_wrk[r][instanceNo+3] = (m_wrk[r][instanceNo+2] - m_wrk[r-1][instanceNo+4])*MathPow((1-alpha),2) + MathPow(alpha,2)*m_wrk[r-1][instanceNo+3];
   m_wrk[r][instanceNo+4] = (m_wrk[r-1][instanceNo+4] + m_wrk[r][instanceNo+3]);

//
//---
//

   return(m_wrk[r][instanceNo+4]);

   #undef bsmax
   #undef bsmin
   #undef volty
   #undef vsum
   #undef avolty
  }    

// Standard Deviation Function between two arrays
double StdDev(int end, int SDPeriod, const double &Avg_Array[], const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
    {
      dAmount+=(S_Array[i]-Avg_Array[i])*(S_Array[i]-Avg_Array[i]);
    }       

    StdValue = MathSqrt(dAmount/SDPeriod);
    return(StdValue);
}  

// Standard Deviation Function between two arrays with +, - sign
double StdDev2(int end, int SDPeriod, const double &Avg_Array[], const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
     {
      dAmount+=(S_Array[i] - Avg_Array[i] )*MathAbs(S_Array[i] - Avg_Array[i]);
     }       

    if(dAmount < 0.)
     {
      StdValue = -1*MathSqrt(MathAbs(dAmount/SDPeriod));
     }
    else StdValue = MathSqrt(dAmount/SDPeriod);

    return(StdValue);
} 

// Standard Deviation Function of array
double StdDev3(int end, int SDPeriod, const double &S_Array[])
{
    double dAmount=0., StdValue=0.;  

    for(int i=end+1-SDPeriod;i<=end;i++)
    {
      dAmount+=(S_Array[i])*(S_Array[i]);
    }       

    StdValue = MathSqrt(dAmount/SDPeriod);
    return(StdValue);
}  

// Linear Regression Function of array
double LinearRegression(int end, int period, const double &close[])
{
    double sumX,sumY,sumXY,sumX2,a,b;
    int X;

//--- calculate coefficient a and b of equation linear regression 
      sumX=0.0;
      sumY=0.0;
      sumXY=0.0;
      sumX2=0.0;
       X=0;
       for(int i=end+1-period;i<=end;i++)
         {
          sumX+=X;
          sumY+=close[i];
          sumXY+=X*close[i];
          sumX2+=MathPow(X,2);
          X++;
         }
       a=(sumX*sumY-period*sumXY)/(MathPow(sumX,2)-period*sumX2);
       b=(sumY-a*sumX)/period;


      return(a);

}


class CLwma
{
   private :
      struct sLwmaArrayStruct
         {
            double value;
            double wsumm;
            double vsumm;
         };
      sLwmaArrayStruct m_array[];
      int              m_arraySize;
      int              m_period;
      double           m_weight;
   public :
      CLwma() : m_period(1), m_weight(1), m_arraySize(-1) {                     return; }
     ~CLwma()                                              { ArrayFree(m_array); return; }
    
     //
     //---
     //

     void init(int period)
     {
         m_period = (period>1) ? period : 1;
     }
        
     double calculate(double value, int i, int bars)
     {
        if (m_arraySize<bars)
          { m_arraySize=ArrayResize(m_array,bars+500); if (m_arraySize<bars) return(0); }

         //
         //
         //

         m_array[i].value=value;
               if (i>m_period)
               {
                     m_array[i].wsumm  = m_array[i-1].wsumm+value*m_period-m_array[i-1       ].vsumm;
                     m_array[i].vsumm  = m_array[i-1].vsumm+value         -m_array[i-m_period].value;
               }
               else
               {
                     m_weight          = 0;
                     m_array[i].wsumm  = 0;
                     m_array[i].vsumm  = 0;
                     for(int k=0, w=m_period; k<m_period && i>=k; k++,w--)
                     {
                           m_weight             += w;
                           m_array[i].wsumm += m_array[i-k].value*(double)w;
                           m_array[i].vsumm += m_array[i-k].value;
                     }
               }
               return(m_array[i].wsumm/m_weight);
      }  
};
CLwma _lwma;


//+------------------------------------------------------------------+
//| Non Linear Regression Function                                   |
//+------------------------------------------------------------------+
double workNlr[][1];
double nlrYValue[];
double nlrXValue[];

// Non Linear Regression Function of array
// Example of this Function : val[i]=iNlr(tempVal[bar],inpPeriod,bar,0,rates_total);
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

// Average Function of array
double myAverage(int end, int avgPeriod, const double &S_Array[])
{
    double sum;
    sum=0.0;
      
    for(int i=end+1-avgPeriod;i<=end;i++)
    {
          sum+=S_Array[i];
    }
       
    return(sum/avgPeriod);

}

// Weighted Moving Average Function of array
// Example of this Function : WmaDiffRatio[bar] = iWma(bar,inpWmaPeriod, DiffRatio);
double iWma(int end, int wmaPeriod, const double &S_Array[])
{

   double Sum = 0., Weight=0., Norm=0., wma=0.;
   
   for(int i=0;i<wmaPeriod;i++)
   { 
      Weight = (wmaPeriod-i)*wmaPeriod;
      Norm += Weight; 
      Sum += S_Array[end-i]*Weight;
   }
   if(Norm>0) wma = Sum/Norm;
   else wma = 0; 
   
   return(wma);
}

// Check if new bar is opened
bool isNewBar(string sym)
{
   static datetime dtBarCurrent=WRONG_VALUE;
   datetime dtBarPrevious=dtBarCurrent;
   dtBarCurrent=(datetime) SeriesInfoInteger(sym,Period(),SERIES_LASTBAR_DATE);
   bool NewBarFlag=(dtBarCurrent!=dtBarPrevious);
   if(NewBarFlag)
      return(true);
   else
      return (false);

   return (false);
}

//// 값이 달라짐=사용불가: average Class of array
class HiAverage
{
private:
   double m_buffer[];    // 데이터를 담을 순환 버퍼
   int    m_size;        // 윈도우 크기
   int    m_index;       // 현재 쓰기 위치 포인터
   int    m_count;       // 현재까지 쌓인 데이터 수
   double m_sum;         // 합계 유지
   int    m_last_bar;    // 이전에 입력받은 bar 값
   double m_last_mean;   // 마지막으로 계산된 평균값
   int    m_last_index;  // 마지막으로 쓴 위치 인덱스
//   double m_sum_sq;      // 제곱합 유지

public:
   // 생성자
   HiAverage(int window_size)
   {
      m_size = window_size;
      ArrayResize(m_buffer, m_size);
      ArrayInitialize(m_buffer, 0.);
      Reset();
   }

   void Reset()
   {
      
      m_index = 0;
      m_count = 0;
      m_sum = 0;
      m_last_bar = -1;
      m_last_mean = 0;
      m_last_index = 0;
//      m_sum_sq = 0;
   }

   // 데이터 추가 및 계산 (매 분마다 호출)
   double Calculate(int bar, double price)
   {
      // bar 값이 이전보다 크면 기존 로직 실행
      if(bar > m_last_bar)
      {
         // 1. 오래된 데이터 제거 (버퍼가 꽉 찼을 때만)
         if(m_count >= m_size)
         {
            double old_val = m_buffer[m_index];
            m_sum -= old_val;
//            m_sum_sq -= (old_val * old_val);
         }
         else m_count++;

         // 2. 새 데이터 추가
         m_buffer[m_index] = price;
         m_sum += price;
//         m_sum_sq += (price * price);

         // 3. 마지막으로 쓴 위치 저장
         m_last_index = m_index;

         // 4. 인덱스 순환
         m_index = (m_index + 1) % m_size;

         // 4. 평균 계산 (O(1))
         if(m_count < 2) 
         {
            m_last_bar = bar;
            m_last_mean = 0;
            return 0;
         }
         
         m_last_mean = m_sum / m_count;
         m_last_bar = bar;
//         double variance = (m_sum_sq / m_count) - (mean * mean);
//         double variance = (m_sum_sq / m_count);
         return m_last_mean;
//         return MathSqrt(MathMax(0, variance));
      }
      else
      {
         // bar 값이 같거나 작으면 price만 업데이트하고 이전 평균 반환
         // (버퍼의 마지막 위치에 price만 업데이트하고 합계도 조정)
         if(m_count > 0)
         {
            // 마지막으로 쓴 위치의 price만 업데이트
            double old_price = m_buffer[m_last_index];
            m_buffer[m_last_index] = price;
            // 합계도 조정 (변화된 price만 반영)
            m_sum = m_sum - old_price + price;
            // 평균 재계산
            if(m_count >= 2)
            {
               m_last_mean = m_sum / m_count;
            }
         }
         return m_last_mean;
      }
   }
};

//// Standard Deviation Function between two arrays with absolute value
class HiStdDev1
{
private:
   double m_buffer[];    // 데이터를 담을 순환 버퍼
   int    m_size;        // 윈도우 크기 (5000)
   int    m_index;       // 현재 쓰기 위치 포인터
   int    m_count;       // 현재까지 쌓인 데이터 수
   int    m_last_bar;    // 이전에 입력받은 bar 값
   double m_last_stdValue; // 마지막으로 계산된 표준편차값
   int    m_last_index;  // 마지막으로 쓴 위치 인덱스
   
//   double m_sum;         // 합계 유지
   double m_sum_sq;      // 절대값 제곱합 유지

public:
   // 생성자
   HiStdDev1(int window_size)
   {
      m_size = window_size;
      ArrayResize(m_buffer, m_size);
      ArrayInitialize(m_buffer, 0.);
      Reset();
   }

   void Reset()
   {
      m_index = 0;
      m_count = 0;
      m_last_bar = -1;
      m_last_stdValue = 0;
      m_last_index = 0;
//      m_sum = 0;
      m_sum_sq = 0;
   }

   // 데이터 추가 및 계산 (매 분마다 호출)
   double Calculate(int bar, double avg_price, double price)
   {
      // bar 값이 이전보다 크면 기존 로직 실행
      if(bar > m_last_bar)
      {
         // 1. 오래된 데이터 제거 (버퍼가 꽉 찼을 때만)
         if(m_count >= m_size)
         {
            double old_val = m_buffer[m_index];
//            m_sum -= old_val;
            m_sum_sq -= old_val;
         }
         else m_count++;

         // 2. 새 데이터 추가
         double temp_val = (price-avg_price)*(price-avg_price);
         m_buffer[m_index] = temp_val;
//         m_sum += price;
         m_sum_sq += temp_val;

         // 3. 마지막으로 쓴 위치 저장
         m_last_index = m_index;

         // 4. 인덱스 순환
         m_index = (m_index + 1) % m_size;

         // 5. 표준편차 계산
         if(m_count < 2) 
         {
            m_last_bar = bar;
            m_last_stdValue = 0;
            return 0;
         }
         
//         double mean = m_sum / m_count;
//         double variance = (m_sum_sq / m_count) - (mean * mean);
         m_last_stdValue = MathSqrt(m_sum_sq / m_count);
         m_last_bar = bar;
         return m_last_stdValue;
      }
      else
      {
         // bar 값이 같거나 작으면 price만 업데이트하고 이전 표준편차 반환
         // (버퍼의 마지막 위치에 price만 업데이트하고 합계도 조정, 입력된 avg_price 사용)
         if(m_count > 0)
         {
            // 마지막으로 쓴 위치의 값만 업데이트 (입력된 avg_price 사용)
            double old_val = m_buffer[m_last_index];
            double temp_val = (price-avg_price)*(price-avg_price);
            m_buffer[m_last_index] = temp_val;
            // 합계도 조정 (변화된 값만 반영)
            m_sum_sq = m_sum_sq - old_val + temp_val;
            // 표준편차 재계산
            if(m_count >= 2)
            {
               m_last_stdValue = MathSqrt(m_sum_sq / m_count);
            }
         }
         return m_last_stdValue;
      }
   }
};


//// Standard Deviation Function between two arrays with +, - sign
class HiStdDev2
{
private:
   double m_buffer[];    // 데이터를 담을 순환 버퍼
   int    m_size;        // 윈도우 크기 (5000)
   int    m_index;       // 현재 쓰기 위치 포인터
   int    m_count;       // 현재까지 쌓인 데이터 수
   int    m_last_bar;    // 이전에 입력받은 bar 값
   double m_last_stdValue; // 마지막으로 계산된 표준편차값
   int    m_last_index;  // 마지막으로 쓴 위치 인덱스
   
//   double m_sum;         // 합계 유지
   double m_sum_sq;      // 기호가진 제곱합 유지

public:
   // 생성자
   HiStdDev2(int window_size)
   {
      m_size = window_size;
      ArrayResize(m_buffer, m_size);
      ArrayInitialize(m_buffer, 0.);
      Reset();
   }

   void Reset()
   {
      m_index = 0;
      m_count = 0;
      m_last_bar = -1;
      m_last_stdValue = 0;
      m_last_index = 0;
//      m_sum = 0;
      m_sum_sq = 0;
   }

   // 데이터 추가 및 계산 (매 분마다 호출)
   double Calculate(int bar, double avg_price, double price)
   {
      // bar 값이 이전보다 크면 기존 로직 실행
      if(bar > m_last_bar)
      {
         // 1. 오래된 데이터 제거 (버퍼가 꽉 찼을 때만)
         if(m_count >= m_size)
         {
            double old_val = m_buffer[m_index];
//            m_sum -= old_val;
            m_sum_sq -= old_val;
         }
         else m_count++;

         // 2. 새 데이터 추가
         double temp_val = (price-avg_price)*MathAbs(price-avg_price);
         m_buffer[m_index] = temp_val;
//         m_sum += price;
         m_sum_sq += temp_val;

         // 3. 마지막으로 쓴 위치 저장
         m_last_index = m_index;

         // 4. 인덱스 순환
         m_index = (m_index + 1) % m_size;

         // 5. 기호가진 표준편차 계산
         if(m_count < 2) 
         {
            m_last_bar = bar;
            m_last_stdValue = 0;
            return 0;
         }
         
//         double mean = m_sum / m_count;
//         double variance = (m_sum_sq / m_count) - (mean * mean);
         double stdValue = 0.;
         if(m_sum_sq < 0.) stdValue = -1.*MathSqrt(MathAbs(m_sum_sq / m_count));
         else stdValue = MathSqrt(MathAbs(m_sum_sq / m_count));

         m_last_stdValue = stdValue;
         m_last_bar = bar;
         return stdValue;
      }
      else
      {
         // bar 값이 같거나 작으면 price만 업데이트하고 이전 표준편차 반환
         // (버퍼의 마지막 위치에 price만 업데이트하고 합계도 조정, 입력된 avg_price 사용)
         if(m_count > 0)
         {
            // 마지막으로 쓴 위치의 값만 업데이트 (입력된 avg_price 사용)
            double old_val = m_buffer[m_last_index];
            double temp_val = (price-avg_price)*MathAbs(price-avg_price);
            m_buffer[m_last_index] = temp_val;
            // 합계도 조정 (변화된 값만 반영)
            m_sum_sq = m_sum_sq - old_val + temp_val;
            // 표준편차 재계산
            if(m_count >= 2)
            {
               double stdValue = 0.;
               if(m_sum_sq < 0.) stdValue = -1.*MathSqrt(MathAbs(m_sum_sq / m_count));
               else stdValue = MathSqrt(MathAbs(m_sum_sq / m_count));
               m_last_stdValue = stdValue;
            }
         }
         return m_last_stdValue;
      }
   }
};

//// StdDev Class of array
class HiStdDev3
{
private:
   double m_buffer[];    // 데이터를 담을 순환 버퍼
   int    m_size;        // 윈도우 크기 (5000)
   int    m_index;       // 현재 쓰기 위치 포인터
   int    m_count;       // 현재까지 쌓인 데이터 수
   int    m_last_bar;    // 이전에 입력받은 bar 값
   double m_last_stdValue; // 마지막으로 계산된 표준편차값
   int    m_last_index;  // 마지막으로 쓴 위치 인덱스
   
//   double m_sum;         // 합계 유지
   double m_sum_sq;      // 제곱합 유지

public:
   // 생성자
   HiStdDev3(int window_size)
   {
      m_size = window_size;
      ArrayResize(m_buffer, m_size);
      ArrayInitialize(m_buffer, 0.);
      Reset();
   }

   void Reset()
   {
      m_index = 0;
      m_count = 0;
      m_last_bar = -1;
      m_last_stdValue = 0;
      m_last_index = 0;
//      m_sum = 0;
      m_sum_sq = 0;
   }

   // 데이터 추가 및 계산 (매 분마다 호출)
   double Calculate(int bar, double price)
   {
      // bar 값이 이전보다 크면 기존 로직 실행
      if(bar > m_last_bar)
      {
         // 1. 오래된 데이터 제거 (버퍼가 꽉 찼을 때만)
         if(m_count >= m_size)
         {
            double old_val = m_buffer[m_index];
//            m_sum -= old_val;
            m_sum_sq -= (old_val * old_val);
         }
         else m_count++;

         // 2. 새 데이터 추가
         m_buffer[m_index] = price;
//         m_sum += price;
         m_sum_sq += (price * price);

         // 3. 마지막으로 쓴 위치 저장
         m_last_index = m_index;

         // 4. 인덱스 순환
         m_index = (m_index + 1) % m_size;

         // 5. 표준편차 공식 적용 (O(1))
         if(m_count < 2) 
         {
            m_last_bar = bar;
            m_last_stdValue = 0;
            return 0;
         }
         
//         double mean = m_sum / m_count;
//         double variance = (m_sum_sq / m_count) - (mean * mean);
         double variance = (m_sum_sq / m_count);
         m_last_stdValue = MathSqrt(MathMax(0, variance));
         m_last_bar = bar;
         return m_last_stdValue;
      }
      else
      {
         // bar 값이 같거나 작으면 price만 업데이트하고 이전 표준편차 반환
         // (버퍼의 마지막 위치에 price만 업데이트하고 합계도 조정)
         if(m_count > 0)
         {
            // 마지막으로 쓴 위치의 price만 업데이트
            double old_price = m_buffer[m_last_index];
            m_buffer[m_last_index] = price;
            // 합계도 조정 (변화된 price만 반영)
            m_sum_sq = m_sum_sq - (old_price * old_price) + (price * price);
            // 표준편차 재계산
            if(m_count >= 2)
            {
               double variance = (m_sum_sq / m_count);
               m_last_stdValue = MathSqrt(MathMax(0, variance));
            }
         }
         return m_last_stdValue;
      }
   }
};