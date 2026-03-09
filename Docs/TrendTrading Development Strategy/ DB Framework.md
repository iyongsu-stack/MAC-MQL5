---
created: 2026-02-19
updated: 2026-03-09
tags:
  - 데이터베이스
  - Parquet
  - DuckDB
  - MT5
  - ETL
  - 데이터파이프라인
  - 매크로피처
  - VectorDB
topics:
  - DataBase/Framework
  - DataBase/ETL
  - Trading/XAUUSD/Data Pipeline
links:
  - "[[ DB Framework+ VectorDB]]"
  - "[[XAUUSD_AI_피처_완전_가이드]]"
  - "[[인디게이터 데이타 파일 만들기]]"
  - "[[XAUUSD_AI_하이브리드_퀀트_프레임워크_종합]]"
  - "[[IcMarketTradingIndex]]"
---

> [!IMPORTANT]
> **🚨 Data Lake 및 DB 아키텍처 6대 핵심 원칙 (절대 준수)**
> 1. **Shift+1 원칙**: Data Lake 2계층(`macro_features`)은 원본 날짜 그대로 저장하며, M1 타임프레임과 병합 시 반드시 1봉 Shift 하여 미래참조를 방지한다.
> 2. **Friction Cost 30포인트**: CE Trailing Stop 라벨(`labels_barrier.parquet`) 생성 및 시뮬레이션 시 `friction_cost` 30.0pt 차감을 기본으로 규정한다.
> 3. **절대값 사용 금지**: 원본 데이터(가격/금리)는 1계층(raw)에만 머무르며, AI가 조회하는 상위 계층에는 파생 피처(변환값) 형태만 저장된다.
> 4. **Warm-up dropna 필수**: `macro_features.parquet`의 각 자산별 첫 ~1440행은 rolling(1440) 등으로 인한 NaN이 포함됨. **M1과 병합하는 모든 스크립트에서 반드시 `dropna(subset=macro_feature_cols)`를 호출**하여 불완전 데이터를 제거해야 한다. 2계층에서는 절대 dropna 하지 않는다.
> 5. **ffill 정책**: 2계층 매크로 피처는 시장별 휴일 차이로 인한 NaN을 `ffill`(직전 거래일 값 유지)로 처리함. `bfill`(역방향 채움)은 미래참조이므로 **절대 사용 금지**.
> 6. **Z-score + pct 병행 필수** ★: Z-score는 레짐 전환 시 스케일 불일치를 유발함. 모든 핵심 피처에 **롤링 퍼센타일 랭크(pct240/pct1440)**를 병행 생성하여 OOS 일반화 성능을 보장한다.

# 프로젝트 데이터베이스 프레임워크

> 최종 업데이트: 2026-03-09

---

## 1. 전체 구조 (4계층 파이프라인 & Data Lake 아키텍처)

> **2026-03-09 업데이트:** 프로젝트 표준 Data Lake 파이프라인 완성. A+B+C 통합 모델 학습 완료 (AUC=0.8298, OOS 3/3 PASS).

```
MT5 기술적 지표 + Yahoo Finance + FRED 매크로 수집
     ↓
  [1계층] Files/raw/
          Files/raw/macro/yfinance/   ← Yahoo Finance CSV 41개 (지수/외환/원자재)
          Files/raw/macro/fred/       ← FRED CSV 19개 (실질금리/기대인플레/스프레드)
     ↓ (Python 스크립트: build_data_lake.py + build_tech_derived.py)
  [2계층] Files/processed/            ← Data Lake 핵심 저장소 (Parquet 메인)
          tech_features.parquet       ← M1 기술 지표 원본 (63컬럼, 742만행)
          tech_features_derived.parquet ← 기술 지표 파생 변환 (Z-score+pct240 Shift+1, 165컬럼)
          macro_features.parquet      ← 매크로 파생 피처 (652컬럼, Δ%+Z-score+Slope)
          labels_barrier.parquet      ← CE Trailing Stop 정답지 (label_long, ~742만행)
          AI_Study_Dataset.parquet    ← 최종 AI 학습 데이터셋 (817컬럼, 266만행)
     ↓ (피처 추출 + 벡터화)
  [4계층] Files/vectordb/             ← VectorDB (ChromaDB) — 패턴 사전
     → 상세 구조: [[ DB Framework+ VectorDB]] 참조
```

---

## 2. 디렉터리별 역할

| 경로 | 포맷 | 설명 |
|:---|:---|:---|
| `Files/raw/` | CSV | MT5 다운로드 지표의 **원본 출력** |
| `Files/raw/macro/{source}` | CSV | Yahoo Finance 및 FRED 매크로 데이터 **원본 출력** |
| `Files/processed/` | Parquet | **Data Lake 핵심 도메인 분리 저장소** (아래 표 참조) |
| `Files/vectordb/` | ChromaDB | **벡터 DB** — 패턴 사전, 임베딩 캐시 |
| `Files/archive/csv_originals/` | CSV | 백업/보관용 원본 CSV |

### 매크로 데이터 수집 대상 (IC Markets MT5)

> 전체 심볼 목록: [[IcMarketTradingIndex]] 참조
> 피처 활용 방법: [[XAUUSD_AI_피처_완전_가이드]] 참조

| 카테고리 | 주요 심볼 | 용도 |
|:---|:---|:---|
| 채권 | `UST10Y_H6`, `UST05Y_H6`, `UST30Y_H6`, `EURBND_H6` | 금리 변화율, 장단기 금리차, 수익률 곡선 |
| 주식 지수 | `US500`, `USTEC`, `DE40`, `JP225` | 위험선호도, 세션별 벤치마크 |
| 외환 | `EURUSD`, `USDJPY`, `USDCHF` | 달러 강약, 안전자산 흐름 |
| EM 통화 | `USDMXN`, `USDZAR`, `USDTRY` | 이머징 스트레스 지표 |
| 귀금속 | `XAGUSD`, `XPTUSD`, `XPDUSD` | 금/은 비율, 섹터 모멘텀 |
| 에너지 | `XTIUSD`, `XBRUSD`, `XNGUSD` | 인플레 기대, 지정학 리스크 |
| 소프트 상품 | `Wheat_K6`, `Coffee_K6`, `Corn_K6` | 인플레이션 선행 지표 |
| 지수 선물 | `DXY_H6`, `VIX_H6` | 달러 인덱스, 공포지수 |

> [!WARNING]
> **매크로 피처 전처리 필수:** 매크로 심볼 원본값(예: UST10Y = 4.25%, EURUSD = 1.0850)을 그대로 AI에 넣으면 안 됩니다. 반드시 **변화율(Δ%)** 또는 **롤링 Z-score**로 변환한 후 `Files/processed/macro/`에 저장해야 합니다. 상세 변환 방법은 [[XAUUSD_AI_피처_완전_가이드]]의 "피처 스케일링 가이드" 참조.

---

## 3. Data Lake 도메인 분리 저장소 현황 (`Files/processed/`)

> 거대한 통짜 파일(TotalResult) 대신 역할별로 분리 저장하는 프로 퀀트 팀 방식 도입.

| 파일 (.parquet) | 내용 | 행/컬럼/용량 기준 | 업데이트 주기 |
|:---|:---|:---|:---|
| `tech_features` | M1 차트 기술 지표 원본 (ADX, BOP, BWMFI 등) | 742만 행 / 63 컬럼 / 약 1GB | 매일 (MT5 스크립트) |
| `tech_features_derived` | 기술 지표 파생 변환 (Z-score+**pct240/1440** Shift+1, MTF 변화점, CE ratio) | 742만 행 / **165 컬럼** / 약 2GB | `build_tech_derived.py` 실행 시 |
| `macro_features` | 매크로 파생 피처 (변화율, 멀티스케일 Z-score, Slope) | 8,651행 / **652 컬럼** / 약 25MB | 매주 (yfinance+FRED) |
| `labels_barrier`| **CE Trailing Stop** 기준 수익/손절 정답지 (Long 전용) | ~742만 행 / 9 컬럼 | 라벨링 로직 수정 시 |
| `AI_Study_Dataset` | **최종 AI 학습 데이터셋** (Tech Derived+Macro Shift+1+Label 병합) | **266만 행** / **817 컬럼** / 약 1.35GB | `/data-build` 워크플로우 실행 시 |

### raw/ (CSV, 수집 원본)

| 경로 / 모듈 | 수집 방식 | 설명 |
|:---|:---|:---|
| `yfinance/` | Python API (`yfinance`) | 1998~현재 일봉. 주식, 환율, 원자재, 달러지수 (41개) |
| `fred/` | Python API (`urllib` 직접 호출) | 1998~현재 일봉. 실질금리, 기대인플레이션, 하이일드 스프레드 (19개) |
| (루트) 기타 지표 | MT5 스크립트 | 기존 `DataDownLoad.mq5` 등을 통한 기술적 지표 |

---

## 4. 쿼리 도구

### DuckDB SQL (VS Code Parquet Visualizer)
```sql
-- 최근 30행 조회 (M1 스케일)
SELECT *
FROM read_parquet('.../processed/tech_features.parquet')
ORDER BY time DESC
LIMIT 30;

-- 매크로 데이터 특정 기간 컬럼 선택
SELECT Date, "UST10Y_ret1d", "DXY_zscore_240"
FROM read_parquet('.../processed/macro_features.parquet')
WHERE Date >= '2024-01-01'
ORDER BY Date ASC;
```

### CLI peek 도구
```powershell
python Files/Tools/peek.py Files/processed/TotalResult_2026_02_19_2.parquet Time ADX --head 100
```

---

## 5. 설계 원칙

- **별도 DB 서버 없음** — 파일 기반(Parquet + DuckDB 인메모리 쿼리) 방식
- **Parquet 선택 이유**: 컬럼 압축 효율, 빠른 컬럼 선택 읽기, Python(pandas/pyarrow) 및 DuckDB 완전 지원
- **CSV → Parquet 변환**: MT5가 CSV로 출력 → Python 스크립트로 Parquet 변환 후 사용
- **VectorDB 보완**: Parquet이 메인 저장소 역할을 유지하며, VectorDB(ChromaDB)는 패턴 사전·유사도 검색 전용으로 보완. 상세 구조는 [[ DB Framework+ VectorDB]] 참조.

---

## 6. ETL 데이터 품질 검증 원칙

> **2026-02-24 추가:** AI 학습 및 벡터 DB 임베딩의 품질은 데이터 품질에 100% 의존합니다. 아래 검증 단계를 ETL 파이프라인에 반드시 포함하세요.

| 검증 항목 | 방법 | 실패 시 조치 |
|:---|:---|:---|
| **결측치(Missing Values)** | `df.isnull().sum()` → 0이어야 함 | forward-fill 적용 또는 해당 행 제거 |
| **이상치(Outliers)** | Z-score > 5인 값 탐지 | Winsorization (상하위 1% 클리핑) |
| **타임스탬프 정합성** | 연속된 1분봉 사이 갭 확인 | 빠진 봉 보간 또는 해당 구간 제외 |
| **타임프레임 정렬** | 매크로 피처(H1)가 M1에 올바르게 매핑되었는지 확인 | **Shift+1 원칙**: M1 현재 봉에는 직전 완성된 H1 봉만 사용 |
| **데이터 범위** | 각 피처의 min/max가 합리적 범위 이내인지 확인 | 비정상 데이터 행 로깅 후 제거 |

> [!CAUTION]
> **Look-ahead Bias 방지:** 상위 타임프레임(H1, H4) 데이터를 M1에 매핑할 때, 반드시 **직전 완성봉(Shift+1)**의 데이터만 사용하세요. 현재 진행 중인 H1 봉의 데이터를 사용하면 미래 정보가 포함되어 백테스트 수익률이 비정상적으로 높게 나옵니다.

---

## 7. 주의사항

> [!WARNING]
> `tech_features.parquet` 파일이 **1GB 이상**으로 매우 큽니다.
> M1 분봉과 H1 일봉 데이터를 함께 참조하기 위해 Python 환경에서 Chunk 사이즈로 분할 읽기 또는 분산 병합을 적극 활용하세요.

> [!NOTE]
> `labels_barrier.parquet`은 `build_labels_barrier.py`로 생성되며, CE Trailing Stop 기반 Long 전용 라벨(약 742만 행)이 포함되어 있습니다. 파라미터 변경 시 `/data-build` 워크플로우를 재실행하여 전체 파이프라인을 재빌드하세요.

---

## 8. AI 학습 결과 요약 (2026-03-09)

> A+B+C 통합 모델 학습 완료. 상세: `롱 학습결과 분석.md` 참조.

| 항목 | 결과 |
|:---|:---|
| 입력 데이터 | `AI_Study_Dataset.parquet` (817컬럼, 266만행) |
| 1라운드 | Spearman 0.85 Pruning(811→419) + LightGBM 5-Fold + SHAP Top-60 |
| 2라운드 | A+B+C 통합 (pct+단조+레짐) → 80개 피처, AUC **0.8298** |
| OOS 검증 | 3/3 PASS (thr=0.20 기준 승률 ≥45%) |
| 실전 조합 | M30_DiPlus>35 + thr=0.25 → **승률 56.3%, 월 ~15건** |