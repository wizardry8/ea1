//+------------------------------------------------------------------+
//|                                                MQL5Tutorial1.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
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

         MqlTick last_tick;
         SymbolInfoTick(_Symbol, last_tick);
         double Ask = last_tick.ask;
         double Bid = last_tick.bid;

   string signal = CheckEntry();
   if(signal == "buy"){
     trade.Buy(0.10, NULL, Ask, Ask - 500 * _Point, Ask + 500 * _Point, NULL);
   }
   else if(signal == "sell"){
     trade.Sell(0.10, NULL, Bid, Bid + 500*_Point, Bid - 500 *_Point, NULL);
   }
   
  }
//+------------------------------------------------------------------+

string CheckEntry(){
  string signal = "";
  
  double KArray[];
  double DArray[];
  
  ArraySetAsSeries(KArray, true);
  ArraySetAsSeries(DArray, true);
  
  int StochasticDefinition = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,STO_LOWHIGH);
  
  CopyBuffer(StochasticDefinition,0,0,3,KArray);
  CopyBuffer(StochasticDefinition,1,0,3,DArray);
  
  double KValue0 = KArray[0];
  double DValue0 = DArray[0];
  
  double KValue1 = KArray[1];
  double DValue1 = DArray[1];
  
  if(KValue0 < 20 && DValue0 < 20){
    //K value has crossed the D value from below
    if((KValue0 > DValue0) && (KValue1 < DValue1)){
      signal = "buy";
    }
  }
  else if(KValue0 > 80 && DValue0 > 80){
    //K value has crossed the D value from above
    if((KValue0 < DValue0) && (KValue1 > DValue1)){
      signal = "sell";
    }
  
  }
  
  return signal;
  
}

