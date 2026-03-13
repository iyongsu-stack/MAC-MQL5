//+------------------------------------------------------------------+
//| CRollingStats.mqh — Ring-buffer based rolling statistics         |
//| Phase 1-1 | AIEngine Module                                      |
//|                                                                  |
//| Provides: Z-score, PctRank, Slope, Accel over configurable       |
//|           rolling windows using a fixed-capacity ring buffer.     |
//|                                                                  |
//| Usage:                                                           |
//|   CRollingStats stats;                                           |
//|   stats.Init(240);                                               |
//|   stats.Push(value);  // call every M1 bar                       |
//|   double z60  = stats.GetZScore(60);                             |
//|   double pct  = stats.GetPctRank(240);                           |
//+------------------------------------------------------------------+
#ifndef __CROLLINGSTATS_MQH__
#define __CROLLINGSTATS_MQH__

//+------------------------------------------------------------------+
//| CRollingStats class                                              |
//+------------------------------------------------------------------+
class CRollingStats
{
private:
   double         m_buffer[];        // Ring buffer (fixed capacity)
   int            m_capacity;        // Max buffer size
   int            m_count;           // Total values pushed (capped at capacity)
   int            m_head;            // Next write position (circular)
   
   // Incremental stats for O(1) mean/std over full buffer
   double         m_sum;             // Running sum of values in buffer
   double         m_sumSq;           // Running sum of squares
   
   //--- Internal helpers
   int            Idx(int offset) const;          // Convert logical offset → physical index
   void           GetRecentValues(double &out[], int window) const;
   
public:
                  CRollingStats();
                 ~CRollingStats();
   
   //--- Initialization
   bool           Init(int capacity);
   void           Reset();
   
   //--- Data input
   void           Push(double value);
   void           PushArray(const double &values[], int count);
   
   //--- Rolling statistics (window ≤ capacity)
   double         GetMean(int window) const;
   double         GetStd(int window) const;
   double         GetZScore(int window) const;
   double         GetPctRank(int window) const;
   double         GetSlope(int window) const;
   double         GetAccel(int slopeWindow, int accelWindow = 0) const;
   
   //--- Accessors
   double         GetLatest() const;
   int            GetCount() const          { return m_count; }
   int            GetCapacity() const       { return m_capacity; }
   bool           IsReady(int window) const { return m_count >= window; }
   double         GetFillRatio(int window) const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRollingStats::CRollingStats()
   : m_capacity(0), m_count(0), m_head(0), m_sum(0.0), m_sumSq(0.0)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRollingStats::~CRollingStats()
{
}

//+------------------------------------------------------------------+
//| Initialize with given capacity                                   |
//+------------------------------------------------------------------+
bool CRollingStats::Init(int capacity)
{
   if(capacity <= 0 || capacity > 10000)
   {
      Print("[CRollingStats] Init failed: invalid capacity=", capacity);
      return false;
   }
   
   m_capacity = capacity;
   ArrayResize(m_buffer, m_capacity);
   ArrayInitialize(m_buffer, 0.0);
   m_count = 0;
   m_head  = 0;
   m_sum   = 0.0;
   m_sumSq = 0.0;
   
   return true;
}

//+------------------------------------------------------------------+
//| Reset to empty state (preserves capacity)                        |
//+------------------------------------------------------------------+
void CRollingStats::Reset()
{
   ArrayInitialize(m_buffer, 0.0);
   m_count = 0;
   m_head  = 0;
   m_sum   = 0.0;
   m_sumSq = 0.0;
}

//+------------------------------------------------------------------+
//| Push a new value into the ring buffer                             |
//+------------------------------------------------------------------+
void CRollingStats::Push(double value)
{
   if(m_capacity <= 0)
      return;
   
   // If buffer is full, subtract the oldest value being overwritten
   if(m_count >= m_capacity)
   {
      double oldVal = m_buffer[m_head];
      m_sum   -= oldVal;
      m_sumSq -= oldVal * oldVal;
   }
   
   // Write new value
   m_buffer[m_head] = value;
   m_sum   += value;
   m_sumSq += value * value;
   
   // Advance head (circular)
   m_head = (m_head + 1) % m_capacity;
   
   // Increment count (capped at capacity)
   if(m_count < m_capacity)
      m_count++;
}

//+------------------------------------------------------------------+
//| Push multiple values at once (for history preload in OnInit)      |
//+------------------------------------------------------------------+
void CRollingStats::PushArray(const double &values[], int count)
{
   int n = MathMin(count, ArraySize(values));
   for(int i = 0; i < n; i++)
      Push(values[i]);
}

//+------------------------------------------------------------------+
//| Convert logical offset (0=latest) → physical buffer index        |
//| offset=0 → most recent, offset=1 → one before, etc.             |
//+------------------------------------------------------------------+
int CRollingStats::Idx(int offset) const
{
   // m_head points to next write position
   // latest value is at (m_head - 1)
   int idx = (m_head - 1 - offset + m_capacity * 2) % m_capacity;
   return idx;
}

//+------------------------------------------------------------------+
//| Extract recent N values into array (out[0]=oldest, out[N-1]=latest)|
//+------------------------------------------------------------------+
void CRollingStats::GetRecentValues(double &out[], int window) const
{
   int w = MathMin(window, m_count);
   ArrayResize(out, w);
   for(int i = 0; i < w; i++)
   {
      // i=0 → oldest in window, i=w-1 → latest
      out[i] = m_buffer[Idx(w - 1 - i)];
   }
}

//+------------------------------------------------------------------+
//| Rolling mean over last N values                                  |
//| O(N) when window < full buffer, O(1) when window == capacity     |
//+------------------------------------------------------------------+
double CRollingStats::GetMean(int window) const
{
   if(m_count == 0 || window <= 0)
      return 0.0;
   
   int w = MathMin(window, m_count);
   
   // Optimization: if window == full buffer count, use incremental sum
   if(w == m_count && m_count == m_capacity)
      return m_sum / w;
   
   // Otherwise, compute from scratch
   double sum = 0.0;
   for(int i = 0; i < w; i++)
      sum += m_buffer[Idx(i)];
   
   return sum / w;
}

//+------------------------------------------------------------------+
//| Rolling standard deviation over last N values                    |
//+------------------------------------------------------------------+
double CRollingStats::GetStd(int window) const
{
   if(m_count < 2 || window < 2)
      return 0.0;
   
   int w = MathMin(window, m_count);
   
   double sum = 0.0, sumSq = 0.0;
   
   // Special case: full buffer
   if(w == m_count && m_count == m_capacity)
   {
      sum   = m_sum;
      sumSq = m_sumSq;
   }
   else
   {
      for(int i = 0; i < w; i++)
      {
         double v = m_buffer[Idx(i)];
         sum   += v;
         sumSq += v * v;
      }
   }
   
   double mean = sum / w;
   double variance = (sumSq / w) - (mean * mean);
   
   // Guard against negative variance due to floating point
   if(variance < 0.0)
      variance = 0.0;
   
   return MathSqrt(variance);
}

//+------------------------------------------------------------------+
//| Z-score (Python Emulation): (latest - mean_shifted) / std_shifted|
//| ┌──────────────────────────────────────────────────────────────┐  |
//| │ [CRITICAL] Python Emulation — DO NOT CHANGE                 │  |
//| │ Python: zscore_shift1(s, w)                                  │  |
//| │   shifted = s.shift(1)                                       │  |
//| │   mean = shifted.rolling(w).mean()                           │  |
//| │   std  = shifted.rolling(w).std()   ← ddof=1 (Pandas 기본)  │  |
//| │   z = (s - mean) / std                                       │  |
//| │                                                              │  |
//| │ 핵심: 현재 봉 s[t]는 mean/std 계산에서 완전히 제외된다.      │  |
//| │ Idx(1) ~ Idx(window) 구간만으로 mean/std를 구한 뒤,          │  |
//| │ (Idx(0) - mean) / std 를 반환한다.                           │  |
//| │ Ref: build_tech_derived.py L43-49, GEMINI.md Rule 1 & Rule 8│  |
//| └──────────────────────────────────────────────────────────────┘  |
//+------------------------------------------------------------------+
double CRollingStats::GetZScore(int window) const
{
   // 최소 window+1개 데이터 필요 (현재봉 + 과거 window개)
   if(m_count < MathMin(window + 1, 3))
      return 0.0;
   
   int w = MathMin(window, m_count - 1);  // 현재봉 제외, 과거 데이터만
   if(w < 2)
      return 0.0;
   
   // Idx(1) ~ Idx(w) 구간의 mean, std 계산 (현재봉 Idx(0) 완전 제외)
   double sum = 0.0, sumSq = 0.0;
   for(int i = 1; i <= w; i++)
   {
      double v = m_buffer[Idx(i)];
      sum   += v;
      sumSq += v * v;
   }
   
   double mean = sum / w;
   // Bessel 보정 (N-1): Pandas .std() 기본값 ddof=1 과 동일
   double variance = (sumSq - sum * sum / w) / (w - 1);
   if(variance < 0.0) variance = 0.0;
   
   double std = MathSqrt(variance);
   if(std < 1e-15)
      return 0.0;
   
   return (GetLatest() - mean) / std;
}

//+------------------------------------------------------------------+
//| Percentile rank (Python Emulation): Idx(1) target ranking        |
//| ┌──────────────────────────────────────────────────────────────┐  |
//| │ [CRITICAL] Python Emulation — DO NOT CHANGE                 │  |
//| │ Python: s.shift(1).rolling(w).rank(pct=True)                 │  |
//| │                                                              │  |
//| │ Pandas의 shift(1) 적용 시 타겟도 함께 밀려,                 │  |
//| │ "직전봉(t-1)이 과거 윈도우에서 상위 몇 %인지" 계산됨.       │  |
//| │ AI 모델(AUC 0.82)이 이 방식에 최적화됨.                     │  |
//| │                                                              │  |
//| │ 🔬 숏전략 개발 시 A/B 비교 실험 지정 항목:                  │  |
//| │   A안(현재): Idx(1) 타겟 (Python 에뮬, 1-bar 지연 랭크)     │  |
//| │   B안: Idx(0) 타겟 (수학적 정확 현재봉 랭크)                │  |
//| │ Ref: build_tech_derived.py, GEMINI.md Rule 8 & 숏전략 TODO  │  |
//| └──────────────────────────────────────────────────────────────┘  |
//+------------------------------------------------------------------+
double CRollingStats::GetPctRank(int window) const
{
   // 최소 2개 데이터 필요 (타겟 Idx(1) + 비교 대상 1개)
   if(m_count < 2 || window <= 0)
      return 0.5;
   
   int w = MathMin(window, m_count - 1);  // Idx(1) ~ Idx(w) 범위
   if(w < 1)
      return 0.5;
   
   // 타겟: 직전봉 Idx(1) — Python의 shift(1) 에뮬레이션
   double target = m_buffer[Idx(1)];
   
   int countBelow = 0;
   for(int i = 1; i <= w; i++)
   {
      if(m_buffer[Idx(i)] <= target)
         countBelow++;
   }
   
   return (double)countBelow / w;
}

//+------------------------------------------------------------------+
//| Slope (Python Emulation): simple momentum diff(n)/n              |
//| ┌──────────────────────────────────────────────────────────────┐  |
//| │ [CRITICAL] Python Emulation — DO NOT CHANGE                 │  |
//| │ Python: slope(s, n) = s.diff(n) / n                         │  |
//| │ = (현재값 - n봉 전 값) / n  (단순 모멘텀)                    │  |
//| │ AI 모델이 이 방식으로 학습됨.                                │  |
//| │ Linear Regression으로 절대 변경 금지!                        │  |
//| │ Ref: build_tech_derived.py L33-35, GEMINI.md Rule 8         │  |
//| └──────────────────────────────────────────────────────────────┘  |
//+------------------------------------------------------------------+
double CRollingStats::GetSlope(int window) const
{
   if(m_count < 2 || window < 2)
      return 0.0;
   
   int w = MathMin(window, m_count - 1);  // 인덱스 범위 방어: Idx(w) 안전 참조
   if(w < 1)
      return 0.0;
   
   // Python: s.diff(n) / n = (latest - n_bars_ago) / n
   double latest = m_buffer[Idx(0)];   // 현재 봉 (가장 최근)
   double nAgo   = m_buffer[Idx(w)];   // w봉 전 값
   
   return (latest - nAgo) / w;
}

//+------------------------------------------------------------------+
//| Acceleration (Python Emulation): slope(s,n).diff(n)              |
//| ┌──────────────────────────────────────────────────────────────┐  |
//| │ [CRITICAL] Python Emulation — DO NOT CHANGE                 │  |
//| │ Python: accel(s, n) = slope(s, n).diff(n)                    │  |
//| │ = (현재 slope - n봉 전 slope)                                │  |
//| │ 이전 구간 Slope도 반드시 단순 모멘텀(diff/n) 방식.           │  |
//| │ Ref: build_tech_derived.py L38-40, GEMINI.md Rule 8         │  |
//| └──────────────────────────────────────────────────────────────┘  |
//+------------------------------------------------------------------+
double CRollingStats::GetAccel(int slopeWindow, int accelWindow) const
{
   if(accelWindow == 0)
      accelWindow = slopeWindow;
   
   // 최대 인덱스: accelWindow + slopeWindow
   int needed = slopeWindow + accelWindow;
   if(m_count <= needed || slopeWindow < 2)
      return 0.0;
   
   // 현재 구간 slope (단순 모멘텀)
   double latest    = m_buffer[Idx(0)];
   double nAgo      = m_buffer[Idx(slopeWindow)];
   double slopeCurr = (latest - nAgo) / slopeWindow;
   
   // 이전 구간 slope (accelWindow봉 전 시점의 단순 모멘텀)
   double prevLatest = m_buffer[Idx(accelWindow)];
   double prevNAgo   = m_buffer[Idx(accelWindow + slopeWindow)];
   double slopePrev  = (prevLatest - prevNAgo) / slopeWindow;
   
   return slopeCurr - slopePrev;
}

//+------------------------------------------------------------------+
//| Get the most recent value                                        |
//+------------------------------------------------------------------+
double CRollingStats::GetLatest() const
{
   if(m_count == 0)
      return 0.0;
   
   return m_buffer[Idx(0)];
}

//+------------------------------------------------------------------+
//| Fill ratio for warm-up progress display                          |
//| Returns 0.0~1.0 (capped at 1.0)                                 |
//+------------------------------------------------------------------+
double CRollingStats::GetFillRatio(int window) const
{
   if(window <= 0)
      return 1.0;
   
   return MathMin(1.0, (double)m_count / window);
}

#endif // __CROLLINGSTATS_MQH__
