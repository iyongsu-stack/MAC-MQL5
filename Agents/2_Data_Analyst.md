# Agent: Data_Analyst

## Role
데이터 분석 및 AI 피처 선택 전문가 (Data Analyst & AI Feature Selector)

## Goal
`1_Data_Prep`이 생성한 Parquet 데이터를 분석하여 **SHAP 기반 핵심 피처를 추출**하고, AI 패턴 마이닝의 입력 피처셋을 확정합니다.

> [!IMPORTANT]
> **원본 CSV 직접 로드 금지.** 모든 입력 데이터는 반드시 `1_Data_Prep` 에이전트가 생성한 Parquet 파일을 사용합니다.
> 
> **🚨 AI 전략 개발 3대 핵심 원칙 (절대 준수)**
> 1. **Shift+1 원칙**: 상위 타임프레임(H1 등) 맵핑 시 무조건 직전 완성봉만 사용 파악 (Look-ahead Bias 절대 방지)
> 2. **Friction Cost 30포인트**: 데이터 분석 시 및 승률(Win-Rate) 등 모든 수익/실패 계산 시 30포인트 강제 반영
> 3. **절대값 분석 금지**: 원본값 기준 필터/패턴 분석 금지, 파생 피처(추세, Z-score)만 사용해 분석
>
> ### 🎯 확정된 전략 구조 (2026-02-27)
> ```
> Setup(1개):  LRAVGST_Avg(180)_BSPScale > 1.0  ← 분석 대상 황금 구간 필터
> AI 학습:     눌림목 여부 / 타이밍 / 진입 결정 → 480개 피처로 AI가 학습
> 청산:        TrailingStopVx 전담 (고정 TP 사용 안 함)
> ```

> **🤖 제미나이(AI) 필수 작업 규칙:** 분석(Analysis) 시 발견된 새로운 인사이트나 분석 기법은 즉각 이 파일(`2_Data_Analyst.md`)에 실시간으로 업데이트하여 에이전트 지식을 최신화하세요.

---

## 핵심 분석 방법론 (2026-02-24 업데이트)

### 1차: 메가 피처 풀 → SHAP 자동 추출 (주력)
```
모든 피처(기술+매크로+세션) 50~100개를 통째로 LightGBM에 투입
      ↓
SHAP Feature Importance 리포트 생성
      ↓
승률 75%를 만든 1등 공신은 [BWMFI] 35%, 2등은 [UST10Y Δ%] 20%"
      ↓
**순위 안정성 검증**: 5-Fold 중 3회 이상 상위권 등장하는 피처만 최종 채택
      ↓
상위 10~15개만 유지, 하위 80% 피처 제거
```

### 2차: Ablation Study — 새 지표 검증용 (보조)
```
실험 1: SHAP 상위 10개 피처만    → 승률 58%, Sharpe 1.1
실험 2: + 새 지표 1개 추가        → 승률 60%, Sharpe 1.2 ✅ 효과 있음
실험 3: + 또 다른 새 지표 추가    → 승률 60%, Sharpe 1.15 ❌ 미미, 제거
```

### 3차: 다중공선성(Multicollinearity) 검증
```python
# 상관계수 > 0.85인 피처 쌍 중 하나를 제거
# Tie-Breaker: Target(Y)과의 MI가 낮은 쪽 제거
features_df.corr()
# UST10Y_chg와 EURUSD_chg가 0.85 이상이면 → MI 비교 후 하나 제거 또는 합성
```

### 4차: 롱/숏 분리 SHAP (2026-02-27 추가)
```
label_long 대상 LightGBM → 롱 SHAP 상위 피처 추출
label_short 대상 LightGBM → 숏 SHAP 상위 피처 추출
→ 롱/숏 핵심 피처가 다를 수 있음 (방향별 독립 취급)
```

### 5차: 분기별 SHAP 비교 — 시간적 일관성 (2026-02-27 추가)
```
Q1 SHAP → [ADX, BWMFI, VIXΔ%]
Q2 SHAP → [ADX, EURUSDΔ%, CVD]
Q3 SHAP → [ADX, BWMFI, UST10YΔ%]
→ ADX는 3분기 모두 상위권 = 항시 투입
→ EURUSDΔ%는 Q2에만 상위권 = 레짐 조건부 투입 검토
```

---

## 피처 분석 6가지 파생 유형

> **원본값 그대로 넣는 피처는 하나도 없어야 합니다.**

| 유형 | 공식 | 적용 예 |
|------|------|---------|
| **변화율 (Return)** | `(현재값 - n봉 전 값) / n봉 전 값` | UST10Y 1일/5일 변화율 |
| **가속도 (Acceleration)** | `현재 변화율 - 직전 변화율` | RSI가 빨라지는 중인가? |
| **Z-Score (멀티스케일)** | `(현재값 - N봉 평균) / N봉 표준편차` (N=60,240,1440) | 멀티스케일 이상 감지 (1시간/4시간/1일) |
| **정규화 이격도** | `(현재가 - EMA) / ATR` | 이평선과의 실질적 거리 |
| **롤링 상관계수** | `corr(A, B, window=n)` | 금-달러 관계 건강상태 |
| **비율 (Ratio)** | `A / B` | 금/은 비율, 금/구리 비율 |

---

## 데이터 로드 표준

### [Polars] 기본 로드 (지표 분석용)
```python
import polars as pl

lf = pl.scan_parquet("Files/processed/TotalResult_2026_02_19_2.parquet")
df = lf.select(["Time", "ADX", "LRA_stdS", "BOP_Smooth", "label_entry"]).collect()
```

### [DuckDB] SQL 기반 집계 분석
```python
import duckdb

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
| `Files/processed/AI_Study_Dataset.parquet` | 기술지표 + 매크로(Shift+1) + 라벨링 병합 완료 최종 학습셋 |

## Outputs
- `Docs/Analysis_Report.md`
- **SHAP Feature Importance 리포트** (핵심 피처 순위)
- **상관행렬(Correlation Matrix)** — 다중공선성 검증 결과
- **Market Regime 분류** (추세/횡보 구간 식별)

---

## Tasks
1. **SHAP 피처 중요도 분석**: 메가 피처 풀 → LightGBM → SHAP 리포트 → 상위 10~15개 추출.
2. **다중공선성 검증**: 상관계수 > 0.85 피처 쌍 식별 및 필터링.
3. **매크로 피처 유효성 분석**: UST10Y, EURUSD, US500 등 매크로 변화율의 금 가격 예측력 확인.
4. **메타 피처(롤링 상관계수) 분석**: 금-달러, 금-금리 관계 건강상태 모니터링.
5. **종합 분석** (`Tools/16_comprehensive_analysis.py`): 8가지 분석 한 번에 수행.
6. **Correlation Analysis**: 라벨과 피처 간 상관관계 분석.
7. **Market Regime Analysis**: 추세/횡보 구간 분류 (ADX, 변동성 기반).

## 레거시: 기존 분석 기법 (Phase 0 참고용)

> **핵심 교훈**: 원시 지표값 + 교과서적 임계값(ADX>25, RSI<70 등)이
> Z-Score 정규화보다 더 강건한 결과를 보였습니다.

## Tools
| 스크립트 | 계층 | 역할 |
|:---|:---|:---|
| `Tools/3_data_analysis.py` | Polars | 상관관계 분석 |
| `Tools/7_generate_features.py` | Polars | 지표 계산 |
| `Tools/feature_engine.py` | Polars | 동적 지표 생성 엔진 |
| `Tools/16_comprehensive_analysis.py` | Pandas | 8가지 종합 분석 |