# 🛠️ Software Development Plan — XAUUSD AI Long Strategy EA

> 최종 업데이트: 2026-03-13
> 상태: Phase 3 진행 중 (설계서 작성 중)

---

## Phase 0: 사전 준비 (~1일)

### 0-1. LightGBM → ONNX 변환
- `model_long_ABC.txt` → `model_long_ABC.onnx`
- `model_addon_ABC.txt` → `model_addon_ABC.onnx`
- Python에서 변환 + 추론값 일치 검증

### 0-2. FeatureSchema 자동 생성
- `export_feature_schema.py` → `FeatureSchema.mqh`
- 80개 피처 순서, 이름, 인덱스 자동 매핑

---

## Phase 1: 기반 모듈 — 의존성 없는 것부터 (~3일)

| 순서 | 모듈 | 핵심 내용 |
|:---:|:---|:---|
| 1-1 | `CRollingStats.mqh` | 링버퍼, Z-score, pct_rank, slope, accel |
| 1-2 | `CMacroLoader.mqh` | CSV 파서, 날짜 매칭, ffill 캐시 |
| 1-3 | `COnnxPredictor.mqh` | ONNX 로드, 추론, 에러 처리 |
| 1-4 | `CEventFilter.mqh` | 이벤트 CSV 로드, 블랙아웃 체크 |

---

## Phase 2: 핵심 로직 모듈 (~4일)

| 순서 | 모듈 | 핵심 내용 |
|:---:|:---|:---|
| 2-1 | `CFeatureEngine.mqh` | ★ 가장 복잡 — 80개 피처 계산, 지표 핸들 매핑, CRollingStats 관리, float[] 출력 |
| 2-2 | `CSignalGenerator.mqh` | 진입/피라미딩 판정 로직 (threshold, 간격, 미실현수익 조건) |
| 2-3 | `CTradeExecutor.mqh` | Virtual Stop + OrderSend + 비상 SL 관리 |
| 2-4 | **긴급복구 (Resilience)** | PreloadHistory(웜업 즉시 해결) + GlobalVariable 상태 복원 + CE2 즉시 판단 프로토콜 |

---

## Phase 3: 보조 모듈 + EA 통합 (~3일)

| 순서 | 모듈 | 핵심 내용 |
|:---:|:---|:---|
| 3-1 | `CDashboard.mqh` | 패널 UI (상태, Warm-up 상세, 포지션, 성과, 설정) |
| 3-2 | `CTradeLogger.mqh` | CSV 로깅 (피처값, 확률, 신호, 사유) |
| 3-3 | `BSP_Long_v1.mq5` | 메인 EA — 모든 모듈 통합 + OnTick 흐름 |

---

## Phase 4: 검증 (~3일)

| 순서 | 검증 항목 | 내용 |
|:---:|:---|:---|
| 4-1 | 피처값 교차 검증 | MQL5 출력 CSV vs Python 출력 비교 (수치 정합성) |
| 4-2 | Strategy Tester | 백테스트 → Python 시뮬 결과와 비교 |
| 4-3 | 버그 수정 | 교차 검증에서 발견된 불일치 수정 |
| 4-4 | **긴급복구 테스트** | EA 강제 종료 후 재시작 → 포지션 복원/CE2 판단/청산 정상 작동 검증 |
| 4-5 | **Dummy Model 통합 테스트** | 가짜 신호로 피라미딩 랏감소/CE2 래칫/CloseAll 동작 검증 |

---

## 모듈별 개발 사이클 (반복)

```
① 클래스 설계서 작성 (Docs/SystemArchitecture/modules/)
   - 클래스 다이어그램 (멤버 변수, 메서드)
   - 입출력 인터페이스 정의
   - 에러 처리 시나리오
   - 의존성 명시
         ↓
② 사용자 검토 + 수정
         ↓
③ MQL5 코드 구현
         ↓
④ 단위 테스트 (컴파일 + 로그 출력 확인)
         ↓
⑤ 다음 모듈로 이동
```

---

## 클래스 설계서 예시 — CRollingStats

```
┌─────────────── CRollingStats ───────────────┐
│                                               │
│ [멤버 변수]                                    │
│   double m_buffer[]    // 링버퍼 (크기 N)      │
│   int    m_size        // 버퍼 크기             │
│   int    m_count       // 현재 데이터 수        │
│   int    m_index       // 현재 인덱스           │
│   double m_sum         // 증분 합계             │
│   double m_sumSq       // 증분 제곱합           │
│                                               │
│ [메서드]                                       │
│   void   Init(int size)                       │
│   void   Add(double value)                    │
│   double GetZScore()                          │
│   double GetPctRank()                         │
│   double GetSlope(int period)                 │
│   double GetAccel(int period)                 │
│   bool   IsReady()      // count >= size?     │
│   double GetFillRatio() // count/size (패널용) │
│                                               │
│ [Warm-up 중요도]                               │
│   CRITICAL / WARNING / OPTIONAL 분류 속성      │
└───────────────────────────────────────────────┘
```

---

## 총 예상 소요 시간

| 구분 | 기간 |
|:---|:---:|
| Phase 0: 사전 준비 | ~1일 |
| Phase 1: 기반 모듈 | ~3일 |
| Phase 2: 핵심 로직 | ~4일 |
| Phase 3: 통합 | ~3일 |
| Phase 4: 검증 | ~3일 |
| **총계** | **~2주** |

---

## 산출물 디렉토리 구조

```
Docs/SystemArchitecture/
├── SystemArchitecture.md          ← 시스템/소프트웨어 아키텍처 (확정)
├── SoftwareDevelopmentPlan.md     ← 이 문서
└── modules/                       ← 모듈별 클래스 설계서
    ├── CRollingStats.md
    ├── CMacroLoader.md
    ├── COnnxPredictor.md
    ├── CEventFilter.md
    ├── CFeatureEngine.md
    ├── CSignalGenerator.md
    ├── CTradeExecutor.md
    ├── CDashboard.md
    └── CTradeLogger.md
```

---

## ⚠️ 확인 필요사항 (TODO)

| # | 항목 | 적용 시점 | 관련 모듈 | 상태 |
|:---:|:---|:---:|:---|:---:|
| 1 | **매크로 발표 시간 Lag 방어**: `macro_fetcher.py` 작성 시 CSV에 `shift(1)` 강제 적용. 당일 발표 데이터가 발표 전에 로드되지 않도록 `as_of_date` 컨럼 추가 고려. MQL5 측은 Python 파이프라인 규칙으로 커버 (Phase 1 코드 수정 불필요) | `macro_fetcher.py` 작성 시 | `CMacroLoader` | ⬜ |
| 2 | **MAX 상수 상향 + Silent Failure 방지**: `MACRO_MAX_FEATURES` 700→1000, `MACRO_MAX_ROWS` 100→200 상향. 초과 시 `Print("CRITICAL: ...")` 로그 출력 + 실제 잘린 건수를 기록하여 조용히 무시되는 데이터 없도록 방어. `ParseCSV()` 루프 종료 후 `if(totalInFile > MAX) Print("CRITICAL: %d rows truncated", totalInFile - MAX)` 패턴 적용 | Phase 1 마무리 | `CMacroLoader`, `CEventFilter` | ✅ |
| 3 | **CLogger 중앙 로깅 시스템 도입**: 에러 수준 체계(DEBUG~FATAL) + Telegram 알림 + 연속 에러 카운터 | Phase 2 | 신규 `CLogger.mqh` + 전 모듈 | ⬜ |
| 4 | **CEventFilter 상태 머신 전환**: O(N) 루프 → 시간순 정렬 + `m_nextEventIdx` 포인터 방식(O(1))으로 리팩토링 | Phase 2 | `CEventFilter` | ⬜ |
| 5 | **COnnxPredictor NaN 방어 게이트 테스트**: ① EA 시작 직후 Warm-up 240봉 동안 NaN Reject 정상 동작 확인 (로그: `NaN/INF at feature[i]`) ② 의도적 NaN 주입 테스트 (features[] 중 1~2개를 `NaN`으로 설정 → `-1.0` 반환 확인) ③ 연속 500봉 NaN 시 `Alert()` 1회 발행 + `m_nanAlerted` 재발행 방지 확인 ④ NaN 해소 후 카운터 리셋 확인 (로그: `NaN resolved after N bars`). 참조: `PossibleErrorAndTest.md` | Phase 4 | `COnnxPredictor` | ⬜ |
| 6 | **긴급복구 테스트**: ① 포지션 진입 후 EA 강제 종료 → 재시작 → GlobalVariable 복원 정상 동작 확인 ② CE2 위/아래 판단 로직 검증 (bid>ce2 → 보유, bid≤ce2 → 청산) ③ 웜업 미완료 상태에서 Virtual Stop/CE2 체크 즉시 실행 확인 ④ 피라미딩 중간 재시작 → addonCount 복원 확인 | Phase 4 | `CTradeExecutor` | ⬜ |
| 7 | **Dummy Model 통합 테스트**: 가짜 신호(`CSignalDummy`)로 Strategy Tester 돌리며 피라미딩 랏감소/CE2 래칫/CloseAll 동작 검증. Phase 3 진입 전 반드시 통과 필요 | Phase 2 부가 | `CTradeExecutor`, `CSignalGenerator` | ⬜ |
| 6 | **만들어 지는 인디게이터 값의 동일성 확인**: iCustom 함수에서 만들어진 값과 학습값과의 동일성 확인 | Phase 4 | `CFeatureEngine` | ⬜ |


