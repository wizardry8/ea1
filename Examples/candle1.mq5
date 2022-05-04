//+------------------------------------------------------------------+
//|                                                      candle1.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

enum TYPE_CANDLESTICK{
  CAND_NONE,            //unrecognized
  CAND_MARIBOZU,
  CAND_MARIBOZU_LONG,
  CAND_DOJI,
  CAND_SPIN_TOP,
  CAND_HAMMER,
  CAND_INVERT_HAMMER,
  CAND_LONG,
  CAND_SHORT,
  CAND_STAR
};

enum TYPE_TREND{
  UPPER,
  DOWN,
  LATERAL
};

struct CANDLE_STRUCTURE{
  double             open,high,low,close;
  datetime           time;
  TYPE_TREND         trend;
  bool               bull;
  double             bodysize;
  TYPE_CANDLESTICK   type;
};

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

bool RecognizeCandle(string symbol, ENUM_TIMEFRAMES period, datetime time, int aver_period, CANDLE_STRUCTURE &res){
  MqlRates rt[];
  //get data of previous candlesticks
  if(CopyRates(symbol, period, time, aver_period+1, rt) < aver_period){
    return(false);
  }

  res.open = rt[aver_period].open;
  res.high = rt[aver_period].high;
  res.low = rt[aver_period].low;
  res.close = rt[aver_period].close;
  res.time = rt[aver_period].time;

  //define trend direction
  double aver = 0;
  for(int i = 0; i < aver_period; i++){
    aver += rt[i].close;
  }
  aver = aver / aver_period;
  
  if(aver < res.close){
    res.trend = UPPER;
  }
  
  if(aver > res.close){
    res.trend = DOWN;
  }
  
  if(aver == res.close){
    res.trend = LATERAL;
  }
  
  //define if bullish or bearish
  res.bull = res.open < res.close;
  
  //get absolute value of the candlestick body size
  res.bodysize = MathAbs(res.open - res.close);
  
  //get size of shadows
  double shade_low = res.close - res.low;
  double shade_high = res.high - res.open;
  
  if(res.bull){
    shade_low = res.open - res.low;
    shade_high = res.high - res.close;
  }

  double HL = res.high - res.low;
  
  //calc average body size of previous candlesticks
  double sum = 0;
  for(int i = 1; i <= aver_period; i++){
    sum = sum + MathAbs(rt[i].open - rt[i].close);
    sum = sum/aver_period;
  }


  //IDENTIFICATION OF CANDLESTICKS
 
  //long [body > (average body of the last five days) * 1.3]
  if(res.bodysize > sum * 1.3){
    res.type = CAND_LONG;
  } 

  //short [body > (average body of the last X days) * 0.5]
  if(res.bodysize < sum * 0.5){
    res.type = CAND_SHORT;
  }
  
  //doji [dodji body < (range from the highest to the lowest prices) * 0.03)]
  if(res.bodysize < HL * 0.03){
    res.type = CAND_DOJI;
  }
  
  //Marubozu, candlestick with no high or low, or they are very small [lower shadow < (body) * 0.03 or (uppershadow) < (body) * 0.03]
  if((shade_low < res.bodysize * 0.01 || shade_high < res.bodysize * 0.01) && res.bodysize > 0){
    if(res.type == CAND_LONG){
      res.type = CAND_MARIBOZU_LONG;
    }else{
      res.type = CAND_MARIBOZU;
    }
  }

  //hammer [(lower shadow) > (body) * 2 and (upper shadow) < (body) * 0.1]
  if(shade_low > res.bodysize * 2 && shade_high < res.bodysize * 0.1){
    res.type = CAND_HAMMER;
  }
  
  //inverted hammer
  if(shade_low < res.bodysize * 0.1 && shade_high > res.bodysize * 2){
    res.type = CAND_INVERT_HAMMER;
  }
  
  //spinning top
  if(res.type == CAND_SHORT && shade_low > res.bodysize && shade_high > res.bodysize){
    res.type = CAND_SPIN_TOP;
  }
  
  
  
  //calculation of candlestick patterns
  for(int i = limit; i < rates_total - 1; i++){
    CANDLE_STRUCTURE cand1;
    
    if(!RecognizedCandle(_Symbol, _Period, time[i], InpPeriodSMA, cand1)){
      continue;
    }
    
    //inverted hammer the bull model
    if(cand1.trend == DOWN && cand1.type == CAND_INVERT_HAMMER)//check trend direction and "inverted hammer"
    {
      comment = _language?"Inverted hammer";
      DrawSignal(prefix+"Inverted Hammer the bull model" + string(objcount++), cand1, InpColorBull, comment);
    }
    //Hanging man the bear model
    if(cand1.trend == UPPER && cand1.type == CAND_HAMMER)//check the trend direction and "hammer"
    {
      comment = _language?"Hanging Man";
      DrawSignal(prefix+"Hanging Man the bear model"+string(objcount++), cand1, InpColorBear, comment);
    }
    
    //Hammer the bull model
    if(cand1.trend == DOWN && cand1.type == CAND_HAMMER){
      comment = language?"Hammer";
      DrawSignal(prefix+"Hammer the bull model" + string(objcount++), cand1, InpColorBull, comment);
    }
    
    //Shooting Star the bear model
    if(cand1.trend == UPPER && cand2.trend == UPPER && cand2.type == CAND_INVERT_HAMMER){
      comment = _language?"Shooting Star";
      if(_forex) //if forex
      {
        if(cand1.close <= cand2.open){
          DrawSignal(prefix + "Shooting Star the bear model" + string(objcount++), cand2, InpColorBear, comment);
        }
      }
      else
      {
        if(cand1.close < cand2.open && cand1.close < cand2.close)
        {
          DrawSignal(prefix + "Shooting Star the bear model" + string(objcount++), cand2, InpColorBear, comment);
        }   
      }
    }
    
    
    CANDLE_STRUCTURE cand2;
    cand2 = cand1;
    if(!RecognizeCandle(_Symbol, _Period, time[i-1], InpPeriodSMA, cand1)){
      continue;
    }
    
    //Englufing the bull model
    if(cand1.trend == DOWN && !cand1.bull && cand2.trend == DOWN && cand2.bull && cand1.bodysize < cand2.bodysize){
      comment = _language?"Engulfing";
      if(_forex){
        if(cand1.close >= cand2.open && cand1.open < cand2.close){
          DrawSignal(prefix + "Engulfing th bull model" + string(objcount++), cand1, cand2, InpColorBull, comment);       
        }
      }
    }
    else{
    if(cand1.close > cand2.open && cand1.open < cand2.close){
      DrawSignal(prefix + "Engulfing the bull model" + string(objcount++), cand1, cand2, InpColorBull, comment);
    }
    
    //Engulfing bear model
    if(cand1.trend == UPPER && cand1.bull && cand2.trend == UPPER && !cand2.bull && cand1.bodysize < cand2.bodysize)
    {
      comment = _language?"Engulfing";
      if(_forex){
        if(cand1.close <= cand2.open && cand1.open > cand2.close){
          DrawSignal(prefix + "Engulfing the bear model" + string(objcount++), cand1, cand2, InpColorBear, comment);
        }
      }
      else
      {
      if(cand1.close < cand2.open && cand1.open > cand2.close){
        DrawSignal(prefix + "Engulfing the bear model" + string(objcount++), cand1, cand2, InpColorBear, comment);
      }
      }
    }
            
   }
        
  } 
}