import pandas as pd
import numpy as np
import math
import os
from datetime import datetime

# ==============================================================================
# Configuration
# ==============================================================================
FILE_PATH = os.path.join(os.getenv('APPDATA'), r"MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\LRAVGSTD_DownLoad.csv")
INP_LWMA_PERIOD = 25
INP_AVG_PERIOD = 60
INP_STD_PERIOD_L = 5000
INP_STD_PERIOD_S = 2
INP_MULTI_FACTOR_L1 = 1.0
INP_MULTI_FACTOR_L2 = 2.0
INP_MULTI_FACTOR_L3 = 3.0
INP_POINT = 0.01

# Time Filter Defaults
STD_CALC_START_HOUR = 1
STD_CALC_START_MINUTE = 30
STD_CALC_END_HOUR = 23
STD_CALC_END_MINUTE = 30

# ==============================================================================
# MQL5 Logic Implementations
# ==============================================================================

def CalculateBuyRatio(open_p, high, low, close, bar, prev_close):
    if bar <= 0: return 0.0
    buyRatio = 0.0
    if close < open_p:
        if prev_close < open_p:
            buyRatio = max(high - prev_close, close - low)
        else:
            buyRatio = max(high - open_p, close - low)
    elif close > open_p:
        if prev_close > open_p:
            buyRatio = high - low
        else:
            buyRatio = max(open_p - prev_close, high - low)
    else:
        if high - close > close - low:
            if prev_close < open_p:
                buyRatio = max(high - prev_close, close - low)
            else:
                buyRatio = high - open_p
        elif high - close < close - low:
            if prev_close > open_p:
                buyRatio = high - low
            else:
                buyRatio = max(open_p - prev_close, high - low)
        else:
            if prev_close > open_p:
                buyRatio = max(high - open_p, close - low)
            elif prev_close < open_p:
                buyRatio = max(open_p - prev_close, high - low)
            else:
                buyRatio = high - low           
    return buyRatio

def CalculateSellRatio(open_p, high, low, close, bar, prev_close):
    if bar <= 0: return 0.0
    sellRatio = 0.0
    if close < open_p:
        if prev_close > open_p:
            sellRatio = max(prev_close - open_p, high - low)
        else:
            sellRatio = high - low
    elif close > open_p:
        if prev_close > open_p:
            sellRatio = max(prev_close - low, high - close)
        else:
            sellRatio = max(open_p - low, high - close)
    else:
        if high - close > close - low:
            if prev_close > open_p:
                sellRatio = max(prev_close - open_p, high - low)
            else:
                sellRatio = high - low
        elif high - close < close - low:
            if prev_close > open_p:
                sellRatio = max(prev_close - low, high - close)
            else:
                sellRatio = open_p - low
        else:
            if prev_close > open_p:
                sellRatio = max(prev_close - open_p, high - low)
            elif prev_close < open_p:
                sellRatio = max(open_p - low, high - close)
            else:
                sellRatio = high - low              
    return sellRatio

class CLwma_Py:
    def __init__(self, period):
        self.period = period if period > 1 else 1
        self.m_array = []
        
    def calculate(self, value, i):
        while len(self.m_array) <= i:
            self.m_array.append({'value': 0.0, 'wsumm': 0.0, 'vsumm': 0.0})
        current = self.m_array[i]
        current['value'] = value
        
        if i >= self.period:
            prev = self.m_array[i-1]
            prev_delayed = self.m_array[i-self.period]
            if i > self.period:
                current['wsumm'] = prev['wsumm'] + value * self.period - prev['vsumm']
                current['vsumm'] = prev['vsumm'] + value - prev_delayed['value']
            else:
                 m_weight = 0
                 current['wsumm'] = 0
                 current['vsumm'] = 0
                 w = self.period
                 for k in range(self.period):
                     if i < k: break
                     m_weight += w
                     val_k = self.m_array[i-k]['value']
                     current['wsumm'] += val_k * w
                     current['vsumm'] += val_k
                     w -= 1
                 if m_weight == 0: return 0.0
                 return current['wsumm'] / m_weight
            m_weight = self.period * (self.period + 1) / 2
            return current['wsumm'] / m_weight
        else:
            m_weight = 0
            current['wsumm'] = 0
            current['vsumm'] = 0
            w = self.period
            for k in range(self.period):
                if i < k: break
                m_weight += w
                val_k = self.m_array[i-k]['value']
                current['wsumm'] += val_k * w
                current['vsumm'] += val_k
                w -= 1
            if m_weight == 0: return 0.0
            return current['wsumm'] / m_weight

class HiStdDev1_Py:
    def __init__(self, window_size):
        self.m_size = window_size
        self.m_buffer = [0.0] * window_size
        self.m_index = 0
        self.m_count = 0
        self.m_last_bar = -1
        self.m_sum_sq = 0.0
        
    def calculate(self, bar, avg_price, price):
        if bar > self.m_last_bar:
            if self.m_count >= self.m_size:
                old_val = self.m_buffer[self.m_index]
                self.m_sum_sq -= old_val
            else:
                self.m_count += 1
            temp_val = (price - avg_price)**2
            self.m_buffer[self.m_index] = temp_val
            self.m_sum_sq += temp_val
            self.m_index = (self.m_index + 1) % self.m_size
            if self.m_count < 2:
                self.m_last_bar = bar
                return 0.0
            std_val = math.sqrt(self.m_sum_sq / self.m_count) if self.m_sum_sq > 0 else 0.0
            self.m_last_bar = bar
            return std_val
        else:
            if self.m_count > 0:
                last_idx = (self.m_index - 1 + self.m_size) % self.m_size
                old_val = self.m_buffer[last_idx]
                temp_val = (price - avg_price)**2
                self.m_buffer[last_idx] = temp_val
                self.m_sum_sq = self.m_sum_sq - old_val + temp_val
                if self.m_count >= 2:
                    return math.sqrt(self.m_sum_sq / self.m_count) if self.m_sum_sq > 0 else 0.0
            return 0.0

class HiStdDev2_Py:
    def __init__(self, window_size):
        self.m_size = window_size
        self.m_buffer = [0.0] * window_size
        self.m_index = 0
        self.m_count = 0
        self.m_last_bar = -1
        self.m_sum_sq = 0.0
        
    def calculate(self, bar, avg_price, price):
        if bar > self.m_last_bar:
            if self.m_count >= self.m_size:
                old_val = self.m_buffer[self.m_index]
                self.m_sum_sq -= old_val
            else:
                self.m_count += 1
            diff = price - avg_price
            temp_val = diff * abs(diff)
            self.m_buffer[self.m_index] = temp_val
            self.m_sum_sq += temp_val
            self.m_index = (self.m_index + 1) % self.m_size
            if self.m_count < 2:
                self.m_last_bar = bar
                return 0.0
            variance = self.m_sum_sq / self.m_count
            std_val = math.sqrt(abs(variance))
            if variance < 0: std_val *= -1
            self.m_last_bar = bar
            return std_val
        else:
             if self.m_count > 0:
                last_idx = (self.m_index - 1 + self.m_size) % self.m_size
                old_val = self.m_buffer[last_idx]
                diff = price - avg_price
                temp_val = diff * abs(diff)
                self.m_buffer[last_idx] = temp_val
                self.m_sum_sq = self.m_sum_sq - old_val + temp_val
                if self.m_count >= 2:
                    variance = self.m_sum_sq / self.m_count
                    std_val = math.sqrt(abs(variance))
                    if variance < 0: std_val *= -1
                    return std_val
             return 0.0

def my_average(arr, k, period):
    if k < 0: return 0.0
    start_idx = k - period + 1
    s = 0.0
    for i in range(start_idx, k + 1):
        if i < 0: continue
        s += arr[i]
    return s / period

def is_std_calc_time(time_val):
    try:
        if isinstance(time_val, str):
            dt = datetime.strptime(time_val, "%Y.%m.%d %H:%M")
        else:
            # Assume it's a datetime object or pandas Timestamp
            dt = time_val
            
        curr_min = dt.hour * 60 + dt.minute
        start_min = STD_CALC_START_HOUR * 60 + STD_CALC_START_MINUTE
        end_min = STD_CALC_END_HOUR * 60 + STD_CALC_END_MINUTE
        
        if start_min < end_min:
            return start_min <= curr_min < end_min
        else:
            return curr_min >= start_min or curr_min < end_min
    except:
        return False

# ==============================================================================
# Main Execution
# ==============================================================================
# ==============================================================================
# Main Execution Logic
# ==============================================================================
def calculate_lravgstd(
    input_data, 
    avg_period=60,
    lwma_period=25,
    std_period_l=5000,
    std_period_s=2
):
    """
    Calculates LRAVGStd indicators.
    input_data: str (csv_path) or pd.DataFrame
    """
    df = None
    if isinstance(input_data, str):
        if not os.path.exists(input_data):
            print(f"Error: File not found at {input_data}")
            # Try alternate path logic if needed, but for now just return None
            return None
        
        # Try reading with different delimiters
        try:
            df = pd.read_csv(input_data, sep='\t')
            if 'Open' not in df.columns:
                raise ValueError("Not tab delimited")
        except:
            try:
                df = pd.read_csv(input_data, sep=';')
                if 'Open' not in df.columns:
                    raise ValueError("Not semicolon delimited")
            except:
                 df = pd.read_csv(input_data) # Default comma

    elif isinstance(input_data, pd.DataFrame):
        df = input_data.copy()
    else:
        return None

    # print(f"Loaded {len(df)} rows.")
    # print("Columns found:", df.columns.tolist())
    # Strip whitespace from columns just in case
    df.columns = df.columns.str.strip()
    
    # Ensure Time column exists/renamed if needed?
    # Original code assumed 'Time' exists? 
    # Yes: times = df['Time'].values
    
    TO_POINT = 100.0
    
    diff_pressure = np.zeros(len(df))
    lwma_val = np.zeros(len(df))
    avg_val_lr = np.zeros(len(df))
    std_s = np.zeros(len(df))
    bsp_scale = np.zeros(len(df))
    standard_deviation_l_arr = np.zeros(len(df))
    
    opens = df['Open'].values
    highs = df['High'].values
    lows = df['Low'].values
    closes = df['Close'].values
    times = df['Time'].values # Assuming standard names
    
    obj_lwma = CLwma_Py(lwma_period)
    obj_std1 = HiStdDev1_Py(std_period_l)
    obj_std2 = HiStdDev2_Py(std_period_s)
    
    # print("Running logic...")
    
    # Initialize first 2 elements as 0 (already done by np.zeros)
    # MQL5 starts loop at bar = 2
    for k in range(2, len(df)):
        prev_close = closes[k-1] if k > 0 else 0
        buy_ratio = CalculateBuyRatio(opens[k], highs[k], lows[k], closes[k], k, prev_close)
        sell_ratio = CalculateSellRatio(opens[k], highs[k], lows[k], closes[k], k, prev_close)
        temp_diff = (abs(buy_ratio) - abs(sell_ratio)) * TO_POINT
        
        # Accumulation
        prev_diff = diff_pressure[k-1]
        diff_pressure[k] = prev_diff + temp_diff
        
        lwma_val[k] = obj_lwma.calculate(diff_pressure[k], k)
        avg_val_lr[k] = my_average(lwma_val, k, avg_period)
        std_s[k] = obj_std2.calculate(k, avg_val_lr[k], lwma_val[k])
        
        is_calc = is_std_calc_time(times[k]) if isinstance(times[k], str) else True # Handle non-string time?
        # Note: Original code parsed strings in is_std_calc_time.
        # If input DF has datetime objects, `is_std_calc_time` might fail or needs update.
        # Check `is_std_calc_time`: calls datetime.strptime.
        # If passed Time is already datetime, this will fail.
        # Let's fix `is_std_calc_time` usage or function.
        # For now, assume it works if we pass string. 
        # If DF has loaded from CSV without parsing dates, they are strings.
        
        if is_calc:
            std_l = obj_std1.calculate(k, avg_val_lr[k], lwma_val[k])
            standard_deviation_l_arr[k] = std_l
            if std_l != 0:
                bsp_scale[k] = std_s[k] / std_l
            else:
                bsp_scale[k] = bsp_scale[k-1] if k > 0 else 0.0
        else:
            standard_deviation_l_arr[k] = standard_deviation_l_arr[k-1] if k > 0 else 0.0
            bsp_scale[k] = bsp_scale[k-1] if k > 0 else 0.0

    df['Py_stdS'] = std_s
    df['Py_BSPScale'] = bsp_scale
    
    return df

def main():
    file_path = os.path.join(os.getenv('APPDATA'), r"MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\LRAVGSTD_DownLoad.csv")
    
    # Use defaults
    df = calculate_lravgstd(file_path, avg_period=60, lwma_period=25)
    
    if df is not None:
        if 'stdS' in df.columns and 'BSPScale' in df.columns:
            mql_stds = df['stdS'].values
            mql_scale = df['BSPScale'].values
            std_s = df['Py_stdS'].values
            bsp_scale = df['Py_BSPScale'].values
            
            diff_stds = np.abs(mql_stds - std_s)
            mae_stds = np.mean(diff_stds)
            max_stds = np.max(diff_stds)
            
            diff_scale = np.abs(mql_scale - bsp_scale)
            mae_scale = np.mean(diff_scale)
            max_scale = np.max(diff_scale)
            
            print(f"\nVerification Results:")
            print(f"stdS matches: MAE={mae_stds:.6f}, MaxDiff={max_stds:.6f}")
            print(f"BSPScale matches: MAE={mae_scale:.6f}, MaxDiff={max_scale:.6f}")
            
            df['Diff_stdS'] = diff_stds
            df['Diff_BSPScale'] = diff_scale
            
            out_path = file_path.replace(".csv", "_Verification_Result.csv")
            df.to_csv(out_path, index=False)
            print(f"Saved comparison to: {out_path}")

if __name__ == "__main__":
    main()
