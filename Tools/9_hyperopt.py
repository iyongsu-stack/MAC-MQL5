import pandas as pd
import numpy as np
import optuna
import os
import sys
import json

# ==========================================
# USER CONFIGURATION (SEARCH SPACE)
# ==========================================
# 1. Weights Range
W_MIN = -3.0
W_MAX = 3.0

# 2. Indicator Periods (Min, Max, Step)
RANGE_LRA = (30, 300, 10)
RANGE_BOP_AVG = (20, 200, 10)
RANGE_BOP_SMOOTH = (20, 200, 10)
RANGE_ADX = (10, 50, 2)
RANGE_TDI_RSI = (10, 30, 2)
RANGE_CHV_SMOOTH = (10, 150, 10)
RANGE_CHV_PERIOD = (10, 150, 10)

# 3. Filters
RANGE_ADX_FILTER = (20.0, 50.0)
RANGE_THRESHOLD = (0.0, 15.0)

# 4. Optimization Settings
N_TRIALS = 100  # Number of experiments
MIN_TRADES = 30 # Minimum trades per set to be considered valid
# ==========================================

# System Config
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRAIN_FILE = os.path.join(BASE_DIR, 'Files', 'TotalResult_Labeled.csv')
OUTPUT_FILE = os.path.join(BASE_DIR, 'Data', 'HyperOpt_Result.json')

sys.path.append(os.path.join(BASE_DIR, 'Tools'))
from feature_engine import generate_features

def calculate_metrics(df, signals):
    if np.sum(signals) == 0: return 0, 0, 0
    
    # Vectorized Approx
    closes = df['Close'].values
    opens = df['Open'].values
    highs = df['High'].values
    lows = df['Low'].values
    
    signal_indices = np.where(signals)[0]
    valid_indices = signal_indices[signal_indices < len(closes) - 60]
    
    if len(valid_indices) == 0: return 0, 0, 0
    
    entries = opens[valid_indices + 1]
    tps = entries + 2.0
    sls = entries - 2.0
    
    outcomes = np.zeros(len(valid_indices))
    
    for i, idx in enumerate(valid_indices):
        wh = highs[idx+1 : idx+61]
        wl = lows[idx+1 : idx+61]
        
        hit_tp = np.where(wh >= tps[i])[0]
        hit_sl = np.where(wl <= sls[i])[0]
        
        ftp = hit_tp[0] if len(hit_tp) > 0 else 999
        fsl = hit_sl[0] if len(hit_sl) > 0 else 999
        
        if ftp < fsl: outcomes[i] = 1
        elif fsl < ftp: outcomes[i] = -1
        else: outcomes[i] = 1 if closes[min(idx+60, len(closes)-1)] > entries[i] else -1
            
    wins = np.sum(outcomes == 1)
    losses = np.sum(outcomes == -1)
    
    pf = wins / losses if losses > 0 else 99.9
    wr = (wins / len(outcomes)) * 100 if len(outcomes) > 0 else 0
    
    return wr, pf, len(outcomes)

def objective(trial):
    # Suggest Params based on CONFIG
    lra_avg = trial.suggest_int('LRA_AvgPeriod', *RANGE_LRA)
    bop_avg = trial.suggest_int('BOP_AvgPeriod', *RANGE_BOP_AVG)
    bop_smooth = trial.suggest_int('BOP_SmoothPeriod', *RANGE_BOP_SMOOTH)
    adx_p = trial.suggest_int('ADX_Period', *RANGE_ADX)
    tdi_rsi = trial.suggest_int('TDI_RSI_Period', *RANGE_TDI_RSI)
    
    chv_sm = trial.suggest_int('CHV_SmoothPeriod', *RANGE_CHV_SMOOTH)
    chv_p = trial.suggest_int('CHV_Period', *RANGE_CHV_PERIOD)
    
    # We allow LRA Large to be a multiplier or separate range? 
    # For now keeping it fixed relative to Small or Standard to reduce noise
    # Or optimize it? Let's genericize.
    
    params = {
        'LRA_Small_Period': lra_avg,
        'LRA_Large_Period': lra_avg * 3, # Common heuristic: 3x
        'BOP_AvgPeriod': bop_avg,
        'BOP_SmoothPeriod': bop_smooth,
        'ADX_Period': adx_p,
        'TDI_RSI_Period': tdi_rsi,
        'CHV_SmoothPeriod': chv_sm,
        'CHV_Period': chv_p,
        # Default others
        'ATR_Period': 14,
        'QQE_RSI_Period': 14
    }
    
    # Weights
    w_lra_s = trial.suggest_float('W_LRA_S', W_MIN, W_MAX)
    w_lra_l = trial.suggest_float('W_LRA_L', W_MIN, W_MAX)
    w_bop = trial.suggest_float('W_BOP', W_MIN, W_MAX)
    w_qqe = trial.suggest_float('W_QQE', W_MIN, W_MAX)
    w_tdi = trial.suggest_float('W_TDI', W_MIN, W_MAX)
    w_chv = trial.suggest_float('W_CHV', W_MIN, W_MAX)
    w_csi = trial.suggest_float('W_CSI', W_MIN, W_MAX)
    
    filter_adx = trial.suggest_float('Filter_ADX', *RANGE_ADX_FILTER)
    threshold = trial.suggest_float('Threshold_Score', *RANGE_THRESHOLD)
    
    # Generate Logic
    df_featured, _ = generate_features(DF_TRAIN, params)
    
    w_sum = (
        df_featured['LRA_BSPScale'] * w_lra_s +
        df_featured['LRA_BSPScale(180)'] * w_lra_l +
        df_featured['BOP_Diff'] * w_bop +
        df_featured['QQE_TrLevel'] * w_qqe +
        df_featured['TDI_TrSi'] * w_tdi +
        df_featured['CHV_CVScale'] * w_chv +
        df_featured['CSI_Scale'] * w_csi
    )
    
    signals = (w_sum > threshold) & (df_featured['ADX_Val'] > filter_adx)
    
    # CROSS VALIDATION (70/30 Split)
    split = int(len(signals) * 0.7)
    
    wr_tr, pf_tr, tx_tr = calculate_metrics(df_featured.iloc[:split], signals[:split])
    wr_te, pf_te, tx_te = calculate_metrics(df_featured.iloc[split:], signals[split:])
    
    # Constraints
    if tx_tr < (MIN_TRADES * 0.7) or tx_te < (MIN_TRADES * 0.3): return -100
    if pf_tr < 1.0 or pf_te < 1.0: return -50
    
    # Score: Maximize Robustness (Min WinRate)
    score = min(wr_tr, wr_te) + (min(pf_tr, pf_te) * 5)
    
    # Store Attributes
    trial.set_user_attr("WR_Test", wr_te)
    trial.set_user_attr("PF_Test", pf_te)
    trial.set_user_attr("Trades_Test", tx_te)
    
    return score

GLOBAL_DF_TRAIN = None

def main():
    global DF_TRAIN
    print(f"Loading Data: {TRAIN_FILE}")
    df = pd.read_csv(TRAIN_FILE)
    df['Time'] = pd.to_datetime(df['Time'])
    df = df.sort_values('Time').drop_duplicates(subset=['Time']).reset_index(drop=True)
    DF_TRAIN = df
    
    print(f"Starting HyperOpt... Trials={N_TRIALS}")
    study = optuna.create_study(direction='maximize', study_name="Master_HyperOpt")
    study.optimize(objective, n_trials=N_TRIALS)
    
    best = study.best_trial
    print("\n--- Best Result ---")
    print(f"Params: {best.params}")
    print(f"Test Metrics: WR={best.user_attrs.get('WR_Test')}, PF={best.user_attrs.get('PF_Test')}")
    
    # Save Result
    config = {
        "Best_Params": best.params,
        "Metrics": best.user_attrs
    }
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(config, f, indent=4)
    print(f"Saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
