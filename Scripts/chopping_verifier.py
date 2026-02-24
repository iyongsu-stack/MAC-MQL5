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

# ---------------------------------------------------------
# 원본의 적응형 JMA 로직 (단 성능을 위해 최적화된 형태로 클래스 복원)
# ---------------------------------------------------------
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

class HiAverage:
    def __init__(self, window_size):
        self.m_size = max(1, window_size)
        self.m_buffer = np.zeros(self.m_size)
        self.m_index = 0
        self.m_count = 0
        self.m_sum = 0.0

    def calculate(self, price):
        if self.m_count >= self.m_size:
            old_val = self.m_buffer[self.m_index]
            self.m_sum -= old_val
        else:
            self.m_count += 1
            
        self.m_buffer[self.m_index] = price
        self.m_sum += price
        
        if self.m_index == 0 and self.m_count > 0:
            self.m_sum = self.m_buffer[:self.m_count].sum()
            
        self.m_index = (self.m_index + 1) % self.m_size
        return self.m_sum / self.m_count if self.m_count > 0 else 0.0

class HiStdDev1:
    def __init__(self, window_size):
        self.m_size = max(1, window_size)
        self.m_buffer = np.zeros(self.m_size)
        self.m_index = 0
        self.m_count = 0
        self.m_sum_sq = 0.0

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
            self.m_sum_sq = self.m_buffer[:self.m_count].sum()
            
        self.m_index = (self.m_index + 1) % self.m_size
        if self.m_count < 1: return 0.0
        var = self.m_sum_sq / self.m_count
        return math.sqrt(max(0.0, var))

def compute_chop(high, low, close, cho_period, smooth_period, avg_period=1000, std_period=4000):
    n = len(close)
    prev_c=np.empty(n); prev_c[0]=np.nan; prev_c[1:]=close[:-1]
    eff_h=np.maximum(high,prev_c); eff_l=np.minimum(low,prev_c)
    bar_tr=pd.Series(eff_h-eff_l)
    
    # 벡터화하여 raw csi 미리 전체 계산 (이것이 이중 for문을 없애서 99% 속도를 향상시킴)
    atr_sum=bar_tr.rolling(cho_period,min_periods=1).sum().values
    rmh=pd.Series(eff_h).rolling(cho_period,min_periods=1).max().values
    rml=pd.Series(eff_l).rolling(cho_period,min_periods=1).min().values
    
    _log=math.log(cho_period)/100.0; denom=rmh-rml
    with np.errstate(divide='ignore',invalid='ignore'):
        val=np.where(denom>0, atr_sum/denom, 0.0)
        raw=np.where((val>0)&(_log!=0), np.log(np.clip(val,1e-30,None))/_log, 0.0)
    raw=np.where(np.isfinite(raw),raw,0.0)
    
    # JMA, Avg, Std는 상태의존 루프 사용 (O(N) 단일 루프이므로 수 초 내 완료)
    jma_obj = JMA()
    hi_avg = HiAverage(avg_period)
    hi_std = HiStdDev1(std_period)
    
    csi = np.zeros(n)
    avg = np.zeros(n)
    scale = np.zeros(n)
    
    for i in range(n):
        smoothed = jma_obj.calculate(raw[i], smooth_period, INP_SMOOTH_PHASE, i)
        csi[i] = smoothed
        
        a = hi_avg.calculate(smoothed)
        avg[i] = a
        
        s = hi_std.calculate(a, smoothed)
        if s != 0:
            scale[i] = (smoothed - a) / s
        else:
            scale[i] = scale[i-1] if i > 0 else 0.0
            
    return csi, avg, scale

def calculate_chopping(input_data):
    df = None
    if isinstance(input_data, str):
        if os.path.exists(input_data):
            try:
                df = pd.read_csv(input_data, sep='\t', low_memory=False)
                if len(df.columns) < 2: df = pd.read_csv(input_data, low_memory=False)
            except:
                df = pd.read_csv(input_data, low_memory=False)
        else:
            return None
    elif isinstance(input_data, pd.DataFrame):
        df = input_data.copy()
    else: return None
        
    if df is None: return None
    
    df.columns = [c.strip() for c in df.columns]
    for col in ['High', 'Low', 'Close']:
        df[col] = pd.to_numeric(df[col], errors='coerce')
        
    H = df['High'].values
    L = df['Low'].values
    C = df['Close'].values
    
    csi, avg, scale = compute_chop(H, L, C, INP_CHO_PERIOD, INP_SMOOTH_PERIOD, INP_AVG_PERIOD, INP_STD_PERIOD)
    
    df['Py_CSI'] = csi
    df['Py_Avg'] = avg
    df['Py_Scale'] = scale
    
    return df

if __name__ == '__main__':
    print("Running Fast Chopping Test...")
