//USE THIS EA TOGETHER WITH tutorial4.mq5 INDICATOR
//ITS FOR DEVELOPING A HFIB EA
//TODO: REMOVE CHRISTMAS HOLIDAYS FROM CALCULATION
//+------------------------------------------------------------------+
//|                                                customIndExp1.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_buffers 5
#property indicator_plots 2

#include <Trade\Trade.mqh>
//#include <mt4datetime.mqh>

int my_custom_indi_handle = 0; //custom indicator handle address?
int ema_indi_handle = 0; //ema handle address
int stoch_indi_handle = 0;

double g_hfib_indi_0[], g_hfib_indi_1[], g_hfib_indi_2[], g_hfib_indi_3[], g_hfib_indi_4[]; //0:g_max_high, 1:g_max_time, 2:g_combined_price, 3:g_combined_time, 4:g_combined_min_or_max
double g_ma_buff[];
double g_stoch_K_buff[];
double g_stoch_D_buff[];
//double g_old_hfib_indi_0[], g_old_hfib_indi_1[];

double g_stored_recieved_max[];
double g_stored_recieved_time[];
double g_stored_recieved_comb_price[];
double g_stored_recieved_comb_time[];
double g_stored_recieved_comb_min_or_max[];

int g_stored_recieved_max_index = 0;
int g_stored_recieved_time_index = 0;
int g_stored_recieved_comb_price_index = 0;
int g_stored_recieved_comb_time_index = 0;
int g_stored_recieved_comb_min_or_max_index = 0;

int g_vertical_line_index = 0;

double g_pending_enter_time = 0;
double g_previous_max_price = 0;
double g_previous_combined_price = 0;

bool drew = false;

int g_output_counter = 10;

bool g_new_trade_ready = false;
int g_last_zeroed_mod = 0; 
int g_last_zeroed_comb_mod = 0;

int g_vib_calc_counter = 0;

int g_init_SL = 500; //150 from orig
int g_trail_SL = 20;//10 from orig
int g_init_TP = 500;//2 * g_init_SL;

int g_bin_index = 0;
ENUM_TIMEFRAMES my_timeframe;
ENUM_TIMEFRAMES g_bin_period = my_timeframe;

CTrade trade;

bool g_debug_done_only_once = false; //TEMP DELETE WHEN DBUGGING DONE

color clrs[6];

int g_enum_clr_index = 0;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
   my_timeframe = Period();
      
   clrs[0] = clrAliceBlue;
   clrs[1] = clrPaleVioletRed;
   clrs[2] = clrAqua;
   clrs[3] = clrOrange;
   clrs[4] = clrBlue;
   clrs[5] = clrRed;
   
   
   my_custom_indi_handle = iCustom(NULL, 0, "tutorial4",
                    500,
                    20,
                    4 
                    );

   //Print("enum debug 1: " + EnumToString(my_timeframe));
                    
   ema_indi_handle = iMA(Symbol(), my_timeframe, 45, 0, MODE_EMA, PRICE_CLOSE);
   int my_timeframe_plus_one = (ENUM_TIMEFRAMES)my_timeframe;
   //Print("enum debug 2: " + EnumToString((ENUM_TIMEFRAMES)my_timeframe_plus_one));
   my_timeframe_plus_one += 2;
   
   //stoch_indi_handle = iStochastic(Symbol(), (ENUM_TIMEFRAMES)my_timeframe_plus_one,14,3,3,MODE_EMA,STO_LOWHIGH);
   stoch_indi_handle = iStochastic(Symbol(), my_timeframe,14,3,3,MODE_EMA,STO_LOWHIGH);   //use this without offset

   //Print("enum debug 3: " + EnumToString((ENUM_TIMEFRAMES)my_timeframe_plus_one));
   
   
   
   ChartIndicatorAdd(ChartID(), 0, ema_indi_handle); //add indicator to chart
   ChartIndicatorAdd(ChartID(), 0, stoch_indi_handle);
   
     ArrayInitialize(g_hfib_indi_0, 0);
     ArrayInitialize(g_hfib_indi_1, 0);
     
     ArrayResize(g_stored_recieved_max, 100000);
     ArrayResize(g_stored_recieved_time, 100000); // [0][1][2][3]
     ArrayResize(g_stored_recieved_comb_price, 100000);
     ArrayResize(g_stored_recieved_comb_time, 100000);
     ArrayResize(g_stored_recieved_comb_min_or_max, 100000);
     ArrayInitialize(g_stored_recieved_max, 0);
     ArrayInitialize(g_stored_recieved_time, 0);
     ArrayInitialize(g_stored_recieved_comb_price, 0);
     ArrayInitialize(g_stored_recieved_comb_time, 0);
     ArrayInitialize(g_stored_recieved_comb_min_or_max, 0);
   
   ///+
   
     if(CopyBuffer(my_custom_indi_handle,0,0,4,g_hfib_indi_0) < 0){
       Print("At init CopyBufferHfib_indi_0 error = ", GetLastError());
     }
     
     if(CopyBuffer(my_custom_indi_handle,1,0,4,g_hfib_indi_1) < 0){
       Print("At init CopyBufferHfib_indi_1 error = ", GetLastError());
     }
     
     if(CopyBuffer(my_custom_indi_handle,2,0,4,g_hfib_indi_2) < 0){
       Print("At init CopyBufferHfib_indi_2 error = ", GetLastError());
     }
     
     if(CopyBuffer(my_custom_indi_handle,3,0,4,g_hfib_indi_3) < 0){
       Print("At init CopyBufferHfib_indi_3 error = ", GetLastError());
     }
     
     if(CopyBuffer(my_custom_indi_handle,4,0,4,g_hfib_indi_4) < 0){
       Print("At init CopyBufferHfib_indi_4 error = ", GetLastError());
     }
     
     ArraySetAsSeries(g_hfib_indi_0, true);  
     ArraySetAsSeries(g_hfib_indi_1, true);
     ArraySetAsSeries(g_hfib_indi_2, true);
     ArraySetAsSeries(g_hfib_indi_3, true);
     ArraySetAsSeries(g_hfib_indi_4, true);
     ArraySetAsSeries(g_stored_recieved_max, true);
     ArraySetAsSeries(g_stored_recieved_time, true);
     ArraySetAsSeries(g_stored_recieved_comb_price, true);
     ArraySetAsSeries(g_stored_recieved_comb_time, true);
     ArraySetAsSeries(g_stored_recieved_comb_min_or_max, true);
     ArraySetAsSeries(g_ma_buff, true);
     ArraySetAsSeries(g_stoch_D_buff,true);
     ArraySetAsSeries(g_stoch_K_buff,true);
      
     //Print(">----------------------------");
     for(int i = 0; i < 4; i++){
       if(g_hfib_indi_0[i] != 0){
         Print("At init expert recieved " + i + " :" + g_hfib_indi_0[i]);
       }
     }
   
     for(int i = 0; i < 4; i++){
       if(g_hfib_indi_1[i] != 0){
         Print("At init expert recieved " + i + " :" + TimeToString(g_hfib_indi_1[i]));
       }
     }
     //Print("<----------------------------");
   
     
     Print("~~~~~~~~~~~~~~~~~~~~~~~~~ INIT DONE ~~~~~~~~~~~~~~~~~~~~~~~~~");
   ///+
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
     
     if(CopyBuffer(my_custom_indi_handle,0,0,4,g_hfib_indi_0) < 0){
       Print("CopyBufferHfib_indi_0 error = ", GetLastError());
     }
     
     if(CopyBuffer(my_custom_indi_handle,1,0,4,g_hfib_indi_1) < 0){
       Print("CopyBufferHfib_indi_1 error = ", GetLastError());
     }
     
     if(CopyBuffer(my_custom_indi_handle,2,0,4,g_hfib_indi_2) < 0){
       Print("At init CopyBufferHfib_indi_2 error = ", GetLastError());
     }
     
     if(CopyBuffer(my_custom_indi_handle,3,0,4,g_hfib_indi_3) < 0){
       Print("At init CopyBufferHfib_indi_3 error = ", GetLastError());
     }
     
     if(CopyBuffer(my_custom_indi_handle,4,0,4,g_hfib_indi_4) < 0){
       Print("At init CopyBufferHfib_indi_4 error = ", GetLastError());
     }
     if(CopyBuffer(ema_indi_handle,0,1,1,g_ma_buff) < 0){
       Print("At init CopyBufferEma error = ", GetLastError());
     }
     if(CopyBuffer(stoch_indi_handle,0,0,3,g_stoch_K_buff) < 0){
       Print("At init CopyBufferStochK error = ", GetLastError());
     }
     if(CopyBuffer(stoch_indi_handle,0,0,3,g_stoch_D_buff) < 0){
       Print("At init CopyBufferStochK error = ", GetLastError());
     }
     
     for(int i = 3; i >= 0; i--){
       
       bool new_value = true; 
       if(g_hfib_indi_0[i] == 0){
           continue;
       }
       
       int j = 3;
       if(g_stored_recieved_max_index < 3){
         j = g_stored_recieved_max_index;
       }
       for(j; j >= 0; j--){
       
         if(g_hfib_indi_0[i] == g_stored_recieved_max[g_stored_recieved_max_index - j]){
           new_value = false;
           break;
         }
         
       }
       
       if(new_value){
         g_stored_recieved_max[g_stored_recieved_max_index] = g_hfib_indi_0[i];
         g_stored_recieved_max_index++;
         //Print("adding max " + TimeToString(g_hfib_indi_0[i]));
         g_stored_recieved_time[g_stored_recieved_time_index] = g_hfib_indi_1[i];
         g_stored_recieved_time_index++;
         //Print("STORED NEW MAX: " + (g_stored_recieved_max_index - 1));
       }
       
     }
	 
     //transfer combined values from indi to expert
     //0:g_max_high, 1:g_max_time, 2:g_combined_price, 3:g_combined_time, 4:g_combined_min_or_max
     for(int i = 3; i >= 0; i--){
       
       bool new_value = true; 
       if(g_hfib_indi_2[i] == 0){
           continue;
       }
       
       int j = 3;
       if(g_stored_recieved_comb_price_index < 3){
         j = g_stored_recieved_comb_price_index;
       }
       for(j; j >= 0; j--){
       
         if(g_hfib_indi_2[i] == g_stored_recieved_comb_price[g_stored_recieved_comb_price_index - j]){
           new_value = false;
           break;
         }
         
       }
       
       //0:g_max_high, 1:g_max_time, 2:g_combined_price, 3:g_combined_time, 4:g_combined_min_or_max
       if(new_value){ // maybe add new_value != 0, see point below
         g_stored_recieved_comb_price[g_stored_recieved_comb_price_index] = g_hfib_indi_2[i]; //shouldnt this be g_hfib_indi_3[i] instead of 2, read log
         g_stored_recieved_comb_price_index++;
         //Print("adding combo " + TimeToString(g_hfib_indi_2[i]) + ", " + g_hfib_indi_4[i]);
         g_stored_recieved_comb_time[g_stored_recieved_comb_time_index] = g_hfib_indi_3[i];
         g_stored_recieved_comb_time_index++;
		   g_stored_recieved_comb_min_or_max[g_stored_recieved_comb_min_or_max_index] = g_hfib_indi_4[i];
		   g_stored_recieved_comb_min_or_max_index++;
         //Print("STORED NEW MAX: " + (g_stored_recieved_max_index - 1));
       }
       
     }
     
     //######
     //disabled since calculation should be done in indicator now 
     calcFibsCombined();
     //######
     
     //-oo
     Print("DBF CHECKING ENTRY");
     Print("g_pending_enter_time: " + g_pending_enter_time + ", and g_new_trade_ready: " + g_new_trade_ready);
       if(TimeCurrent() >= g_pending_enter_time && g_new_trade_ready == true){
       Print("DBF CHECKING ENTRY 2");
       ///Print("----------------------------> Enter time comparison (c >= p): " + TimeToString(TimeCurrent()) + " >= " + g_pending_enter_time);
       //if((g_new_trade_ready == true) && ((double)TimeCurrent() == NormalizeDouble(g_pending_enter_time, 0))){
     
         //Print("taget price reached, entering for " + g_pending_enter_time + ", at current time: " + TimeCurrent());
         //g_previous_max_price = g_stored_recieved_max[g_stored_recieved_max_index - 1];
		   g_previous_combined_price = g_stored_recieved_comb_price[g_stored_recieved_comb_price_index];
		   
		   //[][][][][]
		   
		   int bin = directionalBin();

		   //no directional bias because of equally priced bars, skip that trade
		   if(bin == 0){
		     return;
		   }
		   
		   //[][][][][] 
     
         MqlTick last_tick;
         SymbolInfoTick(_Symbol, last_tick);
         double Ask = last_tick.ask;
         double Bid = last_tick.bid;
       
         //if((PositionsTotal() == 0)){
     
         if(bin < 0 && Ask > g_ma_buff[0]){ //100ema inverse       
			//if(bin < 0 && Bid < g_ma_buff[0] && ((g_stoch_K_buff[0] > 80 && g_stoch_D_buff[0] > 80) || (g_stoch_D_buff[0] > g_stoch_K_buff[0])) ){ //stoch, bin, ema
         //if(bin < 0 && ((g_stoch_K_buff[0] > 80 && g_stoch_D_buff[0] > 80) || (g_stoch_D_buff[0] > g_stoch_K_buff[0])) ){ //stoch, bin
              //trade.Sell(0.10, NULL, Bid, (Bid + 400 * _Point), (Bid - 800 * _Point), NULL); //sell
              trade.Sell(0.10, NULL, Bid, (Bid + g_init_SL * _Point), (Bid - g_init_TP * _Point), NULL); //sell
              g_new_trade_ready = false;
              Print("OPEN SELL ++++++++++++++++++++++++++++++");
            }

			
			else if(bin > 0 && Ask < g_ma_buff[0]){ //ema inverse
			//else if(bin > 0 && Ask > g_ma_buff[0] && ((g_stoch_K_buff[0] < 20 && g_stoch_D_buff[0] < 20) || (g_stoch_D_buff[0] < g_stoch_K_buff[0])) ){ //stoch, bin, ema
			//else if(bin > 0 && ((g_stoch_K_buff[0] < 20 && g_stoch_D_buff[0] < 20) || (g_stoch_D_buff[0] < g_stoch_K_buff[0])) ){ //stoch, bin
              //trade.Buy(0.10, NULL, Ask, (Ask - 400 * _Point), (Ask + 200 * _Point), NULL); //sell
              trade.Buy(0.10, NULL, Ask, (Ask - g_init_SL * _Point), (Ask + g_init_TP * _Point), NULL); //sell
              g_new_trade_ready = false;
              Print("OPEN BUY --------------------------------");
            }
            else{
              Print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~UNABLE TO PLACE TRADE");
              g_new_trade_ready = false;
            }
         //}
       //~} 
       }
      
     //-oo
     //*
          
     //%%%
     double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
     double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
     CheckTrailingStop(Ask, Bid);
     CheckIfPriceTouchesMA(Ask, Bid);
     //%%%
     
     
  }
//+------------------------------------------------------------------+
//When price touches ma, close the position
void CheckIfPriceTouchesMA(double Ask, double Bid){
  for(int i = PositionsTotal() - 1; i >= 0; i--){
    //Print("is: " + Ask + " == " + NormalizeDouble(g_ma_buff[0],5));
    if((Ask == NormalizeDouble(g_ma_buff[0],5)) || (Bid == NormalizeDouble(g_ma_buff[0],5)) ){
      ulong PositionTicket = PositionGetInteger(POSITION_TICKET); //get position numberplate
      trade.PositionClose(PositionTicket); 
    }
   
  }
}

void CheckTrailingStop(double Ask, double Bid){
  for(int i = PositionsTotal() - 1; i >= 0; i--){
  
    
    
    string symbol = PositionGetSymbol(i);
    if(_Symbol == symbol){
      int direction = PositionGetInteger(POSITION_TYPE);
      if(direction == POSITION_TYPE_BUY){
         
        double SL = NormalizeDouble(Ask - g_init_SL * _Point, _Digits); 
                  
        ulong PositionTicket = PositionGetInteger(POSITION_TICKET); //get position numberplate
        double CurrentStopLoss = PositionGetDouble(POSITION_SL);
        
        if(CurrentStopLoss < SL){
          trade.PositionModify(PositionTicket, (CurrentStopLoss + g_trail_SL * _Point), 0); //error: should it be current price + g_trail_SL ? -> initial must be larger than trail with this formula
          //trade.PositionModify(PositionTicket, SL, 0);
        }
        
      }
      else{
       
       double SL = NormalizeDouble(Bid + g_init_SL * _Point, _Digits);
       
       ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
       double CurrentStopLoss = PositionGetDouble(POSITION_SL);
       
       if(CurrentStopLoss > SL){
         trade.PositionModify(PositionTicket, (CurrentStopLoss - g_trail_SL * _Point), 0);
         //trade.PositionModify(PositionTicket, SL, 0);
       }
      
      }
    
    }
  
  }
       
}
     

void calcFibsCombined(){
   
   
   if(g_new_trade_ready == true || (g_stored_recieved_comb_price_index < 4) || (g_stored_recieved_comb_time[g_stored_recieved_comb_time_index - 1] < g_stored_recieved_comb_time[g_stored_recieved_comb_time_index - 3])){
      return;
   }
   
   
   //Print("DBF fibs: " + g_stored_recieved_max_index);
   //if((g_stored_recieved_max_index + 1) % 4 != 0 || g_last_zeroed_mod == (g_stored_recieved_max_index + 1) ){
   if((g_stored_recieved_comb_price_index + 1) % 4 != 0 || g_last_zeroed_comb_mod == (g_stored_recieved_comb_price_index + 1) ){
     return;
   }
   
   //g_last_zeroed_mod = (g_stored_recieved_max_index + 1);
   g_last_zeroed_comb_mod = (g_stored_recieved_comb_price_index + 1);
   
   //Print("fib modu: " + (g_stored_recieved_max_index + 1) + "%4 = " + ((g_stored_recieved_max_index + 1) % 4));
    
    
   double golden_smaller = 0.382;
   double golden_larger = 0.618;
   
   //printf("calc %f", g_hfib_indi_0[0]); //price
   //printf("calc %f", g_hfib_indi_1[0]); //time
   
   //double max_n = g_hfib_indi_1[1];//n - 1 is the rightmost ALWAYS -1 OFFSET TO VALID DATA!!
   
   ////double max_n = g_stored_recieved_time[g_stored_recieved_time_index - 1];
   double max_n = g_stored_recieved_comb_time[g_stored_recieved_comb_time_index - 1];
   
   //Print("fibnr: " + g_vib_calc_counter + " max_n: ", + g_stored_recieved_time[g_stored_recieved_time_index - 1]);
   ////Print("date of max_n: " + TimeToString(max_n));
   //Print("fib DBF1: " + (datetime)g_hfib_indi_1[1]);
   //double max_n_minus_2 = g_hfib_indi_1[3]; //leave a gap of one, trying to leave one out
   
   //double max_n_minus_2 = g_stored_recieved_time[g_stored_recieved_time_index - 3];
   double max_n_minus_2 = g_stored_recieved_comb_time[g_stored_recieved_comb_time_index - 3];
   
   //Print("max_n_minus_2: ", + g_stored_recieved_time[g_stored_recieved_time_index - 3]);
   ////Print("date of max_n_minus_2: " + TimeToString(max_n_minus_2));
   //Print("fib DBF2: " + (datetime)g_hfib_indi_1[3]);
   //Print("max_n: " + max_n);
   //Print("max_n_minus_2: " + max_n_minus_2);
   
   double distance_n_minus_2_to_n = max_n - max_n_minus_2; //a not yet corrected (weekend still included)
   //Print("distance_n_minus_2_to_n: ", + distance_n_minus_2_to_n);
   
   //ÜÜÜ
   //  reducing distance n - (n-2) by # of weekends for calculating fib3 
   //
   
   MqlDateTime timestruct_max_n_minus_2;
   TimeToStruct(max_n_minus_2, timestruct_max_n_minus_2);
   MqlDateTime timestruct_max_n;
   TimeToStruct(max_n, timestruct_max_n);
   
   int days_between_fibs = timestruct_max_n.day_of_year - timestruct_max_n_minus_2.day_of_year;
   //Print("There are " + days_between_fibs + " days between zero and three(target)");
   //if(days_between_fibs < 0){...} cornercase when transtion between years, skip calc of fibs for now
   
   int weekday_index = timestruct_max_n_minus_2.day_of_week;
   int weekend_count = 0;
   
   for(int i = days_between_fibs; i >= 0; i--){ //both legs of fibs will never land on a weekend, they are at identified MAX
     if(weekday_index == 7){
       weekday_index = 0;
       weekday_index++;
     }
     else if(weekday_index == 6){  //day of week (0-sunday, 1-monday, ... , 6-saturday)
       weekend_count++;
       weekday_index++;
     }
     else{
       weekday_index++;
     }
   }
   
   distance_n_minus_2_to_n -= weekend_count * (86400 * 2 + 3600); //1 day = 86400 seconds, 1h = 3600 seconds
   
   //ÜÜÜ
   
   double time_value_of_larger = distance_n_minus_2_to_n/golden_smaller * golden_larger + max_n_minus_2; //timevalue of 0.618
   //Print("time_value_of_larger: ", + time_value_of_larger);
   Print("date of larger: " + TimeToString(time_value_of_larger));
   
   //ÄÄÄ
   //  increasing distance time_value_of_larger - (n - 2) ) by # of weekends for calculating fib3 
   //
   
   MqlDateTime timestruct_time_value_of_larger;
   TimeToStruct(time_value_of_larger, timestruct_time_value_of_larger);
   //MqlDateTime timestruct_max_n;
   //TimeToStruct(max_n, timestruct_max_n_minus_2);
   
   days_between_fibs = timestruct_time_value_of_larger.day_of_year - timestruct_max_n_minus_2.day_of_year;
   //if(days_between_fibs < 0){...} cornercase when transtion between years, skip calc of fibs for now
   
   weekday_index = timestruct_max_n_minus_2.day_of_week;
   weekend_count = 0;
   
   for(int i = days_between_fibs; i >= 0; i--){ //both legs of fibs will never land on a weekend, they are at identified MAX
     if(weekday_index == 7){
       weekday_index = 0;
       weekday_index++;
     }
     else if(weekday_index == 6){  //day of week (0-sunday, 1-monday, ... , 6-saturday)
       weekend_count++;
       weekday_index++;
     }
     else{
       weekday_index++;
     }
   }
   
   time_value_of_larger += weekend_count * (86400 * 2 + 3600); //1 day = 86400 seconds, 1h = 3600 seconds
   
   //ÄÄÄ
   
   //one is disabled for now, till larger is correct
   double time_value_of_one = distance_n_minus_2_to_n / golden_smaller * 1 + max_n_minus_2;  //timevalue of 1
   //Print("time_value_of_one: ", + time_value_of_one);
   Print("date of one: " + TimeToString(time_value_of_one));
   //Print(TimeToString(time_value_of_one)); 
   //Print("time value of larger: " + time_value_of_larger); 
    
   //ÖÖÖ
   //  increasing distance time_value_of_one - (n - 2) ) by # of weekends for calculating fib3 
   //
   
   MqlDateTime timestruct_time_value_of_one;
   TimeToStruct(time_value_of_one, timestruct_time_value_of_one);
   //MqlDateTime timestruct_max_n;
   //TimeToStruct(max_n, timestruct_max_n_minus_2);
   
   days_between_fibs = timestruct_time_value_of_one.day_of_year - timestruct_max_n_minus_2.day_of_year;
   //if(days_between_fibs < 0){...} cornercase when transtion between years, skip calc of fibs for now
   
   weekday_index = timestruct_max_n_minus_2.day_of_week;
   weekend_count = 0;
   
   for(int i = days_between_fibs; i >= 0; i--){ //both legs of fibs will never land on a weekend, they are at identified MAX
     if(weekday_index == 7){
       weekday_index = 0;
       weekday_index++;
     }
     else if(weekday_index == 6){  //day of week (0-sunday, 1-monday, ... , 6-saturday)
       weekend_count++;
       weekday_index++;
     }
     else{
       weekday_index++;
     }
   }
   
   time_value_of_one += weekend_count * (86400 * 2 + 3600); //1 day = 86400 seconds, 1h = 3600 seconds
   
   //ÖÖÖ
    
    
    
    
    
    
   //the calculated extension is stored and readied for a trade 
   //g_pending_enter_time = time_value_of_larger;
   g_pending_enter_time = time_value_of_one;  
   if(g_pending_enter_time > TimeCurrent()){
     g_new_trade_ready = true;
   }
   else{
     Print("####################### pending date already passed");
   }
   
   
   //drawFibs(g_stored_recieved_time[g_stored_recieved_time_index - 3], g_stored_recieved_max[g_stored_recieved_max_index - 3], g_stored_recieved_time[g_stored_recieved_time_index - 1], g_stored_recieved_max[g_stored_recieved_max_index - 1], time_value_of_one);
   //combo values //TODO add automatic selection of right params depending on combo or max, but max will probably stay standard
   //drawFibs(g_stored_recieved_comb_time[g_stored_recieved_comb_time_index - 3], g_stored_recieved_comb_price[g_stored_recieved_comb_price_index - 3], g_stored_recieved_comb_time[g_stored_recieved_comb_time_index - 1], g_stored_recieved_comb_price[g_stored_recieved_comb_price_index - 1], time_value_of_larger);
   drawFibs(g_stored_recieved_comb_time[g_stored_recieved_comb_time_index - 3], g_stored_recieved_comb_price[g_stored_recieved_comb_price_index - 3], g_stored_recieved_comb_time[g_stored_recieved_comb_time_index - 1], g_stored_recieved_comb_price[g_stored_recieved_comb_price_index - 1], time_value_of_one);
   ///Print("----------------------------> pending trade: " + (datetime)g_pending_enter_time + "at current time: " + TimeCurrent());
   
   g_vib_calc_counter++;
}

void calcFibs(){
   
   if(g_new_trade_ready == true || (g_stored_recieved_max_index < 4) || (g_stored_recieved_time[g_stored_recieved_time_index - 1] < g_stored_recieved_time[g_stored_recieved_time_index - 3])){
      return;
   }
   
   
   //Print("DBF fibs: " + g_stored_recieved_max_index);
      
   if((g_stored_recieved_max_index + 1) % 4 != 0 || g_last_zeroed_mod == (g_stored_recieved_max_index + 1) ){
     return;
   }
   
   g_last_zeroed_mod = (g_stored_recieved_max_index + 1);
   
   //Print("fib modu: " + (g_stored_recieved_max_index + 1) + "%4 = " + ((g_stored_recieved_max_index + 1) % 4));
    
   double golden_smaller = 0.382;
   double golden_larger = 0.618;
   
   //printf("calc %f", g_hfib_indi_0[0]); //price
   //printf("calc %f", g_hfib_indi_1[0]); //time
   
   //double max_n = g_hfib_indi_1[1];//n - 1 is the rightmost ALWAYS -1 OFFSET TO VALID DATA!!
   double max_n = g_stored_recieved_time[g_stored_recieved_time_index - 1];
   //Print("fibnr: " + g_vib_calc_counter + " max_n: ", + g_stored_recieved_time[g_stored_recieved_time_index - 1]);
   Print("date of max_n: " + TimeToString(max_n));
   //Print("fib DBF1: " + (datetime)g_hfib_indi_1[1]);
   //double max_n_minus_2 = g_hfib_indi_1[3]; //leave a gap of one, trying to leave one out
   double max_n_minus_2 = g_stored_recieved_time[g_stored_recieved_time_index - 3];
   //Print("max_n_minus_2: ", + g_stored_recieved_time[g_stored_recieved_time_index - 3]);
   Print("date of max_n_minus_2: " + TimeToString(max_n_minus_2));
   //Print("fib DBF2: " + (datetime)g_hfib_indi_1[3]);
   //Print("max_n: " + max_n);
   //Print("max_n_minus_2: " + max_n_minus_2);
   
   double distance_n_minus_2_to_n = max_n - max_n_minus_2; //a not yet corrected (weekend still included)
   //Print("distance_n_minus_2_to_n: ", + distance_n_minus_2_to_n);
   
   //ÜÜÜ
   //  reducing distance n - (n-2) by # of weekends for calculating fib3 
   //
   
   MqlDateTime timestruct_max_n_minus_2;
   TimeToStruct(max_n_minus_2, timestruct_max_n_minus_2);
   MqlDateTime timestruct_max_n;
   TimeToStruct(max_n, timestruct_max_n);
   
   int days_between_fibs = timestruct_max_n.day_of_year - timestruct_max_n_minus_2.day_of_year;
   //Print("There are " + days_between_fibs + " days between zero and three(target)");
   //if(days_between_fibs < 0){...} cornercase when transtion between years, skip calc of fibs for now
   
   int weekday_index = timestruct_max_n_minus_2.day_of_week;
   int weekend_count = 0;
   
   for(int i = days_between_fibs; i >= 0; i--){ //both legs of fibs will never land on a weekend, they are at identified MAX
     if(weekday_index == 7){
       weekday_index = 0;
       weekday_index++;
     }
     else if(weekday_index == 6){  //day of week (0-sunday, 1-monday, ... , 6-saturday)
       weekend_count++;
       weekday_index++;
     }
     else{
       weekday_index++;
     }
   }
   
   distance_n_minus_2_to_n -= weekend_count * (86400 * 2 + 3600); //1 day = 86400 seconds, 1h = 3600 seconds
   
   //ÜÜÜ
   
   double time_value_of_larger = distance_n_minus_2_to_n/golden_smaller * golden_larger + max_n_minus_2; //timevalue of 0.618
   //Print("time_value_of_larger: ", + time_value_of_larger);
   Print("date of larger: " + TimeToString(time_value_of_larger));
   
   //ÄÄÄ
   //  increasing distance time_value_of_larger - (n - 2) ) by # of weekends for calculating fib3 
   //
   
   MqlDateTime timestruct_time_value_of_larger;
   TimeToStruct(time_value_of_larger, timestruct_time_value_of_larger);
   //MqlDateTime timestruct_max_n;
   //TimeToStruct(max_n, timestruct_max_n_minus_2);
   
   days_between_fibs = timestruct_time_value_of_larger.day_of_year - timestruct_max_n_minus_2.day_of_year;
   //if(days_between_fibs < 0){...} cornercase when transtion between years, skip calc of fibs for now
   
   weekday_index = timestruct_max_n_minus_2.day_of_week;
   weekend_count = 0;
   
   for(int i = days_between_fibs; i >= 0; i--){ //both legs of fibs will never land on a weekend, they are at identified MAX
     if(weekday_index == 7){
       weekday_index = 0;
       weekday_index++;
     }
     else if(weekday_index == 6){  //day of week (0-sunday, 1-monday, ... , 6-saturday)
       weekend_count++;
       weekday_index++;
     }
     else{
       weekday_index++;
     }
   }
   
   time_value_of_larger += weekend_count * (86400 * 2 + 3600); //1 day = 86400 seconds, 1h = 3600 seconds
   
   //ÄÄÄ
   
   //one is disabled for now, till larger is correct
   double time_value_of_one = distance_n_minus_2_to_n / golden_smaller * 1 + max_n_minus_2;  //timevalue of 1
   //Print("time_value_of_one: ", + time_value_of_one);
   Print("date of one: " + TimeToString(time_value_of_one));
   //Print(TimeToString(time_value_of_one)); 
   //Print("time value of larger: " + time_value_of_larger); 
    
   //ÖÖÖ
   //  increasing distance time_value_of_one - (n - 2) ) by # of weekends for calculating fib3 
   //
   
   MqlDateTime timestruct_time_value_of_one;
   TimeToStruct(time_value_of_one, timestruct_time_value_of_one);
   //MqlDateTime timestruct_max_n;
   //TimeToStruct(max_n, timestruct_max_n_minus_2);
   
   days_between_fibs = timestruct_time_value_of_one.day_of_year - timestruct_max_n_minus_2.day_of_year;
   //if(days_between_fibs < 0){...} cornercase when transtion between years, skip calc of fibs for now
   
   weekday_index = timestruct_max_n_minus_2.day_of_week;
   weekend_count = 0;
   
   for(int i = days_between_fibs; i >= 0; i--){ //both legs of fibs will never land on a weekend, they are at identified MAX
     if(weekday_index == 7){
       weekday_index = 0;
       weekday_index++;
     }
     else if(weekday_index == 6){  //day of week (0-sunday, 1-monday, ... , 6-saturday)
       weekend_count++;
       weekday_index++;
     }
     else{
       weekday_index++;
     }
   }
   
   time_value_of_one += weekend_count * (86400 * 2 + 3600); //1 day = 86400 seconds, 1h = 3600 seconds
   
   //ÖÖÖ
    
    
    
    
    
    
   //the calculated extension is stored and readied for a trade 
   g_pending_enter_time = time_value_of_larger;
   //g_pending_enter_time = time_value_of_one;  
   
   g_new_trade_ready = true;
   
   //drawFibs(g_stored_recieved_time[g_stored_recieved_time_index - 3], g_stored_recieved_max[g_stored_recieved_max_index - 3], g_stored_recieved_time[g_stored_recieved_time_index - 1], g_stored_recieved_max[g_stored_recieved_max_index - 1], time_value_of_one);
   drawFibs(g_stored_recieved_time[g_stored_recieved_time_index - 3], g_stored_recieved_max[g_stored_recieved_max_index - 3], g_stored_recieved_time[g_stored_recieved_time_index - 1], g_stored_recieved_max[g_stored_recieved_max_index - 1], time_value_of_larger);
   
   Print("pending trade: " + (datetime)g_pending_enter_time);
   
   g_vib_calc_counter++;
}

void drawFibs(double zero, double zero_price, double three_eight_two, double three_eight_two_price, double six_one_eight){
  
  /*
  if(g_debug_done_only_once){
    return;
  }
  g_debug_done_only_once = true;
  */
    
  string obj_name = "vfib";
  string text_object_name;
  string text = obj_name + g_vertical_line_index; //this is the similar identifier for every leg of the hvfib
  
  
  //
  // draw hfibs 0.0
  //
  ObjectCreate(0, obj_name + g_vertical_line_index, OBJ_VLINE, 0, zero,0);
  //ObjectSetInteger(0, obj_name + g_vertical_line_index, OBJPROP_COLOR, 0x99FFFF);
  ObjectSetInteger(0, obj_name + g_vertical_line_index, OBJPROP_COLOR, 0xFFFF99); //light
  //ObjectSetInteger(0, obj_name + g_vertical_line_index, OBJPROP_COLOR, new_clr);
  
  //ObjectCreate(0, obj_name + g_vertical_line_index + "t1", OBJ_TEXT, 0, zero,0);
  //ObjectSetString(0, obj_name + g_vertical_line_index + "t1" ,OBJPROP_TEXT,obj_name + g_vertical_line_index + " 1");
  
  
  //
  // give hfibs 0.0 a label for identification
  //
  text_object_name = obj_name + " " + g_vertical_line_index + " t1";
  
  ObjectCreate(0, text_object_name, OBJ_TEXT, 0, zero, zero_price);
  ObjectSetString(0, text_object_name, OBJPROP_TEXT, text + " t1");
  ObjectGetInteger(0, text_object_name, OBJPROP_COLOR, clrWhite);
  ObjectSetInteger(0, text_object_name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);

  g_vertical_line_index++;
  
 
  //
  // draw hfibs 0.382
  // 
  //Print("drawing vline at: " + TimeToString(zero));
  ObjectCreate(0, obj_name + g_vertical_line_index, OBJ_VLINE, 0, three_eight_two,0);
  //ObjectSetInteger(0, obj_name + g_vertical_line_index, OBJPROP_COLOR, 0x0099FF);
  ObjectSetInteger(0, obj_name + g_vertical_line_index, OBJPROP_COLOR, 0xFF9900); //medium
  //ObjectSetInteger(0, obj_name + g_vertical_line_index, OBJPROP_COLOR, new_clr);
  
  //ObjectCreate(0, obj_name + g_vertical_line_index + "t2", OBJ_TEXT, 0, zero,0);
  //ObjectSetString(0, obj_name + g_vertical_line_index + "t2" ,OBJPROP_TEXT,obj_name + g_vertical_line_index + " 2");
  
  //
  // give hfibs 0.382 a label for identification
  //
  text_object_name = obj_name + " " + g_vertical_line_index + " t2";
  
  ObjectCreate(0, text_object_name, OBJ_TEXT, 0, three_eight_two, three_eight_two_price);
  ObjectSetString(0, text_object_name, OBJPROP_TEXT, text + " t2");
  ObjectGetInteger(0, text_object_name, OBJPROP_COLOR, clrWhite);
  ObjectSetInteger(0, text_object_name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);

  g_vertical_line_index++;
  
  
  //
  // draw hfibs 0.618
  // 
  
  //Print("drawing vline at: " + TimeToString(three_eight_two));
  ObjectCreate(0, obj_name + g_vertical_line_index, OBJ_VLINE, 0, six_one_eight,0);
  //ObjectSetInteger(0, obj_name + g_vertical_line_index, OBJPROP_COLOR, 0x0033FF);
  ObjectSetInteger(0, obj_name + g_vertical_line_index, OBJPROP_COLOR, 0xFF3300); //dark
  //ObjectSetInteger(0, obj_name + g_vertical_line_index, OBJPROP_COLOR, new_clr);
  
  //ObjectCreate(0, obj_name + g_vertical_line_index + "t3", OBJ_TEXT, 0, zero,0);
  //ObjectSetString(0, obj_name + g_vertical_line_index + "t3" ,OBJPROP_TEXT,obj_name + g_vertical_line_index + " 3");
  
  //
  // give hfibs 0.618 a label for identification
  //
  
  text_object_name = obj_name + " " + g_vertical_line_index + " t3";
  
  ObjectCreate(0, text_object_name, OBJ_TEXT, 0, six_one_eight, three_eight_two_price); //we use price of three_eight_two because we dont know the price yet
  ObjectSetString(0, text_object_name, OBJPROP_TEXT, text + " t3");
  ObjectGetInteger(0, text_object_name, OBJPROP_COLOR, clrWhite);
  ObjectSetInteger(0, text_object_name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);

  g_vertical_line_index++;
  //Print("drawing vline at: " + TimeToString(six_one_eight));
}

int directionalBin(){
      
      
      
 		MqlRates PriceLastSevenBars[8]; //array last field seems to be required empty
	   CopyRates(_Symbol,g_bin_period,0,8,PriceLastSevenBars);
	   //printing values of last 7 bars
	   //ArraySetAsSeries(PriceLastSevenBars, false); //doesnt seem to have an effect
	   
	   /*
	   Print("IN&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
	   //[7] is the (moving?)price of the current candle [6]is first bar to the left
	   for(int i = 0; i < 8; i++){
	     Print("candleindex in array " + i + ": " + PriceLastSevenBars[i].high);
	   }
	   Print("OUT&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
	   */
	   
	   //TODO draw text object at price/time of bin ("-" green when larger, red when smaller than compared value)
	   
	   //[7] is the (moving?)price of the current candle [6]is first bar to the left
	   double current_bar_high_minus_low_halfed = PriceLastSevenBars[7].low + ((PriceLastSevenBars[7].high - PriceLastSevenBars[7].low) / 2.0);
	   double left_bar_high_minus_low_halfed = 0;
	   int bin = 0;
	   
	   //Print("IIIIIIII current bar high: " + PriceLastSevenBars[7].high);
	   
	   //wenn links größer dann + 1  //19.2.20 pattern with + and -
	   for(int i = 6; i >= 0; i--){
	   
	   
	     left_bar_high_minus_low_halfed = PriceLastSevenBars[i].low + ((PriceLastSevenBars[i].high - PriceLastSevenBars[i].low) / 2.0);
	     
	     //bin += (left_bar_high_minus_low_halfed > current_bar_high_minus_low_halfed) ? 1 : (-1);
	     
	     if(left_bar_high_minus_low_halfed > current_bar_high_minus_low_halfed){
	       
	       bin += 1;
	       
	       string new_name = (string)g_bin_index;
          g_bin_index += 1;
          ObjectCreate(0, new_name, OBJ_TEXT, 0, PriceLastSevenBars[i].time, left_bar_high_minus_low_halfed);
          ObjectSetString(0, new_name, OBJPROP_TEXT, "+");
          ObjectSetInteger(0,new_name, OBJPROP_COLOR, clrGreen);
          ObjectSetInteger(0, new_name, OBJPROP_FONTSIZE, 24);
          ObjectSetInteger(0, new_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
          
	     }
	     else if(left_bar_high_minus_low_halfed < current_bar_high_minus_low_halfed){
	     
	       bin -= 1;
	       
	       string new_name = (string)g_bin_index;
          g_bin_index += 1;
          ObjectCreate(0, new_name, OBJ_TEXT, 0, PriceLastSevenBars[i].time, left_bar_high_minus_low_halfed);
          ObjectSetString(0, new_name, OBJPROP_TEXT, "-");
          ObjectSetInteger(0,new_name, OBJPROP_COLOR, clrRed);
          ObjectSetInteger(0, new_name, OBJPROP_FONTSIZE, 24);
          ObjectSetInteger(0, new_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
	       
	     }
	     
	     
	     //Print(left_bar_high_minus_low_halfed + " > " + current_bar_high_minus_low_halfed);
	     //Print(")))))))))))))))))))))))))))))))))))))))))bin is " + bin);
	     //PriceLastSevenBars
	   }
	   
	 //Print("bin is " + bin + ", for date: " + TimeCurrent());  
      
      return bin;

}

void drawObjects(double &max_high[], double &max_time[]){

////this section is about drawin hfibs object, which should be placed at 0.0 and 0.382

 //string obj_name = "extremum_high";

 //string obj_name_2 = "extremum_time";

  //printf("ARRAY SIZE: %d", ArraySize(max_high)); //both 100, as should be, but only 6 valid values
  //printf("ARRAY SIZE: %d", ArraySize(max_time));


 //for(int i = 0; i < ArraySize(max_high); i++)
 
 /*
 for(int i = 0; i < 7; i++)
 {
   printf("drawing arrow at time: %f high: %f", max_time[i], max_high[i]);
   ObjectCreate(0, obj_name + i, OBJ_ARROW_DOWN,0,max_time[i],max_high[i]);   
   
   //ObjectCreate(0, obj_name_2 + i, OBJ_ARROW_CHECK,0,0,hfibPoints[i]);
   //ObjectSetInteger(0,obj_name_2 + i, OBJPROP_COLOR,clrCyan);
 }

*/

}