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

////
//// INPUTS
////
input int iPeriod1 = 20;
input int iPeriod2 = 50;
input int iPeriod3 = 200;
// TODO: input higher time interval than current
input bool iDebug = True;
input int iMajorTimeFrame = PERIOD_D1;

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

////
//// GLOBALS
////
Positions *gLongPositions;
Positions *gShortPositions;

int OnInit() {
   // TODO: load current positions
   if (Period() >= iMajorTimeFrame) {
      Alert("Current timeframe is equal/higher than Major timeframe");
      return INIT_PARAMETERS_INCORRECT;
   }
   gLongPositions = new Positions("LONG");
   gShortPositions = new Positions("SHORT");
   gLongPositions.loadCurrentOrders();
   gShortPositions.loadCurrentOrders();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   //EventKillTimer();
   Print("Bye Bye!");
   delete gLongPositions;
   delete gShortPositions;
}

void OnTick() {
   /*
    * Calculate current trend and support/resistence levels
    */
   
   if (Bars < 100) {
      Print("Too few bars.");
      return;
   }

   calculateTrends();
}

void calculateTrends() {
   // HMA current timeframe minor and major trend
   HMATrend *ctMajor = new HMATrend();
   ctMajor.calculate(iPeriod2, iPeriod3);
   HMATrend *ctMinor = new HMATrend();
   ctMinor.calculate(iPeriod1, iPeriod2);
   
   // HMA major timeframe minor and major trends
   HMATrend *mtMajor = new HMATrend(iMajorTimeFrame);
   mtMajor.calculate(iPeriod2, iPeriod3);
   HMATrend *mtMinor = new HMATrend(iMajorTimeFrame);
   mtMinor.calculate(iPeriod1, iPeriod2);
   
   if (iDebug) {
      PrintFormat("[AV.MT.HMA] Major signal %s / Minor signal %s",
                  mtMajor.simplify(), mtMinor.simplify());
      PrintFormat("[AV.CT.HMA] Major Signal (%d -> %s) / Minor signal (%d -> %s)",
                  ctMajor.getTrend(), ctMajor.simplify(), ctMinor.getTrend(), ctMinor.simplify());
   }
   
   // TODO: Execute a trade according to trend values
   tradeOnTrends(mtMajor, mtMinor, ctMajor, ctMinor);
   
   delete ctMajor;
   delete ctMinor;
   delete mtMajor;
   delete mtMinor;
}

void tradeOnTrends(HMATrend *mtMajor, HMATrend *mtMinor, HMATrend *ctMajor, HMATrend *ctMinor) {
   /*
    * Create an Alpha Vision class handling the trends and positions
    *
    * Problems to solve:
    *    a) OK do not execute the same signal more than once
    *    b) Position opening with target/stopLoss:
    *       1) Trend POSITIVE (mtMajor POSITIVE & mtMinor POSITIVE)
    *          Open long on crossing up from ctMinor and ctMajor
    *          Close only when mtMinor turns NEGATIVE (enters NEUTRAL)
    *       2) Trend NEUTRAL (mtMajor != mtMinor)
    *          Cover short & Open long on crossing up / from ctMinor and ctMajor
    *          Close long & Open short on crossing down / from ctMinor and ctMajor
    *       3) Trend NEGATIVE (mtMajor NEGATIVE & mtMinor NEGATIVE)
    *          Open short on crossing down from ctMinor and ctMajor
    *          Close only when mtMinor turns POSITIVE (enters NEUTRAL)
    *
    */
   
   string mtMajorSimplified = mtMajor.simplify();
   string mtMinorSimplified = mtMinor.simplify();
   
   if (mtMajorSimplified != mtMinorSimplified) { // Neutral trend
      tradeNeutralTrend(ctMajor, ctMinor);
   } else if (mtMajorSimplified == "POSITIVE") { // Positive trend
      tradePositiveTrend(ctMajor, ctMinor, mtMinor.getTrend());  
   } else if (mtMajorSimplified == "NEGATIVE") { // Negative trend
      tradeNegativeTrend(ctMajor, ctMinor, mtMinor.getTrend());
   }

}

void tradeNeutralTrend(HMATrend *major, HMATrend *minor) {
   /* neutral territory, scalp setup
    * 1) major != minor
    *    open and close positions on crossing
    * 2) major == minor
    *    only close positions on major crossing?
    *
    */
   
   // current timeframe minor trend cross
   switch (minor.getTrend()) {
      TREND_POSITIVE_FROM_NEGATIVE: // go long
         goLong();
         return;
      default:
        break;
   }
   
   // current timeframe major trend cross
   switch (major.getTrend()) {
      TREND_POSITIVE_FROM_NEGATIVE: // add more long
         goLong();
         return;
      default:
         break;   
   }   
}

void tradePositiveTrend(HMATrend *major, HMATrend *minor, int mtMinorTrend) {
   if (mtMinorTrend == TREND_NEGATIVE_FROM_POSITIVE) {
      sellLongs(); // close longs
      return;
   }
   
   // current timeframe minor trend cross
   switch (minor.getTrend()) {
      TREND_POSITIVE_FROM_NEGATIVE: // go long
         goLong();
         return;
      default:
        break;
   }
   
   // current timeframe major trend cross
   switch (major.getTrend()) {
      TREND_POSITIVE_FROM_NEGATIVE: // add more long
         goLong();
         return;
      default:
         break;   
   }
}

void tradeNegativeTrend(HMATrend *major, HMATrend *minor, int mtMinorTrend) {
   if (mtMinorTrend == TREND_POSITIVE_FROM_NEGATIVE)
      coverShorts(); // cover shorts

   // current timeframe minor trend cross
   switch (minor.getTrend()) {
      TREND_NEGATIVE_FROM_POSITIVE: // go long
         goShort();
         return;
      default:
        break;
   }
   
   // current timeframe major trend cross
   switch (major.getTrend()) {
      TREND_NEGATIVE_FROM_POSITIVE: // add more long
         goShort();
         return;
      default:
         break;   
   }
}

void goLong() {
   if (gLongPositions.lastBar() == Bars || gLongPositions.count() >= MAX_POSITIONS) return; // already traded / full
   //OrderSend
}

void sellLongs() {

}

void goShort() {
   if (gShortPositions.lastBar() == Bars || gShortPositions.count() >= MAX_POSITIONS) return; // already traded?
   // short trades
}

void coverShorts() {

}
