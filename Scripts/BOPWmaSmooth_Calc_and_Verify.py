import pandas as pd
import numpy as np
import os
import math

# Use the faster calculation method from BOPAvgStd_Verifier.py
def calculate_bulls_reward_series(df):
    opens = df['Open'].values
    highs = df['High'].values
    lows = df['Low'].values
    closes = df['Close'].values
    n = len(df)
    rewards = np.zeros(n)
    
    for i in range(n):
        O, H, L, C = opens[i], highs[i], lows[i], closes[i]
        rng = H - L
        if rng == 0:
            rewards[i] = 0
            continue
            
        reward_open = (H - O) / rng
        reward_close = (C - L) / rng
        
        if C > O:
            reward_oc = (C - O) / rng
        else:
            reward_oc = 0.0
            
        rewards[i] = (reward_open + reward_close + reward_oc) / 3.0
        
    return rewards

def calculate_bears_reward_series(df):
    opens = df['Open'].values
    highs = df['High'].values
    lows = df['Low'].values
    closes = df['Close'].values
    n = len(df)
    rewards = np.zeros(n)
    
    for i in range(n):
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

def calculate_wma(data, period):
    # Optimized WMA calculation
    n = len(data)
    wma = np.zeros(n)
    
    weights = np.arange(period, 0, -1)
    denom = period * (period + 1) / 2
    
    # Simple loop for correctness matching MQL5 logic
    # MQL5 iWma logic usually iterates back `period` times
    
    for i in range(n):
        if i < period - 1:
            # Partial WMA (ramp up) matching MQL5
            # MQL5 implementation usually handles i < period by taking available bars
            # Let's verify MQL5 generic WMA... assume standard
            # But the provided python script had logic for `if i < period - 1`
            curr_sum = 0.0
            curr_norm = 0.0
            for k in range(period):
                if i - k < 0: continue
                w_k = (period - k) * period # This weight logic in original script was weird: (period-k)*period?
                # Usually weight is (period-k) or (k+1)
                # Original script: w_k = (period-k)*period ?? 
                # Let's stick to valid WMA: weight 1..period
                # Recent weight = period. Oldest = 1.
                # data[i] * period + data[i-1] * (period-1) ...
                
                # Let's use the standard WMA definition since MQL5 `iWma` usually means standard.
                # However, previous script had custom logic. I will stick to standard WMA 
                # but handle start carefully.
                # PROBABLY the original script logic was trying to match a specific MQL5 artifact.
                # I'll stick to the standard:
                
                # If we want to match previous script's intent of "mimicking MQL5 loop behavior"
                # I will try to support the simple case first:
                pass
            
            # Reverting to simple loop for safety/clarity vs strict speed
            # Since N=100k, an O(N*Period) loop where Period=10 is 1M ops. Very fast in Python too.
            val_sum = 0.0
            weight_sum = 0.0
            for k in range(min(i + 1, period)):
                # k goes 0 to period-1
                # data[i-k] is the value
                # weight?
                # standard WMA: w = period - k ? 
                # YES. data[i]*period + data[i-1]*(period-1)
                w = period - k
                val_sum += data[i-k] * w
                weight_sum += w
            
            wma[i] = val_sum / weight_sum if weight_sum > 0 else 0
            
        else:
            # Full window
            # Use numpy slice
            window = data[i-period+1 : i+1]
            # window is [data[i-9], ..., data[i]]
            # weights should apply to window reversed?
            # data[i] * period + data[i-1] * (period-1)
            # window[-1] * period + ...
            # essentially dot product
            # weights array is [1, 2, ..., 10] (ascending) if dotting with [data[i-9]...data[i]]
            # weights = np.arange(1, period + 1)
            # wma[i] = np.dot(window, weights) / denom
            
            # Let's implement manually to be safe
            val_sum = 0.0
            for k in range(period):
                val_sum += data[i-k] * (period - k)
            wma[i] = val_sum / denom
             
    return wma

class SmoothFilter:
    def __init__(self, length, phase=0):
        self.length = length
        self.phase = phase
        self._instances = 2
        self._instance_size = 10
        self.m_wrk = [] # List of numpy arrays
        
    def calculate(self, price, r):
        # MQL5 Constants
        bsmax  = 5
        bsmin  = 6
        volty  = 7
        vsum   = 8
        avolty = 9
        
        # Ensure buffer size
        while len(self.m_wrk) <= r:
            self.m_wrk.append(np.zeros(20)) # 20 floats
            
        instance_no = 0
        idx = instance_no * self._instance_size
        
        # Access current row array directly
        curr_wrk = self.m_wrk[r]
        
        if r == 0 or self.length <= 1:
            for k in range(7):
                curr_wrk[idx + k] = price
            for k in range(7, 10):
                curr_wrk[idx + k] = 0
            return price
            
        len1 = max(math.log(math.sqrt(0.5 * (self.length - 1))) / math.log(2.0) + 2.0, 0)
        pow1 = max(len1 - 2.0, 0.5)
        
        prev_wrk = self.m_wrk[r-1]
        
        prev_bsmax = prev_wrk[idx + bsmax]
        prev_bsmin = prev_wrk[idx + bsmin]
        
        del1 = price - prev_bsmax
        del2 = price - prev_bsmin
        
        forBar = min(r, 10)
        
        curr_wrk[idx + volty] = 0
        if abs(del1) > abs(del2):
            curr_wrk[idx + volty] = abs(del1)
        if abs(del1) < abs(del2):
            curr_wrk[idx + volty] = abs(del2)
            
        prev_vsum = prev_wrk[idx + vsum]
        curr_volty = curr_wrk[idx + volty]
        old_volty = self.m_wrk[r-forBar][idx + volty]
        
        curr_wrk[idx + vsum] = prev_vsum + (curr_volty - old_volty) * 0.1
        
        prev_avolty = prev_wrk[idx + avolty]
        curr_vsum = curr_wrk[idx + vsum]
        
        curr_wrk[idx + avolty] = prev_avolty + (2.0 / (max(4.0 * self.length, 30) + 1.0)) * (curr_vsum - prev_avolty)
        
        curr_avolty = curr_wrk[idx + avolty]
        dVolty = curr_volty / curr_avolty if curr_avolty > 0 else 0
        
        if dVolty > pow(len1, 1.0/pow1):
            dVolty = pow(len1, 1.0/pow1)
        if dVolty < 1:
            dVolty = 1.0
            
        pow2 = pow(dVolty, pow1)
        len2 = math.sqrt(0.5 * (self.length - 1)) * len1
        Kv = pow(len2 / (len2 + 1), math.sqrt(pow2))
        
        if del1 > 0:
            curr_wrk[idx + bsmax] = price
        else:
            curr_wrk[idx + bsmax] = price - Kv * del1
            
        if del2 < 0:
            curr_wrk[idx + bsmin] = price
        else:
            curr_wrk[idx + bsmin] = price - Kv * del2
            
        corr = max(min(self.phase, 100), -100) / 100.0 + 1.5
        beta = 0.45 * (self.length - 1) / (0.45 * (self.length - 1) + 2)
        alpha = pow(beta, pow2)
        
        prev_0 = prev_wrk[idx + 0]
        curr_wrk[idx + 0] = price + alpha * (prev_0 - price)
        
        curr_0 = curr_wrk[idx + 0]
        prev_1 = prev_wrk[idx + 1]
        curr_wrk[idx + 1] = (price - curr_0) * (1 - beta) + beta * prev_1
        
        curr_1 = curr_wrk[idx + 1]
        curr_wrk[idx + 2] = (curr_0 + corr * curr_1)
        
        curr_2 = curr_wrk[idx + 2]
        prev_4 = prev_wrk[idx + 4]
        prev_3 = prev_wrk[idx + 3]
        
        curr_wrk[idx + 3] = (curr_2 - prev_4) * pow((1 - alpha), 2) + pow(alpha, 2) * prev_3
        
        curr_3 = curr_wrk[idx + 3]
        curr_wrk[idx + 4] = (prev_4 + curr_3)
        
        return curr_wrk[idx + 4]

def calculate_bop_wma(input_data, wma_period=10, smooth_period=3):
    """
    Calculates BOP WMA Smooth.
    input_data: str (csv_path) or pd.DataFrame
    return: pd.DataFrame
    """
    df = None
    if isinstance(input_data, str):
        if not os.path.exists(input_data):
            print(f"File not found: {input_data}")
            return None
        print("Loading CSV...")
        try:
            df = pd.read_csv(input_data, sep='\t')
            if len(df.columns) < 2:
                df = pd.read_csv(input_data)            
        except Exception as e:
            print(f"Error reading CSV: {e}")
            return None
            
        # Normalize and Ensure columns exist
        df.columns = [c.strip().lower() for c in df.columns]
        col_map = {}
        for c in df.columns:
             if 'time' in c: col_map[c] = 'Time'
             if 'open' in c: col_map[c] = 'Open'
             if 'high' in c: col_map[c] = 'High'
             if 'low' in c: col_map[c] = 'Low'
             if 'close' in c: col_map[c] = 'Close'
             if 'smoothbop' in c: col_map[c] = 'SmoothBOP'
        
        df = df.rename(columns=col_map)
        
    elif isinstance(input_data, pd.DataFrame):
        df = input_data.copy()
        # Ensure standard columns if they vary
        if 'Time' not in df.columns and 'time' in df.columns: df.rename(columns={'time': 'Time'}, inplace=True)
    else:
        return None

    # Check required columns
    required_columns = ['Open', 'High', 'Low', 'Close']
    for col in required_columns:
        if col not in df.columns:
            # print(f"Missing column: {col}")
            return None

    # print("Calculating Bulls/Bears Rewards (Vectorized)...")
    df['BullsReward'] = calculate_bulls_reward_series(df)
    df['BearsReward'] = calculate_bears_reward_series(df)
    
    # Cumulative Sum
    df['SumBulls'] = df['BullsReward'].cumsum()
    df['SumBears'] = df['BearsReward'].cumsum()
    
    # print("Calculating WMA...")
    df['WmaBulls'] = calculate_wma(df['SumBulls'].values, wma_period)
    df['WmaBears'] = calculate_wma(df['SumBears'].values, wma_period)
    
    df['BOP'] = df['WmaBulls'] - df['WmaBears']
    
    # print("Calculating Smoothing...")
    smoother = SmoothFilter(smooth_period, 0)
    df['PySmoothBOP'] = [smoother.calculate(bop, i) for i, bop in enumerate(df['BOP'])]
    
    return df

def main():
    # Parameters (Must match MQL5 inputs)
    inpWmaPeriod = 10
    inpSmoothPeriod = 3
    
    csv_file = "C:\\Users\\gim-yongsu\\AppData\\Roaming\\MetaQuotes\\Terminal\\5B326B03063D8D9C446E3637EFA32247\\MQL5\\Files\\BOPWmaSmooth_DownLoad.csv"
    
    df = calculate_bop_wma(csv_file, inpWmaPeriod, inpSmoothPeriod)
    if df is None: return

    # Comparison
    if 'SmoothBOP' in df.columns:
        df['Diff'] = df['PySmoothBOP'] - df['SmoothBOP']
        
        warmup_period = max(inpWmaPeriod, inpSmoothPeriod) * 10
        
        if len(df) > warmup_period:
            valid_diff = df['Diff'].iloc[warmup_period:]
            offset = valid_diff.mean()
            std_dev = valid_diff.std()
            
            df['AdjustedDiff'] = df['Diff'] - offset
            max_adj_diff = df['AdjustedDiff'].iloc[warmup_period:].abs().max()
            
            print(f"\nWarmup Period: {warmup_period} bars")
            print(f"Detected Offset (Py - MQL5): {offset:.6f}")
            print(f"Std Dev of Diff (after warmup): {std_dev:.8f}")
            print(f"Max Adjusted Diff (after warmup): {max_adj_diff:.8f}")
            
            print("\nLast 10 Comparisons (Adjusted):")
            print(df[['Time', 'SmoothBOP', 'PySmoothBOP', 'Diff', 'AdjustedDiff']].tail(10))
            
            if std_dev < 1e-5:
                print("\nSUCCESS: Python calculation matches MQL5 output (with constant offset).")
            else:
                print("\nWARNING: Mismatch detected. Logic may differ.")
                
        else:
            print("\nNot enough data for offset verification.")
            print(f"Max Diff (Unadjusted): {df['Diff'].abs().max()}")

if __name__ == "__main__":
    main()
