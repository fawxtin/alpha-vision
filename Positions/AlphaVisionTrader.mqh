//+------------------------------------------------------------------+
//|                                            AlphaVisionTrader.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Positions\Trader.mqh>
#include <Signals\AlphaVision.mqh>


class AlphaVisionTrader : public Trader {
   protected:
      int m_htTrend;
      int m_bbBarShort;
      int m_bbBarLong;
      AlphaVisionSignals *m_signals;

   public:
      AlphaVisionTrader(Positions *longPs, Positions *shortPs, AlphaVisionSignals *signals): Trader(longPs, shortPs) {
         m_signals = signals;
         m_htTrend = TREND_EMPTY;
         m_bbBarLong = 0;
         m_bbBarShort = 0;         
      }
      
      void ~AlphaVisionTrader() { delete m_signals; }
      
      AlphaVisionSignals *getSignals() { return m_signals; }
      
      bool setHtTrend(int trend) {
         if (m_htTrend != trend) {
            m_htTrend = trend;
            Alert(StringFormat("[Trader] Major timeframe trend changed to: %d", m_htTrend));
            return true;
         } else return false;
      }
      
      // trader executing signals
      void tradeOnTrends();
      void tradeNeutralTrend(bool);
      void tradeNegativeTrend(bool);
      void tradePositiveTrend(bool);
      void goBBLong(string reason, bool useBar=false);
      void goBBShort(string reason, bool useBar=false);

};

void AlphaVisionTrader::tradeOnTrends() {
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

void AlphaVisionTrader::tradeNeutralTrend(bool changed) {
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

void AlphaVisionTrader::tradePositiveTrend(bool changed) {
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

void AlphaVisionTrader::tradeNegativeTrend(bool changed) {
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
void AlphaVisionTrader::goBBLong(string reason, bool useBar=false) {
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

void AlphaVisionTrader::goBBShort(string reason, bool useBar=false) {
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

