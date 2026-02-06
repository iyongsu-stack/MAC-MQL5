//+------------------------------------------------------------------+
//|                                                 DataDownLoad.mq5 |
//|                                      Copyright 2024, BSP Project |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, BSP Project"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   // 1. 심볼 및 주기 확인 (XAUUSD, M1)
   if(_Symbol != "XAUUSD")
     {
      Alert("Error: 이 스크립트는 XAUUSD 차트에서만 실행 가능합니다.");
      return;
     }

   if(_Period != PERIOD_M1)
     {
      Alert("Error: 이 스크립트는 1분(M1) 차트에서만 실행 가능합니다.");
      return;
     }



   // 3. 데이터 요청 (CopyRates)
   MqlRates rates[];
   ArraySetAsSeries(rates, false); // 시간 순서대로 정렬 (과거 -> 현재)

   int copied = CopyRates(_Symbol, _Period, 1, Bars(_Symbol, _Period)-1, rates);

   if(copied <= 0)
     {
      Alert("Error: 데이터를 가져오는데 실패했습니다. Error Code: ", GetLastError());
      return;
     }

   Print("총 ", copied, "개의 1분봉 데이터를 다운로드했습니다.");

   // 4. 파일 이름 생성 및 열기
   string fileName = "XAUUSD.csv";

   // MQL5/Files 폴더 내에 생성됨
   int fileHandle = FileOpen(fileName, FILE_WRITE | FILE_CSV | FILE_ANSI, ",");

   if(fileHandle == INVALID_HANDLE)
     {
      Alert("Error: 파일을 생성할 수 없습니다. Error Code: ", GetLastError());
      return;
     }

   // 5. 헤더 및 데이터 쓰기
   // 헤더: Time|Open|Close|High|Low
   FileWrite(fileHandle, "Time", "Open", "Close", "High", "Low");

   for(int i = 0; i < copied; i++)
     {
      // 시간 포맷: 2004.04.01.13:00 (점 구분자 사용)
      string timeStr = TimeToString(rates[i].time, TIME_DATE | TIME_MINUTES);
      StringReplace(timeStr, " ", "."); // 날짜와 시간 사이의 공백을 점(.)으로 변경

      FileWrite(fileHandle,
                timeStr,
                DoubleToString(rates[i].open, _Digits),
                DoubleToString(rates[i].close, _Digits),
                DoubleToString(rates[i].high, _Digits),
                DoubleToString(rates[i].low, _Digits));
     }

   // 6. 종료 및 알림
   FileClose(fileHandle);
   Alert("성공: 데이터 다운로드 완료! 파일명: ", fileName);
   Print("파일 저장 완료: ", fileName);
  }
//+------------------------------------------------------------------+
