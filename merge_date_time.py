import pandas as pd
import sys
import shutil
import os

file_path = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\TotalResult_MQL5.csv"
backup_path = file_path + ".bak_merged"

try:
    # Backup before this specific operation
    if not os.path.exists(backup_path):
        shutil.copy2(file_path, backup_path)
        print(f"Backup created: {backup_path}")
    
    print("Reading CSV...")
    df = pd.read_csv(file_path)
    
    # Check if Date and Time columns exist
    if 'Date' in df.columns and 'Time' in df.columns:
        print("Merging Date and Time columns...")
        
        # Merge Date and Time into a temporary 'MergedTime'
        # Ensure they are treated as strings
        df['MergedTime'] = df['Date'].astype(str) + ' ' + df['Time'].astype(str)
        
        # Drop original Date and Time
        df.drop(columns=['Date', 'Time'], inplace=True)
        
        # Rename MergedTime to Time and move to front
        df.rename(columns={'MergedTime': 'Time'}, inplace=True)
        
        # Reorder columns to ensure Time is first
        cols = ['Time'] + [c for c in df.columns if c != 'Time']
        df = df[cols]
        
        print(f"New column layout (first 5): {cols[:5]}")
        print("First 3 rows of new Time column:")
        print(df['Time'].head(3))
        
        print("Saving to CSV...")
        df.to_csv(file_path, index=False)
        print("Merge success.")
        
    else:
        print("Error: 'Date' or 'Time' column NOT found. Manual inspection required.")
        print(f"Current columns: {df.columns.tolist()}")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
