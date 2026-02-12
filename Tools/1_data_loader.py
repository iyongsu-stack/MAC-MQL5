import pandas as pd
import zipfile
import os
from datetime import datetime

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES_DIR = os.path.join(BASE_DIR, 'Files')
DATA_DIR = os.path.join(BASE_DIR, 'Data')
ZIP_FILE = os.path.join(FILES_DIR, 'DAT_ASCII_XAUUSD_M1_2025.zip')
CSV_2026 = os.path.join(FILES_DIR, 'xauusd_2026.csv')
OUTPUT_FILE = os.path.join(DATA_DIR, 'XAUUSD.csv')

def load_2025_data():
    """Unzips and loads 2025 data from HistData.com format"""
    print(f"Loading 2025 data from {ZIP_FILE}...")
    with zipfile.ZipFile(ZIP_FILE, 'r') as z:
        # Assume there's one csv/txt file inside
        file_list = z.namelist()
        target_file = [f for f in file_list if f.endswith('.csv') or f.endswith('.txt')][0]
        print(f"Extracting {target_file}...")
        
        with z.open(target_file) as f:
            # HistData format usually: 20250102 170000;123.45;...
            # But let's check the format dynamically or assume standard HistData ASCII
            # Standard HistData: DateTime (YYYYMMDD HHMMSS), Open, High, Low, Close, Volume?
            # Let's inspect first few lines if possible, but pandas can usually infer.
            # We'll try reading with specific delimiter if needed.
            # Often it is strictly semi-colon separated or comma.
            
            # Let's try reading as CSV with no header first to inspect
            df = pd.read_csv(f, header=None, sep=';')
            
            # HistData ASCII M1 format: 20250102 170000;4313.890000;4315.230000;4315.720000;4313.740000;0
            # Col 0: DateTime, 1: Open, 2: High, 3: Low, 4: Close, 5: Volume
            df.columns = ['DateTime_Str', 'Open', 'High', 'Low', 'Close', 'Volume']
            
            # Parse DateTime
            df['Time'] = pd.to_datetime(df['DateTime_Str'], format='%Y%m%d %H%M%S')
            
            # Select and reorder
            df = df[['Time', 'Open', 'High', 'Low', 'Close']]
            print(f"2025 Data loaded: {len(df)} rows")
            return df

def load_2026_data():
    """Loads 2026 data from existing CSV"""
    print(f"Loading 2026 data from {CSV_2026}...")
    # Format: Time,Open,Close,High,Low
    # Time format: 2025.12.31 15:00
    df = pd.read_csv(CSV_2026)
    
    # Parse DateTime
    df['Time'] = pd.to_datetime(df['Time'], format='%Y.%m.%d %H:%M')
    
    # Reorder to standard OHLC
    df = df[['Time', 'Open', 'High', 'Low', 'Close']]
    print(f"2026 Data loaded: {len(df)} rows")
    return df

def main():
    if not os.path.exists(DATA_DIR):
        os.makedirs(DATA_DIR)
        
    df_2025 = load_2025_data()
    df_2026 = load_2026_data()
    
    # Concatenate
    print("Merging data...")
    merged_df = pd.concat([df_2025, df_2026])
    
    # Drop duplicates just in case overlap exists
    merged_df = merged_df.drop_duplicates(subset=['Time']).sort_values('Time')
    
    # Save
    print(f"Saving to {OUTPUT_FILE}...")
    merged_df.to_csv(OUTPUT_FILE, index=False)
    print("Done.")

if __name__ == "__main__":
    main()
