"""
TotalResult_2026_02_18_1.csv - BWMTF shift 검증 (최근 2개월)
- 청크 읽기로 최근 날짜 필터링 → 메모리 절약
"""
import pandas as pd
import numpy as np
import os

MQL5_DIR  = r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5'
TOTAL_CSV = os.path.join(MQL5_DIR, 'Files', 'TotalResult_2026_02_18_1.csv')
CUTOFF    = pd.Timestamp('2025-12-19')   # 이후 데이터만 사용 (~2개월)

# ── Step 1: 청크 방식으로 최근 2개월치 로드 ─────────────────────────
print("청크 로딩 시작 (날짜 필터: 2025-12-19 이후)...", flush=True)
chunks = []
CHUNK = 200_000
with pd.read_csv(TOTAL_CSV, chunksize=CHUNK) as reader:
    for i, chunk in enumerate(reader):
        chunk['Time'] = pd.to_datetime(chunk['Time'])
        filtered = chunk[chunk['Time'] >= CUTOFF]
        if len(filtered):
            chunks.append(filtered)
        if (i+1) % 5 == 0:
            print(f"  {(i+1)*CHUNK:,}행 처리 중...", flush=True)

if not chunks:
    print("❌ 해당 날짜 데이터 없음. CUTOFF 날짜를 조정하세요.")
    exit(1)

tr = pd.concat(chunks, ignore_index=True)
tr = tr.set_index('Time').sort_index()
print(f"  로드 완료: {len(tr):,}행  {tr.index[0]} ~ {tr.index[-1]}")

bw_cols = [c for c in tr.columns if 'BWMTF' in c or 'BWMFI' in c]
print(f"  BWMTF 컬럼: {bw_cols}")
if not any('BWMTF' in c for c in bw_cols):
    print("❌ BWMTF 컬럼 없음!"); exit(1)

# ── Step 2: BWMFI 재계산 ─────────────────────────────────────────
def calc_bwmfi(df_m1, tf_sec, point=0.01):
    freq = f'{tf_sec}s'
    cols = {c: v for c, v in
            {'High':'max','Low':'min','TickVolume':'sum',
             'Close':'last','Open':'first'}.items()
            if c in df_m1.columns}
    df = df_m1.resample(freq).agg(cols).dropna()

    vol = df['TickVolume'].astype(float)
    with np.errstate(divide='ignore', invalid='ignore'):
        mfi = (df['High'] - df['Low']) / point / vol
    mfi = mfi.replace([np.inf,-np.inf], np.nan).ffill().fillna(0.0)
    df['BWMFI'] = mfi

    mfi_a = mfi.values; vol_a = vol.values
    col_a = np.zeros(len(df)); mfi_up = True; vol_up = True
    for i in range(1, len(df)):
        if mfi_a[i] > mfi_a[i-1]:      mfi_up = True
        elif mfi_a[i] < mfi_a[i-1]:    mfi_up = False
        if vol_a[i] > vol_a[i-1]:      vol_up = True
        elif vol_a[i] < vol_a[i-1]:    vol_up = False
        if   mfi_up and vol_up:          col_a[i] = 0.0
        elif not mfi_up and not vol_up:  col_a[i] = 1.0
        elif mfi_up and not vol_up:      col_a[i] = 2.0
        elif not mfi_up and vol_up:      col_a[i] = 3.0
    df['BWMFI_Color'] = col_a
    return df[['BWMFI','BWMFI_Color']].reindex(df_m1.index, method='ffill')

print("\nPython 재계산 중 (M5, H4)...", flush=True)
df_m1 = tr[['Open','High','Low','Close','TickVolume']].copy()
py_m5 = calc_bwmfi(df_m1, 5*60)
py_h4 = calc_bwmfi(df_m1, 4*3600)
print("  완료.")

# ── Step 3: shift 탐색 ────────────────────────────────────────────
TOL = 1e-6

def match_rate(csv_col, py_series, shift=0):
    if csv_col not in tr.columns: return -1.0
    csv_v = tr[csv_col].values.astype(float)
    py_v  = py_series.shift(shift).values
    valid = ~(np.isnan(csv_v) | np.isnan(py_v))
    if valid.sum() == 0: return 0.0
    diff = np.abs(csv_v[valid] - py_v[valid])
    return (diff <= TOL).sum() / valid.sum() * 100

print("\n" + "="*65)
print("  Shift 탐색 (0~5분) — BWMFI 기준")
print("="*65)
print(f"  {'shift':>6} | {'M5_BWMFI':>10} | {'M5_Color':>10} | {'H4_BWMFI':>10} | {'H4_Color':>10}")
print("  " + "-"*62)

best_tot = -1; best_s = 0
results = []
for s in range(6):
    r_m5  = match_rate('BWMTF_M5_BWMFI', py_m5['BWMFI'],        s)
    r_m5c = match_rate('BWMTF_M5_Color', py_m5['BWMFI_Color'],   s)
    r_h4  = match_rate('BWMTF_H4_BWMFI', py_h4['BWMFI'],        s)
    r_h4c = match_rate('BWMTF_H4_Color', py_h4['BWMFI_Color'],   s)
    tot = r_m5 + r_h4
    results.append((s, r_m5, r_m5c, r_h4, r_h4c, tot))
    flag = " ◀" if tot > best_tot else ""
    print(f"  {s:>6} | {r_m5:>9.2f}% | {r_m5c:>9.2f}% | {r_h4:>9.2f}% | {r_h4c:>9.2f}%{flag}")
    if tot > best_tot:
        best_tot = tot; best_s = s

bs = results[best_s]
print(f"\n  ★ 최적 shift = {best_s}분  M5={bs[1]:.2f}%  H4={bs[3]:.2f}%")

# ── Step 4: 불일치 샘플 ──────────────────────────────────────────
print("\n" + "="*65)
print(f"  shift={best_s} 불일치 샘플 (M5 BWMFI, 최대 8개)")
print("="*65)
col = 'BWMTF_M5_BWMFI'
if col in tr.columns:
    csv_v = tr[col].values.astype(float)
    py_v  = py_m5['BWMFI'].shift(best_s).values
    valid = ~(np.isnan(csv_v) | np.isnan(py_v))
    diff  = np.abs(csv_v - py_v)
    mis   = np.where(valid & (diff > TOL))[0]
    if len(mis) == 0:
        print("  ✅ 불일치 없음!")
    else:
        for ii in mis[:8]:
            t = tr.index[ii]
            print(f"  {t}  CSV={csv_v[ii]:.8f}  Py={py_v[ii]:.8f}  |diff|={diff[ii]:.2e}")
        print(f"  ... 총 {len(mis)}개 불일치")

# ── Step 5: 시간 shift 검증 (첫 5행 비교) ────────────────────────
print("\n" + "="*65)
print(f"  시간 확인: shift={best_s} 적용 시 CSV vs Py 샘플 (첫 10행)")
print("="*65)
col = 'BWMTF_M5_BWMFI'
if col in tr.columns:
    csv_s  = tr[col].dropna().head(10)
    py_s   = py_m5['BWMFI'].shift(best_s).reindex(tr.index).dropna().head(10)
    cmp    = pd.DataFrame({'Time': csv_s.index, 'CSV': csv_s.values,
                           f'Py_shift{best_s}': py_s.reindex(csv_s.index).values})
    cmp['diff'] = (cmp['CSV'] - cmp[f'Py_shift{best_s}']).abs()
    print(cmp.to_string(index=False))

print("\n검증 완료.")
