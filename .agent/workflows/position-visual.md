---
description: MT5 차트에 AI 진입/피라미딩/청산 신호를 시각화 — CSV 생성 + ShowLabelingResult 스크립트
---

# /position-visual 워크플로우

> AI Entry + Addon(피라미딩) 예측 결과를 MT5 차트 위에 마커로 표시

## 사전 조건
- Entry 모델: `Files/models/round2_ABC/model_long_ABC.txt`
- Addon 모델: `Files/models/pyramid_round2_ABC/model_addon_ABC.txt`
- 데이터셋: `Files/processed/AI_Study_Dataset.parquet`, `AI_Pyramid_Dataset.parquet`
- OHLC: `Files/processed/tech_features.parquet`
- MT5 스크립트: `Scripts/ShowLabelingResult.mq5` (컴파일 필요)
- CSV 라이브러리: `Include/DKSimplestCSVReader.mqh`

## 실행 단계

### 1. 시각화 기간/임계치 설정
`Files/Tools/export_sim_visual_csv.py` 상단의 파라미터 수정:

```python
SYMBOL    = "XAUUSD_Duka"     # MT5 차트 심볼 이름
ENTRY_THR = 0.20              # Entry 모델 표시 임계치
ADDON_THR = 0.40              # Addon 모델 표시 임계치
VIS_START = "2025-05-05"      # 시각화 시작일
VIS_END   = "2025-05-05 23:59:59"  # 시각화 종료일
```

> ⚠️ **객체 수 500건 초과 시 MT5 성능 저하** — 기간을 짧게(1~3일) 또는 ADDON_THR를 올려 조절

### 2. CSV 생성
// turbo
```bash
cd "/Users/gim-yongsu/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/Tools"
python3.13 export_sim_visual_csv.py
```

출력 파일: `Files/sim_visual_entry_pyramid.csv`

### 3. MT5에서 시각화
1. MT5 열기 → XAUUSD 차트 (M1 타임프레임)
2. **네비게이터** → Scripts → `ShowLabelingResult` 더블클릭
3. 입력 파라미터: `sim_visual_entry_pyramid.csv` (기본값)
4. OK → 차트에 마커 표시 + 자동 스크롤

### 4. 마커 범례

| 마커 | 색상 | 의미 |
|:---:|:---:|:---|
| ▲ | 🔵 Blue | Entry 신호 (prob ≥ ENTRY_THR) |
| ▲ | 🩷 Magenta | Entry Loss (PnL < 0) |
| ◆ | 🟢 Lime | Addon 피라미딩 신호 (prob ≥ ADDON_THR) |
| ▼ | 🟢 Lime | CE_TP 수익 청산 |
| ▼ | 🔴 Red | SL 손절 청산 |

### 5. 마커 제거
차트에서 마커를 지우려면 스크립트를 다시 실행 (ObjectsDeleteAll → 재표시)
또는 MT5 → 차트 우클릭 → 오브젝트 리스트 → 전체 삭제

## 응용 예시

### 특정 월 전체 시각화
```python
VIS_START = "2025-01-01"
VIS_END   = "2025-01-31 23:59:59"
ADDON_THR = 0.50  # 객체 수 제한을 위해 임계치 상향
```

### Entry만 표시 (Addon 없이)
```python
ADDON_THR = 1.0  # 사실상 Addon 비활성
```

## 관련 파일
- **CSV 생성기**: `Files/Tools/export_sim_visual_csv.py`
- **MT5 스크립트**: `Scripts/ShowLabelingResult.mq5`
- **CSV 출력**: `Files/sim_visual_entry_pyramid.csv`
- **CSV 리더**: `Include/DKSimplestCSVReader.mqh`
