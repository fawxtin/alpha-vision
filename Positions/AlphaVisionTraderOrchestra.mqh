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
      
      virtual void tradeOnTrends();
      void tradeSetupOn(int timeframe);
      void tradeOn(int timeframe);
      void orchestraBuy(int timeframe, double signalPrice);
      void orchestraSell(int timeframe, double signalPrice);

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
   tradeSetupOn(stf.fast);
   tradeSetupOn(stf.current);
}

void AlphaVisionTraderOrchestra::tradeSetupOn(int timeframe) {
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
      tradeOn(timeframe);
   } else if (simplifiedMj == "POSITIVE") { // Positive trend
      m_signals.setSignal(timeframe, SSIGNAL_POSITIVE);
      signal = m_signals.getSignal(timeframe);
      if (signal.changed) {
         Alert(StringFormat("[Trader/%s] %s signal changed to: %s", Symbol(),
                            m_signals.getTimeframeStr(timeframe), EnumToString((SSIGNALS) signal.current)));
         if (stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) closeShorts(timeframe, StringFormat("Trend-Positive[%d]", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      tradeOn(timeframe);
   } else if (simplifiedMj == "NEGATIVE") { // Negative trend
      m_signals.setSignal(timeframe, SSIGNAL_NEGATIVE);
      signal = m_signals.getSignal(timeframe);
      if (signal.changed) {
         Alert(StringFormat("[Trader/%s] %s signal changed to: %s", Symbol(),
                            m_signals.getTimeframeStr(timeframe), EnumToString((SSIGNALS) signal.current)));
         if (stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeLongs(timeframe, StringFormat("Trend-Negative[%d]", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      tradeOn(timeframe);
   }
}

void AlphaVisionTraderOrchestra::tradeOn(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   HMATrend *hmaMj = av.m_hmaMajor;
   HMATrend *hmaMn = av.m_hmaMinor;
   // TODO: use 2 stochs? a) on default , and b) default on fast timeframe or faster one
   StochasticTrend *stoch = av.m_stoch;

   // using fast trend signals and current trend BB positioning
   if (hmaMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
       stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      orchestraBuy(timeframe, hmaMj.getMAPeriod2());
   } else if (hmaMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
              stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      orchestraBuy(timeframe, hmaMn.getMAPeriod2());
   } else if (hmaMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      orchestraSell(timeframe, hmaMj.getMAPeriod2());
   } else if (hmaMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      orchestraSell(timeframe, hmaMn.getMAPeriod2());
   }
}

void AlphaVisionTraderOrchestra::orchestraBuy(int timeframe, double signalPrice) {
   if (isBarMarked("long", timeframe)) return;
   else markBarTraded("long", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;
   //AlphaVision *avFt = m_signals.getAlphaVisionOn(stf.fast);
   //ATRdelta *atrFt = avFt.m_at

   double marketPrice = Ask;
   double limitPrice = bb.m_bbBottom;
   double target = bb.m_bbTop;
   double stopLoss = bb3.m_bbBottom - m_mkt.vspread;
   if (riskAndRewardRatio(marketPrice, target, stopLoss) > MIN_RISK_AND_REWARD_RATIO) {
      goLong(timeframe, marketPrice, target, stopLoss, StringFormat("ORCH-market[%d]", timeframe));
   } else {
      double entryPrice = riskAndRewardRatioEntry(MIN_RISK_AND_REWARD_RATIO, target, stopLoss);
      goLong(timeframe, entryPrice, target, stopLoss, StringFormat("ORCH-rr2[%d]", timeframe));
   }
   goLong(timeframe, limitPrice, target, stopLoss, StringFormat("ORCH-limit[%d]", timeframe));
}

void AlphaVisionTraderOrchestra::orchestraSell(int timeframe, double signalPrice) {
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
      goShort(timeframe, marketPrice, target, stopLoss, StringFormat("ORCH-market[%d]", timeframe));
   } else {
      double entryPrice = riskAndRewardRatioEntry(MIN_RISK_AND_REWARD_RATIO, target, stopLoss);
      goShort(timeframe, entryPrice, target, stopLoss, StringFormat("ORCH-rr2[%d]", timeframe));
   }
   goShort(timeframe, limitPrice, target, stopLoss, StringFormat("ORCH-limit[%d]", timeframe));
}
