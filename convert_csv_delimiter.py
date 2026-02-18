import sys
import shutil
import os

try:
    import pandas as pd
except ImportError:
    print("pandas not found. please install it")
    sys.exit(1)

file_path = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\TotalResult_MQL5.csv"
backup_path = file_path + ".bak"

try:
    if not os.path.exists(backup_path):
        shutil.copy2(file_path, backup_path)
        print(f"Backup created: {backup_path}")
    else:
        print(f"Backup already exists.")
    
    # Read header to determine format
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        header_line = f.readline().strip()
        comma_count = header_line.count(',')
        space_count = header_line.count(' ') + header_line.count('\t')
        
        # Heuristic: If significantly more spaces than commas, or commas < 40 (for 69 cols), assume space sep
        # Even if commas exist (due to parens in names), we treat as space sep if structure implies it.
        # But wait, original file (Mixed) had Comma Header (68 commas) and Space Body.
        # Regnerated file (Space) has Space Header (commas only in parens) and Space Body.
        
        print(f"Header analysis: comma_count={comma_count}, space_count={space_count}")
        
        if comma_count > 40:
            print("Assuming Comma-Separated Header (Mixed Format).")
            raw_columns = [c.replace('"', '').strip() for c in header_line.split(',')]
            
            # Deduplicate logic
            seen = {}
            columns = []
            for col in raw_columns:
                if col in seen:
                    seen[col] += 1
                    columns.append(f"{col}.{seen[col]}")
                else:
                    seen[col] = 0
                    columns.append(col)
            
            names_arg = columns
            skip_rows = 1
        else:
            print("Assuming Space-Separated Header.")
            names_arg = None
            skip_rows = 0

    print("Reading CSV...")
    if names_arg:
        # Mixed: comma header passed as names, body read as spaces
        df = pd.read_csv(file_path, sep=r'\s+', skiprows=skip_rows, header=None, names=names_arg, engine='python')
    else:
        # Pure space: pandas infers names from first row splitting by space
        df = pd.read_csv(file_path, sep=r'\s+', engine='python')
    
    print(f"Data shape: {df.shape}")
    print(df.head(3))
    
    print("Writing CSV...")
    df.to_csv(file_path, index=False, sep=',')
    print("Conversion success.")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
