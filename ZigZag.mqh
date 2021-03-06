//+------------------------------------------------------------------+
//|                                                       ZigZag.mqh |
//|                                             Copyright 2018, DNG® |
//|                                 http://www.mql5.com/en/users/dng |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, DNG®"
#property link      "http://www.mql5.com/en/users/dng"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include "Header.mqh"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CZigZag : public CObject
  {
private:
   string            s_Symbol;            // Symbol ZigZag
   ENUM_TIMEFRAMES   e_TimeFrame;         // Timeframe ZigZag
   int               i_Depth;             // Depth ZigZag
   int               i_Deviation;         // Deviation ZigZag
   int               i_Backstep;          // Backstep ZigZag
   int               i_MaxHistory;        // Max history, bars
   s_Extremum        ZigZagBuffer[];      // Extremum buffer
   void              Calculate();
   datetime          dt_LastCalculate;
   void              AddExtremum(double value, datetime time);
//---
   int               i_total;
   double            d_Point;
   
public:
                     CZigZag();
                    ~CZigZag();
   void              Create(string symbol,int depth,int deviation,int backstep,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT);
   void              MaxHistory(int value) {i_MaxHistory=value; return;};
//---
   int               Total(void)                {  Calculate();   return i_total;   }
   double            ExtremumValue(int shift)   {  Calculate();   int pos=i_total-shift-1; if (pos>=0) return ZigZagBuffer[pos].Price; else return -1;};
   datetime          ExtremumTime(int shift)    {  Calculate();   int pos=i_total-shift-1; if (pos>=0) return ZigZagBuffer[pos].TimeStartBar; else return -1;};
   int               ExtremumByTime(datetime time);
   bool              Extremums(s_Extremum &array[],int start=0, int count=-1);
//---
   string            Symbol(void)      {  return s_Symbol;  }
   ENUM_TIMEFRAMES   Timeframe(void)   {  return e_TimeFrame;  }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CZigZag::CZigZag()   :  s_Symbol(_Symbol),
                        e_TimeFrame(PERIOD_CURRENT),
                        i_Depth(12),
                        i_Deviation(5),
                        i_Backstep(3),
                        i_MaxHistory(1000),
                        dt_LastCalculate(0),
                        i_total(0)
  {
   ArrayFree(ZigZagBuffer);
   d_Point=SymbolInfoDouble(s_Symbol,SYMBOL_POINT);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CZigZag::~CZigZag()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CZigZag::Create(string symbol,int depth,int deviation,int backstep,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   s_Symbol=symbol;
   i_Depth=depth;
   i_Deviation=deviation;
   i_Backstep=(backstep>=depth ? depth-1 : backstep);
   e_TimeFrame=timeframe;
   i_MaxHistory=0;
   dt_LastCalculate=0;
   ArrayFree(ZigZagBuffer);
   d_Point=SymbolInfoDouble(s_Symbol,SYMBOL_POINT);
   i_total=0;
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CZigZag::Calculate()
  {
   if (dt_LastCalculate>=iTime(s_Symbol,e_TimeFrame,0))
      return;
   dt_LastCalculate=iTime(s_Symbol,e_TimeFrame,0);
   int    limit=0,whatlookfor=0;
   int    back,lasthighpos=0,lastlowpos=0;
   double extremum;
   double curlow=0.0,curhigh=0.0,lasthigh=0.0,lastlow=0.0;
   int size=i_total-2;
   if (size<=0)
     {
      ArrayFree(ZigZagBuffer);
      i_total=0;
      limit=(i_MaxHistory>0 ? MathMin(iBars(s_Symbol,e_TimeFrame)-i_Depth,i_MaxHistory) : iBars(s_Symbol,e_TimeFrame)-i_Depth);
     }
   else
     {
      i_total--;
      ArrayResize(ZigZagBuffer,i_total);
      limit=iBarShift(s_Symbol,e_TimeFrame,ZigZagBuffer[size].TimeStartBar)+1;
      limit=MathMin(limit,iBars(s_Symbol,e_TimeFrame)-i_Depth);
      if (size>1)
        {
         if (ZigZagBuffer[size-1].Price<ZigZagBuffer[size].Price)
            curhigh=ZigZagBuffer[size-1].Price;
         if (ZigZagBuffer[size-1].Price>ZigZagBuffer[size].Price)
            curlow=ZigZagBuffer[size-1].Price;
        }
      if (curhigh>0)
        {
         limit=iBarShift(s_Symbol,e_TimeFrame,ZigZagBuffer[size].TimeStartBar)+1;
         whatlookfor=-1;
        }
      if (curlow>0)
        {
         limit=iBarShift(s_Symbol,e_TimeFrame,ZigZagBuffer[size].TimeStartBar)+1;
         whatlookfor=1;
        }
      if (curhigh==0 && curlow==0)
        {
         ArrayFree(ZigZagBuffer);
         i_total=0;
         limit=(i_MaxHistory>0 ? MathMin(iBars(s_Symbol,e_TimeFrame)-i_Depth,i_MaxHistory) : iBars(s_Symbol,e_TimeFrame)-i_Depth);
         whatlookfor=0;
        }
     }
//--- main loop
   double ExtHighBuffer[], ExtLowBuffer[];
   ArrayResize(ExtHighBuffer,limit+1+i_Backstep);
   ArrayResize(ExtLowBuffer,limit+1+i_Backstep);
   double low[], high[];
   limit=CopyLow(s_Symbol,e_TimeFrame,0,limit+i_Depth+1,low)-i_Depth-1;
   limit=CopyHigh(s_Symbol,e_TimeFrame,0,limit+i_Depth+1,high)-i_Depth-1;
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   for(int i=limit; i>=0; i--)
     {
      //--- find lowest low in depth of bars
      extremum=low[ArrayMinimum(low,i,i_Depth)];
      //--- this lowest has been found previously
      if(extremum==lastlow)
         extremum=0.0;
      else 
        { 
         //--- new last low
         lastlow=extremum; 
         //--- discard extremum if current low is too high
         if(low[i]-extremum>i_Deviation*d_Point)
            extremum=0.0;
         else
           {
            //--- clear previous extremums in backstep bars
            for(back=1; back<=i_Backstep; back++)
              {
               int pos=i+back;
               if(ExtLowBuffer[pos]!=0 && ExtLowBuffer[pos]>extremum)
                  ExtLowBuffer[pos]=0.0; 
              }
           }
        } 
      //--- found extremum is current low
      if(low[i]==extremum)
         ExtLowBuffer[i]=extremum;
      else
         ExtLowBuffer[i]=0.0;
      //--- find highest high in depth of bars
      extremum=high[ArrayMaximum(high,i,i_Depth)];
      //--- this highest has been found previously
      if(extremum==lasthigh)
         extremum=0.0;
      else 
        {
         //--- new last high
         lasthigh=extremum;
         //--- discard extremum if current high is too low
         if(extremum-high[i]>i_Deviation*d_Point)
            extremum=0.0;
         else
           {
            //--- clear previous extremums in backstep bars
            for(back=1; back<=i_Backstep; back++)
              {
               int pos=i+back;
               if(ExtHighBuffer[pos]!=0 && ExtHighBuffer[pos]<extremum)
                  ExtHighBuffer[pos]=0.0; 
              } 
           }
        }
      //--- found extremum is current high
      if(high[i]==extremum)
         ExtHighBuffer[i]=extremum;
      else
         ExtHighBuffer[i]=0.0;
     }
//--- final cutting 
   if(whatlookfor==0)
     {
      lastlow=0.0;
      lasthigh=0.0;  
     }
   else
     {
      lastlow=curlow;
      lasthigh=curhigh;
     }
   for(int i=limit; i>=0; i--)
     {
      switch(whatlookfor)
        {
         case 0: // look for peak or lawn 
            if(lastlow==0.0 && lasthigh==0.0)
              {
               if(ExtHighBuffer[i]!=0.0)
                 {
                  lasthigh=high[i];
                  lasthighpos=i;
                  whatlookfor=-1;
                  AddExtremum(lasthigh,iTime(s_Symbol,e_TimeFrame,i));
                 }
               if(ExtLowBuffer[i]!=0.0)
                 {
                  lastlow=low[i];
                  lastlowpos=i;
                  whatlookfor=1;
                  AddExtremum(lastlow,iTime(s_Symbol,e_TimeFrame,i));
                 }
              }
             break;  
         case 1: // look for peak
            if(ExtLowBuffer[i]!=0.0 && ExtLowBuffer[i]<lastlow && ExtHighBuffer[i]==0.0)
              {
               i_total--;
               ArrayResize(ZigZagBuffer,i_total);
               lastlowpos=i;
               lastlow=ExtLowBuffer[i];
               AddExtremum(lastlow,iTime(s_Symbol,e_TimeFrame,i));
              }
            if(ExtHighBuffer[i]!=0.0 && ExtLowBuffer[i]==0.0)
              {
               lasthigh=ExtHighBuffer[i];
               lasthighpos=i;
               AddExtremum(lasthigh,iTime(s_Symbol,e_TimeFrame,i));
               whatlookfor=-1;
              }   
            break;               
         case -1: // look for lawn
            if(ExtHighBuffer[i]!=0.0 && ExtHighBuffer[i]>lasthigh && ExtLowBuffer[i]==0.0)
              {
               i_total--;
               ArrayResize(ZigZagBuffer,i_total);
               lasthighpos=i;
               lasthigh=ExtHighBuffer[i];
               AddExtremum(lasthigh,iTime(s_Symbol,e_TimeFrame,i));
              }
            if(ExtLowBuffer[i]!=0.0 && ExtHighBuffer[i]==0.0)
              {
               lastlow=ExtLowBuffer[i];
               lastlowpos=i;
               AddExtremum(lastlow,iTime(s_Symbol,e_TimeFrame,i));
               whatlookfor=1;
              }   
            break;               
        }
     }
//--- done
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CZigZag::AddExtremum(double value, datetime time)
  {
   if (i_total==0 || (iTime(s_Symbol,e_TimeFrame,i_MaxHistory)<ZigZagBuffer[0].TimeStartBar || i_MaxHistory<=0))
      ArrayResize(ZigZagBuffer,i_total+1);
   else
     {
      int k=1;
      while (k<i_total && iTime(s_Symbol,e_TimeFrame,i_MaxHistory)<ZigZagBuffer[k].TimeStartBar)
         k++;
      for (int i=0; i<i_total-k; i++)
         {
         ZigZagBuffer[i].Price=ZigZagBuffer[i+k].Price;
         ZigZagBuffer[i].TimeStartBar=ZigZagBuffer[i+k].TimeStartBar;
         }
      i_total-=k;
     }
   ZigZagBuffer[i_total].Price=value;
   ZigZagBuffer[i_total].TimeStartBar=time;
   i_total++;
   if (ArraySize(ZigZagBuffer)>(i_total))
      ArrayResize(ZigZagBuffer,i_total);
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CZigZag::ExtremumByTime(datetime time)
  {
   Calculate();
   int result=-1;
   for(int i=0;(i<i_total && result<0);i++)
     {
      if(time==ZigZagBuffer[i].TimeStartBar)
        {
         result=i_total-i-1;
         break;
        }
     }
//---
   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CZigZag::Extremums(s_Extremum &array[],int start=0,int count=-1)
  {
   if(start<0 || count==0 || (start+fmax(count,1))>i_total)
      return false;
//---
   if(count<0)
      count=i_total-start;
   if(ArraySize(array)!=count && ArrayResize(array,count)!=count)
      return false;
//---
   for(int i=0;i<count;i++)
     {
      int ii=i_total-i-1;
      if(ii<0 || ii>=i_total)
         continue;
     //---
      array[i].TimeStartBar=ZigZagBuffer[ii].TimeStartBar;
      array[i].Price=ZigZagBuffer[ii].Price;
     }
//---
   return true;
  }
//+------------------------------------------------------------------+