# CTradeLogger — 클래스 설계서

> 모듈 ID: 3-2 | Phase 3 | 의존성: 없음 (독립 모듈)

---

## 1. 단일 책임

모든 **거래 의사결정 근거**를 CSV 파일로 기록한다.
- 진입(Entry), 피라미딩(AddOn), 청산(Close), 복구(Recovery) 이벤트 기록
- 피처값, 확률, 신호 사유를 포함하여 **사후 분석(Post-mortem)** 가능
- MagicNumber별 로그 파일 분리

---

## 2. 클래스 다이어그램

```
┌───────────────────── CTradeLogger ─────────────────────┐
│                                                         │
│ [멤버 변수]                                              │
│   int    m_fileHandle       // CSV 파일 핸들 (-1=미열림) │
│   int    m_magicNumber      // EA 매직넘버              │
│   string m_symbol           // 심볼명                    │
│   string m_filePath         // 파일 전체 경로            │
│   bool   m_headerWritten    // 헤더 작성 완료 플래그     │
│   int    m_flushCounter     // 플러시 카운터 (N건마다)   │
│                                                         │
│ [상수]                                                   │
│   FLUSH_INTERVAL = 10       // 10건마다 FileFlush       │
│   TOP_SHAP_COUNT = 5        // 기록할 주요 피처 수       │
│                                                         │
│ [메서드]                                                 │
│   bool   Init(int magic, string symbol)                 │
│   void   Deinit()                                       │
│                                                         │
│   void   LogEntry(double probEntry, double probAddon,   │
│              double atr, double sl, double lot,          │
│              const float &features[])                    │
│                                                         │
│   void   LogAddon(int addonNum, double probAddon,       │
│              double lot, double unrealizedATR,           │
│              const float &features[])                    │
│                                                         │
│   void   LogClose(string reason, double pnl,            │
│              double holdBars)                            │
│                                                         │
│   void   LogRecovery(string action, string details)     │
│                                                         │
│   void   LogSkip(string reason, double probEntry,       │
│              double probAddon)   // 선택적: 주요 스킵만  │
│                                                         │
│ [내부 메서드]                                            │
│   void   WriteHeader()          // CSV 헤더 1회 작성     │
│   void   WriteRow(string &cols[])  // 행 기록 + 플러시   │
│   string FormatTime(datetime t)    // 시간 포맷팅        │
│   string FormatFeatures(const float &f[], int topN)     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 입출력 인터페이스

### 3.1 Init / Deinit

```
Init(int magic, string symbol)
  ├── m_filePath = "trade_log_" + IntegerToString(magic) + ".csv"
  ├── FileOpen(m_filePath, FILE_CSV|FILE_WRITE|FILE_READ|FILE_SHARE_READ|FILE_COMMON)
  │   ├── 성공 → 파일 끝으로 FileSeek → return true
  │   └── 실패 → Print("CRITICAL: CTradeLogger FileOpen failed") → return false
  ├── 파일 크기 = 0 이면 → WriteHeader()  // 신규 파일
  └── 파일 크기 > 0 이면 → FileSeek(끝)   // 기존 파일 이어쓰기

Deinit()
  ├── FileFlush(m_fileHandle)
  └── FileClose(m_fileHandle)
```

### 3.2 CSV 컬럼 정의

```
Time,MagicNumber,Symbol,Event,Signal,ProbEntry,ProbAddon,ATR,SL,CE2,Lot,PnL,HoldBars,UnrealizedATR,AddonNum,Reason,Feat1_Name,Feat1_Val,Feat2_Name,Feat2_Val,Feat3_Name,Feat3_Val,Feat4_Name,Feat4_Val,Feat5_Name,Feat5_Val
```

| 컬럼 | 타입 | 설명 |
|:---|:---|:---|
| Time | string | `yyyy.MM.dd HH:mm` |
| MagicNumber | int | EA 매직넘버 |
| Symbol | string | `XAUUSD` |
| Event | string | `ENTRY` / `ADDON` / `CLOSE` / `RECOVERY` / `SKIP` |
| Signal | string | `BUY` / `NONE` |
| ProbEntry | double | Entry 모델 확률 (소수점 4자리) |
| ProbAddon | double | AddOn 모델 확률 |
| ATR | double | 현재 ATR14 값 |
| SL | double | 설정된 StopLoss 가격 |
| CE2 | double | 현재 CE2 래칫 가격 |
| Lot | double | 거래 랏 사이즈 |
| PnL | double | 청산 시 실현 손익 (포인트) |
| HoldBars | int | 보유 봉 수 (청산 시) |
| UnrealizedATR | double | 미실현수익 ATR 배수 (피라미딩 시) |
| AddonNum | int | 피라미딩 횟수 (1~3) |
| Reason | string | 의사결정 사유 (자유 텍스트) |
| Feat1~5_Name | string | SHAP Top 피처 이름 |
| Feat1~5_Val | double | 해당 피처값 |

### 3.3 이벤트별 기록 예시

**Entry 기록:**
```
2026.03.13 14:30,100001,XAUUSD,ENTRY,BUY,0.2350,0.1820,28.50,2912.80,0.00,0.15,0.00,0,0.00,0,"prob>=0.20 + no blackout",NLR_zscore60,1.23,CHOP_pct240,0.85,...
```

**AddOn 기록:**
```
2026.03.13 16:45,100001,XAUUSD,ADDON,BUY,0.1900,0.4520,29.10,2912.80,2938.60,0.08,0.00,0,2.30,1,"prob>=0.40 + unrealized>=1.5ATR + 5bar gap",...
```

**Close 기록:**
```
2026.03.14 09:15,100001,XAUUSD,CLOSE,NONE,0.00,0.00,27.80,0.00,2951.20,0.00,+385.50,1125,0.00,0,"CE2 trailing stop triggered",,,,,,,,,,
```

**Recovery 기록:**
```
2026.03.14 09:16,100001,XAUUSD,RECOVERY,NONE,0.00,0.00,0.00,2912.80,2951.20,0.00,0.00,0,0.00,2,"GV restored: SL=2912.80 AddonCount=2 bid>ce2 → hold",,,,,,,,,,
```

---

## 4. 에러 처리

| 시나리오 | 대응 |
|:---|:---|
| `FileOpen()` 실패 | `Print("CRITICAL: ...")` + Init return false. EA는 로거 없이도 동작 가능 (비치명적) |
| `FileWrite()` 도중 디스크 풀 | `GetLastError()` 체크 → `Print("WARNING: disk full")` → 로깅 중단, 거래는 계속 |
| `FileFlush()` 실패 | 무시 (다음 플러시에서 재시도) |
| 비정상 종료 후 재시작 | 기존 파일에 `FileSeek(끝)` → 이어쓰기 (데이터 유실 최소화) |

---

## 5. 성능 고려사항

| 항목 | 설계 |
|:---|:---|
| **I/O 최소화** | 즉시 쓰기 + N건(10건)마다 `FileFlush()` |
| **파일 크기** | 일 평균 3~4 거래 × ~300 bytes ≈ 1KB/일. 연간 ~365KB |
| **파일 공유** | `FILE_SHARE_READ` → 외부 프로그램이 실시간 읽기 가능 |
| **Strategy Tester** | `MQLInfoInteger(MQL_TESTER)` 확인 → 테스터 모드에서는 FILES_COMMON 아닌 로컬 Files/ |

---

## 6. 의존성

```
CTradeLogger
  ├── FeatureSchema.mqh     (피처 이름 상수, FormatFeatures에서 사용)
  └── 외부 의존성 없음       (독립 유틸리티 모듈)
```

**호출 관계:**
- `BSP_Long_v1.mq5` → `CTradeLogger.LogEntry()` / `LogAddon()` / `LogClose()`
- `CTradeExecutor.mqh` → `CTradeLogger.LogRecovery()` (재시작 복구 시)
