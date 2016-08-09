//+------------------------------------------------------------------+
//|                                                          HMA.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>

int CalculateHMATrend(int Period1, int Period2) {
   double ma1 = iCustom(NULL, 0, "hma", Period1, 0, MODE_LWMA, PRICE_TYPICAL, 0, 0);
   double ma1_i = iCustom(NULL, 0, "hma", Period1, 0, MODE_LWMA, PRICE_TYPICAL, 0, 1);
   double ma2 = iCustom(NULL, 0, "hma", Period2, 0, MODE_LWMA, PRICE_TYPICAL, 0, 0);
   double ma2_i = iCustom(NULL, 0, "hma", Period2, 0, MODE_LWMA, PRICE_TYPICAL, 0, 1);

   Alert("MA ", Period1, " (", ma1_i, ", ", ma1, ") / MA ", Period2, " (", ma2_i, ", ", ma2, ")");
   if (ma1_i >= ma2_i) { // came from a bull context
      if (ma1 > ma2) {
         return TREND_POSITIVE;
      } else { // switching to bear!
         return TREND_NEGATIVE_FROM_POSITIVE;
      }
   } else { // came from a bear context
      if (ma1 >= ma2) {
         return TREND_POSITIVE_FROM_NEGATIVE;
      } else {
         return TREND_NEGATIVE;
      }
   }
}
