//+------------------------------------------------------------------+
//|                                                    DoubleTop.mq5 |
//|                                             Copyright 2018, DNG® |
//|                                 http://www.mql5.com/en/users/dng |
//+------------------------------------------------------------------+
#include "Header.mqh"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initialize the object array
   ar_Objects=new CArrayObj();
   if(CheckPointer(ar_Objects)==POINTER_INVALID)
      return INIT_FAILED;
//--- Initialize the ZigZag indicator class
   CZigZag *zig_zag=new CZigZag();
   if(CheckPointer(zig_zag)==POINTER_INVALID)
      return INIT_FAILED;
   if(!ar_Objects.Add(zig_zag))
     {
      delete zig_zag;
      return INIT_FAILED;
     }
   zig_zag.Create(_Symbol,i_Depth,i_Deviation,i_Backstep,e_TimeFrame);
   zig_zag.MaxHistory(i_MaxHistory);
//--- Initiliaze the trend movements search class
   CTrends *trends=new CTrends();
   if(CheckPointer(trends)==POINTER_INVALID)
      return INIT_FAILED;
   if(!ar_Objects.Add(trends))
     {
      delete trends;
      return INIT_FAILED;
     }
   if(!trends.Create(zig_zag,d_MinCorrection))
      return INIT_FAILED;
//--- Initialize the trading operations class
   Trade=new CTrade();
   if(CheckPointer(Trade)==POINTER_INVALID)
      return INIT_FAILED;
   Trade.SetAsyncMode(false);
   Trade.SetDeviationInPoints(l_Slippage);
   Trade.SetTypeFillingBySymbol(_Symbol);
//--- Initialize the additional variables
   start_search=0;
   CLimitTakeProfit::OnlyOneSymbol(true);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   if(CheckPointer(ar_Objects)!=POINTER_INVALID)
     {
      for(int i=ar_Objects.Total()-1;i>=0;i--)
         delete ar_Objects.At(i);
      delete ar_Objects;
     }
   if(CheckPointer(Trade)!=POINTER_INVALID)
      delete Trade;
   if(CheckPointer(Pattern)!=POINTER_INVALID)
      delete Pattern;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   static datetime Last_CfTF=0;
   datetime series=(datetime)SeriesInfoInteger(_Symbol,e_ConfirmationTF,SERIES_LASTBAR_DATE);
   if(Last_CfTF>=series)
      return;
   Last_CfTF=series;
//---
   int total=ar_Objects.Total();
   for(int i=2;i<total;i++)
     {
      if(CheckPointer(ar_Objects.At(i))==POINTER_INVALID)
         if(ar_Objects.Delete(i))
           {
            i--;
            total--;
            continue;
           }
//---
      if(!CheckPattern(ar_Objects.At(i)))
        {
         if(ar_Objects.Delete(i))
           {
            i--;
            total--;
            continue;
           }
        }
     }
//---
   static datetime Last_WT=0;
   series=(datetime)SeriesInfoInteger(_Symbol,e_TimeFrame,SERIES_LASTBAR_DATE);
   if(Last_WT>=series)
      return;
   start_search=iTime(_Symbol,e_TimeFrame,fmin(i_MaxHistory,Bars(_Symbol,e_TimeFrame)));
   if(CheckPointer(Pattern)==POINTER_INVALID)
     {
      Pattern=new CPattern();
      if(CheckPointer(Pattern)==POINTER_INVALID)
       return;
      if(!Pattern.Create(ar_Objects.At(1),d_MinCorrection,d_MaxCorrection))
        {
         delete Pattern;
          return;
        }
     }
   Last_WT=series;
   while(!IsStopped() && Pattern.Search(start_search))
     {
      start_search=fmax(start_search,Pattern.EndTrendTime()+PeriodSeconds(e_TimeFrame));
      bool found=false;
      for(int i=2;i<ar_Objects.Total();i++)
         if(Pattern.Compare(ar_Objects.At(i),0)==0)
           {
            found=true;
            break;
           }
      if(found)
         continue;
      if(!CheckPattern(Pattern))
         continue;
      if(!ar_Objects.Add(Pattern))
         continue;
      Pattern=new CPattern();
      if(CheckPointer(Pattern)==POINTER_INVALID)
         break;
      if(!Pattern.Create(ar_Objects.At(1),d_MinCorrection,d_MaxCorrection))
        {
         delete Pattern;
         break;
        }
     }
//---
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckPattern(CPattern *pattern)
  {
   int signal=0;
   double sl=-1, tp1=-1, tp2=-1;
   if(!pattern.CheckSignal(signal,sl,tp1,tp2))
      return false;
//---
   double price=0;
   double to_close=100;
//---
   switch(signal)
     {
      case 1:
        price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        CLimitTakeProfit::Clear();
        if((tp1-price)>SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point)
           if(CLimitTakeProfit::AddTakeProfit((uint)((tp1-price)/_Point),(fabs(tp1-tp2)>=_Point ? 50 : 100)))
              to_close-=(fabs(tp1-tp2)>=_Point ? 50 : 100);
        if(to_close>0 && (tp2-price)>SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point)
           if(!CLimitTakeProfit::AddTakeProfit((uint)((tp2-price)/_Point),to_close))
              return false;
        if(Trade.Buy(d_Lot,_Symbol,price,sl-i_SL*_Point,0,NULL))
           return false;
        break;
      case -1:
        price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
        CLimitTakeProfit::Clear();
        if((price-tp1)>SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point)
           if(CLimitTakeProfit::AddTakeProfit((uint)((price-tp1)/_Point),(fabs(tp1-tp2)>=_Point ? 50 : 100)))
              to_close-=(fabs(tp1-tp2)>=_Point ? 50 : 100);
        if(to_close>0 && (price-tp2)>SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point)
           if(!CLimitTakeProfit::AddTakeProfit((uint)((price-tp2)/_Point),to_close))
              return false;
        if(Trade.Sell(d_Lot,_Symbol,price,sl+i_SL*_Point,0,NULL))
           return false;
        break;
     }
//---
   return true;
  }
//+------------------------------------------------------------------+
