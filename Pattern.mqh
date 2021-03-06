//+------------------------------------------------------------------+
//|                                                      Pattern.mqh |
//|                                             Copyright 2018, DNG® |
//|                                 http://www.mql5.com/en/users/dng |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, DNG®"
#property link      "http://www.mql5.com/en/users/dng"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPattern;
class CTrends;
#include "Header.mqh"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPattern : public CObject
  {
private:
   s_Extremum     s_StartTrend;        //Trend start point
   s_Extremum     s_StartCorrection;   //Correction start point
   s_Extremum     s_EndCorrection;     //Correction end point
   s_Extremum     s_EndTrend;          //Trend completion point
   double         d_MinCorrection;     //Minimum correction
   double         d_MaxCorrection;     //Maximum correction
//---
   bool           b_found;             //"Pattern detected" flag
//---
   CTrends       *C_Trends;
public:
                     CPattern();
                    ~CPattern();
//--- Class initialization
   virtual bool      Create(CTrends *trends, double min_correction, double max_correction);
//--- Methods for searching the pattern and entry points
   virtual bool      Search(datetime start_time);
   virtual bool      CheckSignal(int &signal, double &sl, double &tp1, double &tp2);
//--- Method of comparing the objects
   virtual int       Compare(const CPattern *node,const int mode=0) const;
//---
   s_Extremum        StartTrend(void)        const {  return s_StartTrend;       }
   s_Extremum        StartCorrection(void)   const {  return s_StartCorrection;  }
   s_Extremum        EndCorrection(void)     const {  return s_EndCorrection;    }
   s_Extremum        EndTrend(void)          const {  return s_EndTrend;         }
   virtual datetime  EndTrendTime(void)            {  return s_EndTrend.TimeStartBar;  }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPattern::CPattern() :  d_MinCorrection(0.236),
                        d_MaxCorrection(0.5),
                        b_found(false),
                        C_Trends(NULL)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPattern::~CPattern()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPattern::Create(CTrends *trends,double min_correction,double max_correction)
  {
   if(CheckPointer(trends)==POINTER_INVALID)
      return false;
//---
   C_Trends=trends;
   b_found=false;
   s_StartTrend.Clear();
   s_StartCorrection.Clear();
   s_EndCorrection.Clear();
   s_EndTrend.Clear();
   d_MinCorrection=min_correction;
   d_MaxCorrection=max_correction;
//---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPattern::Search(datetime start_time)
  {
   if(CheckPointer(C_Trends)==POINTER_INVALID || C_Trends.Total()<4)
      return false;
//---
   int start=C_Trends.ExtremumByTime(start_time);
   if(start<0)
      return false;
//---
   b_found=false;
   for(int i=start;i>=0;i--)
     {
      if((i+3)>=C_Trends.Total())
         continue;
      if(!C_Trends.Extremum(s_StartTrend,i+3) || !C_Trends.Extremum(s_StartCorrection,i+2) ||
         !C_Trends.Extremum(s_EndCorrection,i+1) || !C_Trends.Extremum(s_EndTrend,i))
         continue;
//---
      double trend=s_StartCorrection.Price-s_StartTrend.Price;
      double correction=s_StartCorrection.Price-s_EndCorrection.Price;
      double re_trial=s_EndTrend.Price-s_EndCorrection.Price;
      double koef=correction/trend;
      if(koef<d_MinCorrection || koef>d_MaxCorrection || (1-fmin(correction,re_trial)/fmax(correction,re_trial))>=d_MaxCorrection)
         continue;
      b_found= true; 
//---
      break;
     }
//---
   return b_found;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPattern::CheckSignal(int &signal, double &sl, double &tp1, double &tp2)
  {
   if(!b_found)
      return false;
//---
   string symbol=C_Trends.Symbol();
   if(symbol=="Not Initilized")
      return false;
   datetime start_time=s_EndTrend.TimeStartBar+PeriodSeconds(C_Trends.Timeframe());
   int shift=iBarShift(symbol,e_ConfirmationTF,start_time);
   if(shift<0)
      return false;
   MqlRates rates[];
   int total=CopyRates(symbol,e_ConfirmationTF,0,shift+1,rates);
   if(total<=0)
      return false;
//---
   signal=0;
   sl=tp1=tp2=-1;
   bool up_trend=C_Trends.IsHigh(s_EndTrend);
   double extremum=(up_trend ? fmax(s_StartCorrection.Price,s_EndTrend.Price) : fmin(s_StartCorrection.Price,s_EndTrend.Price));
   double exit_level=2*s_EndCorrection.Price- extremum;
   bool break_neck=false;
   for(int i=0;i<total;i++)
     {
      if(up_trend)
        {
         if(rates[i].low<=exit_level || rates[i].high>extremum)
            return false;
         if(!break_neck)
           {
            if(rates[i].close>s_EndCorrection.Price)
               continue;
            break_neck=true;
            continue;
           }
         if(rates[i].high>s_EndCorrection.Price)
           {
            if(sl==-1)
               sl=rates[i].high;
            else
               sl=fmax(sl,rates[i].high);
           }
         if(rates[i].close<s_EndCorrection.Price || sl==-1)
            continue;
         if((total-i)>2)
            return false;
//---
         signal=-1;
         double top=fmax(s_StartCorrection.Price,s_EndTrend.Price);
         tp1=s_EndCorrection.Price-(top-s_EndCorrection.Price)*0.9;
         tp2=top-(top-s_StartTrend.Price)*0.9;
         tp1=fmax(tp1,tp2);
         break;
        }
      else
        {
         if(rates[i].high>=exit_level || rates[i].low<extremum)
            return false;
         if(!break_neck)
           {
            if(rates[i].close<s_EndCorrection.Price)
               continue;
            break_neck=true;
            continue;
           }
         if(rates[i].low<s_EndCorrection.Price)
           {
            if(sl==-1)
               sl=rates[i].low;
            else
               sl=fmin(sl,rates[i].low);
           }
         if(rates[i].close>s_EndCorrection.Price || sl==-1)
            continue;
         if((total-i)>2)
            return false;
//---
         signal=1;
         double down=fmin(s_StartCorrection.Price,s_EndTrend.Price);
         tp1=s_EndCorrection.Price+(s_EndCorrection.Price-down)*0.9;
         tp2=down+(s_StartTrend.Price-down)*0.9;
         tp1=fmin(tp1,tp2);
         break;
        }
     }   
//---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CPattern::Compare(const CPattern *node,const int mode=0) const
  {
   if(s_StartTrend.TimeStartBar>node.StartTrend().TimeStartBar)
      return -1;
   else
      if(s_StartTrend.TimeStartBar<node.StartTrend().TimeStartBar)
         return 1;
//---
   if(s_StartCorrection.TimeStartBar>node.StartCorrection().TimeStartBar)
      return -1;
   else
      if(s_StartCorrection.TimeStartBar<node.StartCorrection().TimeStartBar)
         return 1;
//---
   if(s_EndCorrection.TimeStartBar>node.EndCorrection().TimeStartBar)
      return -1;
   else
      if(s_EndCorrection.TimeStartBar<node.EndCorrection().TimeStartBar)
         return 1;
//---
   return 0;
  }
//+------------------------------------------------------------------+
