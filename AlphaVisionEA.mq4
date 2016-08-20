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
#include <Positions\Trader.mqh>
#include <Signals\AlphaVision.mqh>



////
//// INPUTS
////
input int iPeriod1 = 20;
input int iPeriod2 = 50;
input int iPeriod3 = 200;
// TODO: input higher time interval than current
input bool iDebug = True;
input int iFastTimeFrame = PERIOD_M5;
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
AlphaVisionSignals *gAlphaVisionSignals; // all AV signals
Trader *gTrader; // Orders maker

int gCurrentTimeFrame;
int gCountMinutes;

int OnInit() {
   gCurrentTimeFrame = Period();
   
   if (gCurrentTimeFrame >= iMajorTimeFrame) {
      Alert("Current timeframe is equal/higher than Major timeframe");
      return INIT_PARAMETERS_INCORRECT;
   } else if (gCurrentTimeFrame <= iFastTimeFrame) {
      Alert("Current timeframe is equal/lower than Fast timeframe");
      return INIT_PARAMETERS_INCORRECT;   
   }

   // loading current positions
   gTrader = new Trader(new Positions("LONG"), new Positions("SHORT"));
   gTrader.loadCurrentOrders();
   
   gAlphaVisionSignals = new AlphaVisionSignals();
   gAlphaVisionSignals.initOn(gCurrentTimeFrame, iPeriod1, iPeriod2, iPeriod3);
   gAlphaVisionSignals.calculateOn(gCurrentTimeFrame);
   gAlphaVisionSignals.initOn(iMajorTimeFrame, iPeriod1, iPeriod2, iPeriod3);
   gAlphaVisionSignals.calculateOn(iMajorTimeFrame);
   gAlphaVisionSignals.initOn(iFastTimeFrame, iPeriod1, iPeriod2, iPeriod3);
   gAlphaVisionSignals.calculateOn(iFastTimeFrame);

   gCountMinutes = 0;
   EventSetTimer(1 * 60); // Every 1 minute, call onTimer
 
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   // timer
   EventKillTimer();
   
   // positions list
   delete gTrader;
   
   // Signals
   delete gAlphaVisionSignals;

   // TODO: add results calculi
   
   Print("Bye Bye!");
}

void OnTimer() {
   if (gCountMinutes >= 60) gCountMinutes = 0; // 1 hour has passed
   else gCountMinutes++;

   if (gCountMinutes % 3 == 0) { // every 3 minutes
      gAlphaVisionSignals.calculateOn(gCurrentTimeFrame);
   } else if (gCountMinutes % 15 == 0) { // every 15 minutes
      gAlphaVisionSignals.calculateOn(iMajorTimeFrame);
   } else if (gCountMinutes % 28 == 0) {
      // calculate gAlphaVisionSuper - on weekly   
   }
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
   //if (iDebug) {
   //   PrintFormat("[AV.MT.HMA] Major signal %s / Minor signal %s",
   //               mtMajor.simplify(), mtMinor.simplify());
   //   PrintFormat("[AV.CT.HMA] Major Signal (%d -> %s) / Minor signal (%d -> %s)",
   //               ctMajor.getTrend(), ctMajor.simplify(), ctMinor.getTrend(), ctMinor.simplify());
   //}
   
   // TODO: Execute a trade according to trend values
   gAlphaVisionSignals.calculateOn(iFastTimeFrame);
   tradeOnTrends();
}

void tradeOnTrends() {
   /*
    * Create an Alpha Vision class handling the trends and positions
    * New Approach: Crossing signals means points of support and resistence,
    *    depending on the major timeframe trend will take different actions
    *    on these lines (moving pivot?)
    *
    * Problems to solve:
    *    a) Position opening with target/stopLoss:
    *       1) Trend POSITIVE (mtMajor POSITIVE & mtMinor POSITIVE)
    *          Open buy limit on crossing up region from ctMinor and ctMajor
    *          Close signal and range when mtMinor turns NEGATIVE (enters NEUTRAL)
    *       
    *       2) Trend NEUTRAL / Trading Range (mtMajor != mtMinor)
    *          Fast moves... Try to find trading rage from last current signals
    *          Open and close positions or later hedge through based on 
    *          found support and resistance points
    *          
    *       3) Trend NEGATIVE (mtMajor NEGATIVE & mtMinor NEGATIVE)
    *          Open sell limit on crossing down region from ctMinor and ctMajor
    *          Close signal and range when mtMinor turns POSITIVE (enters NEUTRAL)
    *
    */
   AlphaVision *avMt = gAlphaVisionSignals.getAlphaVisionOn(iMajorTimeFrame);
   HMATrend *mtMajor = avMt.m_hmaMajor;
   HMATrend *mtMinor = avMt.m_hmaMinor;
   AlphaVision *avCt = gAlphaVisionSignals.getAlphaVisionOn(gCurrentTimeFrame);
   HMATrend *ctMajor = avCt.m_hmaMajor;
   HMATrend *ctMinor = avCt.m_hmaMinor;
   AlphaVision *avFt = gAlphaVisionSignals.getAlphaVisionOn(iFastTimeFrame);
   HMATrend *ftMajor = avFt.m_hmaMajor;
   HMATrend *ftMinor = avFt.m_hmaMinor;

   string mtMajorSimplified = mtMajor.simplify();
   string mtMinorSimplified = mtMinor.simplify();
   
   tradeSimple(ftMajor, ftMinor);
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
         goLong(minor.getMAPeriod1());
         break;
      case TREND_NEGATIVE_FROM_POSITIVE: // go short
         sellLongs();
         goShort(minor.getMAPeriod1());
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
            goLong(minor.getMAPeriod1());
            break;
         case TREND_NEGATIVE_FROM_POSITIVE: // go short
            sellLongs();
            goShort(minor.getMAPeriod1());
            break;
         default:
            break;
      }
   } else if (minor.simplify() == "POSITIVE") { // trending positive - trade when crossing
      if (minor.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
         coverShorts();
         goLong(minor.getMAPeriod1());
      } else if (major.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
         coverShorts();
         goLong(major.getMAPeriod1());
      }
   } else { // trending negative / trade when crossing
      if (minor.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
         sellLongs();
         goShort(major.getMAPeriod1());
      } else if (major.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
         sellLongs();
         goShort(major.getMAPeriod1());
      }
   }   
}

void tradePositiveTrend(HMATrend *major, HMATrend *minor, int mtMinorTrend) {
   if (mtMinorTrend == TREND_NEGATIVE_FROM_POSITIVE) {
      sellLongs(); // close longs
      return;
   }
   
   if (minor.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goLong(minor.getMAPeriod1());
   } else if (major.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goLong(major.getMAPeriod1());
   }
}

void tradeNegativeTrend(HMATrend *major, HMATrend *minor, int mtMinorTrend) {
   if (mtMinorTrend == TREND_POSITIVE_FROM_NEGATIVE) {
      coverShorts(); // cover shorts
      return;
   }

   if (minor.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goShort(minor.getMAPeriod1());
   } else if (major.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goShort(major.getMAPeriod1());
   }
}

void goLong(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="") {
   Positions *lp = gTrader.getLongPositions();
   if (lp.lastBar() == Bars || lp.count() >= MAX_POSITIONS) return; // already traded / full
   //OrderSend
   double price = Ask;
   int ticket = OrderSend(Symbol(), OP_BUY, LOT_SIZE, price, 3, stopLoss, priceTarget, reason, MAGICMA, clrAliceBlue);
   if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      lp.add(new Position(ticket, OrderOpenTime(), OrderLots(),
                                      OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
      lp.setLastBar(Bars);
   }
}

void sellLongs() {
   Positions *lp = gTrader.getLongPositions();
   double price = Bid;
   int oCount = lp.count();
   PositionValue fullPosition = lp.meanPositionValue();
   for (int i = 0; i < oCount; i++) {
      Position *p = lp[i];
      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[AV.sellLongs.%d/%d] Closing order %d (buy price %.4f -> sell price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      }
   }
   if (oCount > 0) {
      PrintFormat("[AV.sellLongs] Closed %d orders (size %.2f) / (long MP %.4f -> sell at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      lp.clear();
   }
}

void goShort(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="") {
   Positions *sp = gTrader.getShortPositions();
   if (sp.lastBar() == Bars || sp.count() >= MAX_POSITIONS) return; // already traded?
   // short trades
   double price = Bid;
   int ticket = OrderSend(Symbol(), OP_SELL, LOT_SIZE, price, 3, stopLoss, priceTarget, reason, MAGICMA, clrPink);
   if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      sp.add(new Position(ticket, OrderOpenTime(), OrderLots(),
                                       OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
      sp.setLastBar(Bars);
   }
}

void coverShorts() {
   Positions *sp = gTrader.getShortPositions();
   double price = Ask;
   int oCount = sp.count();
   PositionValue fullPosition = sp.meanPositionValue();
   for (int i = 0; i < oCount; i++) {
      Position *p = sp[i];
      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[AV.coverShorts.%d/%d] Closing order %d (sell price %.4f -> buy price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      }
   }
   if (oCount > 0) {
      PrintFormat("[AV.coverShorts] Closed %d orders (size %.2f) / (sell MP %.4f -> cover at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      sp.clear();
   }
}

void debugPrintSignal(HMATrend *major, HMATrend *minor, Positions *positions) {
   if (iDebug) {
      PrintFormat("[AV.CT.HMA] Major Signal (%d -> %s) / Minor signal (%d -> %s) / [last bar %d/current bar %d]",
                  major.getTrend(), major.simplify(), minor.getTrend(), minor.simplify(), positions.lastBar(), Bars);
   }
}
