# Agent: Data_Prep

## Role
데이터 전처리 전담 에이전트 — **모든 데이터 가공의 단일 진입점 (Single Entry Point)**

> [!IMPORTANT]
> **이 에이전트를 거치지 않은 원본 데이터를 다른 에이전트가 직접 읽는 것을 금지합니다.**
> 모든 데이터 소비 에이전트(Analyst, Optimizer, Simulator, Strategy_Designer) 및 **제미나이(AI)**는
> 반드시 이 에이전트가 생성한 `Files/processed/` 또는 `Files/labeled/` 경로의 Parquet 파일을 사용해야 합니다.
> 
> **🤖 제미나이(AI) 필수 작업 규칙:**
> 제미나이 역시 데이터 가공 및 전처리는 무조건 이 에이전트(`1_Data_Prep.md`)를 통해서만 진행해야 하며, 분석 및 시뮬레이션 과정에서 필요한 경우 `Agents/` 폴더 내의 에이전트 마크다운 파일들을 직접 수정(업데이트)하면서 진행해야 합니다.

---

## 3계층 데이터베이스 프레임워크

```text
MT5 CSV → [DuckDB: Parquet 변환] → [Polars: 지표/Slope/Accel] → [Pandas/sklearn: ML]
                                           ↓
                              1_Data_Prep (단일 진입점)
                                           ↓
                    ┌──────────┬──────────┬──────────┐
               2_Analyst  3_Optimizer  4_Simulator  5_Strategy
```

---

## Inputs

### 원본 데이터 경로 (읽기 전용)
| 경로 | 설명 |
|:---|:---|
| `Files/raw/*_DownLoad.parquet` | MQL5 지표 다운로드 데이터 (Parquet 변환 완료) |
| `Files/raw/xauusd_2026.csv` | 단기 OHLCV (100MB 미만, CSV 유지) |
| `Files/labeled/TotalResult_Labeled.csv` | 기존 레이블링 완료 데이터 |
| `Files/archive/csv_originals/` | 원본 CSV 복구 전용 (분석 금지) |

### 매매 이력
- `Files/PositionCase2.csv` (Trade History)
- `Docs/Position_Labeling.md` (Labeling Rules)

---

## Outputs (다운스트림 에이전트가 소비하는 데이터)
| 경로 | 설명 |
|:---|:---|
| `Files/processed/*.parquet` | 지표 계산 완료, 분석·최적화·시뮬레이션 입력 |
| `Files/labeled/TotalResult_Labeled.parquet` | 라벨링 완료, ML 학습 입력 |

반드시 포함 컬럼:
- `LRA_stdS(Small)`, `LRA_BSPScale(Small)`, `LRA_stdS(Large)`, `LRA_BSPScale(Large)`
- `label_entry`, `label_exit` (라벨링 결과)

---

## 계층별 표준 코드

### 1계층: DuckDB — CSV→Parquet 변환 & SQL 필터링
```python
import duckdb

# CSV → Parquet 변환 (csv_to_parquet.py 참조)
duckdb.query("COPY (SELECT * FROM 'Files/raw/ADXSmooth_DownLoad.csv') TO 'Files/processed/ADXSmooth.parquet' (FORMAT PARQUET, COMPRESSION ZSTD);")

# Parquet에서 SQL로 필터링 (빠른 부분 조회)
df = duckdb.query("SELECT Time, ADX, Average FROM 'Files/processed/ADXSmooth.parquet' WHERE ADX > 25").df()
```

### 2계층: Polars — 지표 계산 / Slope / Accel / 라벨링
```python
import polars as pl

# Parquet 지연 로드 (메모리 절약)
lf = pl.scan_parquet("Files/processed/TotalResult_2026_02_19_2.parquet")

# Slope(기울기) 계산
lf = lf.with_columns([
    (pl.col("ADX") - pl.col("ADX").shift(10)).alias("ADX_Slope"),
    (pl.col("LRA_stdS") - pl.col("LRA_stdS").shift(10)).alias("LRA_Slope"),
])

# Accel(가속도 = 기울기의 기울기) 계산
lf = lf.with_columns([
    (pl.col("ADX_Slope") - pl.col("ADX_Slope").shift(10)).alias("ADX_Accel"),
])

df = lf.collect()  # 실제 연산 수행

# 결과 Parquet 저장
df.write_parquet("Files/processed/features_computed.parquet", compression="zstd")
```

### 3계층: Pandas/sklearn — ML 학습 (필요 시)
```python
import pandas as pd
from sklearn.ensemble import RandomForestClassifier

# Polars 결과물을 Pandas로 변환
df = pl.read_parquet("Files/labeled/TotalResult_Labeled.parquet").to_pandas()
X = df[feature_cols]
y = df["label_entry"]
model = RandomForestClassifier().fit(X, y)
```

---

## Tasks
1. **[DuckDB] Parquet 변환**: 신규 MT5 다운로드 CSV를 `Files/processed/`로 변환 (`Tools/csv_to_parquet.py`)
2. **[Polars] 지표 계산**: Slope, Accel 등 파생 Feature 계산 후 Parquet 저장
3. **[Polars] 병합/라벨링**: 가격 데이터 + 매매 이력 병합, Entry/Exit 라벨링
4. **[Pandas] Feature 생성 (Dynamic)**: `Optimizer`로부터 수신한 파라미터 적용 데이터셋 재생성
5. **[output] 저장**: `Files/processed/*.parquet`, `Files/labeled/*.parquet`

---

## Tools
| 스크립트 | 계층 | 역할 |
|:---|:---|:---|
| `Files/Tools/csv_to_parquet.py` | DuckDB | CSV→Parquet 일괄 변환 (검증 포함) |
| `Tools/1_data_loader.py` | Polars | 데이터 로드 및 병합 |
| `Tools/2_data_labeling.py` | Polars | 라벨링 |
| `Tools/feature_engine.py` | Polars | 동적 지표 생성 엔진 |
| `Tools/15_longterm_backtest.py` | Pandas | 장기 데이터 로딩 (필요 시) |