# BSP_Long_v1 — EA 통합 설계서

> 모듈 ID: 3-3 | Phase 3 | 의존성: 모든 AIEngine 모듈

---

## 1. 단일 책임

**모든 모듈을 통합하는 메인 EA 파일.**
`OnInit()` / `OnTick()` / `OnDeinit()` 3대 함수에서 전체 시스템 흐름을 제어한다.

---

## 2. EA 구조

```
BSP_Long_v1.mq5
│
├── #include 영역
│   ├── <Trade/Trade.mqh>                  // CTrade
│   ├── "Include/AIEngine/FeatureSchema.mqh"
│   ├── "Include/AIEngine/CRollingStats.mqh"
│   ├── "Include/AIEngine/CMacroLoader.mqh"
│   ├── "Include/AIEngine/CFeatureEngine.mqh"
│   ├── "Include/AIEngine/COnnxPredictor.mqh"
│   ├── "Include/AIEngine/CEventFilter.mqh"
│   ├── "Include/AIEngine/CSignalGenerator.mqh"
│   ├── "Include/AIEngine/CTradeExecutor.mqh"
│   ├── "Include/AIEngine/CTradeLogger.mqh"
│   └── "Include/AIEngine/CDashboard.mqh"
│
├── 전역 인스턴스 선언
│   ├── CTrade           g_trade;
│   ├── CFeatureEngine   g_features;
│   ├── COnnxPredictor   g_entryModel;
│   ├── COnnxPredictor   g_addonModel;
│   ├── CEventFilter     g_eventFilter;
│   ├── CSignalGenerator g_signal;
│   ├── CTradeExecutor   g_executor;
│   ├── CTradeLogger     g_logger;
│   ├── CDashboard       g_dashboard;
│   └── CMacroLoader     g_macroLoader;
│
├── 성과 추적 변수
│   ├── double g_peakEquity;
│   ├── double g_maxDD;
│   └── datetime g_lastPerfCalc;
│
└── OnInit() / OnTick() / OnDeinit()
```

---

## 3. ExternVariables (input 변수 목록)

> `Include/BSPVx/ExternVariables.mqh` (신규 AI EA 전용)

```cpp
// ─── EA 식별 ───
input group           "EA Identification"
input int             MagicNumber          = 100001;   // Magic Number (Long:10000x, Short:20000x)

// ─── 리스크 관리 ───
input group           "Risk Management"
input double          RiskPercent           = 1.0;      // 매 포지션 리스크 (%)

// ─── AI 모델 ───
input group           "AI Model"
input double          EntryThreshold        = 0.20;     // Entry 확률 문턱값
input double          AddonThreshold        = 0.40;     // Addon 확률 문턱값
input int             MaxPyramiding         = 3;        // 추가 진입 최대 횟수

// ─── 안전장치 ───
input group           "Safety"
input double          EmergencySL_ATR_Mult  = 12.0;     // 비상 SL = ATR14 × N
input bool            UseVirtualStop        = true;     // Virtual Stop ON/OFF
input bool            UseEventFilter        = false;    // 이벤트 블랙아웃 ON/OFF

// ─── 파일 경로 ───
input group           "File Paths"
input string          MacroCSVPath          = "live/macro_latest.csv";
input string          EventCSVPath          = "live/events.csv";
input string          EntryModelPath        = "models/model_long_ABC.onnx";
input string          AddonModelPath        = "models/model_addon_ABC.onnx";
```

---

## 4. OnInit() 흐름

```
OnInit()
  │
  ├── 0. CTrade 초기화
  │     g_trade.SetExpertMagicNumber(MagicNumber)
  │     g_trade.SetDeviationInPoints(30)
  │
  ├── 1. MagicNumber 중복 실행 방지 ★
  │     lockKey = "AI_LOCK_" + IntegerToString(MagicNumber)
  │     if(GlobalVariableCheck(lockKey))
  │       ├── 기존 값 = GlobalVariableGet(lockKey)
  │       ├── 현재 ChartID와 다르면 → Alert("중복 MN 감지!") → INIT_FAILED
  │       └── 같으면 → 재시작(정상)
  │     GlobalVariableSet(lockKey, ChartID())
  │
  ├── 2. 모듈 초기화 (의존성 순서)
  │     ├── g_macroLoader.Init(MacroCSVPath)
  │     │     └── 실패 → Print("WARNING: Macro CSV not loaded") (비치명적)
  │     │
  │     ├── g_features.Init(MagicNumber, Symbol())
  │     │     ├── CreateHandles()        // 22개 iCustom 핸들
  │     │     ├── PreloadHistory()       // 과거 1440봉 로드
  │     │     └── 실패 → INIT_FAILED
  │     │
  │     ├── g_entryModel.Init(EntryModelPath, FEATURE_COUNT)
  │     │     └── 실패 → INIT_FAILED
  │     ├── g_addonModel.Init(AddonModelPath, FEATURE_COUNT)
  │     │     └── 실패 → INIT_FAILED
  │     │
  │     ├── g_eventFilter.Init(EventCSVPath)
  │     │     └── 실패 → Print("WARNING: Event filter disabled") (비치명적)
  │     │
  │     ├── g_signal.Init(EntryThreshold, AddonThreshold, MaxPyramiding)
  │     │
  │     ├── g_executor.Init(MagicNumber, Symbol(), g_trade,
  │     │                    EmergencySL_ATR_Mult, UseVirtualStop)
  │     │     └── → 내부에서 PositionScan + GlobalVariable 복원 (Resilience)
  │     │
  │     ├── g_logger.Init(MagicNumber, Symbol())
  │     │     └── 실패 → Print("WARNING: Logger disabled") (비치명적)
  │     │
  │     └── g_dashboard.Init(MagicNumber, Symbol())
  │
  ├── 3. 성과 초기화
  │     g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY)
  │     g_maxDD = 0
  │
  └── return INIT_SUCCEEDED
```

---

## 5. OnTick() 흐름

> SystemArchitecture §2.3 OnTick 흐름 준수

```
OnTick()
  │
  ╔══════════════════════════════════════════════════════╗
  ║  A. 항상 실행 — 웜업 무관 (포지션 보호 최우선)        ║
  ╚══════════════════════════════════════════════════════╝
  │
  ├─ A-1. Virtual Stop 체크 (매 틱)
  │     g_executor.CheckVirtualStop()
  │     ├── bid ≤ virtualSL   → CloseAll("Virtual SL hit")
  │     │                        g_logger.LogClose("Virtual SL", pnl, bars)
  │     ├── bid ≤ virtualCE2  → CloseAll("CE2 trailing stop")
  │     │                        g_logger.LogClose("CE2 stop", pnl, bars)
  │     └── 그 외             → 계속
  │
  ├─ A-2. CE2 래칫 갱신 (매 M1 봉)
  │     if(새 M1 봉)
  │       g_executor.UpdateCE2Ratchet()
  │
  ╔══════════════════════════════════════════════════════╗
  ║  B. 웜업 완료 후에만 실행 (신규 진입 판단)             ║
  ╚══════════════════════════════════════════════════════╝
  │
  ├─ B-0. 새 M1 봉 확인
  │     if(!IsNewBar()) → return
  │
  ├─ B-1. Dashboard 시스템 상태 업데이트
  │     g_dashboard.SetSystemState(...)
  │
  ├─ B-2. 피처 계산
  │     g_features.Update()
  │     if(!g_features.IsReady())
  │       ├── g_dashboard.SetAI(..., warmup 진행률)
  │       ├── g_dashboard.Render()
  │       └── return  // 웜업 미완료 → 진입 판단 스킵
  │
  ├─ B-3. 피처 벡터 추출
  │     float features[FEATURE_COUNT];
  │     g_features.GetFeatureVector(features)
  │
  ├─ B-4. ONNX 추론
  │     double probEntry = g_entryModel.Predict(features)
  │     double probAddon = g_addonModel.Predict(features)
  │
  ├─ B-5. 이벤트 블랙아웃 체크
  │     bool blackout = false
  │     if(UseEventFilter)
  │       blackout = g_eventFilter.IsBlackout()
  │
  ├─ B-6. 신호 판단
  │     SIGNAL sig = g_signal.Evaluate(probEntry, probAddon,
  │                    g_executor.HasPosition(),
  │                    g_executor.GetUnrealizedATR(),
  │                    g_executor.GetAddonCount(),
  │                    g_executor.GetBarsSinceLastAddon(),
  │                    blackout)
  │
  ├─ B-7. 거래 실행
  │     switch(sig)
  │       ├── SIGNAL_ENTRY:
  │       │     g_executor.ExecuteEntry(RiskPercent)
  │       │     g_logger.LogEntry(probEntry, probAddon, atr, sl, lot, features)
  │       │
  │       ├── SIGNAL_ADDON:
  │       │     g_executor.ExecuteAddon(RiskPercent)
  │       │     g_logger.LogAddon(addonNum, probAddon, lot, unrealATR, features)
  │       │
  │       └── SIGNAL_NONE:
  │             // 주요 스킵만 로깅 (매 봉 로깅은 과다 → 선택적)
  │
  ├─ B-8. 성과 계산 (1분 간격)
  │     CalcPerformance()  // MDD 업데이트 포함
  │
  ├─ B-9. Dashboard 업데이트
  │     g_dashboard.SetPosition(...)
  │     g_dashboard.SetAI(probEntry, probAddon, ...)
  │     g_dashboard.SetPerformance(...)
  │     g_dashboard.SetConfig(...)
  │     g_dashboard.Render()
  │
  └── return
```

---

## 6. OnDeinit() 흐름

```
OnDeinit(const int reason)
  │
  ├── g_logger.Deinit()        // 파일 플러시 + 닫기
  ├── g_dashboard.Deinit()     // Comment("") 지우기
  ├── g_features.Deinit()      // 지표 핸들 해제
  ├── g_entryModel.Deinit()    // ONNX 세션 해제
  ├── g_addonModel.Deinit()    // ONNX 세션 해제
  ├── g_eventFilter.Deinit()
  ├── g_executor.Deinit()
  │
  ├── MN 잠금 해제
  │   lockKey = "AI_LOCK_" + IntegerToString(MagicNumber)
  │   GlobalVariableDel(lockKey)
  │
  └── Print("BSP_Long_v1 [MN:", MagicNumber, "] deinitialized. Reason:", reason)
```

---

## 7. MagicNumber 전파 경로

```
input MagicNumber (ExternVariables)
  │
  ├── g_trade.SetExpertMagicNumber(MagicNumber)
  ├── g_features.Init(MagicNumber, ...)
  ├── g_executor.Init(MagicNumber, ...)    → GlobalVariable 키에 사용
  ├── g_logger.Init(MagicNumber, ...)      → 파일명 + CSV 컬럼
  ├── g_dashboard.Init(MagicNumber, ...)   → 패널 헤더
  └── MN 잠금: GlobalVariable("AI_LOCK_{MN}")
```

---

## 8. Strategy Tester 호환성

| 항목 | 라이브 | Strategy Tester |
|:---|:---|:---|
| Python 하트비트 | 체크 | 스킵 (MQL_TESTER 감지) |
| macro CSV | `Files/live/` | `Files/live/` (동일) |
| 로그 파일 | `FILE_COMMON` | 로컬 `Files/` |
| MN 잠금 | GlobalVariable 사용 | GlobalVariable 사용 가능 |
| CE2 지표 | 래칫 + Virtual | 래칫 + Virtual |

---

## 9. 에러 처리 요약

```
[치명적 — INIT_FAILED 반환]
  - CFeatureEngine 핸들 생성 실패 (iCustom 오류)
  - ONNX 모델 로드 실패
  - MagicNumber 중복 감지

[비치명적 — 경고 후 계속]
  - MacroLoader CSV 미존재 → 매크로 피처 NaN → 자연 스킵
  - EventFilter CSV 미존재 → 필터 비활성화
  - Logger 파일 열기 실패 → 로깅 없이 거래 계속
```

---

## 10. 의존성 전체 맵

```
BSP_Long_v1.mq5
  ├── FeatureSchema.mqh
  ├── CRollingStats.mqh
  ├── CMacroLoader.mqh
  ├── CFeatureEngine.mqh    ← CRollingStats, CMacroLoader, FeatureSchema
  ├── COnnxPredictor.mqh
  ├── CEventFilter.mqh
  ├── CSignalGenerator.mqh
  ├── CTradeExecutor.mqh    ← CTrade, TrailingStopVx
  ├── CTradeLogger.mqh      ← FeatureSchema
  └── CDashboard.mqh
```
