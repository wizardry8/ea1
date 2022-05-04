//+------------------------------------------------------------------+
//|                                                   timeBased1.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
     double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
     datetime time = TimeLocal();
     
     string hoursAndMinutes = TimeToString(time, TIME_MINUTES);
     
     if((PositionsTotal() == 0) && StringSubstr(hoursAndMinutes,0,5) == "15:00"){
       trade.Buy(0.10, NULL, Ask, (Ask-200 * _Point), (Ask+200 * _Point), NULL);
     }
     
     Comment(hoursAndMinutes);
     
  }
//+------------------------------------------------------------------+
