import pandas as pd
import numpy as np
import talib
import os

# Configuration
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUT_FILE = os.path.join(BASE_DIR, 'Data', 'xauusd_1min.csv')
OUTPUT_FILE = os.path.join(BASE_DIR, 'Data', '2025_Featured.csv')

def calculate_lra(close, period):
    # Linear Regression Angle/Slope approximation
    # MQL5 LRA is often LinearRegSlope. 
    # Let's use LinRegSlope from TA-Lib and normalize it or use it as is.
    # The optimized strategy uses LRA_BSPScale which is normalized.
    # We need to approximate the *Scale* logic. 
    # Assuming Scale = (Val - Avg) / Std ? No, LRA_BSPScale is likely the indicator value itself if it's already scaled.
    # In MQL5 BSP, LRA is often slope.
    slope = talib.LINEARREG_SLOPE(close, timeperiod=period)
    
    # We need to replicate the scaling logic if possible.
    # If we can't perfectly replicate, we normalize the slope using Z-Score over a rolling window matching the train data's distribution?
    # Or just use the raw slope if the training data was raw. 
    # Wait, the training data `LRA_BSPScale` had mean ~0.1, std ~1.0. It looks like Z-score.
    # I will apply Z-Score normalization on the slope.
    return slope

def calculate_bop(open_, high, low, close):
    # Balance of Power: (Close - Open) / (High - Low)
    bop = (close - open_) / (high - low)
    # The strategy uses 'BOP_Diff'. In MQL5 this might be BOP - MA(BOP).
    # Let's assume BOP_Diff is BOP - SMA(BOP, 20) for now, or just BOP.
    # *Correction*: In Analysis, BOP_Diff was highly correlated. 
    # Let's compute BOP and a smoothed version, then take diff.
    return bop

def calculate_adx(high, low, close, period=14):
    return talib.ADX(high, low, close, timeperiod=period)

def calculate_rsi(close, period=14):
    return talib.RSI(close, timeperiod=period)

def main():
    print(f"Loading {INPUT_FILE}...")
    df = pd.read_csv(INPUT_FILE)
    
    # Ensure correct types
    df['Time'] = pd.to_datetime(df['Time'])
    o = df['Open'].values
    h = df['High'].values
    l = df['Low'].values
    c = df['Close'].values
    
    print("Calculating Indicators...")
    
    # 1. LRA (Linear Regression Angle/Slope) -> Proxy for LRA_BSPScale
    # The authorized strategy uses LRA_BSPScale(60) and (180).
    # We will calc slopes and then standadize them.
    slope_60 = talib.LINEARREG_SLOPE(c, timeperiod=60)
    slope_180 = talib.LINEARREG_SLOPE(c, timeperiod=180)
    
    # 2. BOP (Balance of Power) -> Proxy for BOP_Diff
    # BOP_Diff = BOP - SmoothedBOP? Or BOP change?
    # Let's calculate standard BOP.
    bop = (c - o) / (h - l)
    bop = np.nan_to_num(bop) # Handle 0 division
    
    # 3. TDI / QQE / CHV / CSI (Approximations)
    # TDI: RSI based.
    rsi = talib.RSI(c, timeperiod=13)
    # TDI_TrSi often relates to RSI Signal line.
    
    # ADX
    adx = talib.ADX(h, l, c, timeperiod=14)
    
    # Add to DF
    df['LRA_BSPScale(60)'] = slope_60
    df['LRA_BSPScale(180)'] = slope_180
    df['BOP_Diff'] = bop # Placeholder, will be normalized later
    df['ADX_Val'] = adx
    
    # Mock missing complex indicators with RSI/ATR proxies if exact logic unknown
    # The optimizer used: QQE_TrLevel, TDI_TrSi, CHV_CVScale, CSI_Scale
    # I will substitute them with Normalized RSI/ATR derived features for the proxy
    # UNLESS I have their exact Python logic.
    # Given the constraint, I will map:
    # QQE_TrLevel -> RSI
    # TDI_TrSi -> RSI Moving Average
    # CHV_CVScale -> Chaikin Volatility (High-Low spread change)
    # CSI_Scale -> Commodity Selection Index? Or generic volatility? Let's use ATR/Close.
    
    df['QQE_TrLevel'] = rsi
    df['TDI_TrSi'] = talib.SMA(rsi, timeperiod=5)
    
    # CHV Logic: (EMA(H-L) - EMA(H-L).shift(10)) / EMA(H-L).shift(10)
    ema_hl = talib.EMA(h-l, timeperiod=10)
    ema_hl_series = pd.Series(ema_hl)
    df['CHV_CVScale'] = (ema_hl_series - ema_hl_series.shift(10)) / ema_hl_series.shift(10) * 100
    
    # CSI Logic: ATR / Close * 1000
    df['CSI_Scale'] = talib.ATR(h, l, c, timeperiod=14) / c * 1000
    
    # Normalize! The strategy expects Z-Score scaled inputs (Mean~0, Std~1)
    # We must normalize using the *2025 data itself* to align the distribution 
    # (Or ideally use 2026 stats, but Z-score is relative).
    # Local Z-Score normalization for 2025 is safer for "Pattern Recognition".
    
    cols_to_normalize = ['LRA_BSPScale(60)', 'LRA_BSPScale(180)', 'BOP_Diff', 'QQE_TrLevel', 'TDI_TrSi', 'CHV_CVScale', 'CSI_Scale']
    
    for col in cols_to_normalize:
        series = df[col]
        df[col] = (series - series.mean()) / series.std()
    
    print(f"Saving featured data to {OUTPUT_FILE}...")
    df.to_csv(OUTPUT_FILE, index=False)
    print("Done.")

if __name__ == "__main__":
    main()
