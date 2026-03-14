# Python Companion Services — 통합 설계서

> 모듈 ID: Services | Phase 3 (운용 보조)
> 배치 경로: `MQL5/Services/`
> 실행 환경: Windows Task Scheduler 또는 수동 (Python 3.14+)

---

## 개요

EA(BSP_Long_v1)가 실시간 거래를 수행하는 동안, Python Companion Service는 **외부 데이터 갱신, 모델 건전성 감시, 성과 추적, 알림 전송**을 담당하는 보조 서비스 4종입니다.

```
┌─────────────────────────────────────────────────────────────┐
│              Python Companion Services                       │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │ macro_fetcher.py │  │ drift_monitor.py │                 │
│  │ 매일 장마감 후    │  │ 주 1회 (주말)     │                 │
│  │ macro_latest.csv │  │ PSI > 0.25 감시   │                 │
│  └────────┬─────────┘  └────────┬─────────┘                 │
│           │                      │                           │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │performance_      │  │ alert_service.py │                 │
│  │  tracker.py      │  │ 텔레그램 알림     │                 │
│  │ trade_log → 통계 │  │ 거래/PnL/헬스    │                 │
│  └────────┬─────────┘  └────────┬─────────┘                 │
│           │                      │                           │
│           └──────────┬───────────┘                           │
│                      ▼                                       │
│           service_config.yaml (공통 설정)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. macro_fetcher.py — 매크로 데이터 일일 갱신

### 1.1 단일 책임
매일 장 마감 후 **SHAP 선별된 매크로 피처의 원본 심볼만** 수집하고, 파생 변환(Δ%, Z-score, Slope, Accel, pct)을 적용하여 `macro_latest.csv`를 생성한다.

### 1.2 기존 스크립트와의 관계

| 기존 스크립트 | 역할 | macro_fetcher.py와의 관계 |
|:---|:---|:---|
| `fetch_macro_data.py` | Raw CSV 수집 (전체 60개, **학습용**) | 심볼 리스트 중 필요 부분만 참조 |
| `build_data_lake.py` | Raw → Parquet 변환 | **변환 로직 재사용** (최신 1행만 출력) |

### 1.3 I/O 인터페이스

```
입력:
  - Yahoo Finance API (yfinance) → SHAP 선별 원본 심볼 (~10~15개)
  - FRED API (pandas_datareader) → SHAP 선별 원본 시리즈 (~5~8개)
    ※ 학습용 fetch_macro_data.py는 41+19=60개 전체 수집.
      운용용 macro_fetcher.py는 EA가 실제 사용하는 피처의
      원본 심볼만 수집 (수집 시간 ~5초)

출력:
  - Files/live/macro_latest.csv
    → 컬럼: date + ~20개 SHAP 선별 매크로 피처 (파생 변환 완료)
    → 행: 최근 1행 (당일 장 마감 값)
  - Files/live/heartbeat.txt → 마지막 실행 타임스탬프
```

> [!IMPORTANT]
> **숏전략 추가 시**: 숏 모델의 SHAP 학습 결과에 따라 수집 심볼 목록이 달라질 수 있음.
> 숏전략 학습 완료 후 반드시 `SELECTED_SYMBOLS` 리스트를 재검토하고,
> 롱과 숏에서 공통/추가로 필요한 원본 심볼을 확정할 것.

### 1.4 핵심 로직 — 3단계 Sanity Check 포함

```
수집된 Raw 값
    │
    ▼
[1단계] 절대 범위 검증
    │   금값: 500 ~ 10,000 USD
    │   DXY: 60 ~ 150
    │   VIX: 5 ~ 100
    │   → 범위 밖이면 해당 심볼 DROP + 전일 값 ffill
    ▼
[2단계] 일일 변동률 검증
    │   전일 대비 변동률 계산
    │   금: ±10% 초과 시 경고
    │   지수: ±15% 초과 시 경고
    │   → 초과 시 LOG 기록 + 텔레그램 경고, 하지만 값 자체는 유지
    │     (2020 코로나, 2022 전쟁 등 실제 큰 변동 사례 존재)
    ▼
[3단계] NaN/결측 검증
    │   파생 변환 후 NaN 개수 체크
    │   전체 피처의 50% 이상이 NaN이면 저장 중단
    │   → 전일 CSV 유지 + 텔레그램 알림
    ▼
  Atomic Write → macro_latest.csv 저장
```

```python
def main():
    # 1. 최근 90일 수집 (파생 계산을 위한 충분한 롤링 윈도우)
    raw_yf   = fetch_recent_yahoo(days=90)
    raw_fred = fetch_recent_fred(days=90)

    # 2. [1단계] 절대 범위 검증
    raw_yf = absolute_range_check(raw_yf, SANITY_RULES)

    # 3. [2단계] 일일 변동률 검증 (경고만, 값 유지)
    daily_change_alert(raw_yf, threshold_pct=CHANGE_THRESHOLDS)

    # 4. 파생 변환 (build_data_lake.py 로직 재사용)
    derived = apply_macro_transforms(raw_yf, raw_fred)

    # 5. SHAP 선별 피처만 추출 (~20개)
    selected = derived[SELECTED_MACRO_FEATURES]

    # 6. [3단계] NaN 검증 — 50% 이상 결측이면 저장 중단
    nan_ratio = selected.iloc[-1].isna().mean()
    if nan_ratio > 0.50:
        send_alert(f"❌ macro_fetcher: NaN {nan_ratio:.0%} → 저장 중단")
        return  # 전일 CSV 유지

    # 7. Atomic Write (쓰기 중 충돌 방지)
    atomic_save(selected.iloc[[-1]], MACRO_LATEST_PATH)

    # 8. 하트비트 기록
    write_heartbeat()


def atomic_save(df, target_path):
    """임시 파일에 먼저 쓰고 OS-level rename으로 교체"""
    tmp = target_path + ".tmp"
    bak = target_path + ".bak"
    df.to_csv(tmp, index=True)
    if os.path.exists(target_path):
        shutil.copy2(target_path, bak)
    os.replace(tmp, target_path)  # atomic operation
```

### 1.5 Sanity Check 규칙 (SANITY_RULES)

| 심볼 그룹 | 절대 범위 (1단계) | 일일 변동률 경고 (2단계) |
|:---|:---|:---|
| GOLD (금) | 500 ~ 10,000 USD | ±10% |
| DXY (달러 인덱스) | 60 ~ 150 | ±5% |
| VIX (공포지수) | 5 ~ 100 | ±50% (본래 변동성 큼) |
| 주식 지수 (SP500 등) | 1,000 ~ 100,000 | ±15% |
| 외환 (EURUSD 등) | 0.50 ~ 3.00 | ±5% |
| 국채 수익률 | -3.0 ~ 20.0 | ±30% (절대값 작아서 비율 크게 설정) |
| FRED 금리 | -5.0 ~ 25.0 | ±20% |

### 1.6 오류 처리

| 시나리오 | 대응 |
|:---|:---|
| API 연결 실패 | 10분 간격 2회씩, 총 5회 재시도 (~50분) → 실패 시 전일 CSV 유지 + 알림 |
| 1단계 범위 밖 | 해당 심볼 DROP → ffill (전일 값 복사) |
| 2단계 변동률 초과 | 경고 로그 + 텔레그램, **값 자체는 유지** (실제 급변 가능) |
| 3단계 NaN 50%+ | 저장 중단 → 전일 CSV 유지 + 텔레그램 알림 |
| 디스크 쓰기 실패 | Atomic Write로 .bak 복원 가능 + 알림 |

### 1.7 스케줄

| 항목 | 값 |
|:---|:---|
| 실행 시점 | 매일 장 마감 후 (UTC 22:00 ~ 23:00) |
| 실행 방법 | Windows Task Scheduler 또는 `python macro_fetcher.py` |
| 소요 시간 | ~30초 (네트워크 의존) |

---

## 2. drift_monitor.py — PSI + 실전 성과 교차 판정

### 2.1 단일 책임
학습 데이터와 최근 실전 데이터의 피처 분포를 PSI로 비교하고, `performance_tracker.py`의 실전 성과와 **교차 판정**하여 재학습 필요성을 종합적으로 결정한다.

### 2.2 I/O 인터페이스

```
입력:
  - Files/processed/AI_Study_Dataset.parquet    → 학습 데이터 분포 기준
  - Files/live/macro_latest.csv (최근 N일 누적)  → 실전 분포
  - Files/live/performance_report.csv            → 실전 성과 (performance_tracker 생성)

출력:
  - Files/live/drift_report.csv → PSI 결과 + 교차 판정 테이블
    (피처명, PSI값, 상태, 교차판정, 날짜)
  - 텔레그램 알림 (RETRAIN_REQUIRED 시)
```

### 2.3 PSI 계산 로직

```python
def calculate_psi(expected, actual, bins=10):
    """Population Stability Index 계산"""
    breakpoints = np.quantile(expected, np.linspace(0, 1, bins + 1))

    expected_pct = np.histogram(expected, bins=breakpoints)[0] / len(expected)
    actual_pct   = np.histogram(actual,   bins=breakpoints)[0] / len(actual)

    expected_pct = np.clip(expected_pct, 1e-6, None)
    actual_pct   = np.clip(actual_pct, 1e-6, None)

    psi = np.sum((actual_pct - expected_pct) * np.log(actual_pct / expected_pct))
    return psi
```

### 2.4 PSI + 실전 성과 교차 판정 (핵심)

> PSI만으로는 "분포가 바뀌었다"는 사실만 알 수 있고, "모델 성능이 떨어졌다"는 보장이 없다.
> 실전 성과와 교차하여 **종합 판정**한다.

```
판정 매트릭스:

           │  실전 성과 양호         │  실전 성과 악화
           │  (최근 2주 승률 ≥ 50%)  │  (최근 2주 승률 < 50%)
───────────┼────────────────────────┼──────────────────────
PSI < 0.10 │  ✅ OK                 │  ⚠️ MODEL_ISSUE
           │  (가장 좋은 상태)       │  (피처 외 원인 탐색:
           │                        │   슬리피지? 실행 오류?)
───────────┼────────────────────────┼──────────────────────
PSI > 0.25 │  🟡 WATCH              │  🔴 RETRAIN_REQUIRED
           │  (분포 변했지만         │  (드리프트가 성능에
           │   모델이 아직 버팀)     │   실제로 영향 → 재학습)
```

```python
def combined_assessment(psi_report, performance_stats):
    """PSI + 실전 성과 교차 판정"""
    psi_fail = any(r["psi"] > 0.25 for r in psi_report)
    perf_bad = performance_stats["recent_win_rate"] < 50  # 최근 2주 승률

    if psi_fail and perf_bad:
        return "RETRAIN_REQUIRED"    # 🔴 재학습 필수
    elif psi_fail and not perf_bad:
        return "WATCH"               # 🟡 관찰 (다음 주 재확인)
    elif not psi_fail and perf_bad:
        return "MODEL_ISSUE"         # ⚠️ 피처 외 원인 (슬리피지? 실행?)
    else:
        return "OK"                  # ✅ 정상


def main():
    # 1. PSI 계산
    train_df  = pd.read_parquet(TRAIN_DATASET_PATH)
    recent_df = load_recent_features(days=30)

    results = []
    for col in SHAP_TOP_FEATURES:
        psi = calculate_psi(train_df[col].dropna(), recent_df[col].dropna())
        status = "FAIL" if psi > 0.25 else ("WARN" if psi > 0.10 else "OK")
        results.append({"feature": col, "psi": psi, "status": status})

    # 2. 실전 성과 로드 (performance_tracker 산출물)
    perf = load_performance_report()  # recent_win_rate 포함

    # 3. 교차 판정
    verdict = combined_assessment(results, perf)

    # 4. 리포트 저장
    report = pd.DataFrame(results)
    report["verdict"] = verdict
    report.to_csv(DRIFT_REPORT_PATH, index=False)

    # 5. 텔레그램 알림 (판정별 차등)
    if verdict == "RETRAIN_REQUIRED":
        send_alert("🔴 재학습 필요: PSI 초과 + 실전 승률 하락")
    elif verdict == "WATCH":
        send_alert("🟡 관찰: PSI 초과했으나 성과는 양호")
    elif verdict == "MODEL_ISSUE":
        send_alert("⚠️ 모델 외 문제: 피처 정상이나 승률 하락 (실행 환경 점검)")
```

### 2.5 PSI 해석 기준 (GEMINI.md Rule 9)

| PSI | 상태 | 단독 조치 |
|:---:|:---|:---|
| < 0.10 | OK ✅ | 정상 |
| 0.10 ~ 0.25 | WARN ⚠️ | 모니터링 강화 |
| > 0.25 | **FAIL** 🔴 | 교차 판정 매트릭스로 최종 결정 |

### 2.6 스케줄 및 의존성

| 항목 | 값 |
|:---|:---|
| 실행 시점 | 주 1회 (토요일 UTC 12:00) |
| **선행 조건** | **performance_tracker.py 실행 완료** (실전 성과 필요) |
| 비교 기간 | 최근 30일 vs 전체 학습 기간 |
| 대상 피처 | SHAP Top-60 + 매크로 20개 |

---

## 3. alert_service.py — 텔레그램/이메일 알림

### 3.1 단일 책임
EA 및 Companion Service들의 이벤트를 텔레그램 Bot API를 통해 사용자에게 실시간 알림한다.

### 3.2 I/O 인터페이스

```
입력:
  - 다른 서비스에서 호출 (함수 import 또는 CLI)
  - service_config.yaml → 텔레그램 Bot Token, Chat ID

출력:
  - 텔레그램 메시지 전송
  - Files/Logs/alert_log.csv → 알림 이력 기록
```

### 3.3 핵심 로직

```python
import requests

def send_telegram(message: str, config: dict):
    """텔레그램 Bot API를 통한 메시지 전송"""
    url = f"https://api.telegram.org/bot{config['bot_token']}/sendMessage"
    payload = {
        "chat_id": config["chat_id"],
        "text": message,
        "parse_mode": "HTML"
    }
    resp = requests.post(url, json=payload, timeout=10)
    return resp.status_code == 200
```

### 3.4 알림 유형

| 유형 | 트리거 | 사용자 선택 | 메시지 예시 |
|:---|:---|:---:|:---|
| **거래 발생** | trade_log.csv 신규 행 | ✅ ON/OFF | `🟢 ENTRY: XAUUSD BUY 0.15 lot @ 2945.30 (prob=0.42)` |
| **청산** | trade_log.csv 청산 행 | ✅ ON/OFF | `🔴 CLOSE: +85pt (CE2 trailing), Hold: 340 bars` |
| **일일 PnL** | 매일 장 마감 후 | ✅ ON/OFF | `📊 Daily: +$127 | Week: +$340 | WR: 78%` |
| **서버 헬스** | heartbeat 5분 초과 | 항상 ON | `⚠️ EA heartbeat 미확인 (5분 이상)` |
| **드리프트** | PSI > 0.25 | 항상 ON | `🔴 PSI FAIL: TickVolume_zscore1440 (PSI=0.31)` |
| **매크로 수집 실패** | macro_fetcher 에러 | 항상 ON | `❌ macro_fetcher: FRED 3개 심볼 수집 실패` |

> 초기 설정 시 `input()`으로 거래/청산/일일PnL 수신 여부를 각각 선택.
> 서버 헬스, 드리프트, 수집 실패는 **시스템 안전 알림이므로 항상 활성**.

### 3.5 오류 처리

| 시나리오 | 대응 |
|:---|:---|
| 텔레그램 API 실패 | 3회 재시도 → 실패 시 로그만 기록 |
| Bot Token 미설정 | 경고 출력 후 알림 스킵 (서비스 중단 방지) |
| 메시지 길이 초과 | 4096자 이내로 자동 잘라내기 |

---

## 4. performance_tracker.py — 성과 추적

### 4.1 단일 책임
`CTradeLogger`가 기록한 `trade_log.csv`를 읽어 누적 성과 통계(승률, PF, 에쿼티 커브, MDD)를 계산하고 리포트를 생성한다.

### 4.2 I/O 인터페이스

```
입력:
  - Files/live/trade_log.csv → EA의 CTradeLogger가 기록

출력:
  - Files/live/performance_report.csv → 누적 통계 테이블
  - Files/live/equity_curve.csv → 일별 에쿼티 커브
  - (선택) 텔레그램 일일 리포트 (alert_service 호출)
```

### 4.3 핵심 로직

```python
def generate_report(trade_log_path):
    df = pd.read_csv(trade_log_path)
    closes = df[df["event"] == "CLOSE"].copy()

    if len(closes) == 0:
        return None

    # 기본 통계
    total     = len(closes)
    wins      = (closes["pnl_points"] > 0).sum()
    losses    = total - wins
    win_rate  = wins / total * 100

    # Profit Factor
    gross_profit = closes[closes["pnl_points"] > 0]["pnl_points"].sum()
    gross_loss   = abs(closes[closes["pnl_points"] < 0]["pnl_points"].sum())
    pf = gross_profit / max(gross_loss, 1e-6)

    # 평균 수익/손실
    avg_win  = closes[closes["pnl_points"] > 0]["pnl_points"].mean()
    avg_loss = closes[closes["pnl_points"] < 0]["pnl_points"].mean()

    # MDD
    equity = closes["pnl_points"].cumsum()
    peak = equity.cummax()
    drawdown = equity - peak
    mdd = drawdown.min()

    return {
        "total_trades": total,
        "wins": wins, "losses": losses,
        "win_rate": round(win_rate, 1),
        "profit_factor": round(pf, 2),
        "avg_win": round(avg_win, 1),
        "avg_loss": round(avg_loss, 1),
        "max_drawdown": round(mdd, 1),
        "total_pnl": round(closes["pnl_points"].sum(), 1),
    }
```

### 4.4 리포트 예시

```
═══════════════════════════════════════
  BSP_Long_v1 Performance Report
  2026-03-01 ~ 2026-03-14
═══════════════════════════════════════
  총 거래:     12건
  승률:        75.0% (9승 3패)
  Profit Factor: 2.84
  평균 수익:   +142.3 pt
  평균 손실:   -87.6 pt
  총 PnL:      +1,018.2 pt
  최대 낙폭:   -215.4 pt
═══════════════════════════════════════
```

### 4.5 스케줄

| 항목 | 값 |
|:---|:---|
| 실행 시점 | 매일 장 마감 후 (macro_fetcher 이후) |
| 또는 | `python performance_tracker.py` 수동 실행 |

---

## 5. service_config.yaml — 공통 설정

```yaml
# MQL5/Services/Config/service_config.yaml

paths:
  root: "../../"                                    # MQL5 루트 상대 경로
  macro_latest: "Files/live/macro_latest.csv"
  heartbeat: "Files/live/heartbeat.txt"
  trade_log: "Files/live/trade_log.csv"
  train_dataset: "Files/processed/AI_Study_Dataset.parquet"
  drift_report: "Files/live/drift_report.csv"
  performance_report: "Files/live/performance_report.csv"

telegram:
  bot_token: ""          # 사용자 설정 필요
  chat_id: ""            # 사용자 설정 필요
  enabled: false         # true로 변경 시 활성화

macro_fetcher:
  fetch_days: 90         # 파생 계산용 수집 기간
  selected_features:     # SHAP 선별 매크로 피처 목록
    - GOLD_zscore_240
    - GOLD_slope
    - MXUS_FR_ret1d
    - DAX_ret1d
    - COFFEE_accel
    # ... (전체 ~20개)

drift_monitor:
  psi_threshold: 0.25
  compare_days: 30
  bins: 10

schedule:
  macro_fetcher: "daily 22:00 UTC"
  drift_monitor: "weekly Saturday 12:00 UTC"
  performance_tracker: "daily 22:30 UTC"
```

---

## 6. 파일 관리 정책

### 6.1 운용 파일 분류

| 파일 | 증가 방식 | 관리 방법 |
|:---|:---|:---|
| `macro_latest.csv` | 덮어쓰기 (고정) | 관리 불필요 |
| `macro_latest.csv.bak` | 덮어쓰기 (고정) | 관리 불필요 |
| `heartbeat.txt` | 덮어쓰기 | 관리 불필요 |
| `drift_report.csv` | 주 1회 덮어쓰기 | 관리 불필요 |
| `performance_report.csv` | 덮어쓰기 | 관리 불필요 |
| **`trade_log.csv`** | 계속 증가 (~200행/년) | 수년 방치해도 문제없음 (~50KB/5년) |
| **`alert_log.csv`** | 계속 증가 | **분기 1회** 아카이브 권장 |
| **`service.log`** | 계속 증가 | **월 1회** 로테이션 권장 |

### 6.2 임시 파일 (.tmp) 잔재 정리

Atomic Write 중 크래시 발생 시 `.tmp` 파일이 남을 수 있음. **서비스 시작 시 자동 정리:**

```python
# 각 서비스 main() 시작 시 1회 실행
import glob, os
for f in glob.glob("Files/live/*.tmp"):
    os.remove(f)
```

### 6.3 로그 로테이션 (선택)

```python
# service.log → service_202603.log 로 월별 아카이브
# alert_log.csv → alert_log_2026Q1.csv 로 분기별 아카이브
```

---

## 7. 의존성

```
Python Companion Services
  ├── macro_fetcher.py
  │     ├── yfinance
  │     ├── pandas_datareader (FRED)
  │     ├── pandas, numpy
  │     └── service_config.yaml
  │
  ├── drift_monitor.py
  │     ├── pandas, numpy
  │     ├── Files/processed/AI_Study_Dataset.parquet
  │     ├── alert_service.py (PSI FAIL 시)
  │     └── service_config.yaml
  │
  ├── alert_service.py
  │     ├── requests (텔레그램 API)
  │     └── service_config.yaml
  │
  └── performance_tracker.py
        ├── pandas, numpy
        ├── Files/live/trade_log.csv (CTradeLogger 출력)
        ├── alert_service.py (일일 리포트 전송)
        └── service_config.yaml
```

---

## 8. 검증 계획

| 테스트 | 방법 | 기대 결과 |
|:---|:---|:---|
| macro_fetcher 단독 | `python macro_fetcher.py` | `macro_latest.csv` 생성, ~20개 컬럼, NaN 없음 |
| drift_monitor 단독 | `python drift_monitor.py` | `drift_report.csv` 생성, 각 피처 PSI 값 기록 |
| alert_service 테스트 | `python alert_service.py --test` | "Test message" 텔레그램 수신 확인 |
| performance_tracker | `python performance_tracker.py` | trade_log 기반 통계 출력 |
| 전체 통합 | 상기 4개 순차 실행 | 에러 없이 완료 + 리포트 생성 |
