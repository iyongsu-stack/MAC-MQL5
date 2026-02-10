import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

# 1. Load Data
file_path = r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\ChandelieExit_DownLoad.csv'
df = pd.read_csv(file_path, sep='\t') 

# MQL5 Parameters
ATR_PERIOD = 22
ATR_MULT1 = 3.0
ATR_MULT2 = 4.5
LOOKBACK_PERIOD = 22

# 2. Preprocessing
df.rename(columns={'Time': 'time', 'Open': 'open', 'High': 'high', 'Low': 'low', 'Close': 'close'}, inplace=True)
df['time'] = pd.to_datetime(df['time'])

# 3. Calculate Logic (Python Implementation)

# --- ATR Calculation (Lagged by 1) ---
df['prev_close'] = df['close'].shift(1)
df['tr_high'] = df[['high', 'prev_close']].max(axis=1)
df['tr_low'] = df[['low', 'prev_close']].min(axis=1)
df['tr'] = df['tr_high'] - df['tr_low']
df['atr'] = df['tr'].rolling(window=ATR_PERIOD).mean().shift(1)

# --- Max High / Min Low (Lagged by 1) ---
df['max_high'] = df['high'].rolling(window=LOOKBACK_PERIOD).max().shift(1)
df['min_low'] = df['low'].rolling(window=LOOKBACK_PERIOD).min().shift(1)

# --- Recursive Trend & Trailing Logic ---
n = len(df)
close = df['close'].values
max_high = df['max_high'].values
min_low = df['min_low'].values
atr = df['atr'].values

# Python Buffers
py_upl1 = np.full(n, np.nan)
py_dnl1 = np.full(n, np.nan)
py_upl2 = np.full(n, np.nan)
py_dnl2 = np.full(n, np.nan)

# State variables (Work Arrays equivalent)
# Initialize with NaNs, will behave as 'first assignment' on validity
curr_hi1_work = np.nan
curr_lo1_work = np.nan
curr_hi2_work = np.nan
curr_lo2_work = np.nan
curr_trend1 = 0
curr_trend2 = 0

start_idx = max(ATR_PERIOD, LOOKBACK_PERIOD) + 1

for i in range(start_idx, n):
    _atr = atr[i]
    _max = max_high[i]
    _min = min_low[i]
    
    if np.isnan(_atr) or np.isnan(_max) or np.isnan(_min):
        continue

    # 1. Base Channel Calculation
    raw_hi1 = _max - ATR_MULT1 * _atr
    raw_lo1 = _min + ATR_MULT1 * _atr
    raw_hi2 = _max - ATR_MULT2 * _atr
    raw_lo2 = _min + ATR_MULT2 * _atr

    # Access Previous WORK State
    prev_hi1_work = curr_hi1_work
    prev_lo1_work = curr_lo1_work
    prev_hi2_work = curr_hi2_work
    prev_lo2_work = curr_lo2_work
    
    # Initialize if NaN
    if np.isnan(prev_hi1_work): prev_hi1_work = raw_hi1
    if np.isnan(prev_lo1_work): prev_lo1_work = raw_lo1
    if np.isnan(prev_hi2_work): prev_hi2_work = raw_hi2
    if np.isnan(prev_lo2_work): prev_lo2_work = raw_lo2

    # 2. Trend Logic
    # if(close[i] > work[i-1][_lo1]) trend = 1...
    new_trend1 = curr_trend1
    if close[i] > prev_lo1_work: new_trend1 = 1
    if close[i] < prev_hi1_work: new_trend1 = -1
    
    new_trend2 = curr_trend2
    if close[i] > prev_lo2_work: new_trend2 = 1
    if close[i] < prev_hi2_work: new_trend2 = -1

    # 3. Trailing Logic & Buffer Assignment
    
    # --- Trend 1 ---
    final_hi1_work = raw_hi1
    if new_trend1 == 1:
        # Long Trend: Stop logic - if new stop is LOWER than old, keep old (ascending only)
        # MQL5: if(work[i][_hi1]<work[i-1][_hi1]) work[i][_hi1]=work[i-1][_hi1];
        if raw_hi1 < prev_hi1_work:
            final_hi1_work = prev_hi1_work
        py_upl1[i] = final_hi1_work # Assign to Buffer only if Trend 1
    
    final_lo1_work = raw_lo1
    if new_trend1 == -1:
        # Short Trend: Stop logic - if new stop is HIGHER than old, keep old (descending only)
        # MQL5: if(work[i][_lo1]>work[i-1][_lo1]) work[i][_lo1]=work[i-1][_lo1];
        if raw_lo1 > prev_lo1_work:
            final_lo1_work = prev_lo1_work
        py_dnl1[i] = final_lo1_work

    # --- Trend 2 ---
    final_hi2_work = raw_hi2
    if new_trend2 == 1:
        if raw_hi2 < prev_hi2_work:
            final_hi2_work = prev_hi2_work
        py_upl2[i] = final_hi2_work

    final_lo2_work = raw_lo2
    if new_trend2 == -1:
        if raw_lo2 > prev_lo2_work:
            final_lo2_work = prev_lo2_work
        py_dnl2[i] = final_lo2_work

    # Update State for next loop
    curr_trend1 = new_trend1
    curr_trend2 = new_trend2
    curr_hi1_work = final_hi1_work
    curr_lo1_work = final_lo1_work
    curr_hi2_work = final_hi2_work
    curr_lo2_work = final_lo2_work

# 4. Compare
mql_upl1 = df['UplBuffer1'].replace('NaN', np.nan).astype(float)
mql_dnl1 = df['DnlBuffer1'].replace('NaN', np.nan).astype(float)
mql_upl2 = df['UplBuffer2'].replace('NaN', np.nan).astype(float)
mql_dnl2 = df['DnlBuffer2'].replace('NaN', np.nan).astype(float)

cmp = pd.DataFrame({
    'Time': df['time'],
    'MQL_Upl1': mql_upl1,
    'Py_Upl1': py_upl1,
    'Diff_Upl1': np.nan,
    'MQL_Dnl1': mql_dnl1,
    'Py_Dnl1': py_dnl1,
    'Diff_Dnl1': np.nan,
    'MQL_Upl2': mql_upl2,
    'Py_Upl2': py_upl2,
    'Diff_Upl2': np.nan,
    'MQL_Dnl2': mql_dnl2,
    'Py_Dnl2': py_dnl2,
    'Diff_Dnl2': np.nan
})

# Calculate Diff 1
mask_upl1 = ~np.isnan(cmp['MQL_Upl1']) & ~np.isnan(cmp['Py_Upl1'])
cmp.loc[mask_upl1, 'Diff_Upl1'] = cmp.loc[mask_upl1, 'MQL_Upl1'] - cmp.loc[mask_upl1, 'Py_Upl1']

mask_dnl1 = ~np.isnan(cmp['MQL_Dnl1']) & ~np.isnan(cmp['Py_Dnl1'])
cmp.loc[mask_dnl1, 'Diff_Dnl1'] = cmp.loc[mask_dnl1, 'MQL_Dnl1'] - cmp.loc[mask_dnl1, 'Py_Dnl1']

# Calculate Diff 2
mask_upl2 = ~np.isnan(cmp['MQL_Upl2']) & ~np.isnan(cmp['Py_Upl2'])
cmp.loc[mask_upl2, 'Diff_Upl2'] = cmp.loc[mask_upl2, 'MQL_Upl2'] - cmp.loc[mask_upl2, 'Py_Upl2']

mask_dnl2 = ~np.isnan(cmp['MQL_Dnl2']) & ~np.isnan(cmp['Py_Dnl2'])
cmp.loc[mask_dnl2, 'Diff_Dnl2'] = cmp.loc[mask_dnl2, 'MQL_Dnl2'] - cmp.loc[mask_dnl2, 'Py_Dnl2']

print("\n--- Verification Results ---")
print(f"Total Rows: {len(df)}")
print(f"UplBuffer1 - Max Diff: {cmp['Diff_Upl1'].abs().max()}")
print(f"DnlBuffer1 - Max Diff: {cmp['Diff_Dnl1'].abs().max()}")
print(f"UplBuffer2 - Max Diff: {cmp['Diff_Upl2'].abs().max()}")
print(f"DnlBuffer2 - Max Diff: {cmp['Diff_Dnl2'].abs().max()}")

# Save
output_path = r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\verification_result.csv'
cmp.to_csv(output_path, index=False, na_rep='NaN')
print(f"\nVerification saved to: {output_path}")

# Plot
plt.figure(figsize=(15, 12))
plt.subplot(3, 1, 1)
subset = cmp.iloc[-300:] # Last 300 bars
plt.plot(subset['Time'], subset['MQL_Upl1'], 'b-', label='MQL L1', alpha=0.6, linewidth=2)
plt.plot(subset['Time'], subset['Py_Upl1'], 'c--', label='Py L1', alpha=1.0, linewidth=1.5)
plt.plot(subset['Time'], subset['MQL_Dnl1'], 'r-', label='MQL S1', alpha=0.6, linewidth=2)
plt.plot(subset['Time'], subset['Py_Dnl1'], 'm--', label='Py S1', alpha=1.0, linewidth=1.5)
plt.legend()
plt.title('Chandelier Exit V1 Verification (Overlap)')

plt.subplot(3, 1, 2)
plt.plot(subset['Time'], subset['MQL_Upl2'], 'g-', label='MQL L2', alpha=0.6, linewidth=2)
plt.plot(subset['Time'], subset['Py_Upl2'], 'y--', label='Py L2', alpha=1.0, linewidth=1.5)
plt.plot(subset['Time'], subset['MQL_Dnl2'], 'k-', label='MQL S2', alpha=0.6, linewidth=2)
plt.plot(subset['Time'], subset['Py_Dnl2'], 'b--', label='Py S2', alpha=1.0, linewidth=1.5)
plt.legend()
plt.title('Chandelier Exit V2 Verification (Overlap)')

plt.subplot(3, 1, 3)
plt.plot(subset['Time'], subset['Diff_Upl1'], label='Diff L1')
plt.plot(subset['Time'], subset['Diff_Dnl1'], label='Diff S1')
plt.plot(subset['Time'], subset['Diff_Upl2'], label='Diff L2')
plt.plot(subset['Time'], subset['Diff_Dnl2'], label='Diff S2')
plt.legend()
plt.title('All Differences (Error)')
plt.tight_layout()
plt.savefig(r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\verification_chart.png')
print("Chart saved.")
