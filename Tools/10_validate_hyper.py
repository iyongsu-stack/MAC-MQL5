import pandas as pd
import numpy as np
import os
import sys
import json

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FILE = os.path.join(BASE_DIR, 'Data', 'xauusd_1min.csv')
CONFIG_FILE = os.path.join(BASE_DIR, 'Data', 'HyperOpt_Result.json')

sys.path.append(os.path.join(BASE_DIR, 'Tools'))
from feature_engine import generate_features

def run_validation(df_raw, config):
    params = config['Best_Params']
    
    # Heuristic for LRA Large if missing (consistency with HyperOpt)
    if 'LRA_Large_Period' not in params and 'LRA_AvgPeriod' in params:
        params['LRA_Large_Period'] = params['LRA_AvgPeriod'] * 3
    
    print(f"Generating features...")
    df, _ = generate_features(df_raw, params)
    
    # Weighted Sum
    # Ensure keys match (feature_engine produces these names)
    w_sum = (
        df['LRA_BSPScale'] * params.get('W_LRA_S', 0) +
        df['LRA_BSPScale(180)'] * params.get('W_LRA_L', 0) +
        df['BOP_Diff'] * params.get('W_BOP', 0) +
        df['QQE_TrLevel'] * params.get('W_QQE', 0) +
        df['TDI_TrSi'] * params.get('W_TDI', 0) +
        df['CHV_CVScale'] * params.get('W_CHV', 0) +
        df['CSI_Scale'] * params.get('W_CSI', 0)
    )
    
    threshold = params.get('Threshold_Score', 0)
    filter_adx = params.get('Filter_ADX', 20)
    
    signals = (w_sum > threshold) & (df['ADX_Val'] > filter_adx)
    
    print("Simulating trades on 2025 data...")
    # Vectorized / Loop Simulation
    closes = df['Close'].values
    opens = df['Open'].values
    highs = df['High'].values
    lows = df['Low'].values
    times = df['Time'].values
    
    indices = np.where(signals)[0]
    outcomes = []
    trade_log = []
    
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
            
        outcomes.append(outcome)
        trade_log.append({'Time': times[idx+1], 'Outcome': outcome})
        skip_until = end_idx + 1
        
    if not outcomes:
        print("No trades triggered.")
        return
        
    wins = outcomes.count(1)
    losses = outcomes.count(-1)
    if losses == 0: losses = 0.0001
    pf = wins / losses
    wr = wins / len(outcomes) * 100
    
    print(f"\n--- Validation Result (Standardized) ---")
    print(f"Total Trades: {len(outcomes)}")
    print(f"Win Rate: {wr:.2f}%")
    print(f"Profit Factor: {pf:.2f}")

def main():
    print(f"Loading Data: {DATA_FILE}")
    df = pd.read_csv(DATA_FILE)
    df['Time'] = pd.to_datetime(df['Time'])
    
    print(f"Loading Config: {CONFIG_FILE}")
    with open(CONFIG_FILE, 'r') as f:
        config = json.load(f)
        
    run_validation(df, config)

if __name__ == "__main__":
    main()
