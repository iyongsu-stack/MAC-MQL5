# Agent: Simulator

## Role
백테스팅, ATR 동적 배리어 라벨링(학습용) 및 Walk-Forward 검증 전문가

## Goal
전략을 시뮬레이션하고, **ATR 동적 배리어 라벨링(학습용 정답지)**, **Walk-Forward 3단계 검증**, 정량적 지표 및 월별/연도별 성과로 검증 결과를 반환합니다. **실전 청산은 트레일링스탑이 전담** (AI는 진입 타이밍만 학습).

> [!IMPORTANT]
> **원본 CSV 직접 로드 금지.** 모든 입력 데이터는 `1_Data_Prep`이 생성한 Parquet 파일을 사용합니다.
> 
> **🚨 AI 전략 개발 3대 핵심 원칙 (절대 준수)**
> 1. **Shift+1 원칙**: 시뮬레이터에서 상위 타임프레임 신호 사용 시 무조건 직전 완성봉만 참조 (Look-ahead Bias 절대 방지)
> 2. **Friction Cost 30포인트**: 모든 시뮬레이션의 거래 1회당 수익금 계산, 승률 결정 시 XAUUSD 건당 30포인트 차감 강제
> 3. **절대값 참조 금지**: 시뮬레이션 진입/청산 로직에 가격이나 지표의 특정 절대수치가 포함되지 않도록 보장
>
> ### 🎯 확정된 전략 구조 (2026-02-27)
> ```
> Setup(1개):  LRAVGST_Avg(180)_BSPScale > 1.0  ← 라벨링 황금 구간 필터
> AI 학습:     눌림목 여부 / 타이밍 / 진입 결정 → 480개 피처로 AI가 학습
> 청산:        TrailingStopVx 전담 (고정 TP 사용 안 함)
> ```
> **시뮬레이션 범위**: Setup 필터 통과 봉(황금 구간)에서만 라벨 생성 및 시뮬레이션 수행.

> **🤖 제미나이(AI) 필수 작업 규칙:** 시뮬레이션 과정에서 얻은 핵심 지표(KPI) 기준이나 검증 교훈은 즉각 이 파일(`4_Simulator.md`)에 실시간으로 업데이트하여 에이전트 지식을 최신화하세요.

---

## ATR 동적 배리어 라벨링 — 학습 전용 (2026-02-25 갱신)

> **절대 원칙:** ATR 동적 배리어 라벨링(진입 타이밍 정답지)은 반드시 AI 패턴 마이닝보다 선행되어야 합니다.
> **하이브리드 아키텍처:** AI는 "진입만" 학습. 실전 청산은 BSP TrailingStopVx가 전담.

### 설정 (표준 배리어, 2026-02-27 확정)
```
TP:     ATR(14) × 1.0  (필터링된 황금 구간에서 짧게 확실히 먹기)
SL:     ATR(14) × 1.2  (노이즈에 털리지 않도록 여유 확보)
시간:   45봉 (45분)   (세션 내 추세 확립 에너지 유효 시간)
Friction: 30pt 차감  (IC Markets 스프레드+슬리피지, A2 원칙)
```

> [!NOTE]
> 황금 구간(LRAVGST_Avg(180)_BSPScale > 1.0) 통과 봉에서만 라벨을 생성합니다.
> 해당 구간 내 봉에서만 AI가 눌림목 여부 / 타이밍 / 진입 여부를 학습합니다.

### 판정 기준 (롱/숏 분리)
| 결과 | 조건 | 라벨 |
|:---|:---|:---|
| 숏 수익 | 매도 후 60분 내 TP(1.5×ATR) 먼저 터치 | label_short = 1 |
| 숏 손실 | 매도 후 60분 내 SL(1.0×ATR) 먼저 또는 미터치 | label_short = 0 |

> [!CAUTION]
> **Friction Cost 필수:** 30pt(A2 원칙) 차감 후 TP/SL 도달 여부 판정.
> **M1 섀도우 겹침 문제:** 라벨링은 **Tick 데이터 기반**으로 수행 권장.

---

## Walk-Forward 검증 체계 (2026-02-24 추가)

```
Step 1 (2개월): 패턴 마이닝 → 핵심 피처 + 패턴 도출
     ↓
Step 2 (1년): 패턴 적용 → 승률 유지 확인 (Fail-Fast)
     ↓
Step 3 (최대 가용 데이터): 최종 검증 → 연도별 수익 분해 확인
     ↓ 통과
실전 투입 (0.01랏부터 단계적 증액)
```

> [!WARNING]
> **생존자 편향(Survivorship Bias):** 10년 백테스트 수익이 특정 1~2년 대박에 의해 왜곡될 수 있습니다.
> 반드시 **연도별 수익을 분해**하여 모든 연도에서 꾸준히 양수인지 확인하세요.

---

## 핵심 지표 (KPI)

| 지표 | 설명 | 기준 |
|:---|:---|:---|
| **PF (Profit Factor)** | 총이익/총손실 | > 1.2 이상 권장 |
| **WR (Win Rate)** | 승률 | > 55% 권장 |
| **Net R** | 순수익 (리스크 단위) | 1R = SL 금액 |
| **MDD (Max Drawdown)** | 최대 낙폭 | < 20% 권장 |
| **Sharpe Ratio** | 위험 대비 수익률 | > 1.0 이상 권장 |
| **연도별 수익** | 모든 연도에서 양수 확인 | 생존자 편향 방지 |
| **월별 수익률** | R 환산 월 수익 | 안정적 일관성 중요 |

---

## 데이터 로드 표준

```python
import polars as pl
import duckdb

# [Polars] 전체 데이터 로드
df = pl.read_parquet("Files/processed/AI_Study_Dataset.parquet")

# ── 황금 구간 Setup 필터 (사용자 정의 규칙 — 딱 1개) ──
df_setup = df.filter(pl.col("LRAVGST_Avg(180)_BSPScale") > 1.0)

# [DuckDB] Walk-Forward Step 2 (1년 OOS)
df_oos = duckdb.query("""
    SELECT * FROM 'Files/processed/TotalResult_2026_02_19_2.parquet'
    WHERE Time >= '2025-01-01' AND Time < '2026-01-01'
    ORDER BY Time
""").pl()

# [DuckDB] Walk-Forward Step 3 (10년 OOS)
df_long = duckdb.query("""
    SELECT * FROM 'Files/processed/TotalResult_2026_02_19_2.parquet'
    WHERE Time >= '2016-01-01'
    ORDER BY Time
""").pl()
```

---

## 시뮬레이션 모드

### 1. Triple Barrier (신규 — 주력)
```python
TP = ATR(14) × 1.5
SL = ATR(14) × 1.0
Time_Limit = 30봉
# 스프레드·슬리피지 차감 후 판정
```

### 2. 트레일링스탑 (Trailing Stop) ← Phase 0 최고 성능
```python
Initial SL = Entry - 2.0pt
# 수익 +1.0pt 도달 시: SL을 BE(진입가)로 이동
# 이후: 최고점 - 1.0pt로 계속 추적
# 최대 보유: 120봉 (2시간)
```

### 3. 대칭 TP/SL (참고용)
```python
TP = Entry + 2.0pt, SL = Entry - 2.0pt
# R:R = 1:1
```

---

## Inputs
| 경로 | 설명 |
|:---|:---|
| `Files/processed/TotalResult_2026_02_19_2.parquet` | 전체 지표 데이터 |
| `Files/processed/macro/*.parquet` | 매크로 피처 |
| `Files/labeled/*.parquet` | Triple Barrier 라벨링 완료 데이터 |
| 전략 파라미터 | `Optimizer` 또는 `Strategy_Designer`로부터 수신 |

## Outputs
- PF, WR, Net R, MDD, Sharpe Ratio
- **연도별 수익 분해표** (생존자 편향 검증)
- 월별 성과표
- Equity Curve Data

---

## 레거시: 핵심 교훈 (Phase 0)

> **⚠️ 2025.02 검증 결과**
> - 대칭 TP/SL (1:1) → 어떤 진입 로직도 PF ~1.0 (손익분기)
> - **트레일링스탑** → 동일 진입으로 PF 1.23, Net +659R
> - "알파는 진입이 아니라 청산에서 나온다"

## Tools
| 스크립트 | 계층 | 역할 |
|:---|:---|:---|
| `Tools/6_backtest_2025.py` | Polars/Pandas | 2025년 백테스트 (기본) |
| `Tools/14_best_strategy.py` | Polars | 전문가 전략 6종 비교 |
| `Tools/15_longterm_backtest.py` | DuckDB+Polars | 장기 백테스트 (2010~현재) |
