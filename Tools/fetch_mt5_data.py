import MetaTrader5 as mt5
import pandas as pd
import datetime
import os
import argparse

def fetch_mt5_data(symbol, start_date, end_date, output_dir):
    # 1. MT5 연결
    if not mt5.initialize():
        print(f"❌ MT5 초기화 실패: {mt5.last_error()}")
        return

    print(f"✅ MT5 연결 성공: {mt5.terminal_info().name}")

    # 2. 날짜 설정 (문자열 -> datetime)
    # start_date: 'YYYY-MM-DD'
    try:
        start_dt = datetime.datetime.strptime(start_date, "%Y-%m-%d")
        if end_date:
            end_dt = datetime.datetime.strptime(end_date, "%Y-%m-%d") + datetime.timedelta(days=1) # 23:59:59까지 포함 위해 다음날 0시로
        else:
            end_dt = datetime.datetime.now()
    except ValueError:
        print("❌ 날짜 형식이 잘못되었습니다 (YYYY-MM-DD)")
        mt5.shutdown()
        return

    print(f"📥 {symbol} 데이터 수집 중 ({start_dt.date()} ~ {end_dt.date()})...")

    # 3. 데이터 요청 (M1)
    rates = mt5.copy_rates_range(symbol, mt5.TIMEFRAME_M1, start_dt, end_dt)

    if rates is None or len(rates) == 0:
        print(f"❌ 데이터가 없습니다. (Error: {mt5.last_error()})")
        mt5.shutdown()
        return

    print(f"✅ {len(rates)}개 캔들 수신 완료")

    # 4. DataFrame 변환 및 포맷팅
    df = pd.DataFrame(rates)
    df['time'] = pd.to_datetime(df['time'], unit='s')
    
    # 컬럼 선택 및 이름 변경 (Time, Open, Close, High, Low)
    # MT5 컬럼: time, open, high, low, close, tick_volume, spread, real_volume
    df = df[['time', 'open', 'close', 'high', 'low']]
    df.columns = ['Time', 'Open', 'Close', 'High', 'Low']
    
    # 시간 포맷 (YYYY.MM.DD HH:MM)
    df['Time'] = df['Time'].dt.strftime('%Y.%m.%d %H:%M')

    # 5. CSV 저장
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    filename = f"{symbol}_{start_date}_{end_dt.date()}.csv".replace("-", ".")
    filepath = os.path.join(output_dir, filename)
    
    df.to_csv(filepath, index=False)
    print(f"💾 파일 저장 완료: {filepath}")

    mt5.shutdown()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='MT5 Market Data Fetcher')
    parser.add_argument('--symbol', type=str, default='XAUUSD', help='종목 코드')
    parser.add_argument('--start_date', type=str, required=True, help='시작일 (YYYY-MM-DD)')
    parser.add_argument('--end_date', type=str, help='종료일 (YYYY-MM-DD, 생략 시 현재까지)')
    parser.add_argument('--output_dir', type=str, default='.', help='저장 경로')
    
    args = parser.parse_args()
    
    fetch_mt5_data(args.symbol, args.start_date, args.end_date, args.output_dir)
