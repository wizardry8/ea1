//+------------------------------------------------------------------+
//|                                              zigzagFeedback1.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>


class myZZ{
protected:
  double m_adjust_point;  //3 or 5 point symbol
  CTrade m_trade;         //trading object
  CSymbolInfo m_symbol; //symbol info object
  CPositionInfo m_position;   //trade position object
  CAccountInfo m_account;  //account info wrapper
  
  //---indicators
  int m_handle_zz;   //zig zag indicator handle
  int m_handle_ema;  //moving average indicator handle
  
  //--indicator buffers
  double m_buff_zz[];   //zig zag buffer
  double m_buff_EMA[];  //ema indicator buffer
  //--indicator data for processing
  double m_ema_current;
  double m_ema_previous;

public:
   myZZ(void);
   ~myZZ(void);
  bool   Init(void);
  void   Deinit(void);
  bool   Processing(void);
  
protected:
  bool   InitCheckParameters(const int digits_adjust);
  bool   InitIndicators(void);
  bool   LongOpened(void);
  bool   ShortOpened(void);
    
};

//global expert
myZZ ea_instance;

myZZ::~myZZ(void){
}

myZZ::myZZ(void){
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   printf("dbf1");
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
   
  }
//+------------------------------------------------------------------+
