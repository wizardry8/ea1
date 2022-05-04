//+------------------------------------------------------------------+
//|                                    onBalanceVolumeDivergence.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//timestampLast 29min

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>

input double Lots = 0.1;

#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


input int verificationCandles = 20;
input ENUM_APPLIED_VOLUME app_volume = VOLUME_TICK;
input int STOPL = 500;
input int TAKEP = 1000;

int total_bars;
int handleObv;
int THRESHOLD_PROXIMITY_DIVERGENCE = 5;

ulong position_ticket_long;
ulong position_ticket_short;
int long_positions;
int short_positions;

double last_long_token;
double last_short_token;

struct highs_and_lows
{
  double low1, low2, high1, high2;
  double lowObv1, lowObv2, highObv1, highObv2;
  datetime Low1Time, Low2Time, High1Time, High2Time;
  datetime LowObv1Time, LowObv2Time, HighObv1Time, HighObv2Time;
};

highs_and_lows high_and_lows_;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   total_bars = iBars(_Symbol,PERIOD_CURRENT);
   handleObv = iOBV(_Symbol,PERIOD_CURRENT,app_volume);   
   
   //int StochasticDefinition = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,STO_LOWHIGH); //LR: this loads the indicator to the window
   
   high_and_lows_.low1 = 0; high_and_lows_.low2 = 0; high_and_lows_.high1 = 0; high_and_lows_.high2 = 0;
   high_and_lows_.lowObv1 = 0; high_and_lows_.lowObv2 = 0; high_and_lows_.highObv1 = 0; high_and_lows_.highObv2 = 0;
   high_and_lows_.Low1Time = 0; high_and_lows_.Low2Time = 0; high_and_lows_.High1Time = 0; high_and_lows_.High2Time = 0;
   high_and_lows_.LowObv1Time = 0; high_and_lows_.LowObv2Time = 0; high_and_lows_.HighObv1Time = 0; high_and_lows_.HighObv2Time = 0;
   
   
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
   int bars = iBars(_Symbol,PERIOD_CURRENT);
   if(bars != total_bars){     
     total_bars = bars;
     
     double newLow = 0, newHigh = 0;
     datetime newLowTime = 0, newHighTime = 0;
     findHighLow(newLow, newLowTime, newHigh, newHighTime);
     
     double newLowObv = 0, newHighObv = 0;
     datetime newLowObvTime = 0, newHighObvTime = 0;
     findHighLowObv(newLowObv, newLowObvTime, newHighObv, newHighObvTime);    
     
     if(newLow || newLowObv){
       if(newLow > 0){
         high_and_lows_.low2 = high_and_lows_.low1;
         high_and_lows_.low1 = newLow;
		 
		   high_and_lows_.Low2Time = high_and_lows_.Low1Time;
		   high_and_lows_.Low1Time = newLowTime;
       }
       
       if(newLowObv > 0){
         high_and_lows_.lowObv2 = high_and_lows_.lowObv1;
         high_and_lows_.lowObv1 = newLowObv;
		 
		   high_and_lows_.LowObv2Time = high_and_lows_.LowObv1Time;
		   high_and_lows_.LowObv1Time = newLowObvTime;
       }
     }
     
     if(newHigh || newHighObv){
       if(newHigh > 0){
         high_and_lows_.high2 = high_and_lows_.high1;
         high_and_lows_.high1 = newHigh;
		 
		   high_and_lows_.High2Time = high_and_lows_.High1Time;
		   high_and_lows_.High1Time = newHighTime;
       }
       
       if(newHighObv > 0){
         high_and_lows_.highObv2 = high_and_lows_.highObv1;
         high_and_lows_.highObv1 = newHighObv;
		 
		   high_and_lows_.HighObv2Time = high_and_lows_.HighObv1Time;
		   high_and_lows_.HighObv1Time = newHighObvTime;		 
       }
     }
          
     //Print(high_and_lows_.low1, ", ",high_and_lows_.low2, ", ", high_and_lows_.lowObv1, ", ", high_and_lows_.lowObv2);
     
     //buy divergence
    if(high_and_lows_.low1 < high_and_lows_.low2 && high_and_lows_.lowObv1 > high_and_lows_.lowObv2){      
      checkOpenPositions();
      double this_long_token = high_and_lows_.low1;
      
      //Print("DEBUG2: openpositions: ", long_positions, " , ", short_positions);
	   if(long_positions == 0 && divergenceLinesProximity(false) && this_long_token != last_long_token){
	   //if(divergenceLinesProximity(false)){ 
	     last_long_token = high_and_lows_.low1;
	     drawBuyDivergence();     
	     //Print("BUY SIGNAL!");
	     
        CTrade trade;        
        double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
        trade.Buy(Lots, _Symbol,Ask,Ask-STOPL*_Point,Ask+TAKEP*_Point);
        if(trade.ResultRetcode() == TRADE_RETCODE_DONE){
          position_ticket_long = trade.ResultOrder();  //TODO save order position and check that only one ordre is open
          long_positions += 1;
        }                
	   }	         
    }
         
    //sell divergence
    if(high_and_lows_.high1 > high_and_lows_.high2 && high_and_lows_.highObv1 < high_and_lows_.highObv2){   
      checkOpenPositions();
      double this_short_token = high_and_lows_.high1;
      
      if(short_positions == 0 && divergenceLinesProximity(true) && this_short_token != last_short_token){
	     last_short_token = high_and_lows_.high1;
	     drawSellDivergence();
        //Print("SELL SIGNAL!");
        
        CTrade trade;
        double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
        trade.Sell(Lots, _Symbol,Bid,Bid+STOPL*_Point,Bid-TAKEP*_Point);
        if(trade.ResultRetcode() == TRADE_RETCODE_DONE){
          position_ticket_short = trade.ResultOrder();  //TODO save order position and check that only one ordre is open
          short_positions += 1;
        } 
	   }    
    }
                                        
   }//end if new bar   
  }
//+------------------------------------------------------------------+


void checkOpenPositions(){
  int temp_total_long_pos = 0;
  int temp_total_short_pos = 0;

  for(int i = 0; i < PositionsTotal(); i++){
    int ticket = PositionGetTicket(i);    
    
    if(ticket == position_ticket_long){
      temp_total_long_pos += 1;
    }
    if(ticket == position_ticket_short){
      temp_total_short_pos += 1;
    }
  }
  
  long_positions = temp_total_long_pos;
  short_positions = temp_total_short_pos;  
  Print("DEBUG: new long and short pos: ",temp_total_long_pos, " ,",temp_total_short_pos);
}

bool divergenceLinesProximity(bool high_or_lows){
  if(!high_or_lows){
    int shift_1 = iBarShift(NULL,PERIOD_CURRENT,high_and_lows_.Low1Time);
    int shift_1d = iBarShift(NULL,PERIOD_CURRENT,high_and_lows_.LowObv1Time);
    int distance_1 = shift_1 - shift_1d;
    
    int shift_2 = iBarShift(NULL,PERIOD_CURRENT,high_and_lows_.Low2Time);
    int shift_2d = iBarShift(NULL,PERIOD_CURRENT,high_and_lows_.LowObv2Time);
    int distance_2 = shift_2 - shift_2d;
  
    if( (MathAbs(distance_1) > THRESHOLD_PROXIMITY_DIVERGENCE) || (MathAbs(distance_2) > THRESHOLD_PROXIMITY_DIVERGENCE) ){
      //Print("distance 1 = ",distance_1," ,distance 2 = ",distance_2);
      return false;
    }
    Print("lows: distance 1 = ",MathAbs(distance_1)," ,distance 2 = ",MathAbs(distance_2));
    return true;
  }
  else{
    int shift_1 = iBarShift(NULL,PERIOD_CURRENT,high_and_lows_.High1Time);
    int shift_1d = iBarShift(NULL,PERIOD_CURRENT,high_and_lows_.HighObv1Time);
    int distance_1 = shift_1 - shift_1d;
    
    int shift_2 = iBarShift(NULL,PERIOD_CURRENT,high_and_lows_.High2Time);
    int shift_2d = iBarShift(NULL,PERIOD_CURRENT,high_and_lows_.HighObv2Time);
    int distance_2 = shift_2 - shift_2d;
  
    if( (MathAbs(distance_1) > THRESHOLD_PROXIMITY_DIVERGENCE) || (MathAbs(distance_2) > THRESHOLD_PROXIMITY_DIVERGENCE) ){
      //Print("distance 1 = ",MathAbs(distance_1)," ,distance 2 = ",MathAbs(distance_2));
      return false;
    }
    //Print("highs: distance 1 = ",MathAbs(distance_1)," ,distance 2 = ",MathAbs(distance_2));
    return true;  
  }  
}


void drawBuyDivergence(){
 //example draw in sub window: 
 //ObjectCreate(0,"High@"+TimeToString(time),OBJ_ARROW_SELL,1,time,value);
 
 string obj_name_1 = "buyDiv1"+TimeToString(TimeCurrent());
 string obj_name_2 = "buyDiv2"+TimeToString(TimeCurrent());
 
 //trendline price and obv
 ObjectCreate(0, obj_name_1, OBJ_TREND, 0, high_and_lows_.Low1Time, high_and_lows_.low1, high_and_lows_.Low2Time, high_and_lows_.low2);
 ObjectCreate(0, obj_name_2, OBJ_TREND, 1, high_and_lows_.LowObv1Time, high_and_lows_.lowObv1, high_and_lows_.LowObv2Time, high_and_lows_.lowObv2);
 
 
 //calc difference between two price points
 int shift_p_1 = iBarShift(NULL,PERIOD_CURRENT, high_and_lows_.Low1Time);
 int shift_p_2 = iBarShift(NULL,PERIOD_CURRENT, high_and_lows_.Low2Time);
 int diffr_p = shift_p_2-shift_p_1;
 //Print("shift_1: ",shift_p_1,"/","shift_2: ",shift_p_2);
 
 //label price point
 string difference_label_pri = "difference label price"+TimeToString(TimeCurrent());
 ObjectCreate(0,difference_label_pri,OBJ_TEXT,0,high_and_lows_.Low1Time,high_and_lows_.low1);
 ObjectSetString(0,difference_label_pri,OBJPROP_TEXT,"d:" + diffr_p);
 
 
 //calc difference between two obv points
 int shift_o_1 = iBarShift(NULL,PERIOD_CURRENT, high_and_lows_.LowObv1Time);
 int shift_o_2 = iBarShift(NULL,PERIOD_CURRENT, high_and_lows_.LowObv2Time);
 int diffr_o = shift_o_2-shift_o_1;
 
 //label obv point
 string difference_label_obv = "difference label obv"+TimeToString(TimeCurrent());
 ObjectCreate(0,difference_label_obv,OBJ_TEXT,1,high_and_lows_.LowObv1Time,high_and_lows_.lowObv1);
 ObjectSetString(0,difference_label_obv,OBJPROP_TEXT,"d:" + diffr_o);
 
 
 
 //ObjectCreate(0, difference_label, OBJ_LABEL,0,high_and_lows_.Low1Time, high_and_lows_.low1);
 
 //example calculate difference between bars:
 //ObjectSetString(0,difference_label,OBJPROP_TEXT,"buy signal"); 
      //TODO calculate distance between high and low and obv extremes print it on chart
     //int shift_1 = iBarShift("EUROUSD",PERIOD_M1,some_time1);
     //int shift_2 = iBarShift("EUROUSD",PERIOD_M1,some_time2);
     //int distance = shift_1 - shift_2
}

void drawSellDivergence(){
 //example draw in sub window: ObjectCreate(0,"High@"+TimeToString(time),OBJ_ARROW_SELL,1,time,value);
 string obj_name_1 = "sellDiv1"+TimeToString(TimeCurrent());
 string obj_name_2 = "sellDiv2"+TimeToString(TimeCurrent());
 
 //trendline price and obv
 ObjectCreate(0, obj_name_1, OBJ_TREND, 0, high_and_lows_.High1Time, high_and_lows_.high1, high_and_lows_.High2Time, high_and_lows_.high2);
 ObjectCreate(0, obj_name_2, OBJ_TREND, 1, high_and_lows_.HighObv1Time, high_and_lows_.highObv1, high_and_lows_.HighObv2Time, high_and_lows_.highObv2);
 
 
 //calc difference between two price points
 int shift_p_1 = iBarShift(NULL,PERIOD_CURRENT, high_and_lows_.High1Time);
 int shift_p_2 = iBarShift(NULL,PERIOD_CURRENT, high_and_lows_.High2Time);
 int diffr_p = shift_p_2-shift_p_1;
 //Print("shift_1: ",shift_p_1,"/","shift_2: ",shift_p_2);
 
 //label price point
 string difference_label_pri = "difference label price"+TimeToString(TimeCurrent());
 ObjectCreate(0,difference_label_pri,OBJ_TEXT,0,high_and_lows_.High1Time,high_and_lows_.high1);
 ObjectSetString(0,difference_label_pri,OBJPROP_TEXT,"d:" + diffr_p);
 
 
 //calc difference between two obv points
 int shift_o_1 = iBarShift(NULL,PERIOD_CURRENT, high_and_lows_.HighObv1Time);
 int shift_o_2 = iBarShift(NULL,PERIOD_CURRENT, high_and_lows_.HighObv2Time);
 int diffr_o = shift_o_2-shift_o_1;
 
 //label obv point
 string difference_label_obv = "difference label obv"+TimeToString(TimeCurrent());
 ObjectCreate(0,difference_label_obv,OBJ_TEXT,1,high_and_lows_.HighObv1Time,high_and_lows_.highObv1);
 ObjectSetString(0,difference_label_obv,OBJPROP_TEXT,"d:" + diffr_o);
 
 
 
 //ObjectCreate(0, difference_label, OBJ_LABEL,0,high_and_lows_.Low1Time, high_and_lows_.low1);
 
 //ObjectSetString(0,difference_label,OBJPROP_TEXT,"buy signal");
      //TODO calculate distance between high and low and obv extremes print it on chart
     //int shift_1 = iBarShift("EUROUSD",PERIOD_M1,some_time1);
     //int shift_2 = iBarShift("EUROUSD",PERIOD_M1,some_time2);
     //int distance = shift_1 - shift_2

}

void findHighLowObv(double& newHigh,datetime& newHighTime, double& newLow, datetime& newLowTime){
    int indexBar = verificationCandles;
       
     double obv[];
     //if(CopyBuffer(handleObv,0,1,verificationCandles*2+1,obv) < (verificationCandles*2+1)){
     if(CopyBuffer(handleObv,0,1,verificationCandles*2+1,obv) < 41){
       return;
     }      

     double value = obv[indexBar]; 
   
     datetime time = iTime(_Symbol,PERIOD_CURRENT, indexBar + 1);
         
     bool isHigh = true, isLow = true;
   
     //Print("DEBUG obv array size = ", ArraySize(obv));
     for(int i = 1; i <= verificationCandles; i++){
     //Print("DEBUG indexBar+i = ", (indexBar+i));
       double valLeft = obv[indexBar+i];
       double valRight = obv[indexBar-i];
     
       if(valLeft > value || valRight > value){
         isHigh = false;
       }
          
       if(valLeft < value || valRight < value) {
         isLow = false;
       }
     
       if(!isHigh && !isLow){
       break;
       }
     
       if(i == verificationCandles){
         if(isHigh){
           //Print(__FUNCTION__," > Found a new high (", DoubleToString(value,_Digits),") at ",time,"...");
           ObjectCreate(0,"High@"+TimeToString(time),OBJ_ARROW_SELL,1,time,value);
           newHigh = value;
		     newHighTime = time;
           
         }
         if(isLow){
           //Print(__FUNCTION__," > Found a new low at (", DoubleToString(value, _Digits),") at ",time,"...");
           ObjectCreate(0,"Low@"+TimeToString(time),OBJ_ARROW_BUY,1,time,value);
           newLow = value;
		     newLowTime = time;
         }     
       }  
     }//end for
   
    Comment("Value: ", DoubleToString(value,_Digits));
}

void findHighLow(double& newHigh, datetime& newHighTime, double& newLow, datetime& newLowTime){
     int indexBar = verificationCandles+1;
     double high = iHigh(_Symbol,PERIOD_CURRENT, indexBar); //+1 to not include current candle
     double low = iLow(_Symbol, PERIOD_CURRENT, indexBar);
     datetime time = iTime(_Symbol,PERIOD_CURRENT, indexBar);
   
     bool isHigh = true, isLow = true;
   
     for(int i = 1; i <= verificationCandles; i++){
       double highLeft = iHigh(_Symbol, PERIOD_CURRENT, indexBar+i);
       double highRight = iHigh(_Symbol, PERIOD_CURRENT, indexBar-i);
     
       if(highLeft > high || highRight > high){
         isHigh = false;
       }
     
       double lowLeft = iLow(_Symbol, PERIOD_CURRENT, indexBar+i);
       double lowRight = iLow(_Symbol, PERIOD_CURRENT, indexBar-i);
     
       if(lowLeft < low || lowRight < low) {
         isLow = false;
       }
     
       if(!isHigh && !isLow){
       break;
       }
     
       if(i == verificationCandles){
         if(isHigh){
           //Print(__FUNCTION__," > Found a new high (", DoubleToString(high,_Digits),") at ",time,"...");
           ObjectCreate(0,"High@"+TimeToString(time),OBJ_ARROW_SELL,0,time,high);
           newHigh = high;
		     newHighTime = time;
         }
         if(isLow){
           //Print(__FUNCTION__," > Found a new low at (", DoubleToString(low, _Digits),") at ",time,"...");
           ObjectCreate(0,"Low@"+TimeToString(time),OBJ_ARROW_BUY,0,time,low);
           newLow = low;
		     newLowTime = time;
         }     
       }  
     }//end for
   
    Comment("High: ", DoubleToString(high,_Digits), "\nLow: ", DoubleToString(low,_Digits));
   
}