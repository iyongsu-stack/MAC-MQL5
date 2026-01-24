//+------------------------------------------------------------------+
//|                                                   ReadCSVFile.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <DKSimplestCSVReader.mqh>
#include <ShowDealResult.mqh>

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   string Filename = "filename.csv";
   
   CDKSimplestCSVReader CSVFile; // Create class object
   
   // Read file pass FILE_ANSI for ANSI files or another flag for another codepage.
   // Give values separator and flag of 1st line header in the file
   if (CSVFile.ReadCSV(Filename, FILE_ANSI, ";", true))
   {
      PrintFormat("성공적으로 CSV 파일을 읽었습니다: %s", Filename);
      PrintFormat("행 수: %d, 열 수: %d", CSVFile.RowCount(), CSVFile.ColumnCount());
      
      // 기존 차트 객체 삭제
      ObjectsDeleteAll(0, -1, -1);
      
      int processedCount = 0;
      int skippedCount = 0;
      
      // CSV 데이터를 읽어서 차트에 표시
      for (uint i = 0; i < CSVFile.RowCount(); i++)
      {
         // CSV에서 데이터 읽기
         string inDealType = CSVFile.GetValue(i, "InType");
         
         // InType이 "Buy"나 "Sell"이 아니면 해당 행 무시
         if (inDealType != "Buy" && inDealType != "Sell")
         {
            skippedCount++;
            continue;
         }
         
         // 시간과 가격 데이터 읽기
         datetime inDealTime = StringToTime(CSVFile.GetValue(i, "InTime"));
         datetime outDealTime = StringToTime(CSVFile.GetValue(i, "OutTime"));
         double inDealPrice = StringToDouble(CSVFile.GetValue(i, "InPrice"));
         double outDealPrice = StringToDouble(CSVFile.GetValue(i, "OutPrice"));
         
         // 화살표 이름 생성
         string inArrowName = StringFormat("In-%d", i);
         string outArrowName = StringFormat("Out-%d", i);
         
         // InType에 따라 화살표 표시
         if (inDealType == "Buy")
         {
            // Buy 타입: InTime에 Buy 화살표, OutTime에 Sell 화살표
            if (!ArrowBuyCreate(inArrowName, inDealTime, inDealPrice))
               PrintFormat("[Buy] 진입 화살표 생성 실패 (Row %d): Error %d", i, GetLastError());
            
            if (!ArrowSellCreate(outArrowName, outDealTime, outDealPrice))
               PrintFormat("[Buy] 청산 화살표 생성 실패 (Row %d): Error %d", i, GetLastError());
         }
         else if (inDealType == "Sell")
         {
            // Sell 타입: InTime에 Sell 화살표, OutTime에 Buy 화살표
            if (!ArrowSellCreate(inArrowName, inDealTime, inDealPrice))
               PrintFormat("[Sell] 진입 화살표 생성 실패 (Row %d): Error %d", i, GetLastError());
            
            if (!ArrowBuyCreate(outArrowName, outDealTime, outDealPrice))
               PrintFormat("[Sell] 청산 화살표 생성 실패 (Row %d): Error %d", i, GetLastError());
         }
         
         processedCount++;
      }
      
      PrintFormat("처리 완료: %d개 행 표시, %d개 행 무시", processedCount, skippedCount);
   }
   else
   {
      int errorCode = GetLastError();
      PrintFormat("CSV 파일을 읽는 중 오류가 발생했습니다: %s", Filename);
      PrintFormat("오류 코드: %d", errorCode);
      PrintFormat("파일이 MQL5/Files 디렉토리에 있는지 확인하세요.");
      PrintFormat("파일 경로: %s\\MQL5\\Files\\%s", TerminalInfoString(TERMINAL_DATA_PATH), Filename);
   }
}
//+------------------------------------------------------------------+
