//+------------------------------------------------------------------+
//|                                                       stoch3.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

CTrade trade;
double g_arrow_counter;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   g_arrow_counter = 0;
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
   
   string signal="";
   
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   
   //set up low stoch
   double KArray_low[];
   double DArray_low[];
   
   ArraySetAsSeries(KArray_low,true);
   ArraySetAsSeries(DArray_low,true);
   
   int StochasticLowDefinition=iStochastic(_Symbol,PERIOD_M30,5,3,3,MODE_SMA,STO_LOWHIGH);
   
   CopyBuffer(StochasticLowDefinition,0,0,3,KArray_low);
   CopyBuffer(StochasticLowDefinition,1,0,3,DArray_low);
   
   double KValue0_low=KArray_low[0];
   double DValue0_low=DArray_low[0];
   
   double KValue1_low=KArray_low[1];
   double DValue1_low=DArray_low[1];
   
   //set up high stoch
   double KArray_high[];
   double DArray_high[];
   
   ArraySetAsSeries(KArray_high,true);
   ArraySetAsSeries(DArray_high,true);
   
   int StochasticHighDefinition = iStochastic(_Symbol,PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH);
   
   CopyBuffer(StochasticHighDefinition,0,0,3,KArray_high);
   CopyBuffer(StochasticHighDefinition,1,0,3,DArray_high);
   
   double KValue0_high=KArray_high[0];
   double DValue0_high=DArray_high[0];
   
   double KValue1_high=KArray_high[1];
   double DValue1_high=DArray_high[1];
   
   
   //Entry signal
   if(KValue0_low < 20 && DValue0_low < 20 && KValue0_high > DValue0_high && KValue0_high < 80 && DValue0_high < 80){
     if((KValue0_low > DValue0_low) && (KValue1_low < DValue1_low)){
       signal = "buy";
     }
   }
   
   if(KValue0_low > 80 && DValue0_low > 80 && KValue0_high < DValue0_high && KValue0_high > 20 && DValue0_high > 20){
     if((KValue0_low < DValue0_low) && (KValue1_low > DValue1_low)){
       signal = "sell";
     }
   }
   
   
   if(signal == "sell" && PositionsTotal()<1){
     trade.Sell(0.01,NULL,Bid,Bid+250*_Point,(Bid-500*_Point),NULL);
     drawEntry(Bid, false);
   }
   else if(signal == "buy" && PositionsTotal()<1){
     trade.Buy(0.01,NULL,Ask,Ask-250*_Point,(Ask+500*_Point),NULL);
     drawEntry(Ask, true);
   }
 }
  
 void drawEntry(double price, bool direction_up){

  ObjectCreate(_Symbol,g_arrow_counter,OBJ_ARROW,0,TimeCurrent(),price);
  if(direction_up){
    //ObjectSetInteger(0,"entry",OBJPROP_ARROWCODE,33);
    ObjectSetInteger(0,g_arrow_counter,OBJPROP_ARROWCODE,225);
  }
  else{
    //ObjectSetInteger(0,"entry",OBJPROP_ARROWCODE,34);
    ObjectSetInteger(0,g_arrow_counter,OBJPROP_ARROWCODE,226);
  }
  
  ObjectSetInteger(0,g_arrow_counter,OBJPROP_WIDTH,5);
  Print("arrow added at " + TimeCurrent());
  g_arrow_counter++;
}




//+------------------------------------------------------------------+

/*
void OnTick()
  {
//---
   
   string signal="";
   
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   
   double KArray[];
   double DArray[];
   
   ArraySetAsSeries(KArray,true);
   ArraySetAsSeries(DArray,true);
   
   int StochasticDefinition=iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,STO_LOWHIGH);
   
   CopyBuffer(StochasticDefinition,0,0,3,KArray);
   CopyBuffer(StochasticDefinition,1,0,3,DArray);
   
   double KValue0=KArray[0];
   double DValue0=DArray[0];
   
   double KValue1=KArray[1];
   double DValue1=DArray[1];
   
   if(KValue0 < 20 && DValue0 < 20){
     if((KValue0 > DValue0) && (KValue1 < DValue1)){
       signal = "buy";
     }
   }
   
   if(KValue0 > 80 && DValue0 > 80){
     if((KValue0 < DValue0) && (KValue1 > DValue1)){
       signal = "sell";
     }
   }
   
   
   if(signal == "sell" && PositionsTotal()<1){
     trade.Sell(0.01,NULL,Bid,Bid+250*_Point,(Bid-500*_Point),NULL);
     drawEntry(Bid, false);
   }
   else if(signal == "buy" && PositionsTotal()<1){
     trade.Buy(0.01,NULL,Ask,Ask-250*_Point,(Ask+500*_Point),NULL);
     drawEntry(Ask, true);
   }
   
   
 }
*/

