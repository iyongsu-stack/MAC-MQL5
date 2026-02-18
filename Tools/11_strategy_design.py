import pandas as pd
import numpy as np
import optuna
import os
import sys
import json

# Configuration
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRAIN_FILE = os.path.join(BASE_DIR, 'Files', 'TotalResult_Labeled.csv')
TEST_FILE = os.path.join(BASE_DIR, 'Data', 'xauusd_1min.csv')

sys.path.append(os.path.join(BASE_DIR, 'Tools'))
from feature_engine import generate_features

def calculate_metrics_vectorized(signals, opens, highs, lows, closes):
    """
    Fastest vectorized backtest for optimization loop.
    Assumes Fixed 200pt TP/SL.
    """
    if np.sum(signals) == 0:
        return 0, 0, 0
        
    signal_indices = np.where(signals)[0]
    
    # Filter indices near end
    input_len = len(closes)
    valid_indices = signal_indices[signal_indices < input_len - 60]
    
    if len(valid_indices) == 0:
        return 0, 0, 0
        
    entries = opens[valid_indices + 1]
    tps = entries + 2.0
    sls = entries - 2.0
    
    outcomes = np.zeros(len(valid_indices))
    
    # This loop is still needed but optimized
    for i, idx in enumerate(valid_indices):
        # Slice next 60 candles
        window_h = highs[idx+1 : idx+61]
        window_l = lows[idx+1 : idx+61]
        
        # Check hit
        hit_tp = np.where(window_h >= tps[i])[0]
        hit_sl = np.where(window_l <= sls[i])[0]
        
        first_tp = hit_tp[0] if len(hit_tp) > 0 else 999
        first_sl = hit_sl[0] if len(hit_sl) > 0 else 999
        
        if first_tp < first_sl:
            outcomes[i] = 1
        elif first_sl < first_tp:
            outcomes[i] = -1
        else:
            # Time exit
            outcomes[i] = 1 if closes[min(idx+60, input_len-1)] > entries[i] else -1
            
    wins = np.sum(outcomes == 1)
    losses = np.sum(outcomes == -1)
    
    pf = wins / losses if losses > 0 else 99.9
    wr = (wins / len(outcomes)) * 100 if len(outcomes) > 0 else 0
    
    return wr, pf, len(outcomes)

def objective(trial):
    # --- 1. PARAMETERS (Structure Search) ---
    
    # Feature Selection Flags (Boolean)
    use_lra_s = trial.suggest_categorical('Use_LRA_S', [True, False])
    use_lra_l = trial.suggest_categorical('Use_LRA_L', [True, False])
    use_bop = trial.suggest_categorical('Use_BOP', [True, False])
    use_qqe = trial.suggest_categorical('Use_QQE', [True, False])
    use_tdi = trial.suggest_categorical('Use_TDI', [True, False])
    use_chv = trial.suggest_categorical('Use_CHV', [True, False])
    use_csi = trial.suggest_categorical('Use_CSI', [True, False])
    
    # If no features selected, penalize
    if not any([use_lra_s, use_lra_l, use_bop, use_qqe, use_tdi, use_chv, use_csi]):
        return -100
        
    # Logic Parameters (Regime & Threshold)
    threshold = trial.suggest_float('Threshold', 0.0, 10.0)
    filter_adx = trial.suggest_float('Filter_ADX', 15.0, 40.0)
    
    # Weights (Optimized only if used)
    w_lra_s = trial.suggest_float('W_LRA_S', -3.0, 3.0) if use_lra_s else 0.0
    w_lra_l = trial.suggest_float('W_LRA_L', -3.0, 3.0) if use_lra_l else 0.0
    w_bop = trial.suggest_float('W_BOP', -3.0, 3.0) if use_bop else 0.0
    w_qqe = trial.suggest_float('W_QQE', -3.0, 3.0) if use_qqe else 0.0
    w_tdi = trial.suggest_float('W_TDI', -3.0, 3.0) if use_tdi else 0.0
    w_chv = trial.suggest_float('W_CHV', -3.0, 3.0) if use_chv else 0.0
    w_csi = trial.suggest_float('W_CSI', -3.0, 3.0) if use_csi else 0.0
    
    # --- 2. CALCULATE (Numpy) ---
    # Use global FEATURE_DICT (Dictionary of Numpy Arrays)
    
    w_sum = (
        FEATURE_DICT['LRA_S'] * w_lra_s +
        FEATURE_DICT['LRA_L'] * w_lra_l +
        FEATURE_DICT['BOP'] * w_bop +
        FEATURE_DICT['QQE'] * w_qqe +
        FEATURE_DICT['TDI'] * w_tdi +
        FEATURE_DICT['CHV'] * w_chv +
        FEATURE_DICT['CSI'] * w_csi
    )
    
    signals = (w_sum > threshold) & (FEATURE_DICT['ADX'] > filter_adx)
    
    # --- 3. CROSS VALIDATION ---
    split_idx = int(len(signals) * 0.7)
    
    # Data vectors (Already Numpy)
    opens = FEATURE_DICT['Open']
    highs = FEATURE_DICT['High']
    lows = FEATURE_DICT['Low']
    closes = FEATURE_DICT['Close']
    
    # Train Set
    wr_tr, pf_tr, tx_tr = calculate_metrics_vectorized(
        signals[:split_idx], 
        opens[:split_idx], highs[:split_idx], lows[:split_idx], closes[:split_idx]
    )
    
    # Test Set
    wr_te, pf_te, tx_te = calculate_metrics_vectorized(
        signals[split_idx:], 
        opens[split_idx:], highs[split_idx:], lows[split_idx:], closes[split_idx:]
    )
    
    # Robustness Constraints
    if tx_tr < 20 or tx_te < 10: return -100
    if pf_tr < 1.0 or pf_te < 1.0: return -50
    
    # Score: Maximize Min Win Rate
    score = min(wr_tr, wr_te) + (min(pf_tr, pf_te) * 5)
    
    # Store metrics
    trial.set_user_attr("WR_Train", wr_tr)
    trial.set_user_attr("PF_Train", pf_tr)
    trial.set_user_attr("Trades_Train", tx_tr)
    trial.set_user_attr("WR_Test", wr_te)
    trial.set_user_attr("PF_Test", pf_te)
    trial.set_user_attr("Trades_Test", tx_te)
    
    trial.set_user_attr("Struct", {
        "LRA_S": use_lra_s, "LRA_L": use_lra_l, "BOP": use_bop, 
        "QQE": use_qqe, "TDI": use_tdi, "CHV": use_chv, "CSI": use_csi
    })
    
    return score

FEATURE_DICT = {}

def main():
    global FEATURE_DICT
    
    print(f"Loading Training Data: {TRAIN_FILE}")
    df_raw = pd.read_csv(TRAIN_FILE)
    df_raw['Time'] = pd.to_datetime(df_raw['Time'])
    
    # Dedup and Sort
    df_raw = df_raw.sort_values('Time').drop_duplicates(subset=['Time']).reset_index(drop=True)
    
    # Pre-calculate Features with FIXED robust periods
    print("Pre-calculating features with Fixed Standard Periods...")
    
    params_mapped = {
        'LRA_AvgPeriod': 60, # Small LRA
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
    
    # The feature engine produces 'LRA_BSPScale'.
    # But we want TWO LRAs (Small and Large).
    # We must manually add the second LRA feature here since engine only does one.
    import talib
    c = df_raw['Close'].values
    lra_l = talib.LINEARREG_SLOPE(c, timeperiod=180)
    # Normalize LRA Large
    l_mean = np.nanmean(lra_l)
    l_std = np.nanstd(lra_l)
    df['LRA_BSPScale(180)'] = (lra_l - l_mean) / l_std
    
    # Store as Numpy Arrays in Global Dict for speed and safety
    print("Converting to Numpy Arrays...")
    FEATURE_DICT = {
        'LRA_S': df['LRA_BSPScale'].values, # Default from engine is LRA(60)
        'LRA_L': df['LRA_BSPScale(180)'].values,
        'BOP': df['BOP_Diff'].values,
        'QQE': df['QQE_TrLevel'].values,
        'TDI': df['TDI_TrSi'].values,
        'CHV': df['CHV_CVScale'].values,
        'CSI': df['CSI_Scale'].values,
        'ADX': df['ADX_Val'].values,
        'Open': df['Open'].values,
        'High': df['High'].values,
        'Low': df['Low'].values,
        'Close': df['Close'].values
    }
    
    # Clean NaNs in arrays
    for k, v in FEATURE_DICT.items():
        FEATURE_DICT[k] = np.nan_to_num(v)
    
    print("Starting Structural Strategy Search... n_trials=300")
    study = optuna.create_study(direction='maximize', study_name="Strategy_Design_2026")
    study.optimize(objective, n_trials=300)
    
    best = study.best_trial
    print(f"\n--- Best Strategy Structure ---")
    print(f"Value: {best.value}")
    print(f"Selected Config: {best.user_attrs['Struct']}")
    print(f"Params: {best.params}")
    print(f"Metrics: WR_Test={best.user_attrs['WR_Test']:.2f}%, PF_Test={best.user_attrs['PF_Test']:.2f}")
    
    config = {
        "Strategy_Structure": best.user_attrs['Struct'],
        "Weights": best.params,
        "Metrics": best.user_attrs
    }
    with open(os.path.join(BASE_DIR, 'Data', 'Strategy_Design_Result.json'), 'w') as f:
        json.dump(config, f, indent=4)

if __name__ == "__main__":
    main()
