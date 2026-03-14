# CMacroLoader — 클래스 설계서

> 모듈 ID: 1-2 | Phase 1 | 의존성: 없음 (독립 모듈)

---

## 1. 단일 책임

**CSV 기반 매크로 피처 로더**.
- Python Companion이 매일 생성하는 `macro_latest.csv` (652개 피처 × ~200행)를 파싱
- **ffill(전일 값 유지)** 방식으로 주말/공휴일 NaN 처리 (bfill 절대 금지 — Rule 6)
- 날짜 키 기반 캐싱으로 중복 I/O 방지

---

## 2. 클래스 다이어그램

```
┌──────────────────── CMacroLoader ──────────────────────┐
│                                                         │
│ [구조체]                                                 │
│   MacroRow { datetime date; double values[1000]; }      │
│                                                         │
│ [상수]                                                   │
│   MACRO_MAX_FEATURES = 1000                             │
│   MACRO_MAX_ROWS     = 200                              │
│                                                         │
│ [멤버 변수]                                              │
│   string    m_csvPath          // CSV 경로 (Files/ 상대)│
│   string    m_featureNames[]   // 컬럼명 배열           │
│   int       m_featureCount     // 피처 수 (≤ 1000)      │
│   MacroRow  m_rows[]           // 로드된 전체 행         │
│   int       m_rowCount         // 행 수                  │
│   int       m_cachedRowIdx     // 현재 선택된 행 인덱스  │
│   datetime  m_lastLoadDate     // 마지막 로드 날짜       │
│   bool      m_loaded           // CSV 로드 완료 여부     │
│                                                         │
│ [공개 메서드]                                            │
│   bool     Init(string csvPath, int expectedFeatures)   │
│   bool     LoadForDate(datetime date)  // ffill 방식    │
│   bool     Reload()                    // 강제 재로드   │
│   double   GetFeature(string name)     // 이름으로 조회 │
│   double   GetFeatureByIndex(int idx)  // 인덱스 조회   │
│   int      GetFeatureIndex(string name)                 │
│   bool     IsStale(int maxDays)        // N일 미갱신?   │
│   bool     IsLoaded()                                   │
│   void     GetFeatureNames(string &out[])               │
│                                                         │
│ [내부 메서드]                                            │
│   bool     ParseCSV()                  // CSV 파싱      │
│   datetime ParseDate(string dateStr)   // YYYY-MM-DD    │
│   int      FindRowForDate(datetime)    // ffill 검색    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 입출력 인터페이스

### 3.1 CSV 포맷

```csv
date,SP500_zscore_60,SP500_pct_240,VIX_FRED_accel,...(652개)
2026-03-12,0.1234,-0.5678,...
2026-03-13,0.2345,-0.4567,...
```

- 첫 행: 헤더 (date + 피처명 652개)
- 이후: 날짜별 데이터 행 (최근 ~200일)

### 3.2 LoadForDate — ffill 로직

```
LoadForDate(datetime date)
  ├── CSV 미로드 → ParseCSV() 시도
  ├── FindRowForDate(date)
  │   └── 모든 행 중 date ≤ targetDate인 행 중 가장 최근 행 선택
  │       (주말/공휴일 → 직전 거래일 데이터 자동 적용 = ffill)
  ├── 행 발견 → m_cachedRowIdx 갱신, return true
  └── 미발견 → Print 경고, return false
```

### 3.3 호출 패턴

```
// CFeatureEngine.Update()에서 일 1회 호출
if(new_day_detected)
{
    m_macroLoader.LoadForDate(TimeCurrent());
}
double gold_z = m_macroLoader.GetFeature("GOLD_zscore_240");
```

---

## 4. 에러 처리

| 시나리오 | 대응 |
|:---|:---|
| CSV 파일 미존재 | `Init()` 실패 → Print 경고. EA는 매크로 없이도 기술 피처만으로 동작 가능하나 **신규 진입 차단** |
| 피처 수 불일치 | `expectedFeatures` 와 실제 불일치 시 Print Warning (비치명적) |
| `MACRO_MAX_FEATURES` 초과 | 초과 피처 truncation → Print CRITICAL (확인 필요) |
| `MACRO_MAX_ROWS` 초과 | 초과 행 truncation → Print CRITICAL |
| 날짜별 데이터 없음 | `GetFeature()` → `0.0` 반환 (안전 기본값) |
| 3일 이상 미갱신 (`IsStale(3)=true`) | **신규 1차 진입 차단** + 사용자 알림 |

---

## 5. 성능 고려사항

| 항목 | 설계 |
|:---|:---|
| **CSV 파싱** | OnInit 시 1회 전체 로드 (~200행 × 652컬럼). O(rows × features) |
| **GetFeature(name)** | O(N) 선형 검색 (N ≤ 652). 핫 패스 아님 (봉당 1회) |
| **GetFeatureByIndex** | O(1) 직접 인덱스 접근 |
| **메모리** | `200행 × 1000 double = 1.6MB` (MacroRow 고정 배열) |
| **갱신 주기** | 일 1회 Reload 또는 날짜 변경 시 자동 |

---

## 6. 의존성

```
CMacroLoader
  └── 외부 의존성 없음 (MQL5 표준 File I/O만 사용)

호출 관계:
  ├── CFeatureEngine.mqh  — Init 시 포인터 전달, Update 시 GetFeature 호출
  └── BSP_Long_v1.mq5     — OnInit에서 인스턴스 생성 → CFeatureEngine에 주입
```
