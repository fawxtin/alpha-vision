//+------------------------------------------------------------------+
//|                                                       Trader.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <stdlib.mqh>

#include <Positions\Positions.mqh>
#include <Signals\AlphaVision.mqh>


#ifndef __POSITIONS_TRADER__
#define __POSITIONS_TRADER__ true

#define EXPIRE_NEVER D'2017.01.01 23:59:59'   // 60 * 60 * 24 * 7

double normalizePrice(double val, int s=4) {
   if (s == 2)
      return StringToDouble(StringFormat("%.2f", val));
   else
      return StringToDouble(StringFormat("%.4f", val));
}

class Trader {
   protected:
      int m_htTrend;
      Positions *m_longPositions;
      Positions *m_shortPositions;
      AlphaVisionSignals *m_signals;

   public:
      Trader(Positions *longPs, Positions *shortPs, AlphaVisionSignals *signals): m_htTrend(TREND_EMPTY) {
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
      
      void setHtTrend(int trend) {
         if (m_htTrend != trend) {
            m_htTrend = trend;
            Alert(StringFormat("[Trader] Major timeframe trend changed to: %d", m_htTrend));
         }
      }
      
      void loadCurrentOrders(bool noMagicMA=false) {
         m_longPositions.loadCurrentOrders(noMagicMA);
         m_shortPositions.loadCurrentOrders(noMagicMA);
      }
      
      // trader executing signals
      void tradeOnTrends();
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
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *ctMajor = avCt.m_hmaMajor;
   HMATrend *ctMinor = avCt.m_hmaMinor;

   string ctMajorSimplified = ctMajor.simplify();
   string ctMinorSimplified = ctMinor.simplify();
   
   if (ctMajorSimplified != ctMinorSimplified) { // Neutral trend
      setHtTrend(TREND_NEUTRAL);
      tradeNeutralTrend();
   } else if (ctMajorSimplified == "POSITIVE") { // Positive trend
      setHtTrend(TREND_POSITIVE);
      tradePositiveTrend();
      //tradeNeutralTrend();
   } else if (ctMajorSimplified == "NEGATIVE") { // Negative trend
      setHtTrend(TREND_NEGATIVE);
      tradeNegativeTrend();
      //tradeNeutralTrend();
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
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *ctMinor = avCt.m_hmaMinor;
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *major = avFt.m_hmaMajor;
   HMATrend *minor = avFt.m_hmaMinor;
   BBTrend *bb = avCt.m_bb;

   int superMinorTrend = ctMinor.getTrend();
   if (superMinorTrend == TREND_NEGATIVE_FROM_POSITIVE) {
      sellLongs(); return; // close longs
   } else if (superMinorTrend == TREND_POSITIVE_FROM_NEGATIVE) {
      coverShorts(); return;
   }

   if (major.simplify() != minor.simplify()) { // undecision
      // go with minor trend scalps
      switch (minor.getTrend()) {
         case TREND_POSITIVE_FROM_NEGATIVE: // go long
            //coverShorts();
            if (bb.getTrend() == TREND_POSITIVE || bb.getTrend() == TREND_POSITIVE_BREAKOUT)
               goLong(bb.m_bbMiddle, bb.m_bbTop);
            goLong(bb.m_bbBottom, bb.m_bbTop);
            break;
         case TREND_NEGATIVE_FROM_POSITIVE: // go short
            //sellLongs();
            if (bb.getTrend() == TREND_NEGATIVE || bb.getTrend() == TREND_NEGATIVE_OVERSOLD)
               goShort(bb.m_bbMiddle, bb.m_bbBottom);
            goShort(bb.m_bbTop, bb.m_bbBottom);
            break;
         default:
            break;
      }
   } else if (minor.simplify() == "POSITIVE") { // trending positive - trade when crossing
      if (minor.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
         coverShorts();
         if (bb.getTrend() == TREND_POSITIVE || bb.getTrend() == TREND_POSITIVE_BREAKOUT)
            goLong(bb.m_bbMiddle, bb.m_bbTop);
         goLong(bb.m_bbBottom, bb.m_bbTop);
      } else if (major.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
         coverShorts();
         if (bb.getTrend() == TREND_POSITIVE || bb.getTrend() == TREND_POSITIVE_BREAKOUT)
            goLong(bb.m_bbMiddle, bb.m_bbTop);
         goLong(bb.m_bbBottom, bb.m_bbTop);
      }
   } else { // trending negative / trade when crossing
      if (minor.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
         sellLongs();
         if (bb.getTrend() == TREND_NEGATIVE || bb.getTrend() == TREND_NEGATIVE_OVERSOLD)
            goShort(bb.m_bbMiddle, bb.m_bbBottom);
         goShort(bb.m_bbTop, bb.m_bbBottom);
      } else if (major.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
         sellLongs();
         if (bb.getTrend() == TREND_NEGATIVE || bb.getTrend() == TREND_NEGATIVE_OVERSOLD)
            goShort(bb.m_bbMiddle, bb.m_bbBottom);
         goShort(bb.m_bbTop, bb.m_bbBottom);
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
   BBTrend *bb = avCt.m_bb;

   int superMinorTrend = ctMinor.getTrend();
   if (superMinorTrend == TREND_NEGATIVE_FROM_POSITIVE) {
      sellLongs(); // close longs
      return;
   }
   
   if (minor.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      if (bb.getTrend() == TREND_POSITIVE || bb.getTrend() == TREND_POSITIVE_BREAKOUT)
         goLong(bb.m_bbMiddle);
      goLong(bb.m_bbBottom);
   } else if (major.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      if (bb.getTrend() == TREND_POSITIVE || bb.getTrend() == TREND_POSITIVE_BREAKOUT)
         goLong(bb.m_bbMiddle);
      goLong(bb.m_bbBottom);
   }
}

void Trader::tradeNegativeTrend() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *ctMinor = avCt.m_hmaMinor;
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *major = avFt.m_hmaMajor;
   HMATrend *minor = avFt.m_hmaMinor;
   BBTrend *bb = avCt.m_bb;

   int superMinorTrend = ctMinor.getTrend();
   if (superMinorTrend == TREND_POSITIVE_FROM_NEGATIVE) {
      coverShorts(); // cover shorts
      return;
   }

   if (minor.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      if (bb.getTrend() == TREND_NEGATIVE || bb.getTrend() == TREND_NEGATIVE_OVERSOLD)
         goShort(bb.m_bbMiddle);
      goShort(bb.m_bbTop);
   } else if (major.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      if (bb.getTrend() == TREND_NEGATIVE || bb.getTrend() == TREND_NEGATIVE_OVERSOLD)
         goShort(bb.m_bbMiddle);
      goShort(bb.m_bbTop);
   }
}

//// Executing Orders
/*
 * Orders shall be executed on timeframe and given a reason.
 * 
 */

void Trader::goLong(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="") {
   if (m_longPositions.lastBar() == Bars || m_longPositions.count() >= MAX_POSITIONS) return; // already traded / full
   //OrderSend
   int vdigits = (int)MarketInfo(Symbol(), MODE_DIGITS);
   double vspread = MarketInfo(Symbol(), MODE_SPREAD) / MathPow(10, vdigits);
   int ticket;
   double price = Ask;
   if (MathAbs(price - signalPrice) < vspread) { // buy market
      PrintFormat("[Av.goLong] opening At market (%.4f, %.4f => %.4f (%.4f))", price, signalPrice, vspread, MathAbs(signalPrice - price));
      ticket = OrderSend(Symbol(), OP_BUY, LOT_SIZE, price, 3, stopLoss, priceTarget, reason, MAGICMA, 0, clrAliceBlue);
   } else if (signalPrice < price) { // buy limit
      PrintFormat("[Av.goLong] opening Limit at %f (%.4f)", NormalizeDouble(signalPrice, vdigits), price);
      ticket = OrderSend(Symbol(), OP_BUYLIMIT, LOT_SIZE, NormalizeDouble(signalPrice, vdigits), 3,
                         stopLoss, priceTarget, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
   } else {// buy stop
      PrintFormat("[Av.goLong] opening Stop at %f (%.4f)", NormalizeDouble(signalPrice, vdigits), price);
      ticket = OrderSend(Symbol(), OP_BUYSTOP, LOT_SIZE, NormalizeDouble(signalPrice, vdigits), 3,
                         stopLoss, priceTarget, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
   }
   
   if (ticket == -1) {
      int check = GetLastError();
      PrintFormat("[Av.goLong] ERROR opening order: %d / %s", check, ErrorDescription(check));
   } else if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      m_longPositions.add(new Position(ticket, OrderOpenTime(), OrderLots(),
                                       OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
      m_longPositions.setLastBar(Bars);
   } 
}

void Trader::goShort(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="") {
   if (m_shortPositions.lastBar() == Bars || m_shortPositions.count() >= MAX_POSITIONS) return; // already traded?
   // short trades
   int vdigits = (int)MarketInfo(Symbol(), MODE_DIGITS);
   double vspread = MarketInfo(Symbol(), MODE_SPREAD) / MathPow(10, vdigits);
   int ticket;
   double price = Bid;
   if (MathAbs(signalPrice - price) < vspread) { // sell market
      PrintFormat("[Av.goShort] opening At market (%.4f, %.4f => %.4f (%.4f))", price, signalPrice, vspread, MathAbs(signalPrice - price));
      ticket = OrderSend(Symbol(), OP_SELL, LOT_SIZE, price, 3, 0, 0, reason, MAGICMA, 0, clrPink);
   } else if (signalPrice > price) { // sell limit
      PrintFormat("[Av.goShort] opening Limit at %f (%.4f)", NormalizeDouble(signalPrice, vdigits), price);
      ticket = OrderSend(Symbol(), OP_SELLLIMIT, LOT_SIZE, NormalizeDouble(signalPrice, vdigits), 3,
                         stopLoss, priceTarget, reason, MAGICMA, EXPIRE_NEVER, clrPink);
   } else { // sell stop
      PrintFormat("[Av.goShort] opening Stop at %f (%.4f)", NormalizeDouble(signalPrice, vdigits), price);
      ticket = OrderSend(Symbol(), OP_SELLSTOP, LOT_SIZE, NormalizeDouble(signalPrice, vdigits), 3,
                         stopLoss, priceTarget, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
   }
   
   if (ticket == -1) {
      int check = GetLastError();
      PrintFormat("[Av.goShort] ERROR opening order: %d / %s", check, ErrorDescription(check));
   } else if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
      m_shortPositions.add(new Position(ticket, OrderOpenTime(), OrderLots(),
                                        OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss()));
      m_shortPositions.setLastBar(Bars);
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
      } else {
         int check = GetLastError();
         PrintFormat("[Av.sellLongs.%d/%d] ERROR closing order: %d", i, oCount, check);
      }
   }
   if (oCount > 0) {
      PrintFormat("[AV.sellLongs] Closed %d orders (size %.2f) / (long MP %.4f -> sell at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      m_longPositions.clear();
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
      } else {
         int check = GetLastError();
         PrintFormat("[Av.coverShorts.%d/%d] ERROR closing order: %d", i, oCount, check);
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
