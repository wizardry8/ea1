//+------------------------------------------------------------------+
//|                                                  supertrend1.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
    
#include <Trade/Trade.mqh>    
    
int stHandle = 0; //handle stores pointer to memory address of expert
    
MqlParam params[];

input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input double Lots = 0.1;
input int Periods = 10;
input double Multiplier = 3.0;

int open_trade = 0; //0 no trade, 1 is short, 2 is long
uint cool_down_bars = 5;
uint close_countdown = 3;

int barsTotal;


CTrade trade;
ulong positionTicket;

int OnInit(){
   
  Print("starting supertrend1 ");
  Print("Timeframe: ", Timeframe);
  
  //stHandle = iCustom(_Symbol, Timeframe, "supertrend", Periods, Multiplier);
  stHandle = iCustom(_Symbol, Timeframe, "supertrend", Periods, Multiplier);
  barsTotal = iBars(_Symbol, Timeframe); //returns amount of bars
  
        
  return(INIT_SUCCEEDED);
   
}

void OnDeinit(const int reason)
{

   
}

void OnTick(){  
  int bars = iBars(_Symbol, Timeframe);
  if(barsTotal != bars){
    barsTotal = bars;
    
    if(cool_down_bars >= 1){
      cool_down_bars -= 1;
    }    
    
    if(open_trade != 0){
      if(close_countdown > 1){
        close_countdown -= 1;
      }
      else{
        closeCurrentPosition();
        close_countdown = 3;       
      }
      
    }
    
    
    Print("cooldown_bars: ", cool_down_bars);
    
    double st[];
    CopyBuffer(stHandle,0,0,3,st);
    Comment(st[0]," ",st[1]," ", st[2]);
  
    double close1 = iClose(_Symbol, Timeframe, 1); //0 would be current bar
    double close2 = iClose(_Symbol, Timeframe, 2);
  
    //buy signal
    if(cool_down_bars < 1 && close1 > st[1] && close2 < st[0]){
      Print(__FUNCTION__," > Buy Signal ...");
      
      //check for open complentary position and close
      if(open_trade == 1 ){
        if(PositionSelectByTicket(positionTicket)){
          if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            if(trade.PositionClose(positionTicket)){
              //Print(__FUNCTION__," > Pos #",positionTicket," was closed...");
              open_trade = 0;
              cool_down_bars = 5;
            }
          }
        }
      }
      
      //open long
      if(open_trade == 0 && trade.Buy(Lots,_Symbol)){
      //if(open_trade == 0 && trade.Sell(Lots,_Symbol)){ //complementary tryout, close pos after 3 bars
        if(trade.ResultRetcode() == TRADE_RETCODE_DONE){
          positionTicket = trade.ResultOrder();
          open_trade = 1;
        }
      }
      
    //sell signal  
    }else if(cool_down_bars < 1 && close1 < st[1] && close2 > st[0]){
      Print(__FUNCTION__," > Sell Signal ...");
      
      //check for open compentary position and close
      if(open_trade == 2){
        if(PositionSelectByTicket(positionTicket)){
          if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            if(trade.PositionClose(positionTicket)){
              //Print(__FUNCTION__," > Pos #",positionTicket," was closed...");
              open_trade = 0;
              cool_down_bars = 5;
            }
          }
        }
      }
      
      //open short
      if(cool_down_bars == 0 && open_trade == 0 && trade.Sell(Lots,_Symbol)){
      //if(cool_down_bars == 0 && open_trade == 0 && trade.Buy(Lots,_Symbol)){
        if(trade.ResultRetcode() == TRADE_RETCODE_DONE){
          positionTicket = trade.ResultOrder();
          open_trade = 2;
        }
      }
    }
            
  }
}

void closeCurrentPosition(){
   if(PositionSelectByTicket(positionTicket)){
     if(trade.PositionClose(positionTicket)){
       Print(__FUNCTION__," > Pos #",positionTicket," was closed...");
       open_trade = 0;
       cool_down_bars = 5;       
     }
   }
}


/*


 //buy signal
    if(close1 > st[1] && close2 < st[0]){
      Print(__FUNCTION__," > Buy Signal ...");
      
      //check for open complentary position and close
      if(positionTicket > 0){
        if(PositionSelectByTicket(positionTicket)){
          if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            if(trade.PositionClose(positionTicket)){
              Print(__FUNCTION__," > Pos #",positionTicket," was closed...");
            }
          }
        }
      }
      
      //open long
      if(trade.Buy(Lots,_Symbol)){
        if(trade.ResultRetcode() == TRADE_RETCODE_DONE){
          positionTicket = trade.ResultOrder();
        }
      }
      
    //sell signal  
    }else if(close1 < st[1] && close2 > st[0]){
      Print(__FUNCTION__," > Sell Signal ...");
      
      //check for open compentary position and close
      if(positionTicket > 0){
        if(PositionSelectByTicket(positionTicket)){
          if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            if(trade.PositionClose(positionTicket)){
              Print(__FUNCTION__," > Pos #",positionTicket," was closed...");
            }
          }
        }
      }
      
      //open short
      if(trade.Sell(Lots,_Symbol)){
        if(trade.ResultRetcode() == TRADE_RETCODE_DONE){
          positionTicket = trade.ResultOrder();
        }
      }
    }



*/