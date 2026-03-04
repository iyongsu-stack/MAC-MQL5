---
description: XAUUSD M1 원본 CSV → 마이크로 기술지표 Parquet 생성 (63컬럼, ~45분 소요)
---
// turbo-all

# 마이크로 기술지표 생성 워크플로우 (/data-merge-micro-tech)

> **목적**: Tickstory에서 다운로드한 XAUUSD M1 CSV를 입력받아,
> 검증된 12개 Python Verifier/Converter 스크립트를 활용하여
> `tech_features.parquet` (63개 컬럼)을 생성합니다.

> [!IMPORTANT]
> **⏱️ 소요 시간**: 약 **45분** (742만행 기준)
> **메모리**: 약 4~6GB RAM 사용. 각 단계별 `del` + `gc.collect()` 적용됨.

> [!CAUTION]
> **전제 조건**: `Files/raw/XAUUSD.csv` 파일이 존재해야 합니다.
> CSV 형식: `Time,Open,High,Low,Close,TickVolume` (Tickstory M1 표준)

---

## 전제 조건 확인

1. 원본 M1 CSV 파일 존재 확인:
```powershell
dir "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\raw\XAUUSD.csv"
```

---

## Step 1: 마이크로 기술지표 생성 (build_micro_tech.py)

> **입력**: `Files/raw/XAUUSD.csv` (M1 가격 데이터)
> **출력**: `Files/processed/tech_features.parquet` (63개 컬럼)
> **계산 지표 (15단계)**:
> 1. BOP (Balance of Power) — Diff, Up1, Scale
> 2-3. LRAVGST — Avg(60), Avg(180) × StdS, BSPScale
> 4-5. BOPWMA — (10-3), (30-5) × SmoothBOP
> 6-7. BSPWMA — (10-3), (30-5) × SmoothDiffRatio
> 8. CHV — (10-10) × CHV, StdDev, CVScale
> 9. TDI — (13-34-2-7) × TrSi, Signal
> 10. QQE — (5-14) × RSI, RsiMa, TrLevel
> 11. CE — Upl1, Dnl1, Upl2, Dnl2
> 12. CHOP — (14-14) × CSI, Avg, Scale
> 13. ADXMTF — H4, M5 × DiPlus, DiMinus, ADX
> 14. BWMTF — H4, M5 × BWMFI, Color
> 15. 추가 지표 — CHV(30-30), TDI(14-90-35), QQE(12-32), ADXS(14/80), CHOP(120-40)

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\build_micro_tech.py"
```

**예상 소요**: ~45분
**검증 포인트**: `✅ 기존 63개 컬럼 모두 포함` 메시지 확인

---

## Step 2: 기존 파일과 비교 검증 (compare_parquets.py)

> **입력**: 새로 생성된 `tech_features.parquet` + 기존 `TotalResult_*_pH4.parquet`
> **검증 항목**: 마지막 10분(10행) 데이터의 컬럼별 수치 일치 여부 대조

```powershell
C:\Python314\python.exe "c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Tools\compare_parquets.py"
```

**검증 포인트**: 불일치 컬럼이 0개이면 PASS. ADXMTF 관련 차이는 `ALPHA1` 버그 수정에 따른 정상 변경.

---

## 파이프라인 요약

```
[입력]                                 [/data-merge-micro-tech (이 워크플로우)]
────────                               ─────────────────────────────────────────

Files/raw/XAUUSD.csv ────────────┐
  (Tickstory M1), 742만행         │
                                  │
                        Step 1: build_micro_tech.py
                                  │  (12개 Verifier/Converter 스크립트 활용)
                                  │  (15단계 순차 계산, 각 단계별 메모리 해제)
                                  ▼
                        tech_features.parquet (63 cols, 742만 rows)
                                  │
                        Step 2: compare_parquets.py
                                  │  (기존 TotalResult 파일과 마지막 10분 대조)
                                  ▼
                        ✅ 기술 지표 원본 준비 완료
                                  │
                        ───── 후속 워크플로우 ─────
                        /data-build → 파생 변환 + 라벨링 + 매크로 병합
```

---

## 스크립트 목록

| 스크립트 | 역할 | 위치 |
|:---|:---|:---|
| `build_micro_tech.py` | M1 CSV → 63개 기술 지표 계산 | `Files/Tools/` |
| `compare_parquets.py` | 신규/기존 Parquet 대조 검증 | `Files/Tools/` |

## 의존 스크립트 (Scripts/ 내, build_micro_tech.py가 내부 import)

| 스크립트 | 지표 |
|:---|:---|
| `BOPAvgStd_Verifier.py` | BOP |
| `LRAVGSTD_Verifier.py` | LRAVGST |
| `BOPWmaSmooth_Calc_and_Verify.py` | BOPWMA |
| `BSPWmaSmooth_Converter.py` | BSPWMA |
| `Chaikin_Verification.py` | CHV |
| `TDI_Verifier.py` | TDI |
| `QQE_Verification.py` | QQE |
| `chandelier_exit_verifier.py` | CE |
| `chopping_verifier.py` | CHOP |
| `ADXSmoothMTF_Converter.py` | ADXMTF |
| `BWMFI_MTF_Converter.py` | BWMTF |
| `ATR_Verifier.py` | ATR |

> 새 지표를 추가하려면 `build_micro_tech.py`의 `main()` 함수에 계산 블록을 추가하고,
> `EXPECTED_COLS` 리스트에 컬럼명을 등록하세요.
