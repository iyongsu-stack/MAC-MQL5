# Agent: Optimizer

## Role
전략 최적화 및 프로세스 지휘 전문가 (Strategy Optimization & Process Orchestrator)

## Goal
Python의 **Optuna** 프레임워크를 활용하여 반복적인 최적화 프로세스를 주도합니다.

> [!IMPORTANT]
> **원본 CSV 직접 로드 금지.** 모든 입력 데이터는 `1_Data_Prep`이 생성한 Parquet 파일을 사용합니다.

> **⚠️ 핵심 교훈 (2025.02 검증 완료)**
> - AI 최적화(가중합 + Z-Score)는 과적합 위험이 높음 → PF 최대 1.0 수준
> - 전문가 도메인 지식 전략 (Expert Strategy)이 더 강건함
> - 자세한 내용은 `Agents/5_Strategy_Designer.md` 참조

---

## 데이터 로드 표준

```python
import polars as pl
import duckdb

# [Polars] 최적화 루프 내 빠른 데이터 로드
lf = pl.scan_parquet("Files/processed/TotalResult_2026_02_19_2.parquet")

# [DuckDB] 특정 기간 데이터만 추출 (메모리 절약)
df_train = duckdb.query("""
    SELECT * FROM 'Files/processed/TotalResult_2026_02_19_2.parquet'
    WHERE Time >= '2026-01-01'
""").pl()  # → Polars DataFrame 직접 반환

df_valid = duckdb.query("""
    SELECT * FROM 'Files/processed/TotalResult_2026_02_19_2.parquet'
    WHERE Time >= '2025-01-01' AND Time < '2026-01-01'
""").pl()
```

---

## Tasks
1. **Autonomous Orchestration**: `Tools/5_auto_optimizer.py`를 실행하여 데이터 로드 → 최적화 → 시뮬레이션의 전 과정 자동화.
2. **Define Search Space**: `Tools/9_hyperopt.py` 상단의 `USER CONFIGURATION` 섹션에서 파라미터 범위 정의.
3. **Result Analysis**: 생성된 `Data/HyperOpt_Result.json`을 검토하여 최종 전략 확정.
4. **Cross-Validation**: 2026년 학습, 2025년 검증의 교차 검증으로 과적합 방지.

## Search Space (탐색 범위)

| 파라미터 | 범위 | 설명 |
|:---|:---|:---|
| `W_MIN ~ W_MAX` | -3.0 ~ 3.0 | 지표별 가중치 |
| `RANGE_LRA` | (30, 300, 10) | LRA 평균 기간 |
| `RANGE_LRA_ACCEL` | (5, 20, 1) | 기울기 변화율 룩백 (N봉) |
| `RANGE_ADX_FILTER` | (20.0, 50.0) | ADX 필터 임계값 |
| `RANGE_THRESHOLD` | (0.0, 15.0) | 신호 발생 임계값 |
| `N_TRIALS` | 100+ | Optuna 시행 횟수 |
| `MIN_TRADES` | 30+ | 과적합 방지 최소 거래수 |

### MQL5 지표별 파라미터 범위

| 지표 | 파라미터 | 범위 |
|:---|:---|:---|
| **BOPAvgStd** | SmoothPeriod, AvgPeriod | 20~200 |
| **LRAVGSTD** | LwmaPeriod, AvgPeriod | 20~50, 30~300 |
| **BOPWmaSmooth** | WmaPeriod, SmoothPeriod | 5~50, 3~20 |
| **Chaikin Volatility** | SmoothPeriod, CHVPeriod | 10~150, 14~150 |
| **TDI** | PeriodRSI, VolBand, SmRSI, SmSig | 10~30, 10~50, 2~30, 5~20 |
| **QQE** | SF, RSI_Period | 5~50, 15~50 |
| **ADXSmooth** | Period | 10~50 |
| **ChandelierExit** | AtrPeriod, Multiplier1/2, LookBack | 10~40, 1~7, 10~50 |
| **ChoppingIndex** | Period, SmoothPeriod | 10~300, 5~150 |

## Tools
| 스크립트 | 계층 | 역할 |
|:---|:---|:---|
| `Tools/9_hyperopt.py` | Polars/Pandas | 마스터 최적화 (Optuna, 교차검증) |
| `Tools/10_validate_hyper.py` | Polars | 최적화 결과 검증 (2025년 데이터) |
| `Tools/5_auto_optimizer.py` | - | 자동화 오케스트레이터 |
| `Tools/feature_engine.py` | Polars | 동적 지표 생성 엔진 |