# Position Labeling Methodology

이 문서는 `PositionCase2.csv` (매매 기록)와 `TotalResult_2026_02_11_11.csv` (시장 데이터)를 결합하여 머신러닝 학습용 데이터를 생성하는 과정과 로직을 기술합니다.

## 1. 개요 (Overview)
*   **목적:** 매매 시점의 시장 데이터를 추출하고, 진입 및 청산 시점을 기준으로 라벨링(Labeling)을 수행하여 학습 데이터를 구축함.
*   **스크립트 위치:** `MQL5\Scripts\merge_and_label.py`
*   **결과 파일:** `MQL5\Files\TotalResult_Labeled.csv`

## 2. 데이터 소스 (Input Data)
1.  **매매 기록 파일 (`PositionCase2.csv`)**
    *   **OpenTime:** 진입 시간 (`yyyy.mm.dd HH:MM` 형식)
    *   **OpenType:** 진입 유형 (`Buy` 또는 `Sell`)
    *   **CloseTime:** 청산 시간
    *   **CloseType:** 청산 유형

2.  **시장 데이터 파일 (`TotalResult_2026_02_11_11.csv`)**
    *   **Time:** 1분봉 시간 (`yyyy-mm-dd HH:MM:SS` 형식)
    *   **Close, Indicators:** 종가 및 각종 보조지표 값

## 3. 라벨링 로직 (Labeling Logic)

### 3.1. 진입 신호 (Open Signal)
각 매매 방향(Buy/Sell)별로 별도의 컬럼을 사용하여 **One-Hot Encoding** 방식으로 라벨링함.

*   **기준:** `OpenTime`
*   **윈도우 범위:** 과거 4개 봉 ~ 미래 4개 봉 (본인 포함 총 9개 봉)
    *   $t_{-4}, t_{-3}, t_{-2}, t_{-1}, t_{0}, t_{+1}, t_{+2}, t_{+3}, t_{+4}$
*   **라벨 컬럼:**
    *   **`Label_Open_Buy`:** 매수 진입 시점인 경우 `1`, 아니면 `0`
    *   **`Label_Open_Sell`:** 매도 진입 시점인 경우 `1`, 아니면 `0`

### 3.2. 청산 신호 (Close Signal)
진입한 포지션을 청산하는 시점을 라벨링함.

*   **기준:** `CloseTime`
*   **윈도우 범위:** 과거 3개 봉 ~ 현재 (본인 포함 총 4개 봉)
    *   $t_{-3}, t_{-2}, t_{-1}, t_{0}$ (청산 시점 직전의 움직임 학습)
*   **라벨 컬럼:**
    *   **`Label_Close_Buy`:** 매수(Buy) 포지션을 청산하는 경우 `1`, 아니면 `0`
    *   **`Label_Close_Sell`:** 매도(Sell) 포지션을 청산하는 경우 `1`, 아니면 `0`

## 4. 처리 과정 (Process Sequence)
1.  **데이터 로드:** CSV 파일을 Pandas DataFrame으로 로드.
2.  **전처리:** 
    *   `PositionCase2.csv`의 날짜 형식을 표준 `datetime` 객체로 변환.
    *   `TotalResult` 데이터를 시간순 정렬 및 인덱싱.
3.  **병합 및 One-Hot 라벨링:**
    *   매매 기록의 시간(`OpenTime`, `CloseTime`)과 유형(`OpenType`)을 기반으로 매칭.
    *   `Label_Open_Buy`, `Label_Open_Sell`, `Label_Close_Buy`, `Label_Close_Sell` 4개 컬럼 생성.
4.  **저장:** `TotalResult_Labeled.csv`로 저장.

## 5. 비고 (Notes)
*   Python 스크립트 실행 시 인코딩 에러가 발생할 경우 `cp949` 또는 `utf-8-sig`를 시도하도록 예외 처리됨.
*   시장 데이터(`TotalResult`)에 없는 시간의 매매 기록은 무시됨.
