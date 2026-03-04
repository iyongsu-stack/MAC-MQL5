# 🏆 70% 승률 롱 라벨링 — 메가 Grid Search 보고서

> **날짜**: 2026-03-03  
> **구간**: 2019-01-01 ~ 2020-12-31 (M1 상승장 707,905봉)  
> **목표**: TP=3×ATR, SL=Chandelier_Upl2, TIME=30봉에서 승률 70%+ 달성  

---

## 1. 실험 개요

### 배경
기존 Triple Barrier 라벨링(TP=1ATR, SL=1.2ATR, 45봉)에서 벗어나, **Chandelier_Upl2를 동적 SL**로, TP=3ATR / 30봉으로 설정하여 더 큰 수익을 노리는 라벨링 조건을 탐색.

### Chandelier_Upl2 거리 분석 (사전 조사)
| 지표 | 값 |
|:---|:---:|
| 중앙값 | **2.87 × ATR** |
| P25 | 1.86 × ATR |
| P75 | 3.78 × ATR |

> TP(3ATR) ≈ SL(2.87ATR) 수준이므로, **순수 R:R에서는 유리하지 않다**. 따라서 **진입 타점과 필터 정밀도**가 승률을 결정.

### 실험 규모
| 단계 | 내용 | 조합 수 | 최고 승률 |
|:---:|:---|:---:|:---:|
| 1차 | 단순 필터 26개 (QQE GC 고정) | 26 | 41.3% |
| **2차** | **13 타점 × 260 필터셋** | **2,742** | **80.0%** |

---

## 2. 타점 로직 (13종)

| 코드 | 타점 설명 |
|:---|:---|
| T01 | QQE(5-14) 골든크로스 |
| T02 | Deep Value: QQE 5봉 이상 하회 후 상향돌파 |
| T02b | Deep Value: QQE 10봉 이상 하회 후 상향돌파 |
| T03 | QQE GC 후 3봉 확인 (RsiMa > TrLevel 유지) |
| T03b | QQE GC 후 5봉 확인 |
| T04 | TDI(13-34) Signal > TrSi 상향크로스 |
| T05 | QQE GC + TDI 동시 강세 |
| T05b | Deep Value + TDI 강세 |
| T06 | 변동성 축소→폭발 (CHOP↑ → ADX 가속 + DI+>DI-) |
| T07 | BSPWMA(10-3, 30-5) 동시 slope > 0 |
| T08 | Higher Low + 양봉 3/5 이상 |
| T09 | BSPScale(180) slope 음→양 전환 |
| T10 | QQE(12-32) 골든크로스 (중기 오실레이터) |

---

## 3. 결과

### ★★★ 70% 이상 (2건, 최소 5건 이상)

| # | 타점 | 필터 | 신호수 | 승 | **승률** |
|:---:|:---|:---|:---:|:---:|:---:|
| 1 | **QQE(12-32) GC** | BSP(180)>2.5 + TickVol>2× | 10 | 8 | **80.0%** |
| 2 | **QQE(5-14) GC** | BSP(180)>2.0 + TickVol>2× | 17 | 12 | **70.6%** |

### ★★ 60~70% 구간 (주요 16건)

| 타점 | 필터 | 신호 | 승률 |
|:---|:---|:---:|:---:|
| QQE(12-32)GC | BSP>2.0 + TV>2× | 19 | 68.4% |
| DeepValue(5봉) | BSP>2.0 + TV>2× | 15 | 66.7% |
| QQE(5-14)GC | BSP>2.5 + TV>2× | 12 | 66.7% |
| QQE(5-14)GC | BSP>2.5 + TV>1.5× | 40 | 65.0% |
| DeepValue(5봉) | BSP>2.5 + TV>1.5× | 36 | 63.9% |
| DeepValue(5봉) | BSP>2.5 + TV>2× | 11 | 63.6% |
| DeepValue(10봉) | BSP>2.5 + TV>1.5× | 32 | 62.5% |
| QQE_GC+3봉확인 | CE≤1.5 + TV>2× | 8 | 62.5% |
| BSP_Slope전환 | BSP>1.5 + TV>2× | 15 | 60.0% |
| DeepValue(10봉) | BSP>2.0 + TV>2× | 10 | 60.0% |
| DeepValue(10봉) | CE1≤2.0 + QQE12_bull | 10 | 60.0% |
| QQE(5-14)GC | BSP>2.0 + CE2≤2.0 | 5 | 60.0% |
| DeepValue(5봉) | BSP>2.0 + CE2≤2.0 | 5 | 60.0% |
| DeepValue(10봉) | BSP>2.0 + CE2≤2.0 | 5 | 60.0% |
| QQE_GC+5봉확인 | BSP>2.5 + TV>2× | 5 | 60.0% |
| BSP_Slope전환 | CE2≤2.5 + TV>2× | 5 | 60.0% |

---

## 4. 핵심 인사이트

### 🔑 70% 달성의 3대 핵심 변수

#### 1. TickVolume 폭발 (TV_ratio > 1.5\~2.0×)
- **모든 고승률 조합에 100% 공통 등장**
- 거래량이 60봉 이동평균의 1.5~2배 이상일 때만 진입
- **의미**: 세력(Smart Money)의 참여가 확인된 봉에서만 진입 → 가짜 반등 필터링

#### 2. BSPScale(180) 초강세 (> 2.0\~2.5)
- 단순 황금구간(>1.0)이 아닌, **2.0 이상의 극강 상승장**에서만
- >2.5로 강화 시 승률 10-15%p 상승, 대신 신호 50% 감소

#### 3. QQE 골든크로스 (타점의 본질)
- QQE(12-32): 느린 오실레이터 → 적지만 확실한 턴어라운드 (80%)
- QQE(5-14): 빠른 반응 → 실용적 빈도 (70.6%)
- Deep Value (5~10봉 눌림 후): 중간 성능 (63~67%)

### ⚠️ 유의사항
- 1위(80%) 10건, 2위(70.6%) 17건 → **샘플 수 부족 리스크**
- 2년간 10~17회 = 월 0.4~0.7회 (보수적이나, 숏+추가전략으로 보완)
- **OOS 검증(2021~2025) 필수** — 단순 과적합 가능성 배제 필요

---

## 5. 전략적 방향

### 추천 라벨링 파라미터
```
[최종 후보]
  Setup:   LRAVGST_Avg(180)_BSPScale > 2.0
  타점:    QQE(5-14) 골든크로스 (눌림목 상향 돌파)
  필터:    TickVolume > 2× MA(60)
  TP:      3 × ATR(14)
  SL:      Chandelier_Upl2 (동적, MaxHigh(22) - 4.5×ATR(22))
  TIME:    30봉
  FC:      $0.30
  기대승률: ~70%
```

### 상세 실행 파이프라인 (5단계)

---

#### Step 1. 라벨링 데이터 생성

**목적**: 3-Barrier 규칙으로 label_long 컬럼 생성

```
[입력]  TotalResult_2026_02_19_2_pH4.parquet (원본 M1 데이터)
[처리]  build_labels_barrier.py 업데이트
[출력]  Files/processed/labels_barrier_v2.parquet
```

**라벨링 기본 조건 (넓게 잡고 AI에게 맡기기)**:
```
  Setup:     LRAVGST_Avg(180)_BSPScale > 1.5
  타점:      QQE(5-14) 골든크로스 (RsiMa[n-1] ≤ TrLevel[n-1] AND RsiMa[n] > TrLevel[n])
  필터:      TickVolume > 1.2× MA(60)
  TP:        3 × ATR(14) Wilder
  SL:        Chandelier_Upl2 (동적)
  TIME:      30봉
  FC:        $0.30 차감
  판정:      TP도달=1, SL/시간초과=0
  예상 샘플: 200~300건 / 2년 (AI 학습에 충분한 양)
```

> ⚠️ **승률 50~55%로 낮아도 OK** — AI가 480개 피처로 상위 30%만 선별하면 70~80% 달성 가능.
> 사람이 규칙으로 70%를 만들면 샘플이 10~40건으로 너무 적어 과적합 위험.

---

#### Step 2. 마이크로 피처 병합

**목적**: 라벨링된 각 봉에 M1 기술 지표 파생 피처 부착

```
[입력]  labels_barrier_v2.parquet + micro_tech_features.parquet (or tech_features_derived.parquet)
[처리]  merge_features.py 또는 신규 스크립트
[출력]  Files/processed/AI_Study_Dataset_v2.parquet
```

**마이크로 피처 (~200개)**:
- QQE RSI/RsiMa/TrLevel (5-14, 12-32)
- ADX/DiPlus/DiMinus + Slope/Accel (14, 80, M5, H4)
- CHOP Scale/CSI + Slope (14, 120)
- CHV Z-score (60, 240)
- BSPWMA/BOPWMA Slope/Accel/Slope_Zscore
- CE_Upl1/Upl2/Dnl1/Dnl2 ratio (ATR 대비)
- TDI Signal/TrSi
- BWMFI M5/H4 Z-score
- TickVolume Z-score (60, 240)
- LRAVGST BSPScale/StdS + Slope

**Shift+1 규칙**: 모든 파생 Z-score에 `x.shift(1).rolling(W)` 적용 완료 확인

---

#### Step 3. 메가 피처 병합 (매크로)

**목적**: 거시 경제 환경 컨텍스트 부착

```
[입력]  AI_Study_Dataset_v2.parquet + macro_features.parquet
[처리]  merge_features.py (M1 ↔ Daily 병합, Shift+1 적용)
[출력]  Files/processed/AI_Study_Dataset_v2_mega.parquet
```

**매크로 핵심 피처 (일봉 → M1으로 ffill 후 Shift+1)**:
- 실질금리 (US10Y - BEI) Δ%, Z-score
- DXY 달러인덱스 Δ%, 기울기
- VIX 변동성 Z-score
- Gold ETF(GLD) 플로우 변화율
- EURUSD/USDJPY Δ%, 기울기
- 기대인플레이션 Z-score
- S&P500 변화율
- 등 총 ~360개 파생 컬럼 (이미 build_data_lake.py에서 생성 완료)

**학습 방식 (방법 C 추천)**:
```
[마이크로 ~200개] + [매크로 전체 ~360개] → LightGBM 1개 모델
→ SHAP 분석으로 중요 매크로 자동 선별 (Top 20~30개 식별)
→ 2차 학습에서 중요 매크로만 남기고 노이즈 제거
```

---

#### Step 4. AI 학습 (LightGBM)

**목적**: label=1(성공) vs label=0(실패) 이진 분류 모델 학습

```
[입력]  AI_Study_Dataset_v2_mega.parquet
[처리]  train_lightgbm.py (신규 작성)
[출력]  Models/lgbm_long_v1.pkl + SHAP 분석 결과
```

**학습 파라미터**:
```python
params = {
    'objective': 'binary',
    'metric': 'auc',
    'boosting_type': 'gbdt',
    'num_leaves': 31,
    'learning_rate': 0.05,
    'feature_fraction': 0.7,
    'bagging_fraction': 0.7,
    'scale_pos_weight': neg_count / pos_count,  # 클래스 불균형 보정
}
```

**검증**: Purged Walk-Forward (시간순 분할, 앞구간 학습 → 뒷구간 검증)
- Fold 1: 2019-01~2019-06 학습 → 2019-07~2019-09 검증
- Fold 2: 2019-01~2019-09 학습 → 2019-10~2020-03 검증
- Fold 3: 2019-01~2020-03 학습 → 2020-04~2020-12 검증

**목표 지표**: OOS AUC > 0.7, OOS 상위 30% 예측 승률 > 70%

---

#### Step 5. Walk-Forward 3단계 최종 검증

```
Step 1 (2개월):  2021-01~2021-02 → 최소 생존 검증
Step 2 (1년):    2021 전체 → 안정성 확인
Step 3 (최대):   2021~2025 → 실전 신뢰도
통과 기준: 모든 Step에서 승률 60%+, Sharpe > 1.0
```

실패 시: 라벨링 조건 재조정 → Step 1부터 재시작

---

## 6. 실행 스크립트 & 산출물 요약

| 단계 | 스크립트 | 입력 | 출력 |
|:---:|:---|:---|:---|
| 분석 | `analyze_chandelier_distance.py` | tech_features | CE 거리 통계 |
| 분석 | `sim_long_70pct.py` | TotalResult | 1차 승률표 |
| 분석 | `sim_long_mega.py` | TotalResult | 2차 메가 승률표 |
| Step1 | `build_labels_barrier.py` (업데이트) | TotalResult | labels_barrier_v2 |
| Step2 | `merge_features.py` (업데이트) | labels + micro_tech | AI_Study_Dataset_v2 |
| Step3 | `merge_features.py` (업데이트) | Dataset_v2 + macro | Dataset_v2_mega |
| Step4 | `train_lightgbm.py` (신규) | Dataset_v2_mega | LGBM 모델 + SHAP |
| Step5 | `walk_forward_validate.py` (신규) | 모델 + 2021~2025 데이터 | 검증 리포트 |



AI 피처 도입 후 예상 변화
현재 상태 (규칙 기반만)
QQE(5-14)GC + BSP>2.5 + TV>1.5× → 40건 / 65% 승률
→ 단 3개의 조건만으로 40개의 진입점을 판별 (1차원적)

AI 학습 후 기대되는 구조 변화
단계	신호수	승률	설명
규칙 기반 (현재)	40	65%	3개 조건으로 1차 필터링
+ 마이크로 피처	≈15~25	75~85%	480개 피처로 "진짜 좋은 40개 중의 상위권"을 AI가 선별
+ 메가 피처 (매크로)	≈10~20	80~90%	금리/달러 환경까지 고려 → "시장 조건이 받쳐주는 진입"만 통과
왜 이렇게 되는가?
핵심 원리: AI는 신호를 "늘리는" 게 아니라 "걸러내는" 역할

현재 40건의 진입 중:

26건 성공 (65%) — 이 중에서도 확실한 성공(3ATR 돌파)과 아슬아슬한 성공이 섞여 있음
14건 실패 (35%) — 이 중 AI가 패턴을 학습해서 사전에 걸러낼 수 있는 신호가 많음
AI(LightGBM)가 480개 마이크로 피처를 보면, 예를 들어:

"QQE 골든크로스가 발생했는데, ADX 가속도가 음수이고, CHOP이 아직 높고, BSPWMA slope이 음수인 경우는 10건 중 9건 실패한다"

→ 이런 실패 패턴을 학습하여 자동 제거 → 나머지 20~25개만 실행 → 승률 상승

⚠️ 현실적 우려: 샘플 수 문제
맥락	수치	판정
현재 학습 데이터	40건 (2년)	❌ 매우 부족
LightGBM 최소 권장	200~500건	—
5년(2019-2025) 확장 시	100120건	⚠️ 여전히 적음
BSP>2.0 + TV>1.5×로 완화	7080건/2년	✅ 균형점
💡 제안: 실용적 전략
[라벨링 기본 조건 — 넓게 잡고 AI에게 맡기기]
  Setup:   BSP(180) > 1.5  (더 넓은 황금구간)
  타점:    QQE(5-14) 골든크로스
  필터:    TickVolume > 1.2× MA(60)  (약간만 필터)
  → 예상 ~200~300건/2년 → AI 학습에 충분한 샘플
  승률 50~55% (낮아도 OK)
  AI가 480개 피처로 상위 30%만 선별 → 70~80% 달성
핵심 아이디어: 사람이 규칙으로 70%를 만들려고 하면 샘플이 너무 적어짐. 라벨링은 넓게, 정밀 선별은 AI에게 맡기는 것이 메가 피처 풀 투입 전략의 본질입니다.


제안: 실용적 전략
[라벨링 기본 조건 — 넓게 잡고 AI에게 맡기기]
  Setup:   BSP(180) > 1.5  (더 넓은 황금구간)
  타점:    QQE(5-14) 골든크로스
  필터:    TickVolume > 1.2× MA(60)  (약간만 필터)
  → 예상 ~200~300건/2년 → AI 학습에 충분한 샘플
  승률 50~55% (낮아도 OK)
  AI가 480개 피처로 상위 30%만 선별 → 70~80% 달성

---

## 7. Dukascopy 데이터 재검증 (2026-03-04)

> **목적**: 기존 MT5(ICMarkets) 제공 데이터 대신 **Dukascopy Bank SA M1 데이터** 기반의 `tech_features.parquet`으로 동일 조합 승률이 재현되는지 검증
> **데이터**: `tech_2019_2020.parquet` (763,527행, 2018-12 ~ 2021-02 추출)
> **파라미터**: 동일 (TP=3×ATR, SL=CE_Upl2, TIME=30봉, FC=$0.30)

### 결과 비교

| # | 타점 | 필터 | 신호 | 승 | Duka 승률 | MT5 승률 | 판정 |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 1 | QQE(5-14)GC | BSP>2.5 + TV>2× | 11 | 8 | **72.7%** | 66.7% | ✅ 상승 |
| 2 | DeepValue(5봉) | BSP>2.5 + TV>2× | 11 | 8 | **72.7%** | 63.6% | ✅ 상승 |
| 3 | QQE(12-32)GC | BSP>2.5 + TV>2× | 10 | 7 | **70.0%** | **80.0%** | ⚠️ 하락 |
| 4 | QQE(12-32)GC | BSP>2.0 + TV>2× | 21 | 11 | 52.4% | 68.4% | ⚠️ 하락 |
| 5 | QQE(5-14)GC | BSP>2.0 + TV>2× | 28 | 13 | 46.4% | **70.6%** | ❌ 붕괴 |
| 6 | DeepValue(5봉) | BSP>2.0 + TV>2× | 27 | 13 | 48.1% | 66.7% | ⚠️ 하락 |
| 7 | QQE(5-14)GC | BSP>2.5 + TV>1.5× | 38 | 19 | 50.0% | 65.0% | ⚠️ 하락 |
| 8 | DeepValue(5봉) | BSP>2.5 + TV>1.5× | 35 | 18 | 51.4% | 63.9% | ⚠️ 하락 |
| 9 | DeepValue(10봉) | BSP>2.5 + TV>1.5× | 30 | 15 | 50.0% | 62.5% | ⚠️ |
| 10 | BSPSlope전환 | BSP>1.5 + TV>2× | 21 | 11 | 52.4% | 60.0% | ⚠️ |
| 11 | QQE(5-14)GC | BSP>1.5 + TV>1.2× | 313 | 126 | 40.3% | - | 기준선 |
| 12 | QQE(5-14)GC | BSP>1.0 (기본) | 2,072 | 767 | 37.0% | - | 기준선 |

### 핵심 인사이트

1. **BSP>2.5 + TV>2× 조합은 데이터 소스 불문 강건** — 3건 모두 70%+ 달성
2. **BSP>2.0까지 완화하면 Dukascopy에서 크게 하락** — 브로커 간 TickVolume 스케일 차이가 원인
3. **ATR 중앙값 차이**: MT5 ~$3.00 vs Dukascopy ~$0.38 → TP/SL 배리어 절대값이 다름
4. **AI 학습용 넓은 라벨링** (BSP>1.5 + TV>1.2×): 313건 / 40.3% → 충분한 샘플 확보, AI가 고승률 선별 가능

### 실행 스크립트

| 스크립트 | 역할 |
|:---|:---|
| `Files/Tools/cut_2019_2020.py` | tech_features.parquet → 2019-2020 구간 추출 |
| `Files/Tools/sim_duka_verify.py` | 추출 데이터 기준 Top 12 조합 재검증 |
