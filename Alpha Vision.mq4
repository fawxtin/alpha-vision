//+------------------------------------------------------------------+
//|                                                 Alpha Vision.mq4 |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property version   "1.001"
#property strict

#include <Trends\trends.mqh>
#include <Trends\HMA.mqh>

#include <Positions\Positions.mqh>


input int iPeriod1 = 20;
input int iPeriod2 = 50;
input int iPeriod3 = 200;
// TODO: input higher time interval than current
input bool iDebug = True;
input int iHigherTimeFrame = PERIOD_D1;

/*
 * Create an AlphaVision class that handles with:
 *    - HMA minor/major trend (current time interval)
 *    - HMA minor/major trend (higher time interval / given by input)
 *    - BB std2/std3 trends (current time interval)
 *    - BB std2/std3 trends (higher time interval)
 *    - ATR (current time interval)
 *    - ATR (higher time interval)
 *    - calculate support / resistence ? use BB?
 *
 * Calculate possible entry points, given mixed data:
 *    - HMA cross
 *    - BB bottom/top
 *    - BB crossing MA (changing tunnels)
 *    - BB overtops/overbottoms (reverses) 
 * 
 * Calculate Risk & Reward ratio (check if entry point is good/valid):
 *    - Volatility
 *    - ATR
 *    - Stochastic?
 *
 */

int OnInit() {
   // TODO: load current positions
   Positions positions = new Positions();
   positions.l
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   //EventKillTimer();
   Print("Bye Bye!");
}

void OnTick() {
   /*
    * Calculate current trend and support/resistence levels
    */
   
   if (Bars < 100) {
      Print("Too few bars.");
      return;
   }
   // TODO: the trend object must have the method to calculate its trend.
   // create using *trend = new ... ; and delete the pointer later using delete trend
   HMATrend *majorTrend = new HMATrend();
   majorTrend.calculate(iPeriod2, iPeriod3);
   HMATrend *minorTrend = new HMATrend();
   minorTrend.calculate(iPeriod1, iPeriod2);
   
   if (iDebug) {
      Print("Major Signal (", majorTrend.getTrend(), " -> ", majorTrend.simplify(),
            ") / Minor Signal (", minorTrend.getTrend(), " -> ", minorTrend.simplify(), ")");
   }
   
   // TODO: Execute a trade according to trend values
   majorTrend.alert();
   minorTrend.alert();
   
   delete majorTrend;
   delete minorTrend;
}

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

int calculateSMITrend() {
   /*
    * SMI 6 / 15
    * SMI 18 / 40
    *
    */
    return 0;
}