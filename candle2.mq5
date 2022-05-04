//+------------------------------------------------------------------+
//|                                                      candle2.mq5 |
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
   Print("booting up ea");
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

  MqlRates bar[];
  ArraySetAsSeries(bar, true);
  CopyRates(_Symbol, _Period, 0, 3, bar);
  //double open = bar[1].open;
  //double close = bar[1].close;

  double close[];
  ArraySetAsSeries(close, true);
  CopyClose(_Symbol,_Period,0,3,close);

  double high[];
  ArraySetAsSeries(high,true);
  CopyHigh(_Symbol,_Period,0,3,high);

  double low[];
  ArraySetAsSeries(low,true);
  CopyLow(_Symbol,_Period,0,3,low);

  double open[];
  ArraySetAsSeries(open,true);
  CopyOpen(_Symbol,_Period,0,3,open);

  //Print("close: " + close[1] + " open: " + open[1]);

  //hammer and hanging man candlestick pattern
  double body = MathAbs(close[1] - open[1]);
  
  //Print("body is: " + body);
  
  //define the upper shadow
  double UpperShadow; 
  if(close[1] > open[1]){
    UpperShadow = high[1] - close[1];
  }
  else{
    UpperShadow = high[1] - open[1];  
  }
  
  //define lower shadow of the candlestick
  double LowerShadow;
  if(close[1] > open[1]){
    LowerShadow = open[1] - low[1];
  }else{
    LowerShadow = close[1] - low[1];
  }

  //define the hammer and the hanging man pattern
  //Print("lower shadow > 2 * body && upper shadow < 0.1 * body");
  Print(LowerShadow + " > " + (2 * body) + " && " + UpperShadow + " < " + (0.1 * body));
  //if(LowerShadow > 2 * body && UpperShadow < 0.1 * body){
  if(LowerShadow < 2 * body && UpperShadow > 0.1 * body){
    Print("Hammer and the Hanging man pattern detected at time: " + TimeCurrent());
  }
  else{
    //Print("found nothing");
  }


//definition of SymbolInfoTick
//bool SymbolInfoTick(string symbol, MqlTick& tick);
//MqlTick price;
//SymbolInfoTick(_Symbol, price);
//double ask = price.ask;
//double bid = price.bid;
//datetime time = price.time;

}
//+------------------------------------------------------------------+
