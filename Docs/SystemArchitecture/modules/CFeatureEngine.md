# CFeatureEngine — 클래스 설계서

> 모듈 ID: 2-1 | Phase 2 | ★ 가장 복잡한 모듈
> 의존성: CRollingStats, CMacroLoader, FeatureSchema

---

## 1. 단일 책임

**실시간 피처 엔지니어링 통합 엔진**.
- 22개 iCustom 지표 핸들 관리
- ~35개 Raw 슬롯 → CRollingStats 인스턴스에 Push
- 파생 변환 (Z-score, pct_rank, slope, accel, ratio) 실시간 계산
- Entry(80개) / AddOn(77개) 피처 벡터 조립 (`FeatureSchema.mqh` 순서 엄수)
- PreloadHistory: EA 시작 시 과거 1440봉 일괄 로드 → 즉시 `IsReady()`

---

## 2. 클래스 다이어그램

```
┌────────────────────── CFeatureEngine ──────────────────────┐
│                                                             │
│ [Enum: ENUM_IND_HANDLE — 22개 지표 핸들 ID]                 │
│   IH_ADXS_14, IH_ADXS_80, IH_ADXMTF_M5, IH_ADXMTF_H4    │
│   IH_ATR14, IH_BOP, IH_BSP_10_3, IH_BSP_30_5              │
│   IH_BWMTF_M5, IH_BWMTF_H4, IH_CE                        │
│   IH_CHV_10_10, IH_CHV_30_30, IH_CHOP_14_14, IH_CHOP_120  │
│   IH_LRAVG_60, IH_LRAVG_180, IH_LRAVG_240                 │
│   IH_QQE_5_14, IH_QQE_12_32, IH_TDI_13, IH_TDI_14        │
│                                                             │
│ [Enum: ENUM_RAW_SLOT — 36개 Raw 값 슬롯]                   │
│   RS_ADXS14_DIPLUS ~ RS_CLOSE                              │
│                                                             │
│ [멤버 변수]                                                  │
│   int           m_handles[22]     // 지표 핸들 배열          │
│   double        m_raw[36]         // 현재 봉 Raw 값          │
│   CRollingStats m_rs[36]          // 슬롯별 롤링 통계        │
│   CRollingStats m_rsTick60/240/1440  // TickVol 특수 윈도우  │
│   CMacroLoader* m_macroLoader     // 매크로 로더 포인터       │
│   int           m_warmupBars      // 웜업 봉 카운터          │
│   bool          m_isReady         // 240+ 봉 축적 완료?     │
│   double        m_closeHistory[]  // 가격 모멘텀용 링버퍼     │
│                                                             │
│ [공개 메서드]                                                │
│   bool   Init(CMacroLoader* loader)                         │
│   void   Update()                    // ★ M1 봉당 1회       │
│   void   GetEntryFeatures(float &out[80])                   │
│   void   GetAddonFeatures(float &out[77], ...)              │
│   bool   IsReady()          // CRITICAL warm-up 완료 여부   │
│   int    GetWarmupBars()    // 현재 축적 봉 수              │
│   int    GetWarmupPct()     // 진행률 (0~100%)              │
│   double GetATR14()         // CTradeExecutor용              │
│   double GetCE2Value()      // CE2 trailing 값              │
│   double GetBSPScale()      // AddOn 동적 피처용            │
│                                                             │
│ [내부 메서드]                                                │
│   bool   CreateHandles()    // 22개 핸들 생성                │
│   void   ReadRawValues()    // Shift=1로 완성봉 읽기          │
│   double ReadBuffer(hIdx, bufIdx, shift)                    │
│   bool   PreloadHistory()   // 1440봉 히스토리 프리로드       │
│   double SafeDiv(num, den)  // 0-나눗셈 방어                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 입출력 인터페이스

### 3.1 Init — 초기화 파이프라인

```
Init(CMacroLoader* loader)
  ├── CreateHandles()          ← 22개 iCustom/iATR 핸들 생성
  │   └── 1개라도 실패 → return false (INIT_FAILED)
  ├── CRollingStats[36].Init(240)  ← 모든 슬롯 capacity=240
  ├── m_rsTick60/240/1440.Init(60/240/1440)
  └── PreloadHistory()         ← 과거 1440봉 CopyBuffer → Push
      ├── 성공 → IsReady=true (즉시 거래 가능)
      └── 실패 → 점진적 웜업 폴백 모드
```

### 3.2 Update — M1 봉당 실행 흐름

```
Update()  [매 새 M1 봉마다 호출]
  ├── 1. ReadRawValues()       ← Shift=1 (완성봉만, Rule_Shift+1)
  │       22개 지표 × 1~3 버퍼 → m_raw[36] 채움
  │       CE_Dist = Close - CE_SL (가격-CE 거리 계산)
  │       TickVolume = iVolume(_Symbol, M1, 1)
  │
  ├── 2. CRollingStats Push    ← 36개 슬롯에 m_raw Push
  │       + TickVol 특수 통계 Push (60/240/1440)
  │
  ├── 3. Close 히스토리 갱신   ← 모멘텀(price_mom_10) 계산용
  │
  └── 4. Warmup 카운터          ← 240 도달 시 m_isReady = true
```

### 3.3 GetEntryFeatures — 80개 피처 벡터 조립

```
피처 구성 (FeatureSchema.mqh 순서):
  ├── 기술 지표 파생변환 (~60개)
  │   ├── ZScore(60/240)     ← m_rs[slot].GetZScore(60)
  │   ├── PctRank(240)       ← m_rs[slot].GetPctRank(240)
  │   ├── Slope(5/14)        ← m_rs[slot].GetSlope(14)
  │   ├── Accel(14)          ← m_rs[slot].GetAccel(14)
  │   ├── Passthrough        ← m_raw[slot] (스케일 오실레이터)
  │   ├── Ratio              ← SafeDiv(CE_Dist, ATR14)
  │   └── TickVol Ratio/ZScore/PctRank
  │
  ├── Regime 피처 (4개)
  │   ├── regime_monthly_pct  ← Close의 PctRank
  │   ├── regime_weekly_up_ratio (placeholder)
  │   ├── regime_above_ma20w (placeholder)
  │   └── regime_bull_flag (placeholder)
  │
  └── 매크로 피처 (~16개)
      └── m_macroLoader.GetFeature("GOLD_zscore_240"), etc.
```

### 3.4 GetAddonFeatures — 77개 피처 벡터

```
Entry 피처의 공유 부분 + 동적 포지션 피처 7개:
  ├── addon_count           ← 현재 피라미딩 횟수
  ├── unrealized_pnl_atr    ← 미실현수익 ATR 배수
  ├── bars_since_entry      ← 진입 후 경과 봉
  ├── atr_expansion         ← ATR 확장률
  ├── bsp_scale_delta       ← BSPScale 변화량
  ├── trend_acceleration    ← 추세 가속도
  └── + _pct 변환 (pct240)
```

---

## 4. 에러 처리

| 시나리오 | 대응 |
|:---|:---|
| iCustom 핸들 생성 실패 | Print CRITICAL → `Init()` return false → `INIT_FAILED` |
| CopyBuffer 실패 (ReadBuffer) | `0.0` 반환 (안전 기본값). 로그에 핸들/버퍼 ID 기록 |
| EMPTY_VALUE 반환 | `0.0`으로 치환 (NaN 전파 방지) |
| PreloadHistory 실패 | 점진적 웜업 폴백. 240봉 후 IsReady |
| IsReady=false 상태에서 GetEntryFeatures 호출 | 전부 0으로 채운 배열 반환 |
| SafeDiv → 분모 0 | `0.0` 반환 |

---

## 5. 성능 고려사항

| 항목 | 설계 |
|:---|:---|
| **CopyBuffer 호출** | M1 봉당 36회 (각 O(1), shift=1) ≈ 0.5ms |
| **CRollingStats Push** | M1 봉당 36+3=39회 Push (각 O(1)) |
| **파생 변환** | GetZScore/PctRank/Slope ≒ 80회 × O(240) 최대 |
| **PreloadHistory** | OnInit 1회, 31개 버퍼 × 1440봉 CopyBuffer |
| **메모리** | CRollingStats 39개 × 240×8B = 73KB + 히스토리 배열 |

---

## 6. 의존성

```
CFeatureEngine
  ├── CRollingStats.mqh      — 36+3 인스턴스 (파생 변환 연산)
  ├── CMacroLoader.mqh       — 매크로 피처 로드 (포인터)
  ├── FeatureSchema.mqh      — 피처 순서 상수 (ENTRY_FEATURE_COUNT 등)
  ├── 22개 커스텀 지표        — Indicators/AIEngine/ 폴더
  │     (ADXSmooth, BOPAvgStd, BSPWmaSmooth, BWMFI_MTF,
  │      ChandelierExit, ChaikinVolatility, ChoppingIndex,
  │      LRAVGSTD, QQE, TDI)
  └── iATR (표준 지표)

호출 관계:
  BSP_Long_v1.mq5
    ├── CFeatureEngine.Init(&macroLoader)
    ├── CFeatureEngine.Update()           ← 매 M1 봉
    ├── CFeatureEngine.GetEntryFeatures() → COnnxPredictor
    ├── CFeatureEngine.GetAddonFeatures() → COnnxPredictor
    ├── CFeatureEngine.GetATR14()         → CTradeExecutor
    └── CFeatureEngine.GetCE2Value()      → CTradeExecutor
```
