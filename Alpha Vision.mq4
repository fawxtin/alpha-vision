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
input int iMajorTimeFrame = PERIOD_H4;

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
   
   //if (iDebug) {
   //   PrintFormat("[AV.MT.HMA] Major signal %s / Minor signal %s",
   //               mtMajor.simplify(), mtMinor.simplify());
   //   PrintFormat("[AV.CT.HMA] Major Signal (%d -> %s) / Minor signal (%d -> %s)",
   //               ctMajor.getTrend(), ctMajor.simplify(), ctMinor.getTrend(), ctMinor.simplify());
   //}
   
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
   
   tradeSimple(ctMajor, ctMinor);
   /*
   if (mtMajorSimplified != mtMinorSimplified) { // Neutral trend
      tradeNeutralTrend(ctMajor, ctMinor);
   } else if (mtMajorSimplified == "POSITIVE") { // Positive trend
      //tradePositiveTrend(ctMajor, ctMinor, mtMinor.getTrend());
      tradeNeutralTrend(ctMajor, ctMinor);
   } else if (mtMajorSimplified == "NEGATIVE") { // Negative trend
      //tradeNegativeTrend(ctMajor, ctMinor, mtMinor.getTrend());
      tradeNeutralTrend(ctMajor, ctMinor);
   }*/

}

void tradeSimple(HMATrend *major, HMATrend *minor) {
   switch (minor.getTrend()) {
      case TREND_POSITIVE_FROM_NEGATIVE: // go long
         coverShorts();
         goLong(major, minor);
         break;
      case TREND_NEGATIVE_FROM_POSITIVE: // go short
         sellLongs();
         goShort(major, minor);
         break;
      default:
         break;
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
   
   if (major.simplify() != minor.simplify()) { // undecision
      // go with minor trend scalps
      switch (minor.getTrend()) {
         case TREND_POSITIVE_FROM_NEGATIVE: // go long
            coverShorts();
            goLong(major, minor);
            break;
         case TREND_NEGATIVE_FROM_POSITIVE: // go short
            sellLongs();
            goShort(major, minor);
            break;
         default:
            break;
      }
   } else if (minor.simplify() == "POSITIVE") { // trending positive - trade when crossing
      if (minor.getTrend() == TREND_POSITIVE_FROM_NEGATIVE ||
          major.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
         coverShorts();
         goLong(major, minor);
      }
   } else { // trending negative / trade when crossing
      if (minor.getTrend() == TREND_NEGATIVE_FROM_POSITIVE ||
          major.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
         sellLongs();
         goShort(major, minor);
      }
   }   
}

void tradePositiveTrend(HMATrend *major, HMATrend *minor, int mtMinorTrend) {
   if (mtMinorTrend == TREND_NEGATIVE_FROM_POSITIVE) {
      sellLongs(); // close longs
      return;
   }
   
   if (minor.getTrend() == TREND_POSITIVE_FROM_NEGATIVE ||
       major.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goLong(major, minor);
   }
}

void tradeNegativeTrend(HMATrend *major, HMATrend *minor, int mtMinorTrend) {
   if (mtMinorTrend == TREND_POSITIVE_FROM_NEGATIVE) {
      coverShorts(); // cover shorts
      return;
   }

   if (minor.getTrend() == TREND_NEGATIVE_FROM_POSITIVE ||
       major.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goShort(major, minor);
   }
}

void goLong(HMATrend *major, HMATrend *minor) {
   if (gLongPositions.lastBar() == Bars || gLongPositions.count() >= MAX_POSITIONS) return; // already traded / full
   //OrderSend
   if (iDebug) {
      PrintFormat("[AV.CT.HMA] Major Signal (%d -> %s) / Minor signal (%d -> %s) / [last bar %d/current bar %d]",
                  major.getTrend(), major.simplify(), minor.getTrend(), minor.simplify(), gLongPositions.lastBar(), Bars);
   }
   double price = Ask;
   int ticket = OrderSend(Symbol(), OP_BUY, LOT_SIZE, price, 3, 0, 0, "", MAGICMA, clrAliceBlue);
   if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      gLongPositions.add(new Position(ticket, OrderOpenTime(), OrderLots(),
                                      OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
      gLongPositions.setLastBar(Bars);
   }
}

void sellLongs() {
   double price = Bid;
   int oCount = gLongPositions.count();
   PositionValue fullPosition = gLongPositions.meanPositionValue();
   for (int i = 0; i < oCount; i++) {
      Position *p = gLongPositions[i];
      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[AV.sellLongs.%d/%d] Closing order %d (buy price %.4f -> sell price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      }
   }
   if (oCount > 0) {
      PrintFormat("[AV.sellLongs] Closed %d orders (size %.2f) / (long MP %.4f -> sell at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      gLongPositions.clear();
   }
}

void goShort(HMATrend *major, HMATrend *minor) {
   if (gShortPositions.lastBar() == Bars || gShortPositions.count() >= MAX_POSITIONS) return; // already traded?
   // short trades
   if (iDebug) {
      PrintFormat("[AV.CT.HMA] Major Signal (%d -> %s) / Minor signal (%d -> %s) / [last bar %d/current bar %d]",
                  major.getTrend(), major.simplify(), minor.getTrend(), minor.simplify(), gShortPositions.lastBar(), Bars);
   }
   double price = Bid;
   int ticket = OrderSend(Symbol(), OP_SELL, LOT_SIZE, price, 3, 0, 0, "", MAGICMA, clrPink);
   if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      gShortPositions.add(new Position(ticket, OrderOpenTime(), OrderLots(),
                                       OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
      gShortPositions.setLastBar(Bars);
   }
}

void coverShorts() {
   double price = Ask;
   int oCount = gShortPositions.count();
   PositionValue fullPosition = gShortPositions.meanPositionValue();
   for (int i = 0; i < oCount; i++) {
      Position *p = gShortPositions[i];
      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[AV.coverShorts.%d/%d] Closing order %d (sell price %.4f -> buy price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      }
   }
   if (oCount > 0) {
      PrintFormat("[AV.coverShorts] Closed %d orders (size %.2f) / (sell MP %.4f -> cover at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      gShortPositions.clear();
   }
}
