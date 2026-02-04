import pandas as pd
import numpy as np
import math
import os

# ==========================================
# Parameters (Match MQL5 Inputs)
# ==========================================
inpWmaPeriod = 10
inpSmoothPeriod = 3

# ==========================================
# Helper Functions (myBSPCalculation.mqh)
# ==========================================

def CalculateBuyRatio(row, prev_row):
    """
    Replicates CalculateBuyRatio from myBSPCalculation.mqh
    """
    if prev_row is None:
        return 0.0
    
    open_price = row['Open']
    high = row['High']
    low = row['Low']
    close = row['Close']
    
    prev_close = prev_row['Close']
    
    buyRatio = 0.0
    
    # Bearish Candle
    if close < open_price:
        if prev_close < open_price:
            buyRatio = max(high - prev_close, close - low)
        else:
            buyRatio = max(high - open_price, close - low)
            
    # Bullish Candle
    elif close > open_price:
        if prev_close > open_price:
            buyRatio = high - low
        else:
            buyRatio = max(open_price - prev_close, high - low)
            
    # Doji Candle
    else:
        if (high - close) > (close - low):
            if prev_close < open_price:
                buyRatio = max(high - prev_close, close - low)
            else:
                buyRatio = high - open_price
        elif (high - close) < (close - low):
            if prev_close > open_price:
                buyRatio = high - low
            else:
                buyRatio = max(open_price - prev_close, high - low)
        else:
            if prev_close > open_price:
                buyRatio = max(high - open_price, close - low)
            elif prev_close < open_price:
                buyRatio = max(open_price - prev_close, high - low)
            else:
                buyRatio = high - low
                
    return buyRatio

def CalculateSellRatio(row, prev_row):
    """
    Replicates CalculateSellRatio from myBSPCalculation.mqh
    """
    if prev_row is None:
        return 0.0
    
    open_price = row['Open']
    high = row['High']
    low = row['Low']
    close = row['Close']
    
    prev_close = prev_row['Close']
    
    sellRatio = 0.0
    
    # Bearish Candle
    if close < open_price:
        if prev_close > open_price:
            sellRatio = max(prev_close - open_price, high - low)
        else:
            sellRatio = high - low
            
    # Bullish Candle
    elif close > open_price:
        if prev_close > open_price:
            sellRatio = max(prev_close - low, high - close)
        else:
            sellRatio = max(open_price - low, high - close)
            
    # Doji Candle
    else:
        if (high - close) > (close - low):
            if prev_close > open_price:
                sellRatio = max(prev_close - open_price, high - low)
            else:
                sellRatio = high - low
        elif (high - close) < (close - low):
            if prev_close > open_price:
                sellRatio = max(prev_close - low, high - close)
            else:
                sellRatio = open_price - low
        else:
            if prev_close > open_price:
                sellRatio = max(prev_close - open_price, high - low)
            elif prev_close < open_price:
                sellRatio = max(open_price - low, high - close)
            else:
                sellRatio = high - low
                
    return sellRatio

# ==========================================
# Smoothing Algorithm (mySmoothingAlgorithm.mqh)
# ==========================================

class SmoothFilter:
    """
    Replicates iSmooth function class structure.
    State is maintained per instance.
    """
    def __init__(self, length, phase):
        self.length = length
        self.phase = phase
        
        # Determine array size needed (10 per instance)
        # In Python we just keep a list or dict of vars
        # MQL5: m_wrk[r][instanceNo+k]
        # We only need the "previous" values to calculate current.
        # But MQL5 uses [r-1] and [r-forBar], where forBar can be up to 10 back?
        # int forBar = MathMin(r,10);
        # m_wrk[r-forBar] access implies we need a history buffer of at least 10.
        
        self.history = [] # List of dicts maps to m_wrk rows
        
        # Indices mapping from MQL5 #defines
        self.BSMAX = 5
        self.BSMIN = 6
        self.VOLTY = 7
        self.VSUM  = 8
        self.AVOLTY= 9
        
    def calculate(self, price, r):
        # Initialize current row with zeros
        current_state = {i: 0.0 for i in range(10)}
        
        # Initialization logic from MQL5
        # if(r==0 || length<=1) ...
        if r == 0 or self.length <= 1:
            for k in range(7): current_state[k] = price
            for k in range(7, 10): current_state[k] = 0
            self.history.append(current_state)
            return price

        # Helper to safely get history
        def get_hist(offset, idx):
            if r - offset < 0: return 0.0
            return self.history[r - offset][idx]

        # Calculation
        len1 = max(math.log(math.sqrt(0.5 * (self.length - 1))) / math.log(2.0) + 2.0, 0)
        pow1 = max(len1 - 2.0, 0.5)
        
        prev_bsmax = get_hist(1, self.BSMAX)
        prev_bsmin = get_hist(1, self.BSMIN)
        
        del1 = price - prev_bsmax
        del2 = price - prev_bsmin
        
        forBar = min(r, 10)
        
        volty_val = 0.0
        if abs(del1) > abs(del2): volty_val = abs(del1)
        if abs(del1) < abs(del2): volty_val = abs(del2)
        current_state[self.VOLTY] = volty_val
        
        # m_wrk[r][instanceNo+vsum]=m_wrk[r-1][instanceNo+vsum]+(m_wrk[r][instanceNo+volty]-m_wrk[r-forBar][instanceNo+volty])*0.1;
        prev_vsum = get_hist(1, self.VSUM)
        prev_volty_forBar = get_hist(forBar, self.VOLTY)
        
        vsum_val = prev_vsum + (volty_val - prev_volty_forBar) * 0.1
        current_state[self.VSUM] = vsum_val
        
        # m_wrk[r][instanceNo+avolty]=m_wrk[r-1][instanceNo+avolty]+(2.0/(MathMax(4.0*length,30)+1.0))*(m_wrk[r][instanceNo+vsum]-m_wrk[r-1][instanceNo+avolty]);
        prev_avolty = get_hist(1, self.AVOLTY)
        avolty_val = prev_avolty + (2.0 / (max(4.0 * self.length, 30) + 1.0)) * (vsum_val - prev_avolty)
        current_state[self.AVOLTY] = avolty_val
        
        dVolty = (volty_val / avolty_val) if avolty_val > 0 else 0
        if dVolty > pow(len1, 1.0/pow1): dVolty = pow(len1, 1.0/pow1)
        if dVolty < 1: dVolty = 1.0
        
        pow2 = pow(dVolty, pow1)
        len2 = math.sqrt(0.5 * (self.length - 1)) * len1
        Kv = pow(len2 / (len2 + 1), math.sqrt(pow2))
        
        if del1 > 0: current_state[self.BSMAX] = price
        else: current_state[self.BSMAX] = price - Kv * del1
            
        if del2 < 0: current_state[self.BSMIN] = price
        else: current_state[self.BSMIN] = price - Kv * del2
        
        # Phase calculation
        corr = max(min(self.phase, 100), -100) / 100.0 + 1.5
        beta = 0.45 * (self.length - 1) / (0.45 * (self.length - 1) + 2)
        alpha = pow(beta, pow2)
        
        # m_wrk[r][0] = price + alpha*(m_wrk[r-1][0]-price);
        prev_0 = get_hist(1, 0)
        val_0 = price + alpha * (prev_0 - price)
        current_state[0] = val_0
        
        # m_wrk[r][1] = (price - m_wrk[r][0])*(1-beta) + beta*m_wrk[r-1][1];
        prev_1 = get_hist(1, 1)
        val_1 = (price - val_0) * (1 - beta) + beta * prev_1
        current_state[1] = val_1
        
        # m_wrk[r][2] = (m_wrk[r][0] + corr*m_wrk[r][1]);
        val_2 = val_0 + corr * val_1
        current_state[2] = val_2
        
        # m_wrk[r][3] = (m_wrk[r][2] - m_wrk[r-1][4])*MathPow((1-alpha),2) + MathPow(alpha,2)*m_wrk[r-1][3];
        prev_4 = get_hist(1, 4)
        prev_3 = get_hist(1, 3)
        val_3 = (val_2 - prev_4) * pow((1 - alpha), 2) + pow(alpha, 2) * prev_3
        current_state[3] = val_3
        
        # m_wrk[r][4] = (m_wrk[r-1][4] + m_wrk[r][3]);
        val_4 = prev_4 + val_3
        current_state[4] = val_4
        
        self.history.append(current_state)
        # Limit history size to prevent memory leaks if running forever, though for scripts it's fine.
        # We need at least 'forBar' (up to 10) back.
        
        return val_4

def iWma(index, period, series):
    """
    Weighted Moving Average
    """
    if index < period - 1:
        return 0.0
        
    sum_val = 0.0
    weight_total = 0.0
    norm = 0.0
    
    for i in range(period):
        if index - i < 0: continue
        weight = (period - i) * period # Note: This matches MQL5: (wmaPeriod-i)*wmaPeriod
        norm += weight
        sum_val += series[index - i] * weight
        
    if norm > 0:
        return sum_val / norm
    else:
        return 0.0

# ==========================================
# Main Processing
# ==========================================

def process_file(file_path):
    print(f"Processing {file_path}...")
    
    try:
        # Load Data
        # MQL5 FileWrite often uses delimiters based on locale or explicitly. 
        # The inspected file uses tabs. Check if it's tab or comma.
        try:
            df = pd.read_csv(file_path, sep='\t')
            if 'Time' not in df.columns:
                 # Try comma if tab failed to find columns
                 df = pd.read_csv(file_path, sep=',')
        except:
             df = pd.read_csv(file_path)

        # Validate columns
        required_cols = ['Time', 'Open', 'High', 'Low', 'Close']
        if not all(col in df.columns for col in required_cols):
            print("Error: Missing required columns (Time, Open, High, Low, Close)")
            # Try parsing with no header if it looks like that, but per MQL5 code we wrote headers
            return

        # Prepare arrays for result
        rates_total = len(df)
        SumBuyRatio = np.zeros(rates_total)
        SumSellRatio = np.zeros(rates_total)
        WmaBuyRatio = np.zeros(rates_total)
        WmaSellRatio = np.zeros(rates_total)
        DiffRatio = np.zeros(rates_total)
        SmoothDiffRatio = np.zeros(rates_total)
        
        # Initialize Custom Smoother
        smoother = SmoothFilter(inpSmoothPeriod, 0) # Phase 0
        
        last_SumBuy = 0.0
        last_SumSell = 0.0
        
        # Loop
        for bar in range(rates_total):
            # Get current and previous row
            row = df.iloc[bar]
            prev_row = df.iloc[bar-1] if bar > 0 else None
            
            # Normal Calculation
            # 1. Calc Buy/Sell Ratio
            tempBuyRatio = CalculateBuyRatio(row, prev_row)
            tempSellRatio = CalculateSellRatio(row, prev_row)
        
            # 2. Accumulate Sum
            SumBuyRatio[bar] = last_SumBuy + abs(tempBuyRatio)
            SumSellRatio[bar] = last_SumSell + abs(tempSellRatio)
            
            last_SumBuy = SumBuyRatio[bar]
            last_SumSell = SumSellRatio[bar]
            
            # 3. WMA
            WmaBuyRatio[bar] = iWma(bar, inpWmaPeriod, SumBuyRatio)
            WmaSellRatio[bar] = iWma(bar, inpWmaPeriod, SumSellRatio)
            
            # 4. Diff
            DiffRatio[bar] = WmaBuyRatio[bar] - WmaSellRatio[bar]
            
            # 5. Smooth
            SmoothDiffRatio[bar] = smoother.calculate(DiffRatio[bar], bar)
            
        # Add to DataFrame
        df['MySmoothDiffRatio'] = SmoothDiffRatio
        
        # Save Result
        output_file = file_path.replace(".csv", "_PythonResult.csv")
        df.to_csv(output_file, index=False)
        print(f"Success! Saved to {output_file}")
        
    except Exception as e:
        print(f"Error processing file: {e}")

# ==========================================
# Entry Point
# ==========================================
if __name__ == "__main__":
    # Example usage: Look for the most recent BSPWmaSmooth csv file
    files_dir = os.path.join(os.getenv("APPDATA"), "MetaQuotes", "Terminal", "5B326B03063D8D9C446E3637EFA32247", "MQL5", "Files")
    
    # In a real run, user might want to specify file. 
    # For now, we search for the standard pattern.
    target_file = None
    if os.path.exists(files_dir):
        files = [f for f in os.listdir(files_dir) if f.startswith("BSPWmaSmooth_") and f.endswith(".csv")]
        if files:
            # Pick the newest
            files.sort(key=lambda x: os.path.getmtime(os.path.join(files_dir, x)), reverse=True)
            target_file = os.path.join(files_dir, files[0])
            
    if target_file:
        process_file(target_file)
    else:
        print("No input CSV files found. Please run the MQL5 indicator to generate data first.")
        # Create dummy data for testing logic if no file exists
        print("Running in TEST mode with dummy data...")
        dates = pd.date_range(start="2024-01-01", periods=100, freq="1min")
        dummy_df = pd.DataFrame({
            'Time': dates,
            'Open': np.random.rand(100) + 100,
            'High': np.random.rand(100) + 101,
            'Low': np.random.rand(100) + 99,
            'Close': np.random.rand(100) + 100
        })
        dummy_path = os.path.join(files_dir, "BSPWmaSmooth_TEST_DUMMY.csv") if os.path.exists(files_dir) else "BSPWmaSmooth_TEST_DUMMY.csv"
        dummy_df.to_csv(dummy_path, index=False)
        process_file(dummy_path)
