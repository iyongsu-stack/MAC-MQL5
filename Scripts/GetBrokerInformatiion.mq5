//+------------------------------------------------------------------+
//|                                        GetBrokerInformatiion.mq5 |
//|                                                     Yong-su, Kim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   
   Print("Min Volume: ", min_volume);
   Print("Max Volume: ", max_volume);
   Print("Point Size: ", Point());

   
  }
//+------------------------------------------------------------------+
