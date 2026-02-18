"""
TotalResult_2026_02_18_1.csv 의 BWMTF 컬럼을 올바른 공식으로 재계산하여 덮어씁니다.

[올바른 공식]
  BWMFI = (High - Low) / Point / Volume
  Point = 0.01 (XAUUSD)

[수정 대상 컬럼]
  BWMTF_H4_BWMFI, BWMTF_H4_Color
  BWMTF_M5_BWMFI, BWMTF_M5_Color
"""
import sys, os
sys.path.append(os.path.join(os.path.dirname(__file__)))

import pandas as pd
import numpy as np

# ─── 경로 설정 ────────────────────────────────────────────────────────────────
MQL5_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES_DIR = os.path.join(MQL5_DIR, "Files")
TARGET_CSV = os.path.join(FILES_DIR, "TotalResult_2026_02_18_1.csv")
POINT = 0.01  # XAUUSD

# ─── 1. 데이터 로드 ───────────────────────────────────────────────────────────
print(f"[1/4] 데이터 로드 중: {TARGET_CSV}")
df = pd.read_csv(TARGET_CSV)
df['Time'] = pd.to_datetime(df['Time'])
df.set_index('Time', inplace=True)
print(f"  행 수: {len(df):,}")

# ─── 2. BWMFI 계산 함수 ───────────────────────────────────────────────────────
def calc_bwmfi_mtf(df_m1, target_tf, point=0.01):
    """
    M1 데이터에서 MTF BWMFI 계산.
    공식: (High - Low) / Point / Volume
    Shift(1): 완성봉 기준 (Lookahead Bias 방지)
    """
    # Resample
    agg = {
        'High': 'max',
        'Low': 'min',
        'TickVolume': 'sum',
        'Open': 'first',
        'Close': 'last',
    }
    # 실제 존재하는 컬럼만 집계
    agg = {k: v for k, v in agg.items() if k in df_m1.columns}
    
    df_tf = df_m1.resample(target_tf).agg(agg).dropna(subset=['High', 'Low', 'TickVolume'])
    
    # BWMFI 계산: (High - Low) / Point / Volume
    vol = df_tf['TickVolume'].astype(float)
    with np.errstate(divide='ignore', invalid='ignore'):
        mfi = (df_tf['High'] - df_tf['Low']) / point / vol
    mfi = mfi.replace([np.inf, -np.inf], np.nan).ffill().fillna(0.0)
    df_tf['BWMFI'] = mfi
    
    # Color 계산 (MQL5 BWMFI 색상 로직)
    mfi_arr = df_tf['BWMFI'].values
    vol_arr = vol.values
    color_arr = np.zeros(len(df_tf))
    mfi_up = True
    vol_up = True
    for i in range(1, len(df_tf)):
        if mfi_arr[i] > mfi_arr[i-1]:
            mfi_up = True
        elif mfi_arr[i] < mfi_arr[i-1]:
            mfi_up = False
        if vol_arr[i] > vol_arr[i-1]:
            vol_up = True
        elif vol_arr[i] < vol_arr[i-1]:
            vol_up = False
        # Green=0, Fade=1, Fake=2, Squat=3
        if mfi_up and vol_up:
            color_arr[i] = 0.0
        elif not mfi_up and not vol_up:
            color_arr[i] = 1.0
        elif mfi_up and not vol_up:
            color_arr[i] = 2.0
        else:
            color_arr[i] = 3.0
    df_tf['BWMFI_Color'] = color_arr
    
    # Shift(1): 완성봉 기준
    df_tf['BWMFI'] = df_tf['BWMFI'].shift(1)
    df_tf['BWMFI_Color'] = df_tf['BWMFI_Color'].shift(1)
    
    # M1 인덱스로 리인덱싱 (ffill)
    result = df_tf[['BWMFI', 'BWMFI_Color']].reindex(df_m1.index, method='ffill')
    return result

# ─── 3. H4, M5 재계산 ─────────────────────────────────────────────────────────
print("[2/4] BWMTF H4 재계산 중...")
r_h4 = calc_bwmfi_mtf(df, '4h', point=POINT)
print(f"  H4 샘플: {r_h4['BWMFI'].head(3).values}")

print("[3/4] BWMTF M5 재계산 중...")
r_m5 = calc_bwmfi_mtf(df, '5min', point=POINT)
print(f"  M5 샘플: {r_m5['BWMFI'].head(3).values}")

# ─── 4. 컬럼 업데이트 ─────────────────────────────────────────────────────────
print("[4/4] 컬럼 업데이트 및 저장 중...")
df['BWMTF_H4_BWMFI']  = r_h4['BWMFI'].values
df['BWMTF_H4_Color']   = r_h4['BWMFI_Color'].values
df['BWMTF_M5_BWMFI']  = r_m5['BWMFI'].values
df['BWMTF_M5_Color']   = r_m5['BWMFI_Color'].values

# 인덱스 복원 후 저장
df.index.name = 'Time'
df.to_csv(TARGET_CSV)
print(f"  저장 완료: {TARGET_CSV}")

# ─── 검증 ─────────────────────────────────────────────────────────────────────
print("\n[검증] 수정된 값 샘플:")
print(df[['BWMTF_H4_BWMFI', 'BWMTF_H4_Color', 'BWMTF_M5_BWMFI', 'BWMTF_M5_Color']].head(10).to_string())
print("\n완료!")
