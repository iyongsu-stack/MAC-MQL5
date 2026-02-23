---
description: MQL5 지표 변경 사항을 Python으로 포팅하고 교차 검증을 자동 수행 (Self-Refine 포함)
---

# MQL5 → Python 포팅 및 교차 검증 에이전트

## 역할 정의
이 워크플로우를 수행하는 AI는 다음 3가지 역할을 동시에 수행한다:
- **MQL5 Developer**: 코드 포팅 및 컴파일 검증
- **Quality Judge**: 데이터 무결성 및 허용 오차 판정 (기준: ≤ 1e-5)
- **Process Watchdog**: 단계 순서 준수 및 FAIL 시 자가 수정 루프 강제 실행

---

## 사전 조건: 매핑 테이블 참조
`Indicators/python_converter_list.md` 파일에서 대상 MQL5 파일에 대응하는 Python 파일을 먼저 확인한다.

| MQL5 파일 (Indicators/) | Python 파일 (Scripts/) |
|---|---|
| BOP/BOPAvgStdDownLoad.mq5 | BOPAvgStd_Verifier.py |
| BSP105V9/LRAVGSTDownLoad.mq5 | LRAVGSTD_Verifier.py |
| BOP/BOPWmaSmoothDownLoad.mq5 | BOPWmaSmooth_Calc_and_Verify.py |
| BSP105V9/BSPWmaSmoothDownLoad.mq5 | BSPWmaSmooth_Converter.py |
| BSP105V9/Chaikin VolatilityDownLoad.mq5 | Chaikin_Verification.py |
| Test/TradesDynamicIndexDownLoad.mq5 | TDI_Verifier.py |
| Test/QQE DownLoad.mq5 | QQE_Verification.py |
| Test/ADXSmoothDownLoad.mq5 | adx_verifier.py |
| Test/ChandelieExitDownLoad.mq5 | chandelier_exit_verifier.py |
| Test/ChoppingIndexDownLoad.mq5 | chopping_verifier.py |
| Test/ADXSmoothMTFDownLoad.mq5 | ADXSmoothMTF_Converter.py |
| Test/BWMFI_MTFDownLoad.mq5 | BWMFI_MTF_Converter.py |

---

## Phase 1: [MQL5 Developer] MQL5 변경 사항 파악 및 Python 포팅

1. 사용자가 변경한 MQL5 파일을 전체 읽기
2. 매핑 테이블에서 대응하는 Python 파일 경로 확인 후 전체 읽기
3. 두 파일을 비교하여 **불일치 항목** 식별:
   - 파라미터 값 (period, alpha, window 등)
   - 핵심 계산 로직 (공식, 초기값 처리 방식)
   - 통계 클래스 구현 (`HiAverage`, `HiStdDev1` 등)
   - 파일 쓰기 컬럼 순서
4. 불일치 항목을 Python 파일에 반영
5. **절대 원칙**: Python은 오직 **기초 데이터(OHLC, Time, Volume)만** 사용 — MQL5 계산 결과값을 연산 입력으로 사용 금지
6. 수정된 핵심 로직에 한국어 주석 추가

---

## Phase 2: [MQL5 Developer] MQL5 컴파일 검증

// turbo
1. MetaEditor64로 컴파일 실행:
```powershell
& "C:\Program Files\MetaTrader5\MetaEditor64.exe" /compile:"<대상MQL5파일전체경로>" /log
```

// turbo
2. 컴파일 로그 확인:
```powershell
Get-Content "<대상MQL5파일전체경로>.log"
```

3. `0 error(s), 0 warning(s)` 가 아니면 **즉시 코드 수정 후 재컴파일** (최대 3회)

---

## Phase 3: [Process Watchdog] MT5 데이터 추출 및 Parquet 변환

1. MT5에서 대상 DownLoad 지표를 차트에 적용하여 CSV 파일 생성
   - 출력 경로: `Files/raw/<지표명>_DownLoad.csv`
   - MT5 실행 경로 주의: `"C:\Program Files\MetaTrader5\terminal64.exe"` (공백 포함 → 반드시 큰따옴표)

// turbo
2. CSV → Parquet 변환:
```python
import pandas as pd, os, glob

MQL5_ROOT = r"C:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5"
csv_dir   = os.path.join(MQL5_ROOT, "Files", "raw")
parq_dir  = os.path.join(MQL5_ROOT, "Files", "parquet")
os.makedirs(parq_dir, exist_ok=True)

for csv_path in glob.glob(os.path.join(csv_dir, "*.csv")):
    try:
        df = pd.read_csv(csv_path, sep='\t')
        if df.shape[1] < 2:
            df = pd.read_csv(csv_path)
        df.columns = [c.strip() for c in df.columns]
        out = os.path.join(parq_dir, os.path.basename(csv_path).replace(".csv", ".parquet"))
        df.to_parquet(out, index=False)
        print(f"[OK] {os.path.basename(csv_path)} → {os.path.basename(out)} ({len(df)}행)")
    except Exception as e:
        print(f"[FAIL] {csv_path}: {e}")
```

---

## Phase 4: [Quality Judge] Python 독립 연산 및 결과 병합

1. Parquet에서 **기초 데이터(OHLCV)만** 로드 (MQL5 계산 컬럼 제외)
2. Phase 1에서 수정한 Python 파일의 계산 함수를 호출
3. 계산 결과를 Parquet DataFrame에 새 컬럼으로 추가 (접두사 `Py_`)
4. 병합 결과를 Parquet에 저장

---

## Phase 5: [Quality Judge] 교차 검증

// turbo
```python
import pandas as pd, numpy as np

TOLERANCE = 1e-5
WARMUP    = 200  # Wilder 방식 지표(ADX, RMA 등)는 초기 200봉 제외

df = pd.read_parquet(r"Files\parquet\<지표명>_DownLoad.parquet")
df_check = df.iloc[WARMUP:].copy()

# col_pairs: (MQL5 컬럼명, Python 계산 컬럼명) 쌍을 지표에 맞게 설정
col_pairs = [("ADX", "Py_ADX"), ("Average", "Py_Avg"), ("Scale", "Py_Scale")]

results  = []
all_pass = True

for mql_col, py_col in col_pairs:
    if mql_col not in df_check.columns or py_col not in df_check.columns:
        continue
    diff     = (df_check[mql_col] - df_check[py_col]).abs()
    max_err  = diff.max()
    fail_cnt = (diff > TOLERANCE).sum()
    if fail_cnt > 0: all_pass = False
    results.append({"컬럼": f"{mql_col} vs {py_col}",
                     "최대오차(MAE)": f"{max_err:.2e}",
                     "검증행수": len(df_check),
                     "불일치건수": fail_cnt,
                     "판정": "PASS" if fail_cnt == 0 else "FAIL"})

print(pd.DataFrame(results).to_string(index=False))
print(f"\n{'✅ 전체 PASS' if all_pass else '❌ FAIL — Phase 6 자가 수정 루프 진입'}")
```

**판정**: `불일치건수 == 0` → Phase 7 / `불일치건수 >= 1` → Phase 6

---

## Phase 6: [Process Watchdog] 자가 수정(Self-Refine) 루프

FAIL 판정 시 아래 표를 참조하여 Python 코드 수정 후 **Phase 4-5 반복** (최대 5회):

| 오류 유형 | 조치 방법 |
|---|---|
| 파라미터 불일치 | MQL5 `input` 변수값 → Python 상수 동기화 |
| Warm-up 불일치 | `WARMUP` 값 증가 또는 초기값 로직 재검토 |
| 공식 오류 | MQL5 공식 한 줄씩 Python 직역 (`prev_calculated < min_rates_total` 분기 주의) |
| HiAverage/HiStdDev 버그 | Drift Correction, 링버퍼 인덱스, `m_count` 카운팅 순서 재검토 |
| EMA vs Wilder's Smoothing | `alpha=2/(n+1)` vs `alpha=1/n` 방식 확인 |
| 부동소수점 누적 오차 | Warm-up 구간 확대, `numpy.float64` 정밀도 확인 |
| MTF 정렬 오류 | 바 경계 정렬 및 `resample` 기준 확인 |

---

## Phase 7: [Report] 최종 결과 보고

PASS 달성 시 다음 항목을 사용자에게 보고:

1. **포팅된 Python 코드** — 수정 핵심 로직에 한국어 주석 포함
2. **교차 검증 비교 보고서** (표 형식)

   | 컬럼 비교 | 최대오차(MAE) | 검증 행수 | 불일치건수 | 판정 |
   |---|---|---|---|---|
   | ADX vs Py_ADX | X.XXe-XX | N | 0 | ✅ PASS |

3. **데이터 파일 상태**: Parquet 변환 및 병합 완료 경로
4. **최종 판정**: PASS (자가 수정 루프 반복 횟수 포함)

---

## 공통 주의사항 (CRITICAL)

1. **Python 절대 원칙**: `df[mql_computed_col]` 을 계산 입력으로 사용 금지 — 오직 OHLCV만 허용
2. **경로 공백 처리**: `C:\Program Files\...` 경로는 반드시 큰따옴표로 감싸기
3. **BOPWMA/BSPWMA**: 절대값 기준 필터링 금지 — 기울기(Slope)/가속도(Acceleration)만 허용
4. **언어 규칙**: 설명은 한국어, 코드(변수명·함수명)는 영어
