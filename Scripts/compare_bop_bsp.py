import pandas as pd
import matplotlib.pyplot as plt
import os

# Paths
MQL5_DIR = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files"
FILE_MQL5 = os.path.join(MQL5_DIR, "TotalResult_MQL5.csv")
FILE_PY   = os.path.join(MQL5_DIR, "TotalResult_2026_02_18_1.csv")

OUTPUT_IMG = os.path.join(MQL5_DIR, "Comparison_BOP_BSP.png")

def run_comparison():
    print(f"Loading MQL5: {FILE_MQL5}")
    # MQL5 CSV: Comma separated, Time format YYYY.MM.DD HH:MM
    # Column names might have quotes
    df_mql = pd.read_csv(FILE_MQL5, sep=',')
    
    # Strip whitespace and quotes from columns
    df_mql.columns = [c.strip().strip('"') for c in df_mql.columns]
    
    # Parse Time
    df_mql['Time'] = pd.to_datetime(df_mql['Time'], format='%Y.%m.%d %H:%M')
    
    print(f"Loading Python: {FILE_PY}")
    # Python CSV: Comma separated, Time format ISO or YYYY-MM-DD HH:MM:SS
    df_py = pd.read_csv(FILE_PY, sep=',')
    df_py['Time'] = pd.to_datetime(df_py['Time'])
    
    # Target Columns
    targets = [
        "BOPWMA_(10,3)_SmoothBOP",
        "BOPWMA_(30,5)_SmoothBOP",
        "BSPWMA_(10,3)_SmoothDiffRatio",
        "BSPWMA_(30,5)_SmoothDiffRatio"
    ]
    
    # Check columns
    for cols, name in [(df_mql.columns, 'MQL5'), (df_py.columns, 'Python')]:
        missing = [t for t in targets if t not in cols]
        if missing:
            print(f"Error: Missing columns in {name}: {missing}")
            return

    # Merge
    print("Merging data...")
    df_merged = pd.merge(
        df_mql[['Time'] + targets],
        df_py[['Time'] + targets],
        on='Time',
        suffixes=('_MQL', '_PY'),
        how='inner'
    )
    
    print(f"Merged rows: {len(df_merged)}")
    if len(df_merged) == 0:
        print("No overlapping data found!")
        return

    # Plot
    print("Generating plot...")
    fig, axes = plt.subplots(4, 2, figsize=(18, 16))
    plt.subplots_adjust(hspace=0.4)
    
    for i, col in enumerate(targets):
        col_mql = f"{col}_MQL"
        col_py  = f"{col}_PY"
        
        # Calculate Diff
        diff = df_merged[col_mql] - df_merged[col_py]
        
        # Plot 1: Values (limit to first 1000 points and last 1000 points if too large? No, plot all but maybe alpha)
        # To see convergence, plot all but usually initial part is key.
        # Let's plot entire range but lightweight line
        
        ax_val = axes[i, 0]
        ax_val.plot(df_merged['Time'], df_merged[col_mql], label='MQL5', alpha=0.7, linewidth=1)
        ax_val.plot(df_merged['Time'], df_merged[col_py], label='Python', alpha=0.7, linewidth=1, linestyle='--')
        ax_val.set_title(f"{col} - Value Comparison")
        ax_val.legend()
        ax_val.grid(True)
        
        # Plot 2: Difference
        ax_diff = axes[i, 1]
        ax_diff.plot(df_merged['Time'], diff, label='Diff (MQL - PY)', color='red', linewidth=1)
        ax_diff.set_title(f"{col} - Difference")
        ax_diff.legend()
        ax_diff.grid(True)
        
        # Stats
        max_diff = diff.abs().max()
        mean_diff = diff.abs().mean()
        last_diff = diff.iloc[-1]
        print(f"[{col}] Max Diff: {max_diff:.6f}, Mean Diff: {mean_diff:.6f}, Last Diff: {last_diff:.6f}")

    print(f"Saving plot to {OUTPUT_IMG}")
    plt.savefig(OUTPUT_IMG)
    plt.close()
    print("Done.")

if __name__ == "__main__":
    run_comparison()
