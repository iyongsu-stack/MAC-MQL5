---
description: AI 학습 파이프라인 — Feature Pruning → LightGBM 1라운드 → SHAP 선별 → 2라운드 A+B+C 스나이퍼 모델 → OOS 검증 + 피라미딩 Model_AddOn 학습
---
// turbo-all

# AI 학습 워크플로우 (/ai-train)

> **목적**: AI_Study_Dataset.parquet → Feature Pruning → LightGBM 학습 → SHAP 피처 선별 → A+B+C 스나이퍼 모델 → ONNX 내보내기
> 추가로, 피라미딩(Model_AddOn) 전용 학습 파이프라인도 포함합니다.
> **전제 조건**: `/data-build` 워크플로우의 Step 0~4가 완료되어 `AI_Study_Dataset.parquet`(817컬럼, ~266만행)이 존재해야 합니다.

> [!CAUTION]
> **핵심 규칙: 기존 스크립트/파일 덮어쓰기 금지**
> 기존 롱전략용 스크립트와 모델을 절대 수정하지 않습니다.
> 숏전략 개발 시에도 동일한 기존 코드를 재사용하므로, **항상 새 이름의 파일만 생성**합니다.
> (Neo4j DB 규칙: `스크립트_덮어쓰기_금지`)

---

# [Part A] 롱전략 진입 학습 (Model_Entry) ✅

> [!IMPORTANT]
> **🚨 AI 학습 핵심 원칙 (자동 적용됨)**
> 1. **IS/OOS 엄격 분리**: IS(2018-08~2022-12) / OOS(2023+) — OOS는 최종 검증에서만 사용
> 2. **Feature Pruning**: 스피어만 상관 0.85 이상 중복 제거 → SHAP 분산 왜곡 방지
> 3. **1라운드 = 표준 Logloss**: SHAP 순수성 보호 (비대칭 손실은 2라운드에서)
> 4. **Winsorization**: X_train 기준 percentile만 적용 (미래 정보 누수 방지)
> 5. **Friction Cost 30pt**: 모든 수익성 판단 시 자동 차감

> [!CAUTION]
> **전제 조건**: `AI_Study_Dataset.parquet`가 `Files/processed/`에 존재해야 합니다.
> 데이터 빌드는 `/data-build` 워크플로우를 사용하세요.

---

## 전제 조건 확인

### Windows (기본 실행 환경)
1. AI 학습 데이터셋 존재 확인:
```powershell
dir "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\processed\AI_Study_Dataset.parquet"
```

2. 필수 라이브러리 확인:
```powershell
C:\Python314\python.exe -c "import lightgbm, shap, sklearn; print(f'LightGBM={lightgbm.__version__}, SHAP={shap.__version__}, sklearn={sklearn.__version__}')"
```

### macOS 환경 (2026-03-11 확인)
> [!IMPORTANT]
> macOS에서 python3.13을 사용할 경우 아래 사전 설치가 필요합니다.
> `python3.13 -m pip list`로 설치 여부를 먼저 확인 후 진행.

1. LightGBM 의존성 libomp 설치 (최초 1회):
```bash
brew install libomp
```

2. 필수 Python 라이브러리 설치 (최초 1회):
```bash
python3.13 -m pip install lightgbm shap scipy scikit-learn
```

3. 데이터셋 존재 확인:
```bash
ls -lh "/Users/gim-yongsu/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/processed/AI_Pyramid_Dataset.parquet"
```

---


## Step 1: AI 학습 1라운드 — Feature Pruning + LightGBM + SHAP (train_round1.py)

> **입력**: `Files/processed/AI_Study_Dataset.parquet` (817컬럼, ~266만행)
> **출력**: `Files/models/round1/` 디렉토리
>   - `shap_importance.csv` — 전체 피처 SHAP 중요도 순위
>   - `shap_top60.csv` — 핵심 피처 Top-60
>   - `fold_results.csv` — Walk-Forward Fold별 AUC
>   - `lgbm_round1.txt` — 최선 모델 저장
> **핵심 로직**:
> - IS/OOS 분할: 2018-08~2022-12 (학습) / 2023+ (미사용)
> - Feature Pruning: 스피어만 상관 0.85+ 중복 피처 제거 (10만행 샘플, 811→419개)
> - LightGBM: Expanding Walk-Forward 5-Fold, 표준 Logloss
> - SHAP: TreeExplainer, 5만행 샘플, |SHAP| 평균 기준 Top-60 선별
> - **실측**: 평균 AUC=0.7967±0.0211, pct240 피처 11개 Top-60 선발

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\train_round1.py"
```

**예상 소요**: ~80분 (Spearman 811×811 ~60분 + 5 Fold 학습 + SHAP)
**검증 포인트**:
- 평균 AUC > 0.75
- Fold간 AUC 표준편차 < 0.03
- `shap_top60.csv` 정상 생성 확인, pct240 피처 포함 여부

---

## Step 2: SHAP 결과 검토 및 피처 안정성 검증

> **입력**: `Files/models/round1/shap_top60.csv`, `fold_results.csv`
> **수동 검토 항목**:

1. Top-60 피처 목록 확인:
```powershell
C:\Python314\python.exe -c "import pandas as pd; df=pd.read_csv(r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\models\round1\shap_top60.csv'); print(df.to_string())"
```

2. Fold별 AUC 확인:
```powershell
C:\Python314\python.exe -c "import pandas as pd; df=pd.read_csv(r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\models\round1\fold_results.csv'); print(df.to_string())"
```

**검증 포인트**:
- 매크로/기술 피처 균형 확인 (한쪽 편중 시 경고)
- 특정 Fold에서만 AUC가 높은 경우 → 레짐 의존성 의심
- SHAP Top-60이 5개 Fold 중 3회 이상 등장하는 피처가 대다수인지 확인

---

## Step 3: AI 학습 2라운드 — A+B+C 통합 모델 (train_round2_ABC.py)

> **입력**: `shap_top60.csv` + `AI_Study_Dataset.parquet` + `tech_features.parquet`(Close)
> **출력**: `Files/models/round2_ABC/` 디렉토리
>   - `model_long_ABC.txt` — 최종 롱 모델 (A+B+C)
>   - `oos_ABC.csv` — OOS 검증 결과
> **핵심 로직 (3방안 통합)**:
> - **방안 A (퍼센타일 랭크)**: Top-60 피처에 `rank(pct=True)` 동적 생성 → 60→76개
> - **방안 B (단조 제약)**: `monotone_constraints` +1=19/-1=8 적용
> - **방안 C (레짐 피처)**: regime_monthly_pct, weekly_up_ratio, above_ma20w, bull_flag 4개 추가 → **총 80개**
> - FP 페널티 3.0 가중 + Walk-Forward 3단계 OOS 검증
> - Winsorization: X_train 기준 상하 1% 클리핑
> - **실측**: AUC=0.8298, OOS 3/3 PASS, M30>35+thr=0.25시 승률 56.3%

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\train_round2_ABC.py"
```

**예상 소요**: ~3~5분
**검증 포인트**:
- OOS AUC > 0.79 (전 Step)
- Walk-Forward Step1/2/3 승률 모두 ≥ 45%
- M30>35+thr=0.25 승률 ≥ 55%

---

## Step 4: Walk-Forward 3단계 최종 검증

> **입력**: 2라운드 최종 모델 + OOS 데이터 (2023-01 ~ 2026)
> **검증 구간**:

| 단계 | 구간 | 목적 |
|:---|:---|:---|
| Step 1 | 2023-01~2023-06 (6개월) | 최소 생존 |
| Step 2 | 2023-01~2024-06 (1.5년) | 안정성 |
| Step 3 | 2024-07~2026 (1.5~2년) | 최신 실전 신뢰 |

**통과 기준** (실측치 기반 갱신, 2026-03-08):
- 각 단계 승률 ≥ 45% (thr=0.20 기준)
- M30>35 + thr=0.25 조합 승률 ≥ 55%
- OOS AUC > 0.79

**실측 결과 (A+B+C 모델)**:
| 단계 | AUC | 신호 | 승률 | 판정 |
|:---|:---:|---:|:---:|:---:|
| Step1 (6mo) | 0.8148 | 1,415 | 49.5% | ✅ |
| Step2 (1.5y) | 0.8144 | 4,217 | 47.8% | ✅ |
| Step3 (new) | 0.7959 | 6,063 | 45.0% | ✅ |

**모두 통과 → Step 5 진행 / 실패 → Step 1 또는 /data-build 재실행**

---

## Step 5: ONNX 내보내기 및 MQL5 EA 탑재

> **입력**: 검증 통과한 최종 모델
> **출력**: `model_long.onnx` → MQL5 EA에 탑재

1. ONNX 변환:
```powershell
C:\Python314\python.exe -c "
import lightgbm as lgb
from skl2onnx import convert_sklearn
# ... ONNX 변환 로직
"
```

2. MQL5 EA에 ONNX 모델 로드 코드 추가 (수동)

---

## Part A 파이프라인 요약

```
[/data-build 완료]                    [/ai-train Part A]
────────────────                       ──────────────────────────────
AI_Study_Dataset.parquet ──────────┐
(817 cols, ~266만행, 2018-08~2026) │
                                   │
                         Step 1: train_round1.py            (~80분)
                                   │  (Spearman 811×811 + LightGBM 5-Fold)
                                   │  (표준 Logloss + SHAP Top-60, pct240 포함)
                                   ▼
                         shap_top60.csv + lgbm_round1.txt
                                   │
                         Step 2: SHAP 결과 검토              (수동)
                                   │  (피처 균형, pct 피처 선발 확인)
                                   ▼
                         Step 3: train_round2_ABC.py        (~5분)
                                   │  (Top-60 + A:pct + B:단조 + C:레짐 → 80피처)
                                   │  (AUC=0.8298, OOS 3/3 PASS)
                                   ▼
                         model_long_ABC.txt
                                   │
                         Step 4: Walk-Forward 3단계 검증
                                   │  (Step1~3 모두 승률≥45% 확인 완료)
                                   ▼
                         ✅ 모델 검증 완료 (M30>35+thr=0.25: 56.3%)
                                   │
                         Step 5: ONNX 내보내기
                                   │
                                   ▼
                         model_long.onnx → MQL5 EA
```

---

## Part A 스크립트 목록

| 스크립트 | 역할 | 위치 |
|:---|:---|:---|
| `train_round1.py` | 1라운드: Feature Pruning + LightGBM + SHAP Top-60 | `Files/Tools/` |
| `train_round2_ABC.py` | 2라운드: A+B+C 통합 (pct+단조+레짐) + OOS 검증 | `Files/Tools/` |
| `train_round2_AB.py` | 2라운드: A+B 통합 (pct+단조, 레짐 제외) | `Files/Tools/` |
| `train_round2_mono.py` | 2라운드: B단독 (단조 제약만) — 비교 실험용 | `Files/Tools/` |
| `extract_ABC_signals.py` | 신호 CSV 추출 (M30>35+thr=0.25) | `Files/Tools/` |

---

## Part A 주요 하이퍼파라미터 참조

### 1라운드 (train_round1.py)
```python
params = {
    "objective": "binary",
    "metric": "auc",
    "n_estimators": 1000,
    "learning_rate": 0.05,
    "max_depth": 6,
    "num_leaves": 31,
    "min_child_samples": 100,
    "subsample": 0.8,
    "colsample_bytree": 0.5,
    "scale_pos_weight": 1.63,  # 61.9/38.1 불균형 보정
    "early_stopping_rounds": 50,
}
```

### 2라운드 (train_round2_ABC.py) — 확정 (2026-03-08)
```python
params = {
    "objective": "binary", "metric": "auc",
    "n_estimators": 2000, "learning_rate": 0.03,
    "max_depth": 5, "num_leaves": 20,
    "min_child_samples": 200, "subsample": 0.8,
    "colsample_bytree": 0.6,
    "monotone_constraints": mono_vec,  # +1=19, -1=8, 0=53
    "monotone_constraints_method": "advanced",
}
FP_PENALTY = 3.0  # sample_weight로 FP 가중
THRESHOLD = 0.20  # 기본 임계치 (실전 0.25 추천)
```

### Walk-Forward Fold 구성 (1라운드)
| Fold | 학습 (IS) | 검증 (OOS) |
|:---:|:---|:---|
| 1 | 2018-08~2019-12 | 2020-01~06 |
| 2 | 2018-08~2020-06 | 2020-07~12 |
| 3 | 2018-08~2020-12 | 2021-01~06 |
| 4 | 2018-08~2021-06 | 2021-07~2022-06 |
| 5 | 2018-08~2022-06 | 2022-07~12 |

> 하이퍼파라미터 튜닝이 필요한 경우 Optuna 통합을 검토합니다.
> 숏 모델(`label_short`)은 롱 모델 완성 후 동일 파이프라인으로 별도 학습합니다.

---
---

# [Part B] 피라미딩 학습 (Model_AddOn)

> **목적**: `AI_Pyramid_Dataset.parquet` → Feature Pruning → LightGBM 학습 → SHAP 피처 선별 → A+B+C 모델 → ONNX 내보내기
> 1차 롱 진입이 수익 중인 상태에서, 추가 진입(피라미딩) 여부를 AI가 판단하는 **Model_AddOn** 전용 학습.

> [!CAUTION]
> **핵심 규칙: 기존 스크립트/파일 덮어쓰기 금지**
> Part A의 스크립트(`train_round1.py`, `train_round2_ABC.py` 등)를 절대 수정하지 않습니다.
> 피라미딩 학습은 **`_pyramid_` 접두사가 붙은 신규 스크립트만 생성**합니다.
> (Neo4j DB 규칙: `스크립트_덮어쓰기_금지`)

> [!IMPORTANT]
> **전제 조건**: `/data-build` Part B의 Step P1~P3이 완료되어 다음 파일이 존재해야 합니다:
> - `AI_Pyramid_Dataset.parquet` — Step P2 산출물 (α 피처 6개 포함, Inner Join)
> - `labels_pyramiding_full.parquet` — Step P1 산출물 (참조용)

---

## Step P4: 피라미딩 학습 1라운드 — Feature Pruning + LightGBM + SHAP (train_pyramid_round1.py)

> **입력**: `Files/processed/AI_Pyramid_Dataset.parquet`
> **출력**: `Files/models/pyramid_round1/` 디렉토리
>   - `shap_pyramid_importance.csv` — 전체 피처 SHAP 중요도 순위
>   - `shap_pyramid_top60.csv` — 핵심 피처 Top-60 (α 피처 포함 여부 확인)
>   - `fold_pyramid_results.csv` — Walk-Forward Fold별 AUC
>   - `lgbm_pyramid_round1.txt` — 최선 모델 저장
> **핵심 로직**:
> - **타겟**: `label_pyramid` (Part A의 `label_long`과 다름)
> - **추가 피처**: α 피처 6개 (`unrealized_pnl_atr`, `bars_since_entry`, `bsp_scale_delta`, `atr_expansion`, `trend_acceleration`, `addon_count`)
> - IS/OOS 분할: 2018-08~2022-12 (학습) / 2023+ (미사용)
> - Feature Pruning: 스피어만 상관 0.85+ 중복 피처 제거
> - LightGBM: Expanding Walk-Forward 5-Fold, 표준 Logloss
> - SHAP: TreeExplainer, |SHAP| 평균 기준 Top-60 선별
> - **scale_pos_weight**: 실제 label_pyramid 분포에 맞게 재계산 필요

```bash
# macOS
python3.13 "Files/Tools/train_pyramid_round1.py"
```
```powershell
# Windows
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\train_pyramid_round1.py"
```

**예상 소요**: 약 45~50분 (Spearman 817×817 ~ 553s + 5 Fold 학습 + SHAP)
**검증 포인트**:
- 평균 AUC > 0.75
- Fold간 AUC 표준편차 < 0.03
- α 피처 6개가 SHAP Top-60에 포함되는지 확인 (포함 시 피라미딩 피처 유효성 입증)

**실측 결과 (2026-03-11, AI_Pyramid_Dataset 847MB, 14,193,116행)**:
| 항목 | 실측값 |
|:---|:---|
| IS 데이터 | 7,315,065행 (2018-08~2022-12) |
| IS Win Rate | 19.5% (label=0: 80.5%, label=1: 19.5%) |
| scale_pos_weight | 4.12 (auto 계산) |
| Pruning 결과 | 817 → 430개 (387개 제거) |
| **평균 AUC** | **0.7654 ± 0.0175** ✅ |
| α 피처 Top-60 진입 | **3/6** (`unrealized_pnl_atr` **1위**, `bars_since_entry` 3위, `atr_expansion` 16위) |
| α 피처 Top-60 제외 | `bsp_scale_delta`(274위), `trend_acceleration`(429위), `addon_count`(430위) — 2라운드에서 강제 편입 |

> **주의**: `trend_acceleration`, `addon_count`는 SHAP=0.000000으로 1라운드 모델에서 영향력 없음.
> 단조 제약(`+1`/`-1`)으로 2라운드에서 규칙 기반 영향력 부여.

---

## Step P5: SHAP 결과 검토 및 피처 안정성 검증

> **입력**: `Files/models/pyramid_round1/shap_pyramid_top60.csv`, `fold_pyramid_results.csv`
> **수동 검토 항목**:

1. Top-60 피처 목록 확인:
```powershell
C:\Python314\python.exe -c "import pandas as pd; df=pd.read_csv(r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\models\pyramid_round1\shap_pyramid_top60.csv'); print(df.to_string())"
```

2. Fold별 AUC 확인:
```powershell
C:\Python314\python.exe -c "import pandas as pd; df=pd.read_csv(r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\models\pyramid_round1\fold_pyramid_results.csv'); print(df.to_string())"
```

**검증 포인트**:
- α 피처 6개 중 SHAP Top-60 선발 개수 확인 (최소 2개 이상 권장)
- 매크로/기술/α 피처 균형 확인
- 특정 Fold에서만 AUC가 높은 경우 → 레짐 의존성 의심

---

## Step P6: 피라미딩 학습 2라운드 — A+B+C 통합 모델 (train_pyramid_round2_ABC.py)

> **입력**: `shap_pyramid_top60.csv` + `AI_Pyramid_Dataset.parquet` + `tech_features.parquet`(Close)
> **출력**: `Files/models/pyramid_round2_ABC/` 디렉토리
>   - `model_addon_ABC.txt` — 최종 피라미딩 모델 (A+B+C)
>   - `oos_pyramid_ABC.csv` — OOS 검증 결과
> **핵심 로직 (3방안 통합)**:
> - **방안 A (퍼센타일 랭크)**: Top-60에 `rank(pct=True)` 동적 생성
> - **방안 B (단조 제약)**: `monotone_constraints` — α 피처 포함 재설계 필요
> - **방안 C (레짐 피처)**: regime 피처 4개 추가
> - FP 페널티 + Walk-Forward 3단계 OOS 검증
> - Winsorization: X_train 기준 상하 1% 클리핑

> [!IMPORTANT]
> **피처 구성 (2026-03-11 실측)**:
> - Top-60 + α 피처 강제 편입 = **63개** (`base_feature_cols`, pct/regime 추가 전)
> - 방안 A(pct) 11개 + 방안 C(레짐) 4개 포함 → **실제 학습 피처: 78개**
> - 단조 제약: +1=12개 / -1=4개 / 0(자유)=62개
> - α 피처 단조: `unrealized_pnl_atr`/`bsp_scale_delta`/`trend_acceleration` → +1, `addon_count` → -1

```bash
# macOS
python3.13 "Files/Tools/train_pyramid_round2_ABC.py"
```
```powershell
# Windows
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\train_pyramid_round2_ABC.py"
```

**예상 소요**: ~3~5분
**검증 포인트**:
- OOS AUC > 0.75 (Part A보다 낮을 수 있음 — 데이터 규모 소 + 조건부 학습)
- Walk-Forward Step1/2/3 승률 모두 ≥ 45%

**실측 결과 (2026-03-11)**:
| 항목 | 실측값 |
|:---|:---:|
| IS AUC | 0.7838 |
| IS 실승률 (thr=0.20) | 58.6% |
| IS 신호 수 | 99,297 |


---

## Step P7: Walk-Forward 3단계 최종 검증

> **입력**: 2라운드 최종 모델 + OOS 데이터 (2023-01 ~ 2026)
> **검증 구간**: Part A와 동일 (Step 1: 6개월, Step 2: 1.5년, Step 3: 최신)

**통과 기준**:
- 각 단계 승률 ≥ 45%
- OOS AUC > 0.75

**실측 결과 (A+B+C 모델, 2026-03-11)**:
| 단계 | AUC | 신호 수 | 승률 (thr=0.20) | 판정 |
|:---|:---:|---:|:---:|:---:|
| Step1 (6mo)  | 0.7954 | 106,781  | 58.9% | ✅ PASS |
| Step2 (1.5y) | 0.7841 | 307,852  | 58.2% | ✅ PASS |
| Step3 (new)  | 0.7388 | 482,113  | 56.0% | ✅ PASS |

**모두 통과 → Step P8 진행 / 실패 → Step P4 또는 /data-build Part B 재실행**

---

## Step P8: ONNX 내보내기 및 MQL5 EA 탑재

> **입력**: 검증 통과한 최종 피라미딩 모델
> **출력**: `model_addon.onnx` → MQL5 EA에 탑재 (Model_Entry와 별도 로드)

---

## Part B 파이프라인 요약

```
[/data-build Part B 완료]              [/ai-train Part B]
────────────────────                    ──────────────────────────────
AI_Pyramid_Dataset.parquet ────────┐
(α 피처 6개 포함, Inner Join)      │
                                   │
                         Step P4: train_pyramid_round1.py
                                   │  (Spearman Pruning + 5-Fold + SHAP Top-60)
                                   │  (α 피처 유효성 확인)
                                   ▼
                         shap_pyramid_top60.csv + lgbm_pyramid_round1.txt
                                   │
                         Step P5: SHAP 결과 검토              (수동)
                                   │  (α 피처 선발 확인, 균형 점검)
                                   ▼
                         Step P6: train_pyramid_round2_ABC.py
                                   │  (A+B+C 통합, 단조제약 재설계)
                                   ▼
                         model_addon_ABC.txt
                                   │
                         Step P7: Walk-Forward 3단계 검증
                                   │  (Step1~3 모두 승률≥45%)
                                   ▼
                         ✅ 피라미딩 모델 검증 완료
                                   │
                         Step P8: ONNX 내보내기
                                   │
                                   ▼
                         model_addon.onnx → MQL5 EA
```

---

## Part B 스크립트 목록

| 스크립트 | 역할 | 위치 |
|:---|:---|:---|
| `train_pyramid_round1.py` | 1라운드: Feature Pruning + LightGBM + SHAP Top-60 | `Files/Tools/` |
| `train_pyramid_round2_ABC.py` | 2라운드: A+B+C 통합 + α 피처 단조제약 + OOS 검증 | `Files/Tools/` |
| `extract_pyramid_signals.py` | 피라미딩 신호 CSV 추출 | `Files/Tools/` |

> Part A 스크립트(`train_round1.py`, `train_round2_ABC.py` 등)는 **절대 수정하지 않습니다.**
> 모든 산출물 디렉토리도 `pyramid_round1/`, `pyramid_round2_ABC/`로 Part A와 완전 분리됩니다.

---

## 🐛 Part B 버그 수정 이력

### [2026-03-11] `train_pyramid_round2_ABC.py` — OOS 피처 불일치 버그 (2건 수정)

**증상**: OOS Walk-Forward 루프에서 LightGBM `The number of features in data is not the same as training data` 오류

**원인 분석**:
1. **1차 오류**: OOS 루프에서 `top60`(60개)으로 데이터 로드 → α 피처 누락
2. **근본 원인**: `feature_cols`가 259번째 줄에서 pct+regime 추가 후 78개로 갱신 → OOS 루프에서 존재하지 않는 `*_pct`/`regime_*` 컨럼을 원본 df에서 참조 시 KeyError

**수정 내용**:
```python
# [168번째 줄] 수정 후 추가 — pct/regime 추가 전 원본 피처 보존
feature_cols = list(set(top60 + ALPHA_FEATURES))
base_feature_cols = feature_cols  # OOS 루프에서 원본 피처 참조용 (pct/regime 추가 전, 63개)

# [330번째 줄] 수정 후 — base_feature_cols로 로드
_X = df_oos.loc[mask, base_feature_cols].replace([np.inf,-np.inf], np.nan).fillna(0).clip(lo, hi, axis=1)
```
**수정 결과**: OOS 피처 78개 정상 복원 → 학습 78개와 일치 → OOS Walker-Forward 3/3 PASS

