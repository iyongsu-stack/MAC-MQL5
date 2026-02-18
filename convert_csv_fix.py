import pandas as pd
import sys
import shutil
import os

file_path = r"c:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\TotalResult_MQL5.csv"
backup_path = file_path + ".bak"

try:
    # 1. Read first line (Header)
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        header_line = f.readline().strip()
        data_line = f.readline().strip()
        
    # Analyze splits assuming space separator
    header_tokens = header_line.split()
    data_tokens = data_line.split()
    
    print(f"Header columns: {len(header_tokens)}")
    print(f"Data columns (row 1): {len(data_tokens)}")
    
    header_processed = header_tokens
    
    # 2. Logic to handle Date/Time split
    # If data has 1 more column than header, and the first header is "Time", it usually implies <Date> <Time> are split tokens for one header "Time".
    if len(data_tokens) == len(header_tokens) + 1:
        print("Mismatch detected: Data has 1 more column than header.")
        if "Time" in header_tokens[0]:
            print("First header is 'Time'. Assuming Date and Time columns.")
            header_processed = ["Date"] + header_tokens
        else:
            print("First header is NOT 'Time'. Prepending 'Unknown_Col'.")
            header_processed = ["Unknown_Col"] + header_tokens
            
    elif len(data_tokens) != len(header_tokens):
        print(f"WARNING: Major mismatch. Header={len(header_tokens)}, Data={len(data_tokens)}")
        # Proceed with caution? Or just rely on pandas index_col=False?
        # If we supply 'names', pandas will force usage.
    
    # 3. Read dataframe with explicit names
    print("Reading CSV with corrected headers...")
    # Use delim_whitespace=True which is equiv to sep='\s+' but simpler for this purpose? sep='\s+' is fine.
    df = pd.read_csv(file_path, sep=r'\s+', names=header_processed, skiprows=1, engine='python', index_col=False)
    
    print(f"Data Loaded: {df.shape}")
    print(df.head(3))
    
    # Check if 'Date' exists and if we should merge it back to 'Time'? 
    # User asked for "Comma separated". Usually Date,Time is fine as two columns if header reflects it.
    
    # 4. Save
    print("Saving to CSV...")
    df.to_csv(file_path, index=False, sep=',')
    print("Conversion success.")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
