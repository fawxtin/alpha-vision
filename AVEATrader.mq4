//+------------------------------------------------------------------+
//|                                                 Alpha Vision.mq4 |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property version   "1.003"
#property strict

#include <Signals\AlphaVision.mqh>
#include <Traders\OrchestraTrader.mqh>
#include <Traders\ScalperTrader.mqh>
#include <Traders\SwingTrader.mqh>
#include <Traders\TrendTrader.mqh>
#include <Traders\PivotTrader.mqh>


enum TRADER_TYPES {
   TRADER_ORCHESTRA,
   TRADER_SCALPER,
   TRADER_SWING,
   TRADER_TREND,
   TRADER_PIVOT
};

////
//// INPUTS
////

input bool iIsTest = false;

input TRADER_TYPES iTrader = TRADER_ORCHESTRA;

input double iLotSize = 0.01;
input double iRiskAndRewardRatio = 2.0;

input int iFastTimeFrame = PERIOD_M15;
input int iMajorTimeFrame = PERIOD_H4;
input int iSuperTimeFrame = PERIOD_W1;

input bool iTradeFastP = true;
input bool iTradeCurrentP = true;
input bool iTradeMajorP = true;
input bool iTradeSuperP = true;

////
//// GLOBALS
////
AlphaVisionTrader *gTrader; // Orders maker
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
   switch (iTrader) {
      case TRADER_ORCHESTRA:
         gTrader = new AlphaVisionTraderOrchestra(avSignals, iRiskAndRewardRatio);
         break;
      case TRADER_SCALPER:
         gTrader = new AlphaVisionTraderScalper(avSignals, iRiskAndRewardRatio);
         break;
      case TRADER_SWING:
         gTrader = new AlphaVisionTraderSwing(avSignals, iRiskAndRewardRatio);
         break;
      case TRADER_TREND:
         gTrader = new AlphaVisionTrendTrader(avSignals, iRiskAndRewardRatio);
         break;
      case TRADER_PIVOT:
         gTrader = new AlphaVisionTraderPivot(avSignals, iRiskAndRewardRatio);
         break;
   }
   
   gTrader.setLotSize(iLotSize);
   if (iTradeFastP) gTrader.loadCurrentOrders(gSignalTF.fast);
   if (iTradeCurrentP) gTrader.loadCurrentOrders(gSignalTF.current);
   if (iTradeMajorP) gTrader.loadCurrentOrders(gSignalTF.major);
   if (iTradeSuperP) gTrader.loadCurrentOrders(gSignalTF.super);
   
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
      if (iTradeCurrentP) gTrader.onTrendSetup(gSignalTF.current);
   } else if (gCountMinutes % 15 == 0) { // every 15 minutes
      signals.calculateOn(gSignalTF.major);
      if (iTradeMajorP) gTrader.onTrendSetup(gSignalTF.major);
   } else if (gCountMinutes % 58 == 0) {
      signals.calculateOn(gSignalTF.super);
      if (iTradeSuperP) gTrader.onTrendSetup(gSignalTF.super);
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
   if (iTradeFastP) gTrader.cleanOrders(gSignalTF.fast);
   if (iTradeCurrentP) gTrader.cleanOrders(gSignalTF.current);
   if (iTradeMajorP) gTrader.cleanOrders(gSignalTF.major);
   if (iTradeSuperP) gTrader.cleanOrders(gSignalTF.super);
   
   AlphaVisionSignals *signals = gTrader.getSignals();
   signals.calculateOn(gSignalTF.fast);
   if (iTradeFastP) gTrader.onTrendSetup(gSignalTF.fast);
   
   if (iIsTest) {
      //signals.calculateOn(gSignalTF.current);
      // strategy tester does not call onTimer
      gCountTicks++;
      if (gCountTicks % 35 == 0) {
         signals.calculateOn(gSignalTF.current);
         if (iTradeCurrentP) gTrader.onTrendSetup(gSignalTF.current);
      } else if (gCountTicks % 300 == 0) {
         signals.calculateOn(gSignalTF.major);
         if (iTradeMajorP) gTrader.onTrendSetup(gSignalTF.major);
      } else if (gCountTicks >= 900) {
         gCountTicks = 0;
         signals.calculateOn(gSignalTF.super);
         if (iTradeSuperP) gTrader.onTrendSetup(gSignalTF.super);
      }
   }
}

