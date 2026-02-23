"""
BWMTF M5/H4 검증 스크립트
MQL5 기준 BWMFI_MTF_DownLoad(5M).csv  &  (4H).csv 파일을
Python calculate_bwmfi_mtf() 로 재계산하여 수치 비교

실행: C:\Python314\python.exe verify_bwmtf.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import pandas as pd
import numpy as np

# ────────────────────────────────────────────────────────────────
# BWMFI MTF 계산 함수 (BWMFI_MTF_Converter.py 에서 인라인 복사)
# ────────────────────────────────────────────────────────────────
def calculate_bwmfi_mtf(df_in, target_tf_seconds, volume_col='TickVolume', point=0.01):
    """
    M1 기준 데이터를 target_tf_seconds 단위로 리샘플 후 BWMFI 계산.
    반환: 원본 인덱스로 ffill 된 DataFrame (BWMFI, BWMFI_Color)
    """
    # 리샘플 offset 문자열
    freq = f'{target_tf_seconds}s'
    agg = {'High':'max','Low':'min', volume_col:'sum'}
    if 'Close' in df_in.columns: agg['Close'] = 'last'
    if 'Open'  in df_in.columns: agg['Open']  = 'first'

    df = df_in.resample(freq).agg(agg).dropna()

    # MFI 계산
    vol = df[volume_col].astype(float)
    with np.errstate(divide='ignore', invalid='ignore'):
        mfi = (df['High'] - df['Low']) / point / vol
    mfi = mfi.replace([np.inf, -np.inf], np.nan).ffill().fillna(0.0)
    df['BWMFI'] = mfi

    # Color 계산 (MQL5 동일 – 상태 변수 유지)
    mfi_arr = df['BWMFI'].values
    vol_arr = vol.values
    color_arr = np.zeros(len(df))
    mfi_up = True; vol_up = True
    for i in range(1, len(df)):
        if mfi_arr[i] > mfi_arr[i-1]: mfi_up = True
        elif mfi_arr[i] < mfi_arr[i-1]: mfi_up = False
        if vol_arr[i] > vol_arr[i-1]: vol_up = True
        elif vol_arr[i] < vol_arr[i-1]: vol_up = False
        if mfi_up and vol_up:           color_arr[i] = 0.0
        elif not mfi_up and not vol_up: color_arr[i] = 1.0
        elif mfi_up and not vol_up:     color_arr[i] = 2.0
        elif not mfi_up and vol_up:     color_arr[i] = 3.0
    df['BWMFI_Color'] = color_arr

    # ffill → 원본 인덱스 (M1)
    result = df[['BWMFI','BWMFI_Color']].reindex(df_in.index, method='ffill')
    return result


# ────────────────────────────────────────────────────────────────
# 검증 함수
# ────────────────────────────────────────────────────────────────
def verify(csv_path, tf_seconds, tf_name, tol_bwmfi=1e-6):
    print(f"\n{'='*60}")
    print(f"  {tf_name} 검증 | point=0.01 | freq={tf_seconds}s")
    print(f"{'='*60}")

    # MQL5 CSV 로드
    mql = pd.read_csv(csv_path, sep='\t')
    mql['Time'] = pd.to_datetime(mql['Time'], format='%Y.%m.%d %H:%M')
    mql = mql.set_index('Time').sort_index()
    print(f"  MQL5 행수: {len(mql)}, 범위: {mql.index[0]} ~ {mql.index[-1]}")

    # Python 재계산
    py_result = calculate_bwmfi_mtf(mql, tf_seconds, volume_col='TickVolume', point=0.01)

    # 비교 (NaN 제외하고 처음 tf_seconds/60 바는 warm-up 으로 스킵)
    skip = tf_seconds // 60          # 1 MTF 봉 분량 스킵
    mql_bwmfi = mql['BWMFI'].values[skip:]
    py_bwmfi  = py_result['BWMFI'].values[skip:]
    mql_col   = mql['BWMFI_Color'].values[skip:]
    py_col    = py_result['BWMFI_Color'].values[skip:]

    # BWMFI 오차
    diff = np.abs(mql_bwmfi - py_bwmfi)
    match_bwmfi = diff <= tol_bwmfi
    pct = match_bwmfi.sum() / len(match_bwmfi) * 100

    print(f"\n  [BWMFI 비교] skip={skip}봉 이후 {len(mql_bwmfi)}개")
    print(f"    일치율 : {pct:.2f}%  ({match_bwmfi.sum()}/{len(match_bwmfi)})")
    print(f"    최대오차: {diff.max():.8f}")
    print(f"    평균오차: {diff.mean():.8f}")

    # Color 비교
    col_match = (mql_col == py_col).sum() / len(mql_col) * 100
    print(f"\n  [Color 비교]")
    print(f"    일치율 : {col_match:.2f}%")

    # 첫 10개 불일치 표시
    mismatch_idx = np.where(~match_bwmfi)[0]
    if len(mismatch_idx) > 0:
        print(f"\n  [불일치 샘플 (최대 10개)]")
        for ii in mismatch_idx[:10]:
            t = mql.index[ii + skip]
            print(f"    {t}  MQL5={mql_bwmfi[ii]:.8f}  Py={py_bwmfi[ii]:.8f}  |diff|={diff[ii]:.2e}")
    else:
        print("  ✅ 모든 BWMFI 값 일치!")

    return pct


# ────────────────────────────────────────────────────────────────
# 메인
# ────────────────────────────────────────────────────────────────
FILES_DIR = r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files'

p_m5 = verify(
    csv_path   = FILES_DIR + r'\BWMFI_MTF_DownLoad(5M).csv',
    tf_seconds = 5 * 60,
    tf_name    = 'M5',
)

p_h4 = verify(
    csv_path   = FILES_DIR + r'\BWMFI_MTF_DownLoad(4H).csv',
    tf_seconds = 4 * 60 * 60,
    tf_name    = 'H4',
)

print(f"\n{'='*60}")
if p_m5 >= 99.9 and p_h4 >= 99.9:
    print("✅ PASS: M5, H4 모두 99.9% 이상 일치")
else:
    print(f"⚠️  WARNING: M5={p_m5:.2f}%, H4={p_h4:.2f}%")
print(f"{'='*60}")
