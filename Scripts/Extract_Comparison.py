import pandas as pd
import os

# Define paths
base_dir = os.path.join(os.getenv('APPDATA'), r"MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files")
input_file = os.path.join(base_dir, "LRAVGSTD_DownLoad_Verification_Result.csv")
output_file = os.path.join(base_dir, "LRAVGSTD_Minute_Comparison.csv")

if not os.path.exists(input_file):
    print(f"Error: Input file not found: {input_file}")
    exit(1)

print(f"Reading {input_file}...")
df = pd.read_csv(input_file)

# Select relevant columns for minute-by-minute comparison
cols = ['Time', 'stdS', 'Py_stdS', 'Diff_stdS', 'BSPScale', 'Py_BSPScale', 'Diff_BSPScale']

# Check if columns exist
missing = [c for c in cols if c not in df.columns]
if missing:
    print(f"Error: Missing columns {missing}")
    # Fallback to existing columns
    cols = [c for c in cols if c in df.columns]

out_df = df[cols]

print(f"Saving cleaned comparison to {output_file}...")
out_df.to_csv(output_file, index=False)
print("Done.")
