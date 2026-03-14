# CEventFilter — 클래스 설계서

> 모듈 ID: 1-4 | Phase 1 | 의존성: 없음 (독립 모듈)

---

## 1. 단일 책임

**경제 이벤트 블랙아웃 필터**.
- CSV에서 FOMC/NFP/CPI/PCE 등 고영향 이벤트 일정을 로드
- 이벤트 전후 N시간 동안 **신규 진입 차단** (기본: 전 2시간, 후 1시간)
- Tier 1 이벤트만 블랙아웃 적용 (시뮬레이션 확정)
- **현재 ExternVariables에서 `UseEventFilter = false` (OFF 우위, PnL -6% 감소 확인)**

---

## 2. 클래스 다이어그램

```
┌──────────────────── CEventFilter ─────────────────────┐
│                                                         │
│ [구조체]                                                 │
│   EventInfo {                                           │
│     datetime eventTime, blackoutStart, blackoutEnd      │
│     string   eventType   // "FOMC", "NFP", etc.        │
│     int      tier, beforeHours, afterHours              │
│   }                                                     │
│                                                         │
│ [상수]                                                   │
│   EVENT_MAX_COUNT = 500                                 │
│                                                         │
│ [멤버 변수]                                              │
│   EventInfo m_events[]    // 전체 이벤트 배열           │
│   int       m_eventCount  // 이벤트 수                  │
│   int       m_gmtOffsetET      // ET → GMT (-5h)       │
│   int       m_serverGmtOffset  // Server GMT offset    │
│   bool      m_loaded                                    │
│                                                         │
│ [공개 메서드]                                            │
│   bool     Init(string csvPath, int serverGmtOffset)    │
│   bool     IsBlackout(datetime now)     // 핵심 체크    │
│   string   GetNextEvent(datetime now)   // 다음 이벤트명│
│   datetime GetNextEventTime(datetime)   // 다음 시각    │
│   datetime GetBlackoutEnd(datetime)     // 해제 시각    │
│   string   GetBlackoutStatus(datetime)  // 대시보드용   │
│                                                         │
│ [내부 메서드]                                            │
│   bool     ParseCSV()                                   │
│   datetime ConvertETToServer(dateStr, timeStr)          │
│   int      FindNextEventIdx(datetime now)               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 입출력 인터페이스

### 3.1 CSV 포맷 (`event_calendar.csv`)

```csv
date,time_et,event_type,tier,before_hours,after_hours
2026-03-19,14:00,FOMC,1,4,2
2026-04-04,08:30,NFP,1,2,1
2026-04-10,08:30,CPI,1,2,1
```

- `time_et`: 미국 동부시간(ET) 기준
- `tier`: 1=고영향(블랙아웃 적용), 2=중간(미적용)
- `before_hours/after_hours`: 이벤트 기준 전후 차단 시간

### 3.2 시간대 변환

```
ET → UTC → Server Time
  UTC = ET - (-5h) = ET + 5h
  Server = UTC + serverGmtOffset (기본 +2h)
  
  예: FOMC 14:00 ET = 19:00 UTC = 21:00 Server(GMT+2)
```

### 3.3 IsBlackout — 블랙아웃 판단

```
IsBlackout(datetime now)
  ├── Tier 1 이벤트만 검사
  ├── now ∈ [blackoutStart, blackoutEnd] 인 이벤트 존재?
  │   ├── Yes → return true  (진입 차단)
  │   └── No  → return false (진입 허용)
  └── m_loaded == false → return false (필터 OFF 시 안전)
```

### 3.4 GetBlackoutStatus — 대시보드 표시문

```
블랙아웃 중:  "🚫 FOMC 2h 30m 후 해제"
정상 (24h내): "✅ 정상 (NFP: 18시간 후)"
정상:         "✅ 정상 (FOMC: 5일 후)"
              "✅ 정상 (예정 이벤트 없음)"
미로드:       "⚠️ 이벤트 데이터 미로드"
```

---

## 4. 에러 처리

| 시나리오 | 대응 |
|:---|:---|
| CSV 파일 미존재 | Init 실패 → Print 경고. `IsBlackout()` 항상 `false` → 필터 OFF 동작 |
| 이벤트 500개 초과 | 초과분 truncation + Print CRITICAL |
| DST 전환 시 시간 오차 | `serverGmtOffset` 파라미터로 수동 조정 (2→3, 3→2) |
| 빈 CSV | `m_loaded = false` → 필터 비활성 |

---

## 5. 성능 고려사항

| 항목 | 설계 |
|:---|:---|
| **IsBlackout** | O(N) — 이벤트 수 N ≤ 500. M1 봉당 1회 |
| **FindNextEvent** | O(N) — 선형 검색 |
| **메모리** | `500 × EventInfo` ≈ 수 KB |
| **CSV 파싱** | OnInit 시 1회. 연간 ~50개 이벤트 |

---

## 6. 의존성

```
CEventFilter
  ├── Files/processed/event_calendar.csv  — Python이 생성
  └── 외부 의존성 없음

호출 관계:
  BSP_Long_v1.mq5 → CEventFilter.Init()
                   → IsBlackout(now) → CSignalGenerator 입력으로 전달
  CDashboard.mqh  → GetBlackoutStatus() → 패널 표시
```
