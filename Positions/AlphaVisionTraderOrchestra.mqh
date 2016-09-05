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
#define MIN_RISK_AND_REWARD_RATIO 2

class AlphaVisionTraderOrchestra : public AlphaVisionTrader {
   private:
      int m_barDebug;

   public:
      AlphaVisionTraderOrchestra(AlphaVisionSignals *signals): AlphaVisionTrader(signals) {
         m_barDebug = 0;
      }
      
      virtual void onTrendSetup(int timeframe);
      virtual void onSignalTrade(int timeframe);
      void orchestraBuy(int timeframe, double signalPrice, string signalOrigin="");
      void orchestraSell(int timeframe, double signalPrice, string signalOrigin="");

};

void AlphaVisionTraderOrchestra::onTrendSetup(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   HMATrend *hmaMj = av.m_hmaMajor;
   HMATrend *hmaMn = av.m_hmaMinor;
   StochasticTrend *stoch = av.m_stoch;

   SignalChange *signal;
   string simplifiedMj = hmaMj.simplify();
   string simplifiedMn = hmaMn.simplify();
   if (simplifiedMj != simplifiedMn) { // Neutral trend
      m_signals.setSignal(timeframe, SSIGNAL_NEUTRAL);
      signal = m_signals.getSignal(timeframe);
      onSignalTrade(timeframe);
   } else if (simplifiedMj == "POSITIVE") { // Positive trend
      m_signals.setSignal(timeframe, SSIGNAL_POSITIVE);
      signal = m_signals.getSignal(timeframe);
      if (signal.changed) {
         Alert(StringFormat("[Trader/%s] %s signal changed to: %s", Symbol(),
                            m_signals.getTimeframeStr(timeframe), EnumToString((SSIGNALS) signal.current)));
         if (stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) closeShorts(timeframe, StringFormat("Trend-Positive[%d]", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      onSignalTrade(timeframe);
   } else if (simplifiedMj == "NEGATIVE") { // Negative trend
      m_signals.setSignal(timeframe, SSIGNAL_NEGATIVE);
      signal = m_signals.getSignal(timeframe);
      if (signal.changed) {
         Alert(StringFormat("[Trader/%s] %s signal changed to: %s", Symbol(),
                            m_signals.getTimeframeStr(timeframe), EnumToString((SSIGNALS) signal.current)));
         if (stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeLongs(timeframe, StringFormat("Trend-Negative[%d]", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      onSignalTrade(timeframe);
   }
}

void AlphaVisionTraderOrchestra::onSignalTrade(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   HMATrend *hmaMj = av.m_hmaMajor;
   HMATrend *hmaMn = av.m_hmaMinor;
   StochasticTrend *stoch = av.m_stoch;
   MACDTrend *macd = av.m_macd;

   // using fast trend signals and current trend BB positioning
   if (hmaMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
       stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      orchestraBuy(timeframe, hmaMj.getMAPeriod2(), "hmaMj");
   } else if (hmaMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
              stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      orchestraBuy(timeframe, hmaMn.getMAPeriod2(), "hmaMn");
   } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing up
      orchestraBuy(timeframe, hmaMn.getMAPeriod1(), "macd");
   } else if (hmaMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      orchestraSell(timeframe, hmaMj.getMAPeriod2(), "hmaMj");
   } else if (hmaMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      orchestraSell(timeframe, hmaMn.getMAPeriod2(), "hmaMn");
   } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERSOLD_THRESHOLD) { // crossing down
      orchestraSell(timeframe, hmaMn.getMAPeriod1(), "macd");
   }
}

void AlphaVisionTraderOrchestra::orchestraBuy(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("long", timeframe)) return;
   else markBarTraded("long", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   double marketPrice = Ask;
   double limitPrice = bb.m_bbBottom;
   double target = bb.m_bbTop;
   double stopLoss = bb3.m_bbBottom - m_mkt.vspread;
   if (riskAndRewardRatio(marketPrice, target, stopLoss) > MIN_RISK_AND_REWARD_RATIO) {
      goLong(timeframe, marketPrice, target, stopLoss, StringFormat("ORCH-%s-mkt[%d]", signalOrigin, timeframe));
   } else {
      double entryPrice = riskAndRewardRatioEntry(MIN_RISK_AND_REWARD_RATIO, target, stopLoss);
      goLong(timeframe, entryPrice, target, stopLoss, StringFormat("ORCH-%s-rr2[%d]", signalOrigin, timeframe));
   }
   goLong(timeframe, limitPrice, target, stopLoss, StringFormat("ORCH-%s-lmt[%d]", signalOrigin, timeframe));
}

void AlphaVisionTraderOrchestra::orchestraSell(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("short", timeframe)) return;
   else markBarTraded("short", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   double marketPrice = Bid;
   double limitPrice = bb.m_bbTop;
   double target = bb.m_bbBottom;
   double stopLoss = bb3.m_bbTop + m_mkt.vspread;
   if (riskAndRewardRatio(marketPrice, target, stopLoss) > MIN_RISK_AND_REWARD_RATIO) {
      goShort(timeframe, marketPrice, target, stopLoss, StringFormat("ORCH-%s-mkt[%d]", signalOrigin, timeframe));
   } else {
      double entryPrice = riskAndRewardRatioEntry(MIN_RISK_AND_REWARD_RATIO, target, stopLoss);
      goShort(timeframe, entryPrice, target, stopLoss, StringFormat("ORCH-%s-rr2[%d]", signalOrigin, timeframe));
   }
   goShort(timeframe, limitPrice, target, stopLoss, StringFormat("ORCH-%s-lmt[%d]", signalOrigin, timeframe));
}
