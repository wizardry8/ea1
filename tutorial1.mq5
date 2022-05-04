//+------------------------------------------------------------------+
//|                                                    tutorial1.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

int            iMA_handle; //pointer to indicator
int            iMA_handle_2;
double         iMA_buf[]; //dynamic array for storing indicator value
double         iMA_buf_2[];
double         Close_buf[];  //dynamic array storing the closing price of each bar

string         my_symbol;
ENUM_TIMEFRAMES   my_timeframe;

CTrade         m_Trade;
CPositionInfo  m_Position;


int OnInit()
  {
//---
   my_symbol = Symbol();
   my_timeframe = Period();
   iMA_handle_2 = iMA(my_symbol,my_timeframe,20,0,MODE_EMA,PRICE_CLOSE);
   iMA_handle = iMA(my_symbol,my_timeframe,40,0,MODE_SMA,PRICE_CLOSE);
   if(iMA_handle == INVALID_HANDLE){
     Print("cant load indicator handle");
     return(-1);
   }
   ChartIndicatorAdd(ChartID(),0,iMA_handle);      //add indicator to price chart
     ChartIndicatorAdd(ChartID(),0,iMA_handle_2);
   ArraySetAsSeries(iMA_buf,true);                 //set iMA_buf array indexing as time series
   ArraySetAsSeries(iMA_buf_2,true);                 
   ArraySetAsSeries(Close_buf,true);               //set Close_buf array indexing as time series
   return(0);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
     IndicatorRelease(iMA_handle);
     ArrayFree(iMA_buf);
     ArrayFree(iMA_buf_2);
     ArrayFree(Close_buf);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int err1=0; //storing the results of woring with the indicator buffer
   int err2=0; //storing the results of working with the price chart
   
   err1 = CopyBuffer(iMA_handle,0,1,2,iMA_buf);
   err2 = CopyBuffer(iMA_handle_2,0,1,2,iMA_buf_2);
   if(err1<0 || err2<0){
     Print("failed to copy data");
   }
   
   if(iMA_buf[1] > iMA_buf_2[1] && iMA_buf[0] < iMA_buf_2[0]){
     if(m_Position.Select(my_symbol)){
       if(m_Position.PositionType() == POSITION_TYPE_SELL){
         m_Trade.PositionClose(my_symbol);                           //if sell position then close it
       }                          
       if(m_Position.PositionType() == POSITION_TYPE_BUY){
         return;    //if buy position then exit  
       }
     }
     m_Trade.Buy(0.1,my_symbol);
   }
   
   if(iMA_buf[1] < iMA_buf_2[1] && iMA_buf[0] > iMA_buf_2[0]){
     if(m_Position.Select(my_symbol)){
       if(m_Position.PositionType()==POSITION_TYPE_BUY){
         m_Trade.PositionClose(my_symbol);
       }  
       if(m_Position.PositionType()==POSITION_TYPE_SELL){
        return;
       }
     }
    m_Trade.Sell(0.1,my_symbol);   
   }
   
  }
//+------------------------------------------------------------------+
