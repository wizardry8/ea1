//+------------------------------------------------------------------+
//|                                                      RsiMtf1.mq5 |
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
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   
   string signal="";
   
   double RSIArrayCurrent[], RSIArray30[], RSIArray60[];
   
   
   //CURRENT TIMEFRAME RSI
   //create indicator handle
   int RSIDefinitionCurrent = iRSI(_Symbol,_Period,14,PRICE_CLOSE);
   
   //values at front of array are the newest
   ArraySetAsSeries(RSIArrayCurrent, true);
   
   //copy latest 3 indi values to array
   CopyBuffer(RSIDefinitionCurrent,0,0,3,RSIArrayCurrent);
   
   //calc current RSI
   double RSIValueCurrent=NormalizeDouble(RSIArrayCurrent[0],2);
   
   
   //30 MIN TIMEFRAME RSI
   int RSIDefinition30 = iRSI(_Symbol,PERIOD_M30,14,PRICE_CLOSE);
   
   ArraySetAsSeries(RSIArray30, true);
   
   CopyBuffer(RSIDefinition30,0,0,3,RSIArray30);
   
   double RSIValue30 = NormalizeDouble(RSIArray30[0],2);
   
   
   //60 MIN TIMEFRAME RSI
   int RSIDefinition60 = iRSI(_Symbol,PERIOD_H1,14,PRICE_CLOSE);
   
   ArraySetAsSeries(RSIArrayCurrent,true);
   
   CopyBuffer(RSIDefinition60,0,0,3,RSIArray60);
   
   double RSIValue60 = NormalizeDouble(RSIArray60[0],2);
   
   if((RSIValueCurrent>70)&&(RSIValue30>70)&&(RSIValue60>70)){
     signal = "sell";
   }
   
   if((RSIValueCurrent<70)&&(RSIValue30<70)&&(RSIValue60<70)){
     signal = "sell";
   }
   
   if(signal == "sell" && PositionsTotal()<1){
     trade.Buy(0.1,NULL,Ask,(Ask-200 * _Point), (Ask + 400 * _Point),NULL);
   }
   if(signal == "buy" && PositionsTotal()<1){
     trade.Sell(0.1,NULL,Bid,(Bid + 200 * _Point),(Ask - 400 * _Point),NULL);
   }
   
   
   //Chart output
   Comment(
            "RSI Value CURRENT: ",RSIValueCurrent,"\n",
            "RSI Value 30 MIN: ",RSIValue30,"\n",
            "RSI Value 60 MIN: ",RSIValue60,"\n",
            "The signal is now: ",signal
            
   );
   
   
  }
//+------------------------------------------------------------------+
