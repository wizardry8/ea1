//+------------------------------------------------------------------+
//|                                               2timeframeMACD.mq5 |
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
   MqlRates price_array[];
   ArraySetAsSeries(price_array,true);
   int Data = CopyRates(Symbol(),Period(),0,3,price_array);

   //CopyBuffer(StochasticLowDefinition,0,0,3,KArray_low);
   //CopyBuffer(StochasticLowDefinition,1,0,3,DArray_low);


   //macd fast -> entry when crossing the zero line (middle straight horizontal line))
   double macd_array_fast_main_line[];
   ArraySetAsSeries(macd_array_fast_main_line,true);
   double macd_array_fast_signal_line[];
   ArraySetAsSeries(macd_array_fast_signal_line,true);
   
   int macd_fast_handle = iMACD(_Symbol,PERIOD_CURRENT,12,26,9,PRICE_CLOSE);   
   CopyBuffer(macd_fast_handle,0,0,3,macd_array_fast_main_line);
   CopyBuffer(macd_fast_handle,1,0,3,macd_array_fast_signal_line);
   
   double macd_main_line = macd_array_fast_main_line[1];
   double macd_signal_line = macd_array_fast_signal_line[1];
   
   
   //debugging start
   /*
   //notice, we take the array[1] value so if we report at current candle time, we actually represent current candle -1 value
   if(time != iTime(_Symbol,PERIOD_CURRENT,0)){
    time = iTime(_Symbol,PERIOD_CURRENT,0);
    Print("Main line: " + macd_main_line); //histogram  
    Print("Signal line: " + macd_signal_line); //red dotted line
   }
   */
   //debugging end
   
   //macd slow -> exit when macd line crosses signal line
   double macd_array_slow[];
   ArraySetAsSeries(macd_array_slow,true);
   int macd_slow_handle = iMACD(_Symbol,PERIOD_CURRENT,19,39,9,PRICE_CLOSE);
   CopyBuffer(macd_slow_handle,0,0,3,macd_array_slow);
   
   bool ready = trackCandles();
   
      
   if(ready && PositionsTotal() == 0){
     string signal = "";
     signal = findEntry(price_array, macd_array_fast_main_line, macd_array_fast_signal_line);
     //Print("Signal is: " + signal);
     if(signal != ""){
       executeEntry(signal);
     }     
   }
            
   if(PositionsTotal() != 0){
     PositionSelect(_Symbol);
     Print("type: " + PositionGetInteger(POSITION_TYPE)); //this works
   /*
     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
     Print("Pos type: " + PositionGetInteger(POSITION_TYPE));
     Print("THERE IS AN OPEN BUY POSITION");
     }
   */
   }
   
   
   
  }
//+------------------------------------------------------------------+

void executeEntry(string signal){
  if(signal == "buy"){
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
    trade.Buy(0.01,NULL,Ask,Ask - 1000 * _Point, Ask + 1000 * _Point);
  }
  else if(signal == "sell"){
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
    trade.Sell(0.01,NULL,Bid,Bid + 1000 * _Point, Bid - 1000 * _Point);
  }
}

string findEntry(MqlRates& price_array[], double& macd_array_fast_main_line[], double& macd_array_fast_signal_line[]){
  if(macd_array_fast_main_line[1] < 0 && macd_array_fast_main_line[2] > 0){
    return "sell";
  }
  if(macd_array_fast_main_line[1] > 0 && macd_array_fast_main_line[2] < 0){
    return "buy";
  }
  
  return "";  
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