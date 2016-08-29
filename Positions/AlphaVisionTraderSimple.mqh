//+------------------------------------------------------------------+
//|                                      AlphaVisionTraderSimple.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Positions\AlphaVisionTrader.mqh>

class AlphaVisionTraderSimple : public AlphaVisionTrader {

   public:
      AlphaVisionTraderSimple(Positions *longPs, Positions *shortPs, AlphaVisionSignals *signals): AlphaVisionTrader(longPs, shortPs, signals) {}

      virtual void tradeOnTrends();
      void tradeSimple();
};

void AlphaVisionTraderSimple::tradeOnTrends() {
   /*
    * On Cross signal up, put buy limit orders on BB.
    * On Cross signal down, put sell limit orders on BB.
    *
    * 
    *
    */
   SignalTimeFrames stf = m_signals.getTimeFrames();
   
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *hmaCtMj = avCt.m_hmaMajor;
   HMATrend *hmaCtMn = avCt.m_hmaMinor;
   BBTrend *bbCt = avCt.m_bb;

   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   BBTrend *bbFt = avFt.m_bb;
   BBTrend *bbFt3 = avFt.m_bb3;

   SignalChange *signalCt;
   string simplifiedMj = hmaCtMj.simplify();
   string simplifiedMn = hmaCtMn.simplify();
   if (simplifiedMj != simplifiedMn) { // Neutral trend
      m_signals.setSignal(stf.current, SSIGNAL_NEUTRAL);
      signalCt = m_signals.getSignal(stf.current);
      if (signalCt.changed) {
         if (signalCt.last == SSIGNAL_NEGATIVE)
            goBBLong(bbFt, "Neutral-reversal", true, bbCt.m_bbTop, bbFt3.m_bbBottom);
         else if (signalCt.last == SSIGNAL_POSITIVE)
            goBBShort(bbFt, "Neutral-reversal", true, bbCt.m_bbBottom, bbFt3.m_bbTop);
      }
      tradeSimple();
   } else if (simplifiedMj == "POSITIVE") { // Positive trend
      m_signals.setSignal(stf.current, SSIGNAL_POSITIVE);
      signalCt = m_signals.getSignal(stf.current);
      if (signalCt.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalCt.current));
         closeShorts("Positive-Trend");
         goBBLong(bbFt, "Positive-Reversal", true, bbCt.m_bbTop, bbFt3.m_bbBottom);
      }
      tradeSimple();
   } else if (simplifiedMj == "NEGATIVE") { // Negative trend
      m_signals.setSignal(stf.current, SSIGNAL_NEGATIVE);
      signalCt = m_signals.getSignal(stf.current);
      if (signalCt.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalCt.current));
         closeLongs("Negative-Trend");
         goBBShort(bbFt, "Negative-Reversal", true, bbCt.m_bbBottom, bbFt3.m_bbTop);
      }
      tradeSimple();
   }
}

void AlphaVisionTraderSimple::tradeSimple() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   BBTrend *bbCt = avCt.m_bb;
   BBTrend *bbCt3 = avCt.m_bb3;

   AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   HMATrend *hmaFtMj = avFt.m_hmaMajor;
   HMATrend *hmaFtMn = avFt.m_hmaMinor;

   // using fast trend signals and current trend BB positioning
   if (hmaFtMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) { // crossing up
      goBBLong(bbCt, "TSimple-bb-hmaFtMj", false, 0, bbCt3.m_bbBottom - m_mkt.vspread);
   } else if (hmaFtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE) { // crossing up
      goBBLong(bbCt, "TSimple-bb-hmaFtMn", false, 0, bbCt3.m_bbBottom - m_mkt.vspread);
   } else if (hmaFtMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) { // crossing down
      goBBShort(bbCt, "TSimple-bb-hmaFtMj", false, 0, bbCt3.m_bbTop + m_mkt.vspread);
   } else if (hmaFtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE) { // crossing down
      goBBShort(bbCt, "TSimple-bb-hmaFtMn", false, 0, bbCt3.m_bbTop + m_mkt.vspread);
   }
}
