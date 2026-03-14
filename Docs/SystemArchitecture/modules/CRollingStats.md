# CRollingStats — 클래스 설계서

> 모듈 ID: 1-1 | Phase 1 | 의존성: 없음 (독립 유틸리티)

---

## 1. 단일 책임

**링버퍼 기반 롤링 통계 계산** 유틸리티.
- 고정 용량 링버퍼에 M1 봉 데이터를 Push하고, Z-score / PctRank / Slope / Accel을 O(N) 이하로 계산
- CFeatureEngine이 피처별 인스턴스(~30개)를 보유하며 파생 변환에 활용
- **Python 에뮬레이션 필수** (Rule_Python_MQL5_Fidelity): `build_tech_derived.py`와 수학적으로 100% 동일한 연산

---

## 2. 클래스 다이어그램

```
┌──────────────────── CRollingStats ─────────────────────┐
│                                                         │
│ [멤버 변수]                                              │
│   double m_buffer[]       // 링버퍼 (고정 용량)         │
│   int    m_capacity       // 최대 버퍼 크기              │
│   int    m_count          // 현재 저장된 값 수 (≤ cap)   │
│   int    m_head           // 다음 쓰기 위치 (순환)       │
│   double m_sum            // O(1) 평균용 누적합          │
│   double m_sumSq          // O(1) 표준편차용 제곱합      │
│                                                         │
│ [공개 메서드]                                            │
│   bool   Init(int capacity)                             │
│   void   Reset()                                        │
│   void   Push(double value)                             │
│   void   PushArray(const double &values[], int count)   │
│                                                         │
│   double GetMean(int window)       // 롤링 평균         │
│   double GetStd(int window)        // 롤링 표준편차     │
│   double GetZScore(int window)     // ★ Python 에뮬    │
│   double GetPctRank(int window)    // ★ Python 에뮬    │
│   double GetSlope(int window)      // ★ Python 에뮬    │
│   double GetAccel(int sW, int aW)  // ★ Python 에뮬    │
│                                                         │
│   double GetLatest()               // 최신값 조회       │
│   int    GetCount()                // 현재 저장수       │
│   bool   IsReady(int window)       // window ≤ count?  │
│   double GetFillRatio(int window)  // 웜업 진행률       │
│                                                         │
│ [내부 메서드]                                            │
│   int    Idx(int offset)           // 논리→물리 인덱스  │
│   void   GetRecentValues(double &out[], int window)     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 핵심 연산 (Python 에뮬레이션 — CRITICAL)

> ⚠️ 아래 4개 함수는 **모델 재학습 없이 절대 변경 금지** (GEMINI.md Rule 8)

### 3.1 GetZScore(window)

```
Python: zscore_shift1(s, w)
  shifted = s.shift(1)
  mean = shifted.rolling(w).mean()
  std  = shifted.rolling(w).std()   ← ddof=1 (Pandas 기본)
  z = (s - mean) / std

MQL5 에뮬:
  대상 구간: Idx(1) ~ Idx(window)  ← 현재봉 Idx(0) 완전 제외
  mean = Σ(vals) / w
  variance = (ΣSq - Σ²/w) / (w-1)   ← Bessel 보정
  return (Idx(0) - mean) / sqrt(variance)
```

### 3.2 GetPctRank(window)

```
Python: s.shift(1).rolling(w).rank(pct=True)

MQL5 에뮬:
  타겟: Idx(1)  ← 직전봉 (shift(1) 에뮬)
  대상: Idx(1) ~ Idx(window)
  countBelow = count(val ≤ target)
  return countBelow / window
```

> 🔬 **숏전략 개발 시 A/B 비교 실험 예정** (A안=현재 Idx(1), B안=Idx(0))

### 3.3 GetSlope(window)

```
Python: s.diff(n) / n  (단순 모멘텀)

MQL5 에뮬:
  return (Idx(0) - Idx(window)) / window
  ⚠️ Linear Regression으로 절대 변경 금지!
```

### 3.4 GetAccel(slopeWindow, accelWindow)

```
Python: slope(s, n).diff(n)

MQL5 에뮬:
  slopeCurr = (Idx(0) - Idx(sW)) / sW
  slopePrev = (Idx(aW) - Idx(aW+sW)) / sW
  return slopeCurr - slopePrev
```

---

## 4. 에러 처리

| 시나리오 | 대응 |
|:---|:---|
| `capacity ≤ 0` 또는 `> 10000` | `Init()` → `false` 반환 + Print 경고 |
| `m_count < window+1` (ZScore) | `0.0` 반환 (안전 기본값) |
| `m_count < 2` (PctRank) | `0.5` 반환 (중립 랭크) |
| `std < 1e-15` (ZScore) | `0.0` 반환 (0 나눗셈 방지) |
| `floating-point variance < 0` | `0.0`으로 클리핑 후 계속 |

---

## 5. 성능 고려사항

| 항목 | 설계 |
|:---|:---|
| **Push** | O(1) — 링버퍼 덮어쓰기 + 증분 합/제곱합 갱신 |
| **GetMean (full)** | O(1) — 증분 `m_sum/count` (버퍼 꽉 찬 경우) |
| **GetMean (window)** | O(N) — 부분 윈도우는 루프 |
| **GetZScore** | O(N) — Idx(1)~Idx(w) 순회 |
| **GetPctRank** | O(N) — 비교 순회 |
| **GetSlope** | O(1) — 2개 값만 참조 |
| **메모리** | 인스턴스당 `capacity × 8 bytes` (240 → 1.9KB) |
| **PreloadHistory** | `PushArray()`로 1440봉 일괄 투입 → EA 시작 즉시 IsReady |

---

## 6. 의존성

```
CRollingStats
  └── 외부 의존성 없음 (독립 유틸리티)

호출하는 모듈:
  ├── CFeatureEngine.mqh  — 피처별 인스턴스 ~30개 보유
  └── (간접) GetZScore/GetPctRank/GetSlope → 피처 벡터 조립
```
