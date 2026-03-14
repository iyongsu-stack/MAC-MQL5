# 데이터 명세서 — BSP_Long_v1 EA 데이터 흐름

> 최종 업데이트: 2026-03-14
> 범위: EA에 입력되는 원시 데이터 → 가공된 피처 벡터 → 추론 엔진 출력

---

## 데이터 흐름 개요

```
┌─────────────────────────────────────────────────────────────────┐
│                    1계층: EA 입력 (Raw Data)                      │
│                                                                  │
│  ┌──────────────┐  ┌───────────────┐  ┌───────────────────────┐ │
│  │ 22개 커스텀   │  │ macro_latest  │  │ event_calendar.csv    │ │
│  │ 지표 + iATR   │  │   .csv        │  │                       │ │
│  │ + TickVolume  │  │ (~20 피처)     │  │ (FOMC/NFP/CPI/PCE)   │ │
│  │ + Close Price │  │               │  │                       │ │
│  └──────┬───────┘  └──────┬────────┘  └──────────┬────────────┘ │
│         │                 │                       │              │
└─────────┼─────────────────┼───────────────────────┼──────────────┘
          │                 │                       │
          ▼                 ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│               2계층: 가공 파이프라인 (CFeatureEngine)             │
│                                                                  │
│  Raw → CRollingStats [36+3 인스턴스] ← 롱/숏 공유 가능           │
│  → ZScore / PctRank / Slope / Accel / Ratio / Passthrough 변환   │
│  + CMacroLoader에서 매크로 피처 병합                               │
│  + 레짐 인식 피처 4개 계산                                         │
│  + (AddOn 전용) 동적 포지션 피처 7개 계산                           │
│                                                                  │
│  ┌──────────────────────┐  ┌──────────────────────┐              │
│  │ float features[80]   │  │ float features[77]   │              │
│  │ (Long Entry 벡터)    │  │ (Long AddOn 벡터)    │              │
│  └──────────┬───────────┘  └──────────┬───────────┘              │
│                                                                  │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐  [미래 확장]│
│  │ float features[N]    │  │ float features[M]    │              │
│  │ (Short Entry 벡터)   │  │ (Short AddOn 벡터)   │              │
│  └ ─ ─ ─ ─ ┬ ─ ─ ─ ─ ─┘  └ ─ ─ ─ ─ ┬ ─ ─ ─ ─ ─┘              │
└─────────────┼──────────────────────────┼─────────────────────────┘
              │                          │
              ▼                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                   3계층: 추론 출력 (COnnxPredictor)               │
│                                                                  │
│  model_long_ABC.onnx        model_addon_ABC.onnx                │
│  → P(Win) 0.0~1.0           → P(Win) 0.0~1.0                   │
│                                                                  │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ [미래]    │
│  │ model_short_ABC.onnx    model_short_addon.onnx   │           │
│  │ → P(Win) 0.0~1.0        → P(Win) 0.0~1.0        │           │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘           │
│                                                                  │
│  ┌──────────────────────────────────────────────────┐           │
│  │ CSignalGenerator.Evaluate()                      │           │
│  │ → SIGNAL_ENTRY / SIGNAL_ADDON / SIGNAL_NONE      │           │
│  │ + reason 문자열                                   │           │
│  └──────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

> **숏 모델 확장 시 2계층 고려사항 (Deferred)**
>
> | 항목 | 현재 (롱) | 숏 확장 시 변경점 |
> |:---|:---|:---|
> | CRollingStats | 36+3 인스턴스 | **공유 가능** (동일 Raw 데이터) |
> | PctRank 연산 | Idx(1) 지연 랭크 (A안) | ⚠️ **A/B 실험 결과에 따라 Idx(0) 가능** |
> | SHAP 선별 | Entry 80 / AddOn 77 | **다른 피처 조합** (숏에 유리한 피처) |
> | FeatureSchema | `ENUM_ENTRY_FEATURE` | `ENUM_SHORT_ENTRY_FEATURE` 별도 추가 |
> | 매크로 피처 | ~20개 | 숏용 SHAP 결과에 따라 **다른 서브셋** |
> | 피처 벡터 메서드 | `GetEntryFeatures()` | `GetShortEntryFeatures()` 추가 |

---

## 1계층: EA 입력 데이터 (Raw Data)

### 1.1 커스텀 지표 (22개 핸들, M1 완성봉 Shift=1)

> **Rule_Shift+1**: 상위 TF 지표도 M1으로 접근 시 Shift=1 (직전 완성봉). 미래 참조 완전 차단.

| # | 지표 (iCustom) | 버퍼 수 | 추출 Raw 값 | 타입 |
|:---:|:---|:---:|:---|:---|
| 1 | `ADXSmooth(14)` | 4 | DiPlus, DiMinus, ADX, Avg | 추세/방향성 |
| 2 | `ADXSmooth(80)` | 4 | DiPlus, DiMinus, ADX, Avg | 장기 추세 |
| 3 | `ADXMTF_M5` | 3 | DiPlus, DiMinus, ADX | M5 멀티TF 방향 |
| 4 | `ADXMTF_H4` | 3 | DiPlus, DiMinus, ADX | H4 멀티TF 방향 |
| 5 | `iATR(14)` | 1 | ATR14 | 변동성 |
| 6 | `BOPAvgStd(30,5)` | 2 | BOP, Scale | 매수/매도 압력 |
| 7 | `BSPWmaSmooth(10,3)` | 1 | BSPScale | 단기 추세강도 |
| 8 | `BSPWmaSmooth(30,5)` | 1 | BSPScale | 장기 추세강도 |
| 9 | `BWMFI_MTF_M5` | 2 | BWMFI, Color | M5 시장촉진지수 |
| 10 | `BWMFI_MTF_H4` | 2 | BWMFI, Color | H4 시장촉진지수 |
| 11 | `ChandelierExit(22,4.5)` | 2 | CE_SL1(Long), CE_SL2(Short) | 트레일링 기준 |
| 12 | `ChaikinVolatility(10,10)` | 2 | CHV, StdDev | 변동성 변화율 |
| 13 | `ChaikinVolatility(30,30)` | 1 | CHV | 장기 변동성 |
| 14 | `ChoppingIndex(14,14)` | 2 | Scale, CSI | 레인지/추세 판별 |
| 15 | `ChoppingIndex(120,40)` | 2 | Scale, CSI | 장기 레인지 판별 |
| 16 | `LRAVGSTD(60)` | 1 | StdS | 회귀선 표준편차 |
| 17 | `LRAVGSTD(180)` | 2 | StdS, BSPScale | 장기 회귀 |
| 18 | `LRAVGSTD(240)` | 1 | StdS | 초장기 회귀 |
| 19 | `QQE(5,14)` | 1 | TrLevel | 빠른 QQE |
| 20 | `QQE(12,32)` | 1 | RSI | 느린 QQE |
| 21 | `TDI(13,34,2,7)` | 1 | Signal | 빠른 TDI |
| 22 | `TDI(14,90,35)` | 2 | Signal, TrSi | 느린 TDI |

**총 Raw 슬롯: 36개** (ENUM_RAW_SLOT)

### 1.2 가격 데이터 (MT5 내장)

| 데이터 | 소스 | 용도 |
|:---|:---|:---|
| Close(Shift=1) | `iClose(_Symbol, M1, 1)` | CE 거리, 모멘텀, 레짐 피처 |
| TickVolume(Shift=1) | `iVolume(_Symbol, M1, 1)` | 거래량 파생 피처 |
| Bid/Ask | `SymbolInfoDouble` | 매 틱 Virtual Stop 체크 |
| AccountBalance | `AccountInfoDouble` | 랏 사이즈 계산 |

### 1.3 매크로 데이터 (CSV, 일 1회 갱신)

> **참고**: Data Lake 2계층(`macro_features.parquet`)에는 60개 원본 × 파생 변환 = **652개** 매크로 피처 풀이 존재하지만,
> SHAP 피처 선택을 거쳐 최종 모델에 투입되는 것은 **Entry 5개 + AddOn 18개 = 고유 ~20개**뿐이다.
> EA의 `macro_latest.csv`에는 이 선별된 피처만 포함된다.

| 항목 | 상세 |
|:---|:---|
| **파일** | `Files/processed/macro_latest.csv` |
| **원본 소스** | Yahoo Finance 41개 + FRED 19개 = 60개 |
| **Data Lake 풀** | 652개 (파생 변환: Δ%, Z-score, Slope, Accel, pct 등) |
| **EA 로드 피처** | **~20개** (SHAP 선별분만 — Entry 5개 + AddOn 18개, 중복 제외) |
| **갱신** | Python Companion이 매일 장 마감 후 생성 |
| **NaN 처리** | ffill (전일 값 유지). bfill 절대 금지 |
| **EA 적용 시점** | 날짜 변경 감지 시 LoadForDate() 1회 호출 |

**Entry 모델에 사용되는 매크로 피처 (6개):**

| 피처명 | 원본 소스 | 변환 |
|:---|:---|:---|
| `GOLD_zscore_240` | Yahoo Finance (GC=F) | Z-score(240일) |
| `GOLD_slope` | Yahoo Finance (GC=F) | Slope(5일) |
| `MXUS_FR_ret1d` | Yahoo Finance (^MXUS_FR) | 1일 수익률(Δ%) |
| `DAX_ret1d` | Yahoo Finance (^GDAXI) | 1일 수익률 |
| `COFFEE_accel` | Yahoo Finance (KC=F) | 가속도 |

**AddOn 모델에 사용되는 매크로 피처 (18개):**

| 피처명 | 원본 소스 | 변환 |
|:---|:---|:---|
| `GAS_slope` | Yahoo Finance (NG=F) | Slope |
| `DOW_ret21d` | Yahoo Finance (^DJI) | 21일 수익률 |
| `SOYBEAN_zscore_60` | Yahoo Finance (ZS=F) | Z-score(60일) |
| `TIPS10Y_ma_ratio_1440` | FRED (DFII10) | MA 비율(1440) |
| `SUGAR_slope` | Yahoo Finance (SB=F) | Slope |
| `TIPS10Y_ret1d` | FRED (DFII10) | 1일 수익률 |
| `COTTON_accel` | Yahoo Finance (CT=F) | 가속도 |
| `WHEAT_ret1d` | Yahoo Finance (ZW=F) | 1일 수익률 |
| `WHEAT_ret5d` | Yahoo Finance (ZW=F) | 5일 수익률 |
| `SUGAR_zscore_60` | Yahoo Finance (SB=F) | Z-score(60일) |
| `DOW_ret5d` | Yahoo Finance (^DJI) | 5일 수익률 |
| `VIX_FRED_accel` | FRED (VIXCLS) | 가속도 |
| `SUGAR_ret21d` | Yahoo Finance (SB=F) | 21일 수익률 |
| `USDTRY_accel` | Yahoo Finance (TRY=X) | 가속도 |
| `WTI_FRED_ma_ratio_1440` | FRED (DCOILWTICO) | MA 비율(1440) |
| `FTSE_accel` | Yahoo Finance (^FTSE) | 가속도 |
| `WTI_FRED_ma_ratio_240` | FRED (DCOILWTICO) | MA 비율(240) |
| `BEI10Y_ret5d` | FRED (T10YIE) | 5일 수익률 |
| `FTSE_ma_ratio_1440` | Yahoo Finance (^FTSE) | MA 비율(1440) |
| `UST3M_accel` | FRED (DGS3MO) | 가속도 |

### 1.4 이벤트 캘린더 (CSV, 수동/반자동)

| 항목 | 상세 |
|:---|:---|
| **파일** | `Files/processed/event_calendar.csv` |
| **컬럼** | `date, time_et, event_type, tier, before_hours, after_hours` |
| **Tier 1 이벤트** | FOMC, NFP, CPI, PCE |
| **용도** | 신규 진입 차단 (기존 포지션 유지) |
| **현재 상태** | `UseEventFilter = false` (시뮬 결과 OFF 우위) |

---

## 2계층: 가공 피처 (Feature Engineering → 추론 입력)

### 2.1 파생 변환 유형 (Rule_No_Absolute_Values)

| 변환 유형 | 표기법 | 연산 | MQL5 함수 |
|:---|:---|:---|:---|
| **Z-Score** | `_zscore60`, `_zscore240` | (x − mean) / std, Shift+1 | `CRollingStats::GetZScore(w)` |
| **PctRank** | `_pct240`, `_pct1440` | 롤링 퍼센타일 랭크, Shift+1 | `CRollingStats::GetPctRank(w)` |
| **Slope** | `_slope5`, `_slope14` | (x[0] − x[n]) / n | `CRollingStats::GetSlope(w)` |
| **Accel** | `_accel14` | slope_curr − slope_prev | `CRollingStats::GetAccel(s,a)` |
| **Ratio** | `_dist_ATR`, `_ratio_MA` | a / b (SafeDiv) | 직접 계산 |
| **Passthrough** | (접미사 없음) | 원본 그대로 (스케일 오실레이터) | `m_raw[slot]` |
| **동적 pct** | `_pct` (v2 아님) | 파생값의 PctRank | `GetPctRank` 재적용 |

### 2.2 Entry 모델 피처 벡터 (`float[80]`)

> 순서는 `FeatureSchema.mqh` ENUM_ENTRY_FEATURE 기준 (SHAP 중요도 내림차순)

| Idx | 피처명 | 원본 Raw | 변환 | 카테고리 |
|:---:|:---|:---|:---|:---|
| 0 | `CE_SL2_dist_ATR` | CE_SL2, Close, ATR14 | (Close−CE_SL2)/ATR | CE 거리비율 |
| 1 | `CE_Dist2_slope14` | CE_dist2 | Slope(14) | CE 추세모멘텀 |
| 2 | `QQE_(5-14)_TrLevel` | QQE(5,14) buf0 | Passthrough | 모멘텀 |
| 3 | `ADXMTF_H4_DiPlus_pct240` | ADXMTF_H4 DiPlus | PctRank(240) | H4 방향성 |
| 4 | `QQE_(12-32)_RSI` | QQE(12,32) buf0 | Passthrough | 모멘텀 |
| 5 | `ADXMTF_M5_DiPlus` | ADXMTF_M5 DiPlus | Passthrough | M5 방향성 |
| 6 | `LRAVGST_Avg(180)_StdS_slope14` | LRAVG(180) StdS | Slope(14) | 회귀 표준편차 |
| 7 | `BWMTF_H4_BWMFI_zscore20cp` | BWMFI_MTF_H4 | ZScore(20) | H4 시장촉진 |
| 8 | `CE_Dist1_zscore60` | CE_dist1 | ZScore(60) | CE 거리분포 |
| 9 | `TDI_(14-90-35)_Signal` | TDI(14,90,35) Signal | Passthrough | 추세강도 |
| 10 | `CE_Dist1_slope14` | CE_dist1 | Slope(14) | CE 모멘텀 |
| 11 | `CE_SL2_squeeze` | CE_SL1, CE_SL2 | (SL1−SL2)/ATR | CE 채널폭 |
| 12 | `LRAVGST_Avg(180)_BSPScale` | LRAVG(180) BSPScale | Passthrough | 회귀 스케일 |
| 13 | `ADXMTF_M5_DiMinus` | ADXMTF_M5 DiMinus | Passthrough | M5 역방향 |
| 14 | `BWMTF_M5_Color` | BWMFI_MTF_M5 Color | Passthrough | M5 시장상태 |
| 15 | `BWMTF_M5_BWMFI_zscore60cp` | BWMFI_MTF_M5 | ZScore(60) | M5 시장촉진 |
| 16 | `ADXS_(80)_DiMinus` | ADXSmooth(80) DiMinus | Passthrough | 장기역방향 |
| 17 | `TickVolume_zscore1440` | TickVolume | ZScore(1440) | 거래량 |
| 18 | `ADXS_(80)_DiPlus` | ADXSmooth(80) DiPlus | Passthrough | 장기방향 |
| 19 | `BSP_(10-3)_accel14` | BSP(10,3) | Accel(14) | 단기추세가속 |
| 20 | `ADXS_(80)_DiPlus_pct240` | ADXSmooth(80) DiPlus | PctRank(240) | 장기방향분포 |
| 21 | `CE_SL1_slope5` | CE_SL1 | Slope(5) | CE 단기추세 |
| 22 | `LRAVGST_Avg(60)_StdS_slope14` | LRAVG(60) StdS | Slope(14) | 회귀변동 |
| 23 | `BWMTF_H4_BWMFI_pct240cp_v2` | BWMFI_MTF_H4 | PctRank(240) | H4 촉진분포 |
| 24 | `ATR14` | iATR(14) | Passthrough | 절대변동성 |
| 25 | `BWMTF_H4_Color` | BWMFI_MTF_H4 Color | Passthrough | H4 시장상태 |
| 26 | `CHOP_(120-40)_Scale` | CHOP(120,40) Scale | Passthrough | 장기 레인지 |
| 27 | `ADXMTF_H4_DiPlus` | ADXMTF_H4 DiPlus | Passthrough | H4 방향 |
| 28 | `BWMTF_H4_BWMFI_slope5cp` | BWMFI_MTF_H4 | Slope(5) | H4 촉진단기 |
| 29 | `ADXS_(80)_ADX` | ADXSmooth(80) ADX | Passthrough | 장기추세강도 |
| 30 | `ADXMTF_M5_DiPlus_slope14cp` | ADXMTF_M5 DiPlus | Slope(14) | M5 방향변화 |
| 31 | `ADXMTF_M5_DiMinus_slope14cp` | ADXMTF_M5 DiMinus | Slope(14) | M5 역변화 |
| 32 | `ADXS_(80)_DiMinus_pct240` | ADXSmooth(80) DiMinus | PctRank(240) | 역방향분포 |
| 33 | `ADXMTF_H4_DiPlus_slope5cp_pct240` | ADXMTF_H4 slope5cp | PctRank(240) | 2차 파생 |
| 34 | `BWMTF_M5_BWMFI_slope14cp` | BWMFI_MTF_M5 | Slope(14) | M5 촉진모멘텀 |
| 35 | `BOP_(30-5)_slope14_pct240` | BOP slope14 | PctRank(240) | 매수압력분포 |
| 36 | `ADXMTF_H4_DiPlus_slope5cp` | ADXMTF_H4 DiPlus | Slope(5) | H4 방향단기 |
| 37 | `CHOP_(14-14)_CSI` | CHOP(14,14) CSI | Passthrough | 레인지 강도 |
| 38 | `ADXS_(14)_DiPlus_pct240` | ADXSmooth(14) DiPlus | PctRank(240) | 단기방향분포 |
| 39 | `price_mom_10` | Close | (Close[0]−Close[10])/ATR | 가격모멘텀 |
| 40 | `CHV_(10-10)_StdDev_zscore1440` | CHV(10,10) StdDev | ZScore(1440) | 변동성분포 |
| 41 | `BSP_(30-5)_accel14` | BSP(30,5) | Accel(14) | 장기추세가속 |
| 42 | `CHV_(10-10)_StdDev_zscore60` | CHV(10,10) StdDev | ZScore(60) | 단기변동성 |
| 43 | `ADXS_(80)_ADX_pct240` | ADXSmooth(80) ADX | PctRank(240) | 추세강도분포 |
| 44 | `CE_SL1_squeeze` | CE_SL1, CE_SL2 | (CE_SL2−Close)/ATR | CE 스퀴즈 |
| 45 | `ADXS_(80)_Avg` | ADXSmooth(80) Avg | Passthrough | 장기 평균 |
| 46 | `BOP_Scale` | BOP(30,5) Scale | Passthrough | 매수/매도 압력 |
| 47 | `ADXS_(14)_DiMinus_pct240` | ADXSmooth(14) DiMinus | PctRank(240) | 역방향분포 |
| 48 | `ATR14_zscore30` | ATR14 | ZScore(30) | ATR 단기분포 |
| 49 | `GOLD_zscore_240` | macro CSV | **매크로** | 금 가격분포 |
| 50 | `ADXMTF_H4_DiMinus_slope5cp` | ADXMTF_H4 DiMinus | Slope(5) | H4 역방향단기 |
| 51 | `LRAVGST_Avg(240)_StdS_pct240_v2` | LRAVG(240) StdS | PctRank(240) | 회귀변동분포 |
| 52 | `MXUS_FR_ret1d` | macro CSV | **매크로** | 신흥시장수익률 |
| 53 | `TickVolume_zscore1440_pct1440` | TickVol zscore1440 | PctRank(1440) | 2차 파생 |
| 54 | `LRAVGST_Avg(180)_StdS_pct240_v2` | LRAVG(180) StdS | PctRank(240) | 회귀변동분포 |
| 55 | `ATR14_pct240` | ATR14 | PctRank(240) | 변동성 위치 |
| 56 | `CHV_(30-30)_CHV_zscore240` | CHV(30,30) CHV | ZScore(240) | 장기변동성분포 |
| 57 | `DAX_ret1d` | macro CSV | **매크로** | DAX 수익률 |
| 58 | `GOLD_slope` | macro CSV | **매크로** | 금 추세 |
| 59 | `COFFEE_accel` | macro CSV | **매크로** | 커피 가속도 |
| 60~75 | *(동적 pct 변환)* | 위 피처들 | PctRank(240) | 분포 정규화 |
| 76 | `regime_monthly_pct` | Close | PctRank(long window) | 레짐 인식 |
| 77 | `regime_weekly_up_ratio` | Close | 주간 상승 비율 | 레짐 인식 |
| 78 | `regime_above_ma20w` | Close | MA20W 위 여부 | 레짐 인식 |
| 79 | `regime_bull_flag` | 합성 | 강세장 플래그 | 레짐 인식 |

### 2.3 AddOn 모델 피처 벡터 (`float[77]`)

**Entry와의 차이점:**

| 구분 | Entry (80개) | AddOn (77개) |
|:---|:---|:---|
| 기술 지표 파생 | 56개 | ~48개 (일부 상이) |
| 매크로 | 5개 | 18개 (★ 더 많음) |
| 레짐 | 4개 | 4개 (동일) |
| 동적 포지션 | 없음 | **7+7=14개** ★ |
| 동적 pct | 16개 | 10개 |

**AddOn 전용 — 동적 포지션 피처 (CTradeExecutor 제공):**

| 피처명 | Idx | 계산식 | 설명 |
|:---|:---:|:---|:---|
| `addon_count` | 29 | 현재 피라미딩 횟수 (0~3) | 정수 |
| `atr_expansion` | 34 | currentATR / entryATR | ATR 확장률 |
| `bsp_scale_delta` | 37 | currentBSP − entryBSP | 추세강도 변화 |
| `trend_acceleration` | 45 | slope_curr − slope_prev | 추세 가속도 |
| `unrealized_pnl_atr` | 56 | (bid − entryPrice) / entryATR | 미실현수익 ATR배수 |
| `bars_since_entry` | 60 | 현재봉 − 진입봉 | 경과 봉 수 |
| `*_pct` (6개) | 68~72 | 위 동적 피처의 PctRank(240) | 분포 정규화 |

---

## 3계층: 추론 엔진 출력 (Inference Output)

### 3.1 COnnxPredictor 출력

| 출력 | 타입 | 범위 | 설명 |
|:---|:---|:---|:---|
| `P(Win)` Entry | `float` | 0.0 ~ 1.0 | 롱 진입 성공 확률 |
| `P(Win)` AddOn | `float` | 0.0 ~ 1.0 | 피라미딩 추가 성공 확률 |
| `Status` | `float` | -1.0 | NaN/INF 감지 시 거부 |

> **ONNX 내부**: `output[0]` = 예측 라벨 (int64), `output[1]` = `[P(class=0), P(class=1)]` (float[2])
> → EA는 `output[1][1]` = P(Win)만 사용

### 3.2 CSignalGenerator 최종 출력

```
┌────────────────────────────────────────────────────────────────┐
│                        Evaluate() 입력                          │
├────────────────────────────────────────────────────────────────┤
│ probEntry      : float  ← COnnxPredictor (Entry 모델)          │
│ probAddon      : float  ← COnnxPredictor (AddOn 모델)          │
│ hasPosition    : bool   ← CTradeExecutor                       │
│ addonCount     : int    ← CTradeExecutor (0~3)                 │
│ unrealizedATR  : float  ← CTradeExecutor                       │
│ barsSinceLast  : int    ← CTradeExecutor                       │
│ isBlackout     : bool   ← CEventFilter                         │
│ isWarmupReady  : bool   ← CFeatureEngine                       │
├────────────────────────────────────────────────────────────────┤
│                        Evaluate() 출력                          │
├────────────────────────────────────────────────────────────────┤
│ signal         : ENUM_SIGNAL  (NONE=0, ENTRY=1, ADDON=2)       │
│ reason         : string       (판단 사유)                       │
└────────────────────────────────────────────────────────────────┘
```

### 3.3 CTradeExecutor 실행 출력 (주문 결과)

| 출력 | 발생 조건 | 데이터 |
|:---|:---|:---|
| **Entry 주문** | SIGNAL_ENTRY | lots, emergencySL, virtualSL, entryPrice, entryATR |
| **AddOn 주문** | SIGNAL_ADDON | lots(감소), addonCount++, 1차 SL 유지 |
| **Virtual SL 청산** | bid ≤ virtualSL | CloseAll, reason="Virtual SL hit" |
| **CE2 청산** | bid ≤ ce2 (수익≥4ATR 후) | CloseAll, reason="CE2 trailing hit" |
| **상태 백업** | 진입/청산 시 | GlobalVariable 6~8개 Write |

### 3.4 CTradeLogger 로그 출력 (CSV)

| 이벤트 | 기록 피처 |
|:---|:---|
| ENTRY | Time, prob, ATR, SL, Lot, Top5 피처 이름+값 |
| ADDON | Time, prob, Lot, unrealizedATR, addonNum |
| CLOSE | Time, reason, PnL(points), HoldBars |
| RECOVERY | Time, action, 복원된 상태값 |

---

## 데이터 무결성 체크리스트

| # | 규칙 | 적용 지점 | 검증 방법 |
|:---:|:---|:---|:---|
| 1 | **Shift+1** (미래 참조 금지) | CopyBuffer, ZScore, PctRank | `verify_merged_dataset.py` |
| 2 | **절대값 투입 금지** | 모든 파생 변환 | FeatureSchema 이름 검사 |
| 3 | **Python=MQL5 동일 연산** | GetZScore/PctRank/GetSlope | `/mql5-port-verify` 워크플로우 |
| 4 | **float 정밀도** | ONNX 입력 | `float[]` (double 아님) |
| 5 | **NaN/INF 게이트** | Predict() | `MathIsValidNumber` 전수 검사 |
| 6 | **ffill only** | 매크로 NaN | bfill 사용 시 빌드 실패 |
| 7 | **피처 순서** | FeatureSchema.mqh | 자동 생성 스크립트 |

---

## 4계층: 데이터 중요도와 웜업 결측 허용 (Warm-up Criticality)

초기 기동 시 `CFeatureEngine`이 1440개 봉을 PreloadHistory로 밀어넣지만, 외부 데이터 병합 지연이나 특정 지표 연산 지연 시 `prob` 추론을 어떻게 할 것인지에 대한 통제 정책입니다.

### 4.1 피처 분류 기준 (Criticality)

| 중요도 분류 | 대상 피처군 | 결측 시(NaN/0.0) 추론 정책 | 비고 |
|:---|:---|:---|:---|
| **P0: 100% 필수** | 현재가(Close), ATR14, CE1/CE2, 동적 포지션 피처 | **거래 금지** (Status=-1 반환) | 리스크 직결. 대체 불가능. |
| **P1: 핵심 모델 피처** | ADX/CHOP 원본 14~120 수준 지표, BOP/BSP (30 이내) | **거래 금지** | SHAP 상위 30위 내 피처 대다수 포진 |
| **P2: 장기 분포 피처** | Z-score(1440), pct(1440), 매크로 CSV 데이터 | **거래 금지** | PreloadHistory로 즉시 충족 가능 (1440봉 = 24시간 히스토리) |
| **P3: 이벤트 플래그** | event_calendar.csv | **0.0 대체 후 거래 허용** | 블랙아웃 기간 아니라는 기조 하에 진행 |

### 4.2 CFeatureEngine 웜업 게이트 통제 (IsWarmupReady) — 확정

> **확정 정책 (2026-03-14)**: P0~P2 피처 전체 충족 전까지 **거래 완전 금지**.
> P3(이벤트 플래그)만 결측 시 0.0 대체 후 허용.
> 정상 가동 시 PreloadHistory(1440봉)로 즉시 충족되므로 대기 시간 없음.

*   **구현:** CFeatureEngine 내부 `IsReady()` → **1440개 봉 데이터 100% 충족 시에만** `isWarmupReady = true` 반환
*   **근거:** P2 피처를 0.0으로 마스킹했을 때 모델 성능 저하 범위가 미검증 상태이므로, 안전 우선 원칙 적용
*   **유일한 예외 — CE2 복원 Bypass:**
    *   서버 재부팅 직후 기존 포지션의 CE2 청산/Virtual SL 체크는 **웜업 진행률과 완전 무관하게 즉각 실행**
    *   이 로직은 CTradeExecutor가 GlobalVariable에서 복원한 bid/CE2 비교만으로 동작하므로 피처 웜업 불필요
    *   (CTradeExecutor.md 복원 로직과 연계)

**향후 검토 항목:**
- [ ] P2 피처 전체 마스킹(0.0) 시 AUC/승률 변화 시뮬레이션
- [ ] Entry vs AddOn 웜업 요구 수준 분리 검토
- [ ] PreloadHistory 90% 이상 시 부분 추론 허용 여부 재검토
