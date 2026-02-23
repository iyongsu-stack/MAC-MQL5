import pandas as pd
import numpy as np
import math
import os

# --- Parameters (Must match ADXSmoothDownLoad.mq5) ---
ADX_PERIOD = 14  # MQL5: input int period = 14 에 맞춰 동기화
ALPHA1 = 0.25
ALPHA2 = 0.33
AVG_PERIOD = 1000
STD_PERIOD = 4000

# --- HiAverage Class ---
class HiAverage:
    def __init__(self, window_size):
        self.m_size = max(1, window_size)
        self.m_buffer = [0.0] * self.m_size
        self.reset()
    
    def reset(self):
        self.m_index = 0
        self.m_count = 0
        self.m_sum = 0.0
        self.m_buffer = [0.0] * self.m_size

    def calculate(self, price):
        if self.m_count >= self.m_size:
            old_val = self.m_buffer[self.m_index]
            self.m_sum -= old_val
        else:
            self.m_count += 1
            
        self.m_buffer[self.m_index] = price
        self.m_sum += price
        
        # Drift Correction
        if self.m_index == 0 and self.m_count > 0:
            self.m_sum = sum(self.m_buffer[:self.m_count])
            
        self.m_index = (self.m_index + 1) % self.m_size
        
        return self.m_sum / self.m_count if self.m_count > 0 else 0.0

# --- HiStdDev1 Class ---
class HiStdDev1:
    def __init__(self, window_size):
        self.m_size = max(1, window_size)
        self.m_buffer = [0.0] * self.m_size
        self.reset()
        
    def reset(self):
        self.m_index = 0
        self.m_count = 0
        self.m_sum_sq = 0.0
        self.m_buffer = [0.0] * self.m_size
        self.m_last_std_value = 0.0

    def calculate(self, avg_price, price):
        if self.m_count >= self.m_size:
            old_val = self.m_buffer[self.m_index]
            self.m_sum_sq -= old_val
        else:
            self.m_count += 1
            
        diff = price - avg_price
        sq_val = diff * diff
        self.m_buffer[self.m_index] = sq_val
        self.m_sum_sq += sq_val
        
        # Drift Correction
        if self.m_index == 0 and self.m_count > 0:
            self.m_sum_sq = sum(self.m_buffer[:self.m_count])
            
        self.m_index = (self.m_index + 1) % self.m_size
        
        if self.m_count < 1:
            return 0.0
            
        var = self.m_sum_sq / self.m_count
        return math.sqrt(max(0.0, var))

def calculate_adx(input_data):
    """
    Calculates ADX Smooth indicators.
    input_data: str (csv_path) or pd.DataFrame
    """
    df = None
    if isinstance(input_data, str):
        if os.path.exists(input_data):
            try:
                df = pd.read_csv(input_data, sep='\t')
                if len(df.columns) < 2: df = pd.read_csv(input_data)
            except:
                df = pd.read_csv(input_data)
        else:
            return None
    elif isinstance(input_data, pd.DataFrame):
        df = input_data.copy()
    else:
        return None
        
    if df is None: return None
    
    # Normalize
    df.columns = [c.strip() for c in df.columns]
    
    rates_total = len(df)
    high = df['High'].values
    low = df['Low'].values
    close = df['Close'].values
    
    alpha_adx = 2.0 / (ADX_PERIOD + 1.0)
    
    tr_arr = np.zeros(rates_total)
    pdm_ratio = np.zeros(rates_total)
    mdm_ratio = np.zeros(rates_total)
    
    # MQL5 iADX Logic
    for i in range(1, rates_total):
        h = high[i]
        l = low[i]
        cp = close[i-1]
        hp = high[i-1]
        lp = low[i-1]
        
        tr_val = max(h - l, abs(h - cp), abs(l - cp))
        tr_arr[i] = tr_val
        
        up = h - hp
        down = lp - l
        
        dm_p = 0.0
        dm_m = 0.0
        
        if up > down and up > 0:
            dm_p = up
        elif down > up and down > 0:
            dm_m = down
            
        if tr_val != 0.0:
            pdm_ratio[i] = 100.0 * dm_p / tr_val
            mdm_ratio[i] = 100.0 * dm_m / tr_val
            
    # Smoothing (Standard EMA)
    pdi = np.zeros(rates_total)
    ndi = np.zeros(rates_total)
    prev_p = 0.0
    prev_n = 0.0
    
    for i in range(1, rates_total):
        pdi[i] = pdm_ratio[i] * alpha_adx + prev_p * (1.0 - alpha_adx)
        ndi[i] = mdm_ratio[i] * alpha_adx + prev_n * (1.0 - alpha_adx)
        prev_p = pdi[i]
        prev_n = ndi[i]
        
    # DX
    dx = np.zeros(rates_total)
    with np.errstate(divide='ignore', invalid='ignore'):
        sum_di = pdi + ndi
        sum_di[sum_di == 0] = 1e-9
        dx = 100.0 * np.abs(pdi - ndi) / sum_di
        dx = np.nan_to_num(dx)
        
    # ADX (Smoothed DX via EMA)
    adx_raw = np.zeros(rates_total)
    prev_a = 0.0
    for i in range(1, rates_total):
        adx_raw[i] = dx[i] * alpha_adx + prev_a * (1.0 - alpha_adx)
        prev_a = adx_raw[i]
            
    # Custom Smoothing Logic (Level 1 → Level 2, DiPlus/DiMinus/ADX 모두 동일 구조)
    adx_intermediate   = np.zeros(rates_total)
    adx_final_buf      = np.zeros(rates_total)
    diplus_inter       = np.zeros(rates_total)  # Level-1 DiPlus 중간값
    diminus_inter      = np.zeros(rates_total)  # Level-1 DiMinus 중간값
    diplus_final_buf   = np.zeros(rates_total)  # Level-2 DiPlus 최종 버퍼
    diminus_final_buf  = np.zeros(rates_total)  # Level-2 DiMinus 최종 버퍼

    last_adx_val    = 0.0
    last_diplus_val = 0.0   # Level-1 DiPlus 이전 상태
    last_diminus_val= 0.0   # Level-1 DiMinus 이전 상태
    
    avg_calc = HiAverage(AVG_PERIOD)
    std_calc = HiStdDev1(STD_PERIOD)
    
    avg_adx_buf = np.zeros(rates_total)
    scale_buf = np.zeros(rates_total)
    
    for i in range(1, rates_total):
        curr_raw  = adx_raw[i]
        prev_raw  = adx_raw[i-1]
        curr_dip  = pdi[i]
        prev_dip  = pdi[i-1]
        curr_dim  = ndi[i]
        prev_dim  = ndi[i-1]

        # Level 1 Smoothing (ADX, DiPlus, DiMinus 동일 공식)
        val_adx    = 2 * curr_raw + (ALPHA1 - 2) * prev_raw + (1 - ALPHA1) * last_adx_val
        val_diplus = 2 * curr_dip + (ALPHA1 - 2) * prev_dip + (1 - ALPHA1) * last_diplus_val
        val_diminus= 2 * curr_dim + (ALPHA1 - 2) * prev_dim + (1 - ALPHA1) * last_diminus_val
        adx_intermediate[i]  = val_adx
        diplus_inter[i]      = val_diplus
        diminus_inter[i]     = val_diminus

        # Level 2 Smoothing
        adx_final_buf[i]     = ALPHA2 * val_adx    + (1 - ALPHA2) * adx_final_buf[i-1]
        diplus_final_buf[i]  = ALPHA2 * val_diplus  + (1 - ALPHA2) * diplus_final_buf[i-1]
        diminus_final_buf[i] = ALPHA2 * val_diminus + (1 - ALPHA2) * diminus_final_buf[i-1]

        # 상태 업데이트 (MQL5: i < rates_total-1 일 때만 갱신)
        last_adx_val     = val_adx
        last_diplus_val  = val_diplus
        last_diminus_val = val_diminus
        
        # Stats
        avg = avg_calc.calculate(adx_final_buf[i])
        std = std_calc.calculate(avg, adx_final_buf[i])
        
        avg_adx_buf[i] = avg
        if std != 0:
            scale_buf[i] = (adx_final_buf[i] - avg) / std
        else:
            scale_buf[i] = scale_buf[i-1] if i > 0 else 0.0

    df['Py_DiPlus']  = diplus_final_buf   # Level-2 DiPlus 최종값
    df['Py_DiMinus'] = diminus_final_buf  # Level-2 DiMinus 최종값
    df['Py_ADX']     = adx_final_buf
    df['Py_Avg']     = avg_adx_buf
    df['Py_Scale']   = scale_buf
    
    return df

if __name__ == "__main__":
    import sys
    # Parquet 경로를 인자로 받거나 기본 경로 사용
    parq_path = sys.argv[1] if len(sys.argv) > 1 else \
        r'c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\parquet\ADXSmooth_DownLoad.parquet'

    print(f"[adx_verifier] Parquet 로드: {parq_path}")
    import pyarrow.parquet as pq
    df_raw = pq.read_table(parq_path).to_pandas()
    df_raw.columns = [c.strip() for c in df_raw.columns]

    # OHLCV 기초 데이터만 추출 (MQL5 계산값 제외)
    base_cols = ['Time', 'Open', 'High', 'Low', 'Close']
    df_base = df_raw[base_cols].copy()

    res = calculate_adx(df_base)
    if res is None:
        print("[FAIL] 계산 실패"); sys.exit(1)

    # MQL5 결과값 병합
    for col in ['DiPlus', 'DiMinus', 'ADX', 'Average', 'Scale']:
        if col in df_raw.columns:
            res[col] = df_raw[col].values

    # Parquet 저장 (덮어쓰기)
    res.to_parquet(parq_path, index=False)
    print(f"[OK] 독립 계산 결과 병합 완료: {parq_path}")

    # 교차 검증
    TOLERANCE = 1e-5
    WARMUP    = 200
    col_pairs = [
        ('DiPlus',  'Py_DiPlus'),
        ('DiMinus', 'Py_DiMinus'),
        ('ADX',     'Py_ADX'),
        ('Average', 'Py_Avg'),
        ('Scale',   'Py_Scale'),
    ]
    df_check  = res.iloc[WARMUP:].copy()
    rows      = []
    all_pass  = True
    for mql_col, py_col in col_pairs:
        if mql_col not in df_check.columns or py_col not in df_check.columns:
            rows.append({'컬럼': f'{mql_col} vs {py_col}', '최대오차(MAE)': 'N/A', '검증행수': 0, '불일치건수': -1, '판정': 'SKIP'})
            continue
        diff     = (df_check[mql_col] - df_check[py_col]).abs()
        max_err  = diff.max()
        fail_cnt = int((diff > TOLERANCE).sum())
        if fail_cnt > 0: all_pass = False
        rows.append({'컬럼': f'{mql_col} vs {py_col}', '최대오차(MAE)': f'{max_err:.2e}',
                     '검증행수': len(df_check), '불일치건수': fail_cnt,
                     '판정': 'PASS' if fail_cnt == 0 else 'FAIL'})

    import pandas as pd
    print("\n" + "="*60)
    print(pd.DataFrame(rows).to_string(index=False))
    print("\n" + ("✅ 전체 PASS" if all_pass else "❌ FAIL — Self-Refine 필요"))
