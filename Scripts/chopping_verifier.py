import pandas as pd
import numpy as np
import math
import os

# --- Parameters ---
INP_CHO_PERIOD = 120
INP_SMOOTH_PERIOD = 40
INP_AVG_PERIOD = 1000
INP_STD_PERIOD = 4000
INP_SMOOTH_PHASE = 0.0

# --- Classes ---
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
        
        if self.m_index == 0 and self.m_count > 0:
            self.m_sum = sum(self.m_buffer[:self.m_count])
            
        self.m_index = (self.m_index + 1) % self.m_size
        
        return self.m_sum / self.m_count if self.m_count > 0 else 0.0

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
        
        if self.m_index == 0 and self.m_count > 0:
            self.m_sum_sq = sum(self.m_buffer[:self.m_count])
            
        self.m_index = (self.m_index + 1) % self.m_size
        
        if self.m_count < 1:
            return 0.0
            
        var = self.m_sum_sq / self.m_count
        return math.sqrt(max(0.0, var))

class JMA:
    def __init__(self):
        self.history = [] 
        
    def calculate(self, price, length, phase, r):
        current_row = [0.0] * 10
        
        if r == 0 or length <= 1:
            for k in range(7): current_row[k] = price
            self.history.append(current_row)
            return price
            
        prev_row = self.history[-1] 
        
        len1 = max(math.log(math.sqrt(0.5*(length-1)))/math.log(2.0)+2.0, 0)
        pow1 = max(len1-2.0, 0.5)
        bsmax = 5; bsmin = 6; volty = 7; vsum = 8; avolty = 9
        
        del1 = price - prev_row[bsmax]
        del2 = price - prev_row[bsmin]
        forBar = min(r, 10)
        hist_row_forBar = self.history[r - forBar]
        
        v_val = 0.0
        if abs(del1) > abs(del2): v_val = abs(del1)
        if abs(del1) < abs(del2): v_val = abs(del2)
        current_row[volty] = v_val
        
        current_row[vsum] = prev_row[vsum] + (v_val - hist_row_forBar[volty]) * 0.1
        current_row[avolty] = prev_row[avolty] + (2.0/(max(4.0*length,30)+1.0)) * (current_row[vsum] - prev_row[avolty])
        
        dVolty = current_row[volty] / current_row[avolty] if current_row[avolty] > 0 else 0
        if dVolty > math.pow(len1, 1.0/pow1): dVolty = math.pow(len1, 1.0/pow1)
        if dVolty < 1: dVolty = 1.0
        
        pow2 = math.pow(dVolty, pow1)
        len2 = math.sqrt(0.5*(length-1))*len1
        Kv = math.pow(len2/(len2+1), math.sqrt(pow2))
        
        if del1 > 0: current_row[bsmax] = price
        else: current_row[bsmax] = price - Kv * del1
        if del2 < 0: current_row[bsmin] = price
        else: current_row[bsmin] = price - Kv * del2
        
        corr = max(min(phase, 100), -100)/100.0 + 1.5
        beta = 0.45*(length-1)/(0.45*(length-1)+2)
        alpha = math.pow(beta, pow2)
        
        current_row[0] = price + alpha*(prev_row[0] - price)
        current_row[1] = (price - current_row[0])*(1-beta) + beta*prev_row[1]
        current_row[2] = (current_row[0] + corr*current_row[1])
        current_row[3] = (current_row[2] - prev_row[4])*math.pow((1-alpha),2) + math.pow(alpha,2)*prev_row[3]
        current_row[4] = (prev_row[4] + current_row[3])
        
        self.history.append(current_row)
        return current_row[4]

def calculate_chopping(input_data):
    """
    Calculates Chopping Index indicators.
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
    
    jma = JMA()
    hi_avg = HiAverage(INP_AVG_PERIOD)
    hi_std = HiStdDev1(INP_STD_PERIOD)
    
    _log = math.log(INP_CHO_PERIOD) / 100.0
    
    rates = len(df)
    py_csi = []
    py_avg = []
    py_scale = []
    
    high_series = df['High'].values
    low_series = df['Low'].values
    close_series = df['Close'].values
    
    # Precompute needed values for speed?
    # The double loop logic (k-loop) is heavy. 
    # For now keep it as is.
    
    for i in range(rates):
        max_h = high_series[i]
        min_l = low_series[i]
        
        atr_sum = 0.0
        
        for k in range(INP_CHO_PERIOD):
            if (i - k - 1) < 0: break
            
            h = high_series[i-k]
            l = low_series[i-k]
            prev_c = close_series[i-k-1]
            
            # TR
            tr = max(h, prev_c) - min(l, prev_c)
            atr_sum += tr
            
            max_h = max(max_h, max(h, prev_c))
            min_l = min(min_l, min(l, prev_c))
            
        val = 0.0
        if max_h != min_l: val = atr_sum / (max_h - min_l)
        
        csi_raw = 0.0
        if val != 0: csi_raw = math.log(val) / _log
        
        # Smoothing
        smoothed = jma.calculate(csi_raw, INP_SMOOTH_PERIOD, INP_SMOOTH_PHASE, i)
        py_csi.append(smoothed)
        
        # Average
        avg = hi_avg.calculate(smoothed)
        py_avg.append(avg)
        
        # StdDev
        std = hi_std.calculate(avg, smoothed)
        
        # Scale
        scale = 0.0
        if std != 0:
            scale = (smoothed - avg) / std
        else:
            if i > 0: scale = py_scale[-1]
            else: scale = 0.0
            
        py_scale.append(scale)
        
    df['Py_CSI'] = py_csi
    df['Py_Avg'] = py_avg
    df['Py_Scale'] = py_scale
    
    return df

if __name__ == '__main__':
    print("Running Chopping Test...")
