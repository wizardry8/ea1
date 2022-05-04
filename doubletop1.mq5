//+------------------------------------------------------------------+
//|                                                   doubletop1.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"


struct s_Extremum
{
  datetime TimeStartBar;
  double Price;
  
  s_Extremum(void) : TimeStartBar(0), Price(0)
  {
  }
  void Clear(void)
  {
  TimeStartBar = 0;
  Price = 0;
  }
}

class CTrends : public CObject
{
private:
  CZigZag         *C_ZigZag;        //reference to ZigZag indicator object
  s_Extremum      Trends[];         //Array of extremums    
  int             i_total;          //Total number of saved extremums
  double          d_MinCorrection   //minimum movement value for trend continuation


public:
                  CTrends();
                  ~CTrends();
//-- Class initialization method
  virtual bool    Create(CZigZag *pointer, double min_correction);
//-- Get info on the extremum  
  virtual bool    IsHigh(s_Extremum &pointer) const;
  virtual bool    Extremum(s_Extremum &pointer, const int position = 0);
  virtual int     ExtremumByTime(datetime time);
//-- Get general info
  virtual int     Total(void)  {  Calculate(); return i_total;  }
  virtual string  Symbol(void) const {  if(CheckPointer(C_ZigZag)==POINTER_INVALID) return "Not initialized"; return C_ZigZag.Symbol(); }
  virtual ENUM_TIMEFRAMES Timeframe(void) const {  if(CheckPointer(C_ZigZag)==POINTER_INVALID) return PERIOD_CURRENT; return C_ZigZag.Timeframe();  }
  
protected:
  virtual bool    Calculate(void);  
  virtual bool    AddTrendPoint(s_Extremum &pointer);
  
};
  
  //check the relevance of the reference to the indicator class object and the presence of extremums found by the indicator
bool CTrends::Calculate(void){
  if(CheckPointer(C_ZigZag)==POINTER_INVALID){
    return false;
  }
  if(C_ZigZag.Total()==0)
    return true;
  
  //define the number of unprocessed extremums. If all extremums are processed, exit the method with the true result  
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
        start=C_ZigZag.Total();)
      }
      else
        i_total=ArraySize(Trends);
      if(start==0)
        return true;
      break;    
  }
  
  //request the necessary amount of extremums form the indicator class
  s_Extremum base[];
  if(!C_ZigZag.Extremums(base,0,start)){
    return false;
  }
  
  int total = ArraySize(base);
  if(total <= 0){
    return true;
  }
  
  //if there have been no extremums in the database up to this time, add the oldest extremum to the database by calling the AddTrendPoint method.
  if(i_total==0){
    if(!AddTrendPoint(base[total-1])){
      return false;
    }
  }
  
  //arrange the loop with iteration over all downloaded extremums. Previous extremums before the last saved one are skipped.
  for(int i = total-1; i >= 0; i--){
    int trends_pos=i_total-1;
    if(Trends[trends_pos].TimeStartBar >= base[i].TimeStartBar){
      contine;
    }
  }
  
  //In the next step, check if the extreme points are unidirectional. If a new extremum re-draws the previous one, update the data
  if(IsHigh(Trends[trends_pos])){
    if(IsHigh(base[i])){
      if(Trends[trends_pos].Price < base[i].Price){
        Trends[trend_pos].Price = base[i].Price;
        Trends[trend_pos].Price = TimeStartBar = base[i].TimeStartBar;
      }
      contine;
    }
    //For oppositely directed extreme points, check whether the new movement is a continuation of a previous trend.
    //if yes, update data on extrememums. If no, add data on the extremum by calling the AddTrendPoint method
    else{
      if(trends_pos > 1 && Trends[trends_pos-1].Price > base[i].Price && Trends[trends_pos-2].Price > Trends[trends_pos].Price){
        double trend = fabs(Trends[trend_pos].Price-Trends[trends_pos-1].Price);
        double correction = fabs(Trends[trends_pos].Price - base[i].Price);
        if(fabs(1 - correction/trend) > d_MinCorrection){
          Trends[trends_pos - 1].Price = base[i].Price;
          Trends[trends_pos - 1].TimeStartBar = base[i].TimeStartBar;
          i_total--;
          ArrayResize(Trends,i_total);
          continue;
        }
      }
      AddTrendPoint(base[i]);
    }
  }
  
  
}



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
