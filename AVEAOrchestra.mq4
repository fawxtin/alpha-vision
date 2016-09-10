//+------------------------------------------------------------------+
//|                                                 Alpha Vision.mq4 |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property version   "1.002"
#property strict

#include <Signals\AlphaVision.mqh>
#include <Traders\OrchestraTrader.mqh>

////
//// INPUTS
////

input bool iIsTest = false;

input int iFastTimeFrame = PERIOD_M5;
input int iMajorTimeFrame = PERIOD_H4;
input int iSuperTimeFrame = PERIOD_W1;

////
//// GLOBALS
////
AlphaVisionTraderOrchestra *gTrader; // Orders maker
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
   avSignals.initOn(gSignalTF.fast);
   avSignals.calculateOn(gSignalTF.fast);
   avSignals.initOn(gSignalTF.current);
   avSignals.calculateOn(gSignalTF.current);
   avSignals.initOn(gSignalTF.major);
   avSignals.calculateOn(gSignalTF.major);
   avSignals.initOn(gSignalTF.super);
   avSignals.calculateOn(gSignalTF.super);
   avSignals.initOn(PERIOD_MN1);
   avSignals.calculateOn(PERIOD_MN1);


   // loading current positions
   gTrader = new AlphaVisionTraderOrchestra(avSignals);
   gTrader.loadCurrentOrders(gSignalTF.fast);
   gTrader.loadCurrentOrders(gSignalTF.current);
   gTrader.loadCurrentOrders(gSignalTF.major);
   gTrader.loadCurrentOrders(gSignalTF.super);
   
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
   gTrader.closeLongs(gSignalTF.super, "End-Of-Test");

   gTrader.closeShorts(gSignalTF.fast, "End-Of-Test");
   gTrader.closeShorts(gSignalTF.current, "End-Of-Test");
   gTrader.closeShorts(gSignalTF.major, "End-Of-Test");
   gTrader.closeShorts(gSignalTF.super, "End-Of-Test");

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
   } else if (gCountMinutes % 58 == 0) {
      signals.calculateOn(gSignalTF.super);
      gTrader.onTrendSetup(gSignalTF.super);
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
   gTrader.cleanOrders(gSignalTF.super);
   
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
      } else if (gCountTicks % 300 == 0) {
         signals.calculateOn(gSignalTF.major);
         gTrader.onTrendSetup(gSignalTF.major);
      } else if (gCountTicks >= 900) {
         gCountTicks = 0;
         signals.calculateOn(gSignalTF.super);
         gTrader.onTrendSetup(gSignalTF.super);
      }
   }
}

