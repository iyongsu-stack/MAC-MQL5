import pandas as pd
import numpy as np
import os
import sys
import json
import talib

# Configuration
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FILE = os.path.join(BASE_DIR, 'Data', 'xauusd_1min.csv')
CONFIG_FILE = os.path.join(BASE_DIR, 'Data', 'Strategy_Design_Result.json')

sys.path.append(os.path.join(BASE_DIR, 'Tools'))
from feature_engine import generate_features

def run_validation(df_raw, config):
    # 1. Feature Generation (Fixed Standard Periods as used in Design)
    print("Generating Features (Fixed Robust Periods)...")
    
    params_mapped = {
        'LRA_AvgPeriod': 60,
        'BOP_AvgPeriod': 50,
        'BOP_SmoothPeriod': 20,
        'ADX_Period': 14,
        'TDI_RSI_Period': 13,
        'TDI_VolBand_Period': 34,
        'TDI_RSI_Smooth': 2,
        'TDI_Sig_Smooth': 7,
        'QQE_SF': 5,
        'QQE_RSI_Period': 14,
        'CHV_SmoothPeriod': 10,
        'CHV_Period': 10,
        'ATR_Period': 14,
        'Chop_Period': 14
    }
    
    df, _ = generate_features(df_raw, params_mapped)
    
    # Add LRA Large
    c = df_raw['Close'].values
    lra_l = talib.LINEARREG_SLOPE(c, timeperiod=180)
    # Normalize LRA Large (using expanding window or simple z-score? Design used batch z-score)
    # We must match Design normalization.
    l_mean = np.nanmean(lra_l)
    l_std = np.nanstd(lra_l)
    if l_std == 0: l_std = 1
    df['LRA_BSPScale(180)'] = (lra_l - l_mean) / l_std
    df.rename(columns={'LRA_BSPScale': 'LRA_BSPScale(60)'}, inplace=True)
    
    # 2. Extract Config
    weights = config['Weights']
    struct = config['Strategy_Structure']
    threshold = weights['Threshold']
    filter_adx = weights['Filter_ADX']
    
    # 3. Calculate Weighted Sum
    # Zero out unused features (though weights might be 0 anyway)
    
    ws = 0.0
    if struct['LRA_S']: ws += df['LRA_BSPScale(60)'].values * weights['W_LRA_S']
    if struct['LRA_L']: ws += df['LRA_BSPScale(180)'].values * weights['W_LRA_L']
    if struct['BOP']: ws += df['BOP_Diff'].values * weights['W_BOP']
    if struct['QQE']: ws += df['QQE_TrLevel'].values * weights['W_QQE']
    if struct['TDI']: ws += df['TDI_TrSi'].values * weights['W_TDI']
    if struct['CHV']: ws += df['CHV_CVScale'].values * weights['W_CHV']
    if struct['CSI']: ws += df['CSI_Scale'].values * weights['W_CSI']
    
    # 4. Signals
    # Logic: Weighted Sum > Threshold AND ADX > Filter
    adx_arr = df['ADX_Val'].values
    signals = (ws > threshold) & (adx_arr > filter_adx)
    
    # 5. Simulate Trades (Fixed 200 pts)
    print("Simulating Trades on 2025 Data...")
    
    closes = df['Close'].values
    opens = df['Open'].values
    highs = df['High'].values
    lows = df['Low'].values
    times = df['Time'].values
    
    trade_log = []
    outcomes = []
    
    indices = np.where(signals)[0]
    skip_until = 0
    
    for idx in indices:
        if idx < skip_until: continue
        if idx >= len(closes) - 60: continue
        
        entry = opens[idx+1]
        tp = entry + 2.0
        sl = entry - 2.0
        
        outcome = 0
        end_idx = idx
        
        for i in range(idx+1, min(idx+61, len(closes))):
            h = highs[i]
            l = lows[i]
            end_idx = i
            
            if l <= sl:
                outcome = -1
                break
            if h >= tp:
                outcome = 1
                break
        
        if outcome == 0:
            c = closes[end_idx]
            outcome = 1 if c > entry else -1
            
        trade_log.append({
            'Time': times[idx+1],
            'Outcome': outcome
        })
        outcomes.append(outcome)
        skip_until = end_idx + 1
        
    # Metrics
    if not trade_log:
        print("No trades triggered.")
        return

    wins = outcomes.count(1)
    losses = outcomes.count(-1)
    total = len(outcomes)
    wr = (wins / total * 100) if total > 0 else 0
    pf = wins / losses if losses > 0 else 99.9
    
    print(f"\n--- AI Strategy Validation Results (2025) ---")
    print(f"Total Trades: {total}")
    print(f"Win Rate: {wr:.2f}%")
    print(f"Profit Factor: {pf:.2f}")
    
    # Monthly Breakdown
    df_log = pd.DataFrame(trade_log)
    df_log['Time'] = pd.to_datetime(df_log['Time'])
    df_log['Month'] = df_log['Time'].dt.to_period('M')
    
    print(f"\nMonth      | Trades   | Win Rate   | Profit Factor")
    print("-" * 55)
    
    for name, group in df_log.groupby('Month'):
        m_wins = (group['Outcome'] == 1).sum()
        m_losses = (group['Outcome'] == -1).sum()
        m_total = len(group)
        m_wr = (m_wins / m_total * 100) if m_total > 0 else 0
        m_pf = m_wins / m_losses if m_losses > 0 else 99.9
        print(f"{str(name):<10} | {m_total:<8} | {m_wr:>6.2f}%   | {m_pf:>6.2f}")

def main():
    print(f"Loading {DATA_FILE}...")
    df = pd.read_csv(DATA_FILE)
    df['Time'] = pd.to_datetime(df['Time'])
    
    print(f"Loading Config {CONFIG_FILE}...")
    with open(CONFIG_FILE, 'r') as f:
        config = json.load(f)
        
    run_validation(df, config)

if __name__ == "__main__":
    main()
