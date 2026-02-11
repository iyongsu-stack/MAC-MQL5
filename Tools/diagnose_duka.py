import sys
import datetime
import os
import traceback
import argparse

def diagnose(symbol, year, month, day):
    try:
        print(f"[Diagnosis] Starting for {symbol} on {year}-{month}-{day}...")
        try:
            import duka.app
            from duka.core.utils import TimeFrame
            print("✅ Import duka successful")
        except ImportError:
            print("❌ ImportError: duka library not found.")
            return

        start = datetime.date(year, month, day)
        end = datetime.date(year, month, day)
        
        output_folder = f"diagnosis_{symbol}_{year}{month:02d}{day:02d}"
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)
            
        print(f"📥 Attempting download: {start} -> {output_folder}")
        
        duka.app.app(
            [symbol], start, end,  
            threads=1, timeframe=TimeFrame.M1, folder=output_folder, 
            header=True
        )
        print("✅ Download function executed (check output folder)")
        
        files = os.listdir(output_folder)
        print(f"📂 Output files: {files}")
        
        csv_count = sum(1 for f in files if f.endswith('.csv') and os.path.getsize(os.path.join(output_folder, f)) > 0)
        
        if csv_count > 0:
            print("🎉 SUCCESS: Valid CSV file found.")
        else:
            print("⚠️ WARNING: No CSV file or empty file generated.")
        
    except Exception as e:
        print("❌ Error occurred:")
        print(traceback.format_exc())

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Duka Library Diagnostic Tool')
    parser.add_argument('--symbol', type=str, default='EURUSD', help='Symbol to test')
    parser.add_argument('--year', type=int, default=2026, help='Year')
    parser.add_argument('--month', type=int, default=2, help='Month')
    parser.add_argument('--day', type=int, default=10, help='Day')
    
    args = parser.parse_args()
    diagnose(args.symbol, args.year, args.month, args.day)
