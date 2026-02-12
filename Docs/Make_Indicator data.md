# Indicator Data Generation & Verification Guide

이 문서는 MQL5 기반 트레이딩 시스템을 위한 **머신러닝 학습 및 백테스트용 통합 데이터셋(`TotalResult_YYYY_MM_DD_N.csv`)**을 생성하는 전체 파이프라인과 검증 과정을 요약합니다.

## 1. 전체 프로세스 개요

데이터 생성 과정은 크게 **데이터 추출 -> 개별 지표 계산 -> 통합 데이터셋 생성 -> 정합성 검증**의 4단계로 구성됩니다.

1.  **데이터 추출 (MQL5)**: MT5에서 Raw Data(`XAUUSD.csv`) 및 검증용 MQL5 지표 출력값(`Indi_DownLoad.csv`) 생성.
2.  **파이썬 로직 구현**: 각 MQL5 지표(`BOP`, `BSP`, `ADX` 등)의 로직을 파이썬으로 1:1 이식.
3.  **마스터 스크립트 실행**: `Generate_TotalResult_Custom.py`를 통해 모든 지표를 계산하고 하나의 CSV로 병합.
4.  **정합성 검증**: MQL5 출력값과 파이썬 계산값을 비교하여 오차(MAE)가 0에 수렴하는지 확인.

---

## 2. 파일 및 디렉토리 구조

스크립트와 데이터는 다음과 같은 구조로 관리됩니다.

- **`MQL5/Files/`**: 데이터 저장소 (Input/Output)
    - `XAUUSD.csv` (또는 `xauusd_2026.csv`): 원본 가격 데이터 (Time, Open, High, Low, Close).
    - `*_DownLoad.csv`: MQL5 지표가 출력한 검증용 데이터 (예: `ADXSmooth_DownLoad.csv`).
    - `TotalResult_YYYY_MM_DD_N.csv`: 최종 생성된 통합 데이터셋.
- **`MQL5/Files/Instruction/`**: 실행 및 분석 스크립트
    - `Generate_TotalResult_Custom.py`: **[핵심]** 데이터 생성 마스터 스크립트.
    - `Investigate_*_Diff.py`: 지표별 오차 분석 스크립트 (ADX, BOP 등).
    - `Make_Indicator data.md`: 본 문서.
- **`MQL5/Scripts/`**: 개별 지표 계산/검증 모듈
    - `BOPWmaSmooth_Calc_and_Verify.py`: BOP 계산 로직.
    - `BSPWmaSmooth_Converter.py`: BSP 계산 로직.
    - `adx_verifier.py`, `TDI_Verifier.py`, `LRAVGSTD_Verifier.py` 등.

---

## 3. 주요 스크립트 설명

### 3.1. 마스터 스크립트 (`Generate_TotalResult_Custom.py`)
이 스크립트는 모든 개별 지표 모듈을 import하여 순차적으로 계산을 수행하고 결과를 병합합니다.

*   **기능**:
    *   `xauusd_2026.csv` 로드 (Tab/Comma 구분자 자동 처리).
    *   컬럼명 정규화 (Time, Open, High, Low, Close).
    *   각 지표 모듈 호출 및 결과 컬럼 병합 (Prefix 적용: `BOP_`, `LRA_`, `ADX_` 등).
    *   최종 결과 저장 (파일명 자동 번호 매김).
*   **사용법**:
    ```bash
    cd MQL5/Files/Instruction
    python Generate_TotalResult_Custom.py
    ```

### 3.2. 핵심 지표 모듈 및 검증 이슈

각 지표를 파이썬으로 이식하면서 해결한 주요 이슈들은 다음과 같습니다.

| 지표명 | 주요 이슈 및 해결 (Key Learnings) |
| :--- | :--- |
| **BOP (Balance of Power)** | **정규화 Reward**: MQL5의 `CalculateBullsReward` 로직(가격 범위 기반 정규화)을 정확히 구현해야 함.<br>**초기값 차이**: 누적합(CumSum) 방식이므로 시작 시점에 따라 상수 오차(Offset) 발생 가능. (정상) |
| **BSP (Buying/Selling Pressure)** | **계산 순서**: `Sum -> WMA -> Diff -> Smooth` 순서를 엄격히 준수해야 함.<br>**iWma 초기화**: MQL5 `iWma`는 초기 데이터 부족 시 0이 아니라 부분 계산을 수행함. 파이썬에서도 이를 반영해야 함. |
| **ADX (Average Directional Index)** | **Warm-up 구간**: 재귀적(Recursive) 계산(EMA 등)을 사용하므로, 데이터 초반 100~200 bar 구간에서는 MQL5와 파이썬 값에 차이가 발생함.<br>**수렴성**: 시간이 지날수록 오차는 0으로 수렴함. (`Investigate_ADX_Diff.py`로 확인됨). |
| **LRAVGSTD (Linear Reg)** | **시간 처리**: `datetime` 객체 변환 후 연산 수행 필요. |

---

## 4. 검증 및 디버깅 가이드

데이터 생성 후 의심스러운 값이 있다면 다음 절차를 따르십시오.

1.  **MQL5 데이터 확보**: 해당 지표의 MQL5 버전(`*_DownLoad.mq5`)을 실행하여 CSV를 출력합니다.
2.  **비교 스크립트 실행**: `Investigate_*_Diff.py` 류의 스크립트를 사용하여 두 CSV를 비교합니다.
3.  **오차 유형 분석**:
    *   **Constant Offset**: 누적합 시작점 차이 (BOP, BSP 등). -> **정상 (무시 가능)**
    *   **Decaying Error**: EMA 초기화 차이 (ADX, RSI 등). -> **정상 (데이터 앞부분 200개 버림 권장)**
    *   **Random Noise**: 로직 불일치. -> **코드 수정 필요**

## 5. 최종 산출물 (`TotalResult_...csv`) 명세

최종 파일은 약 40,000개 이상의 Row(1분봉 기준 1년치 이상)를 가지며, 다음 주요 컬럼들을 포함합니다.

*   `Time`, `Open`, `High`, `Low`, `Close`
*   `BOP_Diff`, `BOP_Scale`
*   `LRA_stdS(60)`, `LRA_BSPScale(60)`
*   `SmoothBOP_Val(10,3)`
*   `SmoothBSP_Val(10,3)`
*   `SmoothBOP_Val(30,5)`
*   `SmoothBSP_Val(30,5)`
*   `CHV_Val`, `CHV_StdDev`
*   `TDI_TrSi`, `TDI_Signal`
*   `QQE_RsiMa`, `QQE_TrLevel`
*   `ADX_Val`, `ADX_Avg`, `ADX_Scale`
*   `CE_Upl1`, `CE_Dnl1` ...
*   `CSI_Val`, `CSI_Scale`

이 데이터셋은 머신러닝 모델의 **Feature(입력값)**로 사용하기에 적합하도록 정제되었습니다.
