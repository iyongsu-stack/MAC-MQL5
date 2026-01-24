//+------------------------------------------------------------------+
//|                                           ShowTradingHistory.mq5 |
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
  
// 다운로드 받은 파일을 읽으면 처음 케리터를 잘못 읽는다. 따라서 다운로드 받아서 filename.csv 파일로 카피-> 페이스 해야 된다.    
  CDKSimplestCSVReader CSVFile; // Create class object
  
  // Read file pass FILE_ANSI for ANSI files or another flag for another codepage.
  // Give values separator and flag of 1sr line header in the file
  if (CSVFile.ReadCSV(Filename, FILE_ANSI, ";", true)) 
  {
    PrintFormat("Successfully read %d lines from CSV file with %d columns: %s",
                CSVFile.RowCount(),     // Return data lines count without header
                CSVFile.ColumnCount(),  // Retuen columns count from 1st line of the file
                Filename);
/*    
    // Print all columns of the file from 1st line
    for (uint i = 0; i < CSVFile.ColumnCount(); i++) 
    {  
      PrintFormat("  Column Index=#%d; Name=%s", i, CSVFile.GetColumn(i));
    }        
                
    // Print values from all rows
    for (uint i = 0; i < CSVFile.RowCount(); i++) {
    {
      datetime InTime = StringToTime(CSVFile.GetValue(i, "InTime"));
      PrintFormat("Row %d: Value by column name: CSVFile.GetValue(i, ""InTime"")=%s", i, TimeToString(InTime) ); // Get value from i line by column name
      PrintFormat("Row %d: Value by column index: CSVFile.GetValue(i, 0)=%s", i, CSVFile.GetValue(i, 0));            // Get value from i line by column index
    } 
*/
          
  }
  else
    PrintFormat("Error reading CSV file or file has now any rows: %s", Filename);
  
  ObjectsDeleteAll(0, -1, -1);
  
  datetime chartStartTime = iTime(Symbol(), PERIOD_CURRENT, iBars(Symbol(), 0)-1 );
//  PrintFormat( "Bar Number: %d, cahrtStartTime: %s", iBars(Symbol(), 0)-1, TimeToString(chartStartTime) );
  
  for(uint i=0; i < CSVFile.RowCount(); i++)
  {
     datetime inDealTime = StringToTime(CSVFile.GetValue(i, "InTime")), outDealTime = StringToTime(CSVFile.GetValue(i, "OutTime"));
     string dealSymbol= StringSubstr(CSVFile.GetValue(i, "Symbol"), 0, 6);
     double inDealPrice = StringToDouble(CSVFile.GetValue(i, "InPrice")), outDealPrice = StringToDouble(CSVFile.GetValue(i, "OutPrice"));
     string inDealType = CSVFile.GetValue(i, "InType");

     if(  (inDealTime <= chartStartTime) || (outDealTime > TimeCurrent()) ) 
     {
         PrintFormat( "Time is Wrong" );
         continue;
     } 

     string tempSymbol = Symbol();
     if(dealSymbol != Symbol() ) 
     {
         PrintFormat( "Symbol is %s", dealSymbol );
         continue;
     }    
  
     // 거래 타입에 따라 객체 이름 생성
     string inArrowName, outArrowName, lineName;
     
     if( inDealType == "Buy" ) 
     {
         inArrowName = StringFormat("Buy-%d", i);
         outArrowName = StringFormat("OutBuy-%d", i);
         lineName = StringFormat("BuyProfit-%d; %s", i, DoubleToString((outDealPrice-inDealPrice), Digits()));
         
         if(!ArrowBuyCreate(inArrowName, inDealTime, inDealPrice)) 
             PrintFormat("[Buy] 진입 화살표 생성 실패 (Row %d): Error %d", i, GetLastError());
      
         if(!ArrowSellCreate(outArrowName, outDealTime, outDealPrice)) 
             PrintFormat("[Buy] 청산 화살표 생성 실패 (Row %d): Error %d", i, GetLastError()); 
      
         if(!ArrowedLineCreate(lineName, inDealTime, inDealPrice, outDealTime, outDealPrice)) 
             PrintFormat("[Buy] 수익선 생성 실패 (Row %d): Error %d", i, GetLastError());       
     }
     else if( inDealType == "Sell" )
     {
         inArrowName = StringFormat("Sell-%d", i);
         outArrowName = StringFormat("OutSell-%d", i);
         lineName = StringFormat("SellProfit-%d; %s", i, DoubleToString((inDealPrice-outDealPrice), Digits()));
         
         if(!ArrowSellCreate(inArrowName, inDealTime, inDealPrice)) 
             PrintFormat("[Sell] 진입 화살표 생성 실패 (Row %d): Error %d", i, GetLastError());
      
         if(!ArrowBuyCreate(outArrowName, outDealTime, outDealPrice)) 
             PrintFormat("[Sell] 청산 화살표 생성 실패 (Row %d): Error %d", i, GetLastError());    

         if(!ArrowedLineCreate(lineName, inDealTime, inDealPrice, outDealTime, outDealPrice)) 
             PrintFormat("[Sell] 수익선 생성 실패 (Row %d): Error %d", i, GetLastError());       

     }
     else 
         PrintFormat("[경고] 알 수 없는 거래 타입 (Row %d): Type = %s", i, inDealType );
  }

/*
  int i = 0;
  datetime inDealTime = StringToTime(CSVFile.GetValue(i, "InTime")), outDealTime = StringToTime(CSVFile.GetValue(i, "OutTime"));
  string dealSymbol= StringSubstr(CSVFile.GetValue(i, "Symbol"), 0, 6);
  double inDealPrice = StringToDouble(CSVFile.GetValue(i, "InPrice")), outDealPrice = StringToDouble(CSVFile.GetValue(i, "OutPrice"));
  string inDealType = CSVFile.GetValue(i, "InType");

  if(  (inDealTime <= chartStartTime) || (outDealTime > TimeCurrent()) ) PrintFormat( "Time is Wrong" );
  else PrintFormat( "Time is Right" );

  if(dealSymbol != Symbol() ) PrintFormat( "Symbol is not identical" );
  else PrintFormat( "Symbol is identical" );
  
  if( inDealType == "Buy" ) 
  {
      StringConcatenate(objectBuyName, "Buy-", IntegerToString(i));
      if(!ArrowBuyCreate(objectBuyName, inDealTime, inDealPrice)) PrintFormat("ObjectCreateError1");
      
      StringConcatenate(objectSellName, "OutBuy-", IntegerToString(i));
      if(!ArrowSellCreate(objectSellName, outDealTime, outDealPrice)) PrintFormat("ObjectCreateError2"); 
      
      StringConcatenate(objectLineName, "BuyProfit-", IntegerToString(i), "; ", DoubleToString((outDealPrice-inDealPrice), Digits())); 
      if(!ArrowedLineCreate(objectLineName, inDealTime, inDealPrice, outDealTime, outDealPrice)) PrintFormat("ObjectCreateError3");       
  }
  else if( inDealType == "Sell" )
  {
      StringConcatenate(objectBuyName, "Sell-", IntegerToString(i));
      if(!ArrowSellCreate(objectBuyName, inDealTime, inDealPrice)) PrintFormat("ObjectCreateError1");
      
      StringConcatenate(objectSellName, "OutSell-", IntegerToString(i));
      if(!ArrowBuyCreate(objectSellName, outDealTime, outDealPrice)) PrintFormat("ObjectCreateError2");    

      StringConcatenate(objectLineName, "SellProfit-", IntegerToString(i), "; ", DoubleToString((inDealPrice-outDealPrice), Digits())); 
      if(!ArrowedLineCreate(objectLineName, inDealTime, inDealPrice, outDealTime, outDealPrice)) PrintFormat("ObjectCreateError3");       
  
  }
  else PrintFormat("Not Deal Type, Type is %S", inDealType );
*/
              
}
