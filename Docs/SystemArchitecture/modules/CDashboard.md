# CDashboard — 클래스 설계서

> 모듈 ID: 3-1 | Phase 3 | 의존성: CFeatureEngine, COnnxPredictor, CTradeExecutor, CEventFilter

---

## 1. 단일 책임

차트 좌측 상단에 **EA 상태, 포지션, AI, 성과, 설정 정보를 실시간 표시**하는 패널.
MagicNumber를 헤더에 표시하여 멀티 인스턴스 운용 시 즉시 식별 가능.

---

## 2. 클래스 다이어그램

```
┌──────────────────── CDashboard ────────────────────────┐
│                                                         │
│ [멤버 변수]                                              │
│   int    m_magicNumber        // 표시용 매직넘버         │
│   string m_symbol             // 심볼명                  │
│                                                         │
│   // 섹션별 캐시 데이터 (외부에서 Set)                    │
│   string m_eaState            // "Active"/"Warm-up"/"Stopped"  │
│   string m_pythonState        // "Alive"/"Down"          │
│   string m_brokerState        // "Connected"/"Disconnected"    │
│   string m_macroState         // "✅ 2h전" / "⚠️ 3일"   │
│   string m_eventState         // "✅ 정상" / "🚫 NFP 2h후"   │
│                                                         │
│   // 포지션 섹션                                         │
│   bool   m_hasPosition        // 포지션 유무             │
│   double m_entryPrice         // 진입가                  │
│   double m_totalLot           // 총 랏                   │
│   int    m_addonCount         // 피라미딩 횟수           │
│   double m_unrealizedPnL      // 미실현 손익 ($)         │
│   double m_unrealizedATR      // 미실현 ATR 배수         │
│   double m_virtualSL          // 가상 SL                 │
│   double m_virtualCE2         // 가상 CE2                │
│                                                         │
│   // AI 섹션                                             │
│   double m_probEntry          // Entry 확률              │
│   double m_probAddon          // AddOn 확률              │
│   int    m_warmupCurrent      // 현재 채워진 봉 수       │
│   int    m_warmupTotal        // 필요 봉 수 (240)        │
│   bool   m_warmupReady        // 웜업 완료 여부          │
│                                                         │
│   // 성과 섹션                                           │
│   double m_pnlToday           // 오늘 PnL               │
│   double m_pnlMonth           // 이번달 PnL             │
│   int    m_totalTrades        // 총 거래 수              │
│   int    m_winTrades          // 승리 거래 수            │
│   double m_profitFactor       // PF                      │
│   double m_maxDD              // MDD %                   │
│                                                         │
│   // 설정 섹션                                           │
│   double m_riskPercent        // 리스크 %                │
│   double m_riskAmount         // 리스크 $ 환산           │
│   int    m_maxPyramiding      // 최대 피라미딩 횟수      │
│   bool   m_useEventFilter     // 이벤트 필터 ON/OFF      │
│                                                         │
│ [메서드]                                                 │
│                                                         │
│   // 초기화/종료                                         │
│   bool   Init(int magic, string symbol)                 │
│   void   Deinit()                                       │
│                                                         │
│   // 데이터 업데이트 (각 모듈이 호출)                     │
│   void   SetSystemState(string ea, string python,       │
│              string broker, string macro, string event)  │
│   void   SetPosition(bool has, double entry, double lot,│
│              int addon, double pnl, double atrMult,     │
│              double sl, double ce2)                      │
│   void   SetAI(double probE, double probA,              │
│              int warmCur, int warmTotal, bool ready)     │
│   void   SetPerformance(double today, double month,     │
│              int total, int wins, double pf, double mdd)│
│   void   SetConfig(double riskPct, double riskAmt,      │
│              int maxPyr, bool eventFilter)               │
│                                                         │
│   // 화면 갱신                                           │
│   void   Render()             // Comment() 호출          │
│                                                         │
│ [내부 메서드]                                            │
│   string BuildSystemSection()                           │
│   string BuildPositionSection()                         │
│   string BuildAISection()                               │
│   string BuildPerformanceSection()                      │
│   string BuildConfigSection()                           │
│   string BuildWarmupBar(int cur, int total)  // ████░░  │
│   string GetStateEmoji(string state)  // 🟢/🔴/🟡      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 패널 레이아웃

```
┌────────── BSP Long v1.0 [MN:100001] ──────────┐
│ [시스템]                                          │
│  EA: 🟢 Active  Python: 🟢  Broker: 🟢          │
│  매크로: ✅ 2시간 전 갱신                         │
│  이벤트: ✅ 정상 (NFP: 2일 후)                    │
├────────────────────────────────────────────────┤
│ [포지션]                                          │
│  🟢 LONG  $2,945.30  랏 0.15 (AddOn 1/3)        │
│  미실현: +$128.50 (+4.2 ATR)                     │
│  SL: $2,912.80  CE2: $2,938.60                  │
├────────────────────────────────────────────────┤
│ [AI 모델]                                         │
│  Entry: prob=0.37   AddOn: prob=0.52            │
│  Warm-up: ██████████ 240/240 ✅ Ready           │
├────────────────────────────────────────────────┤
│ [성과]                                            │
│  오늘: +$85.20  이번달: +$1,245.00              │
│  승률 76.3% (29/38)  PF 2.41  MDD -3.2%        │
├────────────────────────────────────────────────┤
│ [설정]                                            │
│  리스크: 1.0% ($100.00)  피라미딩: 3회            │
│  이벤트필터: ON                                    │
└────────────────────────────────────────────────┘
```

### 상태별 표시 변화

**포지션 없을 때:**
```
│ [포지션]                                          │
│  ⬜ 대기 중 — 진입 조건 미충족                    │
```

**Warm-up 진행 중:**
```
│ [AI 모델]                                         │
│  Entry: ---    AddOn: ---                        │
│  Warm-up: ████████░░ 192/240 (80%) ⏳ ~48분      │
```

**블랙아웃 기간:**
```
│  이벤트: 🚫 FOMC 1시간 30분 후 — 신규 진입 차단   │
```

---

## 4. 입출력 인터페이스

### 4.1 Init / Deinit

```
Init(int magic, string symbol)
  ├── m_magicNumber = magic
  ├── m_symbol = symbol
  └── return true (Comment 방식은 초기화 실패 없음)

Deinit()
  └── Comment("")  // 패널 지우기
```

### 4.2 Render 흐름

```
Render()  // 매 M1 봉마다 EA에서 호출
  │
  ├── header = "━━━ BSP Long v1.0 [MN:" + m_magicNumber + "] ━━━"
  ├── section1 = BuildSystemSection()
  ├── section2 = BuildPositionSection()
  ├── section3 = BuildAISection()
  ├── section4 = BuildPerformanceSection()
  ├── section5 = BuildConfigSection()
  │
  └── Comment(header + "\n" + section1 + "\n" + ... + section5)
```

### 4.3 데이터 흐름 (누가 어떤 Set 메서드를 호출하나)

```
BSP_Long_v1.mq5::OnTick()
  │
  ├── dashboard.SetSystemState(...)    ← CommonVx, heartbeat.txt, 연결 상태
  ├── dashboard.SetPosition(...)       ← CTradeExecutor 멤버에서 읽기
  ├── dashboard.SetAI(...)             ← COnnxPredictor.Predict() 결과 + CFeatureEngine.IsReady()
  ├── dashboard.SetPerformance(...)    ← HistoryDeal 기반 계산 (EA 내부)
  ├── dashboard.SetConfig(...)         ← ExternVariables 값
  │
  └── dashboard.Render()               ← 최종 Comment() 호출
```

---

## 5. 성과 계산 로직

> EA 내부에서 `HistoryDeal` API로 계산, CDashboard에 전달

```
CalcPerformance()    // BSP_Long_v1 내부 또는 별도 헬퍼
  │
  ├── HistorySelect(오늘 0시, 현재시간)
  │   └── 오늘 PnL = Σ closed deals profit (매직넘버 필터)
  │
  ├── HistorySelect(이달 1일, 현재시간)
  │   └── 이번달 PnL = Σ closed deals profit
  │
  ├── HistorySelect(전체 기간)
  │   ├── 총 거래수, 승리 거래수
  │   ├── 승률 = wins / total × 100
  │   ├── PF = gross_profit / |gross_loss|
  │   └── MDD = 이건 에쿼티 기반이라 실시간 트래킹 필요
  │       (AccountInfoDouble로 에쿼티 변화 누적 추적)
  │
  └── dashboard.SetPerformance(...)
```

**MDD 트래킹:**
```
// EA 멤버 변수로 관리
double m_peakEquity = 0;
double m_maxDrawdown = 0;  // % 단위

OnTick():
  equity = AccountInfoDouble(ACCOUNT_EQUITY)
  if(equity > m_peakEquity) m_peakEquity = equity
  dd = (m_peakEquity - equity) / m_peakEquity * 100
  if(dd > m_maxDrawdown) m_maxDrawdown = dd
```

---

## 6. Python 하트비트 체크

```
CheckPythonHeartbeat()
  │
  ├── FileOpen("heartbeat.txt", FILE_READ|FILE_TXT, ...)
  │   └── 실패 → "Down"
  ├── 마지막 줄 읽기 → 타임스탬프 파싱
  ├── (현재시간 - 타임스탬프) > 300초?
  │   ├── Yes → "Down" 🔴
  │   └── No  → "Alive" 🟢
  └── FileClose
```

---

## 7. 에러 처리

| 시나리오 | 대응 |
|:---|:---|
| `Comment()` 호출 실패 | MQL5에서 발생하지 않음 (항상 성공) |
| heartbeat.txt 미존재 | `Python: 🔴 Down (파일 없음)` 표시 |
| 성과 데이터 없음 (첫 거래 전) | `승률 ---% (0/0)` 표시 |
| Strategy Tester 모드 | Python 하트비트 체크 스킵 (서비스 미가동), 성과는 정상 표시 |

---

## 8. 성능 고려사항

| 항목 | 설계 |
|:---|:---|
| **갱신 빈도** | 매 M1 봉 (1분), OnTick마다 아님 → CPU 부담 최소 |
| **Comment() 사용** | GUI 오브젝트 대비 극히 가벼움, Strategy Tester 호환 |
| **하트비트 I/O** | 1분 1회 파일 읽기 → 무시할 수준 |
| **성과 계산** | HistorySelect는 매 봉마다가 아닌, 청산 이벤트 시 + 1분마다 1회 |
| **Phase 2 업그레이드** | 필요 시 `CAppDialog` 기반 GUI로 전환 (현재는 Comment() 우선) |

---

## 9. 의존성

```
CDashboard
  ├── 직접 의존 없음 (Set 메서드로 데이터를 받기만 함)
  └── BSP_Long_v1.mq5가 각 모듈에서 데이터를 수집하여 Set 호출
```

**느슨한 결합**: CDashboard는 다른 모듈을 직접 참조하지 않음. EA가 중간 다리.
