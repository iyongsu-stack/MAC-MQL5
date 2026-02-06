
import pandas as pd
import numpy as np
import os

# ==============================================================================
# Helper Functions
# ==============================================================================
def calculate_wilder_rsi(close_prices, period):
    """
    Calculates RSI using Wilder's Smoothing to match MQL5 iRSI.
    """
    # Calculate changes
    delta = pd.Series(close_prices).diff().values
    
    # Separation of gains and losses
    gain = np.clip(delta, 0, None)
    loss = -np.clip(delta, None, 0)
    
    avg_gain = np.zeros_like(close_prices)
    avg_loss = np.zeros_like(close_prices)
    rsi = np.zeros_like(close_prices)
    
    if len(close_prices) < period + 1:
        return rsi
        
    # Initial average (SMA)
    # Slicing gain[1:period+1] gives 'period' elements
    # MQL5 iRSI starts calculating at index 'period'.
    avg_gain[period] = gain[1:period+1].mean()
    avg_loss[period] = loss[1:period+1].mean()
    
    # Recursive Wilder's Smoothing
    for i in range(period + 1, len(close_prices)):
        avg_gain[i] = (avg_gain[i-1] * (period - 1) + gain[i]) / period
        avg_loss[i] = (avg_loss[i-1] * (period - 1) + loss[i]) / period
        
    # Calc RSI
    # Avoid division by zero
    rs = np.divide(avg_gain, avg_loss, out=np.zeros_like(avg_gain), where=avg_loss!=0)
    
    rsi = 100 - (100 / (1 + rs))
    
    for i in range(len(rsi)):
        if avg_loss[i] == 0:
            if avg_gain[i] > 0:
                rsi[i] = 100.0
            else:
                rsi[i] = 0.0 
                
    # Clean up before start period
    rsi[:period] = 0.0
    
    return rsi

def calculate_sma(series, period):
    """
    Calculates Simple Moving Average on a numpy array.
    Matches MQL5 SimpleMAOnBuffer.
    """
    sma = np.zeros_like(series)
    series_s = pd.Series(series)
    # Pandas rolling mean
    sma_s = series_s.rolling(window=period).mean()
    sma = sma_s.fillna(0.0).values
    return sma

# ==============================================================================
# Main Logic
# ==============================================================================
def calculate_tdi(
    input_data, 
    rsi_period=13, 
    smooth_rsi_period=2, 
    signal_period=7
):
    """
    Calculates TDI indicators.
    input_data: str (csv_path) or pd.DataFrame
    """
    df = None
    if isinstance(input_data, str):
        if not os.path.exists(input_data):
            print(f"Error: File not found {input_data}")
            return None
        # Robust CSV Loading
        try:
            df = pd.read_csv(input_data, sep='\t')
            if 'Close' not in df.columns:
                df = pd.read_csv(input_data, sep=r'\s+')
                if 'Close' not in df.columns:
                    df = pd.read_csv(input_data)
        except:
             df = pd.read_csv(input_data)
    elif isinstance(input_data, pd.DataFrame):
        df = input_data.copy()
    else:
        return None

    # Check Columns
    if 'Close' not in df.columns:
        return None

    close = df['Close'].values
    
    # 1. Calculate RSI
    py_rsi = calculate_wilder_rsi(close, rsi_period)
    
    # 2. Calculate TrSi (Green) = SMA(RSI, 2)
    py_trsi = calculate_sma(py_rsi, smooth_rsi_period)
    
    # 3. Calculate Signal (Red) = SMA(RSI, 7)
    py_signal = calculate_sma(py_rsi, signal_period)
    
    df['Py_RSI'] = py_rsi
    df['Py_TrSi'] = py_trsi
    df['Py_Signal'] = py_signal
    
    return df

def main():
    file_path = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\TradesDynamicIndex_DownLoad.csv"
    
    # Use defaults
    df = calculate_tdi(file_path)
    
    if df is not None:
        if 'TrSi' in df.columns and 'Signal' in df.columns:
            mql_trsi = df['TrSi'].values
            mql_signal = df['Signal'].values
            
            py_trsi = df['Py_TrSi'].values
            py_signal = df['Py_Signal'].values
            
            # Find start index
            start_idx = 0
            for i in range(len(mql_signal)):
                if mql_signal[i] != 0 and mql_trsi[i] != 0:
                    start_idx = i
                    break
                    
            print(f"Comparison starting at index: {start_idx}")
            
            v_mql_trsi = mql_trsi[start_idx:]
            v_py_trsi = py_trsi[start_idx:]
            
            v_mql_sig = mql_signal[start_idx:]
            v_py_sig = py_signal[start_idx:]
            
            mae_trsi = np.mean(np.abs(v_mql_trsi - v_py_trsi))
            mae_sig = np.mean(np.abs(v_mql_sig - v_py_sig))
            
            print("-" * 30)
            print(f"Verification Results (Rows {start_idx} to {len(df)})")
            print("-" * 30)
            print(f"TrSi (Green) MAE: {mae_trsi:.6f}")
            print(f"Signal (Red) MAE: {mae_sig:.6f}")
            
            df['Diff_TrSi'] = np.abs(df['TrSi'] - df['Py_TrSi'])
            df['Diff_Signal'] = np.abs(df['Signal'] - df['Py_Signal'])
            
            output_path = file_path.replace(".csv", "_Verification_Result.csv")
            df.to_csv(output_path, index=False)
            print(f"Comparison file saved to: {output_path}")

if __name__ == "__main__":
    main()
