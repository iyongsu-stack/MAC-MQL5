# =============================================================================
# build_total_result.py
# =============================================================================
# Purpose : Run 17 MQL5 indicator Python implementations sequentially,
#           merge results into a single CSV dataset.
# Data    : BWMFI_MTF_DownLoad.csv (M1 OHLCV base data)
# Period  : Output 2018-05-01 ~ 2019-01-31 (strict)
#           Warmup load from 2017-11-01 (6 months prior)
# Output  : Files/TotalResult_YYYY_MM_DD_N.csv
# =============================================================================

import os
import sys
import math
import datetime
import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# Path Setup
# ---------------------------------------------------------------------------
MQL5_ROOT = os.path.join(
    os.getenv('APPDATA'),
    r'MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5'
)
SCRIPTS_DIR = os.path.join(MQL5_ROOT, 'Scripts')
FILES_DIR   = os.path.join(MQL5_ROOT, 'Files')

if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

# ---------------------------------------------------------------------------
# Period Constants
# ---------------------------------------------------------------------------
WARMUP_START  = pd.Timestamp('2017-11-01')   # 6-month warmup before target
OUTPUT_START  = pd.Timestamp('2018-05-01')
OUTPUT_END    = pd.Timestamp('2019-01-31 23:59:59')

# ---------------------------------------------------------------------------
# Import existing indicator modules
# ---------------------------------------------------------------------------
from BOPAvgStd_Verifier          import calculate_bop_avg_std
from LRAVGSTD_Verifier           import calculate_lravgstd
from BOPWmaSmooth_Calc_and_Verify import calculate_bop_wma
from BSPWmaSmooth_Converter      import calculate_bsp_wma_smooth
from Chaikin_Verification        import calculate_chaikin
from TDI_Verifier                import calculate_tdi
from QQE_Verification            import calculate_qqe
import adx_verifier              as adx_mod
from chandelier_exit_verifier    import calculate_chandelier
import chopping_verifier         as chop_mod
from ADXSmoothMTF_Converter      import calculate_adx_smooth_mtf
from BWMFI_MTF_Converter         import calculate_bwmfi_mtf

# ---------------------------------------------------------------------------
# Fix: ADXSmoothMTF_Converter bug (ALPHA1 uppercase NameError)
# Patch the function locally
# ---------------------------------------------------------------------------
import ADXSmoothMTF_Converter as adxmtf_mod

def calculate_adx_smooth_mtf_fixed(df, target_timeframe='4h', period=14, alpha1=0.25, alpha2=0.33):
    """Patched version: fixes ALPHA1 NameError in original file."""
    import numpy as np

    MQL5_TO_PANDAS_TF = {
        'PERIOD_M1': '1min', 'PERIOD_M5': '5min', 'PERIOD_M15': '15min',
        'PERIOD_M30': '30min', 'PERIOD_H1': '1h', 'PERIOD_H4': '4h',
        'PERIOD_D1': '1D', 'PERIOD_W1': '1W', 'PERIOD_MN1': '1ME'
    }

    data = df.copy()
    if not isinstance(data.index, pd.DatetimeIndex):
        try:
            data.index = pd.to_datetime(data['Time'])
        except Exception:
            pass

    actual_timeframe = target_timeframe
    if actual_timeframe in MQL5_TO_PANDAS_TF:
        actual_timeframe = MQL5_TO_PANDAS_TF[actual_timeframe]

    if actual_timeframe:
        ts_data = data.resample(actual_timeframe).agg({
            'Open': 'first', 'High': 'max', 'Low': 'min', 'Close': 'last'
        }).dropna()
    else:
        ts_data = data

    high  = ts_data['High'].values
    low   = ts_data['Low'].values
    close = ts_data['Close'].values
    rates_total = len(ts_data)

    alpha_adx = 2.0 / (period + 1.0)
    tr_arr    = np.zeros(rates_total)
    pdm_ratio = np.zeros(rates_total)
    mdm_ratio = np.zeros(rates_total)

    for i in range(1, rates_total):
        h, l, cp = high[i], low[i], close[i-1]
        tr_val = max(h - l, abs(h - cp), abs(l - cp))
        tr_arr[i] = tr_val
        up   = h - high[i-1]
        down = low[i-1] - l
        dm_p = dm_m = 0.0
        if up > down and up > 0:   dm_p = up
        elif down > up and down > 0: dm_m = down
        if tr_val != 0.0:
            pdm_ratio[i] = 100.0 * dm_p / tr_val
            mdm_ratio[i] = 100.0 * dm_m / tr_val

    pdi = np.zeros(rates_total)
    ndi = np.zeros(rates_total)
    prev_p = prev_n = 0.0
    for i in range(1, rates_total):
        pdi[i] = pdm_ratio[i] * alpha_adx + prev_p * (1.0 - alpha_adx)
        ndi[i] = mdm_ratio[i] * alpha_adx + prev_n * (1.0 - alpha_adx)
        prev_p, prev_n = pdi[i], ndi[i]

    with np.errstate(divide='ignore', invalid='ignore'):
        sum_di   = pdi + ndi
        safe_sum = np.where(sum_di == 0, 1e-9, sum_di)
        dx = 100.0 * np.abs(pdi - ndi) / safe_sum

    adx_raw = np.zeros(rates_total)
    prev_a  = 0.0
    for i in range(1, rates_total):
        adx_raw[i] = dx[i] * alpha_adx + prev_a * (1.0 - alpha_adx)
        prev_a = adx_raw[i]

    di_plus_final  = np.zeros(rates_total)
    di_minus_final = np.zeros(rates_total)
    adx_final      = np.zeros(rates_total)
    last_p = last_m = last_a = 0.0

    for i in range(1, rates_total):
        # Level 1 smoothing (fixed: alpha1 lowercase)
        val_p = 2 * pdi[i]     + (alpha1 - 2) * pdi[i-1]     + (1 - alpha1) * last_p
        val_m = 2 * ndi[i]     + (alpha1 - 2) * ndi[i-1]     + (1 - alpha1) * last_m
        val_a = 2 * adx_raw[i] + (alpha1 - 2) * adx_raw[i-1] + (1 - alpha1) * last_a
        last_p, last_m, last_a = val_p, val_m, val_a
        # Level 2 smoothing
        di_plus_final[i]  = alpha2 * val_p + (1 - alpha2) * di_plus_final[i-1]
        di_minus_final[i] = alpha2 * val_m + (1 - alpha2) * di_minus_final[i-1]
        adx_final[i]      = alpha2 * val_a + (1 - alpha2) * adx_final[i-1]

    ts_data = ts_data.copy()
    ts_data['DiPlus_Final']  = di_plus_final
    ts_data['DiMinus_Final'] = di_minus_final
    ts_data['ADX_Final']     = adx_final

    if actual_timeframe:
        result = data[['Close']].copy()
        result = result.join(ts_data[['DiPlus_Final', 'DiMinus_Final', 'ADX_Final']], how='left')
        result.ffill(inplace=True)
        return result
    else:
        return ts_data[['DiPlus_Final', 'DiMinus_Final', 'ADX_Final']]


# ---------------------------------------------------------------------------
# Phase 1: Load Base Data
# ---------------------------------------------------------------------------
def phase1_load_data():
    print("=" * 60)
    print("[Phase 1] 기본 데이터 로드")
    print("=" * 60)

    base_path = os.path.join(FILES_DIR, 'BWMFI_MTF_DownLoad.csv')
    if not os.path.exists(base_path):
        raise FileNotFoundError(f"기본 데이터 파일 없음: {base_path}")

    # Read with tab separator (MQL5 default)
    df = pd.read_csv(base_path, sep='\t')
    df.columns = [c.strip() for c in df.columns]

    # Parse datetime (MQL5 format: 2018.05.01 00:00)
    df['Time'] = pd.to_datetime(df['Time'], format='%Y.%m.%d %H:%M')

    # Sort ascending
    df = df.sort_values('Time').reset_index(drop=True)

    # BWMFI, BWMFI_Color 컬럼 제거 (M1 현재봉 값 — 분석 불필요)
    df = df.drop(columns=['BWMFI', 'BWMFI_Color'], errors='ignore')

    # Load warmup + output range
    df_warmup = df[df['Time'] >= WARMUP_START].copy().reset_index(drop=True)

    print(f"  전체 데이터 범위: {df['Time'].min()} ~ {df['Time'].max()}")
    print(f"  웜업 포함 로드 범위: {df_warmup['Time'].min()} ~ {df_warmup['Time'].max()}")
    print(f"  웜업 포함 행 수: {len(df_warmup):,}")

    return df_warmup


# ---------------------------------------------------------------------------
# Phase 2: Run All 17 Indicators
# ---------------------------------------------------------------------------
def phase2_run_indicators(df_warmup):
    print()
    print("=" * 60)
    print("[Phase 2] 인디케이터 계산 (17개)")
    print("=" * 60)

    result = df_warmup.copy()
    n = len(result)

    # ── 1. BOP (BOPAvgStd, 디폴트) ──────────────────────────────────────
    print("  [1/17] BOP (BOPAvgStd, 디폴트)...", end=' ')
    r = calculate_bop_avg_std(result.copy())
    if r is not None:
        result['BOP_Diff']  = r['Diff'].values
        result['BOP_Up1']   = r['Up1'].values
        result['BOP_Scale'] = r['Scale_Py'].values
        print("DONE")
    else:
        result['BOP_Diff'] = result['BOP_Up1'] = result['BOP_Scale'] = np.nan
        print("FAIL")

    # ── 2. LRAVGST Avg(60) ──────────────────────────────────────────────
    print("  [2/17] LRAVGST Avg(60)...", end=' ')
    r = calculate_lravgstd(result.copy(), avg_period=60)
    if r is not None:
        result['LRAVGST_Avg(60)_StdS']     = r['Py_stdS'].values
        result['LRAVGST_Avg(60)_BSPScale'] = r['Py_BSPScale'].values
        print("DONE")
    else:
        result['LRAVGST_Avg(60)_StdS'] = result['LRAVGST_Avg(60)_BSPScale'] = np.nan
        print("FAIL")

    # ── 3. LRAVGST Avg(180) ─────────────────────────────────────────────
    print("  [3/17] LRAVGST Avg(180)...", end=' ')
    r = calculate_lravgstd(result.copy(), avg_period=180)
    if r is not None:
        result['LRAVGST_Avg(180)_StdS']     = r['Py_stdS'].values
        result['LRAVGST_Avg(180)_BSPScale'] = r['Py_BSPScale'].values
        print("DONE")
    else:
        result['LRAVGST_Avg(180)_StdS'] = result['LRAVGST_Avg(180)_BSPScale'] = np.nan
        print("FAIL")

    # ── 4. BOPWMA (10, 3) ───────────────────────────────────────────────
    # [WARNING] Absolute value is meaningless due to cumulative sum initialization.
    # Analytical Focus: Relative Change (Slope), Acceleration (Slope of Slope) ONLY.
    print("  [4/17] BOPWMA (10,3)...", end=' ')
    r = calculate_bop_wma(result.copy(), wma_period=10, smooth_period=3)
    if r is not None:
        result['BOPWMA_(10,3)_SmoothBOP'] = r['PySmoothBOP'].values
        print("DONE")
    else:
        result['BOPWMA_(10,3)_SmoothBOP'] = np.nan
        print("FAIL")

    # ── 5. BOPWMA (30, 5) ───────────────────────────────────────────────
    # [WARNING] Absolute value is meaningless. Use Slope/Acceleration only.
    print("  [5/17] BOPWMA (30,5)...", end=' ')
    r = calculate_bop_wma(result.copy(), wma_period=30, smooth_period=5)
    if r is not None:
        result['BOPWMA_(30,5)_SmoothBOP'] = r['PySmoothBOP'].values
        print("DONE")
    else:
        result['BOPWMA_(30,5)_SmoothBOP'] = np.nan
        print("FAIL")

    # ── 6. BSPWMA (10, 3) ───────────────────────────────────────────────
    # [WARNING] Absolute value is meaningless. Use Slope/Acceleration only.
    print("  [6/17] BSPWMA (10,3)...", end=' ')
    r = calculate_bsp_wma_smooth(result.copy(), wma_period=10, smooth_period=3)
    if r is not None:
        result['BSPWMA_(10,3)_SmoothDiffRatio'] = r['MySmoothDiffRatio'].values
        print("DONE")
    else:
        result['BSPWMA_(10,3)_SmoothDiffRatio'] = np.nan
        print("FAIL")

    # ── 7. BSPWMA (30, 5) ───────────────────────────────────────────────
    # [WARNING] Absolute value is meaningless. Use Slope/Acceleration only.
    print("  [7/17] BSPWMA (30,5)...", end=' ')
    r = calculate_bsp_wma_smooth(result.copy(), wma_period=30, smooth_period=5)
    if r is not None:
        result['BSPWMA_(30,5)_SmoothDiffRatio'] = r['MySmoothDiffRatio'].values
        print("DONE")
    else:
        result['BSPWMA_(30,5)_SmoothDiffRatio'] = np.nan
        print("FAIL")

    # ── 8. CHV (10, 10) ─────────────────────────────────────────────────
    print("  [8/17] CHV (10,10)...", end=' ')
    r = calculate_chaikin(result.copy(), smooth_period=10, chv_period=10)
    if r is not None:
        result['CHV_(10,10)_CHV']    = r['Py_CHV'].values
        result['CHV_(10,10)_StdDev'] = r['Py_StdDev'].values
        result['CHV_(10,10)_CVScale']= r['Py_CVScale'].values
        print("DONE")
    else:
        result['CHV_(10,10)_CHV'] = result['CHV_(10,10)_StdDev'] = result['CHV_(10,10)_CVScale'] = np.nan
        print("FAIL")

    # ── 9. TDI (13, 34, 2, 7) ───────────────────────────────────────────
    # Note: vol_period=34 is not used in calculate_tdi (RSI-based only)
    print("  [9/17] TDI (13,34,2,7)...", end=' ')
    r = calculate_tdi(result.copy(), rsi_period=13, smooth_rsi_period=2, signal_period=7)
    if r is not None:
        result['TDI_(13,34,2,7)_TrSi']   = r['Py_TrSi'].values
        result['TDI_(13,34,2,7)_Signal']  = r['Py_Signal'].values
        print("DONE")
    else:
        result['TDI_(13,34,2,7)_TrSi'] = result['TDI_(13,34,2,7)_Signal'] = np.nan
        print("FAIL")

    # ── 10. QQE (SF=5, RSI=14) ──────────────────────────────────────────
    print("  [10/17] QQE (5,14)...", end=' ')
    r = calculate_qqe(result.copy(), rsi_period=14, sf=5)
    if r is not None:
        result['QQE_(5,14)_RSI']      = r['Py_RSI'].values
        result['QQE_(5,14)_RsiMa']    = r['Py_RsiMa'].values
        result['QQE_(5,14)_TrLevel']  = r['Py_TrLevel'].values
        print("DONE")
    else:
        result['QQE_(5,14)_RSI'] = result['QQE_(5,14)_RsiMa'] = result['QQE_(5,14)_TrLevel'] = np.nan
        print("FAIL")

    # ── 11. ADXSmooth (Vma=10, Smooth=5) → ADX_PERIOD=10 ───────────────
    print("  [11/17] ADXS (10,5)...", end=' ')
    # Patch global variables before calling
    adx_mod.ADX_PERIOD = 10
    adx_mod.ALPHA1     = 0.25
    adx_mod.ALPHA2     = 0.33
    adx_mod.AVG_PERIOD = 1000
    adx_mod.STD_PERIOD = 4000
    r = adx_mod.calculate_adx(result.copy())
    if r is not None:
        result['ADXS_(10,5)_ADX']   = r['Py_ADX'].values
        result['ADXS_(10,5)_Avg']   = r['Py_Avg'].values
        result['ADXS_(10,5)_Scale'] = r['Py_Scale'].values
        print("DONE")
    else:
        result['ADXS_(10,5)_ADX'] = result['ADXS_(10,5)_Avg'] = result['ADXS_(10,5)_Scale'] = np.nan
        print("FAIL")

    # ── 12. ChandelierExit (디폴트) ─────────────────────────────────────
    print("  [12/17] CE (디폴트)...", end=' ')
    r = calculate_chandelier(result.copy())
    if r is not None:
        result['CE_Upl1'] = r['Py_Upl1'].values
        result['CE_Dnl1'] = r['Py_Dnl1'].values
        result['CE_Upl2'] = r['Py_Upl2'].values
        result['CE_Dnl2'] = r['Py_Dnl2'].values
        print("DONE")
    else:
        result['CE_Upl1'] = result['CE_Dnl1'] = result['CE_Upl2'] = result['CE_Dnl2'] = np.nan
        print("FAIL")

    # ── 13. ChoppingIndex (Cho=14, Smooth=14) ───────────────────────────
    print("  [13/17] CHOP (14,14)...", end=' ')
    # Patch global variables
    chop_mod.INP_CHO_PERIOD    = 14
    chop_mod.INP_SMOOTH_PERIOD = 14
    chop_mod.INP_AVG_PERIOD    = 1000
    chop_mod.INP_STD_PERIOD    = 4000
    chop_mod.INP_SMOOTH_PHASE  = 0.0
    r = chop_mod.calculate_chopping(result.copy())
    if r is not None:
        result['CHOP_(14,14)_CSI']   = r['Py_CSI'].values
        result['CHOP_(14,14)_Avg']   = r['Py_Avg'].values
        result['CHOP_(14,14)_Scale'] = r['Py_Scale'].values
        print("DONE")
    else:
        result['CHOP_(14,14)_CSI'] = result['CHOP_(14,14)_Avg'] = result['CHOP_(14,14)_Scale'] = np.nan
        print("FAIL")

    # ── 14. ADXSmoothMTF H4 ─────────────────────────────────────────────
    print("  [14/17] ADXMTF H4...", end=' ')
    # Prepare DatetimeIndex for MTF functions
    df_mtf = result.copy()
    df_mtf.index = pd.to_datetime(df_mtf['Time'])
    r = calculate_adx_smooth_mtf_fixed(df_mtf, target_timeframe='4h', period=14)
    if r is not None:
        # Limit ffill to output range only (no leakage)
        r = r.reindex(df_mtf.index)
        result['ADXMTF_H4_DiPlus']  = r['DiPlus_Final'].values
        result['ADXMTF_H4_DiMinus'] = r['DiMinus_Final'].values
        result['ADXMTF_H4_ADX']     = r['ADX_Final'].values
        print("DONE")
    else:
        result['ADXMTF_H4_DiPlus'] = result['ADXMTF_H4_DiMinus'] = result['ADXMTF_H4_ADX'] = np.nan
        print("FAIL")

    # ── 15. ADXSmoothMTF M5 ─────────────────────────────────────────────
    print("  [15/17] ADXMTF M5...", end=' ')
    r = calculate_adx_smooth_mtf_fixed(df_mtf, target_timeframe='5min', period=14)
    if r is not None:
        r = r.reindex(df_mtf.index)
        result['ADXMTF_M5_DiPlus']  = r['DiPlus_Final'].values
        result['ADXMTF_M5_DiMinus'] = r['DiMinus_Final'].values
        result['ADXMTF_M5_ADX']     = r['ADX_Final'].values
        print("DONE")
    else:
        result['ADXMTF_M5_DiPlus'] = result['ADXMTF_M5_DiMinus'] = result['ADXMTF_M5_ADX'] = np.nan
        print("FAIL")

    # ── 16. BWMFI_MTF H4 ────────────────────────────────────────────────
    print("  [16/17] BWMTF H4...", end=' ')
    df_bw = result.copy()
    df_bw.index = pd.to_datetime(df_bw['Time'])
    # [FIX] point=0.01 (XAUUSD): 올바른 공식 = (High-Low) / Point / Volume
    r = calculate_bwmfi_mtf(df_bw, target_timeframe='PERIOD_H4', volume_col='TickVolume', point=0.01)
    if r is not None:
        result['BWMTF_H4_BWMFI'] = r['BWMFI'].values
        result['BWMTF_H4_Color'] = r['BWMFI_Color'].values
        print("DONE")
    else:
        result['BWMTF_H4_BWMFI'] = result['BWMTF_H4_Color'] = np.nan
        print("FAIL")

    # ── 17. BWMFI_MTF M5 ────────────────────────────────────────────────
    print("  [17/17] BWMTF M5...", end=' ')
    # [FIX] point=0.01 (XAUUSD): 올바른 공식 = (High-Low) / Point / Volume
    r = calculate_bwmfi_mtf(df_bw, target_timeframe='PERIOD_M5', volume_col='TickVolume', point=0.01)
    if r is not None:
        result['BWMTF_M5_BWMFI'] = r['BWMFI'].values
        result['BWMTF_M5_Color'] = r['BWMFI_Color'].values
        print("DONE")
    else:
        result['BWMTF_M5_BWMFI'] = result['BWMTF_M5_Color'] = np.nan
        print("FAIL")

    return result


# ---------------------------------------------------------------------------
# Phase 3: Filter to output range + Validate
# ---------------------------------------------------------------------------
def phase3_filter_and_validate(df_full):
    print()
    print("=" * 60)
    print("[Phase 3] 기간 필터링 및 무결성 검증")
    print("=" * 60)

    # Apply strict output filter
    df = df_full[
        (df_full['Time'] >= OUTPUT_START) &
        (df_full['Time'] <= OUTPUT_END)
    ].copy().reset_index(drop=True)

    base_rows = len(df)
    print(f"  시작일: {df['Time'].min()}")
    print(f"  종료일: {df['Time'].max()}")
    print(f"  총 행 수: {base_rows:,}")

    # Validation checks
    all_pass = True

    # 1. Date range
    if df['Time'].min() >= OUTPUT_START:
        print("  [PASS] 시작일 >= 2018-05-01")
    else:
        print("  [FAIL] 시작일 범위 초과!")
        all_pass = False

    if df['Time'].max() <= OUTPUT_END:
        print("  [PASS] 종료일 <= 2019-01-31")
    else:
        print("  [FAIL] 종료일 범위 초과!")
        all_pass = False

    # 2. No data beyond output end
    beyond = df[df['Time'] > OUTPUT_END]
    if len(beyond) == 0:
        print("  [PASS] 기간 외 데이터 없음 (0건)")
    else:
        print(f"  [FAIL] 기간 외 데이터 {len(beyond)}건 발견!")
        all_pass = False

    # 3. NaN ratio per indicator column
    base_cols = ['Time', 'Open', 'High', 'Low', 'Close', 'TickVolume']
    indicator_cols = [c for c in df.columns if c not in base_cols]

    print()
    print("  NaN 비율 검증 (< 5% 기준):")
    nan_issues = []
    for col in indicator_cols:
        nan_ratio = df[col].isna().mean()
        status = "PASS" if nan_ratio < 0.05 else "WARNING"
        if nan_ratio > 0:
            print(f"    [{status}] {col}: {nan_ratio*100:.2f}%")
        if nan_ratio >= 0.05:
            nan_issues.append(col)

    if not nan_issues:
        print("    [PASS] 모든 컬럼 NaN < 5%")
    else:
        print(f"    [WARNING] NaN >= 5% 컬럼: {nan_issues}")

    # 4. Column order
    ordered_cols = ['Time', 'Open', 'Close', 'High', 'Low', 'TickVolume'] + indicator_cols
    # Only keep columns that exist
    ordered_cols = [c for c in ordered_cols if c in df.columns]
    df = df[ordered_cols]

    print()
    if all_pass:
        print("  [PASS] 전체 검증 통과")
    else:
        print("  [WARNING] 일부 검증 실패 — 결과 파일은 저장되지만 확인 필요")

    return df, base_rows


# ---------------------------------------------------------------------------
# Phase 4: Save Output
# ---------------------------------------------------------------------------
def phase4_save(df):
    print()
    print("=" * 60)
    print("[Phase 4] 파일 저장")
    print("=" * 60)

    today = datetime.date.today()
    date_str = today.strftime('%Y_%m_%d')

    # Auto-increment N
    n = 1
    while True:
        filename = f"TotalResult_{date_str}_{n}.csv"
        out_path = os.path.join(FILES_DIR, filename)
        if not os.path.exists(out_path):
            break
        n += 1

    # Final pre-save report
    print(f"  Time min : {df['Time'].min()}")
    print(f"  Time max : {df['Time'].max()}")
    print(f"  총 행 수  : {len(df):,}")
    print(f"  총 컬럼 수: {len(df.columns)}")

    df.to_csv(out_path, index=False, encoding='utf-8-sig')
    print(f"  저장 완료: {out_path}")

    return out_path


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if __name__ == '__main__':
    print()
    print("=" * 60)
    print("  build_total_result.py 시작")
    print(f"  웜업 시작: {WARMUP_START.date()}")
    print(f"  출력 범위: {OUTPUT_START.date()} ~ {OUTPUT_END.date()}")
    print("=" * 60)

    # Phase 1
    df_warmup = phase1_load_data()

    # Phase 2
    df_full = phase2_run_indicators(df_warmup)

    # Phase 3
    df_output, base_rows = phase3_filter_and_validate(df_full)

    # Phase 4
    out_path = phase4_save(df_output)

    print()
    print("=" * 60)
    print("  완료!")
    print(f"  출력 파일: {out_path}")
    print("=" * 60)
