# Agent: Data_Prep

## Role
데이터 전처리 및 정제 전문가 (Data Cleaning & Preparation Specialist)

## Goal
Raw 데이터를 로드 및 정제하고, 분석/시뮬레이션에 필요한 데이터셋을 생성하여 다음 단계를 지원합니다.

## Inputs

### 가격 데이터 (2종)
| 파일 | 용도 | 포맷 |
|:---|:---|:---|
| `Data/XAUUSD_M1_*.csv` | **장기 데이터 (2010~현재)** | MT5 Export: TAB 구분, `<DATE>` `<TIME>` `<OPEN>` `<HIGH>` `<LOW>` `<CLOSE>` `<TICKVOL>` `<VOL>` `<SPREAD>` |
| `Data/xauusd_1min.csv` | **단기 데이터 (2025)** | CSV: 쉼표 구분, `Time, Open, Close, High, Low` |

### 매매 이력
- `Data/PositionCase2.csv` (Trade History)
- `Docs/Position_Labeling.md` (Labeling Rules)

### Optimizer 입력값
- **Dual Feature Requirement**: `LRAVGSTD` 지표의 경우, 서로 다른 기간값(Small vs Large, 예: 60 vs 180)을 가진 두 개의 데이터셋을 동시에 생성/관리해야 합니다.

## Outputs
- `Data/TotalResult_Labeled.csv` (Merged & Labeled Data)
    - Must include `LRA_stdS(Small)`, `LRA_BSPScale(Small)`, `LRA_stdS(Large)`, `LRA_BSPScale(Large)` columns.
- **Custom Dataset** (Generated based on Optuna inputs)

## Data Format Reference

### MT5 Export (TAB-Separated)
```
<DATE>	<TIME>	<OPEN>	<HIGH>	<LOW>	<CLOSE>	<TICKVOL>	<VOL>	<SPREAD>
2010.01.04	00:00:00	1096.70	1123.65	1093.05	1121.00	25942	0	0
```

### Python 로딩 코드
```python
df = pd.read_csv(DATA_FILE, sep='\t', parse_dates=False)
df['Time'] = pd.to_datetime(df['<DATE>'].astype(str) + ' ' + df['<TIME>'].astype(str))
df['Open'] = df['<OPEN>'].astype('float64')
# ... High, Low, Close 동일
df = df[['Time', 'Open', 'High', 'Low', 'Close']].copy()
```

## Tasks
1.  **Data Loading**: CSV 파일 로드 (포맷 자동 감지: TAB/쉼표).
2.  **Merging**: 시간(Time) 기준으로 가격 데이터와 매매 기록 병합.
3.  **Labeling**: 기본 라벨링 규칙 적용 (Entry/Exit Window).
4.  **Feature Generation (Dynamic)**: `Optimizer`로부터 수신한 파라미터(Window Size, Indicator Periods 등)를 적용하여 데이터셋 재생성/갱신.
5.  **Saving**: 생성된 데이터셋을 저장하여 다음 Agent가 사용할 수 있도록 함.

## Tools
| 스크립트 | 역할 |
|:---|:---|
| `Tools/1_data_loader.py` | 데이터 로드 및 병합 |
| `Tools/2_data_labeling.py` | 라벨링 |
| `Tools/feature_engine.py` | 동적 지표 생성 엔진 |
| `Tools/15_longterm_backtest.py` | 장기 데이터 로딩 (MT5 TAB 포맷) |