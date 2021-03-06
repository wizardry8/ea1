//+------------------------------------------------------------------+
//|                                                       Trends.mqh |
//|                                             Copyright 2018, DNG® |
//|                                 http://www.mql5.com/en/users/dng |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, DNG®"
#property link      "http://www.mql5.com/en/users/dng"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CZigZag;
#include "Header.mqh"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTrends : public CObject
  {
private:
   CZigZag          *C_ZigZag;         // Link to the ZigZag indicator object
   s_Extremum        Trends[];         // Array of extremums
   int               i_total;          // Total number of saved extremums
   double            d_MinCorrection;  // Minimum movement value for trend continuation

public:
                     CTrends();
                    ~CTrends();
//--- Class initialization method
   virtual bool      Create(CZigZag *pointer, double min_correction);
//--- Get info on the extremum
   virtual bool      IsHigh(s_Extremum &pointer) const;
   virtual bool      Extremum(s_Extremum &pointer, const int position=0);
   virtual int       ExtremumByTime(datetime time);
//--- Get general info
   virtual int       Total(void)          {  Calculate(); return i_total;   }
   virtual string    Symbol(void) const   {  if(CheckPointer(C_ZigZag)==POINTER_INVALID) return "Not Initilized"; return C_ZigZag.Symbol();  }
   virtual ENUM_TIMEFRAMES Timeframe(void) const   {  if(CheckPointer(C_ZigZag)==POINTER_INVALID) return PERIOD_CURRENT; return C_ZigZag.Timeframe();  }
   
protected:
   virtual bool      Calculate(void);
   virtual bool      AddTrendPoint(s_Extremum &pointer);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrends::CTrends()   :  C_ZigZag(NULL),
                        i_total(0)
  {
   ArrayFree(Trends);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrends::~CTrends()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrends::Create(CZigZag *pointer, double min_correction)
  {
   if(CheckPointer(pointer)==POINTER_INVALID || min_correction<0 || min_correction>0.5)
      return false;
//---
   C_ZigZag=pointer;
   ArrayFree(Trends);
   i_total=0;
   d_MinCorrection=min_correction;
//---
   return Calculate();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrends::Calculate(void)
  {
   if(CheckPointer(C_ZigZag)==POINTER_INVALID)
      return false;
//---
   if(C_ZigZag.Total()==0)
      return true;
//---
   int start=(i_total<=0 ? C_ZigZag.Total() : C_ZigZag.ExtremumByTime(Trends[i_total-1].TimeStartBar));
   switch(start)
     {
      case 0:
        return true;
        break;
      case -1:
        start=(i_total<=1 ? C_ZigZag.Total() : C_ZigZag.ExtremumByTime(Trends[i_total-2].TimeStartBar));
        if(start<0 || ArrayResize(Trends,i_total-1)<=0)
          {
           ArrayFree(Trends);
           i_total=0;
           start=C_ZigZag.Total();
          }
        else
           i_total=ArraySize(Trends);
        if(start==0)
           return true;
        break;
     }
//---
   s_Extremum  base[];
   if(!C_ZigZag.Extremums(base,0,start))
      return false;
   int total=ArraySize(base);
   if(total<=0)
      return true;
//---
   if(i_total==0)
      if(!AddTrendPoint(base[total-1]))
         return false;
//---
   for(int i=total-1;i>=0;i--)
     {
      int trends_pos=i_total-1;
      if(Trends[trends_pos].TimeStartBar>=base[i].TimeStartBar)
         continue;
      if(IsHigh(Trends[trends_pos]))
        {
         if(IsHigh(base[i]))
           {
            if(Trends[trends_pos].Price<base[i].Price)
              {
               Trends[trends_pos].Price=base[i].Price;
               Trends[trends_pos].TimeStartBar=base[i].TimeStartBar;
              }
            continue;
           }
         else
           {
            if(trends_pos>1 && Trends[trends_pos-1].Price>base[i].Price  && Trends[trends_pos-2].Price>Trends[trends_pos].Price)
              {
               double trend=fabs(Trends[trends_pos].Price-Trends[trends_pos-1].Price);
               double correction=fabs(Trends[trends_pos].Price-base[i].Price);
               if(fabs(1-correction/trend)>d_MinCorrection)
                 {
                  Trends[trends_pos-1].Price=base[i].Price;
                  Trends[trends_pos-1].TimeStartBar=base[i].TimeStartBar;
                  i_total--;
                  ArrayResize(Trends,i_total);
                  continue;
                 }
              }
            AddTrendPoint(base[i]);
           }
        }
      else
        {
         if(!IsHigh(base[i]))
           {
            if(Trends[trends_pos].Price>base[i].Price)
              {
               Trends[trends_pos].Price=base[i].Price;
               Trends[trends_pos].TimeStartBar=base[i].TimeStartBar;
              }
            continue;
           }
         else
           {
            if(trends_pos>1 && Trends[trends_pos-1].Price<base[i].Price  && Trends[trends_pos-2].Price<Trends[trends_pos].Price)
              {
               double trend=fabs(Trends[trends_pos].Price-Trends[trends_pos-1].Price);
               double correction=fabs(Trends[trends_pos].Price-base[i].Price);
               if(fabs(1-correction/trend)>d_MinCorrection)
                 {
                  Trends[trends_pos-1].Price=base[i].Price;
                  Trends[trends_pos-1].TimeStartBar=base[i].TimeStartBar;
                  i_total--;
                  ArrayResize(Trends,i_total);
                  continue;
                 }
              }
            AddTrendPoint(base[i]);
           }
        }
     }
//---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrends::AddTrendPoint(s_Extremum &pointer)
  {
   if(ArrayResize(Trends,i_total+1)<0)
      return false;
//---
   Trends[i_total].TimeStartBar=pointer.TimeStartBar;
   Trends[i_total].Price=pointer.Price;
   i_total++;
//---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrends::IsHigh(s_Extremum &pointer) const
  {
   if(CheckPointer(C_ZigZag)==POINTER_INVALID)
      return false;
//---
   int shift=iBarShift(C_ZigZag.Symbol(),C_ZigZag.Timeframe(),pointer.TimeStartBar);
   if(shift<0)
      return false;
//---
   return (iHigh(C_ZigZag.Symbol(),C_ZigZag.Timeframe(),shift)==pointer.Price);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrends::Extremum(s_Extremum &pointer,const int position=0)
  {
   if(!Calculate() || position<0 || position>=i_total)
      return false;
   else
      pointer=Trends[i_total-position-1];
//---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CTrends::ExtremumByTime(datetime time)
  {
   Calculate();
   int result=-1;
   for(int i=0;(i<i_total && result<0);i++)
     {
      if(Trends[i].TimeStartBar>=time)
        {
         result=i_total-i-1;
         break;
        }
     }
//---
   return result;
  }
//+------------------------------------------------------------------+
