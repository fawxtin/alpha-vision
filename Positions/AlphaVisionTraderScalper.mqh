//+------------------------------------------------------------------+
//|                                     AlphaVisionTraderScalper.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <Positions\AlphaVisionTrader.mqh>

#define STOCH_OVERSOLD_THRESHOLD 40
#define STOCH_OVERBOUGHT_THRESHOLD 60
#define MIN_RISK_AND_REWARD_RATIO 1.55

class AlphaVisionTraderScalper : public AlphaVisionTrader {
   public:
      AlphaVisionTraderScalper(AlphaVisionSignals *signals): AlphaVisionTrader(signals) { }
      
      virtual void onTrendSetup(int timeframe);
      virtual void onSignalTrade(int timeframe);
      virtual void onSignalValidation(int timeframe) {}
      virtual void checkVolatility(int timeframe);
      virtual void onScalpTrade(int timeframe);
      virtual void onBreakoutTrade(int timeframe) {}
      void scalperBuy(int timeframe, double signalPrice, string signalOrigin="");
      void scalperSell(int timeframe, double signalPrice, string signalOrigin="");

};

void AlphaVisionTraderScalper::onTrendSetup(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   HMATrend *hmaMj = av.m_hmaMajor;
   HMATrend *hmaMn = av.m_hmaMinor;
   StochasticTrend *stoch = av.m_stoch;
   ATRdelta *atr = av.m_atr;

   SignalChange *signal;
   string simplifiedMj = hmaMj.simplify();
   string simplifiedMn = hmaMn.simplify();
   if (simplifiedMj != simplifiedMn) { // Neutral trend
      m_signals.setSignal(timeframe, SSIGNAL_NEUTRAL);
      signal = m_signals.getSignal(timeframe);
      onSignalTrade(timeframe);
   } else if (simplifiedMj == "POSITIVE") { // Positive trend - only buy
      m_signals.setSignal(timeframe, SSIGNAL_POSITIVE);
      signal = m_signals.getSignal(timeframe);
      if (signal.changed) {
         Alert(StringFormat("[Trader/%s] %s signal changed to: %s/%s", Symbol(), m_signals.getTimeframeStr(timeframe),
                            EnumToString((SSIGNALS) signal.current), EnumToString((TRENDS) atr.getTrend())));
         if (stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) closeShorts(timeframe, StringFormat("Trend-Positive[%d]", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      onSignalTrade(timeframe);
   } else if (simplifiedMj == "NEGATIVE") { // Negative trend - only sell
      m_signals.setSignal(timeframe, SSIGNAL_NEGATIVE);
      signal = m_signals.getSignal(timeframe);
      if (signal.changed) {
         Alert(StringFormat("[Trader/%s] %s signal changed to: %s/%s", Symbol(), m_signals.getTimeframeStr(timeframe), 
                            EnumToString((SSIGNALS) signal.current), EnumToString((TRENDS) atr.getTrend())));
         if (stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeLongs(timeframe, StringFormat("Trend-Negative[%d]", timeframe));
         // TODO: else update current positions stoploss and sell more
      }
      onSignalTrade(timeframe);
   }
}

//void AlphaVisionTraderScalper::checkVolatility(int timeframe) { // not using it
//   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
//   ATRdelta *atr = av.m_atr;
//
//   if (atr.getTrend() == TREND_VOLATILITY_LOW) onScalpTrade(timeframe); 
//}

void AlphaVisionTraderScalper::onSignalTrade(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   HMATrend *hmaMj = av.m_hmaMajor;
   HMATrend *hmaMn = av.m_hmaMinor;
   MACDTrend *macd = av.m_macd;
   StochasticTrend *stoch = av.m_stoch;
   ATRdelta *atr = av.m_atr;
   BBTrend *bb = av.m_bb;

   // scalper not trading on high volatility
   if (atr.getTrend() == TREND_VOLATILITY_HIGH || atr.getTrend() == TREND_VOLATILITY_LOW_TO_HIGH) return;
   
   // using fast trend signals and current trend BB positioning
   if (hmaMj.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
       stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      scalperBuy(timeframe, hmaMj.getMAPeriod2(), "hmaMj");
   } else if (hmaMn.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
              stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      scalperBuy(timeframe, hmaMn.getMAPeriod2(), "hmaMn");
   } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing up
      scalperBuy(timeframe, Ask, "macd");
   } else if (hmaMj.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      scalperSell(timeframe, hmaMj.getMAPeriod2(), "hmaMj");
   } else if (hmaMn.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      scalperSell(timeframe, hmaMn.getMAPeriod2(), "hmaMn");
   } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERSOLD_THRESHOLD) { // crossing down
      scalperSell(timeframe, Bid, "macd");
   }
}

void AlphaVisionTraderScalper::scalperBuy(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("long", timeframe)) return;
   else markBarTraded("long", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   double marketPrice = Ask;
   double limitPrice;
   double target;
   double stopLoss;
   
   if (bb.simplify() == "POSITIVE") {
      limitPrice = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
      target = bb.m_bbTop;
      stopLoss = bb.m_bbBottom - (m_mkt.vspread * 2);
   } else { // Negative
      limitPrice = bb.m_bbBottom;
      target = (bb.m_bbMiddle + bb.m_bbTop) / 2;
      stopLoss = bb3.m_bbBottom - (m_mkt.vspread * 2);      
   }
   
   if (riskAndRewardRatio(marketPrice, target, stopLoss) > MIN_RISK_AND_REWARD_RATIO) {
      goLong(timeframe, marketPrice, target, stopLoss, StringFormat("SCLP-%s-mkt[%d]", signalOrigin, timeframe));
   } else {
      double entryPrice = riskAndRewardRatioEntry(MIN_RISK_AND_REWARD_RATIO, target, stopLoss);
      goLong(timeframe, entryPrice, target, stopLoss, StringFormat("SCLP-%s-rr[%d]", signalOrigin, timeframe));
   }
   goLong(timeframe, limitPrice, target, stopLoss, StringFormat("SCLP-%s-lmt[%d]", signalOrigin, timeframe));
}

void AlphaVisionTraderScalper::scalperSell(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("short", timeframe)) return;
   else markBarTraded("short", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   double marketPrice = Bid;
   double limitPrice = bb.m_bbTop;
   double target = bb.m_bbBottom;
   double stopLoss = bb3.m_bbTop + m_mkt.vspread;

   if (bb.simplify() == "POSITIVE") {
      limitPrice = bb.m_bbTop;
      target = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
      stopLoss = bb3.m_bbTop + (m_mkt.vspread * 2);      
   } else if (bb.simplify() == "NEGATIVE") {
      limitPrice = (bb.m_bbMiddle + bb.m_bbTop) / 2;
      target = bb.m_bbBottom;
      stopLoss = bb.m_bbTop + (m_mkt.vspread * 2);
   }

   if (riskAndRewardRatio(marketPrice, target, stopLoss) > MIN_RISK_AND_REWARD_RATIO) {
      goShort(timeframe, marketPrice, target, stopLoss, StringFormat("SCLP-%s-mkt[%d]", signalOrigin, timeframe));
   } else {
      double entryPrice = riskAndRewardRatioEntry(MIN_RISK_AND_REWARD_RATIO, target, stopLoss);
      goShort(timeframe, entryPrice, target, stopLoss, StringFormat("SCLP-%s-rr[%d]", signalOrigin, timeframe));
   }
   goShort(timeframe, limitPrice, target, stopLoss, StringFormat("SCLP-%s-lmt[%d]", signalOrigin, timeframe));
}
