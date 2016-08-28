//+------------------------------------------------------------------+
//|                                   AlphaVisionTraderOrchestra.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Positions\AlphaVisionTrader.mqh>

#define STOCH_OVERSOLD_THRESHOLD 35
#define STOCH_OVERBOUGHT_THRESHOLD 65
#define MIN_RISK_AND_REWARD_RATIO 1.55

class AlphaVisionTraderOrchestra : public AlphaVisionTrader {
   private:
      int m_barLong;
      int m_barShort;
      int m_barDebug;

   public:
      AlphaVisionTraderOrchestra(Positions *longPs, Positions *shortPs, AlphaVisionSignals *signals): AlphaVisionTrader(longPs, shortPs, signals) {
         m_barLong = 0;
         m_barShort = 0;
         m_barDebug = 0;
      }

      virtual void tradeOnTrends();
      void tradeOn();
      void orchestraBuy();
      void orchestraSell();
};

void AlphaVisionTraderOrchestra::tradeOnTrends() {
   /*
    * On MACD cross signal & Stochastic signal ahead/below 70/30,
    * try to put sell/buy orders, with target on BB bottom/top:
    *   a) when market order Risk&Reward > 2, sell/buy market
    *   b) limit order on BB top/bottom
    *
    * 
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
      m_signals.setSignalCt(SSIGNAL_NEUTRAL);
      signalCt = m_signals.getSignalCt();
      tradeOn();
   } else if (simplifiedMj == "POSITIVE") { // Positive trend
      m_signals.setSignalCt(SSIGNAL_POSITIVE);
      signalCt = m_signals.getSignalCt();
      if (signalCt.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalCt.current));
         // TODO: when overbought region, dont close shorts -> sell more instead
         closeShorts("Positive-Trend");
      }
      tradeOn();
   } else if (simplifiedMj == "NEGATIVE") { // Negative trend
      m_signals.setSignalCt(SSIGNAL_NEGATIVE);
      signalCt = m_signals.getSignalCt();
      if (signalCt.changed) {
         Alert(StringFormat("[Trader] Current Timeframe trend changed to: %d", signalCt.current));
         // TODO: when oversold region, dont close longs -> buy more instead
         closeLongs("Negative-Trend");
      }
      tradeOn();
   }
}


void AlphaVisionTraderOrchestra::tradeOn() {
   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   HMATrend *hmaCtMj = avCt.m_hmaMajor;
   HMATrend *hmaCtMn = avCt.m_hmaMinor;
   // TODO: use 2 stochs? a) on default , and b) default on fast timeframe or faster one
   StochasticTrend *stoch = avCt.m_stoch;

   // using fast trend signals and current trend BB positioning
   if (hmaCtMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
       stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      orchestraBuy();
   } else if (hmaCtMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
              stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      orchestraBuy();
   } else if (hmaCtMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      orchestraSell();
   } else if (hmaCtMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      orchestraSell();
   }
}

void AlphaVisionTraderOrchestra::orchestraBuy(void) {
   if (m_barLong == Bars) return;
   else m_barLong = Bars;

   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   BBTrend *bbCt = avCt.m_bb;
   BBTrend *bb3Ct = avCt.m_bb3;
   //AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   //ATRdelta *atrFt = avFt.m_at

   double marketPrice = Ask;
   double limitPrice = bbCt.m_bbBottom;
   double target = bbCt.m_bbTop;
   double stopLoss = bb3Ct.m_bbBottom - m_mkt.vspread;
   if (riskAndRewardRatio(marketPrice, target, stopLoss) > MIN_RISK_AND_REWARD_RATIO) {
      goLong(marketPrice, target, stopLoss, "ORCH-market");
   } else {
      double entryPrice = riskAndRewardRatioEntry(2, target, stopLoss);
      PrintFormat("[ORCH] Best entry price for limit: %.4f", entryPrice);
      goLong(entryPrice, target, stopLoss, "ORCH-rr2");
   }
   goLong(limitPrice, target, stopLoss, "ORCH-limit");
}

void AlphaVisionTraderOrchestra::orchestraSell(void) {
   if (m_barShort == Bars) return;
   else m_barShort = Bars;

   SignalTimeFrames stf = m_signals.getTimeFrames();
   AlphaVision *avCt = m_signals.getAlphaVisionOn(stf.current);
   BBTrend *bbCt = avCt.m_bb;
   BBTrend *bb3Ct = avCt.m_bb3;

   double marketPrice = Bid;
   double limitPrice = bbCt.m_bbTop;
   double target = bbCt.m_bbBottom;
   double stopLoss = bb3Ct.m_bbTop + m_mkt.vspread;
   if (riskAndRewardRatio(marketPrice, target, stopLoss) > MIN_RISK_AND_REWARD_RATIO) {
      goShort(marketPrice, target, stopLoss, "ORCH-market");
   } else {
      double entryPrice = riskAndRewardRatioEntry(2, target, stopLoss);
      PrintFormat("[ORCH] Best entry price for limit: %.4f", entryPrice);
      goShort(entryPrice, target, stopLoss, "ORCH-rr2");
   }
   goShort(limitPrice, target, stopLoss, "ORCH-limit");
}
