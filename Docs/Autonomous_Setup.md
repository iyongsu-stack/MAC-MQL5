# Autonomous Optimization System Setup

사용자의 개입 없이 최적화 작업을 완전 자동화(Fully Autonomous)하기 위한 환경 설정 및 아키텍처 가이드입니다.

## 1. Core Architecture: Python-Driven Orchestration
AI 에이전트가 대화창에서 도구를 하나씩 실행하는 방식은 느리고 승인이 필요합니다. 따라서 **모든 로직을 하나의 Python 마스터 스크립트(`Tools/5_auto_optimizer.py`)로 캡슐화**하여, 실행 버튼 한 번으로 수천 번의 최적화 루프가 돌아가도록 구성합니다.

### Workflow
1.  **Optimizer (Brain)**: `Optuna`가 파라미터 제안.
2.  **Data Prep (Generator)**: Python 코드 내에서 지표(BOP, LRA 등)를 즉시 계산 (MQL5 의존성 제거로 속도 100배 향상).
3.  **Simulator (Evaluator)**: 벡터화된 백테스팅 엔진으로 수익률 검증.
4.  **Feedback**: 결과를 Optuna에 반환하여 다음 파라미터 개선.

## 2. Prerequisites (환경 설정)

### A. Python Environment
필수 라이브러리가 설치되어 있어야 합니다.
```bash
pip install optuna pandas numpy matplotlib seaborn MetaTrader5
```
* `MetaTrader5`: 필요시 실시간 데이터 갱신을 위해 사용 (선택 사항).

### B. MQL5 vs Python Parity (필수 조건)
가장 중요한 조건은 **"MQL5 인디케이터 로직의 완벽한 Python 이식"**입니다.
- 매번 MT5 터미널을 백테스트로 돌리면 속도가 너무 느립니다.
- 따라서, `LRAVGSTD`, `BOP` 등의 핵심 로직을 Python 함수로 구현하여 메모리 상에서 계산해야 합니다.
- *현재 프로젝트 상태:* `Tools/3_data_analysis.py` 등에서 일부 구현되었으나, `Simulator`를 위한 완전한 로직 통합이 필요합니다.

### C. System Configuration (권장)
- **전원 관리**: 장시간 실행 시 PC가 절전 모드로 들어가지 않도록 설정.
- **Multiprocessing**: `Optuna`의 `n_jobs` 옵션을 활용하여 CPU 코어를 최대한 사용하여 병렬 처리를 수행하도록 스크립트 구성.

## 3. Execution Strategy
사용자는 아래 명령 한 번만 실행하면 됩니다.
```bash
python Tools/5_auto_optimizer.py --trials 1000 --parallel 4
```
이 스크립트는 `Docs/Optimization_Result.json`에 최적값을 지속적으로 업데이트하며, 목표 점수 도달 시 또는 중단 시까지 무한 가동됩니다.
