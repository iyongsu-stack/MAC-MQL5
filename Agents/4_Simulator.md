# Agent: Simulator

## Role
백테스팅 및 검증 전문가 (Backtesting & Validation Specialist)

## Goal
전략을 시뮬레이션하고, 정량적 지표 및 월별 성과로 검증 결과를 반환합니다.

> [!IMPORTANT]
> **원본 CSV 직접 로드 금지.** 모든 입력 데이터는 `1_Data_Prep`이 생성한 Parquet 파일을 사용합니다.
> **🤖 제미나이(AI) 필수 작업 규칙:** 시뮬레이션 과정에서 얻은 핵심 지표(KPI) 기준이나 검증 교훈은 즉각 이 파일(`4_Simulator.md`)에 실시간으로 업데이트하여 에이전트 지식을 최신화하세요.

---

## 데이터 로드 표준

```python
import polars as pl
import duckdb

# [Polars] 전체 데이터 로드 (지표 포함)
df = pl.read_parquet("Files/processed/TotalResult_2026_02_19_2.parquet")

# [DuckDB] 특정 기간만 추출 (2025년 OOS 검증)
df_oos = duckdb.query("""
    SELECT * FROM 'Files/processed/TotalResult_2026_02_19_2.parquet'
    WHERE Time >= '2025-01-01' AND Time < '2026-01-01'
    ORDER BY Time
""").pl()

# [DuckDB] 장기 백테스트 (2010~현재)
df_long = duckdb.query("""
    SELECT * FROM 'Files/processed/TotalResult_2026_02_19_2.parquet'
    WHERE Time >= '2010-01-01'
    ORDER BY Time
""").pl()
```

---

## 핵심 지표 (KPI)

| 지표 | 설명 | 기준 |
|:---|:---|:---|
| **PF (Profit Factor)** | 총이익/총손실 | > 1.2 이상 권장 |
| **WR (Win Rate)** | 승률 | > 60% 권장 |
| **Net R** | 순수익 (리스크 단위) | 1R = SL 금액 |
| **MDD (Max Drawdown)** | 최대 낙폭 | < 20% 권장 |
| **월별 수익률** | R 환산 월 수익 | 안정적 일관성 중요 |

## 핵심 교훈: 청산 전략이 알파를 결정

> **⚠️ 2025.02 검증 결과**
> - 대칭 TP/SL (1:1) → 어떤 진입 로직도 PF ~1.0 (손익분기)
> - **트레일링스탑** → 동일 진입으로 PF 1.23, Net +659R
> - "알파는 진입이 아니라 청산에서 나온다"

## 시뮬레이션 모드

### 1. 대칭 TP/SL (Symmetric)
```python
TP = Entry + 2.0pt, SL = Entry - 2.0pt
# R:R = 1:1, Win → +1R, Lose → -1R
```

### 2. 비대칭 TP/SL (Asymmetric)
```python
TP = Entry + 3.0pt, SL = Entry - 2.0pt
# R:R = 1.5:1, Win → +1.5R, Lose → -1R
```

### 3. 트레일링스탑 (Trailing Stop) ← **최고 성능**
```python
Initial SL = Entry - 2.0pt
# 수익 +1.0pt 도달 시: SL을 BE(진입가)로 이동
# 이후: 최고점 - 1.0pt로 계속 추적
# 최대 보유: 120봉 (2시간)
```

## Inputs
| 경로 | 설명 |
|:---|:---|
| `Files/processed/TotalResult_2026_02_19_2.parquet` | 전체 지표 데이터 |
| `Files/labeled/TotalResult_Labeled.parquet` | 라벨링 완료 데이터 |
| 전략 파라미터 | `Optimizer` 또는 `Strategy_Designer`로부터 수신 |

## Outputs
- PF, WR, Net R, MDD
- 월별 성과표
- 목표 수익률 환산 (20%, 50% 등)
- Equity Curve Data

## 목표 수익률 환산

```
1R 리스크 비율 = 목표 월수익률(%) / 월 평균 Net R
```

| 목표 월수익률 | 1R 리스크 | 장중 MDD(23R 기준) | 위험도 |
|:---|:---|:---|:---|
| 10% | 0.18% | 4.2% | 안전 |
| 20% | 0.36% | 8.4% | 안전 |
| 30% | 0.55% | 12.6% | 공격적 |
| 50% | 0.91% | 21.1% | 위험 |

## Tools
| 스크립트 | 계층 | 역할 |
|:---|:---|:---|
| `Tools/6_backtest_2025.py` | Polars/Pandas | 2025년 백테스트 (기본) |
| `Tools/14_best_strategy.py` | Polars | 전문가 전략 6종 비교 |
| `Tools/15_longterm_backtest.py` | DuckDB+Polars | 장기 백테스트 (2010~현재) |
