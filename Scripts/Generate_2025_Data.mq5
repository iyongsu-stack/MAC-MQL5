//+------------------------------------------------------------------+
//|                                           Generate_2025_Data.mq5 |
//|                                     Copyright 2026, Gim Yong-Su  |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Gim Yong-Su"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

// --- Include BSP Framework ---
#include <BSPV9/ExternVariables.mqh>
#include <BSPV9/IndicatorV9.mqh>

// --- Input Parameters ---
input datetime InpStartDate = D'2025.01.01 00:00';
input datetime InpEndDate   = D'2025.12.31 23:59';
input string   InpFileName  = "TotalResult_2025.csv";

// --- Global Variables ---
int file_handle;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Starting 2025 Data Generation...");

   // 1. Open File
   file_handle = FileOpen(InpFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ",");
   if(file_handle == INVALID_HANDLE)
   {
      Print("Error opening file: ", GetLastError());
      return;
   }

   // 2. Write Header (Must match Python columns)
   FileWrite(file_handle, 
      "Time", "Open", "High", "Low", "Close",
      "BOP_Diff", "LRA_BSPScale(60)", "LRA_BSPScale(180)", 
      "QQE_TrLevel", "TDI_TrSi", "CHV_CVScale", "CSI_Scale", "ADX_Val", 
      "Label_Open_Buy" // Dummy Label for format compatibility
   );

   // 3. Load Indicators (Dummy calls to Initialize)
   // NOTE: This is a simplified script. Real indicator values need access to buffers.
   // Since Indicators are computed in OnTick of EA, a Script cannot easily access them 
   // UNLESS we use iCustom or implement the calculation logic here.
   
   // CRITICAL: Re-implementing complex BSP logic in a script is error-prone.
   // BETTER APPROACH: Use the EXISTING "DataDownLoad" EA or Script that generated 'TotalResult_Labeled.csv'
   // and just change the DATE range.
   
   Print("Requesting User to use existing Data Downloader for 2025...");
   FileClose(file_handle);
}
//+------------------------------------------------------------------+
