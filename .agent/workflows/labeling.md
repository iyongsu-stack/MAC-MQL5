---
description: XAUUSD 롱전략 CE Trailing Stop 라벨링 시뮬레이션 — TP/필터 조합 탐색 → Win CSV 생성 → MT5 시각 검증
---

# 라벨링 시뮬레이션 워크플로우 (/labeling)

> **목적**: 3-Barrier(CE Trailing Stop) 방식으로 TP 배수·필터 조합을 탐색하고, MT5 차트에서 시각적으로 검증한다.  
> 확정된 파라미터로 AI 학습용 라벨을 생성할 때는 `/data-build` Step 2를 사용한다.

> [!IMPORTANT]
> **확정된 설계 원칙 (2026-03-09 갱신)**
> - SL = **2.5 × ATR14** (Low 기준 트리거)
> - TP = **2.0 × ATR14** (Win 기준 — CE Trailing Stop 또는 Timeout 30봉 도달 시)
> - 마찰비용 = **30포인트 ($0.30)**
> - 실전 하드 필터 = **ADXMTF_M30_DiPlus > 35** (AI 모델 앞단에만 적용, 라벨링에는 포함 안 함)
> - 3-Barrier 라벨링은 **전봉 생성** (AI가 ADXMTF 피처를 스스로 학습)
> - **AI 모델 결과**: A+B+C 통합 → M30>35+thr=0.25시 **승률 56.3%** (AUC=0.8298)

> [!NOTE]
> **역할 구분**
> - **이 워크플로우 (탐색용)**: `sim_YYYY_uptrend.parquet` 슬라이스로 빠른 실험
> - **실제 라벨 생성**: `build_labels_barrier.py` (전체 740만봉, `/data-build` Step 2)

> [!CAUTION]
> **전제 조건**: 탐색 시뮬레이션 파일이 존재해야 합니다.
> - `Files/processed/sim_YYYY_uptrend.parquet` (시뮬레이션 구간 슬라이스)
> - `Files/processed/tech_features.parquet` (CE_CE2, ATR14 원천)

---

## 전제 조건 확인

```powershell
dir "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\processed\sim_*_uptrend.parquet"
dir "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\processed\tech_features.parquet"
```

---

## Step 1: TP 배수별 비교 시뮬레이션

> **입력**: `sim_YYYY_uptrend.parquet` + `tech_features.parquet` (CE_CE2, ATR14)  
> **출력**: TP=2.0/2.5/3.0/3.5 Win CSV 4개 (`Files/ce_trailing_wins_TP*.csv`)

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\sim_label_ce_trailing_multi.py"
```

**예상 소요**: ~15초  
**검증 포인트**: `TP=2.0: ~32,760 Win (8.0%)` 확인

**참고 — 확정된 비교 결과 (sim_2019_uptrend.parquet, 410,392행 기준)**:

| TP (×ATR) | Win 수 | 승률 | AvgPnL | CSV |
|:---:|---:|:---:|:---:|:---|
| **2.0** | **32,760** | **8.0%** | 1.63 | `ce_trailing_wins_TP2.0.csv` |
| 2.5 | 27,940 | 6.8% | 1.77 | `ce_trailing_wins_TP2.5.csv` |
| 3.0 | 23,778 | 5.8% | 1.91 | `ce_trailing_wins_TP3.0.csv` |
| 3.5 | 20,169 | 4.9% | 2.04 | `ce_trailing_wins_TP3.5.csv` |

---

## Step 2: ADXMTF 필터 비교 시뮬레이션

> **입력**: `sim_YYYY_uptrend.parquet` (TP=2.0 고정)  
> **출력**: M30/H1 필터 7조합 비교표 + Win CSV 2개

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\sim_adxmtf_filter_compare.py"
```

**예상 소요**: ~10초  
**검증 포인트**: `M30 DiPlus>35 → 승률 13.3%` 확인

**참고 — 확정된 비교 결과**:

| 필터 | 봉 수 | Win | 승률 | 채택 |
|:---|---:|---:|:---:|:---:|
| 없음 (기준선) | 410,358 | 32,760 | 8.0% | — |
| **M30 DiPlus > 35** | **18,220** | **2,426** | **13.3%** | **✅** |
| H1 DiPlus > 35 | 17,251 | 2,088 | 12.1% | — |
| DiPlus<15 & DiMinus>40 차단 | 406,429 | 32,557 | 8.0% | ❌ 효과 없음 |

> **핵심 발견**: DiMinus 추가 조건은 중복 불필요 (DiPlus>35 구간에서 이미 DiMinus가 낮음)

---

## Step 3: MT5 시각적 검증

> **목적**: 녹색 점이 실제 상승 추세의 눌림목에 집중되는지 육안 확인

### 3-1. MQ5 스크립트 컴파일 (처음에만)
```powershell
& "C:\Program Files\MetaTrader5\MetaEditor64.exe" /compile:"Scripts\ShowLabelingResult.mq5" /log
```
**검증**: `Result: 0 errors, 0 warnings`

### 3-2. MT5에서 시각화

1. MT5 → XAUUSD M1 차트 → `ShowLabelingResult` 드래그&드롭
2. Input 창에서 CSV 선택:

| 검증 목적 | 파일명 | 건수 |
|:---|:---|---:|
| TP=2.0 전체 Win | `ce_trailing_wins_TP2.0.csv` | 32,760 |
| DiPlus>35 필터 적용 Win | `adxmtf_wins_C_M30_DipDim.csv` | 2,426 |
| **AI 모델 A+B+C 신호** ⭐ | **`ABC_signals_M30gt35_thr025.csv`** | **503** |

3. 확인 사항:
   - 녹색 점이 상승 추세 눌림목에서 자주 등장하는가
   - 하향추세 구간에서 점이 거의 없는가 (DiPlus>35 CSV)
   - AI 신호가 필터 Win과 겹치되 더 선별적인가 (ABC CSV)
   - 점 호버 → 진입가/청산가/PnL/청산유형 확인

---

## Step 4: 새로운 조건 탐색 (선택)

### TP 값 변경
`sim_label_ce_trailing_multi.py` 상단 수정:
```python
TP_LEVELS = [2.0, 2.5, 3.0, 3.5]  # 원하는 값으로 수정
```

### 새로운 필터 추가
`sim_adxmtf_filter_compare.py`의 `FILTERS` 딕셔너리에 추가:
```python
"H. 새 필터명": (dip_m30 > 30),  # 원하는 조건으로 변경
```

---

## 확정 결론 (2026-03-09 갱신)

> 상세 시뮬레이션 결과는 `Docs/TrendTrading Development Strategy/Labeling.md` 참조

| 항목 | 확정값 | 실적 |
|:---|:---|:---|
| SL | 2.5 × ATR14 (Low 기준) | — |
| TP | **2.0 × ATR14** | — |
| 타임아웃 | 30봉 | — |
| 마찰비용 | 30포인트 | — |
| 전봉 Win 비율 | — | **7.89%** (586,103/7,424,357봉) |
| AI 데이터셋 Win 비율 | — | **9.5%** (252,959/2,659,938행) |
| 실전 하드 필터 | **ADXMTF_M30_DiPlus > 35** | 8.0%→13.3% (+5.3%p) |
| **AI 모델 (A+B+C)** | **M30>35 + thr=0.25** | **56.3% (549건, AUC=0.8298)** |
| AI 스나이퍼 | M30>35 + thr=0.30 | 63.4% (172건) |

---

## 스크립트 목록

| 스크립트 | 역할 | 위치 |
|:---|:---|:---|
| `build_labels_barrier.py` | **실제 전봉 라벨 생성** (740만행, `/data-build` Step 2) | `Files/Tools/` |
| `sim_label_ce_trailing_multi.py` | TP 배수별 탐색 비교 + CSV 생성 | `Files/Tools/` |
| `sim_adxmtf_filter_compare.py` | ADXMTF 필터 조합 탐색 + Win CSV 생성 | `Files/Tools/` |
| `extract_ABC_signals.py` | **AI 신호 CSV 추출** (M30>35+thr=0.25, 503건) | `Files/Tools/` |
| `ShowLabelingResult.mq5` | MT5 시각화 (녹색 점) | `Scripts/` |
