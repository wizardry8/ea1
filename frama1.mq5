//+------------------------------------------------------------------+
//|                                                       frama1.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

CTrade trade;
double g_symbol_counter;

int count = 0;
datetime time;

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

  string signal = "";
  
  MqlRates PriceArray[];
  ArraySetAsSeries(PriceArray,true);
  int Data = CopyRates(Symbol(),Period(),0,3,PriceArray);
  
  //frama high
  double FramaArrayHigh[];
  int FramaDefinitionHigh = iFrAMA(_Symbol,PERIOD_H8,14,0,PRICE_CLOSE);
  CopyBuffer(FramaDefinitionHigh,0,0,3,FramaArrayHigh);
  double FramaValueHigh = FramaArrayHigh[1];
  
  //frama low
  double FramaArrayLow[];
  int FramaDefinitionLow = iFrAMA(_Symbol,PERIOD_M30,14,0,PRICE_CLOSE);
  CopyBuffer(FramaDefinitionLow,0,0,3,FramaArrayLow);
  double FramaValueLow = FramaArrayLow[1];
  
  bool ready = trackCandles();  
  
  if(ready){
    signal = findEntry(PriceArray, FramaValueHigh, FramaValueLow);
    executeEntry(signal);
  }
  
  }
//+------------------------------------------------------------------+

//Arrays, structures and class objects in MQL5 are always passed as reference
string findEntry(MqlRates& PriceArray[],double FramaValueHigh, double FramaValueLow){
  string entry_direction = "";
  if(FramaValueHigh > PriceArray[1].high && FramaValueLow > PriceArray[1].high){
    entry_direction = "sell";
  }
  
  if(FramaValueHigh < PriceArray[1].low){
    entry_direction = "buy";
  }
   
  Comment("FramaValue H|L: ", FramaValueHigh, "|", FramaValueLow,"\n", "Signal: ", entry_direction); 
   
  return entry_direction;
}

void executeEntry(string signal){
  if(signal == "buy" && PositionsTotal() == 0){
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
    trade.Buy(0.01,NULL,Ask,Ask-1200*_Point,Ask+1200*_Point);    
  }
  else if(signal == "sell" && PositionsTotal() == 0){
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
    trade.Sell(0.01,NULL,Bid,Bid+1200*_Point,Bid-1200*_Point);    
  }
}

void drawEntry(double price, bool direction_up){
  ObjectCreate(_Symbol, g_symbol_counter, OBJ_ARROW,0,TimeCurrent(),price);
  if(direction_up){
    ObjectSetInteger(0,g_symbol_counter,OBJPROP_ARROWCODE,225);
  }
  else{
    ObjectSetInteger(0,g_symbol_counter,OBJPROP_ARROWCODE,226);
  }
  
  Print("arrow added at " + TimeCurrent());  
}

bool trackCandles(){

  if(count == 5){
    count = 0;
    return true;
  }
  
  if(time != iTime(Symbol(),PERIOD_CURRENT,0)){
    count++;
    time = iTime(Symbol(),PERIOD_CURRENT,0);
  }  
  return false;
}

/*
////-S
  int count=0;
datetime time;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(time!=iTime(Symbol(),PERIOD_CURRENT,0))
     {
      count++;
      time=iTime(Symbol(),PERIOD_CURRENT,0);
     }
   if(count==20)
     {
      Alert("20 new candles !");
      count=0;// reset counter
     }
  }
  ////-E
  */