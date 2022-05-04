//+------------------------------------------------------------------+
//|                                                    Mql5Book2.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Mql5Book\Trade.mqh>

//Globals
CTrade Trade;
bool glBuyPlaced, glSellPlaced;

//Input Vars
input double TradeVolume = 0.1;
input int StopLoss = 1000;
input int TakeProfit = 1000;
input int MAPeriod = 10;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("initialization called");
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
   
   Print("Watchdog reporting");
   
  
   
   //Trade structures
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   
   //Moving average
   double ma[];
   ArraySetAsSeries(ma, true); //vorne ist null
   
   int maHandle = iMA(_Symbol,0,MAPeriod,MODE_LWMA,0,PRICE_CLOSE);
   
   //Close price
   double close[];
   ArraySetAsSeries(close, true);
   CopyClose(_Symbol,0,0,1,close);
   
   
   //current position information
   bool openPosition = PositionSelect(_Symbol);
   long positionType = PositionGetInteger(POSITION_TYPE);
   
   double currentVolume = 0;
   if(openPosition == true){
     currentVolume = PositionGetDouble(POSITION_VOLUME);
   }
   
   //open buy market order
   if(close[0] > ma[0] && glBuyPlaced == false && (positionType != POSITION_TYPE_BUY || openPosition == false)){
     glBuyPlaced = Trade.Buy(_Symbol, TradeVolume);
               
     //Modify SL/TP
     if(glBuyPlaced == true){
       request.action = TRADE_ACTION_SLTP;
       
       do{
        Sleep(100);
       }
       while(PositionSelect(_Symbol) == false);
       
       double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
       
       double buyStopLoss = BuyStopLoss(_Symbol,StopLoss,positionOpenPrice);
       if(buyStopLoss > 0){
         request.sl = AdjustBelowStopLevel(_Symbol, buyStopLoss);
       }  
       
       double buyTakeProfit = BuyTakeProfit(_Symbol, TakeProfit, positionOpenPrice);
       if(buyTakeProfit > 0){
         request.tp = AdjustAboveStopLevel(_Symbol,buyTakeProfit);
       }
       
       if(request.sl > 0 && request.tp > 0){
         OrderSend(request, result);                
       }
       
       glSellPlaced = false;       
     }
   }  
   else if(close[0] < ma[0] && glSellPlaced == false && positionType != POSITION_TYPE_SELL){
       glSellPlaced = Trade.Sell(_Symbol,  TradeVolume);
       
       //Modify SL/TP
       if(glSellPlaced == true){
         request.action = TRADE_ACTION_SLTP;
         
         do{ 
           Sleep(100);
         }
         while(PositionSelect(_Symbol) == false);
         double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         
         double sellStopLoss = SellStopLoss(_Symbol,StopLoss,positionOpenPrice);
         if(sellStopLoss > 0){
           request.sl = AdjustAboveStopLevel(_Symbol,sellStopLoss);
         }
         double sellTakeProfit = SellTakeProfit(_Symbol,TakeProfit,positionOpenPrice);
         if(sellTakeProfit > 0){
           request.tp = AdjustBelowStopLevel(_Symbol,sellTakeProfit);
         }
         
         
         if(request.sl > 0 && request.tp > 0){
           OrderSend(request, result);           
         }
         
         glBuyPlaced = false;         
       }
     }
     
     
     
   }
   
   
  }
//+------------------------------------------------------------------+
