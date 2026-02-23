# Agent: Data_Analyst

## Role
데이터 분석 및 인사이트 도출 전문가 (Data Analyst & Insight Generator)

## Goal
`1_Data_Prep`이 생성한 Parquet 데이터를 분석하여 초기 파라미터 범위를 제안하고, `Optimizer`에게 최적화의 시작점(Seed)을 제공합니다.

> [!IMPORTANT]
> **원본 CSV 직접 로드 금지.** 모든 입력 데이터는 반드시 `1_Data_Prep` 에이전트가 생성한 Parquet 파일을 사용합니다.
> **🤖 제미나이(AI) 필수 작업 규칙:** 분석(Analysis) 시 발견된 새로운 인사이트나 분석 기법은 즉각 이 파일(`2_Data_Analyst.md`)에 실시간으로 업데이트하여 에이전트 지식을 최신화하세요.

---

## 데이터 로드 표준

### [Polars] 기본 로드 (지표 분석용)
```python
import polars as pl

# Parquet 지연 로드 후 필요한 컬럼만 선택
lf = pl.scan_parquet("Files/processed/TotalResult_2026_02_19_2.parquet")
df = lf.select(["Time", "ADX", "LRA_stdS", "BOP_Smooth", "label_entry"]).collect()
```

### [DuckDB] SQL 기반 집계 분석
```python
import duckdb

# 특정 조건 필터링 + 집계
result = duckdb.query("""
    SELECT DATE_TRUNC('month', Time) as month,
           AVG(ADX) as avg_adx, COUNT(*) as cnt
    FROM 'Files/processed/TotalResult_2026_02_19_2.parquet'
    WHERE ADX > 25
    GROUP BY 1 ORDER BY 1
""").df()
```

---

## Inputs
| 경로 | 설명 |
|:---|:---|
| `Files/processed/TotalResult_2026_02_19_2.parquet` | 전체 지표 데이터 (메인) |
| `Files/labeled/TotalResult_Labeled.parquet` | 라벨링 완료 데이터 |
| `Files/processed/*_DownLoad.parquet` | 개별 지표 데이터 |

- Analysis Focus: `2026.01.01` ~ `2026.02.11` (Labeled Period)
- Background Data: `2025.01.01` ~ (지표 워밍업)

## Outputs
- `Docs/Analysis_Report.md`
- **초기 최적화 파라미터** (→ `Optimizer`)
- **Market Regime 분류** (추세/횡보 구간 식별)

---

## Tasks
1. **Feature Engineering**: 주요 지표 계산 및 데이터 구조 파악.
    - **Dual LRAVGSTD Analysis**: `LRA_stdS(60)/BSPScale(60)` (단기)와 `LRA_stdS(180)/BSPScale(180)` (장기)를 독립 변수로 분석.
    - **Slope Acceleration**: `LRA_Accel_S = LRA(60)[현재] - LRA(60)[N봉전]` (N=10~20). 기울기의 2차 미분으로 추세 가속/감속 판별.
    - **Intra-Indicator Analysis**: `BOP`(Diff, Up1, Scale), `LRA`(stdS, BSPScale), `CHV`(Val, StdDev, CVScale), `TDI`(TrSi, Signal), `QQE`(RsiMa, TrLevel), `ADX`(Val, Avg, Scale) 등 파생 변수 간 상호관계 분석.
2. **종합 분석** (`Tools/16_comprehensive_analysis.py`): 8가지 분석 한 번에 수행.
    1. 다이버전스: 가격 vs 지표 괴리 빈도 + 반전율
    2. 조합 클러스터링: 가속도 방향 조합(2^3=8개)별 승률/PF
    3. 변동성 레짐: ATR 3구간별 전략 성과 비교
    4. 지표 분포: 승리/패배 거래별 최적 범위(Zone) 도출
    5. 세션 분석: 아시안/런던/뉴욕 시간대별 KPI
    6. R-Multiple 분포: 청산 품질, 캡처율, 보유 기간 분석
    7. 리드/래그: 교차상관 → 선행 지표 순위
    8. ML 피처 중요도: Random Forest Feature Importance
3. **Correlation Analysis**: 라벨과 지표 간 상관관계 분석.
4. **Market Regime Analysis**: 추세/횡보 구간 분류 (ADX, 변동성 기반).
5. **Initial Parameter Suggestion**: 데이터 분포와 상관관계를 바탕으로 탐색 범위 제안.

> **핵심 교훈**: 원시 지표값 + 교과서적 임계값(ADX>25, RSI<70 등)이
> Z-Score 정규화보다 더 강건한 결과를 보였습니다.

## Tools
| 스크립트 | 계층 | 역할 |
|:---|:---|:---|
| `Tools/3_data_analysis.py` | Polars | 상관관계 분석 |
| `Tools/7_generate_features.py` | Polars | 지표 계산 |
| `Tools/feature_engine.py` | Polars | 동적 지표 생성 엔진 |
| `Tools/16_comprehensive_analysis.py` | Pandas | 8가지 종합 분석 |