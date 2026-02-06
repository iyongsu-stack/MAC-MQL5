import pandas as pd
import numpy as np
import math
import os

# ==============================================================================
# Configuration
# ==============================================================================
# Adjust path if necessary
FILE_PATH = os.path.join(os.getenv('APPDATA'), r"MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Chaikin_Volatility_DownLoad.csv")

INP_SMOOTH_PERIOD = 30
INP_CHV_PERIOD = 30
INP_STD_PERIOD = 5000

# ==============================================================================
# Helper Classes & Functions
# ==============================================================================

def calculate_wma(data, period):
    """
    Calculates Linear Weighted Moving Average.
    Weight logic matches MQL5: Most recent value has weight 'period', oldest has weight 1.
    """
    n = len(data)
    wma = np.zeros(n)
    if period <= 0: return wma
    
    # Pre-calculate denominator
    denom = period * (period + 1) / 2.0
    
    # Weighted sum
    # Efficient implementation using rolling window is preferred, but simple loop is safer for matching exact logic
    # MQL5: for i in range(pos...): sum=0; weight=0; for k=0 to period-1: sum += data[i-k]*(period-k); ...
    
    for i in range(n):
        if i < period - 1:
            wma[i] = 0.0 # Or handle partial? MQL5 usually starts from period-1
            continue
            
        sum_val = 0.0
        weight_sum = 0.0
        
        # k goes from 0 to period-1
        # data index: i-k
        # weight: period-k
        for k in range(period):
            idx = i - k
            w = period - k
            sum_val += data[idx] * w
            # weight_sum += w # We know weight_sum is denom
            
        wma[i] = sum_val / denom
        
    return wma

class HiStdDev3_Py:
    """
    Replication of HiStdDev3 from mySmoothingAlgorithm.mqh
    Logic: RMS (Root Mean Square) of the input series.
    buffer stores x, sum_sq stores sum(x^2).
    Value = sqrt(sum_sq / count)
    """
    def __init__(self, window_size):
        self.m_size = window_size
        self.m_buffer = np.zeros(window_size)
        self.m_index = 0
        self.m_count = 0
        self.m_last_bar = -1
        self.m_sum_sq = 0.0
        
    def calculate(self, bar, price):
        if bar > self.m_last_bar:
            # 1. Remove old data if buffer is full
            if self.m_count >= self.m_size:
                old_val = self.m_buffer[self.m_index]
                self.m_sum_sq -= (old_val * old_val)
            else:
                self.m_count += 1
            
            # 2. Add new data
            self.m_buffer[self.m_index] = price
            self.m_sum_sq += (price * price)
            
            # 3. Save last index (logic simplified from MQL5 as we don't need revert usually)
            last_index = self.m_index
            
            # 4. Increment index
            self.m_index = (self.m_index + 1) % self.m_size
            
            # 5. Calculate
            if self.m_count < 2:
                self.m_last_bar = bar
                return 0.0
            
            variance = self.m_sum_sq / self.m_count
            val = math.sqrt(max(0, variance))
            
            self.m_last_bar = bar
            return val
        else:
            # Recalculate based on same bar (update)
             if self.m_count > 0:
                 # Last written index is (m_index - 1 + size) % size
                 prev_idx = (self.m_index - 1 + self.m_size) % self.m_size
                 old_price = self.m_buffer[prev_idx]
                 
                 self.m_buffer[prev_idx] = price
                 self.m_sum_sq = self.m_sum_sq - (old_price * old_price) + (price * price)
                 
                 if self.m_count >= 2:
                     variance = self.m_sum_sq / self.m_count
                     return math.sqrt(max(0, variance))
                     
             return 0.0

# ==============================================================================
# Main Logic
# ==============================================================================

# ==============================================================================
# Main Logic
# ==============================================================================
def calculate_chaikin(input_data, smooth_period=30, chv_period=30, std_period=5000):
    """
    Calculates Chaikin Volatility indicators.
    input_data: str (csv_path) or pd.DataFrame
    return: pd.DataFrame
    """
    df = None
    if isinstance(input_data, str):
        # print(f"Loading {input_data}...")
        if not os.path.exists(input_data):
            # Check alt path logic if needed, but for module usage, just warn
             if "Tester" not in input_data and "MetaQuotes" in input_data:
                  alt = input_data.replace("MQL5\\Files", "Tester\\Files")
                  if os.path.exists(alt):
                       input_data = alt
             
             if not os.path.exists(input_data):
                 print(f"Error: File not found {input_data}")
                 return None

        # Robust CSV Loading
        try:
            df = pd.read_csv(input_data, sep='\t')
            if 'High' not in df.columns:
                # Try semicolon
                df = pd.read_csv(input_data, sep=';')
                if 'High' not in df.columns:
                     df = pd.read_csv(input_data) # Default comma
        except:
             df = pd.read_csv(input_data)
    elif isinstance(input_data, pd.DataFrame):
        df = input_data.copy()
    else:
        return None

    # Strip whitespace
    df.columns = df.columns.str.strip()
    
    # Check Required Columns
    req = ['High', 'Low']
    if not all(c in df.columns for c in req):
        return None

    # Data Arrays
    highs = df['High'].values
    lows = df['Low'].values
    
    # 1. Calculate HL
    hl = highs - lows
    
    # 2. Calculate SHL (Smoothed HL using WMA)
    shl = calculate_wma(hl, smooth_period)
    
    # 3. Calculate CHV
    # Match MQL5 posCHV logic: ExtCHVPeriod + ExtSmoothPeriod - 2 = 30 + 30 - 2 = 58
    START_OFFSET = chv_period + smooth_period - 2
    
    chv = np.zeros(len(df))
    for i in range(len(df)):
        
        if i < START_OFFSET:
            chv[i] = 0.0
            continue
    
        prev_idx = i - chv_period
        # Just in case, though START_OFFSET ensures prev_idx >= 28
        if prev_idx < 0:
            chv[i] = 0.0
        else:
            denom = shl[prev_idx]
            if denom != 0 and abs(denom) > 1e-10:
                chv[i] = 100.0 * (shl[i] - denom) / denom
            else:
                chv[i] = 0.0
    
    # 4. Calculate StdDev & CVScale
    std_obj = HiStdDev3_Py(std_period)
    py_std = np.zeros(len(df))
    py_scale = np.zeros(len(df))
    
    for i in range(len(df)):
        
        if i < START_OFFSET:
             py_std[i] = 0.0 # Initialized to 0
             py_scale[i] = 0.0 # Initialized to 0
             continue
    
        # Calculate StdDev on CHV
        val = std_obj.calculate(i, chv[i])
        py_std[i] = val
        
        # Calculate CVScale
        if val != 0:
            py_scale[i] = chv[i] / val
        else:
            # Match MQL5 else branch
            py_scale[i] = py_scale[i-1] if i > 0 else 0.0
            
    # Add to DF
    df['Py_CHV'] = chv
    df['Py_StdDev'] = py_std
    df['Py_CVScale'] = py_scale

    return df

def main():
    FILE_PATH = os.path.join(os.getenv('APPDATA'), r"MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\Chaikin_Volatility_DownLoad.csv")
    
    INP_SMOOTH_PERIOD = 30
    INP_CHV_PERIOD = 30
    INP_STD_PERIOD = 5000
    
    df = calculate_chaikin(FILE_PATH, INP_SMOOTH_PERIOD, INP_CHV_PERIOD, INP_STD_PERIOD)
    
    if df is None: return

    # Comparison Stats
    def get_stats(arr1, arr2, name):
        # Filter out initial zeros or NaNs which might differ due to startup
        # Assuming valid data starts after 60 bars approx?
        # Let's compare all, but note large diffs at start
        diff = np.abs(arr1 - arr2)
        mae = np.mean(diff)
        mx = np.max(diff)
        print(f"[{name}] MAE: {mae:.6f}, MaxDiff: {mx:.6f}")
        return diff
    
    if 'CHV' in df.columns:
        mql_chv = df['CHV'].values
        mql_std = df['StdDev'].values
        mql_scale = df['CVScale'].values
        
        chv = df['Py_CHV'].values
        py_std = df['Py_StdDev'].values
        py_scale = df['Py_CVScale'].values
    
        print("\n--- Verification Results ---")
        diff_chv = get_stats(mql_chv, chv, "CHV")
        diff_std = get_stats(mql_std, py_std, "StdDev")
        diff_scale = get_stats(mql_scale, py_scale, "CVScale")
        
        df['Diff_CHV'] = diff_chv
        df['Diff_StdDev'] = diff_std
        df['Diff_CVScale'] = diff_scale
        
        out_file = FILE_PATH.replace(".csv", "_Verification.csv")
        df.to_csv(out_file, index=False)
        print(f"\nSaved comparison to: {out_file}")

if __name__ == "__main__":
    main()
