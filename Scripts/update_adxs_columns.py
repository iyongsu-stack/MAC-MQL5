"""
ADXS 컬럼 재계산 및 컬럼명 변경 스크립트
- ADX_PERIOD: 10 → 14
- 컬럼명: ADXS_(10,5)_ADX/Avg/Scale → ADXS_(14)_ADX/Avg/Scale
- 방식: csv 스트리밍 (pandas 미사용, 메모리 효율적)
"""
import csv
import os
import sys
import math
import numpy as np

# ---------------------------------------------------------------------------
# 경로 설정
# ---------------------------------------------------------------------------
MQL5_ROOT  = os.path.join(os.getenv('APPDATA'),
    r'MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5')
FILES_DIR  = os.path.join(MQL5_ROOT, 'Files')
SCRIPTS_DIR = os.path.join(MQL5_ROOT, 'Scripts')
sys.path.insert(0, SCRIPTS_DIR)

CSV_PATH = os.path.join(FILES_DIR, 'TotalResult_2026_02_18_1.csv')
TMP_PATH = CSV_PATH + '.tmp'

# ---------------------------------------------------------------------------
# 파라미터
# ---------------------------------------------------------------------------
ADX_PERIOD = 14
ALPHA1     = 0.25
ALPHA2     = 0.33
AVG_PERIOD = 1000
STD_PERIOD = 4000

# 컬럼명 매핑 (구 → 신)
COL_RENAME = {
    'ADXS_(10,5)_ADX'  : 'ADXS_(14)_ADX',
    'ADXS_(10,5)_Avg'  : 'ADXS_(14)_Avg',
    'ADXS_(10,5)_Scale': 'ADXS_(14)_Scale',
}

# ---------------------------------------------------------------------------
# HiAverage (O(1) 증분 이동평균)
# ---------------------------------------------------------------------------
class HiAverage:
    def __init__(self, window_size):
        self.m_size   = max(1, window_size)
        self.m_buffer = [0.0] * self.m_size
        self.m_index  = 0
        self.m_count  = 0
        self.m_sum    = 0.0

    def calculate(self, price):
        if self.m_count >= self.m_size:
            self.m_sum -= self.m_buffer[self.m_index]
        else:
            self.m_count += 1
        self.m_buffer[self.m_index] = price
        self.m_sum += price
        if self.m_index == 0 and self.m_count > 0:
            self.m_sum = sum(self.m_buffer[:self.m_count])
        self.m_index = (self.m_index + 1) % self.m_size
        return self.m_sum / self.m_count if self.m_count > 0 else 0.0

# ---------------------------------------------------------------------------
# HiStdDev (O(1) 증분 표준편차)
# ---------------------------------------------------------------------------
class HiStdDev1:
    def __init__(self, window_size):
        self.m_size    = max(1, window_size)
        self.m_buffer  = [0.0] * self.m_size
        self.m_index   = 0
        self.m_count   = 0
        self.m_sum_sq  = 0.0

    def calculate(self, avg_price, price):
        if self.m_count >= self.m_size:
            self.m_sum_sq -= self.m_buffer[self.m_index]
        else:
            self.m_count += 1
        diff   = price - avg_price
        sq_val = diff * diff
        self.m_buffer[self.m_index] = sq_val
        self.m_sum_sq += sq_val
        if self.m_index == 0 and self.m_count > 0:
            self.m_sum_sq = sum(self.m_buffer[:self.m_count])
        self.m_index = (self.m_index + 1) % self.m_size
        if self.m_count < 1:
            return 0.0
        return math.sqrt(max(0.0, self.m_sum_sq / self.m_count))

# ---------------------------------------------------------------------------
# Step 1: CSV 전체 로드 (OHLC만 추출)
# ---------------------------------------------------------------------------
print("=" * 60)
print("[Step 1] CSV 로드 중 (OHLC 추출)...")

times  = []
highs  = []
lows   = []
closes = []
all_rows = []
fieldnames_orig = None

with open(CSV_PATH, 'r', encoding='utf-8-sig', newline='') as f:
    reader = csv.DictReader(f)
    fieldnames_orig = reader.fieldnames[:]
    for i, row in enumerate(reader):
        all_rows.append(row)
        highs.append(float(row['High']))
        lows.append(float(row['Low']))
        closes.append(float(row['Close']))
        if i % 50000 == 0:
            print(f"  {i:,}행 로드 중...")

n = len(all_rows)
print(f"  총 {n:,}행 로드 완료")

# ---------------------------------------------------------------------------
# Step 2: ADX 계산 (period=14)
# ---------------------------------------------------------------------------
print(f"\n[Step 2] ADX 계산 (period={ADX_PERIOD})...")

alpha_adx = 2.0 / (ADX_PERIOD + 1.0)
high  = np.array(highs)
low   = np.array(lows)
close = np.array(closes)

# TR / DM
pdm_ratio = np.zeros(n)
mdm_ratio = np.zeros(n)
for i in range(1, n):
    h, l, cp = high[i], low[i], close[i-1]
    hp, lp   = high[i-1], low[i-1]
    tr_val   = max(h - l, abs(h - cp), abs(l - cp))
    up   = h - hp
    down = lp - l
    dm_p = dm_m = 0.0
    if up > down and up > 0:
        dm_p = up
    elif down > up and down > 0:
        dm_m = down
    if tr_val != 0.0:
        pdm_ratio[i] = 100.0 * dm_p / tr_val
        mdm_ratio[i] = 100.0 * dm_m / tr_val

# EMA 스무딩
pdi = np.zeros(n)
ndi = np.zeros(n)
prev_p = prev_n = 0.0
for i in range(1, n):
    pdi[i] = pdm_ratio[i] * alpha_adx + prev_p * (1.0 - alpha_adx)
    ndi[i] = mdm_ratio[i] * alpha_adx + prev_n * (1.0 - alpha_adx)
    prev_p, prev_n = pdi[i], ndi[i]

# DX
with np.errstate(divide='ignore', invalid='ignore'):
    sum_di = pdi + ndi
    sum_di[sum_di == 0] = 1e-9
    dx = 100.0 * np.abs(pdi - ndi) / sum_di
    dx = np.nan_to_num(dx)

# ADX raw
adx_raw = np.zeros(n)
prev_a = 0.0
for i in range(1, n):
    adx_raw[i] = dx[i] * alpha_adx + prev_a * (1.0 - alpha_adx)
    prev_a = adx_raw[i]

# 2중 커스텀 스무딩
adx_final = np.zeros(n)
last_val  = 0.0
avg_calc  = HiAverage(AVG_PERIOD)
std_calc  = HiStdDev1(STD_PERIOD)
avg_buf   = np.zeros(n)
scale_buf = np.zeros(n)

for i in range(1, n):
    val = 2 * adx_raw[i] + (ALPHA1 - 2) * adx_raw[i-1] + (1 - ALPHA1) * last_val
    adx_final[i] = ALPHA2 * val + (1 - ALPHA2) * adx_final[i-1]
    last_val = val
    avg = avg_calc.calculate(adx_final[i])
    std = std_calc.calculate(avg, adx_final[i])
    avg_buf[i] = avg
    scale_buf[i] = (adx_final[i] - avg) / std if std != 0 else (scale_buf[i-1] if i > 0 else 0.0)

print("  ADX 계산 완료")

# ---------------------------------------------------------------------------
# Step 3: 새 컬럼명으로 CSV 저장 (스트리밍)
# ---------------------------------------------------------------------------
print("\n[Step 3] CSV 저장 중...")

# 헤더 변환
new_fieldnames = [COL_RENAME.get(c, c) for c in fieldnames_orig]

# 구 컬럼명 인덱스
old_adx_col   = 'ADXS_(10,5)_ADX'
old_avg_col   = 'ADXS_(10,5)_Avg'
old_scale_col = 'ADXS_(10,5)_Scale'
new_adx_col   = 'ADXS_(14)_ADX'
new_avg_col   = 'ADXS_(14)_Avg'
new_scale_col = 'ADXS_(14)_Scale'

with open(TMP_PATH, 'w', encoding='utf-8-sig', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=new_fieldnames, extrasaction='ignore')
    writer.writeheader()

    for i, row in enumerate(all_rows):
        # 컬럼명 변환 + 값 갱신
        new_row = {}
        for old_col, new_col in zip(fieldnames_orig, new_fieldnames):
            new_row[new_col] = row[old_col]

        # 새 값으로 덮어쓰기
        new_row[new_adx_col]   = f'{adx_final[i]:.10f}'
        new_row[new_avg_col]   = f'{avg_buf[i]:.10f}'
        new_row[new_scale_col] = f'{scale_buf[i]:.10f}'

        writer.writerow(new_row)

        if i % 50000 == 0:
            print(f"  {i:,}행 저장 중...")

print("  임시 파일 → 원본 교체 중...")
os.replace(TMP_PATH, CSV_PATH)
print("  완료!")

# ---------------------------------------------------------------------------
# 검증 샘플 출력
# ---------------------------------------------------------------------------
print("\n[검증] 마지막 5행 샘플:")
for i in range(n-5, n):
    print(f"  [{i}] ADX={adx_final[i]:.6f}  Avg={avg_buf[i]:.6f}  Scale={scale_buf[i]:.6f}")

print("\n" + "=" * 60)
print(f"완료! ADX_PERIOD={ADX_PERIOD}, 컬럼명 ADXS_(10,5)→ADXS_(14)")
print("=" * 60)
