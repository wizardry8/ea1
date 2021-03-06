//USE THIS INDICATOR TOGETHER WITH customIndExp1.mq5 INDICATOR
//ITS FOR DEVELOPING A HFIB EA
//indicator draws all fibs
//indicator sends only entry dates to expert
//expert discards outdated entry and saves future dates chronologically sorted

//try recalculating with every new bar that is coming, and check for last_max != this_max

//+-----------------------------------------------------------------+
//|                                                    tutorial4.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots 5

input int pseudo_input = 0;
input int inp_start_bar = 500;       //the nr of bars from which the search will begin  
//input int inp_search_width = 10;    //nr of bars that are compared in one step
input int fib_placement = 4;

//removed the input variables because it caused some unexplainable behavior when testing the expert
//int inp_start_bar = 500;
//int inp_search_width = 10;
int inp_search_width = 10;
//int fib_placement = 4;

int g_object_counter = 0;

double g_max_high[];       //these two arrays actually store the maxiums found
double g_max_time[];
double g_max_high_temp[];
double g_max_time_temp[];
int	 g_temp_array_max_index = 0;
double g_last_max_time = 0;

double g_min_low[];
double g_min_time[];
double g_min_low_temp[];
double g_min_time_temp[];
int    g_temp_array_min_index = 0;
double g_last_min_time = 0;

double g_combined_price[];
double g_combined_time[];
double g_combined_min_or_max[]; //max = true
int    g_combined_index = 0;
double g_last_combined_time = 0;
int    g_combine_offset = 0;


int    g_offset_bars[];			//delete?
int    g_wait_for_new_bars = 0;	//delete?

//int g_extremum = 0;
//int g_temp_counter = 0;


double g_price_combined_no_buffer[];
double g_time_combined_no_buffer[];
double g_min_or_max_combined_no_buffer[];
int g_combined_no_buffer_index = 0;

double g_price_combined_temp_no_buffer[];
double g_time_combined_temp_no_buffer[];
double g_min_or_max_combined_temp_no_buffer[];
int g_combined_temp_no_buffer_index = 0;

double g_entries[];
int g_entries_index = 0;

bool g_init = false;


void OnDeinit(const int reason)
{
  ObjectsDeleteAll(0,-1,-1);       
}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- indicator buffers mapping
   
   ArrayResize(g_max_high, 1000000);
   ArrayResize(g_max_time, 1000000);
   ArrayResize(g_max_high_temp, 1000000);
   ArrayResize(g_max_time_temp, 1000000);

   ArrayInitialize(g_max_high,0);
   ArrayInitialize(g_max_time, 0);
   ArrayInitialize(g_max_high_temp,0);
   Print("arrB size1: " + ArraySize(g_max_high_temp));
   ArrayInitialize(g_max_time_temp, 0);

	  
   ArrayResize(g_min_low, 1000000);
   ArrayResize(g_min_time, 1000000);
   ArrayResize(g_min_low_temp, 1000000);
   ArrayResize(g_min_time_temp, 1000000);
   
   ArrayInitialize(g_min_low,0);
   ArrayInitialize(g_min_time, 0);
   ArrayInitialize(g_min_low_temp,0);
   ArrayInitialize(g_min_time_temp, 0);
   
   
   ArrayResize(g_combined_price, 1000000);
   ArrayResize(g_combined_time, 1000000);
   ArrayResize(g_combined_min_or_max, 1000000);
  
   ArrayInitialize(g_combined_price, 0);
   //Print("arr size1: " + ArraySize(g_combined_price));
   ArrayInitialize(g_combined_time, 0);
   ArrayInitialize(g_combined_min_or_max, 0);
   
   
   ArrayResize(g_price_combined_no_buffer, 100000);
   ArrayResize(g_time_combined_no_buffer, 100000);
   ArrayResize(g_min_or_max_combined_no_buffer, 100000);
   
   ArrayInitialize(g_price_combined_no_buffer, 0);
   ArrayInitialize(g_time_combined_no_buffer,0);
   ArrayInitialize(g_min_or_max_combined_no_buffer, 0);
	
	//14.4.21 changed buffer size to 100000 until I remember what I wanted to do with it
   //ArrayResize(g_price_combined_temp_no_buffer,25);
   //ArrayResize(g_time_combined_temp_no_buffer,25);
   //ArrayResize(g_min_or_max_combined_temp_no_buffer,25);
   ArrayResize(g_price_combined_temp_no_buffer,100000);
   ArrayResize(g_time_combined_temp_no_buffer,100000);
   ArrayResize(g_min_or_max_combined_temp_no_buffer,100000);

   
   ArrayInitialize(g_price_combined_temp_no_buffer,0);
   ArrayInitialize(g_time_combined_temp_no_buffer,0);
   ArrayInitialize(g_min_or_max_combined_temp_no_buffer,0);
   
   
   
   ArrayResize(g_entries, 100000);
   ArrayInitialize(g_entries, 0);
   
	/*
	double g_price_temp_no_buffer[];
   double g_time_temp_no_buffer[];
   double g_min_or_max_temp_no_buffer[];
   double g_temp_no_buffer[];
	*/
	
   SetIndexBuffer(0, g_max_high, INDICATOR_DATA);
   SetIndexBuffer(1, g_max_time, INDICATOR_DATA);
   SetIndexBuffer(2, g_combined_price, INDICATOR_DATA); 
   SetIndexBuffer(3, g_combined_time, INDICATOR_DATA);   
   SetIndexBuffer(4, g_combined_min_or_max, INDICATOR_DATA); //combined because buffer contains min and max
   SetIndexBuffer(5, g_entries, INDICATOR_DATA);
   
   //g_center_of_search = inp_start_bar; //DO I NEED THIS GLOBAL??
   
//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//---

  if(prev_calculated != rates_total){
  
   g_max_high[rates_total - 1] = 0;
   g_max_time[rates_total - 1] = 0;
   
   if(!g_init){

     g_init = true;
     //findMax(time, high, rates_total, g_center_of_search);
     findMax(time, high, rates_total, inp_start_bar);
     findMin(time, low, rates_total, inp_start_bar);
     
     for(int i = 0; i <= g_temp_array_max_index; i++){
       drawExtremum(time, low, high, i, true);
     }
     
	 //draw found maxs
	 if(g_temp_array_max_index >= 1){
       g_last_max_time = g_max_time_temp[g_temp_array_max_index - 1];  //remember last found high, we will compare this to avoid redraw //g_temp_array_index is always indexing the empty top, u need -1

     Print("dbf1000");  //THIS IS NOT EVEN CALLED
	   
        //write the last three maximums into buffer to hand over to expert  
        if(g_temp_array_max_index >= 4 ){
		
		Print("dbf0001");  //THIS IS NOT EVEN CALLED
        	
          for(int i = 1; i <=3; i++){
            g_max_high[rates_total - i] = g_max_high_temp[g_temp_array_max_index - i];
            g_max_time[rates_total - i] = g_max_time_temp[g_temp_array_max_index - i];			
          
		    //fill left side of combined buffer [6][5][4][][][]
		    int COMBINE_OFFSET_LEFT = 3;
		    g_combined_price[rates_total - (i + COMBINE_OFFSET_LEFT)] = g_max_high_temp[g_temp_array_max_index - i];
		    g_combined_time[rates_total - (i + COMBINE_OFFSET_LEFT)] = g_max_time_temp[g_temp_array_max_index - i];
		    g_combined_min_or_max[rates_total - (i + COMBINE_OFFSET_LEFT)] = true;
		  }
		  
        }

     }  
	 
	 //draw the found mins
     for(int i = 0; i <= g_temp_array_min_index; i++){
	   drawExtremum(time, low, high, i, false);
	 }
	 
	 if(g_temp_array_min_index >= 1){
       g_last_min_time = g_min_time_temp[g_temp_array_min_index - 1];  //remember last found high, we will compare this to avoid redraw //g_temp_array_index is always indexing the empty top, u need -1

	 Print("dbf2000");  //THIS IS NOT EVEN CALLED
	   
       //write the last three minimums into buffer to hand over to expert  //THIS IS NOT EVEN CALLED
       if(g_temp_array_min_index >= 4 ){
        
		 Print("dbf0002");  //THIS IS NOT EVEN CALLED
		
         for(int i = 1; i <=3; i++){
           g_min_low[rates_total - i] = g_min_low_temp[g_temp_array_min_index - i];
           g_min_time[rates_total - i] = g_min_time_temp[g_temp_array_min_index - i];
         
		   //fill right side of combined buffer [][][][3][2][1]     
		   int COMBINE_OFFSET_RIGHT = 0;
		   g_combined_price[rates_total - (i + COMBINE_OFFSET_RIGHT)] = g_max_high_temp[g_temp_array_max_index - i];
		   g_combined_time[rates_total - (i + COMBINE_OFFSET_RIGHT)] = g_max_time_temp[g_temp_array_max_index - i];
		   g_combined_min_or_max[rates_total - (i + COMBINE_OFFSET_RIGHT)] = false;
           
		   //sort them inline, the newest first. [6][5][4][][][start] 6,5,4 should be sortet. 4 being highest.
		   int TO_LEFT = 1;
		   for(int combine_index = 1; combine_index <= 5; combine_index++){
		     if(g_combined_time[rates_total - combine_index] < g_combined_time[rates_total - (combine_index + TO_LEFT)]){
			   double switch_temp = 0;
			   
			   switch_temp = g_combined_time[rates_total - combine_index];
			   g_combined_time[rates_total - combine_index] = g_combined_time[rates_total - (combine_index + TO_LEFT)];
			   g_combined_time[rates_total - (combine_index + TO_LEFT)] = switch_temp;
			   
			   switch_temp = g_combined_price[rates_total - combine_index];
			   g_combined_price[rates_total - combine_index] = g_combined_price[rates_total - (combine_index + TO_LEFT)];
			   g_combined_price[rates_total - (combine_index + TO_LEFT)] = switch_temp;
			   
			   switch_temp = g_combined_min_or_max[rates_total - combine_index];
			   g_combined_min_or_max[rates_total - combine_index] = g_combined_min_or_max[rates_total - (combine_index + TO_LEFT)];
			   g_combined_min_or_max[rates_total - (combine_index + TO_LEFT)] = switch_temp;
			 }
			 
           }
         }	 
	   } 	   
     } 
			
   }
   else{
		
	  //find max and mins
      g_wait_for_new_bars = 0;
      findMax(time, high, rates_total, 26); //20 is offset for new high streaming bars //26 old value
      findMin(time, low, rates_total, 26);
      
	  //draw max
      if(g_temp_array_max_index >= 1){     
        if(g_last_max_time != g_max_time_temp[g_temp_array_max_index - 1]){
          
          int i = 1;
          if(g_temp_array_max_index >= 2)
          {
            
            while(g_last_max_time != g_max_time_temp[g_temp_array_max_index - i]){
              drawExtremum(time, low, high, g_temp_array_max_index - i,true);  //search for new entries and draw the extremums
			     fillTempBuffer(time, low, high, g_temp_array_max_index - i, true);
              i++;
            
              for(int j = 1; j < i; j ++){
                g_max_high[rates_total - j] = g_max_high_temp[g_temp_array_max_index - j];
                g_max_time[rates_total - j] = g_max_time_temp[g_temp_array_max_index - j];
				
				//fill right side of combined buffer [][][i][n][2][1]
		        g_combine_offset = i - 1;
		        g_combined_price[rates_total - j] = g_max_high_temp[g_temp_array_max_index - j];
		        g_combined_time[rates_total - j] = g_max_time_temp[g_temp_array_max_index - j];
		        g_combined_min_or_max[rates_total - j] = true;
				
				int TO_LEFT = 1;
		        
				for(int combine_index = 1; combine_index <= 5; combine_index++){
		          if(g_combined_time[rates_total - combine_index] < g_combined_time[rates_total - (combine_index + TO_LEFT)]){
			        double switch_temp = 0;
			   
			        switch_temp = g_combined_time[rates_total - combine_index];
			        g_combined_time[rates_total - combine_index] = g_combined_time[rates_total - (combine_index + TO_LEFT)];
			        g_combined_time[rates_total - (combine_index + TO_LEFT)] = switch_temp;
			   
			        switch_temp = g_combined_price[rates_total - combine_index];
			        g_combined_price[rates_total - combine_index] = g_combined_price[rates_total - (combine_index + TO_LEFT)];
			        g_combined_price[rates_total - (combine_index + TO_LEFT)] = switch_temp;
			   
			        switch_temp = g_combined_min_or_max[rates_total - combine_index];
			        g_combined_min_or_max[rates_total - combine_index] = g_combined_min_or_max[rates_total - (combine_index + TO_LEFT)];
			        g_combined_min_or_max[rates_total - (combine_index + TO_LEFT)] = switch_temp;
			      }
			 
                }
				

              }
              
            }
			
            g_last_max_time = g_max_time_temp[g_temp_array_max_index - 1];
			
          }
          else{
            drawExtremum(time, low, high, g_temp_array_max_index - 1, true);
            g_last_max_time = g_max_time_temp[g_temp_array_max_index - 1];
            g_max_high[rates_total - 1] = g_max_high_temp[g_temp_array_max_index - 1];
            g_max_time[rates_total - 1] = g_max_time_temp[g_temp_array_max_index - 1];
			
		    g_combined_price[rates_total - 1] = g_max_high_temp[g_temp_array_max_index - 1];
		    g_combined_time[rates_total - 1] = g_max_time_temp[g_temp_array_max_index - 1];
		    g_combined_min_or_max[rates_total - 1] = true;
          }

        }
	
      }
	  
	  //draw min
	  if(g_temp_array_min_index >= 1){    
	  
        if(g_last_min_time != g_min_time_temp[g_temp_array_min_index - 1]){
		  //Print("}}}}}}}}}}}}}}}}}}}}}} adding min at: " + TimeToString(g_min_time_temp[g_temp_array_min_index - 1]));
          
          int i = 1;
          if(g_temp_array_min_index >= 2)
          {
            
            while(g_last_min_time != g_min_time_temp[g_temp_array_min_index - i]){
              drawExtremum(time, low, high, g_temp_array_min_index - i, false);  //search for new entries and draw the extremums
			     fillTempBuffer(time, low, high, g_temp_array_min_index - i, false); 
              i++;
            
              for(int j = 1; j < i; j ++){
                g_min_low[rates_total - j] = g_min_low_temp[g_temp_array_min_index - j];
                g_min_time[rates_total - j] = g_min_time_temp[g_temp_array_min_index - j];
				
				//fill left side of combined buffer [n][2][1][i][][]     
		        g_combined_price[rates_total - (j + g_combine_offset)] = g_min_low_temp[g_temp_array_min_index - j];
		        g_combined_time[rates_total - (j + g_combine_offset)] = g_min_time_temp[g_temp_array_min_index - j];
		        g_combined_min_or_max[rates_total - (j + g_combine_offset)] = false;
				//Print("adding multi min at " + rates_total - (j + g_combine_offset) + ": " + TimeToString(g_combined_time[rates_total - (j + g_combine_offset)]));
              }
              
            }
			
            g_last_min_time = g_min_time_temp[g_temp_array_min_index - 1];
			
          }
          else{
            drawExtremum(time, low, high, g_temp_array_min_index - 1, false);
            g_last_min_time = g_min_time_temp[g_temp_array_min_index - 1];
            g_min_low[rates_total - 1] = g_min_low_temp[g_temp_array_min_index - 1];
            g_min_time[rates_total - 1] = g_min_time_temp[g_temp_array_min_index - 1];
			
		    g_combined_price[rates_total - 1] = g_min_low_temp[g_temp_array_min_index - 1];
		    g_combined_time[rates_total - 1] = g_min_time_temp[g_temp_array_min_index - 1];
		    g_combined_min_or_max[rates_total - 1] = false;
			
			//Print("adding single min at " + rates_total - 1 + ": " + TimeToString(g_combined_time[rates_total - 1]));
          }

        }
			
			/* 
			//debug print, prints out last 5 entries of combined array
			Print("A///////////////////////////////////////////");
			for(int x = 1; x<= 5; x++){
			  if(g_combined_time[rates_total - x] != 0)
			  {
			    Print("comb time [" + x + "]: " + TimeToString(g_combined_time[rates_total - x]));
				Print("comb dir [" + x + "]: " + g_combined_min_or_max[rates_total - x]);
			  }
			}
			Print("B///////////////////////////////////////////");
			*/
			
      }

   else{ //DO I NEED THIS? DELETE
     g_wait_for_new_bars += 1;
   }
   }
   
   //resetTempBufferIndex();  //why am I resetting not sure right now maybe need it
   
  }
   
//--- return value of prev_calculated for next call
  return(rates_total);
}
//+------------------------------------------------------------------+

void resetTempBufferIndex(){

	//###
	
	//TODO NEED A MANUAL SORTING ROUTINE swap indexes of the parallel arrays //sort it inline
	//ArraySort(g_price_temp_no_buffer);
	//ArraySort(g_time_temp_no_buffer);
	
	

	
	//	if(is_max){
	//	g_price_temp_no_buffer[g_temp_no_buffer_index] = p_high[index];
	//}else{
	//	g_price_temp_no_buffer[g_temp_no_buffer_index] = p_low[index];
	//}
	
	//g_time_temp_no_buffer[g_temp_no_buffer_index] = p_time[index];
	//g_min_or_max_temp_no_buffer[g_temp_no_buffer_index] = is_max;
	
	//###
	
	//after min and max are stored for this cycle the temp buffer index resets and later the array must be zeroed 
	  
	  //Print("resetTempBufferIndex: index before reset:" + g_combined_temp_no_buffer_index + ", printing array now");
	  if(g_combined_temp_no_buffer_index > 0){
	    ArrayPrint(g_time_combined_temp_no_buffer,_Digits,NULL,0,26,ARRAYPRINT_DATE );
	    ArrayPrint(g_price_combined_temp_no_buffer,_Digits,NULL,0,26,0);
	    ArrayPrint(g_min_or_max_combined_temp_no_buffer,_Digits,NULL,0,26,0);
	  }
	  g_combined_temp_no_buffer_index = 0;
}

void fillTempBuffer(const datetime &p_time[],const double &p_low[], const double &p_high[], int index, bool is_max){
    
	//double g_price_temp_no_buffer[];
	//double g_time_temp_no_buffer[];
	//double g_min_or_max_temp_no_buffer[];
	//int g_temp_no_buffer_index = 0;
	
	//when max take value from high, for min from low
	if(is_max){
	
	   //without sorting just inserting	
	   if(g_combined_temp_no_buffer_index == 0){
	   	 g_price_combined_temp_no_buffer[g_combined_temp_no_buffer_index] = g_max_high_temp[index];
	     Print("fillTempBuffer: adding initial price " + g_max_high_temp[index] + " to buffer");
	     g_time_combined_temp_no_buffer[g_combined_temp_no_buffer_index] = g_max_time_temp[index];
	     Print("fillTempBuffer: adding initial time " + (datetime)g_max_time_temp[index] + " to buffer");
		 g_min_or_max_combined_temp_no_buffer[g_combined_temp_no_buffer_index] = (int)is_max;
	     Print("fillTempBuffer: adding direction " + is_max + " to buffer");  
	   }
	   //end without sorting
	   else{	  
	     //if sorting is needed e.g. [2][3][9][12] <-?(8) => [2][3][9][][12] => [2][3][][9][12] //shift value to right if larger than new
	     int sort_index = g_combined_temp_no_buffer_index - 1; // buffer index should point to first empty, we want first value thats why -1
	     while(g_max_time_temp[index] < g_time_combined_temp_no_buffer[sort_index]){
	       g_time_combined_temp_no_buffer[sort_index + 1] = g_time_combined_temp_no_buffer[sort_index];
		   g_price_combined_temp_no_buffer[sort_index + 1] = g_price_combined_temp_no_buffer[sort_index];
		   g_min_or_max_combined_temp_no_buffer[sort_index + 1] = g_min_or_max_combined_temp_no_buffer[sort_index];
		   sort_index -= 1; 
	     }
	     sort_index += 1; //point to empty again
	   
	     //inserting e.g. [2][3][][9][12] <-?(8) => [2][3][8][9][12]
	     g_price_combined_temp_no_buffer[sort_index] = g_max_high_temp[index];
	     Print("fillTempBuffer: adding price " + g_max_high_temp[index] + " to buffer");
	     g_time_combined_temp_no_buffer[sort_index] = g_max_time_temp[index];
	     Print("fillTempBuffer: adding time " + (datetime)g_max_time_temp[index] + " to buffer");
	     g_min_or_max_combined_temp_no_buffer[sort_index] = (int)is_max;
	     Print("fillTempBuffer: adding direction " + is_max + " to buffer");   	   
	     //end sorting and inserting
		
	   }

	}else{
	
		   //without sorting just inserting	
	   if(g_combined_temp_no_buffer_index == 0){
	   	 g_price_combined_temp_no_buffer[g_combined_temp_no_buffer_index] = g_min_low_temp[index];
	     Print("fillTempBuffer: adding initial price " + g_min_low_temp[index] + " to buffer");
	     g_time_combined_temp_no_buffer[g_combined_temp_no_buffer_index] = g_min_time_temp[index];
	     Print("fillTempBuffer: adding initial time " + (datetime)g_min_time_temp[index] + " to buffer");
		 g_min_or_max_combined_temp_no_buffer[g_combined_temp_no_buffer_index] = (int)is_max;
	     Print("fillTempBuffer: adding direction " + is_max + " to buffer");  
	   }
	   //end without sorting
	   else{	  
	     //if sorting is needed e.g. [2][3][9][12] <-?(8) => [2][3][9][][12] => [2][3][][9][12] //shift value to right if larger than new
	     int sort_index = g_combined_temp_no_buffer_index - 1; // buffer index should point to first empty, we want first value thats why -1
	     while(g_min_time_temp[index] < g_time_combined_temp_no_buffer[sort_index]){
	       g_time_combined_temp_no_buffer[sort_index + 1] = g_time_combined_temp_no_buffer[sort_index];
		   g_price_combined_temp_no_buffer[sort_index + 1] = g_price_combined_temp_no_buffer[sort_index];
		   g_min_or_max_combined_temp_no_buffer[sort_index + 1] = g_min_or_max_combined_temp_no_buffer[sort_index];
		   sort_index -= 1; 
	     }
	     sort_index += 1; //point to empty again
	   
	     //inserting e.g. [2][3][][9][12] <-?(8) => [2][3][8][9][12]
		 Print("DBF1");
	     g_price_combined_temp_no_buffer[sort_index] = g_min_low_temp[index];
	     Print("fillTempBuffer: adding price " + g_min_low_temp[index] + " to buffer");
	     g_time_combined_temp_no_buffer[sort_index] = g_min_time_temp[index];
	     Print("fillTempBuffer: adding time " + (datetime)g_min_time_temp[index] + " to buffer");
	     g_min_or_max_combined_temp_no_buffer[sort_index] = (int)is_max;
	     Print("fillTempBuffer: adding direction " + is_max + " to buffer");   	   
	     //end sorting and inserting
	   }
	}

	g_combined_temp_no_buffer_index += 1;
	Print("fillTempBuffer: end of fill temp buffer, fill temp buffer index now: " + g_combined_temp_no_buffer_index);
		
	//printing buffer for debug
	Print("Array Time"); ArrayPrint(g_time_combined_temp_no_buffer,_Digits,NULL,0,26,ARRAYPRINT_DATE );
	Print("Array Price"); ArrayPrint(g_price_combined_temp_no_buffer,_Digits,NULL,0,26,0);
	Print("Array Dir"); ArrayPrint(g_min_or_max_combined_temp_no_buffer,_Digits,NULL,0,26,0);
	//
	
}

void findMax(const datetime &p_time[], const double &p_high[], const int rates_total, int center_of_search){ //int center_of_search should be call by copy not reference, careful

  ArraySetAsSeries(p_time,true);
  ArraySetAsSeries(p_high,true);

  int search_padding = 2; //one for center of search + one for zero index
  
  int temp_delete = inp_search_width + search_padding;
  

  while(center_of_search > inp_search_width + search_padding){

    for( ; !isMax(p_high, center_of_search) && center_of_search > inp_search_width + search_padding ; center_of_search--);
    if(!(center_of_search <= inp_search_width + search_padding)){ //make sure the last center of search which is no max doesnt get mistaken as one
      
      //filter out maximums that form when two bars have same high value (and are actually no real max)
      if(!(g_temp_array_max_index > 1 && g_max_high_temp[g_temp_array_max_index - 1] == p_high[center_of_search])){
         
        g_max_high_temp[g_temp_array_max_index] = p_high[center_of_search];  //stash the found extremums in temp array
        g_max_time_temp[g_temp_array_max_index] = p_time[center_of_search];
        //g_offset_bars[g_temp_array_max_index] == center_of_search;
      
        g_temp_array_max_index += 1;
      }

    }  
    center_of_search -= 1;
  }
  
}

void findMin(const datetime &p_time[], const double &p_low[], const int rates_total, int center_of_search){ //int center_of_search should be call by copy not reference, careful

  ArraySetAsSeries(p_time,true);
  ArraySetAsSeries(p_low,true);

  int search_padding = 2; //one for center of search + one for zero index
  
  int temp_delete = inp_search_width + search_padding;
  

  while(center_of_search > inp_search_width + search_padding){

    for( ; !isMin(p_low, center_of_search) && center_of_search > inp_search_width + search_padding ; center_of_search--);
    if(!(center_of_search <= inp_search_width + search_padding)){ //make sure the last center of search which is no max doesnt get mistaken as one
      
      //filter out minimums that form when two bars have same low value (and are actually no real min)
      if(!(g_temp_array_min_index > 1 && g_min_low_temp[g_temp_array_min_index - 1] == p_low[center_of_search])){
         
        g_min_low_temp[g_temp_array_min_index] = p_low[center_of_search];  //stash the found extremums in temp array
        g_min_time_temp[g_temp_array_min_index] = p_time[center_of_search];
        //g_offset_bars[g_temp_array_min_index] == center_of_search;  //delete this?
      
        g_temp_array_min_index += 1;
      }

    }  
    center_of_search -= 1;
  }
  
}

bool isMax(const double &p_high[], int center_of_search){

  for(int i = 0; i < inp_search_width; i++){
    if(p_high[center_of_search + i] > p_high[center_of_search] || p_high[center_of_search - i] > p_high[center_of_search]){
      return false;
    }
      
  }
  return true;
}

bool isMin(const double &p_low[], int center_of_search){

  for(int i = 0; i < inp_search_width; i++){
    if(p_low[center_of_search + i] < p_low[center_of_search] || p_low[center_of_search - i] < p_low[center_of_search]){
      return false;
    }
      
  }
  return true;
}

void drawExtremum(const datetime &p_time[],const double &p_low[], const double &p_high[], int index, bool is_max){

  string obj_name = "extremum" + g_object_counter;
  string obj_text;
  
  if(is_max){
   obj_text = "MAX" + g_object_counter;
	ObjectCreate(0, obj_name, OBJ_TEXT, 0, g_max_time_temp[index], g_max_high_temp[index]);
  }else{
   obj_text = "MIN" + g_object_counter;
	ObjectCreate(0, obj_name, OBJ_TEXT, 0, g_min_time_temp[index], g_min_low_temp[index]);
  }
  
  ObjectSetString(0, obj_name, OBJPROP_TEXT, obj_text);
  ObjectGetInteger(0, obj_name, OBJPROP_COLOR, clrBisque);
  
  g_object_counter += 1;

}

void calcFibs(const int rates_total){
      
   if(g_combined_temp_no_buffer_index < 2){return;}
       
   double golden_smaller = 0.382;
   double golden_larger = 0.618;
   int first_leg_offset = -1; // this is the newest found extremum
   int second_leg_offset = -2; // -2 means take next extreme for second leg
   
   double max_n = g_time_combined_no_buffer[g_combined_temp_no_buffer_index - first_leg_offset];
   Print("date of max_n: " + TimeToString(max_n));
   double max_n_minus_x = g_time_combined_no_buffer[g_combined_temp_no_buffer_index - second_leg_offset];
   Print("date of max_n_minus_x: " + TimeToString(max_n_minus_x));
   
   double distance_n_minus_x_to_n = max_n - max_n_minus_x; //a not yet corrected (weekend still included)
   
   //ÜÜÜ
   //  reducing distance n - (n-2) by # of weekends for calculating fib3 
   //
   
   MqlDateTime timestruct_max_n_minus_x;
   TimeToStruct(max_n_minus_x, timestruct_max_n_minus_x);
   MqlDateTime timestruct_max_n;
   TimeToStruct(max_n, timestruct_max_n);
   
   int days_between_fibs = timestruct_max_n.day_of_year - timestruct_max_n_minus_x.day_of_year;
   //Print("There are " + days_between_fibs + " days between zero and three(target)");
   //if(days_between_fibs < 0){...} cornercase when transtion between years, skip calc of fibs for now
   
   int weekday_index = timestruct_max_n_minus_x.day_of_week;
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
   
   distance_n_minus_x_to_n -= weekend_count * (86400 * 2 + 3600); //1 day = 86400 seconds, 1h = 3600 seconds
   
   //ÜÜÜ
   
   double time_value_of_larger = distance_n_minus_x_to_n/golden_smaller * golden_larger + max_n_minus_x; //timevalue of 0.618
   //Print("time_value_of_larger: ", + time_value_of_larger);
   Print("date of larger: " + TimeToString(time_value_of_larger));
   
   //ÄÄÄ
   //  increasing distance time_value_of_larger - (n - 2) ) by # of weekends for calculating fib3 
   //
   
   MqlDateTime timestruct_time_value_of_larger;
   TimeToStruct(time_value_of_larger, timestruct_time_value_of_larger);
   //MqlDateTime timestruct_max_n;
   //TimeToStruct(max_n, timestruct_max_n_minus_x);
   
   days_between_fibs = timestruct_time_value_of_larger.day_of_year - timestruct_max_n_minus_x.day_of_year;
   //if(days_between_fibs < 0){...} cornercase when transtion between years, skip calc of fibs for now
   
   weekday_index = timestruct_max_n_minus_x.day_of_week;
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
   double time_value_of_one = distance_n_minus_x_to_n / golden_smaller * 1 + max_n_minus_x;  //timevalue of 1
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
   //TimeToStruct(max_n, timestruct_max_n_minus_x);
   
   days_between_fibs = timestruct_time_value_of_one.day_of_year - timestruct_max_n_minus_x.day_of_year;
   //if(days_between_fibs < 0){...} cornercase when transtion between years, skip calc of fibs for now
   
   weekday_index = timestruct_max_n_minus_x.day_of_week;
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
   //g_pending_enter_time = time_value_of_one;  
   
   //g_new_trade_ready = true;
   
   //drawFibs(g_stored_recieved_time[g_stored_recieved_time_index - 3], g_stored_recieved_max[g_stored_recieved_max_index - 3], g_stored_recieved_time[g_stored_recieved_time_index - 1], g_stored_recieved_max[g_stored_recieved_max_index - 1], time_value_of_one);
   drawFibs(g_time_combined_no_buffer[g_combined_temp_no_buffer_index - second_leg_offset], g_price_combined_temp_no_buffer[g_combined_temp_no_buffer_index - second_leg_offset], g_time_combined_no_buffer[g_combined_temp_no_buffer_index - first_leg_offset], g_price_combined_temp_no_buffer[g_combined_temp_no_buffer_index - first_leg_offset], time_value_of_larger);
   
   //Print("pending trade: " + (datetime)g_pending_enter_time);
   
   //add new entrypoint to buffer
   g_entries[rates_total - 1] = time_value_of_larger; // larger is 0.618
   g_entries_index += 1;
   
    
}

void drawFibs(double zero, double zero_price, double three_eight_two, double three_eight_two_price, double six_one_eight){ //zero, three_eight_two and six_one_eight are time values, six_one_eight may be switched with one
  
  /*
  
  //if(g_debug_done_only_once){
  //  return;
  //}
  //g_debug_done_only_once = true;
  
    
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
  */
}