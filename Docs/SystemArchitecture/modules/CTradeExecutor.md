# CTradeExecutor — 클래스 설계서

> 모듈 ID: 2-3 | Phase 2 | 의존성: CTrade, CPositionInfo, CSymbolInfo (MQL5 표준)

---

## 1. 단일 책임

**거래 실행 + Virtual Stop + 피라미딩 + 상태 복원**.
- 1차 진입(Entry) 및 피라미딩(AddOn) 주문 실행
- **Virtual Stop 체계**: 브로커 SL(ATR×12 비상용) + 내부 SL(ATR×7) + CE2 트레일링
- **피라미딩 랏 공식**: Worst-case 1% 리스크 보장 (정피라미드 1.0→0.50→0.25→0.125)
- **EA 재시작 복구**: GlobalVariable 기반 상태 백업/복원 + CE2 즉시 판단

---

## 2. 클래스 다이어그램

```
┌───────────────────── CTradeExecutor ──────────────────────┐
│                                                            │
│ [구조체]                                                    │
│   PositionEntry { ticket, openPrice, lots, type,           │
│                   openBar, openTime }                      │
│                                                            │
│ [상수]                                                      │
│   EXEC_MAX_POSITIONS = 10                                  │
│                                                            │
│ [멤버 변수 — 설정]                                           │
│   ulong  m_magic           // EA 매직넘버 (100001)          │
│   double m_riskPercent     // 리스크 비율 (0.01 = 1%)       │
│   double m_slATRMult       // Virtual SL 배수 (7.0)         │
│   double m_emergencySLMult // 비상 SL 배수 (12.0)           │
│   int    m_maxAddon        // 최대 피라미딩 (3)             │
│   double m_lotRatio        // 감소비 (0.50)                 │
│   double m_spacingATR      // SL 간격 (1.5 ATR)            │
│                                                            │
│ [멤버 변수 — 포지션 추적]                                     │
│   PositionEntry m_positions[]   // 관리 중인 포지션 배열     │
│   int    m_posCount, m_addonCount                          │
│   double m_firstEntryPrice, m_firstEntryATR                │
│   double m_firstEntryBSPScale                              │
│   int    m_firstEntryBar, m_lastEntryBar                   │
│                                                            │
│ [멤버 변수 — Virtual Stop]                                   │
│   double m_virtualSL       // 가상 손절가 (ATR×7)           │
│   double m_virtualCE2      // CE2 래칫 가격                 │
│   bool   m_ce2Active       // CE2 활성화 여부               │
│   bool   m_hasPosition                                     │
│                                                            │
│ [공개 메서드]                                                │
│   bool   Init(magic, risk, slMult, emergSL, ...)           │
│   virtual bool   ExecuteEntry(atr, price)                  │
│   virtual bool   ExecuteAddon(atr, price)                  │
│   virtual bool   CheckVirtualStops(currentPrice) // 매 틱  │
│   virtual void   UpdateCE2(ce2Value, unrealATR, minTPATR)  │
│   bool   CloseAll(reason)                                  │
│   void   Reset()                                           │
│   virtual bool   RestoreAndRecover(ceHandle)  // 재시작    │
│                                                            │
│ [접근자]                                                     │
│   HasPosition, GetAddonCount, GetEntryPrice, GetFirstATR   │
│   GetVirtualSL, GetVirtualCE2, IsCE2Active                 │
│   virtual GetUnrealizedATR, GetBarsSinceEntry/LastEntry    │
│                                                            │
│ [내부 메서드]                                                │
│   CalcLotSize(slPoints)          // 레거시 단일 랏          │
│   CalcPyramidBaseLot(atr)        // ★ Worst-case 공식     │
│   NormalizeLots(lots)            // 브로커 step 정규화      │
│   RecordPosition(ticket, ...)    // 내부 추적 등록          │
│   virtual SendOrder(lots, sl, comment)  // Buy             │
│   SaveState() / ClearState()     // GlobalVariable 영속    │
│   GVKey(suffix)                  // 키 이름 빌더           │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 3. 입출력 인터페이스

### 3.1 Virtual Stop 3계층 방어

```
┌─────────────────────────────────────────────────────┐
│ 계층 │ 수단                    │ 위치   │ 실행     │
│──────┼─────────────────────────┼────────┼──────────│
│ 1차  │ Virtual SL (ATR×7)      │ EA 내부│ 매 틱    │
│ 2차  │ CE2 Trailing (ATR×4.5)  │ EA 내부│ M1 봉   │
│ 3차  │ Emergency SL (ATR×12)   │ 브로커 │ 서버     │
│ 최후 │ 마진콜                   │ 브로커 │ 서버     │
└─────────────────────────────────────────────────────┘

Virtual Stop → 가격 헌팅 방지 (브로커에 실제 SL 노출 최소화)
Emergency SL → EA 장애/통신 장애 시 최후 방어선
```

### 3.2 ExecuteEntry — 1차 진입

```
ExecuteEntry(atr, price)
  ├── 포지션 존재 확인 → 거부
  ├── virtualSL    = ask - ATR × 7.0
  ├── emergencySL  = ask - ATR × 12.0
  ├── lots = CalcPyramidBaseLot(atr)  // Worst-case 1% 공식
  ├── SendOrder(lots, emergencySL, "AI_Entry")
  ├── 내부 상태 설정 (virtualSL, entryPrice, entryATR, ...)
  └── SaveState()  ← GlobalVariable 백업
```

### 3.3 CalcPyramidBaseLot — Worst-case 1% 리스크 공식

```
worst_case = SL×1.0 + (SL+1.5×1)×0.50 + (SL+1.5×2)×0.25 + (SL+1.5×3)×0.125
           = 7.0 + 8.5×0.50 + 10.0×0.25 + 11.5×0.125
           = 7.0 + 4.25 + 2.50 + 1.4375
           = 15.1875

base_lot = (Balance × 1%) / (worst_case × ATR × contract_size)

→ 모든 포지션(1차+3회 추가)이 동시에 SL 히트해도 총 손실 = 정확히 1%
```

### 3.4 ExecuteAddon — 피라미딩

```
ExecuteAddon(atr, price)
  ├── 포지션 미존재 → 거부
  ├── addonCount ≥ 3 → 거부
  ├── addonLots = CalcPyramidBaseLot(1차ATR) × lotRatio^(addonCount+1)
  │   → 1차: ×1.0, Addon1: ×0.50, Addon2: ×0.25, Addon3: ×0.125
  ├── SL = 1차 진입의 Emergency SL 유지
  ├── SendOrder(addonLots, emergencySL, "AI_Addon{n}")
  └── SaveState()
```

### 3.5 CheckVirtualStops — 매 틱 실행

```
CheckVirtualStops(bid)
  ├── bid ≤ m_virtualSL → CloseAll("Virtual SL hit")
  ├── m_ce2Active AND bid ≤ m_virtualCE2 → CloseAll("CE2 trailing hit")
  └── 둘 다 아님 → return false (계속 보유)
```

### 3.6 UpdateCE2 — CE2 래칫 메커니즘

```
UpdateCE2(ce2Value, unrealizedATR, minTPATR=4.0)
  ├── unrealizedATR < 4.0 → CE2 리셋 (다음 파동 대기)
  ├── 첫 활성화: m_virtualCE2 = ce2Value
  └── 래칫: ce2Value > m_virtualCE2 → 갱신 (올라가기만 함)
```

### 3.7 RestoreAndRecover — EA 재시작 복구

```
RestoreAndRecover(ceHandle)
  ├── PositionScan: Magic+Symbol 포지션 존재?
  │   └── 없음 → Clean start, ClearState()
  │
  ├── 존재 → GlobalVariable에서 복원 (EntryATR, VirtualSL, AddonCount, ...)
  │
  ├── CASE 1: bid ≤ virtualSL   → CloseAll("Recovery: below SL")
  ├── CASE 2: bid ≤ ce2         → CloseAll("Recovery: below CE2")
  └── CASE 3: bid > ce2         → m_virtualCE2=ce2, 정상 보유 계속
  
  ★ 이 전체 과정은 웜업 완료를 기다리지 않음
    (CE2는 가격 OHLC 기반 → MT5 히스토리에서 즉시 계산)
```

---

## 4. 에러 처리

| 시나리오 | 대응 |
|:---|:---|
| ATR ≤ 0 | Entry/Addon 거부 + Print |
| OrderSend 실패 | 1회 재시도 (500ms 대기) → 재실패 시 false + 로그 |
| `TRADE_RETCODE_NO_MONEY` | 치명적 에러 → 알림 |
| GV 상태 부재 + 포지션 존재 | CRITICAL 경고 → Emergency SL에만 의존 |
| CloseAll 부분 실패 | 실패 포지션 로그 + 재시도 불가 시 `allClosed=false` |
| 포지션 추적 배열 풀 | Print CRITICAL (EXEC_MAX_POSITIONS=10 → 충분) |

---

## 5. 성능 고려사항

| 항목 | 설계 |
|:---|:---|
| **CheckVirtualStops** | O(1) — 매 틱 호출, 단순 비교 2회 |
| **UpdateCE2** | O(1) — M1 봉당 1회, 단순 비교 |
| **CalcPyramidBaseLot** | O(maxAddon) = O(3), 1회 실행 |
| **SendOrder** | 네트워크 I/O 포함 (~100ms). 진입 시에만 실행 |
| **GlobalVariable** | Set/Get/Del ≈ O(1). 진입/청산 시에만 실행 |

---

## 6. 의존성

```
CTradeExecutor
  ├── Trade/Trade.mqh          (CTrade — 주문 실행)
  ├── Trade/PositionInfo.mqh   (CPositionInfo — 포지션 조회)
  └── Trade/SymbolInfo.mqh     (CSymbolInfo — 시세 조회)

호출 관계:
  BSP_Long_v1.mq5
    ├── Init(magic, risk, ...)
    ├── RestoreAndRecover(ceHandle)     ← OnInit
    ├── CheckVirtualStops(bid)          ← OnTick 매 틱
    ├── UpdateCE2(ce2, unrealATR)       ← OnTick M1 봉
    ├── ExecuteEntry(atr, price)        ← SIGNAL_ENTRY 시
    ├── ExecuteAddon(atr, price)        ← SIGNAL_ADDON 시
    └── CloseAll(reason)

입력 제공:
  ├── CFeatureEngine → ATR14, CE2Value
  ├── CSignalGenerator → ENUM_SIGNAL
  └── CTradeLogger → LogEntry/Addon/Close/Recovery
```

### 확장 설계 (숏전략용)

```
CTradeExecutor (virtual 메서드)
  └── CShortTradeExecutor 상속
      ├── override SendOrder → Sell
      ├── override CheckVirtualStops → Ask 기준
      ├── override GetUnrealizedATR → (entryPrice - ask) / ATR
      └── override RestoreAndRecover → 숏 방향 CE2 판단
```
