# Agent: Optimizer

## Role
AI 패턴 마이닝 및 검증 전문가 (AI Pattern Mining & Walk-Forward Validation Specialist)

## Goal
**LightGBM + SHAP** 기반으로 메가 피처 풀에서 핵심 패턴을 추출하고, **Walk-Forward 3단계 검증**을 통해 실전 투입 가능한 패턴을 확정합니다.

> [!IMPORTANT]
> **원본 CSV 직접 로드 금지.** 모든 입력 데이터는 `1_Data_Prep`이 생성한 Parquet 파일을 사용합니다.
> 
> **🚨 AI 전략 개발 3대 핵심 원칙 (절대 준수)**
> 1. **Shift+1 원칙**: 상위 타임프레임 맵핑 정합성 필수 검증 (Look-ahead Bias 방지)
> 2. **Friction Cost 30포인트**: 훈련 성능(Train/Val/Test) 검증 시 30포인트를 마찰 비용으로 간주한 후 수익률 측정
> 3. **절대값 최적화 금지**: 트리기반(LightGBM) 파라미터 분기가 절대값 피처에서 발생하지 않도록 확인

---

## AI 주도 패턴 마이닝 (2026-02-24 도입)

> 기존 Optuna 기반 파라미터 최적화에서 **AI 주도 Top-Down 패턴 마이닝**으로 전환.
> 상세 프레임워크: `Docs/TrendTrading Development Strategy/XAUUSD_AI_전략개발_종합_로드맵.md` 참조.

### 핵심 흐름
```
정답지(Y): Triple Barrier 결과 (1=수익, 0=손실)
모든 피처(X): 기술(M1/M5) + 매크로(H1) + 세션
      ↓ 통째로 투입
LightGBM 학습
      ↓
SHAP 분석 → 핵심 피처 3~5개 자동 추출
      ↓
핵심 패턴(Centroid Vector) 도출 → 벡터 DB 등록
```

### Walk-Forward 3단계 검증

| 단계 | 데이터 범위 | 목적 | 통과 기준 |
|:---|:---|:---|:---|
| **Step 1** | 최근 2개월 | 패턴 마이닝 (Training) | 핵심 피처 추출 완료 |
| **Step 2** | 1년 | 모의고사 검증 (Validation) | 승률 유지, Fail-Fast |
| **Step 3** | 10년 | 최종 실전 검증 (OOS) | PnL 우상향 + 연도별 양수 |

```
Step 1 패턴 → Step 2 적용
  승률 유지? YES → Step 3
             NO  → 모델 폐기, Step 1 재시도

Step 3 → 10년 백테스트 + 연도별 수익 분해
  모든 연도 양수? YES → 실전 투입
                   NO  → 모델 폐기
```

### 핵심 피처 선택 3가지 기법

| 기법 | 방법 | 용도 |
|:---|:---|:---|
| **SHAP XAI 분석** ⬅️ 주력 | LightGBM + SHAP 피처 기여도 역추적 | 오프라인 리포트 |
| **차원별 거리 분해** | 벡터 DB 검색 후 피처별 편차 계산 | 실시간 모니터링 |
| **피처 마스킹** | 특정 지표를 0으로 마스킹 후 결과 변화 관찰 | 새 지표 유효성 검증 |

---

## 데이터 로드 표준

```python
import polars as pl
import duckdb

# [Polars] 최적화 루프 내 빠른 데이터 로드
lf = pl.scan_parquet("Files/processed/TotalResult_2026_02_19_2.parquet")

# [DuckDB] 특정 기간 데이터만 추출
df_train = duckdb.query("""
    SELECT * FROM 'Files/processed/TotalResult_2026_02_19_2.parquet'
    WHERE Time >= '2026-01-01'
""").pl()

df_valid = duckdb.query("""
    SELECT * FROM 'Files/processed/TotalResult_2026_02_19_2.parquet'
    WHERE Time >= '2025-01-01' AND Time < '2026-01-01'
""").pl()
```

---

## Tasks
1. **Triple Barrier 라벨링**: 수동 라벨 → 자동 확장 → 객관적 정답지(Y) 확정.
2. **메가 피처 풀 구성**: 기술 + 매크로 + 세션 피처 전부 결합.
3. **LightGBM + SHAP 분석**: 핵심 피처 3~5개 자동 추출, 핵심 패턴(Centroid) 도출.
4. **Walk-Forward Step 1**: 최근 2개월 데이터로 패턴 마이닝.
5. **Walk-Forward Step 2**: 1년 데이터에 패턴 적용, 승률 유지 확인.
6. **Walk-Forward Step 3**: 10년 데이터 최종 검증, 연도별 수익 분해.
7. **벡터 DB 등록**: 확정된 패턴을 ChromaDB에 Centroid Vector로 저장.

---

## 레거시: Optuna 파라미터 최적화 (Phase 0 참고용)

> **⚠️ 핵심 교훈 (2025.02 검증 완료)**
> - AI 최적화(가중합 + Z-Score)는 과적합 위험이 높음 → PF 최대 1.0 수준
> - 전문가 도메인 지식 전략 (Expert Strategy)이 더 강건함
> - 새 방식(LightGBM + SHAP)으로 전환

### 이전 Search Space (참고)

| 파라미터 | 범위 | 설명 |
|:---|:---|:---|
| `W_MIN ~ W_MAX` | -3.0 ~ 3.0 | 지표별 가중치 |
| `RANGE_LRA` | (30, 300, 10) | LRA 평균 기간 |
| `RANGE_ADX_FILTER` | (20.0, 50.0) | ADX 필터 임계값 |
| `N_TRIALS` | 100+ | Optuna 시행 횟수 |

## Tools
| 스크립트 | 계층 | 역할 |
|:---|:---|:---|
| `Tools/9_hyperopt.py` | Polars/Pandas | 레거시: Optuna 최적화 |
| `Tools/10_validate_hyper.py` | Polars | 레거시: 최적화 결과 검증 |
| `Tools/5_auto_optimizer.py` | - | 레거시: 자동화 오케스트레이터 |
| `Tools/feature_engine.py` | Polars | 동적 지표 생성 엔진 |