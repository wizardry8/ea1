//+------------------------------------------------------------------+
//|                                   MQLTUTORIALBASICSbollinger.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
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
  MqlRates PriceInfo[];
  ArraySetAsSeries(PriceInfo, true);
 
  int PriceData = CopyRates(_Symbol,_Period,0,3,PriceInfo);
 
  string ChartSignal="", EURUSDSignal="";
 
  double EMA20Array[],EMAEURUSD20Array[];
 
  //EMA
  int EMA20Definition = iMA(_Symbol,_Period,20,0,MODE_EMA,PRICE_CLOSE);
  /// EMA EURUSD
  int EMAEURUSD20Definition = iMA ("EURUSD",_Period,20,0,MODE_EMA,PRICE_CLOSE);
  
  ArraySetAsSeries(EMA20Array,true);
  ArraySetAsSeries(EMAEURUSD20Array,true);
  
  CopyBuffer(EMA20Definition,0,0,3,EMA20Array);
  CopyBuffer(EMAEURUSD20Definition,0,0,3,EMAEURUSD20Array);
  
  if(EMA20Array[0]>EMA20Array[2]){
    ChartSignal="buy";
  }
  if(EMA20Array[0]<EMA20Array[2]){
    ChartSignal="sell";
  }

  if(EMAEURUSD20Array[0]>EMAEURUSD20Array[2]){
    EURUSDSignal="buy";
  }
  if(EMAEURUSD20Array[0]<EMAEURUSD20Array[2]){
    EURUSDSignal="sell";
  }
   
  Comment(
    "EMA 20 ", _Symbol,": ",EMA20Array[0],"\n",
    "EMA 20 EURUSD: ", EMAEURUSD20Array[0], "\n",
    "TREND ", _Symbol,": ", ChartSignal,"\n",
    "TREND EURUSD: ",EURUSDSignal, "\n"
  ); 
   
   
}
//+------------------------------------------------------------------+
