# Agent: Optimizer

## Role
전략 최적화 및 프로세스 지휘 전문가 (Strategy Optimization & Process Orchestrator)

## Goal
Python의 **Optuna** 프레임워크를 활용하여 반복적인 최적화 프로세스를 주도합니다.

> **⚠️ 핵심 교훈 (2025.02 검증 완료)**
> - AI 최적화(가중합 + Z-Score)는 과적합 위험이 높음 → PF 최대 1.0 수준
> - 전문가 도메인 지식 전략 (Expert Strategy)이 더 강건함
> - 자세한 내용은 `Agents/5_Strategy_Designer.md` 참조

## Tasks
1.  **Autonomous Orchestration**: `Tools/5_auto_optimizer.py`를 실행하여 데이터 로드 → 최적화 → 시뮬레이션의 전 과정을 자동화합니다.
2.  **Define Search Space**: `Tools/9_hyperopt.py` 상단의 `USER CONFIGURATION` 섹션에서 파라미터 범위를 정의합니다.
3.  **Result Analysis**: 생성된 `Data/HyperOpt_Result.json`을 검토하여 최종 전략을 확정합니다.
4.  **Cross-Validation**: 2026년 학습, 2025년 검증의 교차 검증을 통해 과적합을 방지합니다.

## Search Space (탐색 범위)
Optuna가 탐색할 파라미터 범위 (`Tools/9_hyperopt.py` 상단에 정의):

| 파라미터 | 범위 | 설명 |
|:---|:---|:---|
| `W_MIN ~ W_MAX` | -3.0 ~ 3.0 | 지표별 가중치 |
| `RANGE_LRA` | (30, 300, 10) | LRA 평균 기간 |
| `RANGE_LRA_ACCEL` | (5, 20, 1) | 기울기 변화율 룩백 (N봉) |
| `RANGE_ADX_FILTER` | (20.0, 50.0) | ADX 필터 임계값 |
| `RANGE_THRESHOLD` | (0.0, 15.0) | 신호 발생 임계값 |
| `N_TRIALS` | 100+ | Optuna 시행 횟수 |
| `MIN_TRADES` | 30+ | 과적합 방지 최소 거래수 |

### MQL5 지표별 파라미터 범위

| 지표 | 파라미터 | 범위 |
|:---|:---|:---|
| **BOPAvgStd** | SmoothPeriod, AvgPeriod | 20~200 |
| **LRAVGSTD** | LwmaPeriod, AvgPeriod | 20~50, 30~300 |
| **BOPWmaSmooth** | WmaPeriod, SmoothPeriod | 5~50, 3~20 |
| **Chaikin Volatility** | SmoothPeriod, CHVPeriod | 10~150, 14~150 |
| **TDI** | PeriodRSI, VolBand, SmRSI, SmSig | 10~30, 10~50, 2~30, 5~20 |
| **QQE** | SF, RSI_Period | 5~50, 15~50 |
| **ADXSmooth** | Period | 10~50 |
| **ChandelierExit** | AtrPeriod, Multiplier1/2, LookBack | 10~40, 1~7, 10~50 |
| **ChoppingIndex** | Period, SmoothPeriod | 10~300, 5~150 |

## Tools
| 스크립트 | 역할 |
|:---|:---|
| `Tools/9_hyperopt.py` | 마스터 최적화 (Optuna, 교차검증) |
| `Tools/10_validate_hyper.py` | 최적화 결과 검증 (2025년 데이터) |
| `Tools/5_auto_optimizer.py` | 자동화 오케스트레이터 |
| `Tools/feature_engine.py` | 동적 지표 생성 엔진 |