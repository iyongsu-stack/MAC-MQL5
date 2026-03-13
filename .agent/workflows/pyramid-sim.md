---
description: 피라미딩 통합 CE 시뮬레이션 — 격자탐색으로 최적 피라미딩 파라미터 도출
---

# /pyramid-sim 워크플로우

> CE+피라미딩 통합 시뮬레이터 격자탐색 실행

## 사전 조건
- Entry 모델 학습 완료: `Files/models/round2_ABC/model_long_ABC.txt`
- Addon 모델 학습 완료: `Files/models/pyramid_round2_ABC/model_addon_ABC.txt`
- 데이터셋: `Files/processed/AI_Study_Dataset.parquet`, `Files/processed/AI_Pyramid_Dataset.parquet`
- CE 모듈: `Files/Tools/CE_TrailingStop.py`
- OHLC: `Files/processed/tech_features.parquet`

## 확정 파라미터 (2026-03-12)

```
addon_thr      = 0.40   (AI 임계치 — 보수적)
max_addon      = 3      (최대 3회 추가)
lot_ratio      = 0.50   (정피라미드: 1.0 → 0.50 → 0.25)
min_interval   = 5봉     (추가 간격 최소 5봉)
min_unrealized = 1.5 ATR (최소 미실현수익)
be_mode        = None   (B/E SL 이동 없음 — 1차 SL 고정 유지)
CE_MULT        = 4.5    (CE SL2 — 라벨링과 동일, AtrMultiplier2)
```

> 랏사이즈: `CalculatePyramidLotSize()` 사용 (피라미딩 포함 총 리스크 1% 제한)
> Python: `from money_manage import calc_base_lot`  |  MQL5: `MoneyManageV9.mqh`

> be_mode=None 확정 근거: B/E 이동 시 SL 조기 촉발로 수익 파동 조기 청산 (SL 340건 vs 163건).
> SL=7×ATR이 충분히 넓어 추가 B/E 보호 불필요. OOS/비급상승 구간 모두 None 우세.

## 실행 단계

### 1. 격자탐색 시뮬레이터 실행
// turbo
```bash
cd "/Users/gim-yongsu/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/Tools"
python3.13 sim_pyramid_grid.py
```

### 2. B/E 모드 비교 시뮬레이터 실행 (선택)
// turbo
```bash
cd "/Users/gim-yongsu/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/Tools"
python3.13 sim_pyramid_be_compare.py
```

> Phase 1(OOS 전체) + Phase 2(특정 기간) 두 구간에서 be_move vs None 비교

### 3. 실행 결과 확인
스크립트가 출력하는 내용:
- **베이스라인**: 피라미딩 없는 SL=7ATR / CE≥4ATR 결과
- **격자탐색 Top-10**: 총PnL 및 Calmar 기준 상위 10개 조합
- **최적 파라미터**: addon_thr, max_addon, lot_ratio, min_interval, min_unrealized

### 4. 결과 CSV 확인
// turbo
```bash
cd "/Users/gim-yongsu/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/Tools"
python3.13 -c "
import pandas as pd
df = pd.read_csv('../processed/pyramid_grid_results.csv')
print(f'총 {len(df)}개 조합')
top5 = df.sort_values('total_pnl', ascending=False).head(5)
print(top5[['addon_thr','max_addon','lot_ratio','min_interval','min_unrealized','trades','win_rate','total_pnl','pnl_uplift_pct','calmar']].to_string())
"
```

## 격자탐색 변수 설명

| 변수 | 확정값 | 탐색 범위 | 의미 |
|:---|:---:|:---|:---|
| `addon_thr` | **0.40** | 0.20 ~ 0.50 | Addon AI 모델 확률 임계치 |
| `max_addon` | **3** | 1, 2, 3 | 최대 추가 진입 횟수 |
| `lot_ratio` | **0.50** | 0.25 ~ 0.50 | 정피라미드 랏 비율 |
| `min_interval` | **5** | 5 ~ 15봉 | 추가 진입 최소 간격 |
| `min_unrealized` | **1.5** | 0.5 ~ 1.5 ATR | 추가 진입 전제 |
| `be_mode` | **None** | be_move / None | B/E SL 이동 방식 |

## 파라미터 변경 방법
`sim_pyramid_grid.py`의 `grid` 딕셔너리를 수정:

```python
grid = {
    "addon_thr":      [0.20, 0.25, 0.30, 0.35, 0.40],
    "max_addon":      [1, 2, 3],
    "lot_ratio":      [0.25, 0.33, 0.50],
    "min_interval":   [5, 10, 15],
    "min_unrealized": [0.5, 1.0, 1.5],
}
```

> **주의**: 조합 수 = 각 리스트 길이의 곱. 405개 조합 ≈ 38분 소요.

## 관련 파일
- **격자탐색 시뮬레이터**: `Files/Tools/sim_pyramid_grid.py`
- **B/E 비교 시뮬레이터**: `Files/Tools/sim_pyramid_be_compare.py`
- **결과 CSV**: `Files/processed/pyramid_grid_results.csv`
- **문서**: `Docs/TrendTrading Development Strategy/Pyramiding.md`
- **Entry 모델**: `Files/models/round2_ABC/model_long_ABC.txt`
- **Addon 모델**: `Files/models/pyramid_round2_ABC/model_addon_ABC.txt`
- **Phase 1 분석**: `Files/Tools/sim_pyramid_phase1.py`

## Phase 1 핵심 통계 (되돌림/리스크 분석)

> addon_thr=0.40, max_addon=3, lot_ratio=0.50, min_interval=5, min_unrealized=1.5 기준

### 승률
| 구분 | 승률 | 건수 |
|:---|:---:|:---:|
| addon 있는 거래 | **93.0%** | 571건 |
| addon 없는 거래 | 26.8% | 168건 |
| addon SL Loss | 5.4% | 40건 |

### Addon 되돌림 깊이 (ATR)
| %ile | Addon1 | Addon2 | Addon3 |
|:---:|:---:|:---:|:---:|
| 중위 | 1.14 | 1.28 | 1.14 |
| 75%ile | 2.52 | 2.53 | 2.42 |
| 90%ile | 5.94 | 5.11 | 5.49 |
| 승리 90%ile | — | **3.64** | — |
| 패배 중위 | — | **9.98** | — |

### 미실현수익 구간별 addon 승률
| 구간 | 승률 | 되돌림 90%ile |
|:---:|:---:|:---:|
| 1~2 ATR | 90.2% | 7.87 ATR |
| 2~3 ATR | 93.6% | 5.48 |
| 3~4 ATR | 93.2% | 5.37 |
| **4~6 ATR** | **96.6%** | **4.15** |
| 6+ ATR | 100% | ~3.15 |

### 최악 총 손실 (addon+SL 일괄청산 시)
| %ile | ATR |
|:---:|:---:|
| 75%ile | 16.12 |
| 90%ile | 16.69 |
| **95%ile** | **17.08** |

> CE2 진입 시 위치: 71.6%가 1차 진입가 위 (평균 +1.23ATR)

## B/E 비교 실측 결과 요약 — CE2(4.5) 기준 (2026-03-12)

| 기간 | be_move 총PnL | None 총PnL | 차이 | 승자 |
|:---|:---:|:---:|:---:|:---:|
| OOS 전체 (23.01~26.02) | +6,689 | **+7,490** | +801 | 🏆 None |
| 비급상승 (22.03~23.04) | +1,643 | **+1,900** | +257 | 🏆 None |

> CE_MULT=3.0(CE1)→4.5(CE2)로 변경 후 총PnL 약 +12% 증가, MDD 소폭 증가
