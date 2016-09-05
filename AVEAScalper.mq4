//+------------------------------------------------------------------+
//|                                                 Alpha Vision.mq4 |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property version   "1.001"
#property strict

#include <Signals\AlphaVision.mqh>
#include <Positions\AlphaVisionTraderScalper.mqh>


////
//// INPUTS
////

input bool iIsTest = false;
input int iPeriod1 = 20;
input int iPeriod2 = 50;
input int iPeriod3 = 200;
// TODO: input higher time interval than current
input int iFastTimeFrame = PERIOD_M5;
input int iMajorTimeFrame = PERIOD_H4;
input int iSuperTimeFrame = PERIOD_W1;

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
AlphaVisionTraderScalper *gTrader; // Orders maker
SignalTimeFrames gSignalTF;

int gCountMinutes;
int gCountTicks;


int OnInit() {
   gSignalTF.current = Period();
   gSignalTF.fast = iFastTimeFrame;
   gSignalTF.major = iMajorTimeFrame;
   gSignalTF.super = iSuperTimeFrame;
   
   if (gSignalTF.current >= iMajorTimeFrame) {
      Alert("Current timeframe is equal/higher than Major timeframe");
      return INIT_PARAMETERS_INCORRECT;
   } else if (gSignalTF.current <= iFastTimeFrame) {
      Alert("Current timeframe is equal/lower than Fast timeframe");
      return INIT_PARAMETERS_INCORRECT;   
   }

   // loading signals
   AlphaVisionSignals *avSignals = new AlphaVisionSignals(gSignalTF);
   avSignals.initOn(gSignalTF.fast, iPeriod1, iPeriod2, iPeriod3);
   avSignals.calculateOn(gSignalTF.fast);
   avSignals.initOn(gSignalTF.current, iPeriod1, iPeriod2, iPeriod3);
   avSignals.calculateOn(gSignalTF.current);
   avSignals.initOn(gSignalTF.major, iPeriod1, iPeriod2, iPeriod3);
   avSignals.calculateOn(gSignalTF.major);


   // loading current positions
   gTrader = new AlphaVisionTraderScalper(avSignals);
   gTrader.loadCurrentOrders(gSignalTF.fast);
   gTrader.loadCurrentOrders(gSignalTF.current);
   gTrader.loadCurrentOrders(gSignalTF.major);
   
   gCountMinutes = 0;
   gCountTicks = 0;
   EventSetTimer(60); // Every 1 minute, call onTimer
 
   return INIT_SUCCEEDED;
}

// OnTester - close positions
double OnTester() {
   gTrader.closeLongs(gSignalTF.fast, "End-Of-Test");
   gTrader.closeLongs(gSignalTF.current, "End-Of-Test");
   gTrader.closeLongs(gSignalTF.major, "End-Of-Test");

   gTrader.closeShorts(gSignalTF.fast, "End-Of-Test");
   gTrader.closeShorts(gSignalTF.current, "End-Of-Test");
   gTrader.closeShorts(gSignalTF.major, "End-Of-Test");

   return 0;
}

void OnDeinit(const int reason) {
   // timer
   EventKillTimer();
   
   // positions list
   delete gTrader;

   // TODO: add results calculi
   Print("Bye Bye!");
}

void OnTimer() {
   AlphaVisionSignals *signals = gTrader.getSignals();

   if (gCountMinutes >= 60) gCountMinutes = 0; // 1 hour has passed
   else gCountMinutes++;

   if (gCountMinutes % 3 == 0) { // every 3 minutes
      signals.calculateOn(gSignalTF.current);
      gTrader.onTrendSetup(gSignalTF.current);
   } else if (gCountMinutes % 15 == 0) { // every 15 minutes
      signals.calculateOn(gSignalTF.major);
      gTrader.onTrendSetup(gSignalTF.major);
   } else if (gCountMinutes % 28 == 0) {
      // calculate gAlphaVisionSuper - on weekly   
   }
}

void OnTick() {
   /*
    * Calculate current trend and support/resistence levels
    */
   
   if (Bars < 220) {
      Print("Too few bars.");
      return;
   }
   // remove already closed orders
   gTrader.cleanOrders(gSignalTF.fast);
   gTrader.cleanOrders(gSignalTF.current);
   gTrader.cleanOrders(gSignalTF.major);
   
   AlphaVisionSignals *signals = gTrader.getSignals();
   signals.calculateOn(gSignalTF.fast);
   gTrader.onTrendSetup(gSignalTF.fast);
   
   if (iIsTest) {
      //signals.calculateOn(gSignalTF.current);
      // strategy tester does not call onTimer
      gCountTicks++;
      if (gCountTicks % 35 == 0) {
         signals.calculateOn(gSignalTF.current);
         gTrader.onTrendSetup(gSignalTF.current);
      } else if (gCountTicks >= 300) {
         gCountTicks = 0;
         signals.calculateOn(gSignalTF.major);
         gTrader.onTrendSetup(gSignalTF.major);
      }
   }
}

