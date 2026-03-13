---
description: 이벤트 블랙아웃 필터 시뮬레이션 — FOMC/NFP/CPI/PCE 이벤트 전후 진입 차단 ON/OFF 비교
---

# /event-sim 워크플로우

> FOMC/NFP/CPI/PCE 경제 이벤트 블랙아웃 필터의 전략 성과 영향 비교

## 사전 조건
- Entry 모델 학습 완료: `Files/models/round2_ABC/model_long_ABC.txt`
- 데이터셋: `Files/processed/AI_Study_Dataset.parquet`
- OHLC: `Files/processed/tech_features.parquet`
- CE 모듈: `Files/Tools/CE_TrailingStop.py`
- SHAP Top-60: `Files/models/round1/shap_top60.csv`
- 이벤트 캘린더: `Files/processed/event_calendar.csv`

## 이벤트 블랙아웃 윈도우

| 이벤트 | 발표시간(ET) | Before | After | Tier |
|:---|:---|:---:|:---:|:---:|
| FOMC | 14:00 | 4h | 2h | 1 |
| NFP | 08:30 | 2h | 1h | 1 |
| CPI | 08:30 | 2h | 1h | 1 |
| PCE | 08:30 | 1h | 1h | 2 |

## 실행 단계

### 1. 이벤트 시뮬레이터 실행
// turbo
```bash
cd "/Users/gim-yongsu/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/Tools"
python3.13 sim_event_blackout.py
```

### 2. 결과 확인
스크립트 출력 내용:
- **3가지 필터 조건 비교**: 필터OFF / Tier1(FOMC+NFP+CPI) / Tier1+2(+PCE)
- **각 조건별 월별 통계**: 거래 수, 승률, 총PnL
- **비교 요약 테이블**: 승률, PnL 변화, 차단 건수
- **차단 이벤트별 분포**: FOMC/NFP/CPI/PCE별 차단 건수

## 비교 매트릭스

```
임계치 0.20 기준:
  (1) 필터 OFF — 베이스라인 (sim_ai_ce_exit.py 동일 결과)
  (2) Tier 1: FOMC + NFP + CPI → 연 32건 블랙아웃
  (3) Tier 1+2: + PCE → 연 44건 블랙아웃
```

## 시간대 변환
- 이벤트 캘린더: ET (Eastern Time) 기준 기록
- MT5 서버시간: EET/EEST (UTC+2/+3, Europe/Athens)
- 스크립트에서 `zoneinfo`로 DST 자동 처리

## 이벤트 캘린더 편집
`Files/processed/event_calendar.csv`에 행 추가/삭제:
```csv
date,time_et,event_type,tier,before_hours,after_hours
2026-04-10,08:30,CPI,1,2,1
```

## 블랙아웃 윈도우 조정
`sim_event_blackout.py`의 event_calendar.csv에서 `before_hours`/`after_hours` 컬럼 편집.

## 확정 파라미터
| 항목 | 값 |
|:---|:---|
| 진입 | AI A+B+C prob ≥ 0.20 (M30 필터 미사용) |
| SL | ATR14 × 7.0 |
| CE 최소 TP | 4.0 × ATR |
| CE 설정 | 22봉 / 4.5배수 |
| 마찰비용 | $0.30 (30포인트) |

## 관련 파일
- **시뮬레이터**: `Files/Tools/sim_event_blackout.py`
- **이벤트 캘린더**: `Files/processed/event_calendar.csv`
- **베이스라인 시뮬레이터**: `Files/Tools/sim_ai_ce_exit.py`
- **Entry 모델**: `Files/models/round2_ABC/model_long_ABC.txt`
