import pandas as pd
import numpy as np

# MQL5 to Pandas Timeframe Mapping
MQL5_TO_PANDAS_TF = {
    'PERIOD_M1': '1min',
    'PERIOD_M5': '5min',
    'PERIOD_M15': '15min',
    'PERIOD_M30': '30min',
    'PERIOD_H1': '1h',
    'PERIOD_H4': '4h',
    'PERIOD_D1': '1D',
    'PERIOD_W1': '1W',
    'PERIOD_MN1': '1ME'
}

def calculate_adx_smooth_mtf(df, target_timeframe='4h', period=14, alpha1=0.25, alpha2=0.33):
    """
    Calculates ADXSmoothMTF from lower timeframe data (e.g., M1).
    
    Parameters:
    df (pd.DataFrame): DataFrame containing 'High', 'Low', 'Close' columns and a Datetime Index.
    target_timeframe (str): Timeframe to resample to (e.g., '4h', '1d', or None). 
                            You can also pass MQL5 timeframe names like 'PERIOD_H4' (using MQL5_TO_PANDAS_TF).
    period (int): Period for ADX calculation (default 14).
    alpha1 (float): Coefficient for 1st smoothing stage.
    alpha2 (float): Coefficient for 2nd smoothing stage.
    
    Returns:
    pd.DataFrame: DataFrame with 'DiPlus_Final', 'DiMinus_Final', 'ADX_Final' columns aligned to original index (ffill).
    """
    # Create a copy to avoid modifying original
    data = df.copy()
    
    # Check for Datetime Index
    if not isinstance(data.index, pd.DatetimeIndex):
        try:
            data.index = pd.to_datetime(data['Time'])
        except:
            pass # Assume index is already correct or handled by caller
            
    # Resample Logic
    actual_timeframe = target_timeframe
    if actual_timeframe in MQL5_TO_PANDAS_TF:
        actual_timeframe = MQL5_TO_PANDAS_TF[actual_timeframe]
        
    if actual_timeframe:
        ts_data = data.resample(actual_timeframe).agg({
            'Open': 'first',
            'High': 'max',
            'Low': 'min',
            'Close': 'last'
        }).dropna()
    else:
        ts_data = data

    # --- Standard ADX Calculation (EMA based, matching MQL5 ADX.mq5) ---
    high = ts_data['High'].values
    low = ts_data['Low'].values
    close = ts_data['Close'].values
    rates_total = len(ts_data)
    
    # MQL5 iADX uses Standard EMA: alpha = 2.0 / (period + 1.0)
    alpha_adx = 2.0 / (period + 1.0)
    
    tr_arr = np.zeros(rates_total)
    pdm_ratio = np.zeros(rates_total)
    mdm_ratio = np.zeros(rates_total)
    
    for i in range(1, rates_total):
        h = high[i]
        l = low[i]
        cp = close[i-1]
        
        tr_val = max(h - l, abs(h - cp), abs(l - cp))
        tr_arr[i] = tr_val
        
        up = h - high[i-1]
        down = low[i-1] - l
        
        dm_p = 0.0
        dm_m = 0.0
        
        if up > down and up > 0:
            dm_p = up
        elif down > up and down > 0:
            dm_m = down
            
        if tr_val != 0.0:
            pdm_ratio[i] = 100.0 * dm_p / tr_val
            mdm_ratio[i] = 100.0 * dm_m / tr_val

    # Smoothing (EMA)
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
        safe_sum = np.where(sum_di == 0, 1e-9, sum_di)
        dx = 100.0 * np.abs(pdi - ndi) / safe_sum
        
    # ADX (EMA)
    adx_raw = np.zeros(rates_total)
    prev_a = 0.0
    for i in range(1, rates_total):
        adx_raw[i] = dx[i] * alpha_adx + prev_a * (1.0 - alpha_adx)
        prev_a = adx_raw[i]
        
    # --- Custom Smoothing Logic (2 Stages) ---
    di_plus_final = np.zeros(rates_total)
    di_minus_final = np.zeros(rates_total)
    adx_final = np.zeros(rates_total)
    
    # State variables
    last_p, last_m, last_a = 0.0, 0.0, 0.0 
    
    for i in range(1, rates_total):
        # Level 1 Smoothing
        val_p = 2 * pdi[i] + (alpha1 - 2) * pdi[i-1] + (1 - alpha1) * last_p
        val_m = 2 * ndi[i] + (alpha1 - 2) * ndi[i-1] + (1 - ALPHA1) * last_m
        val_a = 2 * adx_raw[i] + (alpha1 - 2) * adx_raw[i-1] + (1 - ALPHA1) * last_a
        
        last_p, last_m, last_a = val_p, val_m, val_a
        
        # Level 2 Smoothing
        di_plus_final[i] = alpha2 * val_p + (1 - alpha2) * di_plus_final[i-1]
        di_minus_final[i] = alpha2 * val_m + (1 - alpha2) * di_minus_final[i-1]
        adx_final[i] = alpha2 * val_a + (1 - alpha2) * adx_final[i-1]

    # Assign to DataFrame
    ts_data['DiPlus_Final'] = di_plus_final
    ts_data['DiMinus_Final'] = di_minus_final
    ts_data['ADX_Final'] = adx_final
    
    # Merge back to original specific logic:
    # If resampling was done, we need to map back to original timeline (ffill)
    if target_timeframe:
        # Align index
        result = data[['Close']].copy() # Dummy copy to preserve index
        result = result.join(ts_data[['DiPlus_Final', 'DiMinus_Final', 'ADX_Final']], how='left')
        result.ffill(inplace=True)
        return result
    else:
        return ts_data[['DiPlus_Final', 'DiMinus_Final', 'ADX_Final']]

# Example Usage
if __name__ == "__main__":
    # Example for M1 -> H4 conversion
    pass
