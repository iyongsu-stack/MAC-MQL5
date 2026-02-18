import optuna
import pandas as pd
import numpy as np
import os
import json
import time
from datetime import datetime

# --- Configuration ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_PATH = os.path.join(BASE_DIR, 'Files', 'TotalResult_Labeled.csv')
RESULT_DIR = os.path.join(BASE_DIR, 'Docs')
BEST_PARAMS_FILE = os.path.join(RESULT_DIR, 'Optimization_Result.json')

# --- 1. Data Prep (In-Memory) ---
def load_data():
    """Load raw data once to speed up optimization."""
    print(f"Loading data from {DATA_PATH}...")
    df = pd.read_csv(DATA_PATH)
    df.columns = df.columns.str.strip()
    df['Time'] = pd.to_datetime(df['Time'])
    # Cache required columns to numpy arrays for speed if needed
    return df

# --- 2. Feature Engineering ---
def normalize_features(df, feature_cols):
    """
    Apply Standard Scaling (Z-Score) to features.
    Returns df with scaled columns and the scaler stats.
    """
    scaler_stats = {}
    df_scaled = df.copy()
    
    for col in feature_cols:
        if col in df.columns:
            mean = df[col].mean()
            std = df[col].std()
            if std == 0: std = 1
            
            df_scaled[col] = (df[col] - mean) / std
            scaler_stats[col] = {'mean': mean, 'std': std}
            
    return df_scaled, scaler_stats

# --- 3. Metrics & Simulation Logic ---
def calculate_metrics(df, params, scaler_stats=None):
    """
    Calculate detailed performance metrics.
    df must be the SCALED dataframe.
    """
    # Feature Config (Name, Weight)
    features = [
        ('LRA_BSPScale(60)', params.get('W_LRA60', 0)),
        ('LRA_BSPScale(180)', params.get('W_LRA180', 0)),
        ('BOP_Diff', params.get('W_BOP', 0)),
        ('QQE_TrLevel', params.get('W_QQE', 0)),
        ('TDI_TrSi', params.get('W_TDI', 0)),
        ('CHV_CVScale', params.get('W_CHV', 0)),
        ('CSI_Scale', params.get('W_CSI', 0))
    ]
    
    # Calculate Weighted Sum (Vectorized)
    weighted_sum = np.zeros(len(df))
    for col, weight in features:
        if col in df.columns:
            weighted_sum += df[col] * weight
            
    # Filters (Use raw values for ADX filter? No, ADX is usually absolute. 
    # BUT df is scaled now. 
    # PROBLEM: ADX filter 'Filter_ADX' (range 10-40) expects RAW ADX.
    # SOLVED: Pass RAW df for filters, SCALED df for weights?
    # Better: Keep df as RAW, scale inside? No, slow.
    # Solution: Add unscaled ADX column to df_scaled with a different name or keep explicit.
    # Let's assume df_scaled has both scaled features and raw 'ADX_Val' (if we didn't scale ADX).
    # We only scale the voting features.
    
    # ADX Filter (Applied on RAW ADX_Val, assuming it wasn't overwritten or we kept it)
    # Actually, normalize_features creates a copy. 
    # Let's ensure ADX_Val is available. it's in df_scaled (copy of df). 
    # If we didn't scale ADX_Val, it's raw.
    
    filter_adx_thresh = params.get('Filter_ADX', 20.0)
    # Check if ADX_Val was scaled. The list below defines what to scale.
    # We will only scale the voting features.
    adx_filter = df['ADX_Val'] > filter_adx_thresh
    
    # Combined Signal
    thresh_score = params.get('Threshold_Score', 1.0)
    condition = (weighted_sum > thresh_score) & adx_filter
    signals = np.where(condition, 1, 0)

    # --- Metrics Logic ---
    total_trades = np.sum(signals)
    if total_trades < 10: # Minimum sample size constraint
        return {
            "Total_Trades": 0, "Win_Rate": 0.0, "Profit_Factor": 0.0, 
            "MDD": 0.0, "SQN": 0.0, "Estimated_Net_Score": 0
        }

    matches = signals * df['Label_Open_Buy']
    wins = np.sum(matches)
    losses = total_trades - wins
    win_rate = (wins / total_trades) * 100
    
    # Profit Simulation
    pnl_stream = np.where(signals == 1, np.where(df['Label_Open_Buy'] == 1, 1.0, -1.0), 0.0)
    trades = pnl_stream[pnl_stream != 0]
    
    gross_profit = np.sum(trades[trades > 0])
    gross_loss = np.abs(np.sum(trades[trades < 0]))
    profit_factor = gross_profit / gross_loss if gross_loss != 0 else 99.99
    
    avg_pnl = np.mean(trades)
    std_pnl = np.std(trades)
    sqn = (avg_pnl / std_pnl) * np.sqrt(len(trades)) if std_pnl != 0 else 0.0
    
    equity_curve = np.cumsum(trades)
    peak = np.maximum.accumulate(equity_curve)
    drawdown = peak - equity_curve
    max_drawdown = np.max(drawdown) if len(drawdown) > 0 else 0.0
    
    estimated_net_score = wins - losses

    return {
        "Total_Trades": int(total_trades),
        "Win_Rate": round(win_rate, 2),
        "Profit_Factor": round(profit_factor, 2),
        "MDD": round(max_drawdown, 2),
        "SQN": round(sqn, 2),
        "Estimated_Net_Score": int(estimated_net_score)
    }

# --- 3. Optimizer (Optuna) ---
def objective(trial, df):
    # Define Advanced Search Space
    params = {
        # Weights (-2.0 to 2.0 to allow negative correlation)
        'W_LRA60': trial.suggest_float('W_LRA60', -2.0, 2.0),
        'W_LRA180': trial.suggest_float('W_LRA180', -2.0, 2.0),
        'W_BOP': trial.suggest_float('W_BOP', -2.0, 2.0),
        'W_QQE': trial.suggest_float('W_QQE', -2.0, 2.0),
        'W_TDI': trial.suggest_float('W_TDI', -2.0, 2.0),
        'W_CHV': trial.suggest_float('W_CHV', -2.0, 2.0),
        'W_CSI': trial.suggest_float('W_CSI', -2.0, 2.0),
        
        # Filters
        'Filter_ADX': trial.suggest_float('Filter_ADX', 10.0, 40.0), # Trade only strong trends?
        'Threshold_Score': trial.suggest_float('Threshold_Score', 0.5, 10.0),
    }
    
    # Run Simulation
    metrics = calculate_metrics(df, params)
    
    # Optimization Goal: Win Rate > 70% AND Maximize Profit
    win_rate = metrics['Win_Rate']
    pf = metrics['Profit_Factor']
    trades = metrics['Total_Trades']
    
    # Strict Constraint
    if win_rate < 70.0:
        # Penalty Score (Higher winstate is better even if < 70)
        return win_rate - 100 # Range -100 to -30
        
    # Bonus for Trades Count (Don't want 100% win rate on 1 trade)
    # Log trade count scaling
    trade_score = np.log1p(trades) 
    
    # Return Weighted Utility
    # Main driver: Profit Factor + Win Rate
    # Since WR > 70 here, base score starts high
    return win_rate + (pf * 10) + trade_score

def main():
    print("Initializing Autonomous Optimizer...")
    
    # 1. Load Data
    df = load_data()
    print(f"Data Loaded: {len(df)} rows")
    
    # 1b. Normalize Features
    feature_cols = [
        'LRA_BSPScale(60)', 'LRA_BSPScale(180)', 'BOP_Diff', 
        'QQE_TrLevel', 'TDI_TrSi', 'CHV_CVScale', 'CSI_Scale'
    ]
    df_scaled, scaler_stats = normalize_features(df, feature_cols)
    print("Features Normalized.")
    
    # 2. Setup Study
    storage_name = "sqlite:///{}/optimization.db".format(RESULT_DIR.replace('\\', '/'))
    study = optuna.create_study(
        study_name="MQL5_Strategy_Opt_Advanced_Scaled", # New study name
        direction="maximize",
        storage=storage_name,
        load_if_exists=True
    )
    
    print("Starting Optimization Loop. Press Ctrl+C to stop.")
    try:
        # Optimization Loop (More trials for complex logic)
        study.optimize(lambda trial: objective(trial, df_scaled), n_trials=500) 
    except KeyboardInterrupt:
        print("\nOptimization paused by user.")
    
    # 3. Save Results with Metrics
    print(f"Best Value: {study.best_value}")
    print(f"Best Params: {study.best_params}")
    
    # Calculate detailed metrics for the best params
    # Calculate detailed metrics for the best params
    metrics = calculate_metrics(df_scaled, study.best_params)
    
    final_result = {
        "Best_Params": study.best_params,
        "Best_Score": study.best_value,
        "Scaler_Stats": scaler_stats,
        "Simulation_Metrics": metrics
    }
    
    with open(BEST_PARAMS_FILE, 'w') as f:
        json.dump(final_result, f, indent=4)
    print(f"Saved detailed results to {BEST_PARAMS_FILE}")

if __name__ == "__main__":
    main()
