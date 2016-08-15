//+------------------------------------------------------------------+
//|                                                           BB.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict


int calculateBBTrend() {
   /*
    * BB shall provide info on whether the trend is positive or negative
    * Also, it shall consider Buy/Sell opportunities when volatility is low.
    */
   double bb2_middle = iBands(NULL, 0, iPeriod1, 2.0, 0, PRICE_CLOSE, MODE_MAIN, 0);
   double bb2_bottom = iBands(NULL, 0, iPeriod1, 2.0, 0, PRICE_CLOSE, MODE_LOWER, 0);
   double bb2_top = iBands(NULL, 0, iPeriod1, 2.0, 0, PRICE_CLOSE, MODE_UPPER, 0);
   
   // bb3_middle = iBands(NULL, 0, Period1, 3.0, 0, PRICE_CLOSE, MODE_MAIN);
   // bb3_bottom = iBands(NULL, 0, Period1, 3.0, 0, PRICE_CLOSE, MODE_LOWER);
   // bb3_top = iBands(NULL, 0, Period1, 3.0, 0, PRICE_CLOSE, MODE_UPPER);
   
   if (Bid >= bb2_middle) { // Positive Tunnel
      if (Bid <= bb2_top) { // Inside Positive Tunnel
         return TREND_POSITIVE;   
      } else { // Breakout Over Positive Tunnel
         // TODO: check bb3_top
         // bb3_top = iBands(NULL, 0, Period1, 3.0, 0, PRICE_CLOSE, MODE_UPPER, 0);
         return TREND_POSITIVE_OVERBOUGHT;   
      }
   } else { // Negative Tunnel
      if (Bid >= bb2_bottom) { // Inside Negative Tunnel
         return TREND_NEGATIVE;
      } else { // Breakout Negative Tunnel
         return TREND_NEGATIVE_OVERSOLD;
      }
   }
   
}
