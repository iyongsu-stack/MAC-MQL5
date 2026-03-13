---
description: AI 진입신호 기반 CE 청산 시뮬레이션 — SL/TP 격자탐색으로 최적 진입 파라미터 도출
---

# /entry-sim 워크플로우

> AI A+B+C 모델 진입신호 + CE2 트레일링 청산 시뮬레이션 (SL/TP 격자탐색)

## 사전 조건
- Entry 모델 학습 완료: `Files/models/round2_ABC/model_long_ABC.txt`
- 데이터셋: `Files/processed/AI_Study_Dataset.parquet`
- OHLC: `Files/processed/tech_features.parquet`
- CE 모듈: `Files/Tools/CE_TrailingStop.py`
- SHAP Top-60: `Files/models/round1/shap_top60.csv`

## 실행 단계

### 1. 시뮬레이터 실행
// turbo
```bash
cd "/Users/gim-yongsu/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/Tools"
python3.13 sim_ai_ce_exit.py
```

### 2. 결과 확인
스크립트가 출력하는 내용:
- **임계치별 시뮬레이션**: thr=0.15, 0.20, 0.25
- **전체/월별 통계**: 거래 수, 승률, 평균 PnL, CE/SL 비율

## 시뮬레이션 구간 변경
`sim_ai_ce_exit.py` 37~38행의 OOS 필터를 수정:
```python
# 전체 OOS (기본)
oos = df[df["Time"] >= "2023-01-01"].copy()

# 2023년만
oos = df[(df["Time"] >= "2023-01-01") & (df["Time"] < "2024-01-01")].copy()

# 특정 구간
oos = df[(df["Time"] >= "2022-03-01") & (df["Time"] < "2023-05-01")].copy()
```

## SL/TP 격자탐색 변경
SL/TP 배수를 변경하려면 시뮬레이션 함수의 파라미터를 조정:
```python
# 기존 sim_ai_ce_exit.py의 고정값:
fixed_sl = entry_price - 5.0 * atr14   # SL 배수
min_tp_profit = 3.0 * atr14             # CE 최소 TP 배수

# 격자탐색 시 반복:
for sl_mult in [3, 4, 5, 7]:
    for tp_mult in [1.0, 2.0, 3.0, 4.0]:
        ...
```

## 확정 파라미터
| 항목 | 값 |
|:---|:---|
| 진입 | AI A+B+C prob ≥ 0.20 (M30 필터 미사용) |
| SL | ATR14 × 7.0 |
| CE 최소 TP | 4.0 × ATR |
| CE 설정 | 22봉 / 3.0배수 |
| 마찰비용 | $0.30 (30포인트) |

## 관련 파일
- **시뮬레이터**: `Files/Tools/sim_ai_ce_exit.py`
- **문서**: `Docs/TrendTrading Development Strategy/롱 학습결과 분석.md`
- **Entry 모델**: `Files/models/round2_ABC/model_long_ABC.txt`
