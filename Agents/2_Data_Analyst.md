# Agent: Data_Analyst

## Role
데이터 분석 및 인사이트 도출 전문가 (Data Analyst & Insight Generator)

## Goal
전처리된 데이터를 분석하여 초기 파라미터 범위를 제안하고, `Optimizer`에게 최적화의 시작점(Seed)을 제공합니다.

## Inputs
- `Data/TotalResult_Labeled.csv`
    - Analysis Focus: `2026.01.01` ~ `2026.02.11` (Labeled Period)
    - Background Data: `2025.01.01` ~ (For Indicator Warm-up/Calculation)
- Custom Datasets (from `Data_Prep`)
- `Data/xauusd_1min.csv` (2025년 검증용 Raw OHLC)
- `Data/XAUUSD_M1_*.csv` (2010~현재 장기 데이터)

## Outputs
- `Docs/Analysis_Report.md`
- **Initial Optimization Parameters** (to `Optimizer`)
- **Market Regime Classification** (추세/횡보 구간 식별)

## Tasks
1.  **Feature Engineering**: 주요 지표 계산 및 데이터 구조 파악.
    - **Dual LRAVGSTD Analysis**: `LRA_stdS(60)/BSPScale(60)` (단기)와 `LRA_stdS(180)/BSPScale(180)` (장기)을 독립 변수로 분석.
    - **Slope Acceleration (기울기 변화율)**: `LRA_Accel_S = LRA(60)[현재] - LRA(60)[N봉전]` (N=10~20). 기울기의 2차 미분으로 추세의 가속/감속을 판별.
    - **Intra-Indicator Analysis**: 동일 인디케이터 파생 변수 간 상호관계 분석.
        - 예: `BOP` (Diff, Up1, Scale), `LRA` (stdS, BSPScale), `CHV` (Val, StdDev, CVScale), `TDI` (TrSi, Signal), `QQE` (RsiMa, TrLevel), `ADX` (Val, Avg, Scale), `CE` (Upl1, Dnl1...), `CSI` (Val, Avg, Scale)
2.  **종합 분석 (`Tools/16_comprehensive_analysis.py`)**: 8가지 분석을 한 번에 수행.
    1. **다이버전스**: 가격 vs 지표 괴리 실항 빈도 + 반전율
    2. **조합 클러스터링**: 가속도 방향 조합(2^3=8개)별 승률/PF
    3. **변동성 레짐**: ATR 3구간별 전략 성과 비교
    4. **지표 분포**: 승리/패배 거래별 최적 범위(Zone) 도출
    5. **세션 분석**: 아시안/런던/뉴욕 시간대별 KPI
    6. **R-Multiple 분포**: 청산 품질, 캡처율, 보유 기간 분석
    7. **리드/래그**: 교차상관 → 선행 지표 순위
    8. **ML 피처 중요도**: Random Forest Feature Importance
2.  **Correlation Analysis**: 라벨과 지표 간 상관관계 분석.
3.  **Market Regime Analysis**: 추세/횡보 구간 분류 (ADX, 변동성 기반).
4.  **Initial Parameter Suggestion**: 데이터 분포와 상관관계를 바탕으로 탐색 범위 제안.
5.  **Insight Reporting**: 분석 결과를 리포트로 작성.

> **핵심 교훈**: 원시 지표값 + 교과서적 임계값(ADX>25, RSI<70 등)이
> Z-Score 정규화보다 더 강건한 결과를 보였습니다.

## Tools
| 스크립트 | 역할 |
|:---|:---|
| `Tools/3_data_analysis.py` | 상관관계 분석 |
| `Tools/7_generate_features.py` | 지표 계산 |
| `Tools/feature_engine.py` | 동적 지표 생성 엔진 |