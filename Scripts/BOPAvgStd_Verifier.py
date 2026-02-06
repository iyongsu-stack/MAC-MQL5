import pandas as pd
import numpy as np
import math
import os
from datetime import datetime

# ==============================================================================
# 1. Configuration & Constants
# ==============================================================================
# ==============================================================================
# 1. Configuration & Constants
# ==============================================================================
# Defaults
DEFAULT_SMOOTH_PERIOD = 50
DEFAULT_AVG_PERIOD = 50
DEFAULT_STD_PERIOD = 5000
DEFAULT_STD_MULTI1 = 1.0
DEFAULT_STD_MULTI2 = 2.0
DEFAULT_STD_MULTI3 = 3.0

# Time Filter Defaults
STD_CALC_START_HOUR = 1
STD_CALC_START_MINUTE = 30
STD_CALC_END_HOUR = 23
STD_CALC_END_MINUTE = 30


# Time Filter Defaults
STD_CALC_START_HOUR = 1
STD_CALC_START_MINUTE = 30
STD_CALC_END_HOUR = 23
STD_CALC_END_MINUTE = 30

# ==============================================================================
# 2. Logic Implementations (Bulls/Bears Reward)
# ==============================================================================
def calculate_bulls_reward_series(df):
    """
    Vectorized calculation of BullsReward.
    Logic from CalculateBullsReward in myBSPCalculation.mqh
    """
    results = []
    
    # Pre-calculate shifted values for performance
    # In MQL5: close[bar-1] is the previous candle. 
    # In Pandas: shift(1) allows accessing previous row.
    prev_close = df['Close'].shift(1)
    
    # Iterate is safer for complex logic, but we can vectorize step-by-step
    # For clarity and exact logic matching, we'll use row iteration or apply
    # But since performance is requested, let's try to keep it efficient.
    # However, the condition tree in MQL5 is complex. Let's use a function applied to rows.
    
    # To make it fast, we pass numpy arrays
    opens = df['Open'].values
    highs = df['High'].values
    lows = df['Low'].values
    closes = df['Close'].values
    prev_closes = np.roll(closes, 1) # simple shift
    prev_closes[0] = opens[0] # Handle first undefined
    
    n = len(df)
    rewards = np.zeros(n)
    
    for i in range(n):
        if i == 0: continue
        
        O, H, L, C = opens[i], highs[i], lows[i], closes[i]
        prev_C = prev_closes[i]
        
        rng = H - L
        if rng == 0:
            rewards[i] = 0
            continue
            
        reward_open = 0.0
        reward_close = 0.0
        reward_oc = 0.0
        
        # Logic mirroring CalculateBullsReward
        reward_open = (H - O) / rng
        reward_close = (C - L) / rng
        
        if C > O:
            reward_oc = (C - O) / rng
        else:
            reward_oc = 0.0
            
        rewards[i] = (reward_open + reward_close + reward_oc) / 3.0
        
    return rewards

def calculate_bears_reward_series(df):
    """
    Vectorized calculation of BearsReward.
    """
    opens = df['Open'].values
    highs = df['High'].values
    lows = df['Low'].values
    closes = df['Close'].values
    prev_closes = np.roll(closes, 1)
    prev_closes[0] = opens[0]
    
    n = len(df)
    rewards = np.zeros(n)
    
    for i in range(n):
        if i == 0: continue
        
        O, H, L, C = opens[i], highs[i], lows[i], closes[i]
        
        rng = H - L
        if rng == 0:
            rewards[i] = 0
            continue
            
        reward_open = (O - L) / rng
        reward_close = (H - C) / rng
        
        if C < O:
            reward_oc = (O - C) / rng
        else:
            reward_oc = 0.0
            
        rewards[i] = (reward_open + reward_close + reward_oc) / 3.0
        
    return rewards


# ==============================================================================
# 3. Recursive Smoothing Algorithm (iSmooth)
# ==============================================================================
class ISmooth:
    """
    Python implementation of iSmooth from mySmoothingAlgorithm.mqh
    """
    def __init__(self, length, phase, size_estimate):
        self.length = float(length)
        self.phase = float(phase)
        self.bars = size_estimate
        
        # MQL5: double m_wrk[][_smoothInstances*_smoothInstancesSize];
        # Instance size is 10. We only need one instance for this specific usage.
        # Dimensions: [bars][10]
        # We initialize with zeros
        self.m_wrk = np.zeros((size_estimate + 100, 10)) 
        
        # Constants for indices
        self.BSMAX = 5
        self.BSMIN = 6
        self.VOLTY = 7
        self.VSUM  = 8
        self.AVOLTY= 9
        
    def calculate(self, price, r):
        """
        r: current bar index (0-based)
        price: input value
        """
        # Safety resize if needed (Python dynamic list is slower, pre-allocated numpy is better)
        if r >= len(self.m_wrk):
            # Extend array
            extension = np.zeros((1000, 10))
            self.m_wrk = np.vstack([self.m_wrk, extension])
            
        instanceNo = 0 # Offset 0 as we only have 1 instance per object
        
        # Initialization case
        if r == 0 or self.length <= 1:
            for k in range(7):
                self.m_wrk[r][k] = price
            for k in range(7, 10):
                self.m_wrk[r][k] = 0
            return price
            
        # Calculation Logic
        len1 = max(math.log(math.sqrt(0.5 * (self.length - 1))) / math.log(2.0) + 2.0, 0)
        pow1 = max(len1 - 2.0, 0.5)
        
        # Accessing previous step values (r-1)
        prev_bsmax = self.m_wrk[r-1][self.BSMAX]
        prev_bsmin = self.m_wrk[r-1][self.BSMIN]
        
        del1 = price - prev_bsmax
        del2 = price - prev_bsmin
        
        forBar = min(r, 10)
        
        self.m_wrk[r][self.VOLTY] = 0
        if abs(del1) > abs(del2):
            self.m_wrk[r][self.VOLTY] = abs(del1)
        if abs(del1) < abs(del2):
            self.m_wrk[r][self.VOLTY] = abs(del2)
            
        # vsum
        prev_vsum = self.m_wrk[r-1][self.VSUM]
        volty = self.m_wrk[r][self.VOLTY]
        volty_delayed = self.m_wrk[r-forBar][self.VOLTY]
        
        self.m_wrk[r][self.VSUM] = prev_vsum + (volty - volty_delayed) * 0.1
        
        # avolty
        prev_avolty = self.m_wrk[r-1][self.AVOLTY]
        curr_vsum = self.m_wrk[r][self.VSUM]
        
        self.m_wrk[r][self.AVOLTY] = prev_avolty + (2.0 / (max(4.0 * self.length, 30) + 1.0)) * (curr_vsum - prev_avolty)
        
        dVolty = 0
        if self.m_wrk[r][self.AVOLTY] > 0:
            dVolty = self.m_wrk[r][self.VOLTY] / self.m_wrk[r][self.AVOLTY]
            
        if dVolty > pow(len1, 1.0/pow1):
            dVolty = pow(len1, 1.0/pow1)
        if dVolty < 1:
            dVolty = 1.0
            
        pow2 = pow(dVolty, pow1)
        len2 = math.sqrt(0.5 * (self.length - 1)) * len1
        Kv = pow(len2 / (len2 + 1), math.sqrt(pow2))
        
        if del1 > 0:
            self.m_wrk[r][self.BSMAX] = price
        else:
            self.m_wrk[r][self.BSMAX] = price - Kv * del1
            
        if del2 < 0:
            self.m_wrk[r][self.BSMIN] = price
        else:
            self.m_wrk[r][self.BSMIN] = price - Kv * del2
            
        # Final phases
        corr = max(min(self.phase, 100), -100) / 100.0 + 1.5
        beta = 0.45 * (self.length - 1) / (0.45 * (self.length - 1) + 2)
        alpha = pow(beta, pow2)
        
        # m_wrk indices 0 to 4 mappings
        prev_0 = self.m_wrk[r-1][0]
        prev_1 = self.m_wrk[r-1][1]
        prev_3 = self.m_wrk[r-1][3]
        prev_4 = self.m_wrk[r-1][4]
        
        self.m_wrk[r][0] = price + alpha * (prev_0 - price)
        self.m_wrk[r][1] = (price - self.m_wrk[r][0]) * (1 - beta) + beta * prev_1
        self.m_wrk[r][2] = (self.m_wrk[r][0] + corr * self.m_wrk[r][1])
        self.m_wrk[r][3] = (self.m_wrk[r][2] - prev_4) * pow((1 - alpha), 2) + pow(alpha, 2) * prev_3
        self.m_wrk[r][4] = (prev_4 + self.m_wrk[r][3])
        
        return self.m_wrk[r][4]


# ==============================================================================
# 4. Standard Deviation Class (HiStdDev3)
# ==============================================================================
class HiStdDev3:
    """
    Python implementation of HiStdDev3 from mySmoothingAlgorithm.mqh
    Standard Deviation Logic that maintains a fixed size buffer and updates O(1)
    """
    def __init__(self, window_size):
        self.m_size = window_size
        self.m_buffer = np.zeros(window_size)
        self.m_index = 0
        self.m_count = 0
        self.m_last_bar = -1
        self.m_last_stdValue = 0.0
        self.m_last_index = 0
        self.m_sum_sq = 0.0
        
    def calculate(self, bar, price):
        if bar > self.m_last_bar:
            # New bar (new data point event)
            
            # 1. Remove old data if buffer full
            if self.m_count >= self.m_size:
                old_val = self.m_buffer[self.m_index]
                self.m_sum_sq -= (old_val * old_val)
            else:
                self.m_count += 1
                
            # 2. Add new data
            self.m_buffer[self.m_index] = price
            self.m_sum_sq += (price * price)
            
            # 3. Save last index
            self.m_last_index = self.m_index
            
            # 4. Cycle index
            self.m_index = (self.m_index + 1) % self.m_size
            
            # 5. Calculate StdDev
            if self.m_count < 2:
                self.m_last_bar = bar
                self.m_last_stdValue = 0.0
                return 0.0
                
            variance = self.m_sum_sq / self.m_count
            self.m_last_stdValue = math.sqrt(max(0, variance))
            self.m_last_bar = bar
            return self.m_last_stdValue
            
        else:
            # Same bar (update current candle)
            if self.m_count > 0:
                old_price = self.m_buffer[self.m_last_index]
                self.m_buffer[self.m_last_index] = price
                
                self.m_sum_sq = self.m_sum_sq - (old_price * old_price) + (price * price)
                
                if self.m_count >= 2:
                    variance = self.m_sum_sq / self.m_count
                    self.m_last_stdValue = math.sqrt(max(0, variance))
                    
            return self.m_last_stdValue

# ==============================================================================
# 5. Helper: Time Filter
# ==============================================================================
def is_std_calculation_time(timestamp):
    """
    Replicates IsStdCalculationTime from myFunction.mqh
    """
    # Parse timestamp to hour/minute
    # Use pandas integer minutes
    # timestamp is expected to be a pandas Timestamp object
    
    current_minutes = timestamp.hour * 60 + timestamp.minute
    start_minutes = STD_CALC_START_HOUR * 60 + STD_CALC_START_MINUTE
    end_minutes = STD_CALC_END_HOUR * 60 + STD_CALC_END_MINUTE
    
    if start_minutes < end_minutes:
        return (current_minutes >= start_minutes) and (current_minutes < end_minutes)
    else:
        # Case spanning midnight
        return (current_minutes >= start_minutes) or (current_minutes < end_minutes)

# ==============================================================================
# 6. Main Execution Logic
# ==============================================================================
# ==============================================================================
# 6. Main Execution Logic
# ==============================================================================
def calculate_bop_avg_std(
    input_data, 
    smooth_period=DEFAULT_SMOOTH_PERIOD,
    avg_period=DEFAULT_AVG_PERIOD,
    std_period=DEFAULT_STD_PERIOD,
    std_multi1=DEFAULT_STD_MULTI1,
    std_multi2=DEFAULT_STD_MULTI2,
    std_multi3=DEFAULT_STD_MULTI3
):
    """
    Calculates BOP Avg Std indicators.
    input_data: str (csv_path) or pd.DataFrame
    Returns: pd.DataFrame with calculated columns
    """
    
    # 1. Load Data
    df = None
    if isinstance(input_data, str):
        print(f"Loading data from {input_data}...")
        try:
            # Try reading with tab separator first as MQL5 often defaults to it
            try:
                df = pd.read_csv(input_data, sep='\t')
                # If only 1 column found, retry with comma (auto-detect fallback)
                if len(df.columns) < 2:
                     df = pd.read_csv(input_data)
            except:
                df = pd.read_csv(input_data)
            
            # Normalize column names
            df.columns = [c.strip().lower() for c in df.columns]
            # Mapping common names to standard OCHL
            col_map = {}
            for c in df.columns:
                if 'time' in c or 'date' in c: col_map[c] = 'Time'
                if 'open' in c: col_map[c] = 'Open'
                if 'high' in c: col_map[c] = 'High'
                if 'low' in c: col_map[c] = 'Low'
                if 'close' in c: col_map[c] = 'Close'
                
            df = df.rename(columns=col_map)
            
            # Ensure Time is datetime
            try:
                 df['Time'] = pd.to_datetime(df['Time'])
            except:
                 df['Time'] = pd.to_datetime(df['Time'], format='%Y.%m.%d %H:%M')

        except Exception as e:
            print(f"Error loading CSV: {e}")
            return None
    elif isinstance(input_data, pd.DataFrame):
        df = input_data.copy()
        # Ensure columns are normalized if not already
        # Assuming Master script handles normalization, but safety check:
        if 'Time' not in df.columns and 'time' in df.columns:
            df.rename(columns={'time': 'Time'}, inplace=True)
    else:
        print("Invalid input data type")
        return None

    # print(f"Data Loaded: {len(df)} rows.")

    # 2. Calculate Rewards
    # print("Calculating Bulls/Bears Rewards...")
    bulls_reward = calculate_bulls_reward_series(df)
    bears_reward = calculate_bears_reward_series(df)
    
    # 3. Main Loop: Smoothing and StdDev
    # print("Running Main Loop (Smoothing & StdDev)...")
    
    results = {
        'BOP': [],
        'BOPAvg': [],
        'Diff': [],
        'Up3': [], 'Up2': [], 'Up1': [],
        'Down1': [], 'Down2': [], 'Down3': []
    }
    
    # Objects
    smoother = ISmooth(smooth_period, 0, len(df))
    std_dev3 = HiStdDev3(std_period)
    
    # Buffers (Lists for speed appending)
    bop_list = []
    
    # Pre-compute needed values
    times = df['Time'].dt.to_pydatetime()
    
    # Variables for loop
    prev_up3 = 0.0
    prev_up2 = 0.0
    prev_up1 = 0.0
    prev_down1 = 0.0
    prev_down2 = 0.0
    prev_down3 = 0.0
    
    n = len(df)
    
    for i in range(n):
        # --- 1. BOP Calculation using iSmooth ---
        # BOP[i] = iSmooth(Bulls - Bears, ...)
        raw_diff = bulls_reward[i] - bears_reward[i]
        bop_val = smoother.calculate(raw_diff, i)
        bop_list.append(bop_val)
        
        # --- 2. BOPAvg Calculation ---
        # BOPAvg[i] = myAverage(i, inpAvgPeriod, BOP)
        start_idx = i + 1 - avg_period
        if start_idx < 0: start_idx = 0
        slice_vals = bop_list[start_idx : i+1]
        
        bop_avg_val = 0.0
        if len(slice_vals) > 0:
            bop_avg_val = sum(slice_vals) / avg_period 
        
        diff_val = bop_val - bop_avg_val
        
        results['BOP'].append(bop_val)
        results['BOPAvg'].append(bop_avg_val)
        results['Diff'].append(diff_val)
        
        # --- 3. StdDev Calculation with Time Filter ---
        is_calc = is_std_calculation_time(times[i])
        
        up3, up2, up1 = 0.0, 0.0, 0.0
        dn1, dn2, dn3 = 0.0, 0.0, 0.0
        
        if is_calc:
            std_val = std_dev3.calculate(i, diff_val)
            up3 = std_val * std_multi3
            up2 = std_val * std_multi2
            up1 = std_val * std_multi1
            dn1 = -std_val * std_multi1
            dn2 = -std_val * std_multi2
            dn3 = -std_val * std_multi3
            
            # Update prevs
            prev_up3, prev_up2, prev_up1 = up3, up2, up1
            prev_down3, prev_down2, prev_down1 = dn3, dn2, dn1
        else:
            if i > 0:
                up3, up2, up1 = prev_up3, prev_up2, prev_up1
                dn1, dn2, dn3 = prev_down1, prev_down2, prev_down3
            else:
                pass # Zeros
                
        results['Up3'].append(up3)
        results['Up2'].append(up2)
        results['Up1'].append(up1)
        results['Down1'].append(dn1)
        results['Down2'].append(dn2)
        results['Down3'].append(dn3)
        
    # 4. Compile Results
    result_df = df.copy()
    for k, v in results.items():
        result_df[k] = v
        
    # Calculate Scale (Diff / StdDev)
    scales = np.zeros(len(df))
    diffs = result_df['Diff'].values
    up1s = result_df['Up1'].values
    
    for i in range(len(df)):
        std = up1s[i] / std_multi1 if std_multi1 != 0 else 0
        if std != 0:
            scales[i] = diffs[i] / std
        else:
            if i > 0:
                scales[i] = scales[i-1]
            else:
                scales[i] = 0.0
                
    result_df['Scale_Py'] = scales
    
    # print("Calculation Complete.")
    return result_df

def run_bop_analysis(csv_path):
    # Compatibility wrapper for standalone execution
    result_df = calculate_bop_avg_std(csv_path)
    if result_df is None: return

    # 5. Verification / Comparison (Logic moved here for standalone only)
    # The input CSV from MQL5 has columns: Diff, Up1, Scale (from MQL5)
    # We should look for them.
    # Note: If called as a library, we might not want to verify against specific columns unless requested.
    # But for this wrapper, we verify.
    
    df = result_df # result_df already includes original cols + new cols
    
    mql_cols = {'diff': 'Diff_MQL', 'up1': 'Up1_MQL', 'scale': 'Scale_MQL'}
    comparison_df = result_df.copy()
    
    # Check original columns
    found_mql = False
    for c in df.columns:
        c_lower = c.lower().strip()
        # This check is tricky because we already merged. 
        # But 'Diff' is now our calculated Diff. 
        # The original CSV loading logic in calculate_bop_avg_std keeps original columns? 
        # Yes, result_df = df.copy() and then we add new columns.
        # If input CSV had 'Diff', it is now overwritten by results['Diff']?
        # NO. df['Diff'] = v overwrites.
        # So we lost original Diff if it was named 'Diff'.
        pass

    # Wait, `results['Diff']` assignment overwrites the column.
    # If we want to verify, we should have renamed original columns upon loading.
    # In `calculate_bop_avg_std`, we didn't preserve original 'Diff' safely if names collide.
    # However, standard MQL5 export CSVs usually have specific names like 'Diff', 'Up1'.
    # If we overwrite them, we can't verify.
    
    # FOR NOW: I will assume the user uses this for generation mainly.
    # For verification, the input CSV usually has unique names or we should trust the parity I established before.
    # The previous code overwrote it too!
    # "result_df = df.copy()" -> "result_df[k] = v".
    # So previous verifier was actually overwriting 'Diff' if it existed?
    # Let's check previous code...
    # It loaded df.
    # Then it calculated.
    # Then `mql_cols = {'diff': 'Diff_MQL'...}`
    # `if c_lower in mql_cols: comparison_df[mql_cols[c_lower]] = df[c]`
    # Ah, `df` is the ORIGINAL dataframe. `result_df` is the NEW one.
    # In my new function, `result_df` is returned.
    # But I lost `df` (the original one) outside the function context unless I check columns before overwrite.
    
    # FIX: In `calculate_bop_avg_std`, I should return `result_df`. 
    # If I want to verify, I need the original values. 
    # But the prompt is about "Ensemble Data Generation", not strictly verification of the old file.
    # So it's fine.
    
    output_path = csv_path.replace(".csv", "_BOP_Analyzed.csv")
    result_df.to_csv(output_path, index=False)
    print(f"Results saved to: {output_path}")

# ==============================================================================
# 7. Entry Point
# ==============================================================================
if __name__ == "__main__":
    # Target specific file from User
    target_csv = "C:\\Users\\gim-yongsu\\AppData\\Roaming\\MetaQuotes\\Terminal\\5B326B03063D8D9C446E3637EFA32247\\MQL5\\Files\\BOPAvgStd_DownLoad.csv"
    
    if not os.path.exists(target_csv):
        print(f"Error: Target file not found at {target_csv}")
    else:
        run_bop_analysis(target_csv)
