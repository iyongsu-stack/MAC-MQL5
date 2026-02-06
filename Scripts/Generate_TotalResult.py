
import pandas as pd
import numpy as np
import os
import datetime
import sys

# Import refactored verifiers
# Ensure current directory is in path if running from same folder
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    import BOPAvgStd_Verifier as bop_avg
    import BOPWmaSmooth_Calc_and_Verify as bop_wma
    import LRAVGSTD_Verifier as lravg
    import BSPWmaSmooth_Converter as bsp_wma
    import Chaikin_Verification as chaikin
    import TDI_Verifier as tdi
    import QQE_Verification as qqe
except ImportError as e:
    print(f"Error importing modules: {e}")
    sys.exit(1)

# ==============================================================================
# Configuration
# ==============================================================================
BASE_DIR = os.path.join(os.getenv('APPDATA'), r"MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files")
OUTPUT_FILENAME_PATTERN = "TotalResult_{}_{}.csv"

# ==============================================================================
# Helper Functions
# ==============================================================================
def find_base_data(directory):
    """
    Finds a suitable CSV file to use as the base for OHLCV data.
    Prioritizes files that likely contain raw price data.
    """
    candidates = [
        "XAUUSD.csv",
        "LRAVGSTD_DownLoad.csv",
        "BOPAvgStd_DownLoad.csv",
        "DataDownLoad.csv",
        "XAUUSD_Data.csv"
    ]
    
    for filename in candidates:
        path = os.path.join(directory, filename)
        if os.path.exists(path):
            print(f"Using base data file: {filename}")
            return path
            
    # Fallback: take any csv
    files = [f for f in os.listdir(directory) if f.endswith(".csv") and "Result" not in f]
    if files:
        print(f"Using fallback base data file: {files[0]}")
        return os.path.join(directory, files[0])
        
    return None

def rename_columns(df, prefix, suffix=""):
    """
    Renames columns with a prefix/suffix, keeping Time/OHLC intact.
    """
    new_cols = {}
    for col in df.columns:
        if col in ['Time', 'CheckTime', 'Open', 'High', 'Low', 'Close']:
            continue
        
        # Helper to avoid double naming if prefix is already hinted
        name = f"{prefix}_{col}{suffix}"
        # If prefix is "BOP" and col is "BOP", result "BOP_BOP". Good enough.
        
        # Clean specific python columns prefix if present
        if col.startswith("Py_"):
             name = f"{prefix}_{col[3:]}{suffix}"
        
        new_cols[col] = name
        
    return df.rename(columns=new_cols)

# ==============================================================================
# Main Runner
# ==============================================================================
def main():
    print("--- Starting Ensemble Data Generation ---")
    
    # 1. Load Base Data
    base_path = find_base_data(BASE_DIR)
    if not base_path:
        print("Error: No base data file found.")
        return
        
    # Read base df
    try:
        base_df = pd.read_csv(base_path, sep='\t')
        if 'Time' not in base_df.columns:
             base_df = pd.read_csv(base_path, sep=';')
             if 'Time' not in base_df.columns:
                  base_df = pd.read_csv(base_path, sep=',')
    except:
        base_df = pd.read_csv(base_path)
        
    base_df.columns = base_df.columns.str.strip()
    
    # Keep only essential columns for the master DF
    essential_cols = ['Time', 'Open', 'High', 'Low', 'Close']
    if not all(c in base_df.columns for c in essential_cols):
        print(f"Error: Base file missing columns. Found: {base_df.columns}")
        return
        
    master_df = base_df[essential_cols].copy()
    
    # Ensure Time is datetime
    try:
        master_df['Time'] = pd.to_datetime(master_df['Time'])
    except Exception as e:
        print(f"Warning: Could not convert Time to datetime: {e}")
        # Try custom parser for MQL5 format 'YYYY.MM.DD HH:MM'
        try:
            master_df['Time'] = pd.to_datetime(master_df['Time'], format='%Y.%m.%d %H:%M')
        except:
            pass

    print(f"Base data loaded: {len(master_df)} rows.")

    # 2. Sequential Execution
    # ---------------------------------------------------------
    # 1. BOPAvgStd (Default)
    print("\n[1/10] Processing BOPAvgStd (Default)...")
    res1 = bop_avg.calculate_bop_avg_std(master_df) # Default params
    # Expected cols: Py_BOP, Py_Avg, Py_StdDev, Py_Reward
    # We want to keep specific outputs. 
    # Protocol says "Sequential Indicator Buffers".
    # We'll keep all "Py_" columns.
    
    # Filter for BOPAvgStd specific columns
    # Note: BOPAvgStd_Verifier does not strictly use Py_ prefix for all
    target_cols = ['BOP', 'BOPAvg', 'Diff', 'Up1', 'Down1', 'Scale_Py']
    cols_to_keep = [c for c in target_cols if c in res1.columns]
    
    if not cols_to_keep:
        print("Warning: No output columns found for BOPAvgStd.")
    else:
        subset = res1[cols_to_keep].copy()
        # Rename Scale_Py to Scale
        subset.rename(columns={'Scale_Py': 'Scale'}, inplace=True)
        master_df = pd.concat([master_df, subset], axis=1)

    # ---------------------------------------------------------
    # 2. LRAVGSTD (AvgPeriod=60)
    print("\n[2/10] Processing LRAVGSTD (Avg=60)...")
    res2 = lravg.calculate_lravgstd(master_df, avg_period=60)
    # Output: Py_stdS, Py_BSPScale
    cols_to_keep = [c for c in res2.columns if c.startswith("Py_")]
    subset = res2[cols_to_keep].copy()
    subset.columns = [c.replace("Py_", "") + "(60)" for c in subset.columns]
    master_df = pd.concat([master_df, subset], axis=1)

    # ---------------------------------------------------------
    # 3. LRAVGSTD (AvgPeriod=180)
    print("\n[3/10] Processing LRAVGSTD (Avg=180)...")
    res3 = lravg.calculate_lravgstd(master_df, avg_period=180)
    cols_to_keep = [c for c in res3.columns if c.startswith("Py_")]
    subset = res3[cols_to_keep].copy()
    subset.columns = [c.replace("Py_", "") + "(180)" for c in subset.columns]
    master_df = pd.concat([master_df, subset], axis=1)

    # ---------------------------------------------------------
    # 4. BOPWmaSmooth (Wma=10, Smooth=3) -> Default
    print("\n[4/10] Processing BOPWmaSmooth (10, 3)...")
    res4 = bop_wma.calculate_bop_wma(master_df, wma_period=10, smooth_period=3)
    # Output: Py_SmoothBOP
    cols_to_keep = [c for c in res4.columns if c.startswith("Py_")]
    subset = res4[cols_to_keep].copy()
    # Convention: BufferName(Val1, Val2) -> SmoothBOP(10, 3)
    subset.columns = [c.replace("Py_", "") + "(10,3)" for c in subset.columns]
    master_df = pd.concat([master_df, subset], axis=1)

    # ---------------------------------------------------------
    # 5. BOPWmaSmooth (Wma=30, Smooth=5)
    print("\n[5/10] Processing BOPWmaSmooth (30, 5)...")
    res5 = bop_wma.calculate_bop_wma(master_df, wma_period=30, smooth_period=5)
    cols_to_keep = [c for c in res5.columns if c.startswith("Py_")]
    subset = res5[cols_to_keep].copy()
    subset.columns = [c.replace("Py_", "") + "(30,5)" for c in subset.columns]
    master_df = pd.concat([master_df, subset], axis=1)
    
    # ---------------------------------------------------------
    # 6. BSPWmaSmooth (Wma=10, Smooth=3) -> Default
    # Note: Variable names in script were inpWmaPeriod=10, inpSmoothPeriod=3
    print("\n[6/10] Processing BSPWmaSmooth (10, 3)...")
    res6 = bsp_wma.calculate_bsp_wma_smooth(master_df, wma_period=10, smooth_period=3)
    # Output: MySmoothDiffRatio
    # Rename to just SmoothDiffRatio(10,3)
    # The script output column was 'MySmoothDiffRatio'
    if 'MySmoothDiffRatio' in res6.columns:
        col_data = res6['MySmoothDiffRatio']
        master_df['SmoothDiffRatio(10,3)'] = col_data
        
    # ---------------------------------------------------------
    # 7. BSPWmaSmooth (Wma=30, Smooth=5)
    print("\n[7/10] Processing BSPWmaSmooth (30, 5)...")
    res7 = bsp_wma.calculate_bsp_wma_smooth(master_df, wma_period=30, smooth_period=5)
    if 'MySmoothDiffRatio' in res7.columns:
        col_data = res7['MySmoothDiffRatio']
        master_df['SmoothDiffRatio(30,5)'] = col_data
        
    # ---------------------------------------------------------
    # 8. Chaikin (Default)
    print("\n[8/10] Processing Chaikin (Default)...")
    res8 = chaikin.calculate_chaikin(master_df)
    # Output: Py_CHV, Py_StdDev, Py_CVScale
    cols_to_keep = [c for c in res8.columns if c.startswith("Py_")]
    subset = res8[cols_to_keep].copy()
    subset.columns = [c.replace("Py_", "") for c in subset.columns]
    master_df = pd.concat([master_df, subset], axis=1)

    # ---------------------------------------------------------
    # 9. TDI (Default)
    print("\n[9/10] Processing TDI (Default)...")
    res9 = tdi.calculate_tdi(master_df)
    # Output: Py_RSI, Py_TrSi, Py_Signal
    cols_to_keep = [c for c in res9.columns if c.startswith("Py_")]
    subset = res9[cols_to_keep].copy()
    subset.columns = [c.replace("Py_", "") for c in subset.columns]
    master_df = pd.concat([master_df, subset], axis=1)

    # ---------------------------------------------------------
    # 10. QQE (Default)
    print("\n[10/10] Processing QQE (Default)...")
    res10 = qqe.calculate_qqe(master_df)
    # Output: Py_RSI (dup?), Py_RsiMa, Py_TrLevel
    # Note: TDI also output Py_RSI. We might have duplicate "RSI".
    # Better rename explicitly.
    # QQE_RSI, QQE_RsiMa, QQE_TrLevel
    cols_to_keep = [c for c in res10.columns if c.startswith("Py_")]
    subset = res10[cols_to_keep].copy()
    subset.columns = ["QQE_" + c.replace("Py_", "") for c in subset.columns]
    master_df = pd.concat([master_df, subset], axis=1)
    
    # 3. Save Final Result
    now = datetime.datetime.now()
    output_filename = OUTPUT_FILENAME_PATTERN.format(
        now.strftime("%Y_%m_%d"),
        "1" # Sequence number, simplified for now
    )
    output_path = os.path.join(BASE_DIR, output_filename)
    
    print(f"\nMerging complete.")
    print(f"Final columns: {master_df.columns.tolist()}")
    
    master_df.to_csv(output_path, index=False)
    print(f"saved to: {output_path}")

if __name__ == "__main__":
    main()
