import pandas as pd
import numpy as np
import os
from datetime import timedelta

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, 'Data')
PRICE_FILE = os.path.join(DATA_DIR, 'XAUUSD.csv')
TRADE_FILE = os.path.join(DATA_DIR, 'PositionCase2.csv')
OUTPUT_FILE = os.path.join(DATA_DIR, 'TotalResult_Labeled.csv')

def load_data():
    print("Loading price data...")
    if not os.path.exists(PRICE_FILE):
        raise FileNotFoundError(f"{PRICE_FILE} not found. Run 1_data_loader.py first.")
    
    df_price = pd.read_csv(PRICE_FILE)
    df_price['Time'] = pd.to_datetime(df_price['Time'])
    df_price.sort_values('Time', inplace=True)
    df_price.reset_index(drop=True, inplace=True)
    
    print("Loading trade data...")
    if not os.path.exists(TRADE_FILE):
        raise FileNotFoundError(f"{TRADE_FILE} not found.")
        
    df_trade = pd.read_csv(TRADE_FILE)
    # Trade file Time format: 2026.01.02 04:45
    df_trade['OpenTime'] = pd.to_datetime(df_trade['OpenTime'], format='%Y.%m.%d %H:%M')
    df_trade['CloseTime'] = pd.to_datetime(df_trade['CloseTime'], format='%Y.%m.%d %H:%M')
    
    return df_price, df_trade

def apply_labeling(df_price, df_trade):
    print("Applying applying labeling logic...")
    
    # Initialize Label Columns
    df_price['Label_Open_Buy'] = 0
    df_price['Label_Open_Sell'] = 0
    df_price['Label_Close_Buy'] = 0
    df_price['Label_Close_Sell'] = 0
    
    # Create a Time-to-Index map for faster lookup
    time_map = {t: i for i, t in enumerate(df_price['Time'])}
    
    total_trades = len(df_trade)
    print(f"Processing {total_trades} trades...")
    
    for idx, row in df_trade.iterrows():
        open_time = row['OpenTime']
        close_time = row['CloseTime']
        open_type = row['OpenType'] # Buy or Sell
        close_type = row['CloseType'] # Sell or Buy
        
        # --- Entry Labeling ---
        # Window: -4 to +4 (9 bars) around OpenTime
        if open_time in time_map:
            center_idx = time_map[open_time]
            start_idx = max(0, center_idx - 4)
            end_idx = min(len(df_price) - 1, center_idx + 4)
            
            indices = range(start_idx, end_idx + 1)
            
            if open_type == 'Buy':
                df_price.loc[indices, 'Label_Open_Buy'] = 1
            elif open_type == 'Sell':
                df_price.loc[indices, 'Label_Open_Sell'] = 1
        
        # --- Exit Labeling ---
        # Window: -3 to 0 (4 bars) ending at CloseTime
        if close_time in time_map:
            end_idx = time_map[close_time]
            start_idx = max(0, end_idx - 3)
            
            indices = range(start_idx, end_idx + 1)
            
            # CloseType is the ACTION. 
            # If Position was Buy, CloseType is Sell. We label "Close_Buy".
            # The Docs say: Label_Close_Buy: "Closing a Buy position".
            # My logic: If OpenType was Buy, then this exit is Closing a Buy.
            
            if open_type == 'Buy': # We are closing a Buy position
                df_price.loc[indices, 'Label_Close_Buy'] = 1
            elif open_type == 'Sell': # We are closing a Sell position
                df_price.loc[indices, 'Label_Close_Sell'] = 1

    return df_price

def main():
    try:
        df_price, df_trade = load_data()
        labeled_df = apply_labeling(df_price, df_trade)
        
        print(f"Saving labeled data to {OUTPUT_FILE}...")
        labeled_df.to_csv(OUTPUT_FILE, index=False)
        
        # Validation stats
        print("\nLabel Statistics:")
        print(labeled_df[['Label_Open_Buy', 'Label_Open_Sell', 'Label_Close_Buy', 'Label_Close_Sell']].sum())
        
        print("Done.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
