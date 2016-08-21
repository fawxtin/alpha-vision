//+------------------------------------------------------------------+
//|                                                       Trader.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Positions\Positions.mqh>
#include <Signals\AlphaVision.mqh>


#ifndef __POSITIONS_TRADER__
#define __POSITIONS_TRADER__ true

class Trader {
   protected:
      Positions *m_longPositions;
      Positions *m_shortPositions;
      AlphaVisionSignals *m_signals;

   public:
      Trader(Positions *longPs, Positions *shortPs, AlphaVisionSignals *signals) {
         m_longPositions = longPs;
         m_shortPositions = shortPs;
         m_signals = signals;
      }
      
      void ~Trader() {
         delete m_longPositions;
         delete m_shortPositions;
         delete m_signals;
      }
      
      AlphaVisionSignals *getSignals() { return m_signals; }
      
      void loadCurrentOrders(bool noMagicMA=false) {
         m_longPositions.loadCurrentOrders(noMagicMA);
         m_shortPositions.loadCurrentOrders(noMagicMA);
      }
      
      // trader executing signals
      void tradeOnTrends();
      void tradeSimple();
      void tradeNeutralTrend();
      void tradeNegativeTrend();
      void tradePositiveTrend();
      
      // trader executing orders
      void goLong(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="");
      void goShort(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="");
      void sellLongs();
      void coverShorts();
};

void Trader::tradeOnTrends() {
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
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avMt = m_signals.getAlphaVisionOn(stf.major);
   HMATrend *mtMajor = avMt.m_hmaMajor;
   HMATrend *mtMinor = avMt.m_hmaMinor;

   string mtMajorSimplified = mtMajor.simplify();
   string mtMinorSimplified = mtMinor.simplify();
   
   if (mtMajorSimplified != mtMinorSimplified) { // Neutral trend
      tradeNeutralTrend();
   } else if (mtMajorSimplified == "POSITIVE") { // Positive trend
      tradePositiveTrend();
      //tradeNeutralTrend();
   } else if (mtMajorSimplified == "NEGATIVE") { // Negative trend
      tradeNegativeTrend();
      //tradeNeutralTrend();
   }
}

void Trader::tradeSimple() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *major = avFt.m_hmaMajor;
   HMATrend *minor = avFt.m_hmaMinor;

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

void Trader::tradeNeutralTrend() {
   /* neutral territory, scalp setup
    * 1) major != minor
    *    open and close positions on crossing
    * 2) major == minor
    *    only close positions on major crossing?
    *
    */
   
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *major = avFt.m_hmaMajor;
   HMATrend *minor = avFt.m_hmaMinor;

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

void Trader::tradePositiveTrend() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *ctMinor = avCt.m_hmaMinor;
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *major = avFt.m_hmaMajor;
   HMATrend *minor = avFt.m_hmaMinor;

   int superMinorTrend = ctMinor.getTrend();
   if (superMinorTrend == TREND_NEGATIVE_FROM_POSITIVE) {
      sellLongs(); // close longs
      return;
   }
   
   if (minor.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goLong(minor.getMAPeriod1());
   } else if (major.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goLong(major.getMAPeriod1());
   }
}

void Trader::tradeNegativeTrend() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *ctMinor = avCt.m_hmaMinor;
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *major = avFt.m_hmaMajor;
   HMATrend *minor = avFt.m_hmaMinor;

   int superMinorTrend = ctMinor.getTrend();
   if (superMinorTrend == TREND_POSITIVE_FROM_NEGATIVE) {
      coverShorts(); // cover shorts
      return;
   }

   if (minor.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goShort(minor.getMAPeriod1());
   } else if (major.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goShort(major.getMAPeriod1());
   }
}

//// Executing Orders

void Trader::goLong(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="") {
   if (m_longPositions.lastBar() == Bars || m_longPositions.count() >= MAX_POSITIONS) return; // already traded / full
   //OrderSend
   double price = Ask;
   int ticket = OrderSend(Symbol(), OP_BUY, LOT_SIZE, price, 3, stopLoss, priceTarget, reason, MAGICMA, clrAliceBlue);
   if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      m_longPositions.add(new Position(ticket, OrderOpenTime(), OrderLots(),
                                       OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
      m_longPositions.setLastBar(Bars);
   }
}

void Trader::sellLongs() {
   double price = Bid;
   int oCount = m_longPositions.count();
   PositionValue fullPosition = m_longPositions.meanPositionValue();
   for (int i = 0; i < oCount; i++) {
      Position *p = m_longPositions[i];
      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[AV.sellLongs.%d/%d] Closing order %d (buy price %.4f -> sell price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      }
   }
   if (oCount > 0) {
      PrintFormat("[AV.sellLongs] Closed %d orders (size %.2f) / (long MP %.4f -> sell at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      m_longPositions.clear();
   }
}

void Trader::goShort(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="") {
   if (m_shortPositions.lastBar() == Bars || m_shortPositions.count() >= MAX_POSITIONS) return; // already traded?
   // short trades
   double price = Bid;
   int ticket = OrderSend(Symbol(), OP_SELL, LOT_SIZE, price, 3, stopLoss, priceTarget, reason, MAGICMA, clrPink);
   if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      m_shortPositions.add(new Position(ticket, OrderOpenTime(), OrderLots(),
                                        OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
      m_shortPositions.setLastBar(Bars);
   }
}

void Trader::coverShorts() {
   double price = Ask;
   int oCount = m_shortPositions.count();
   PositionValue fullPosition = m_shortPositions.meanPositionValue();
   for (int i = 0; i < oCount; i++) {
      Position *p = m_shortPositions[i];
      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[AV.coverShorts.%d/%d] Closing order %d (sell price %.4f -> buy price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      }
   }
   if (oCount > 0) {
      PrintFormat("[AV.coverShorts] Closed %d orders (size %.2f) / (sell MP %.4f -> cover at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      m_shortPositions.clear();
   }
}

//void debugPrintSignal() {
//   if (iDebug) {
//      PrintFormat("[AV.CT.HMA] Major Signal (%d -> %s) / Minor signal (%d -> %s) / [last bar %d/current bar %d]",
//                  major.getTrend(), major.simplify(), minor.getTrend(), minor.simplify(), positions.lastBar(), Bars);
//   }
//}



#endif
