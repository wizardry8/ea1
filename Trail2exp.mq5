//+------------------------------------------------------------------+
//|                                                    Trail2exp.mq5 |
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
  double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
  
  if(PositionsTotal() == 0){
    trade.Buy(0.10, NULL, Ask, (Ask-1000*_Point),0,NULL);
  }
  
  CheckTrailingStop(Ask);
   
  }
//+------------------------------------------------------------------+

void CheckTrailingStop(double Ask){
  //set the stop loss to 150 points
  double SL = NormalizeDouble(Ask-150 * _Point, _Digits);
  
  //go through all positions
  for(int i = PositionsTotal() - 1; i >= 0; i--){
    string symbol = PositionGetSymbol(i);
    if(_Symbol == symbol){ //check if order symbol equals current charts symbol
      
      //get ticket number
      ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
      
      //calculate the current stop loss
      double CurrentStopLoss = PositionGetDouble(POSITION_SL);
      
      //if current stop loss is more than 150 points
      if(CurrentStopLoss < SL){
        trade.PositionModify(PositionTicket,(CurrentStopLoss + 10*_Point),0);
      }
    }
  }
}
