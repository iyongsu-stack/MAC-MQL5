---
description: AI 학습용 데이터셋 자동 빌드 — 기술 피처 파생 → 라벨링 → 매크로 병합 → 검증
---
// turbo-all

# AI 학습 데이터셋 빌드 워크플로우 (/data-build)

> **목적**: 수집된 원본 데이터(`TotalResult_*.parquet`, `macro_features.parquet`)를 기반으로
> AI 학습용 최종 데이터셋(`AI_Study_Dataset.parquet`)을 자동 생성합니다.

> [!IMPORTANT]
> **🚨 AI 전략 개발 3대 핵심 원칙 (자동 적용됨)**
> 1. **Shift+1 원칙**: Z-score 계산 시 `x.shift(1).rolling(W)` 사용, Macro 병합 전 `shift(1)` 적용
> 2. **Friction Cost 30포인트**: `build_labels_barrier.py`에서 라벨링 시 자동 차감
> 3. **절대값 사용 금지**: `build_tech_derived.py`에서 파생 피처(Z-score/Slope/Ratio)로 자동 변환

> [!CAUTION]
> **전제 조건**: 이 워크플로우를 실행하기 전, `/data-fetch` 워크플로우가 완료되어
> `Files/processed/` 아래에 원본 Parquet 파일들이 존재해야 합니다.

---

## 전제 조건 확인

1. 원본 기술 지표 Parquet 파일 존재 확인:
```powershell
dir "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\processed\TotalResult_*.parquet"
```

2. 매크로 피처 Parquet 파일 존재 확인:
```powershell
dir "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\processed\macro_features.parquet"
```

---

## Step 1: 기술 지표 파생 변환 (build_tech_derived.py)

> **입력**: `TotalResult_*_pH4.parquet` (63개 원본 컬럼)
> **출력**: `tech_features_derived.parquet` (~94개 파생 피처)
> **핵심 로직**:
> - Z-score: `x.shift(1).rolling(W)` (Shift+1 원칙으로 Look-ahead 방지)
> - MTF 변화점 기반: M5/H4 값 변화 시점에서만 Slope/Z-score 계산 후 ffill
> - BOPWMA/BSPWMA: Slope + Accel + Slope_Zscore만 허용 (원본 DROP)
> - CE: `(Close - CE) / ATR14` 비율 변환 (원본 DROP)
> - OHLC, TickVolume 원본: DROP

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\build_tech_derived.py"
```

**예상 소요**: ~30초
**검증 포인트**: `✅ 절대값 누수 없음` 메시지 확인

---

## Step 2: Triple Barrier 라벨링 (build_labels_barrier.py)

> **입력**: `TotalResult_*_pH4.parquet`
> **출력**: `labels_barrier.parquet`
> **핵심 로직**:
> - Setup 조건: Long = `LRAVGST_Avg(180)_BSPScale > 1.0`, Short = `< -1.0`
> - 학습 구간: 2012-2015 (하락장 숏) + 2019-2021 (상승장 롱)
> - 배리어: TP = ATR(14) × 1.0, SL = ATR(14) × 1.2, Time = 45봉
> - Friction Cost: $0.30 자동 차감

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\build_labels_barrier.py"
```

**예상 소요**: ~2분
**검증 포인트**: Long/Short 라벨 개수 및 승률 출력 확인

---

## Step 3: 피처 병합 (merge_features.py)

> **입력**: `tech_features_derived.parquet` + `macro_features.parquet` + `labels_barrier.parquet`
> **출력**: `AI_Study_Dataset.parquet`
> **핵심 로직**:
> - Macro 데이터 **Shift+1 선적용**: `df_macro[features].shift(1)` 으로 미래 참조 완전 차단
> - `merge_asof(direction="backward")`: 시간 기준 과거 매핑 (행 밀림 불가)
> - Labels: Left Join으로 학습 구간 데이터에만 라벨 부착

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\merge_features.py"
```

**예상 소요**: ~100초
**검증 포인트**: 최종 컬럼 수 ~460개, 행 수 ~315만

---

## Step 4: 병합 무결성 검증 (verify_merged_dataset.py)

> **입력**: `AI_Study_Dataset.parquet` + 원본 파일들
> **검증 항목**:
> 1. Macro Shift+1: 2019-01-02 M1봉에 2019-01-01 매크로 값이 매핑되는지
> 2. M5 변화점: 5봉 블록 내 Slope 동일값 유지 확인
> 3. H4 변화점: 4시간 블록 내 Slope 일관성 확인
> 4. Label 정합성: 학습 구간에만 라벨 존재, 비학습 구간 NaN

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\verify_merged_dataset.py"
```

**검증 포인트**: 모든 항목 `✅ PASS` 확인

---

## 파이프라인 요약

```
[/data-fetch]                          [/data-build (이 워크플로우)]
────────────                           ────────────────────────────────
MT5 → TotalResult.parquet  ─────────┐
Yahoo/FRED → macro_features.parquet ─┤
                                     │
                           Step 1: build_tech_derived.py
                                     │  (Z-score Shift+1, MTF 변화점, CE Ratio)
                                     ▼
                           tech_features_derived.parquet (94 cols)
                                     │
                           Step 2: build_labels_barrier.py
                                     │  (Triple Barrier, ATR 동적, Friction $0.30)
                                     ▼
                           labels_barrier.parquet (~24만 rows)
                                     │
                           Step 3: merge_features.py
                                     │  (Macro Shift+1, merge_asof, Label Left Join)
                                     ▼
                           AI_Study_Dataset.parquet (~460 cols, 315만 rows)
                                     │
                           Step 4: verify_merged_dataset.py
                                     │  (Shift+1, MTF, Label 무결성 검증)
                                     ▼
                           ✅ AI 학습 준비 완료
```

---

## 스크립트 목록

| 스크립트 | 역할 | 위치 |
|:---|:---|:---|
| `build_tech_derived.py` | 기술 지표 파생 변환 | `Files/Tools/` |
| `build_labels_barrier.py` | Triple Barrier 라벨링 | `Files/Tools/` |
| `merge_features.py` | 3개 Parquet 병합 | `Files/Tools/` |
| `verify_merged_dataset.py` | 병합 무결성 검증 | `Files/Tools/` |

> 파라미터(학습 구간, Setup 조건, ATR 배수 등)를 변경하려면 각 스크립트 상단의 설정 섹션을 수정 후 이 워크플로우를 재실행하세요.
