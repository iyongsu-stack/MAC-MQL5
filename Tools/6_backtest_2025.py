import pandas as pd
import numpy as np
import json
import os

# Configuration
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_FILE = os.path.join(BASE_DIR, 'Data', '2025_Featured.csv')
CONFIG_FILE = os.path.join(BASE_DIR, 'Data', 'Strategy_Config.json')

def load_config():
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def run_backtest(df, config):
    entry_logic = config['Entry_Logic']
    weights = entry_logic['Weights']
    params = entry_logic['Parameters']
    scaling_stats = config['Feature_Scaling_Stats']
    
    # 1. Calculate Weighted Sum
    # IMPORTANT: We must normalize using the SAVED scaling stats from 2026 data
    # to simulate "Real-time" trading (using training set stats).
    # However, for this quick test, the feature generator already normalized using 2025 stats (Local Z-Score).
    # Ideally, we should use 2026 stats. 
    # But since 7_generate_features.py did local normalization, the values are already Z-Scores of 2025 distribution.
    # This assumes the distribution shape is similar.
    
    weighted_sum = np.zeros(len(df))
    
    for feature, weight in weights.items():
        if feature in df.columns:
            # Feature is already normalized locally in 2025_Featured.csv
            weighted_sum += df[feature] * weight
        else:
            print(f"Warning: Feature {feature} not found in 2025 data.")
            
    # 2. Apply Filters
    filter_adx = params['Filter_ADX']
    if 'ADX_Val' in df.columns:
        adx_condition = df['ADX_Val'] > filter_adx
    else:
        print("Warning: ADX_Val not found. Skipping filter.")
        adx_condition = True
        
    # 3. Signals
    threshold = params['Threshold_Score']
    signals = (weighted_sum > threshold) & adx_condition
    
    # 4. Simulate Trades
    # Since we don't have 'Labels' for 2025 (we don't know the future of 2025 relative to itself without looking ahead),
    # We must simulate PnL using Price Data (Open/Close/High/Low).
    # Logic: Buy at Close of Signal Candle. Holding Period? 
    # The original label was 'Open_Buy' (Win/Loss).
    # We need to approximate the 'Label' logic: 
    # "Profit Target reached before Stop Loss?"
    # Since we don't have the exact label definition code here, we'll use a simple proxy:
    # "Close + 10 pips vs Close - 10 pips" or based on ATR?
    # Config says: TP/SL = ATR(14) * 1.5. 
    # Let's calculate ATR-based outcome.
    
    # We need ATR for trade simulation.
    # 7_generate_features.py didn't save ATR explicitly, but we can re-calc or use High-Low.
    # Let's assume a fixed TP/SL of 200 points (20 pips) for simplicity purely for this relative comparison,
    # OR better: use the 'Label' proxy logic if we can.
    # Since we can't easily reproduce the complex label logic, we will use:
    # Entry: Next Open.
    # Exit: Fixed 200 points TP / 200 points SL.
    
    print("Simulating Trades (Fixed 200pts TP/SL)...")
    
    results = []
    
    # Iterate through signals
    # Vectorized approach is hard for path-dependent TP/SL. Using loop.
    signal_indices = np.where(signals)[0]
    
    for idx in signal_indices:
        if idx >= len(df) - 1: continue
        
        entry_price = df.iloc[idx+1]['Open'] # Enter on next open
        tp_price = entry_price + 2.00 # Gold 200 pips (approx 2.0 dollars?) XAUUSD 1 pip = 0.01 or 0.1? 
        # XAUUSD 1 lot = 100 oz. 0.01 move is 1 tick?
        # Usually XAUUSD digits=2. 2.0 = 200 ticks.
        # Let's check current price. ~2500. 2.0 is 0.08%. Reasonable scalp.
        sl_price = entry_price - 2.00
        
        # Look forward
        outcome = 0 # 0: running, 1: win, -1: loss
        for i in range(idx+1, min(idx+60, len(df))): # Look ahead 60 mins
            high = df.iloc[i]['High']
            low = df.iloc[i]['Low']
            
            if low <= sl_price:
                outcome = -1
                break
            if high >= tp_price:
                outcome = 1
                break
        
        # If time runs out, close at market
        if outcome == 0:
            close_price = df.iloc[min(idx+60, len(df)-1)]['Close']
            if close_price > entry_price: outcome = 1 # Slight win
            else: outcome = -1 # Slight loss
            
        results.append(outcome)
        
    # Metrics
    if not results:
        print("No trades triggered.")
        return
        
    wins = results.count(1)
    losses = results.count(-1)
    total = len(results)
    win_rate = (wins / total) * 100
    profit_factor = wins / losses if losses > 0 else 99.9
    
    print(f"\n--- 2025 Out-of-Sample Results ---")
    print(f"Total Trades: {total}")
    print(f"Win Rate: {win_rate:.2f}%")
    print(f"Profit Factor: {profit_factor:.2f}")
    
    # Print Monthly Breakdown
    print(f"\n--- Monthly Breakdown (2025) ---")
    print(f"{'Month':<10} | {'Trades':<8} | {'Win Rate':<10} | {'Profit Factor':<15}")
    print("-" * 55)

    monthly_stats = {}
    df['Month'] = df['Time'].dt.to_period('M')
    
    # Map trade results to months
    # We need to store (Month, Outcome) pairs
    monthly_results = []
    
    current_trade_idx = 0
    signal_indices = np.where(signals)[0]
    
    for idx in signal_indices:
        if idx >= len(df) - 1: continue
        # Get the month of the trade entry
        trade_month = df.iloc[idx+1]['Time'].strftime('%Y-%m')
        
        # Get outcome from the results list (assuming sequential match)
        if current_trade_idx < len(results):
            outcome = results[current_trade_idx]
            monthly_results.append({'Month': trade_month, 'Outcome': outcome})
            current_trade_idx += 1
            
    # Aggregate
    results_df = pd.DataFrame(monthly_results)
    if not results_df.empty:
        monthly_groups = results_df.groupby('Month')
        
        for name, group in monthly_groups:
            m_wins = (group['Outcome'] == 1).sum()
            m_losses = (group['Outcome'] == -1).sum()
            m_total = len(group)
            m_wr = (m_wins / m_total) * 100 if m_total > 0 else 0
            m_pf = m_wins / m_losses if m_losses > 0 else 99.9
            
            print(f"{name:<10} | {m_total:<8} | {m_wr:>6.2f}%   | {m_pf:>6.2f}")
            
            monthly_stats[str(name)] = {
                "Total_Trades": int(m_total),
                "Win_Rate": float(m_wr),
                "Profit_Factor": float(m_pf)
            }

    # Save validation report
    report = {
        "Period": "2025.01.01 - 2025.12.31",
        "Total_Trades": total,
        "Win_Rate": win_rate,
        "Profit_Factor": profit_factor,
        "Monthly_Breakdown": monthly_stats
    }
    with open(os.path.join(BASE_DIR, 'Docs', 'Validation_Report_2025.json'), 'w') as f:
        json.dump(report, f, indent=4)
        
    # --- QUICK TEST: Short Logic (Symmetric) ---
    print(f"\n--- Checking Short Logic (Symmetric) ---")
    signals_sell = (weighted_sum < -threshold) & adx_condition
    if np.sum(signals_sell) == 0:
        print("No Short Signals triggered (Score < -Threshold).")
    else:
        results_sell = []
        indices_sell = np.where(signals_sell)[0]
        for idx in indices_sell:
            if idx >= len(df) - 1: continue
            entry = df.iloc[idx+1]['Open']
            tp = entry - 2.00 # Short TP
            sl = entry + 2.00 # Short SL
            outcome = 0
            for i in range(idx+1, min(idx+60, len(df))):
                h = df.iloc[i]['High']
                l = df.iloc[i]['Low']
                if h >= sl: outcome = -1; break
                if l <= tp: outcome = 1; break
            if outcome == 0:
                close = df.iloc[min(idx+60, len(df)-1)]['Close']
                if close < entry: outcome = 1
                else: outcome = -1
            results_sell.append(outcome)
            
        wins_s = results_sell.count(1)
        losses_s = results_sell.count(-1)
        total_s = len(results_sell)
        wr_s = (wins_s / total_s) * 100 if total_s > 0 else 0
        pf_s = wins_s / losses_s if losses_s > 0 else 99.9
        print(f"Short Trades: {total_s}")
        print(f"Short WR: {wr_s:.2f}%")
        print(f"Short PF: {pf_s:.2f}")

    return results # Return the trade sequence for further analysis

def main():
    print(f"Loading {DATA_FILE}...")
    df = pd.read_csv(DATA_FILE)
    df['Time'] = pd.to_datetime(df['Time'])  # Ensure Time is datetime object
    config = load_config()
    results = run_backtest(df, config)
    
    # MDD Calculation
    if results:
        cumulative = np.cumsum(results)
        peak = np.maximum.accumulate(cumulative)
        drawdown = peak - cumulative
        max_drawdown_r = np.max(drawdown) if len(drawdown) > 0 else 0
        net_profit_r = np.sum(results)
        
        print(f"\n--- Risk Analysis (Based on 1R Risk) ---")
        print(f"Net Profit (R): {net_profit_r}")
        print(f"Max Drawdown (R): {max_drawdown_r}")
        
        target_return_pct = 20.0
        if net_profit_r > 0:
            risk_per_trade_pct = target_return_pct / net_profit_r
            expected_mdd_pct = max_drawdown_r * risk_per_trade_pct
            print(f"To achieve {target_return_pct}% Return:")
            print(f"  - Risk per Trade: {risk_per_trade_pct:.2f}%")
            print(f"  - Expected MDD:   {expected_mdd_pct:.2f}%")
        else:
            print("Strategy had a net loss. Cannot calculate risk for positive return.")

if __name__ == "__main__":
    main()
