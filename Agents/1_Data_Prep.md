# Agent: Data_Prep

## Role
데이터 전처리 전담 에이전트 — **모든 데이터 가공의 단일 진입점 (Single Entry Point)**

> [!IMPORTANT]
> **이 에이전트를 거치지 않은 원본 데이터를 다른 에이전트가 직접 읽는 것을 금지합니다.**
> 모든 데이터 소비 에이전트(Analyst, Optimizer, Simulator, Strategy_Designer) 및 **제미나이(AI)**는
> 반드시 이 에이전트가 생성한 `Files/processed/` 또는 `Files/labeled/` 경로의 Parquet 파일을 사용해야 합니다.
> 
> **🚨 AI 전략 개발 3대 핵심 원칙 (절대 준수)**
> 1. **Shift+1 원칙**: 상위 타임프레임(H1 등) 매핑 시 무조건 직전 완성봉만 사용 (Look-ahead Bias 절대 방지)
> 2. **Friction Cost 30포인트**: 데이터 분석, 승률 계산, 가설 검증 시 수익에서 무조건 30포인트 차감
> 3. **절대값 사용 금지**: 원본 가격/금리 대신 파생 피처(Δ%, Z-score 등)만 생성/전송
>
> ### 🎯 확정된 전략 구조 (2026-02-27)
> ```
> Setup(1개):  LRAVGST_Avg(180)_BSPScale > 1.0  ← 라벨링 황금 구간 필터
> AI 학습:     눌림목 여부 / 타이밍 / 진입 결정 → 480개 피처로 AI가 학습
> 청산:        TrailingStopVx 전담 (고정 TP 사용 안 함)
> ```
> **라벨링 시 반드시 준수**: `LRAVGST_Avg(180)_BSPScale > 1.0` 조건 충족 봉에서만 라벨 생성.

> **🤖 제미나이(AI) 필수 작업 규칙:**
> 제미나이 역시 데이터 가공 및 전처리는 무조건 이 에이전트(`1_Data_Prep.md`)를 통해서만 진행해야 하며, 분석 및 시뮬레이션 과정에서 필요한 경우 `Agents/` 폴더 내의 에이전트 마크다운 파일들을 직접 수정(업데이트)하면서 진행해야 합니다.

---

## 4계층 데이터베이스 프레임워크

> **2026-02-24 업데이트:** 기존 3계층에서 매크로 데이터 경로 + VectorDB(4계층)으로 확장.
> 상세 구조: `Docs/TrendTrading Development Strategy/ DB Framework.md` 참조.

```text
MT5 기술적 지표 + 매크로 심볼 수집
     ↓
  [1계층] Files/raw/              ← CSV 원본 (MT5 출력)
          Files/raw/macro/        ← 매크로 심볼 CSV (UST10Y, EURUSD 등)
     ↓ (변환 + 전처리)
  [2계층] Files/processed/        ← Parquet 처리 데이터 (메인 저장소)
          Files/processed/macro/  ← Parquet 매크로 피처 (Δ%, Z-score 변환 완료)
     ↓ (라벨링)
  [3계층] Files/labeled/          ← Triple Barrier 라벨 데이터
     ↓ (피처 추출 + 벡터화)
  [4계층] Files/vectordb/         ← VectorDB (ChromaDB) — 패턴 사전

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
| `Files/raw/macro/*.csv` | MT5 매크로 심볼 CSV (UST10Y, EURUSD 등) |
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
| `Files/processed/tech_features.parquet` | 기술적 지표 원본 (63개 컬럼, M1 분봉) |
| `Files/processed/tech_features_derived.parquet` | 기술적 지표 파생 변환 완료 (~94개 피처, Z-score Shift+1 적용) |
| `Files/processed/macro_features.parquet` | 매크로 피처 데이터 정제 완료 (360개 파생 피처) |
| `Files/processed/labels_barrier.parquet` | Triple Barrier 라벨 데이터 (Long/Short 분리, ~24만 행) |
| `Files/processed/AI_Study_Dataset.parquet` | **최종 AI 학습 데이터셋** (Tech+Macro+Label 병합, ~460컬럼) |
| `Files/vectordb/` | 벡터 DB (ChromaDB) — 패턴 사전 저장 |

---

## ETL 데이터 품질 검증 원칙 (2026-02-24 추가)

> **AI 학습 및 벡터 DB 임베딩의 품질은 데이터 품질에 100% 의존합니다.**

| 검증 항목 | 방법 | 실패 시 조치 |
|:---|:---|:---|
| **결측치(Missing Values)** | `df.isnull().sum()` → 0이어야 함 | forward-fill 적용(`limit=4`, bfill 금지) 또는 해당 행 제거 |
| **이상치(Outliers)** | Z-score > 5인 값 탐지 | **Winsorization 상하 1% 클리핑** (제거 금지, 비대칭 분포 시 개별 조정) |
| **타임스탬프 정합성** | 연속된 1분봉 사이 갭 확인 | 빠진 봉 보간 또는 해당 구간 제외 |
| **타임프레임 정렬** | 매크로 피처(H1)가 M1에 올바르게 매핑되었는지 확인 | **Shift+1 원칙**: M1 현재 봉에는 직전 완성된 H1 봉만 사용 |
| **데이터 범위** | 각 피처의 min/max가 합리적 범위 이내인지 확인 | 비정상 데이터 행 로깅 후 제거 |
| **PSI 모니터링** | Walk-Forward 단계 간 피처 분포 안정성 측정 | **PSI > 0.25 → 불안정 피처 → 재학습 트리거** |
| **캔린더 피처** | 요일/월/시간 sin/cos 순환 인코딩 + 월말 플래그 + FOMC/NFP 48h 원핫 | 정수 인코딩 금지 (트리 모델 순서 학습 오류 방지) |

> [!CAUTION]
> **Look-ahead Bias 방지:** 상위 타임프레임(H1, H4) 데이터를 M1에 매핑할 때, 반드시 **직전 완성봉(Shift+1)**의 데이터만 사용하세요.

---

## 매크로 데이터 전처리 파이프라인 (2026-02-24 추가)

```text
MT5 매크로 심볼 수집 (Yahoo Finance/FRED)
     ↓
  [1계층] Files/raw/macro/yfinance/ 및 fred/  ← CSV 원본
     ↓ (변환 + 전처리: build_data_lake.py)
  [2계층] Files/processed/macro_features.parquet  ← Parquet 매크로 피처

전처리 규칙:
  ❌ 금지: 원본값 그대로 저장 (금리 4.25%, EURUSD 1.0850)
  ✅ 필수: 변화율(Δ%) 또는 롤링 Z-score로 변환 후 저장
```

6가지 파생 유형 (원본값 그대로 넣는 피처는 하나도 없어야 합니다):

| 유형 | 공식 | 적용 예 |
|------|------|---------|
| **변화율 (Return)** | `(현재값 - n봉 전 값) / n봉 전 값` | UST10Y 1일/5일 변화율 |
| **가속도 (Acceleration)** | `현재 변화율 - 직전 변화율` | RSI가 빨라지는 중인가? |
| **Z-Score (멀티스케일)** | `(현재값 - N봉 평균) / N봉 표준편차` (N=60,240,1440) | 멀티스케일 이상 감지 (1시간/4시간/1일) |
| **정규화 이격도** | `(현재가 - EMA) / ATR` | 이평선과의 실질적 거리 |
| **롤링 상관계수** | `corr(A, B, window=n)` | 금-달러 관계 건강상태 |
| **비율 (Ratio)** | `A / B` | 금/은 비율, 금/구리 비율 |

---

## 계층별 표준 코드

### 1계층: DuckDB — CSV→Parquet 변환 & SQL 필터링
```python
import duckdb

# CSV → Parquet 변환
duckdb.query("COPY (SELECT * FROM 'Files/raw/ADXSmooth_DownLoad.csv') TO 'Files/processed/ADXSmooth.parquet' (FORMAT PARQUET, COMPRESSION ZSTD);")

# 매크로 CSV → Parquet 변환 (전처리 포함)
# → Files/raw/macro/ → Files/processed/macro/
```

### 2계층: Polars — 지표 계산 / Slope / Accel / 라벨링
```python
import polars as pl

lf = pl.scan_parquet("Files/processed/TotalResult_2026_02_19_2.parquet")
lf = lf.with_columns([
    (pl.col("ADXS_(14)_ADX") - pl.col("ADXS_(14)_ADX").shift(10)).alias("ADXS14_Slope"),
])
df = lf.collect()
df.write_parquet("Files/processed/features_computed.parquet", compression="zstd")
```

### 3계층: ATR 동적 배리어 라벨링 — 학습 전용 (2026-02-27 갱신)
```python
# ATR 동적 배리어 설정 (학습용 진입 타이밍 정답지)
#   TP:     ATR(14) × 1.0 (방향성 관성 판별)
#   SL:     ATR(14) × 1.2 (노이즈 필터링)
#   시간:   45봉 (45분)
#   Friction: 30pt 차감 (A2 원칙)
#   라벨: label_long(1/0), label_short(1/0) 분리
#   실전 청산은 트레일링스탑 전담 (AI는 진입만 학습)
# → Files/processed/labels_barrier.parquet
# → 스크립트: Files/Tools/build_labels_barrier.py
```

### 4계층: Pandas/sklearn — ML 학습 (필요 시)
```python
import pandas as pd
from sklearn.ensemble import RandomForestClassifier

df = pl.read_parquet("Files/labeled/TotalResult_Labeled.parquet").to_pandas()
X = df[feature_cols]
y = df["label_entry"]
model = RandomForestClassifier().fit(X, y)
```

---

## 현재 Parquet 컬럼 현황

### TotalResult_2026_02_19_2.parquet

> **최종 업데이트**: 2026-02-23  |  총 **59개 컬럼**, **3,150,208행**

| 그룹 | 컬럼명 | 파라미터 |
|:---|:---|:---|
| OHLCV | `Time`, `Open`, `Close`, `High`, `Low`, `TickVolume` | — |
| BOP | `BOP_Diff`, `BOP_Up1`, `BOP_Scale` | — |
| LRA | `LRAVGST_Avg(60)_StdS`, `LRAVGST_Avg(60)_BSPScale` | period=60 |
| LRA | `LRAVGST_Avg(180)_StdS`, `LRAVGST_Avg(180)_BSPScale` | period=180 |
| BOPWMA | `BOPWMA_(10-3)_SmoothBOP`, `BOPWMA_(30-5)_SmoothBOP` | 10-3, 30-5 |
| BSPWMA | `BSPWMA_(10-3)_SmoothDiffRatio`, `BSPWMA_(30-5)_SmoothDiffRatio` | 10-3, 30-5 |
| CHV | `CHV_(10-10)_CHV/StdDev/CVScale` | Smooth=10, CHV=10 |
| **CHV** | `CHV_(30-30)_CHV/StdDev/CVScale` | **Smooth=30, CHV=30** ✨ |
| TDI | `TDI_(13-34-2-7)_TrSi/Signal` | RSI=13, SmRSI=2, SmSig=7 |
| **TDI** | `TDI_(14-90-35)_TrSi/Signal` | **RSI=14, SmRSI=90, SmSig=35** ✨ |
| QQE | `QQE_(5-14)_RSI/RsiMa/TrLevel` | SF=5, RSI=14 |
| **QQE** | `QQE_(12-32)_RSI/RsiMa/TrLevel` | **SF=12, RSI=32** ✨ |
| CE | `CE_Upl1/Dnl1/Upl2/Dnl2` | — |
| CHOP | `CHOP_(14-14)_CSI/Avg/Scale` | Cho=14, Smooth=14 |
| **CHOP** | `CHOP_(120-40)_CSI/Avg/Scale` | **Cho=120, Smooth=40** ✨ |
| **ADXS** | `ADXS_(14)_ADX/Avg/Scale` | **period=14** ✨ |
| **ADXS** | `ADXS_(80)_ADX/Avg/Scale` | **period=80** ✨ |
| ADXMTF | `ADXMTF_H4_DiPlus/DiMinus/ADX` | H4 |
| ADXMTF | `ADXMTF_M5_DiPlus/DiMinus/ADX` | M5 |
| BWMTF | `BWMTF_H4_BWMFI/Color` | H4 |
| BWMTF | `BWMTF_M5_BWMFI/Color` | M5 |

> ✨ = 2026-02-23 추가/재계산  |  **스크립트**: `Files/Tools/update_features.py`

---

## Tasks
1. **[파이프라인] Data Lake 빌드**: 신규 다운로드 CSV(기술지표, 매크로)를 Parquet으로 일괄 변환 (`Files/Tools/build_data_lake.py` 실행)
2. **[매크로] 전처리 보강**: 추가적인 파생 Feature (Slope, Accel 등) 계산 로직이 필요 시 파이프라인 스크립트 수정
3. **[병합/라벨링]**: `tech_features.parquet`와 `macro_features.parquet`를 Shift+1 원칙 적용하여 병합한 후, Triple Barrier 라벨링 결과를 `labels_barrier.parquet`에 저장
4. **[ETL] 품질 검증**: 결측치, 이상치, 타임스탬프 정합성 검증 확인
5. **[VectorDB] 벡터화**: 확정된 피처를 벡터로 변환하여 `Files/vectordb/`에 저장
6. **[output] 최종 목적지 확인**: `Files/processed/` 하위 3개 핵심 Parquet 및 `Files/vectordb/`

---

## Tools
| 스크립트 | 계층 | 역할 |
|:---|:---|:---|
| `Files/Tools/build_data_lake.py` | Python | 기술지표/Yahoo/FRED CSV → 3개 Parquet 일괄 빌더 (전처리 포함) |
| `Files/Tools/build_tech_derived.py` | Python | 기술 지표 파생 변환 (Z-score Shift+1, MTF 변화점, CE ratio) |
| `Files/Tools/build_labels_barrier.py` | Python | Triple Barrier 라벨링 (ATR×1.0/1.2, 45봉, Friction 30pt) |
| `Files/Tools/merge_features.py` | Python | Tech+Macro(Shift+1)+Labels 병합 → AI_Study_Dataset.parquet |
| `Files/Tools/verify_merged_dataset.py` | Python | 병합 무결성 검증 (Shift+1, MTF, Label 정합성) |
| `Files/Tools/peek_schema.py` | Python | Parquet 스키마/데이터 초고속 확인 |
| `Files/Tools/update_features.py` | Python | 보조 지표 계산 업데이트 |
| `Files/Tools/fetch_macro_data.py` | Python | Yahoo Finance 매크로 수집 |
| `Files/Tools/fetch_fred_data.py` | Python | FRED 경제 지표 수집 |