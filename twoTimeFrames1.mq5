//+------------------------------------------------------------------+
//|                                               twoTimeFrames1.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

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
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
    string signal="";
    MqlRates PriceInformation[];
    
    //Sort it from current candle to oldest candle
    ArraySetAsSeries(PriceInformation, true);
    
    //Fill the array with data LR: setting order first then filling seems to be ok
    CopyRates(_Symbol, _Period, 0, 3, PriceInformation);
    
    double myMovingAverageArray[];
    
    int movingAverageDefinition = iMA(_Symbol,_Period,1,20,MODE_SMA, PRICE_CLOSE);
    
    ArraySetAsSeries(myMovingAverageArray, true);
    
    CopyBuffer(movingAverageDefinition,0,0,3,myMovingAverageArray);
    
    //calculate EA for the current candle
    double myMovingAverageValue = myMovingAverageArray[0];
    if(myMovingAverageValue < PriceInformation[0].close){
      signal = "buy";
    }
    
    if(myMovingAverageValue > PriceInformation[0].close){
      signal = "sell";
    }
      
    //Sell 10 Microlot
    if(signal == "sell" && PositionsTotal() < 1){
      trade.Sell(0.10, NULL, Bid, (Bid + 150 * _Point), Bid - 300 * _Point, NULL);
    }
    //or buy 10 Microlot
    if(signal == "buy" && PositionsTotal() < 1){
      trade.Buy(0.10, NULL, Ask, (Ask - 150 * _Point), Bid + 300 * _Point, NULL);
    }
    
    Comment("The signal is now: ", signal);
    
   
    
    
  }
//+------------------------------------------------------------------+

void CheckTrailingStop(double Ask){
  //set the desired Stop Loss to 150 Points
  double SL = NormalizeDouble(Ask-150 * _Point, _Digits);
  for(int i = PositionsTotal() - 1; i >= 0; i--){
    string symbol = PositionGetSymbol(i);
    if(_Symbol == symbol){
      ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
      double CurrentStopLoss = PositionGetDouble(POSITION_SL);
      
      if(CurrentStopLoss < SL){
        //Modify Stop loss by 10 Points
        trade.PositionModify(PositionTicket,(CurrentStopLoss + 10 * _Point),0);
      }
    } //End symbol if loop
  } //End all open positions loop
}