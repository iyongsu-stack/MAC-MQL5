"""
ATR (Average True Range) Python 독립 계산 및 MQL5 교차 검증 스크립트.
MQL5 ATRDownLoad.mq5의 롤링 SMA-14 ATR 로직을 Python으로 포팅.

워크플로우: /mql5-port-verify
원본: Indicators/Test/ATRDownLoad.mq5
"""
import pandas as pd
import numpy as np
import os

# --- Parameters (MQL5 input 변수와 동기화) ---
ATR_PERIOD = 14
TOLERANCE = 1e-5
WARMUP = ATR_PERIOD + 1  # 초기 14봉은 SMA 시드 구간

# --- 경로 설정 ---
MQL5_ROOT = r"C:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5"
CSV_PATH = os.path.join(MQL5_ROOT, "Files", "raw", "ATR_DownLoad.csv")
PARQ_DIR = os.path.join(MQL5_ROOT, "Files", "parquet")
PARQ_PATH = os.path.join(PARQ_DIR, "ATR_DownLoad.parquet")


def compute_atr(high: np.ndarray, low: np.ndarray, close: np.ndarray, period: int = 14) -> np.ndarray:
    """
    MQL5 ATRDownLoad.mq5의 ATR 계산 로직을 Python으로 직역.
    
    방식: 롤링 SMA (Simple Moving Average) of True Range
    - 초기값: TR[1..period]의 단순 평균
    - 증분: ATR[i] = ATR[i-1] + (TR[i] - TR[i-period]) / period
    
    Parameters:
        high, low, close: OHLC 가격 배열 (기초 데이터만 사용)
        period: ATR 기간 (기본값 14)
    
    Returns:
        ATR 배열 (초기 구간은 NaN)
    """
    n = len(close)
    tr = np.full(n, np.nan)
    atr = np.full(n, np.nan)

    # --- True Range 계산: TR[i] = max(high[i], close[i-1]) - min(low[i], close[i-1]) ---
    for i in range(1, n):
        tr[i] = max(high[i], close[i - 1]) - min(low[i], close[i - 1])

    # --- 초기 ATR: TR[1..period]의 단순 평균 (MQL5 초기화 로직 직역) ---
    cumul = 0.0
    for i in range(1, period + 1):
        cumul += tr[i]
    atr[period] = cumul / period

    # --- 증분 ATR: 롤링 SMA 방식 (새 값 추가, 가장 오래된 값 제거) ---
    for i in range(period + 1, n):
        atr[i] = atr[i - 1] + (tr[i] - tr[i - period]) / period

    return atr


def main():
    print("=" * 60)
    print("  ATR Python 독립 계산 및 교차 검증")
    print("=" * 60)

    # --- Phase 3: CSV 로드 ---
    print(f"\n[1] CSV 로드: {CSV_PATH}")
    df = pd.read_csv(CSV_PATH, sep='\t', low_memory=False)
    if df.shape[1] < 2:
        df = pd.read_csv(CSV_PATH, low_memory=False)
    df.columns = [c.strip() for c in df.columns]
    print(f"    행 수: {len(df):,}")
    print(f"    컬럼: {list(df.columns)}")

    # 숫자 변환
    for col in ['Open', 'Close', 'High', 'Low', 'ATR']:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    # --- Phase 3: Parquet 변환 ---
    os.makedirs(PARQ_DIR, exist_ok=True)
    df.to_parquet(PARQ_PATH, index=False)
    print(f"    Parquet 저장: {PARQ_PATH}")

    # --- Phase 4: Python 독립 연산 (OHLC만 사용) ---
    print(f"\n[2] Python ATR 독립 계산 (period={ATR_PERIOD})")
    H = df['High'].values
    L = df['Low'].values
    C = df['Close'].values

    py_atr = compute_atr(H, L, C, ATR_PERIOD)
    df['Py_ATR'] = py_atr

    # Parquet에 Python 계산 결과 병합 저장
    df.to_parquet(PARQ_PATH, index=False)
    print(f"    Py_ATR 컬럼 추가 완료 → Parquet 재저장")

    # --- Phase 5: 교차 검증 ---
    print(f"\n[3] 교차 검증 (허용 오차: {TOLERANCE}, Warm-up: {WARMUP}봉)")

    # MQL5의 EMPTY_VALUE (DBL_MAX) 행 제외 — 초기 미계산 구간
    DBL_MAX = 1.7976931348623157e+308
    df_check = df.iloc[WARMUP:].copy()
    df_check = df_check[df_check['ATR'] < DBL_MAX].copy()
    df_check = df_check.dropna(subset=['Py_ATR']).copy()

    mql_col = 'ATR'
    py_col = 'Py_ATR'

    diff = (df_check[mql_col] - df_check[py_col]).abs()
    max_err = diff.max()
    mean_err = diff.mean()
    fail_cnt = int((diff > TOLERANCE).sum())
    total_rows = len(df_check)

    # 결과 출력
    results = pd.DataFrame([{
        "컬럼 비교": f"{mql_col} vs {py_col}",
        "최대오차(MAE)": f"{max_err:.2e}",
        "평균오차": f"{mean_err:.2e}",
        "검증행수": total_rows,
        "불일치건수": fail_cnt,
        "판정": "✅ PASS" if fail_cnt == 0 else "❌ FAIL"
    }])

    print("\n" + results.to_string(index=False))

    if fail_cnt == 0:
        print(f"\n✅ 전체 PASS — ATR 교차 검증 완료")
    else:
        print(f"\n❌ FAIL — 불일치 {fail_cnt}건 발견")
        # 불일치 상위 5건 출력
        df_check['Diff'] = diff
        worst = df_check.nlargest(5, 'Diff')[['Time', mql_col, py_col, 'Diff']]
        print("\n불일치 상위 5건:")
        print(worst.to_string(index=False))

    return fail_cnt == 0


if __name__ == '__main__':
    main()
