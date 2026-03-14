# CSignalGenerator — 클래스 설계서

> 모듈 ID: 2-2 | Phase 2 | 의존성: 없음 (독립 판단 엔진)

---

## 1. 단일 책임

**진입 신호 판단 엔진**.
- AI 모델 확률(prob)을 임계치와 비교 → `ENTRY` / `ADDON` / `NONE` 신호 생성
- 다단계 게이트: Warm-up → Event Blackout → ONNX 유효성 → 확률 판단 → 피라미딩 조건
- 모든 판단에 **사유(reason)** 문자열 기록 → CTradeLogger로 전달

---

## 2. 클래스 다이어그램

```
┌──────────────── CSignalGenerator ──────────────────┐
│                                                     │
│ [Enum: ENUM_SIGNAL]                                 │
│   SIGNAL_NONE  = 0  // 행동 없음                    │
│   SIGNAL_ENTRY = 1  // 1차 진입 (롱)                │
│   SIGNAL_ADDON = 2  // 피라미딩 추가 진입            │
│                                                     │
│ [멤버 변수]                                          │
│   double m_entryThreshold   // 진입 임계치 (0.20)   │
│   double m_addonThreshold   // 피라미딩 임계치 (0.40)│
│   int    m_maxPyramiding    // 최대 추가 횟수 (3)    │
│   int    m_minBarsGap       // 최소 봉 간격 (5)     │
│   double m_minProfitATR     // 최소 미실현수익 (1.5) │
│   string m_lastReason       // 마지막 판단 사유      │
│   ENUM_SIGNAL m_lastSignal  // 마지막 신호           │
│                                                     │
│ [공개 메서드]                                        │
│   void        Init(entryThr, addonThr, ...)         │
│   ENUM_SIGNAL Evaluate(probEntry, probAddon,        │
│                   hasPosition, addonCount,           │
│                   unrealizedATR, barsSinceLast,      │
│                   isBlackout, isWarmupReady)         │
│   string      GetLastReason()                       │
│   void        Reset()   // 포지션 청산 시 호출       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 3. 입출력 인터페이스

### 3.1 Evaluate — 다단계 게이트 판단 흐름

```
Evaluate(probEntry, probAddon, hasPosition, addonCount,
         unrealizedATR, barsSinceLastEntry, isBlackout, isWarmupReady)
  │
  ├── Gate 1: isWarmupReady == false?
  │   └── NONE "Warm-up not complete"
  │
  ├── Gate 2: isBlackout == true?
  │   └── NONE "Event blackout active"
  │
  ├── Gate 3: probEntry < 0 AND probAddon < 0?
  │   └── NONE "ONNX inference failed"
  │
  ├── Case A: 포지션 없음 (hasPosition == false)
  │   ├── probEntry < 0       → NONE "Entry prob invalid"
  │   ├── probEntry ≥ 0.20    → ★ ENTRY
  │   └── probEntry < 0.20    → NONE "prob < threshold"
  │
  └── Case B: 포지션 있음 (hasPosition == true)
      ├── probAddon < 0       → NONE "Addon prob invalid"
      ├── probAddon < 0.40    → NONE "addon prob < 0.40"
      ├── addonCount ≥ 3      → NONE "max addon reached"
      ├── unrealizedATR < 1.5 → NONE "profit < 1.5 ATR"
      ├── barsSince < 5       → NONE "bars gap < 5"
      └── 전부 통과           → ★ ADDON
```

### 3.2 판단 사유 예시

```
"ENTRY: prob=0.2350 >= 0.20"
"ADDON: prob=0.4520, count=2, profit=3.1ATR, gap=12 bars"
"NONE: addon_prob=0.3800 < 0.40"
"NONE: unrealized=1.2ATR < min=1.5"
"NONE: Event blackout active"
```

---

## 4. 에러 처리

| 시나리오 | 대응 |
|:---|:---|
| prob = -1.0 (ONNX 실패) | Gate 3에서 `NONE` 반환 — 안전하게 스킵 |
| 모든 파라미터 정상 범위 외 | 각 Gate에서 명시적 `NONE` + 사유 기록 |
| Reset 호출 누락 | 포지션 청산 감지 시 CTradeExecutor가 자동 호출 |

---

## 5. 성능 고려사항

| 항목 | 설계 |
|:---|:---|
| **연산 비용** | O(1) — 단순 비교 연산만 수행 |
| **호출 빈도** | M1 봉당 1회 |
| **메모리** | 상수 + 문자열 1개 ≈ 수백 바이트 |

---

## 6. 의존성

```
CSignalGenerator
  └── 외부 의존성 없음 (순수 판단 로직)

입력 제공 모듈:
  ├── COnnxPredictor     → probEntry, probAddon
  ├── CTradeExecutor     → hasPosition, addonCount, unrealizedATR, barsSince
  ├── CEventFilter       → isBlackout
  └── CFeatureEngine     → isWarmupReady

출력 소비 모듈:
  ├── BSP_Long_v1.mq5    → ENUM_SIGNAL에 따라 ExecuteEntry/Addon 호출
  └── CTradeLogger       → GetLastReason() → 로그 기록
```
