import argparse
import datetime
import os
import pandas as pd
import shutil
from duka.app import app as import_duka
from duka.core.utils import TimeFrame

def fetch_and_process(symbol, days, timeframe_str, offset_hours, output_dir_path=None, use_ochl=False, threads=1, start_date_str=None, end_date_str=None):
    # 1. 날짜 설정
    if start_date_str:
        start_date = datetime.datetime.strptime(start_date_str, "%Y-%m-%d").date()
        if end_date_str:
            end_date = datetime.datetime.strptime(end_date_str, "%Y-%m-%d").date()
        else:
            end_date = datetime.date.today()
    else:
        # 기존 로직: 오늘 기준으로 N일 전 ~ 어제까지
        end_date = datetime.date.today() - datetime.timedelta(days=1)
        start_date = end_date - datetime.timedelta(days=days)
    
    print(f"\n[작업 시작] {symbol} 데이터 다운로드")
    print(f"기간: {start_date} ~ {end_date}")
    
    # 2. 타임프레임 설정
    tf = TimeFrame.M1
    if timeframe_str.upper() == 'TICK': tf = TimeFrame.TICK
    elif timeframe_str.upper() == 'H1': tf = TimeFrame.H1

    # 3. 임시 저장 폴더 (market_data_temp_PID)
    # 병렬 실행 시 충돌 방지를 위해 PID 포함
    temp_folder = f"market_data_temp_{os.getpid()}"
    if not os.path.exists(temp_folder):
        os.makedirs(temp_folder)

    # 4. Dukascopy에서 다운로드 실행
    try:
        print(f"[다운로드 중] Dukascopy 데이터 다운로드... (Threads: {threads})")
        import_duka(
            [symbol], start_date, end_date, 
            threads=threads, timeframe=tf, folder=temp_folder, 
            header=True
        )
        print(f"[다운로드 완료] 처리 중...")

        # 5. 시간 변환 및 컬럼 재정렬
        target_file = None
        for file in os.listdir(temp_folder):
            if symbol in file and file.endswith(".csv"):
                target_file = os.path.join(temp_folder, file)
                break
        
        if target_file:
            df = pd.read_csv(target_file)
            
            # 시간 컬럼 인식 ('time' 또는 'Time')
            time_col = 'time' if 'time' in df.columns else 'Time'
            
            if time_col in df.columns:
                # 시간 변환 (GMT+Offset)
                df[time_col] = pd.to_datetime(df[time_col])
                df[time_col] = df[time_col] + pd.Timedelta(hours=offset_hours)
                
                # 컬럼 재정렬 (OCHL 요청 시: Time, Open, Close, High, Low)
                if use_ochl:
                    # 대소문자 문제 방지를 위해 컬럼명 표준화 시도
                    df.columns = [c.lower() for c in df.columns]
                    # 필요한 컬럼만 추출 및 순서 지정
                    # duka 기본: time, open, high, low, close, volume
                    cols = ['time', 'open', 'close', 'high', 'low']
                    if 'volume' in df.columns: 
                        cols.append('volume') # Volume도 유지하는 것이 좋음, 하지만 요청은 OCHL
                    
                    # 요청사항: Time, Open, Close, High, Low 순서
                    final_cols = ['time', 'open', 'close', 'high', 'low']
                    df = df[final_cols]
                    
                    # 컬럼명 대문자화 (선택사항, MT5 호환성 위해 Time, Open...)
                    df.columns = ['Time', 'Open', 'Close', 'High', 'Low']
                
                # 포맷팅 (Time 컬럼: YYYY.MM.DD HH:MM)
                # MT5 형식에 맞게 문자열로 변환 (초 단위 제거 등)
                df['Time'] = df['Time'].dt.strftime('%Y.%m.%d %H:%M')

                # 최종 저장 경로 설정
                if output_dir_path:
                    if not os.path.exists(output_dir_path):
                        os.makedirs(output_dir_path)
                    final_filename = f"{symbol}_{start_date}_{end_date}.csv".replace("-", ".")
                    final_path = os.path.join(output_dir_path, final_filename)
                else:
                    final_path = target_file # 덮어쓰기

                df.to_csv(final_path, index=False)
                print(f"[성공] 처리 완료! 파일 위치:\n   -> {final_path}")
                
            else:
                print("[경고] 시간 컬럼을 찾지 못해 변환하지 못했습니다.")
        else:
            print("[경고] 다운로드된 파일을 찾을 수 없습니다.")
            
    except Exception as e:
        print(f"[오류] 발생: {e}")
    finally:
        # 임시 폴더 삭제
        if os.path.exists(temp_folder):
            try:
                shutil.rmtree(temp_folder)
            except:
                pass

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--symbol', type=str, default='XAUUSD')
    parser.add_argument('--days', type=int, default=10)
    parser.add_argument('--tf', type=str, default='M1')
    parser.add_argument('--offset', type=int, default=2) # 기본값 GMT+2
    parser.add_argument('--output_dir', type=str, required=False, help='Path to save the CSV file')
    parser.add_argument('--ochl', action='store_true', help='Use Time, Open, Close, High, Low format')
    parser.add_argument('--threads', type=int, default=1, help='Number of threads for downloading')
    parser.add_argument('--start_date', type=str, required=False, help='Start date (YYYY-MM-DD)')
    parser.add_argument('--end_date', type=str, required=False, help='End date (YYYY-MM-DD)')
    
    args = parser.parse_args()
    
    fetch_and_process(args.symbol, args.days, args.tf, args.offset, args.output_dir, args.ochl, args.threads, args.start_date, args.end_date)