import argparse
import os
from histdata import download_hist_data as dl
from histdata.api import Platform, TimeFrame

def fetch_histdata(pair_str, year, month=None, output_dir=None):
    # 1. 설정 (기본값: XAUUSD, M1, Generic CSV)
    # pair_str 예시: 'XAUUSD', 'EURUSD'
    
    # Pair 매핑 불필요 (라이브러리가 문자열을 직접 받음)
    target_pair = pair_str.lower()


    if not output_dir:
        output_dir = "market_data_hist"
        
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print(f"[HistData] {pair_str} ({year}년 {month if month else '전체'}) 다운로드 시작... -> {output_dir}")

    try:
        # 2. 다운로드 실행
        # month가 없으면 1년치 전체, 있으면 해당 월만 다운로드
        csv_path = dl(
            pair=target_pair,
            time_frame=TimeFrame.ONE_MINUTE, # M1 (1분봉)
            platform=Platform.GENERIC_ASCII, # CSV 형식
            year=year,
            month=month,
            output_directory=output_dir,
            verbose=True
        )
        print(f"[다운로드 완료] 파일 위치: {csv_path}")

    except Exception as e:
        print(f"[오류] 발생: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='HistData.com Downloader')
    parser.add_argument('--pair', type=str, default='XAUUSD', help='통화쌍 (XAUUSD, EURUSD)')
    parser.add_argument('--year', type=int, required=True, help='연도 (예: 2023)')
    parser.add_argument('--month', type=int, help='월 (선택사항, 없으면 1년치)')
    parser.add_argument('--output_dir', type=str, help='저장 경로')
    
    args = parser.parse_args()
    
    fetch_histdata(args.pair, args.year, args.month, args.output_dir)