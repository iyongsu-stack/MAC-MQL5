---
description: 에쿼티 커브 시뮬레이션 — 실제 잔고 기반 복리 수익률/MDD 산출 (롱/숏 전략 공용)
---

# /equity-sim 워크플로우

> 전략의 실제 수익률(%)을 시뮬레이션. 잔고 추적 + 피라미딩 포함 총 리스크 1% 제한.

## 사전 조건
- Entry 모델: `Files/models/round2_ABC/model_long_ABC.txt`
- Addon 모델: `Files/models/pyramid_round2_ABC/model_addon_ABC.txt`
- 데이터셋: `Files/processed/AI_Study_Dataset.parquet`, `AI_Pyramid_Dataset.parquet`
- OHLC: `Files/processed/tech_features.parquet`
- 공용 모듈: `Files/Tools/money_manage.py`, `Files/Tools/CE_TrailingStop.py`

## 핵심 파라미터

`Files/Tools/sim_equity_curve.py` 상단에서 수정:

```python
INIT_BALANCE  = 100_000.0     # 시작 잔고 ($)
RISK_PCT      = 0.01          # 리스크 비율 (0.01 = 1%)
CONTRACT_SIZE = 100           # 1 lot = 100 oz (XAUUSD)
CE_MULT       = 4.5           # CE SL2 (라벨링과 동일)
ENTRY_THR     = 0.20          # Entry AI 임계치
ADDON_THR     = 0.40          # Addon AI 임계치

# Phase 정의 — 필요 시 구간 추가/변경
PHASES = [
    ("Phase 1: OOS 전체", "2023-01-01", "2026-03-01"),
    ("Phase 2: 비급상승 구간", "2022-03-01", "2023-05-01"),
]
```

## 랏사이즈 공식 (money_manage.py)

```
worst_case_ATR_lots = SL_mult × 1.0
  + Σ (SL_mult + spacing × n) × lot_ratio^n   (n = 1..max_addon)
  = 7.0 + 4.25 + 2.50 + 1.44 = 15.19

base_lot = (Balance × risk%) / (worst_case_ATR_lots × ATR14 × contract_size)
```

> **의미**: 피라미딩 전체 그룹이 SL 히트 시에도 정확히 1% 손실이 되도록 base_lot을 역산.

## 실행 단계

### 1. 파라미터 설정
`sim_equity_curve.py` 상단의 `INIT_BALANCE`, `RISK_PCT`, `PHASES` 수정

### 2. 시뮬레이션 실행
// turbo
```bash
cd "/Users/gim-yongsu/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/Tools"
python3.13 sim_equity_curve.py
```

> ⏱ 소요 시간: ~7분 (Phase 2개 기준)

### 3. 출력 항목

| 항목 | 단위 |
|:---|:---|
| 최종 잔고 | $ |
| 총 수익률 | % |
| 거래 수 / 승률 | 건 / % |
| 평균 거래수익 | % of balance |
| MDD | % of peak |
| 월별 잔고/수익률 | $/% |
| CAGR | % |
| base_lot 범위 | lots |

## 숏전략 적용 시 변경 사항

숏전략 개발 시 아래만 수정:

1. **모델 경로**: `model_long_ABC.txt` → `model_short_ABC.txt`
2. **라벨 컬럼**: `label_long` → `label_short`
3. **방향**: 매수→매도 (SL=entry+ATR, CE trailing 방향 반전)
4. **PHASES**: 숏 OOS 구간으로 변경

## 롱+숏 통합 시나리오

두 전략 결과를 합산하여 통합 에쿼티를 계산할 경우:
- 각 전략 개별 실행 → 월별 수익률 추출
- 통합 월수익 = 롱 월수익 + 숏 월수익 (시간 겹침 시 합산)
- 통합 MDD = 합산 에쿼티에서 재계산

## 관련 파일
- **시뮬레이터**: `Files/Tools/sim_equity_curve.py`
- **랏 계산기**: `Files/Tools/money_manage.py`
- **CE 모듈**: `Files/Tools/CE_TrailingStop.py`
- **MQL5 랏 함수**: `Include/BSPV9/MoneyManageV9.mqh` → `CalculatePyramidLotSize()`
- **문서**: `Docs/TrendTrading Development Strategy/Pyramiding.md` (에쿼티 커브 섹션)

## 기준 결과 (2026-03-12 롱전략)

| 항목 | Phase 1 (OOS 38개월) | Phase 2 (비급상승 14개월) |
|:---|:---:|:---:|
| 시작 잔고 | $100,000 | $100,000 |
| 최종 잔고 | **$13,378,536** | **$601,016** |
| 월평균 수익률 | **+13.89%** | **+13.88%** |
| MDD | **-5.21%** | **-2.02%** |
| 양수 월 | 37/38 (97%) | 14/14 (100%) |
| CAGR | +369% | +365% |
