import pandas as pd
import numpy as np
import os

# MQL5 Parameters
ATR_PERIOD = 22
ATR_MULT1 = 3.0
ATR_MULT2 = 4.5
LOOKBACK_PERIOD = 22

def calculate_chandelier(input_data):
    """
    Calculates Chandelier Exit indicators.
    input_data: str (csv path) or pd.DataFrame
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

    # Preprocessing
    df.columns = [c.strip().lower() for c in df.columns]
    col_map = {}
    for c in df.columns:
        if 'time' in c: col_map[c] = 'time'
        if 'open' in c: col_map[c] = 'open'
        if 'high' in c: col_map[c] = 'high'
        if 'low' in c: col_map[c] = 'low'
        if 'close' in c: col_map[c] = 'close'
        
    df.rename(columns=col_map, inplace=True)
    if 'time' in df.columns:
        try:
            df['time'] = pd.to_datetime(df['time'])
        except:
            pass

    # Logic
    df['prev_close'] = df['close'].shift(1)
    df['tr_high'] = df[['high', 'prev_close']].max(axis=1)
    df['tr_low'] = df[['low', 'prev_close']].min(axis=1)
    df['tr'] = df['tr_high'] - df['tr_low']
    df['atr'] = df['tr'].rolling(window=ATR_PERIOD).mean().shift(1)

    df['max_high'] = df['high'].rolling(window=LOOKBACK_PERIOD).max().shift(1)
    df['min_low'] = df['low'].rolling(window=LOOKBACK_PERIOD).min().shift(1)

    n = len(df)
    close = df['close'].values
    max_high = df['max_high'].values
    min_low = df['min_low'].values
    atr = df['atr'].values

    py_upl1 = np.full(n, np.nan)
    py_dnl1 = np.full(n, np.nan)
    py_upl2 = np.full(n, np.nan)
    py_dnl2 = np.full(n, np.nan)

    curr_hi1_work = np.nan
    curr_lo1_work = np.nan
    curr_hi2_work = np.nan
    curr_lo2_work = np.nan
    curr_trend1 = 0
    curr_trend2 = 0

    start_idx = max(ATR_PERIOD, LOOKBACK_PERIOD) + 1

    for i in range(start_idx, n):
        _atr = atr[i]
        _max = max_high[i]
        _min = min_low[i]
        
        if np.isnan(_atr) or np.isnan(_max) or np.isnan(_min):
            continue

        raw_hi1 = _max - ATR_MULT1 * _atr
        raw_lo1 = _min + ATR_MULT1 * _atr
        raw_hi2 = _max - ATR_MULT2 * _atr
        raw_lo2 = _min + ATR_MULT2 * _atr

        prev_hi1_work = curr_hi1_work
        prev_lo1_work = curr_lo1_work
        prev_hi2_work = curr_hi2_work
        prev_lo2_work = curr_lo2_work
        
        if np.isnan(prev_hi1_work): prev_hi1_work = raw_hi1
        if np.isnan(prev_lo1_work): prev_lo1_work = raw_lo1
        if np.isnan(prev_hi2_work): prev_hi2_work = raw_hi2
        if np.isnan(prev_lo2_work): prev_lo2_work = raw_lo2

        new_trend1 = curr_trend1
        if close[i] > prev_lo1_work: new_trend1 = 1
        if close[i] < prev_hi1_work: new_trend1 = -1
        
        new_trend2 = curr_trend2
        if close[i] > prev_lo2_work: new_trend2 = 1
        if close[i] < prev_hi2_work: new_trend2 = -1

        final_hi1_work = raw_hi1
        if new_trend1 == 1:
            if raw_hi1 < prev_hi1_work: final_hi1_work = prev_hi1_work
            py_upl1[i] = final_hi1_work
        
        final_lo1_work = raw_lo1
        if new_trend1 == -1:
            if raw_lo1 > prev_lo1_work: final_lo1_work = prev_lo1_work
            py_dnl1[i] = final_lo1_work

        final_hi2_work = raw_hi2
        if new_trend2 == 1:
            if raw_hi2 < prev_hi2_work: final_hi2_work = prev_hi2_work
            py_upl2[i] = final_hi2_work

        final_lo2_work = raw_lo2
        if new_trend2 == -1:
            if raw_lo2 > prev_lo2_work: final_lo2_work = prev_lo2_work
            py_dnl2[i] = final_lo2_work

        curr_trend1 = new_trend1
        curr_trend2 = new_trend2
        curr_hi1_work = final_hi1_work
        curr_lo1_work = final_lo1_work
        curr_hi2_work = final_hi2_work
        curr_lo2_work = final_lo2_work

    df['Py_Upl1'] = py_upl1
    df['Py_Dnl1'] = py_dnl1
    df['Py_Upl2'] = py_upl2
    df['Py_Dnl2'] = py_dnl2
    
    return df

if __name__ == "__main__":
    print("Running Chandelier Verifier...")
    # csv_path = ...
