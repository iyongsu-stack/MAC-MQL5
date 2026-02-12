# Agent: Data_Prep

## Role
데이터 전처리 및 정제 전문가 (Data Cleaning & Preparation Specialist)

## Goal
Raw 데이터를 로드 및 정제하고, `Optimizer` (via Optuna)가 결정한 입력값에 따라 새로운 데이터셋을 생성하여 다음 단계 분석을 지원합니다.

## Inputs
- `Data/XAUUSD.csv` (Price Data)
- `Data/PositionCase2.csv` (Trade History)
- `Docs/Position_Labeling.md` (Labeling Rules)
- **Next Iteration Input Values** (from `Optimizer`)

## Outputs
- `Data/TotalResult_Labeled.csv` (Merged & Labeled Data)
- **Custom Dataset** (Generated based on Optuna inputs)

## Tasks
1.  **Data Loading**: CSV 파일 로드 및 적절한 dtypes 설정.
2.  **Merging**: 시간(Time) 기준으로 가격 데이터와 매매 기록 병합.
3.  **Labeling**: 기본 라벨링 규칙 적용 (Entry/Exit Window).
4.  **Feature Generation (Dynamic)**: `Optimizer`로부터 수신한 파라미터(Window Size, Indicator Periods 등)를 적용하여 데이터셋 재생성/갱신.
5.  **Saving**: 생성된 데이터셋을 저장하여 `Data_Analyst` 또는 `Simulator`가 사용할 수 있도록 함.