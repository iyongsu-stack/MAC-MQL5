# 🏗️ System Architecture — XAUUSD AI Quant Trading

> 최종 업데이트: 2026-03-13
> 상태: 설계 확정 (Phase 3 진행 중)

---

## 1. 시스템 아키텍처 결정 요약

### 1.1 배포 전략: 2-Phase 접근

| Phase | 기간 | 목표 |
|:---:|:---:|:---|
| **Phase 1** | ~3주 | ONNX Self-contained EA 제작 + Strategy Tester 백테스트 |
| **Phase 2** | ~1주 | Windows Server 배포 + Demo 계좌 실시간 강건성 검증 |

### 1.2 핵심 기술 결정

| 결정 항목 | 선택 | 근거 |
|:---|:---|:---|
| **모델 배포** | MQL5 ONNX Runtime | Strategy Tester 호환, EA 독립 작동, 산업 표준 |
| **Python↔MT5 통신** | 파일 공유 (CSV) | 실시간 통신 불필요 (매크로=일봉 단위), 가장 안정적 |
| **매크로 피처** | Python 매일 CSV 생성 → EA가 읽기 | MQL5 외부 API 호출 불필요, Shift+1 준수 |
| **멀티 모델** | 동일 MT5 내 별도 차트+매직넘버 | 4개 EA 동시 운용 가능, 리소스 충돌 없음 |

### 1.3 서버 사양 (4개 모델 동시 운용 기준)

| 항목 | 권장 | 비고 |
|:---|:---|:---|
| CPU | 4+ vCPU | 트리 모델 추론 < 0.1ms, 부담 극소 |
| RAM | 16 GB | MT5(4G) + 피처버퍼(1G) + Python(2G) + OS(4G) + 여유 |
| SSD | 100 GB | 히스토리 + 로그 + 모델 |
| OS | Windows Server 2022 | |
| 네트워크 | 안정적 VPS | 초단타 아닌 주 3~4회 진입 → 안정성 > 레이턴시 |

### 1.4 서버 전체 구성도

```
┌──────────────── Windows Server 2022 ─────────────────┐
│                                                       │
│  ┌─── MT5 Terminal ──────────────┐                   │
│  │                                │                   │
│  │  Chart 1: BSP_Long_v1.mq5     │                   │
│  │  Chart 2: BSP_Short_v1.mq5    │ (추후)            │
│  │  Chart 3: BSP_Reversal_v1.mq5 │ (추후)            │
│  │                                │                   │
│  │  각 EA: ONNX 자체 추론         │                   │
│  │  각 EA: 독립 매직넘버          │                   │
│  └────────────────────────────────┘                   │
│              ▲ CSV 읽기                               │
│              │                                        │
│  ┌─── Python Companion Service ──┐                   │
│  │  📊 매크로 Fetcher (일 1회)    │                   │
│  │  🔍 PSI 드리프트 모니터        │                   │
│  │  🔔 텔레그램/이메일 알림       │                   │
│  │  📝 성과 Tracker              │                   │
│  └────────────────────────────────┘                   │
│                                                       │
│  ┌─── Task Scheduler ───────────┐                    │
│  │  매일: 매크로 수집 + CSV 생성  │                    │
│  │  매주: PSI 드리프트 체크       │                    │
│  │  매일: PnL 리포트 발송         │                    │
│  └───────────────────────────────┘                    │
└───────────────────────────────────────────────────────┘
```

### 1.5 검증 체계

```
Python 시뮬 (승률 77.9%, +6,688)
     ↕ 피처값 수치 정합성 검증 (MQL5 vs Python, 오차 < 1e-6)
Phase 1: ONNX EA Strategy Tester 백테스트
     ↕ PnL 교차 검증 (오차 < 5%)
Phase 2: Demo 계좌 실시간 운용 (3개월+)
     ↕ 실전 강건성 확인
실전 투입
```

---

## 2. 소프트웨어 아키텍처

### 2.1 모듈 구조 (Module Map)

```
BSP_Long_v1.mq5  (Main EA — OnInit/OnTick/OnDeinit)
│
├── Include/BSPVx/
│   ├── ExternVariables.mqh     — 모든 외부 설정 변수
│   ├── CommonVx.mqh            — 시간 관리, 바 생성 감지
│   ├── MoneyManageVx.mqh       — 랏 계산 (1% 리스크)
│   └── TrailingStopVx.mqh      — CE2 트레일링 스탑
│
├── Include/AIEngine/                   [신규 모듈 그룹]
│   ├── CRollingStats.mqh       — 링버퍼 기반 롤링 통계 유틸리티
│   │                             (Z-score, pct_rank, slope, accel)
│   ├── CMacroLoader.mqh        — 매크로 CSV 파싱/캐싱
│   ├── CFeatureEngine.mqh      — 피처 엔지니어링 통합 엔진
│   │                             (기술+매크로+레짐 → 피처 벡터)
│   ├── COnnxPredictor.mqh      — ONNX 모델 로드/추론 래퍼
│   ├── CEventFilter.mqh        — 경제 이벤트 블랙아웃 필터
│   │                             (FOMC, NFP, CPI 등 고영향 이벤트
│   │                              발표 전후 N시간 신규 진입 차단)
│   ├── CSignalGenerator.mqh    — 신호 판단 (Entry/AddOn/None)
│   ├── CTradeExecutor.mqh      — 거래 실행 (진입+피라미딩)
│   ├── CTradeLogger.mqh        — 거래 결정 로깅
│   ├── CDashboard.mqh          — 차트 대시보드 패널
│   │                             (시스템 상태, 포지션, AI, 성과 표시)
│   └── FeatureSchema.mqh       — 피처 이름↔인덱스 매핑 상수
│
├── Files/models/
│   ├── model_long_ABC.onnx     — Entry 모델
│   └── model_addon_ABC.onnx    — 피라미딩 AddOn 모델
│
└── Files/live/
    ├── macro_latest.csv        — Python이 매일 갱신
    └── heartbeat.txt           — Python 하트비트 (매분 타임스탬프 기록)


Python Companion Service  (Windows Task Scheduler로 실행)
│
├── Services/
│   ├── macro_fetcher.py        — Yahoo Finance(41개) + FRED(19개) 수집
│   │                             → 파생 변환(Δ%, Z-score, pct_rank)
│   │                             → Files/live/macro_latest.csv 갱신
│   ├── drift_monitor.py        — PSI 드리프트 감시 (주 1회)
│   │                             → PSI > 0.25 시 재학습 알림
│   ├── alert_service.py        — 텔레그램/이메일 알림
│   │                             (거래 발생, 일일 PnL, 서버 헬스)
│   └── performance_tracker.py  — trade_log.csv 누적 통계
│                                  에쿼티 커브, 승률, PF 추적
│
├── Config/
│   └── service_config.yaml     — API 키, 알림 설정, 스케줄
│
└── Logs/
    └── service.log             — Python 서비스 실행 로그
```

### 2.2 모듈별 책임

**MQL5 EA 모듈**:

| 모듈 | 단일 책임 | 핵심 인터페이스 |
|:---|:---|:---|
| **CRollingStats** | 링버퍼 기반 롤링 계산 | `Push(value)`, `GetZScore()`, `GetPctRank()`, `GetSlope()` |
| **CMacroLoader** | CSV에서 매크로 피처 로드 | `LoadForDate(date)`, `GetFeature(name)` |
| **CFeatureEngine** | 모든 피처를 수집·변환·벡터화 | `Update()`, `GetFeatureVector(float &out[])` |
| **COnnxPredictor** | ONNX 모델 추론 | `Init(path)`, `Predict(features[]) → prob` |
| **CSignalGenerator** | 진입 조건 판단 (prob 임계치 + 피라미딩 조건) | `Evaluate() → SIGNAL_ENTRY/ADDON/NONE` |
| **CTradeExecutor** | 주문 실행 (BSP 연동) | `ExecuteEntry()`, `ExecuteAddon()` |
| **CEventFilter** | 경제 이벤트 블랙아웃 (FOMC/NFP/CPI 등) | `IsBlackout() → bool`, `GetNextEvent() → name,time` |
| **CTradeLogger** | 의사결정 근거 기록 | `LogDecision(signal, prob, features)` |
| **CDashboard** | 차트 대시보드 패널 (상태+포지션+AI+성과) | `Update()`, `OnChartEvent()` |
| **FeatureSchema** | 피처 순서 상수 정의 | `FEAT_IDX_NLR_ZSCORE60 = 0`, ... |

**Python Companion 모듈**:

| 모듈 | 단일 책임 | 실행 주기 |
|:---|:---|:---|
| **macro_fetcher** | 매크로 데이터 수집 + 파생 변환 + CSV 저장 | 매일 1회 (장 시작 전) |
| **drift_monitor** | PSI 기반 피처 분포 드리프트 감시 | 매주 1회 |
| **alert_service** | 거래 알림, PnL 리포트, 헬스 체크 | 이벤트 기반 + 매일 |
| **performance_tracker** | 누적 성과 통계 (에쿼티, 승률, PF) | 매일 1회 |

### 2.3 OnTick 실행 흐름

> ⚠️ **포지션 보호 로직(Virtual Stop + CE2)**은 웜업 상태와 무관하게 항상 즉시 실행됩니다.

```
OnTick()
  │
  ├─── [항상 실행 — 웜업 무관] ────────────────────
  │
  ├─ A. Virtual Stop 체크 (매 틱, 최우선)
  │     ├─ Bid ≤ m_virtualSL?  → CloseAll() (손절)
  │     ├─ Bid ≤ m_virtualCE2? → CloseAll() (트레일링 청산)
  │     └─ 브로커 SL(비상)    → 수정 안 함 (헌팅 방지)
  │
  ├─ B. CE2 래칫 갱신 (매 M1 봉)
  │     ├─ CE2 지표값 = CopyBuffer(hCE, 0, 1, 1) ← 웜업 불필요
  │     ├─ 수익 < 4×ATR → CE 리셋 (파동 대기)
  │     └─ 수익 ≥ 4×ATR → m_virtualCE2 래칫 업 (브로커 미전송)
  │
  ├─── [웜업 완료 후에만 실행] ────────────────────
  │
  ├─ 1. CommonVx: 새 M1 봉 생성 확인
  │     No → return (틱 무시)
  │     Yes ↓
  │
  ├─ 2. CFeatureEngine.Update()
  │     ├─ iCustom 지표값 → CRollingStats Push
  │     ├─ 파생 변환 (Z-score, pct_rank, slope)
  │     ├─ CMacroLoader: 오늘 매크로 로드 (일 1회)
  │     └─ float features[80] 조립 (FeatureSchema 순서)
  │
  ├─ 3. COnnxPredictor.Predict(features)
  │     ├─ prob_long  = Entry 모델 추론
  │     └─ prob_addon = AddOn 모델 추론
  │
  ├─ 4. CEventFilter.IsBlackout()
  │     ├─ 향후 N시간 내 고영향 이벤트(FOMC/NFP/CPI)? → 🚫 스킵
  │     └─ 블랙아웃 아님 → 계속 ↓
  │
  ├─ 5. CSignalGenerator.Evaluate(prob_long, prob_addon)
  │     ├─ 포지션 없음 + prob_long ≥ 0.20 → ENTRY
  │     ├─ 포지션 있음 + prob_addon ≥ 0.40
  │     │   + 미실현수익 ≥ 1.5×ATR + 5봉 간격 + 3회 미만 → ADDON
  │     └─ 그 외 → NONE
  │
  ├─ 6. CTradeExecutor (신호가 있을 때)
  │     ├─ ENTRY: 랏 계산 → OrderSend(sl=ATR×12 비상SL)
  │     │   m_virtualSL = ATR×7 (내부 보관)
  │     │   GlobalVariable에 상태 백업
  │     └─ ADDON: 감소 피라미드 랏 → OrderSend → GV 업데이트
  │
  └─ 7. CTradeLogger: 결정 기록 (prob, 피처값, 신호, 사유)
```

### 2.4 CRollingStats — 링버퍼 설계

> 롤링 Z-score(60/240), pct_rank(240), slope 계산을 위한 공용 유틸리티

```
CRollingStats (capacity = 240)
  ├─ 내부 링버퍼: double buffer[240]
  ├─ Push(double value)     — 새 값 추가 (oldest 덮어쓰기)
  ├─ GetMean(int window)    — 최근 N개 평균
  ├─ GetStd(int window)     — 최근 N개 표준편차
  ├─ GetZScore(int window)  — (latest - mean) / std
  ├─ GetPctRank(int window) — 최근 N개 중 순위 백분율
  ├─ GetSlope(int window)   — 최근 N개 선형회귀 기울기
  └─ GetAccel(int window)   — Slope의 변화율
```

- 각 기술적 피처마다 CRollingStats 인스턴스 1개 보유
- 예: `NLR_Value` → `CRollingStats m_nlr` → `m_nlr.GetZScore(60)`, `m_nlr.GetPctRank(240)`

### 2.5 FeatureSchema — 피처 순서 관리 (CRITICAL)

> ONNX 모델은 학습 시 피처 순서에 엄격하게 의존. 순서 불일치 = 쓰레기 확률값.

```
// FeatureSchema.mqh — Python 학습 코드에서 자동 생성
#define FEATURE_COUNT        80
#define FEAT_NLR_ZSCORE60     0
#define FEAT_NLR_ZSCORE240    1
#define FEAT_NLR_PCT240       2
#define FEAT_NLR_SLOPE        3
// ... (80개 전부 정의)

// 피처 이름 배열 (디버깅용)
const string FeatureNames[FEATURE_COUNT] = {
   "NLR_zscore60", "NLR_zscore240", "NLR_pct240", "NLR_slope", ...
};
```

**자동 생성 스크립트** (`export_feature_schema.py`):
- 학습 코드에서 `model.feature_name_` 추출
- → `FeatureSchema.mqh` 헤더 파일 자동 생성
- 모델 재학습 시마다 실행하여 동기화 보장

### 2.6 히스토리 프리로드 + Warm-up 폴백

> **1차: OnInit에서 과거 데이터 즉시 로드 → Warm-up 불필요**
> **2차: 로드 실패 시 → Warm-up 모드 진입 (폴백)**

```
OnInit()
  │
  ├─ CopyClose/CopyBuffer로 과거 240봉 로드 시도
  │
  ├─ 성공 ✅ → 링버퍼 즉시 채움 → 첫 봉부터 거래 가능
  │             패널: EA 🟢 Active
  │
  └─ 실패 ❌ → Warm-up 모드 진입
               패널: EA 🟡 Warm-up (192/240봉)
               매 봉마다 링버퍼 축적
               240봉 채워지면 → 🟢 Active 전환
```

| 파생 변환 | 필요 봉수 | 중요도 | 미충족 시 |
|:---|:---:|:---:|:---|
| Z-score(240) | 240 | 🔴 CRITICAL | 스케일 왜곡 → 확률값 무효 |
| pct_rank(240) | 240 | 🔴 CRITICAL | 순위 왜곡 → 확률값 무효 |
| Regime(240) | 240 | 🔴 CRITICAL | 롤링 윈도우 기반, 미충족 시 무효 |
| Z-score(60) | 60 | 🟡 WARNING | 단기 스케일 부정확, 60봉 후 정상화 |
| MA Ratio(60~240) | 60~240 | 🟡 WARNING | MA 구간에 따라 다름 |
| Slope(20) | 20 | 🟢 OPTIONAL | 20봉이면 충족, 빠름 |
| Acceleration(40) | 40 | 🟢 OPTIONAL | Slope의 Slope, 빠름 |
| 매크로 피처 | 0 | ✅ READY | CSV에서 즉시 로드 |

**거래 차단 규칙**:
```
🔴 CRITICAL 하나라도 미충족 → 거래 차단 (MUST)
🟡 WARNING만 미충족         → 거래 허용, 패널에 경고 표시
🟢 OPTIONAL 미충족           → 무시 가능
✅ READY                     → CSV/API에서 즉시 로드 완료
```

**Warm-up 상세 패널** (패널에서 [상세 ▶] 버튼 클릭 시 펼침):
```
┌── Warm-up 상세 ─────────────────┐
│                                  │
│  🔴 CRITICAL (거래 차단 조건)     │
│  Z-score(240)  ████████░░ 72%   │
│  pct_rank(240) ████████░░ 72%   │
│  Regime(240)   ████████░░ 72%   │
│                                  │
│  🟡 WARNING (경고만)             │
│  Z-score(60)   ██████████ 100% ✅│
│  MA_Ratio(60)  ██████████ 100% ✅│
│                                  │
│  🟢 OPTIONAL (무시 가능)         │
│  Slope(20)     ██████████ 100% ✅│
│  Accel(40)     ██████████ 100% ✅│
│                                  │
│  ✅ READY (즉시 사용)            │
│  매크로 피처    CSV 로드 완료 ✅   │
│                                  │
│  ⏳ 거래 가능까지: ~67봉 (67분)   │
└──────────────────────────────────┘
```

- **정상 시**: OnInit에서 과거 240봉 프리로드 → 전부 100% ✅ → 즉시 거래 가능
- **폴백 시**: CRITICAL 그룹이 100% 될 때까지 거래 차단, 진행률 실시간 표시
- Strategy Tester: 히스토리 데이터 항상 존재하므로 즉시 시작

### 2.7 에러 처리 및 안전장치

```
[에러 처리 계층]

Level 1 — ONNX 추론 실패
  → 재시도 1회 → 실패 시 해당 봉 스킵 + 로그
  → 🚫 신규 1차 진입 차단 (확률값 없이 진입 금지)
  → 🔔 사용자 알림 발송 (텔레그램/패널 경고 표시)
  → 기존 포지션은 Virtual Stop + CE2가 독립 관리 (안전)

Level 2 — 매크로 CSV 로드 실패
  → 전일 캐시값 유지 (ffill 원칙)
  → 🚫 신규 1차 진입 차단 (불완전한 피처로 진입 금지)
  → 3일 연속 실패 → 🔔 사용자 알림 발송

Level 3 — iCustom 지표 로드 실패
  → INIT_FAILED 반환 → EA 정지
  → 사전 점검: OnInit()에서 모든 지표 핸들 유효성 확인

Level 4 — 주문 실행 실패
  → GetLastError() 확인 → 재시도 로직
  → TRADE_RETCODE_NO_MONEY 등 치명 에러 → 알림

Level 5 — Virtual Stop 장애 (비상 보호)
  → EA 다운/서버 장애 시 → 브로커의 비상 SL(ATR×12)이 최후 방어선
  → 정상 복구 후 손실 원인 분석 + 로그 기록
```

### 2.8 EA 재시작 긴급복구 (Resilience & State Recovery)

> ⚠️ **포지션이 열린 채 EA가 크래시/재시작되는 경우의 안전 프로토콜**

#### A. CFeatureEngine 웜업 즉시 해결 (PreloadHistory)
```
CFeatureEngine::Init()
  ├── CreateHandles()              ← 22개 iCustom 핸들 생성
  └── PreloadHistory()             ← 과거 1440봉 CopyBuffer → CRollingStats Push 루프
      → EA 시작 즉시 IsReady()=true (대기 시간 0)
      → 실패 시 → Warm-up 폴백 모드 (점진적 축적)
```

#### B. CTradeExecutor 상태 복원 (GlobalVariable 기반)

**저장 대상 (진입/애드온 시 백업, 청산 시 삭제):**

| GlobalVariable Key | 값 | 성격 |
|:---|:---|:---:|
| `AI_<Magic>_<Symbol>_EntryATR` | 1차 진입 시 ATR | 고정 |
| `AI_<Magic>_<Symbol>_EntryPrice` | 1차 진입가 | 고정 |
| `AI_<Magic>_<Symbol>_VirtualSL` | 가상 손절가 | 고정 |
| `AI_<Magic>_<Symbol>_AddonCount` | 피라미딩 횟수 | 이산 |

> CE2 래칫 값은 저장하지 않음 → 재시작 시 현재 시점 기준으로 재판단 (아래 참조)

#### C. 재시작 시 즉시 판단 프로토콜 (웜업 대기 없이 실행)
```
OnInit() → CTradeExecutor::Init()
  │
  ├── PositionScan: 같은 Magic+Symbol 포지션 존재?
  │   └── 없음 → Reset(), 정상 시작
  │
  ├── 있음 → ★ 복구 모드
  │   ├── GlobalVariable에서 고정값 복원 (EntryATR, VirtualSL, AddonCount)
  │   ├── bid = SymbolInfoDouble(SYMBOL_BID)
  │   ├── ce2 = CopyBuffer(hCE, 0, 1, 1)  ← 웜업 불필요, 즉시 읽기 가능
  │   │
  │   ├── CASE 1: bid ≤ m_virtualSL
  │   │   └── CloseAll("Recovery: below Virtual SL") → 즉시 청산
  │   │
  │   ├── CASE 2: bid ≤ ce2 (가격이 CE2 아래 = 추세 이탈)
  │   │   └── CloseAll("Recovery: price below CE2") → 즉시 청산
  │   │
  │   └── CASE 3: bid > ce2 (가격이 CE2 위 = 상승추세 유지)
  │       ├── m_virtualCE2 = ce2 (현재 CE2를 새 래칫 기준)
  │       ├── m_ce2Active = true
  │       └── 정상 OnTick() 루프 재개 → 계속 보유
  │
  └── ★ 핵심: 이 전체 과정은 웜업 완료를 기다리지 않음
      (CE2 지표는 가격 OHLC 기반 → MT5 히스토리에서 즉시 계산됨)
```

**방어 계층 요약:**

| 계층 | 방어 수단 | 웜업 필요 |
|:---:|:---|:---:|
| 1차 | Virtual SL (고정, GlobalVar 복원) | ❌ |
| 2차 | CE2 추세 즉시 판단 (bid vs ce2) | ❌ |
| 3차 | Emergency SL (ATR×12, 브로커 서버) | ❌ |
| 최후 | 마진콜 | ❌ |

### 2.8 대시보드 패널 (CDashboard)

> 차트 좌측 상단에 EA 상태, 포지션, AI, 성과를 실시간 표시하는 패널

```
┌─────────── BSP Long v1.0 ──────────────┐
│ [시스템]                                    │
│  EA: 🟢  Python: 🟢  Broker: 🟢            │
│  매크로: ✅ 2시간 전 갱신                   │
│  이벤트: ✅ 정상 (NFP: 2일 후)              │
├──────────────────────────────────────────┤
│ [포지션]                                    │
│  🟢 LONG  $2,945.30  랏 0.15 (AddOn 1/3)  │
│  미실현: +$128.50 (+4.2 ATR)               │
│  SL: $2,912.80  CE2: $2,938.60            │
├──────────────────────────────────────────┤
│ [AI 모델]                                   │
│  Entry: prob=0.37   AddOn: prob=0.52     │
│  Warm-up: ████████░░ 192/240 (80%)        │
├──────────────────────────────────────────┤
│ [성과]                                      │
│  오늘: +$85.20  이번달: +$1,245.00       │
│  승률 76.3% (29/38)  PF 2.41  MDD -3.2%  │
├──────────────────────────────────────────┤
│ [설정]                                      │
│  리스크: 1.0% ($100.00)  피라미딩: 3회      │
│  이벤트필터: ON                               │
└──────────────────────────────────────────┘
```

**패널 표시 항목 상세**:

| 구분 | 항목 | 표시 내용 |
|:---|:---|:---|
| **시스템** | EA 상태 | 🟢 Active / 🔴 Stopped / 🟡 Warm-up |
| | Python 서비스 | 🟢 Alive / 🔴 Down (heartbeat.txt 기준, 5분 초과 시 Down) |
| | 매크로 데이터 | ✅ N시간 전 갱신 / ⚠️ N일 경과 |
| | 브로커 연결 | 🟢 Connected / 🔴 Disconnected |
| | 이벤트 블랙아웃 | 🚫 "이벤트명 N시간 후" / ✅ 정상 |
| **포지션** | 상태 | 🟢 LONG / ⬜ 대기 |
| | 진입가 / 랏 | $2,945.30 / 0.15 |
| | 피라미딩 | N/3회 완료 |
| | 미실현 손익 | +$128.50 (+4.2 × ATR) |
| | SL / CE2 | $2,912.80 / $2,938.60 |
| **AI** | Entry 확률 | prob=0.37 (임계치 0.20) |
| | AddOn 확률 | prob=0.52 (임계치 0.40) |
| | Warm-up | 진행률 바 + N/240봉 |
| **성과** | 오늘/주/월 PnL | +$85.20 / +$312.50 / +$1,245.00 |
| | 승률 / PF / MDD | 76.3% / 2.41 / -3.2% |
| **설정** | 리스크 % | 현재 설정값 + 실제 금액 환산 (1.0% = $100.00) |
| | 피라미딩 / 이벤트필터 | 현재 설정값 표시 |

**Python 하트비트 메커니즘**:
- Python 서비스가 매분 `Files/live/heartbeat.txt`에 타임스탬프 기록
- EA가 이 파일을 읽어서 5분 이상 갱신 없으맄 🔴 Down 표시
- 파일 기반이라 프로세스 간 결합 없음

**구현 전략**:
- Phase 1: `Comment()` 기반 읽기 전용 패널 (빠른 개발)
- Phase 2: `CAppDialog` 기반 GUI 패널로 업그레이드 (필요 시)

### 2.9 ExternVariables (사용자 설정 변수)

| 설정 | 타입 | 기본값 | 설명 |
|:---|:---|:---|:---|
| **MagicNumber** | int | 100001 | EA 식별용 매직넘버 (Long:10000x, Short:20000x, Reversal:30000x) |
| **RiskPercent** | double | 1.0 | 매 포지션 최대 리스크 (%) |
| **EntryThreshold** | double | 0.20 | 진입 확률 문턱값 |
| **AddonThreshold** | double | 0.40 | 피라미딩 확률 문턱값 |
| **MaxPyramiding** | int | 3 | 추가 진입 최대 횟수 |
| **UseEventFilter** | bool | false | 이벤트 블랙아웃 ON/OFF (시뮬 결과: OFF 우위, PnL -6% 감소 확인) |
| **EmergencySL_ATR_Mult** | double | 12.0 | 비상 SL = ATR14 × N (브로커 전송, 헌팅 방지) |
| **UseVirtualStop** | bool | true | Virtual Stop ON/OFF (OFF 시 브로커 SL 직접 전송) |

### 2.10 내부 상수 (시뮬레이션 확정값 — 코드 내부에서만 관리)

| 상수 | 값 | 모듈 |
|:---|:---|:---|
| SL_ATR_Mult | 7.0 | CTradeExecutor |
| CE2_Lookback | 22 | TrailingStopVx |
| CE2_Mult | 4.5 | TrailingStopVx |
| CE2_MinTP_ATR | 4.0 | TrailingStopVx |
| EventBlackoutBefore | 2h | CEventFilter |
| EventBlackoutAfter | 1h | CEventFilter |

### 2.11 설계 원칙

| # | 원칙 | 적용 |
|:---:|:---|:---|
| 1 | **단일 책임** | 모듈당 하나의 역할 (피처/추론/거래/로그 분리) |
| 2 | **느슨한 결합** | 모듈 간 float[] 또는 enum 신호로만 통신 |
| 3 | **설정 외부화** | 모든 파라미터 ExternVariables에 집중 |
| 4 | **로깅 완전성** | 모든 의사결정의 피처값+확률+근거 기록 |
| 5 | **Fail-Safe** | 추론 실패해도 기존 포지션은 TrailingStop이 보호 |
| 6 | **피처 순서 자동화** | Python→MQL5 헤더 자동 생성으로 불일치 방지 |
| 7 | **Resilience (복원력)** | EA 재시작 시 GlobalVariable 기반 상태 복원 + CE2 즉시 판단 + PreloadHistory |
