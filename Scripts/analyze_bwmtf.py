import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt

# Paths
MQL5_DIR = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files"
FILE_MQL5 = os.path.join(MQL5_DIR, "TotalResult_MQL5.csv")
FILE_PY   = os.path.join(MQL5_DIR, "TotalResult_2026_02_18_1.csv")

def analyze_bwmtf():
    print(f"Loading MQL5: {FILE_MQL5}")
    try:
        df_mql = pd.read_csv(FILE_MQL5, sep=',')
    except:
        df_mql = pd.read_csv(FILE_MQL5, sep='\t') # Fallback
        
    # Column clean up
    df_mql.columns = [c.strip().strip('"') for c in df_mql.columns]
    
    # Check correct columns
    target_cols = ['BWMTF_H4_BWMFI', 'BWMTF_M5_BWMFI']
    available_cols = [c for c in target_cols if c in df_mql.columns]
    if not available_cols:
        print("Required MQL5 columns not found. Finding close matches...")
        for c in df_mql.columns:
            if 'BWMFI' in c: print(f"Found: {c}")
        # Try to use index if columns missing? No, assume standard names from previous output
    
    # Parse Time
    # MQL5 format is usually YYYY.MM.DD HH:MM
    df_mql['Time'] = pd.to_datetime(df_mql['Time'], format='%Y.%m.%d %H:%M')
    
    print(f"Loading Python: {FILE_PY}")
    df_py = pd.read_csv(FILE_PY, sep=',')
    df_py['Time'] = pd.to_datetime(df_py['Time'])
    
    # Merge
    print("Merging...")
    df = pd.merge(df_mql[['Time'] + target_cols], df_py[['Time'] + target_cols], on='Time', suffixes=('_MQL', '_PY'), how='inner')
    
    if len(df) == 0:
        print("No overlapping data.")
        return

    # Analyze
    print(f"Merged Data: {len(df)} rows")
    
    # Calculate Ratios
    for col in target_cols:
        mql_col = f"{col}_MQL"
        py_col = f"{col}_PY"
        
        # Avoid division by zero
        df['Ratio'] = df[mql_col] / df[py_col].replace(0, np.nan)
        
        print(f"\nAnalysis for {col}:")
        print(df[['Time', mql_col, py_col, 'Ratio']].head(10))
        
        median_ratio = df['Ratio'].median()
        mean_ratio = df['Ratio'].mean()
        std_ratio = df['Ratio'].std()
        
        print(f"Median Ratio (MQL/PY): {median_ratio:.6f}")
        print(f"Mean Ratio: {mean_ratio:.6f}")
        print(f"Std Ratio: {std_ratio:.6f}")
        
        # Check if Ratio is close to a power of 10 or Point related
        if 90 < median_ratio < 110:
            print(">> Likely Point Scaling Issue (Factor ~100)")
        elif 9000 < median_ratio < 11000:
            print(">> Likely Point Scaling Issue (Factor ~10000)")
            
    # Also check if Volume might be the issue
    # MQL5 BWMFI = (High - Low) * Factor / Volume ?
    # Python BWMFI = (High - Low) / Volume
    
if __name__ == "__main__":
    analyze_bwmtf()
