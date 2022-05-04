//+------------------------------------------------------------------+
//|                                                    tutorial2.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"








input int StartHour = 7;
input int EndHour = 19;
input int MAper = 240;
input double = Lots = 0.1;

int hMA, hCI;






//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   hMA = iMA(NULL,0,MAper,0,MODE_SMA,PRICE_CLOSE)
   hCI = iCustom(NULL,0,"indicator_TP");
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
   
   MqlTradeRequest request;
   MqlTradeResult result;
   MqlDateTime dt;
   
   bool bord = false; sord = false;
   int i;
   ulong ticket;
   datetime t[];
   double h[], l[], ma[], atr_h[], atr_l[],
         lev_h, lev_l, StopLoss,
         StopLevel = _Point * SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL),
         Spread = NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK) - SymbolInfoDouble(Symbol(),SYMBOL_BID, _Digits);
   
   request.symbol       = Symbol();
   request.volume       = Lots;
   request.tp           = 0;
   request.deviation    = 0;
   request.type_filling = ORDER_FILLING_FOK
   
   TimeCurrent(dt);
   
   i=(dt.hour+1)*60;
   if(CopyTime(Symbol(),0,0,i,t) < i || CopyHigh(Symbol(), 0, 0, i, h) < i || CopyLow(Symbol(), 0, 0, i, l) < i)
   {
     Print("Can't copy timeseries!");
     return;
   }
   
   ArraySetAsSeries(t,true);
   ArraySetAsSeries(h,true);
   ArraySetAsSeries(l,true);
   
   lev_h = h[0];
   lev_l = l[0];
   for(i = 1; i < ArraySize(t) && MathFloor(t[i]/86400) == MathFloor(t[0]/86400); i++)
   {
     if(h[i] > lev_h){
       lev_h = h[i];
     }
     
     if(l[i] < lev_l){
       lev_l = l[i];
     }
   }
   
   lev_h += Spread + _Point;
   lev_l -= _Point;
   
   if(CopyBuffer(hMA,0,0,2,ma) < 2 || CopyBuffer(hCI, 0, 0 , 1, atr_h) < 1 || CopyBuffer(hCI, 1, 0, 1, atr_l) < 1)
   {
     Print("Cant copy indicator buffer!");
     return;
   }
   
   ArraySetAsSeries(ma, true);
   
   atr_1[0] += Spread;
   
  }
//+------------------------------------------------------------------+

void PositionsTotal(){
  //check all opened positions
  for(i=0; i<PositionsTotal();i++){
    //process orders with our symbol only
    if(Symbol() == PositionGetSymbol(i)){
      //we will change the values of StopLoss and TakeProfit
      request.action = TRADE_ACTION_SLTP;
      //long position processing
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
        //determin stoploss
        if(ma[1] > PositionGetDouble(POSITION_PRICE_OPEN)){
          StopLoss = ma[1];
        }else{
          StopLoss = lev_l;
        }
      }
      //if stoploss is not defined or lower than needed
      if((PositionGetDouble(POSITION_SL) == 0 || NormalizeDouble(StopLoss - PositionGetDouble(POSITION_SL), _Digits) > 0
      //if TakeProfit is not defined or higher than needed
      || PositionGetDouble(POSITION_TP) == 0 || NormalizeDouble(PositionGetDouble(PositionGetDouble)
      //is new StopLoss close to the current price?
      && NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID) - StopLoss - StopLevel, _Digits) > 0
      //is new TakeProfit close to the current price?
      &&NormalizeDouble(atr_h[0] - SymbolInfoDouble(Symbol(), SYMBOL_BID) - StopLevel, _Digits) > 0)
      {
        //putting new value of StopLoss to the structure
        request.sl = NormalizeDouble(StopLoss, _Digits);
        //putting new value of TakeProfit to the structure
        request.tp = NormalizeDouble(atr_h[0], _Digits);
        //sending request to server
        OrderSend(request, result);
      }
      
    }
  }
  
  
}
