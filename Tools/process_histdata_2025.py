import zipfile
import os
import pandas as pd
import argparse
import shutil

def process_data(zip_path, output_dir=None):
    # 1. 파일 경로 확인
    if not os.path.exists(zip_path):
        print(f"❌ 파일을 찾을 수 없습니다: {zip_path}")
        return

    # 출력 디렉토리는 ZIP 파일 위치를 기본값으로
    base_dir = os.path.dirname(zip_path)
    if output_dir:
        base_dir = output_dir
        if not os.path.exists(base_dir):
            os.makedirs(base_dir)

    print(f"압축 해제 중: {zip_path}")
    
    extracted_csv_path = None
    
    try:
        # ZIP 내 CSV 찾기 및 해제
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            # 임시 해제 말고 일단 리스트 확인
            extracted_files = zip_ref.namelist()
            target_csv = None
            for f in extracted_files:
                if f.endswith('.csv'):
                    target_csv = f
                    break
            
            if target_csv:
                zip_ref.extract(target_csv, base_dir)
                extracted_csv_path = os.path.join(base_dir, target_csv)
                print(f"압축 해제됨: {target_csv}")
            else:
                print("❌ ZIP 파일 내에 CSV가 없습니다.")
                return

    except Exception as e:
        print(f"압축 해제 오류: {e}")
        return

    if extracted_csv_path:
        print("데이터 포맷 변환 중...")
        
        try:
            # 구분자 감지
            with open(extracted_csv_path, 'r') as f:
                first_line = f.readline()
            sep = ';' if ';' in first_line else ','
            print(f"감지된 구분자: '{sep}'")
            
            # CSV 읽기 (헤더 없는 경우 처리)
            # HistData.com Generic ASCII Format:
            # DateTime, Open, High, Low, Close, Volume
            # 20250101 170000;...
            
            df = pd.read_csv(extracted_csv_path, sep=sep, header=None)
            
            # 컬럼 매핑 확인
            # 최소 5~6개 컬럼 예상
            if len(df.columns) >= 5:
                # 컬럼 순서 가정: DateTime, Open, High, Low, Close, (Volume)
                # 데이터 파싱
                
                # DateTime 처리 (YYYYMMDD HHMMSS 문자열일 경우)
                # 첫 번째 컬럼 샘플 확인
                sample_time = str(df.iloc[0, 0])
                
                # 20250101 170000 형식인지 확인
                try:
                    df['Time'] = pd.to_datetime(df[0], format='%Y%m%d %H%M%S')
                except:
                    # 다른 형식 시도 (YYYY-MM-DD HH:MM:SS)
                    try:
                        df['Time'] = pd.to_datetime(df[0])
                    except:
                        print("❌ 시간 형식을 인식할 수 없습니다.")
                        return

                df['Open'] = df[1]
                df['High'] = df[2]
                df['Low'] = df[3]
                df['Close'] = df[4]
                
                # 목표 포맷: Time, Open, Close, High, Low
                df_final = df[['Time', 'Open', 'Close', 'High', 'Low']]
                
                # Time 포맷: YYYY.MM.DD HH:MM (MT5 포맷)
                df_final['Time'] = df_final['Time'].dt.strftime('%Y.%m.%d %H:%M')
                
                # 출력 파일명 생성 (ZIP 파일명 기반)
                zip_name = os.path.basename(zip_path)
                base_name = os.path.splitext(zip_name)[0]
                # DAT_ASCII_XAUUSD_M1_2025 -> XAUUSD_2025.csv 등으로 정리되면 좋음
                # 하지만 간단히 접미사 _formatted 추가
                final_name = base_name.replace("DAT_ASCII_", "").replace("_M1", "") + "_formatted.csv"
                output_path = os.path.join(base_dir, final_name)
                
                df_final.to_csv(output_path, index=False)
                
                print(f"💾 변환 완료 및 저장: {output_path}")
                
                # 원본/임시 CSV 삭제
                try:
                    os.remove(extracted_csv_path)
                    print("임시 CSV 삭제 완료")
                except:
                    pass
                
            else:
                print(f"데이터 컬럼 형식이 예상과 다릅니다. 컬럼 수: {len(df.columns)}")
                
        except Exception as e:
            print(f"변환 오류: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='HistData ZIP Processor & Formatter')
    parser.add_argument('--zip_path', type=str, required=True, help='Path to the HistData ZIP file')
    parser.add_argument('--output_dir', type=str, help='Output directory (optional)')
    
    args = parser.parse_args()
    
    process_data(args.zip_path, args.output_dir)
