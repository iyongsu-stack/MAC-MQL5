---
description: AI 학습용 데이터셋 자동 빌드 — 기술 피처 파생 → 라벨링 → 매크로 병합 → 검증 + 피라미딩 전용 데이터 빌드
---
// turbo-all

# AI 학습 데이터셋 빌드 워크플로우 (/data-build)

> **목적**: Dukascopy M1 CSV → 기술 지표 원본 → 파생 피처 → 라벨링 → 매크로 병합 → 최종 AI 학습 데이터셋 자동 생성
> 추가로, 피라미딩(Model_AddOn) 전용 데이터셋 빌드 파이프라인도 포함합니다.

> [!IMPORTANT]
> **🚨 AI 전략 개발 핵심 원칙 (자동 적용됨)**
> 1. **Shift+1 원칙**: Z-score 계산 시 `x.shift(1).rolling(W)` 사용, Macro 병합 전 `shift(1)` 적용
> 2. **Friction Cost 30포인트**: `build_labels_barrier.py`에서 라벨링 시 자동 차감
> 3. **절대값 사용 금지**: `build_tech_derived.py`에서 파생 피처(Z-score/Slope/Ratio/MA비율/**pct240**)로 자동 변환
> 4. **CE 통합 버퍼**: CE_CE1/CE_CE2(2버퍼) → CE_Dist(ATR 정규화 거리)로 파생

> [!CAUTION]
> **전제 조건**: Dukascopy M1 CSV가 `Files/raw/dukascopy/XAUUSD.csv`에 존재해야 합니다.
> 데이터 수집은 `/duka-fetch` 워크플로우를 사용하세요.

---

## 전제 조건 확인

1. Dukascopy M1 CSV 존재 확인:
```powershell
dir "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\raw\dukascopy\XAUUSD.csv"
```

2. 매크로 피처 Parquet 파일 존재 확인 (Step 3에서 필요):
```powershell
dir "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\processed\macro_features.parquet"
```

---

## Step 0: 기술 지표 원본 생성 (build_micro_tech.py)

> **입력**: `Files/raw/dukascopy/XAUUSD.csv` (M1, ~740만행)
> **출력**: `Files/processed/tech_features.parquet` (62컬럼)
> **핵심 로직**:
> - BOP, LRAVGST, BOPWMA, BSPWMA, CHV, TDI, QQE, CE, ATR14, CHOP, ADXMTF, BWMTF 전체 계산
> - CE: 2버퍼 통합(`CE_CE1`, `CE_CE2`) — 상승추세=지지, 하락추세=저항
> - 검증된 Python Verifier 함수들을 import하여 재사용

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\build_micro_tech.py"
```

**예상 소요**: ~35분 (740만행 전체 계산)
**검증 포인트**: `컬럼 수: 62`, `기존 61개 컬럼 모두 포함` 메시지 확인

---

## Step 1: 기술 지표 파생 변환 (build_tech_derived.py)

> **입력**: `tech_features.parquet` (62컬럼)
> **출력**: `tech_features_derived.parquet` (165컬럼, 7,424,421행, ~4.5GB)
> **핵심 로직**:
> - Z-score: `x.shift(1).rolling(W)` (Shift+1, W=60/240/1440)
> - **롤링 퍼센타일 랭크**: `x.shift(1).rolling(W).rank(pct=True)` (pct240/pct1440, **45개 피처 추가**) ★
> - MTF 변화점 기반: M5/H4 값 변화 시점에서만 Slope/Z-score 계산 후 ffill
> - BOPWMA/BSPWMA: Slope + Accel + Slope_Zscore만 허용 (원본 DROP)
> - CE 트레일링 SL: dist_ATR, slope5, slope5_zscore60, squeeze (래칫 적용)
> - **CE_Dist**: `(Close - CE) / ATR14` + Slope(14) + Z-score(60)
> - TickVolume: MA비율(60/240/1440) + Z-Score(60/240/1440) + **pct240** (원본 DROP)
> - ATR 필터 피처: ATR14 + accel5 + zscore30 + pullback_depth + momentum
> - OHLC 원본: DROP

```powershell
$env:PYTHONIOENCODING='utf-8'; C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\build_tech_derived.py"
```

**예상 소요**: ~120분 (pct240/pct1440 rolling 계산 포함)
**검증 포인트**: `✅ 절대값 누수 없음` 메시지 확인, 컬럼 165개

---

## Step 2: Triple Barrier 라벨링 (build_labels_barrier.py)

> **입력**: `tech_features.parquet`
> **출력**: `labels_barrier.parquet`
> **핵심 로직**:
> - 배리어: TP = ATR(14) × 2.5, SL = ATR(14) × 2.5, Time = 30봉
> - TP 판정: Close 기준 (위크 배제)
> - Friction Cost: $0.30 자동 차감
> - **Long 전용** — 전체 봉에 대해 라벨 생성 (AI는 진입만 학습, 청산은 TrailingStopVx 전담)

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\build_labels_barrier.py"
```

**예상 소요**: ~7분
**검증 포인트**: Long 승률 ~34%, TP/SL/TIME 배리어 분포 출력 확인

---

## Step 3: 피처 병합 (merge_features.py)

> **입력**: `tech_features_derived.parquet` + `macro_features.parquet` + `labels_barrier.parquet`
> **출력**: `AI_Study_Dataset.parquet` (**817컬럼**, ~266만행, 1.35GB)
> **핵심 로직**:
> - Macro 데이터 **Shift+1 선적용**: `df_macro[features].shift(1)` 으로 미래 참조 완전 차단
> - `merge_asof(direction="backward")`: 시간 기준 과거 매핑
> - Labels: Left Join으로 전체 봉에 라벨 부착 (Long 전용)
> - **100% NaN 매크로 컬럼 사전 제거**: FEDFUNDS/UMCSENT `_1440` 4개
> - **Warm-up dropna**: `dropna(subset=macro_cols)` 로 매크로 rolling 웜업 NaN 제거
> - **데이터 시작점**: 2018-08 (BTC_zscore_1440 웜업이 병목)

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\merge_features.py"
```

**예상 소요**: ~200초
**검증 포인트**: 최종 컬럼 수 **817개**, 행 수 ~266만, Win Rate ~9.5%

---

## Step 4: 병합 무결성 검증 (verify_merged_dataset.py)

> **입력**: `AI_Study_Dataset.parquet` + 원본 파일들
> **검증 항목**:
> 1. Macro Shift+1: 2019-01-02 M1봉에 2019-01-01 매크로 값이 매핑되는지
> 2. M5 변화점: 5봉 블록 내 Slope 동일값 유지 확인
> 3. H4 변화점: 4시간 블록 내 Slope 일관성 확인
> 4. Label 정합성: 전체 봉에 Long 라벨 존재 (label_long 컬럼)
> 5. **원본 절대값 잔존 검증**: FORBIDDEN_COLS(OHLC, TickVolume, CE_CE1/CE2 등) 누수 여부

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\verify_merged_dataset.py"
```

**검증 포인트**: 모든 항목 `✅ PASS` 확인

---

## Step 5: AI 학습 1라운드 — Feature Pruning + LightGBM + SHAP (train_round1.py)

> **입력**: `AI_Study_Dataset.parquet` (817컬럼, ~266만행)
> **출력**: `Files/models/round1/` 디렉토리
>   - `shap_importance.csv` — 전체 피처 SHAP 중요도 순위
>   - `shap_top60.csv` — 핵심 피처 Top-60
>   - `fold_results.csv` — Walk-Forward Fold별 AUC
>   - `lgbm_round1.txt` — 최선 모델 저장
> **핵심 로직**:
> - IS/OOS 분할: 2018-08~2022-12 (학습) / 2023+ (미사용)
> - Feature Pruning: Spearman 상관 0.85+ 제거 (10만행 샘플, **811→419개**)
> - LightGBM: Expanding Walk-Forward 5-Fold, 표준 Logloss
> - SHAP: TreeExplainer, 5만행 샘플, |SHAP| 평균 기준 Top-60 선별
> - **실측**: 평균 AUC=0.7967±0.0211, pct240 피처 11개 Top-60 선발

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\train_round1.py"
```

**예상 소요**: ~80분 (Spearman 811×811 ~60분 + 5 Fold + SHAP)
**검증 포인트**: 평균 AUC > 0.75, Fold간 AUC 표준편차 < 0.03, pct240 피처 Top-60 포함

---

## Step 6: AI 학습 2라운드 — A+B+C 통합 모델 (train_round2_ABC.py) ✅

> **입력**: `shap_top60.csv` + `AI_Study_Dataset.parquet` + `tech_features.parquet`(Close)
> **출력**: `Files/models/round2_ABC/`
>   - `model_long_ABC.txt` — 최종 롱 모델 (A+B+C)
>   - `oos_ABC.csv` — OOS 검증 결과
> **핵심 로직 (3방안 통합)**:
> - **방안 A**: Top-60에 `rank(pct=True)` 동적 생성 → 60→76개
> - **방안 B**: `monotone_constraints` +1=19/-1=8 적용
> - **방안 C**: regime 피처 4개 추가 → **총 80개**
> - FP 페널티 3.0 + Walk-Forward 3단계 OOS 검증
> - **실측**: AUC=0.8298, OOS 3/3 PASS, M30>35+thr=0.25 승률 **56.3%**

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\train_round2_ABC.py"
```

**예상 소요**: ~5분
**검증 포인트**: OOS AUC > 0.79, M30>35+thr=0.25 승률 ≥ 55%

---

## 파이프라인 요약

```
[/duka-fetch]                          [/data-build (이 워크플로우)]
────────────                           ────────────────────────────────
Dukascopy → XAUUSD.csv (M1) ────────┐
Yahoo/FRED → macro_features.parquet ─┤
                                     │
                           Step 0: build_micro_tech.py        (~35분)
                                     │  (15개 지표군, CE 2버퍼 통합, 62컬럼)
                                     ▼
                           tech_features.parquet (62 cols, ~740만행)
                                     │
                           Step 1: build_tech_derived.py       (~120분)
                                     │  (Z-score Shift+1, **pct240/pct1440**, MTF, CE_Dist)
                                     ▼
                           tech_features_derived.parquet (165 cols, ~742만행)
                                     │
                           Step 2: build_labels_barrier.py     (~7분)
                                     │  (Triple Barrier Long전용, ATR×2.5, Friction $0.30)
                                     ▼
                           labels_barrier.parquet
                                     │
                           Step 3: merge_features.py           (~200초)
                                     │  (Macro Shift+1, merge_asof, dropna)
                                     ▼
                           AI_Study_Dataset.parquet (817 cols, ~266만행)
                                     │
                           Step 4: verify_merged_dataset.py
                                     │  (Shift+1, MTF, Label, 절대값 — 5/5 PASS)
                                     ▼
                           ✅ 데이터 빌드 완료
                                     │
                           Step 5: train_round1.py             (~80분)
                                     │  (Spearman 811→419 + 5-Fold AUC=0.7967 + SHAP Top-60)
                                     ▼
                           shap_top60.csv + lgbm_round1.txt
                                     │
                           Step 6: train_round2_ABC.py         (~5분)
                                     │  (A+B+C 80피처, AUC=0.8298, OOS 3/3 PASS)
                                     ▼
                           model_long_ABC.txt → (ONNX 내보내기) → MQL5 EA
```

---

# [Part B] 피라미딩 전용 데이터 빌드 (Model_AddOn)

> **목적**: 이미 1차 롱 진입이 성공(Win)한 상태에서, 추가 진입(피라미딩) 여부를 AI가 판단하는 Model_AddOn 전용 학습 데이터셋 생성.

> [!CAUTION]
> **핵심 규칙: 기존 스크립트/파일 덮어쓰기 금지**
> 기존 롱전략용 스크립트와 데이터를 절대 수정하지 않습니다.
> 숏전략 개발 시에도 동일한 기존 코드를 재사용하므로, **항상 새 이름의 파일만 생성**합니다.
> (Neo4j DB 규칙: `스크립트_덮어쓰기_금지`)

> [!IMPORTANT]
> **전제 조건**: Part A의 Step 0~2가 완료되어 다음 파일들이 존재해야 합니다:
> - `tech_features.parquet` (62컬럼) — Step 0 산출물
> - `tech_features_derived.parquet` (165컬럼) — Step 1 산출물
> - `macro_features.parquet` (652컬럼) — `/data-fetch` 산출물
> - `labels_barrier.parquet` — Step 2 산출물 (Win 위치 참조용)

---

## Step P1: 피라미딩 전체 구간 라벨링 (build_pyramid_labels_full.py)

> **입력**: `tech_features.parquet` + `labels_barrier.parquet`
> **출력**: `labels_pyramiding_full.parquet`
> **핵심 로직**:
> - `sim_label_pyramiding_v2.py`의 V2 로직 기반 (기존 스크립트 미수정)
> - 전체 구간(IS+OOS, 2018-08 ~ 데이터 끝) 라벨링
> - 3-Barrier: SL = ATR×2.5, TP = ATR×2.0, CE2 청산, Friction $0.30
> - 눌림목 State Machine (PULLBACK_ATR_DIP=1.0) 으로 눌림목 구간 제외
> - **α 피처 6개** 동시 계산:
>   1. `unrealized_pnl_atr` — (현재가 - 1차진입가) / ATR
>   2. `bars_since_entry` — 1차 진입 후 경과 봉 수
>   3. `bsp_scale_delta` — 진입 시점 대비 BSPScale 변화
>   4. `atr_expansion` — 현재ATR / 1차진입ATR (변동성 확장 비율)
>   5. `trend_acceleration` — BSPScale 5봉 기울기
>   6. `addon_count` — 이미 추가한 횟수 (초기 0)

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\build_pyramid_labels_full.py"
```

**예상 소요**: ~15분
**검증 포인트**: α 피처 6개 NaN=0, label_pyramid 분포(0/1), 연도별 분포 출력

---

## Step P2: 피라미딩 전용 피처 병합 (merge_features_pyramid.py)

> **입력**: `tech_features_derived.parquet` + `macro_features.parquet` + `labels_pyramiding_full.parquet`
> **출력**: `AI_Pyramid_Dataset.parquet`
> **핵심 로직**:
> - Macro 데이터 **Shift+1 선적용** (기존 merge_features.py와 동일)
> - `merge_asof(direction="backward")` 시간 기준 과거 매핑
> - **Inner Join**: 라벨이 존재하는 봉만 남김 (Model_AddOn 조건부 학습 목적)
> - 100% NaN 매크로 컬럼 사전 제거
> - **Warm-up dropna**: `dropna(subset=macro_cols)`

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\merge_features_pyramid.py"
```

**예상 소요**: ~60초
**검증 포인트**: 전체 행 수 = labels_pyramiding_full 행 수와 일치, α 피처 6개 + 기존 피처 병합 완료

---

## Step P3: 피라미딩 데이터셋 무결성 검증 (verify_pyramid_dataset.py)

> **입력**: `AI_Pyramid_Dataset.parquet` + 원본 파일들
> **검증 항목**:
> 1. Macro Shift+1 정합성
> 2. M5/H4 변화점 일관성
> 3. `label_pyramid` 컬럼 존재 및 값 분포 (0/1)
> 4. α 피처 6개 존재 및 NaN 비율
> 5. 절대값(OHLC, TickVolume) 누수 검증

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\verify_pyramid_dataset.py"
```

**검증 포인트**: 모든 항목 `✅ PASS` 확인

---

## ⚠️ 피라미딩 데이터 빌드 시 주의사항 (2026-03-11 실행 검증 완료)

> 아래 3가지는 실제 파이프라인 실행 시 발견된 설계 함정입니다.
> **Part A(진입 학습)에는 해당 없음** — α 피처는 "포지션 보유 중" 전제 위에 설계.

| # | 함정 | 원인 | 해결 (코드 반영 완료) |
|:---:|:---|:---|:---|
| W-1 | `price_vs_entry`가 `unrealized_pnl_atr`과 중복 | 동일 수식 → SHAP 분산 낭비 | `atr_expansion`(현재ATR/진입ATR) 교체 |
| W-2 | `bsp_scale_delta`가 `BOP_Scale` 참조 | 변수명과 실제 참조 불일치 | `LRAVGST_Avg(60)_BSPScale` 참조로 통일 |
| W-3 | Left Join 시 대부분 행 label=NaN | 조건부 학습에 불필요한 데이터 | **Inner Join** 채택 |

**추가 버그(실행 시 발견, 수정 완료)**:
- `tech_features_derived.parquet`: `time`(소문자) → `Time` rename 필요
- `macro_features.parquet`: `Date`가 index로 저장 → `reset_index()` + tz 제거 필요
- 라벨 Parquet에서 원본 OHLC/CE_CE2 컬럼이 병합 시 유입 → 라벨 DF 컬럼 필터(Time + label + α 6개만 선택) 추가

---

## 피라미딩 파이프라인 요약

```
[Part A 산출물 — 재사용]
  tech_features.parquet (62컬럼)
  tech_features_derived.parquet (165컬럼)
  macro_features.parquet (652컬럼)
  labels_barrier.parquet (Win 위치 참조)
          │
  Step P1: build_pyramid_labels_full.py          (~15분)
          │  (V2 로직 + α 피처 6개, IS+OOS 전구간)
          ▼
  labels_pyramiding_full.parquet
          │
  Step P2: merge_features_pyramid.py             (~60초)
          │  (Tech+Macro+PyramidLabel Inner Join)
          ▼
  AI_Pyramid_Dataset.parquet
          │
  Step P3: verify_pyramid_dataset.py
          │  (무결성 5/5 PASS)
          ▼
  ✅ 피라미딩 데이터 빌드 완료
```

---

## 스크립트 목록

### Part A: 롱전략 (Model_Entry)

| 스크립트 | 역할 | 위치 |
|:---|:---|:---|
| `build_micro_tech.py` | M1 CSV → 기술 지표 원본 (62컬럼) | `Files/Tools/` |
| `build_tech_derived.py` | 기술 지표 파생 변환 (165피처, pct240/pct1440 포함) | `Files/Tools/` |
| `build_labels_barrier.py` | Triple Barrier 라벨링 (Long전용, TP/SL=ATR×2.5, 30봉) | `Files/Tools/` |
| `merge_features.py` | 3개 Parquet 병합 (817컬럼, ~266만행) | `Files/Tools/` |
| `verify_merged_dataset.py` | 병합 무결성 검증 (5/5 PASS) | `Files/Tools/` |
| `train_round1.py` | 1라운드 (Spearman Pruning + LightGBM + SHAP Top-60) | `Files/Tools/` |
| `train_round2_ABC.py` | 2라운드 A+B+C 통합 (AUC=0.8298, 56.3%) | `Files/Tools/` |
| `extract_ABC_signals.py` | 신호 CSV 추출 (M30>35+thr=0.25) | `Files/Tools/` |

### Part B: 피라미딩 (Model_AddOn)

| 스크립트 | 역할 | 위치 |
|:---|:---|:---|
| `build_pyramid_labels_full.py` | 피라미딩 전체 구간 라벨링 + α 피처 6개 | `Files/Tools/` |
| `merge_features_pyramid.py` | 피라미딩 전용 Inner Join 병합 | `Files/Tools/` |
| `verify_pyramid_dataset.py` | 피라미딩 데이터셋 무결성 검증 (5/5 PASS) | `Files/Tools/` |

> 파라미터(ATR 배수 등)를 변경하려면 각 스크립트 상단의 설정 섹션을 수정 후 이 워크플로우를 재실행하세요.
> 라벨링만 단독 재실행하려면 `/data-label` 워크플로우를 사용하세요.
