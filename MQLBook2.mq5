//+------------------------------------------------------------------+
//|                                                     MQLBook2.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>

CTrade trade;

bool g_trade_open;
double g_arrow_counter;

enum last_trade_direction{
 sell,
 buy,
 unkown
};

last_trade_direction g_last_direction;

#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   g_trade_open = false;
   g_arrow_counter = 0;
   g_last_direction = unkown;
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

   if(PositionsTotal() == 0){
     g_trade_open = false;
   }
   else{
    g_trade_open = true;
   }

   


   MqlTick last_tick;
   SymbolInfoTick(_Symbol,last_tick);
   double Ask = last_tick.ask;
   double Bid = last_tick.bid;
        
   string signal = CheckEntry();
   if(signal == "buy" && g_trade_open == false){
    trade.Buy(0.01,NULL,Ask,Ask - 200 * _Point, Ask + 400 * _Point,NULL);
         drawEntry(Ask, true);
   }
   else if(signal == "sell" && g_trade_open == false){
     trade.Sell(0.01,NULL,Bid,Bid + 200 * _Point, Bid - 400 * _Point,NULL);
          drawEntry(Bid, false);
   }
   
   //Print("signal is: " + signal);
   
  }
//+------------------------------------------------------------------+

string CheckEntry(){
   string signal = "";
   double K_Array_Low[];
   double D_Array_Low[];
   double K_Array_High[];
   double D_Array_High[];
   
   
   int stoch_high_handle = iStochastic(_Symbol,PERIOD_H4,5,3,3,MODE_EMA,STO_LOWHIGH);
   //int stoch_low_handle = iStochastic(_Symbol, PERIOD_M30,5,3,3,MODE_EMA,STO_LOWHIGH);
   int stoch_low_handle = iStochastic(_Symbol, _Period,5,3,3,MODE_EMA,STO_LOWHIGH);
   
   
   CopyBuffer(stoch_high_handle,0,0,3,K_Array_High);
   CopyBuffer(stoch_high_handle,1,0,3,D_Array_High);
   
   CopyBuffer(stoch_low_handle,0,0,3,K_Array_Low);
   CopyBuffer(stoch_low_handle,1,0,3,D_Array_Low);
      

   double K_value_high_0 = K_Array_High[0];
   double D_value_high_0 = D_Array_High[0];
   double K_value_high_1 = K_Array_High[1];
   double D_value_high_1 = D_Array_High[1];
   
   double K_value_low_0 = K_Array_Low[0];
   double D_value_low_0 = D_Array_Low[0];
   double K_value_low_1 = K_Array_Low[1];
   double D_value_low_1 = D_Array_Low[1];

   
////   
/*
// stoch3 code just for comparison --begin   
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
// stoch3 code just for comparison --end   
*/
 
   //why are these results not what I would expect --begin
   // K_value_low_0 is the more recent candle and must be K_value_low_0 > D_value_low_0 for buy, thats why it worked when I jumbled the order
   //if(K_value_low_0 > 80 && D_value_low_0 > 80 && K_value_low_0 < D_value_low_0 && K_value_low_1 > D_value_low_1 && (g_last_direction == buy || g_last_direction == unkown)){
   if(K_value_low_0 > 80 && D_value_low_0 > 80 && K_value_low_0 < D_value_low_0 && K_value_low_1 > D_value_low_1){
     signal = "sell";
     g_last_direction = sell;
   }
   
   //if(K_value_low_0 < 20 && D_value_low_0 < 20 && K_value_low_0 > D_value_low_0 && K_value_low_1 < D_value_low_1 && (g_last_direction == sell || g_last_direction == unkown)){
   if(K_value_low_0 < 20 && D_value_low_0 < 20 && K_value_low_0 > D_value_low_0 && K_value_low_1 < D_value_low_1){
     signal = "buy";
     g_last_direction = buy;
   }
   //why are these results not what I would expect --end
      
   /*
   //This code behaves as intended --begin
   //if(K_value_low_0 > 80 && D_value_low_0 > 80 && K_value_low_0 < D_value_low_0 && K_value_low_1 > D_value_low_1 && (g_last_direction == buy || g_last_direction == unkown)){
   if(K_value_low_0 < 20 && D_value_low_0 < 20 && K_value_low_0 < D_value_low_0 && K_value_low_1 > D_value_low_1){
     signal = "buy";
     g_last_direction = buy;
   }
   
   //if(K_value_low_0 < 20 && D_value_low_0 < 20 && K_value_low_0 > D_value_low_0 && K_value_low_1 < D_value_low_1 && (g_last_direction == sell || g_last_direction == unkown)){
   if(K_value_low_0 > 80 && D_value_low_0 > 80 && K_value_low_0 > D_value_low_0 && K_value_low_1 < D_value_low_1){
     signal = "sell";
     g_last_direction = sell;
   }
   //This code behaves as intended --end
   */

///
   
   /*
   //double_K_value_high_0 = stoch_high_handle[]
   
   //if(K_value_high_0 < 20 && D_value_high_0 < 20 || K_value_high_0 > D_value_high_0){
   //if(K_value_high_0 < 20 && D_value_high_0 < 20){
   if(K_value_high_0 < 20 && D_value_high_0 < 20 && K_value_high_0 > D_value_high_0){
     if(K_value_low_0 > D_value_low_0 && K_value_low_1 < D_value_low_1){
         signal = "buy";
     }   
   }
   //else if(K_value_high_0 > 80 && D_value_high_0 > 80 || K_value_high_0 < D_value_high_0){
   
   //else if(K_value_high_0 > 80 && D_value_high_0 > 80 ){
   else if(K_value_high_0 > 80 && D_value_high_0 > 80 && K_value_high_0 < D_value_high_0){
     if(K_value_low_0 < D_value_low_0 && K_value_low_1 > D_value_low_1){
       signal = "sell";
     }     
   }
   */
   
   //Print("[kh0,dh0], [kh1,dh1], [kl0,dl0], [kl1,dl1]");
   //Print("[" + K_value_high_0 + "," + D_value_high_0 + "]"  +  "[" + K_value_high_1 + "," + D_value_high_1 + "]"  +  "[" + K_value_low_0 + "," + D_value_low_0 + "]"  +  "[" + K_value_low_1 + "," + D_value_low_1 + "]" );

         
         
   return signal;
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