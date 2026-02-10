import os
import requests
import pandas as pd
import io
import time

def fetch_data():
    api_key = os.environ.get('ALPHAVANTAGE_API_KEY')
    if not api_key:
        print("Error: ALPHAVANTAGE_API_KEY not found.")
        return

    months = [f"2025-{i:02d}" for i in range(1, 13)]
    all_data = []

    print("Starting download for 2025 XAUUSD (1min)...")

    for month in months:
        url = f"https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=XAUUSD&interval=1min&month={month}&outputsize=full&apikey={api_key}&datatype=csv"
        
        print(f"Fetching {month}...")
        try:
            response = requests.get(url)
            if response.status_code == 200:
                # Check if response is valid CSV or error message
                content = response.text
                if "Error Message" in content or "Information" in content:
                     print(f"Warning for {month}: {content}")
                     continue
                
                # Parse CSV
                df = pd.read_csv(io.StringIO(content))
                if not df.empty:
                    all_data.append(df)
                    print(f"  > Retrieved {len(df)} records.")
                else:
                    print(f"  > No data found.")
            else:
                print(f"Error fetching {month}: Status {response.status_code}")
        except Exception as e:
            print(f"Exception for {month}: {e}")
            
        time.sleep(15) # Wait to avoid rate limits (standard free tier is 5 calls/min)

    if all_data:
        final_df = pd.concat(all_data)
        final_df['timestamp'] = pd.to_datetime(final_df['timestamp'])
        final_df = final_df.sort_values('timestamp')
        
        output_path = r"C:\Users\gim-yongsu\AppData\Roaming\MetaQuotes\Terminal\5B326B03063D8D9C446E3637EFA32247\MQL5\Files\vantage.csv"
        final_df.to_csv(output_path, index=False)
        print(f"Successfully saved {len(final_df)} records to {output_path}")
    else:
        print("No data collected.")

if __name__ == "__main__":
    fetch_data()
