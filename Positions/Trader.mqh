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
      int m_bbBarShort;
      int m_bbBarLong;
      Positions *m_longPositions;
      Positions *m_shortPositions;
      AlphaVisionSignals *m_signals;

   public:
      Trader(Positions *longPs, Positions *shortPs, AlphaVisionSignals *signals): m_htTrend(TREND_EMPTY) {
         m_longPositions = longPs;
         m_shortPositions = shortPs;
         m_signals = signals;
         m_bbBarLong = 0;
         m_bbBarShort = 0;
      }
      
      void ~Trader() {
         delete m_longPositions;
         delete m_shortPositions;
         delete m_signals;
      }
      
      AlphaVisionSignals *getSignals() { return m_signals; }
      
      bool setHtTrend(int trend) {
         if (m_htTrend != trend) {
            m_htTrend = trend;
            Alert(StringFormat("[Trader] Major timeframe trend changed to: %d", m_htTrend));
            return true;
         } else return false;
      }
      
      void loadCurrentOrders(bool noMagicMA=false) {
         m_longPositions.loadCurrentOrders(noMagicMA);
         m_shortPositions.loadCurrentOrders(noMagicMA);
      }
      
      // trader executing signals
      void tradeOnTrends();
      void tradeNeutralTrend(bool);
      void tradeNegativeTrend(bool);
      void tradePositiveTrend(bool);
      
      // trader executing orders
      void goBBLong(string reason, bool useBar=false);
      void goBBShort(string reason, bool useBar=false);
      void goLong(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="");
      void goShort(double signalPrice, double priceTarget=0, double stopLoss=0, string reason="");
      void closeLongs(string);
      void closeShorts(string);
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
   bool changed = false;
   if (ctMajorSimplified != ctMinorSimplified) { // Neutral trend
      changed = setHtTrend(TREND_NEUTRAL);
      tradeNeutralTrend(changed);
   } else if (ctMajorSimplified == "POSITIVE") { // Positive trend
      changed = setHtTrend(TREND_POSITIVE);
      if (changed) closeShorts();
      tradePositiveTrend(changed);
      //tradeNeutralTrend();
   } else if (ctMajorSimplified == "NEGATIVE") { // Negative trend
      changed = setHtTrend(TREND_NEGATIVE);
      if (changed) closeLongs();
      tradeNegativeTrend(changed);
      //tradeNeutralTrend();
   }
}

void Trader::tradeNeutralTrend(bool changed) {
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

   int superMinorTrend = ctMinor.getTrend();
   if (changed) PrintFormat("[tradeNeutralTrend] above trend changed: %d", superMinorTrend);
   //if (superMinorTrend == TREND_NEGATIVE_FROM_POSITIVE) {
   //   closeLongs("Neutral Trend"); return; // close longs
   //} else if (superMinorTrend == TREND_POSITIVE_FROM_NEGATIVE) {
   //   closeShorts("Neutral Trend"); return; // close shorts
   //}

   if (major.simplify() != minor.simplify()) { // undecision
      // go with minor trend scalps
      switch (minor.getTrend()) {
         case TREND_POSITIVE_FROM_NEGATIVE: // go long
            //coverShorts();
            goBBLong("TNeutral-neutral");
            break;
         case TREND_NEGATIVE_FROM_POSITIVE: // go short
            //sellLongs();
            goBBShort("TNeutral-neutral");
            break;
         default:
            break;
      }
   } else if (minor.simplify() == "POSITIVE") { // trending positive - trade when crossing
      if (minor.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
         //closeShorts();
         goBBLong("TNeutral-positive");
      } else if (major.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
         //closeShorts();
         goBBLong("TNeutral-positive");
      }
   } else { // trending negative / trade when crossing
      if (minor.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
         //closeLongs();
         goBBShort("TNeutral-negative");
      } else if (major.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
         //closeLongs();
         goBBShort("TNeutral-negative");
      }
   }
}

void Trader::tradePositiveTrend(bool changed) {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *ctMinor = avCt.m_hmaMinor;
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *major = avFt.m_hmaMajor;
   HMATrend *minor = avFt.m_hmaMinor;

   int superMinorTrend = ctMinor.getTrend();
   if (changed) PrintFormat("[tradePositiveTrend] above trend changed: %d", superMinorTrend);
   if (superMinorTrend == TREND_NEGATIVE_FROM_POSITIVE) {
      closeLongs("Positive Trend"); // close longs
      goBBShort("TPositive-Reversal", true);
      return;
   }
   
   if (minor.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goBBLong("TPositive-FT-minor");
   } else if (major.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goBBLong("TPositive-FT-major");
   }
}

void Trader::tradeNegativeTrend(bool changed) {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *ctMinor = avCt.m_hmaMinor;
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *major = avFt.m_hmaMajor;
   HMATrend *minor = avFt.m_hmaMinor;

   int superMinorTrend = ctMinor.getTrend();
   if (changed) PrintFormat("[tradeNegativeTrend] above trend changed: %d", superMinorTrend);
   if (superMinorTrend == TREND_POSITIVE_FROM_NEGATIVE) {
      closeShorts("Negative Trend"); // cover shorts
      goBBLong("TNegative-Reversal", true);
      return;
   }

   if (minor.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goBBShort("TNegative-FT-minor");
   } else if (major.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goBBShort("TNegative-FT-major");
   }
}

//// Executing Orders
/*
 * Orders shall be executed on timeframe and given a reason.
 * 
 */

void Trader::goBBLong(string reason, bool useBar=false) {
   if (useBar) {
      if (m_bbBarLong == Bars) return;
      else m_bbBarLong = Bars;
   }
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   BBTrend *bb = avCt.m_bb;

   if (bb.getTrend() == TREND_POSITIVE || bb.getTrend() == TREND_POSITIVE_BREAKOUT)
      goLong(bb.m_bbMiddle, bb.m_bbTop, 0, reason);
   goLong(bb.m_bbBottom, bb.m_bbTop, 0, reason);
}

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

void Trader::goBBShort(string reason, bool useBar=false) {
   if (useBar) {
      if (m_bbBarShort == Bars) return;
      else m_bbBarShort = Bars;
   }
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   BBTrend *bb = avCt.m_bb;

   if (bb.getTrend() == TREND_NEGATIVE || bb.getTrend() == TREND_NEGATIVE_OVERSOLD)
      goShort(bb.m_bbMiddle, bb.m_bbBottom, 0, reason);
   goShort(bb.m_bbTop, bb.m_bbBottom, 0, reason);
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

void Trader::closeLongs(string msg="") {
   double price = Bid;
   int oCount = m_longPositions.count();
   PositionValue fullPosition = m_longPositions.meanPositionValue();
   
   if (msg != "") PrintFormat("[AV.closeLongs] Closing %d longs from: %s", oCount, msg);
   
   // Close pending orders not tracked
   for (int j = 0; j < OrdersTotal(); j++) {
      if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
         if ((OrderSymbol() == Symbol()) && (OrderType() == OP_BUYLIMIT) &&
             (OrderMagicNumber() == MAGICMA)) {
            if (OrderDelete(OrderTicket()))
               PrintFormat("[AV.closeLongs] Pending long at %.4f closed.", OrderOpenPrice());
            else
               PrintFormat("[AV.closeLongs] Error closing pending long at %.4f closed. (error %d)", OrderOpenPrice(), GetLastError());
         }
      }
   }

   // Close tracked orders
   for (int i = 0; i < oCount; i++) {
      Position *p = m_longPositions[i];
      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[AV.closeLongs.%d/%d] Closing order %d (buy price %.4f -> sell price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      } else {
         int check = GetLastError();
         PrintFormat("[AV.closeLongs.%d/%d] ERROR closing order: %d", i, oCount, check);
      }
   }
   if (oCount > 0) {
      PrintFormat("[AV.closeLongs] Closed %d orders (size %.2f) / (long MP %.4f -> sell at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, price);
      m_longPositions.clear();
   }
}

void Trader::closeShorts(string msg="") {
   double price = Ask;
   int oCount = m_shortPositions.count();
   PositionValue fullPosition = m_shortPositions.meanPositionValue();
   
   if (msg != "") PrintFormat("[AV.closeShorts] Closing %d shorts from: %s", oCount, msg);

   // Close pending orders not tracked
   for (int j = 0; j < OrdersTotal(); j++) {
      if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
         if ((OrderSymbol() == Symbol()) && (OrderType() == OP_SELLLIMIT) &&
             (OrderMagicNumber() == MAGICMA)) {
            if (OrderDelete(OrderTicket()))
               PrintFormat("[AV.closeShorts] Pending short at %.4f closed. (error %d)", OrderOpenPrice(), GetLastError());
         }
      }
   }

   // Close tracked orders
   for (int i = 0; i < oCount; i++) {
      Position *p = m_shortPositions[i];
      if (OrderClose(p.m_ticket, p.m_size, price, 3) == true) {
         PrintFormat("[AV.closeShorts.%d/%d] Closing order %d (sell price %.4f -> buy price %.4f)", 
                     i, oCount, p.m_ticket, p.m_price, price);
      } else {
         int check = GetLastError();
         PrintFormat("[AV.closeShorts.%d/%d] ERROR closing order: %d", i, oCount, check);
      }
   }
   if (oCount > 0) {
      PrintFormat("[AV.closeShorts] Closed %d orders (size %.2f) / (sell MP %.4f -> cover at %.4f)",
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
