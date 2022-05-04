//+------------------------------------------------------------------+
//|                                        indiBufferExpertTest1.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property tester_indicator "indiBufferTest1.ex5"

double Test[];
int handle;
int counter = 2000;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   handle = iCustom(NULL, 0, "indiBufferTest1");
   if(handle == INVALID_HANDLE){
     Print("Failed to get IndicatorHandle!");
     ExpertRemove();
   }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   IndicatorRelease(handle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   CopyBuffer(handle,0,0,3,Test);
   
   ArraySetAsSeries(Test,true);
   
   Print("<-----------------------------------------------");
   ArrayPrint(Test);
   Print(">-----------------------------------------------");
   
   for(int i = 0; i < 3; i++){
     Print(i,"  ", DoubleToString(Test[i],0));
     Print("");
     counter--;
     if(counter == 0){
       TesterStop();
     }
   }
   
  }
//+------------------------------------------------------------------+
