import pandas as pd
import sys

file_path = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\TotalResult_MQL5.csv"

try:
    # First, just read the first line to peek at raw content
    with open(file_path, 'r', encoding='utf-8') as f:
        first_line = f.readline().strip()
        print(f"Raw Header Line Sample: {first_line[:100]}...")
        
        # Check delimiters
        space_split = first_line.split()
        tab_split = first_line.split('\t')
        comma_split = first_line.split(',')
        
        print(f"Split counts -> Space: {len(space_split)}, Tab: {len(tab_split)}, Comma: {len(comma_split)}")

    # Try reading with pandas assuming whitespace separator
    print("\nAttempting pandas read with sep='\\s+'...")
    df = pd.read_csv(file_path, sep=r'\s+', engine='python', nrows=5)
    print(f"Pandas detected {len(df.columns)} columns.")
    print(f"Columns: {df.columns.tolist()}")
    
except Exception as e:
    print(f"Error: {e}")
