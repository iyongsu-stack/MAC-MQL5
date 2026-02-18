import pandas as pd
import numpy as np
import sys
import os

# Add Scripts to params
sys.path.append(os.path.join(os.getcwd(), 'Scripts'))

from BWMFI_MTF_Converter import calculate_bwmfi_mtf

# Paths
MQL5_DIR = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files"
FILE_DATA = os.path.join(MQL5_DIR, "BWMFI_MTF_DownLoad.csv")
FILE_MQL5 = os.path.join(MQL5_DIR, "TotalResult_MQL5.csv")

def check_bwmtf():
    print("Loading Base Data...")
    try:
        df = pd.read_csv(FILE_DATA, sep='\t')
    except:
        df = pd.read_csv(FILE_DATA)
        
    df['Time'] = pd.to_datetime(df['Time'], format='%Y.%m.%d %H:%M')
    df.set_index('Time', inplace=True)
    
    # Run BWMTF
    print("Running BWMTF H4 (Point=0.01)...")
    df_h4 = calculate_bwmfi_mtf(df.copy(), target_timeframe='PERIOD_H4', volume_col='TickVolume', point=0.01)
    
    print("Running BWMTF M5 (Point=0.01)...")
    df_m5 = calculate_bwmfi_mtf(df.copy(), target_timeframe='PERIOD_M5', volume_col='TickVolume', point=0.01)
    
    # Load MQL5 Result
    print("Loading MQL5 Result...")
    df_mql = pd.read_csv(FILE_MQL5)
    # Clean output columns
    df_mql.columns = [c.strip().strip('"') for c in df_mql.columns]
    df_mql['Time'] = pd.to_datetime(df_mql['Time'], format='%Y.%m.%d %H:%M')
    
    # Merge
    print("Merging...")
    merged = pd.merge(df_mql, df_m5[['BWMFI']], left_on='Time', right_index=True, suffixes=('_MQL', '_PY'), how='inner')
    
    # Calculate Ratio
    target_col = 'BWMTF_M5_BWMFI'
    merged['Ratio'] = merged[target_col] / merged['BWMFI']
    
    print("\n[Result Analysis]")
    print(merged[['Time', target_col, 'BWMFI', 'Ratio']].head(10))
    print(f"Median Ratio: {merged['Ratio'].median()}")
    
    # Check H4
    merged_h4 = pd.merge(df_mql, df_h4[['BWMFI']], left_on='Time', right_index=True, suffixes=('_MQL', '_PY'), how='inner')
    merged_h4['Ratio'] = merged_h4['BWMTF_H4_BWMFI'] / merged_h4['BWMFI']
    print("\n[H4 Analysis]")
    print(merged_h4[['Time', 'BWMTF_H4_BWMFI', 'BWMFI', 'Ratio']].head(10))
    print(f"H4 Median Ratio: {merged_h4['Ratio'].median()}")

if __name__ == "__main__":
    check_bwmtf()
