//+------------------------------------------------------------------+
//|                                                       Header.mqh |
//|                                             Copyright 2018, DNG® |
//|                                 http://www.mql5.com/en/users/dng |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  Structures                                                      |
//+------------------------------------------------------------------+
   struct s_Extremum
     {
      datetime          TimeStartBar;
      double            Price;
      
      s_Extremum(void)  :  TimeStartBar(0),
                           Price(0)
         {
         }
      void Clear(void)
        {
         TimeStartBar=0;
         Price=0;
        }
     };
//+------------------------------------------------------------------+
//|  Includes                                                        |
//+------------------------------------------------------------------+
#include <Trade\LimitTakeProfit.mqh>
#include <Arrays\ArrayObj.mqh>
#include "ZigZag.mqh"
#include "Trends.mqh"
#include "Pattern.mqh"
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
sinput   string            s1             =  "---- ZigZag Settings ----";     //---
input    int               i_Depth        =  12;                              // Depth
input    int               i_Deviation    =  100;                             // Deviation
input    int               i_Backstep     =  3;                               // Backstep
input    int               i_MaxHistory   =  1000;                            // Max history, bars
input    ENUM_TIMEFRAMES   e_TimeFrame    =  PERIOD_M30;                      // Work Timeframe
sinput   string            s2             =  "---- Pattern Settings ----";    //---
input    double            d_MinCorrection=  0.118;                           // Minimal Correction
input    double            d_MaxCorrection=  0.5;                             // Maximal Correction
input    ENUM_TIMEFRAMES   e_ConfirmationTF= PERIOD_M5;                       // Timeframe for confirmation
sinput   string            s3             =  "---- Trade Settings ----";      //---
input    double            d_Lot          =  0.1;                             // Trade Lot
input    ulong             l_Slippage     =  10;                              // Slippage
input    uint              i_SL           =  350;                             // Stop Loss Backstep, points
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CArrayObj         *ar_Objects;
CTrade            *Trade;
CPattern          *Pattern;
datetime           start_search;
//+------------------------------------------------------------------+

