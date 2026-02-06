import pandas as pd
import numpy as np
import os

# ==============================================================================
# Configuration
# ==============================================================================
FILE_PATH = os.path.join(os.getenv('APPDATA'), r"MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\QQE_DownLoad.csv")

INP_RSI_PERIOD = 32
INP_SF = 12
INP_WILDERS_PERIOD = INP_RSI_PERIOD * 2 - 1

# ==============================================================================
# Helper Functions
# ==============================================================================

def calculate_rsi_mql5(close_prices, period):
    """
    Calculates RSI matching MQL5's iRSI (Smoothed Moving Average for gains/losses).
    """
    n = len(close_prices)
    rsi = np.zeros(n)
    
    # Differences
    deltas = np.diff(close_prices)
    gains = np.where(deltas > 0, deltas, 0.0)
    losses = np.where(deltas < 0, -deltas, 0.0)
    
    # Initialization (First 'period' values used for simple average)
    # MQL5 iRSI starts providing values at index 'period'.
    # Indexes 0 to period-1 are effectively invalid (or 0).
    
    if n <= period:
        return rsi
        
    # First Average (Simple Mean)
    # Note: MQL5 implementation details might slightly vary on init.
    # Standard Wilder's: Simple MA for first period.
    avg_gain = np.mean(gains[:period])
    avg_loss = np.mean(losses[:period])
    
    # But wait, MQL5 often calculates from index `period` where it effectively uses previous values.
    # Let's try standard SMMA logic:
    # SMMA_i = (SMMA_{i-1} * (n-1) + Price_i) / n
    
    smma_gain = avg_gain
    smma_loss = avg_loss
    
    # RSI at index 'period' (the (period+1)-th bar)
    if smma_loss == 0:
        rsi[period] = 100.0
    else:
        rs = smma_gain / smma_loss
        rsi[period] = 100.0 - (100.0 / (1.0 + rs))
        
    for i in range(period + 1, n):
        idx = i - 1 # diff array index
        
        # SMMA Logic
        smma_gain = (smma_gain * (period - 1) + gains[idx]) / period
        smma_loss = (smma_loss * (period - 1) + losses[idx]) / period
        
        if smma_loss == 0:
            if smma_gain == 0:
                rsi[i] = 0.0 # Or 50? MQL5 handles divide by zero specifically.
            else:
                rsi[i] = 100.0
        else:
            rs = smma_gain / smma_loss
            rsi[i] = 100.0 - (100.0 / (1.0 + rs))
            
    return rsi

# ==============================================================================
# Main Logic
# ==============================================================================

# ==============================================================================
# Helper Functions
# ==============================================================================
def calculate_rsi_mql5(close_prices, period):
    """
    Calculates RSI matching MQL5's iRSI (Smoothed Moving Average for gains/losses).
    """
    n = len(close_prices)
    rsi = np.zeros(n)
    
    # Differences
    deltas = np.diff(close_prices)
    gains = np.where(deltas > 0, deltas, 0.0)
    losses = np.where(deltas < 0, -deltas, 0.0)
    
    # Initialization (First 'period' values used for simple average)
    if n <= period:
        return rsi
        
    # First Average (Simple Mean)
    avg_gain = np.mean(gains[:period])
    avg_loss = np.mean(losses[:period])
    
    smma_gain = avg_gain
    smma_loss = avg_loss
    
    # RSI at index 'period' (the (period+1)-th bar)
    if smma_loss == 0:
        rsi[period] = 100.0
    else:
        rs = smma_gain / smma_loss
        rsi[period] = 100.0 - (100.0 / (1.0 + rs))
        
    for i in range(period + 1, n):
        idx = i - 1 # diff array index
        
        # SMMA Logic
        smma_gain = (smma_gain * (period - 1) + gains[idx]) / period
        smma_loss = (smma_loss * (period - 1) + losses[idx]) / period
        
        if smma_loss == 0:
            if smma_gain == 0:
                rsi[i] = 0.0 # Or 50? MQL5 handles divide by zero specifically.
            else:
                rsi[i] = 100.0
        else:
            rs = smma_gain / smma_loss
            rsi[i] = 100.0 - (100.0 / (1.0 + rs))
            
    return rsi

# ==============================================================================
# Main Logic
# ==============================================================================
def calculate_qqe(
    input_data, 
    rsi_period=32, 
    sf=12
):
    """
    Calculates QQE indicators.
    input_data: str (csv_path) or pd.DataFrame
    """
    df = None
    if isinstance(input_data, str):
        if not os.path.exists(input_data):
            print(f"Error: File not found {input_data}")
            return None
        try:
            df = pd.read_csv(input_data, sep='\t')
            if 'Open' not in df.columns: raise ValueError
        except:
            try:
                df = pd.read_csv(input_data)
            except:
                return None
    elif isinstance(input_data, pd.DataFrame):
        df = input_data.copy()
    else:
        return None

    df.columns = df.columns.str.strip()
    if 'Close' not in df.columns:
        return None

    closes = df['Close'].values
    n = len(df)
    
    wilders_period = rsi_period * 2 - 1
    
    # 1. Calculate RSI
    rsi = calculate_rsi_mql5(closes, rsi_period)
    
    # 2. QQE Logic
    rsi_ma = np.zeros(n)
    atr_rsi = np.zeros(n)
    ma_atr_rsi = np.zeros(n)
    dar = np.zeros(n) # Stores the smoothed value before * 4.236
    tr_level = np.zeros(n)
    
    alpha_sf = 2.0 / (sf + 1.0)
    alpha_wilder = 2.0 / (wilders_period + 1.0)
    
    # Start logic
    for i in range(n):
        if i == 0:
            rsi_ma[i] = rsi[i]
            tr_level[i] = rsi_ma[i]
            # Others 0 initialized
            continue
            
        # [Step 1] RsiMa (EMA)
        rsi_ma[i] = rsi[i] * alpha_sf + rsi_ma[i-1] * (1.0 - alpha_sf)
        
        # [Step 2] ATR of RSI
        atr_rsi[i] = abs(rsi_ma[i] - rsi_ma[i-1])
        
        # [Step 3] Smooth ATR (EMA)
        ma_atr_rsi[i] = atr_rsi[i] * alpha_wilder + ma_atr_rsi[i-1] * (1.0 - alpha_wilder)
        
        # [Step 4] Smooth again (EMA) -> stored in DarBuffer
        dar[i] = ma_atr_rsi[i] * alpha_wilder + dar[i-1] * (1.0 - alpha_wilder)
        
        actual_dar = dar[i] * 4.236
        
        # [Step 5] Trailing Level
        prev_tr = tr_level[i-1]
        
        rsi0 = rsi_ma[i]
        rsi1 = rsi_ma[i-1]
        
        new_tr = prev_tr 
        
        if rsi0 < prev_tr:
            new_tr = rsi0 + actual_dar
            if rsi1 < prev_tr:
                if new_tr > prev_tr:
                    new_tr = prev_tr
        elif rsi0 > prev_tr:
            new_tr = rsi0 - actual_dar
            if rsi1 > prev_tr:
                if new_tr < prev_tr:
                    new_tr = prev_tr
                    
        tr_level[i] = new_tr
    
    df['Py_RSI'] = rsi
    df['Py_RsiMa'] = rsi_ma
    df['Py_TrLevel'] = tr_level
    
    return df

def main():
    file_path = os.path.join(os.getenv('APPDATA'), r"MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\QQE_DownLoad.csv")
    
    INP_RSI_PERIOD = 32
    INP_SF = 12
    
    df = calculate_qqe(file_path, INP_RSI_PERIOD, INP_SF)
    
    if df is not None and 'RsiMa' in df.columns:
        mql_rsi_ma = df['RsiMa'].values
        mql_tr_level = df['TrLevelSlow'].values
        
        rsi_ma = df['Py_RsiMa'].values
        tr_level = df['Py_TrLevel'].values
        
        # Comparison parameters
        valid_idx = INP_RSI_PERIOD * 3 
        
        diff_rsi_ma = np.abs(mql_rsi_ma - rsi_ma)
        diff_tr = np.abs(mql_tr_level - tr_level)
        
        print("\n--- Verification Results ---")
        print(f"RsiMa MAE (All): {np.mean(diff_rsi_ma):.6f}")
        print(f"RsiMa MAE (Valid > {valid_idx}): {np.mean(diff_rsi_ma[valid_idx:]):.6f}")
        
        print(f"TrLevel MAE (All): {np.mean(diff_tr):.6f}")
        print(f"TrLevel Max Diff (Valid): {np.max(diff_tr[valid_idx:]):.6f}")
        
        df['Diff_RsiMa'] = diff_rsi_ma
        df['Diff_TrLevel'] = diff_tr
        
        out_file = file_path.replace(".csv", "_Verification.csv")
        df.to_csv(out_file, index=False)
        print(f"Saved to {out_file}")

if __name__ == "__main__":
    main()
