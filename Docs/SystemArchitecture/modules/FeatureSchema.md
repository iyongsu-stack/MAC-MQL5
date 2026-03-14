# FeatureSchema — 모듈 설계서

> 모듈 ID: N/A | 자동 생성 헤더 | 의존성: 없음 (상수 정의 전용)

---

## 1. 단일 책임

**피처 이름 ↔ 인덱스 매핑 상수 정의**.
- ONNX 모델의 입력 피처 순서를 코드 상수로 관리
- Python `export_feature_schema.py`에서 **자동 생성** (수동 편집 금지)
- Entry 모델(80개) + AddOn 모델(77개) 2세트 정의

---

## 2. 구성

```
FeatureSchema.mqh
  │
  ├── ENTRY_FEATURE_COUNT = 80
  ├── enum ENUM_ENTRY_FEATURE
  │     ENTRY_F_CE_SL2_dist_ATR = 0
  │     ENTRY_F_CE_Dist2_slope14 = 1
  │     ... (80개 전부 정의)
  │     ENTRY_F_regime_bull_flag = 79
  │
  ├── const string EntryFeatureNames[80]
  │     {"CE_SL2_dist_ATR", "CE_Dist2_slope14", ...}
  │
  ├── ADDON_FEATURE_COUNT = 77
  ├── enum ENUM_ADDON_FEATURE
  │     ADDON_F_ADXS_80_Avg_slope14 = 0
  │     ... (77개 전부 정의)
  │     ADDON_F_regime_bull_flag = 76
  │
  └── const string AddonFeatureNames[77]
        {"ADXS_(80)_Avg_slope14", ...}
```

---

## 3. 피처 카테고리 분류

### Entry 모델 (80개)

| 카테고리 | 피처 수 | 대표 피처 |
|:---|:---:|:---|
| 기술 지표 파생 | ~56 | CE_dist_ATR, ADXS_pct240, CHV_zscore, BSP_accel |
| 레짐 인식 | 4 | regime_monthly_pct, regime_weekly_up_ratio, regime_above_ma20w, regime_bull_flag |
| 매크로 | ~8 | GOLD_zscore_240, MXUS_FR_ret1d, DAX_ret1d, COFFEE_accel |
| TickVolume | ~4 | TickVolume_zscore1440, TickVolume_zscore1440_pct1440 |
| 가격 모멘텀 | 1 | price_mom_10 |
| 동적 pct | ~7 | ATR14_pct, ADXMTF_H4_DiPlus_pct, CE_Dist2_slope14_pct |

### AddOn 모델 (77개)

Entry와 공유되는 기술 피처 + 추가 동적 피처:

| 추가 피처 | 설명 |
|:---|:---|
| addon_count | 현재 피라미딩 횟수 |
| unrealized_pnl_atr | 미실현수익 ATR 배수 |
| bars_since_entry | 진입 후 경과 봉 수 |
| atr_expansion | ATR 확장률 |
| bsp_scale_delta | BSPScale 변화량 |
| trend_acceleration | 추세 가속도 |
| + *_pct 변환 | 위 동적 피처의 pct240 |

---

## 4. 자동 생성 스크립트

```
export_feature_schema.py
  ├── LightGBM 모델에서 model.feature_name_ 추출
  ├── Entry/Addon 모델 각각의 피처 이름 + 순서 → enum 생성
  ├── const string[] 배열 생성 (디버깅용)
  └── FeatureSchema.mqh 파일 출력
```

> ⚠️ **모델 재학습 시 반드시 스크립트 재실행** → 순서 동기화 보장

---

## 5. 사용처

| 모듈 | 용도 |
|:---|:---|
| **CFeatureEngine** | `GetEntryFeatures(out[ENTRY_FEATURE_COUNT])` — 배열 크기 및 조립 순서 |
| **COnnxPredictor** | `Init(path, ENTRY_FEATURE_COUNT)` — 입력 크기 검증 |
| **CTradeLogger** | `EntryFeatureNames[idx]` — 피처 이름으로 로그 기록 |
| **CDashboard** | 피처 이름 표시 (디버깅 모드) |

---

## 6. 의존성

```
FeatureSchema.mqh
  └── 자동 생성 (export_feature_schema.py)
      ├── 입력: model_long_ABC.txt → feature_name_
      └── 입력: model_addon_ABC.txt → feature_name_

호출하는 모듈:
  ├── CFeatureEngine.mqh  (#include)
  ├── COnnxPredictor.mqh  (#include 간접)
  ├── CTradeLogger.mqh    (#include)
  └── CDashboard.mqh      (#include 간접)
```
