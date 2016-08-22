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
      int m_bbBarShort;
      int m_bbBarLong;
      AlphaVisionSignals *m_signals;

   public:
      AlphaVisionTrader(Positions *longPs, Positions *shortPs, AlphaVisionSignals *signals): Trader(longPs, shortPs) {
         m_signals = signals;
         m_bbBarLong = 0;
         m_bbBarShort = 0;         
      }
      
      void ~AlphaVisionTrader() { delete m_signals; }
      
      AlphaVisionSignals *getSignals() { return m_signals; }
      
      // trader executing signals
      void tradeOnTrends();
      void tradeNeutralTrend();
      void tradeNegativeTrend();
      void tradePositiveTrend();
      void goBBLong(BBTrend *bb, string reason, bool useBar=false, double target=0);
      void goBBShort(BBTrend *bb, string reason, bool useBar=false, double target=0);

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
   HMATrend *hmaCtMj = avCt.m_hmaMajor;
   HMATrend *hmaCtMn = avCt.m_hmaMinor;
   
   SignalChange signalCt;
   string simplifiedMj = hmaCtMj.simplify();
   string simplifiedMn = hmaCtMn.simplify();
   if (simplifiedMj != simplifiedMn) { // Neutral trend
      m_signals.setTrendCt(TREND_NEUTRAL);
      tradeNeutralTrend();
   } else if (simplifiedMj == "POSITIVE") { // Positive trend
      m_signals.setTrendCt(TREND_POSITIVE);
      signalCt = m_signals.getTrendCt();
      if (signalCt.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalCt.current));
         closeShorts();
      }
      tradePositiveTrend();
   } else if (simplifiedMj == "NEGATIVE") { // Negative trend
      m_signals.setTrendCt(TREND_NEGATIVE);
      signalCt = m_signals.getTrendCt();
      if (signalCt.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalCt.current));
         closeLongs();
      }
      tradeNegativeTrend();
   }
}

void AlphaVisionTrader::tradeNeutralTrend() {
   /* neutral territory, scalp setup
    * 1) major != minor
    *    open and close positions on crossing
    * 2) major == minor
    *    only close positions on major crossing?
    *
    */
   
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *hmaFtMj = avFt.m_hmaMajor;
   HMATrend *hmaFtMn = avFt.m_hmaMinor;
   BBTrend *bbFt = avFt.m_bb;

   if (hmaFtMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) { // crossing up
      goLong(hmaFtMj.getMAPeriod1(), bbFt.m_bbTop, 0, "Neutral-hma");
      goBBLong(bbFt, "TNeutral-bb");
   } else if (hmaFtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) { // crossing up
      goLong(hmaFtMn.getMAPeriod1(), bbFt.m_bbTop, 0, "Neutral-hma");
      goBBLong(bbFt, "TNeutral-bb");
   } else if (hmaFtMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) { // crossing down
      goShort(hmaFtMj.getMAPeriod1(), bbFt.m_bbBottom, 0, "Neutral-hma");
      goBBShort(bbFt, "TNeutral-bb");
   } else if (hmaFtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) { // crossing down
      goShort(hmaFtMn.getMAPeriod1(), bbFt.m_bbBottom, 0, "Neutral-hma");
      goBBShort(bbFt, "TNeutral-bb");
   }
}

void AlphaVisionTrader::tradePositiveTrend() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *hmaCtMn = avCt.m_hmaMinor;
   BBTrend *bbCt = avCt.m_bb;
  
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *hmaFtMj = avFt.m_hmaMajor;
   HMATrend *hmaFtMn = avFt.m_hmaMinor;
   BBTrend *bbFt = avFt.m_bb;

   if (hmaCtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      closeLongs("Positive Trend"); // close longs
      goBBShort(bbCt, "TPositive-Reversal", true);
      return;
   }
   
   if (hmaFtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goLong(hmaFtMn.getMAPeriod1(), bbCt.m_bbTop, 0, "TPositive-hma");
      goBBLong(bbFt, "TPositive-bb", false, bbCt.m_bbTop);
   } else if (hmaFtMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      goLong(hmaFtMj.getMAPeriod1(), bbCt.m_bbTop, 0, "TPositive-hma");
      goBBLong(bbFt, "TPositive-bb", false, bbCt.m_bbTop);
   }
}

void AlphaVisionTrader::tradeNegativeTrend() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *hmaCtMn = avCt.m_hmaMinor;
   BBTrend *bbCt = avCt.m_bb;
  
   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *hmaFtMj = avFt.m_hmaMajor;
   HMATrend *hmaFtMn = avFt.m_hmaMinor;
   BBTrend *bbFt = avFt.m_bb;

   if (hmaCtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) {
      closeShorts("Negative Trend"); // cover shorts
      goBBLong(bbCt, "TNegative-Reversal", true);
      return;
   }

   if (hmaFtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goShort(hmaFtMn.getMAPeriod1(), bbCt.m_bbBottom, 0, "TPositive-hma");
      goBBShort(bbFt, "TNegative-bb", false, bbCt.m_bbBottom);
   } else if (hmaFtMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) {
      goShort(hmaFtMj.getMAPeriod1(), bbCt.m_bbBottom, 0, "TPositive-hma");
      goBBShort(bbFt, "TNegative-bb", false, bbCt.m_bbBottom);
   }
}

double getTarget(double target, double nDefault) {
   if (target == 0) return nDefault;
   else return target;
}

//// Executing Orders
void AlphaVisionTrader::goBBLong(BBTrend *bb, string reason, bool useBar=false, double target=0) {
   if (useBar) {
      if (m_bbBarLong == Bars) return;
      else m_bbBarLong = Bars;
   }

   if (bb.getTrend() == TREND_POSITIVE || bb.getTrend() == TREND_POSITIVE_BREAKOUT)
      goLong(bb.m_bbMiddle, getTarget(target, bb.m_bbTop), 0, reason);
   goLong(bb.m_bbBottom, getTarget(target, bb.m_bbTop), 0, reason);
}

void AlphaVisionTrader::goBBShort(BBTrend *bb, string reason, bool useBar=false, double target=0) {
   if (useBar) {
      if (m_bbBarShort == Bars) return;
      else m_bbBarShort = Bars;
   }

   if (bb.getTrend() == TREND_NEGATIVE || bb.getTrend() == TREND_NEGATIVE_OVERSOLD)
      goShort(bb.m_bbMiddle, getTarget(target, bb.m_bbBottom), 0, reason);
   goShort(bb.m_bbTop, getTarget(target, bb.m_bbBottom), 0, reason);
}

