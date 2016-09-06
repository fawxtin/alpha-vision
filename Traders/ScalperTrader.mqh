//+------------------------------------------------------------------+
//|                                     AlphaVisionTraderScalper.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <Traders\AlphaVisionTrader.mqh>

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
   ATRdelta *atr = av.m_atr;
   int higherTF = m_signals.getTimeFrameAbove(timeframe);

   // scalper not trading on high volatility
   if (atr.getTrend() == TREND_VOLATILITY_HIGH || atr.getTrend() == TREND_VOLATILITY_LOW_TO_HIGH) return;
   else onSignalTrade(timeframe);

   // TODO: maybe scalper can act better scalping on major timeframe trend rule
//   SignalChange *signal;
//   string simplifiedMj = hmaMj.simplify();
//   string simplifiedMn = hmaMn.simplify();
//   if (simplifiedMj != simplifiedMn) { // Neutral trend
//      m_signals.setSignal(timeframe, SSIGNAL_NEUTRAL);
//      signal = m_signals.getSignal(timeframe);
//      onSignalTrade(timeframe);
//   } else if (simplifiedMj == "POSITIVE") { // Positive trend - only buy
//      m_signals.setSignal(timeframe, SSIGNAL_POSITIVE);
//      signal = m_signals.getSignal(timeframe);
//      if (signal.changed) {
//         Alert(StringFormat("[Trader/%s] %s signal changed to: %s/%s", Symbol(), m_signals.getTimeframeStr(timeframe),
//                            EnumToString((SSIGNALS) signal.current), EnumToString((TRENDS) atr.getTrend())));
//         if (stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) closeShorts(timeframe, StringFormat("Trend-Positive[%d]", timeframe));
//         // TODO: else update current positions stoploss and sell more
//      }
//      onSignalTrade(timeframe);
//   } else if (simplifiedMj == "NEGATIVE") { // Negative trend - only sell
//      m_signals.setSignal(timeframe, SSIGNAL_NEGATIVE);
//      signal = m_signals.getSignal(timeframe);
//      if (signal.changed) {
//         Alert(StringFormat("[Trader/%s] %s signal changed to: %s/%s", Symbol(), m_signals.getTimeframeStr(timeframe), 
//                            EnumToString((SSIGNALS) signal.current), EnumToString((TRENDS) atr.getTrend())));
//         if (stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeLongs(timeframe, StringFormat("Trend-Negative[%d]", timeframe));
//         // TODO: else update current positions stoploss and sell more
//      }
//      onSignalTrade(timeframe);
//   }
}

//void AlphaVisionTraderScalper::checkVolatility(int timeframe) { // not using it
//   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
//   ATRdelta *atr = av.m_atr;
//
//   if (atr.getTrend() == TREND_VOLATILITY_LOW) onScalpTrade(timeframe); 
//}

void AlphaVisionTraderScalper::onSignalTrade(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbow = av.m_rainbow;
   HMATrend *hmaMn = av.m_hmaMinor;
   StochasticTrend *stoch = av.m_stoch;
   ATRdelta *atr = av.m_atr;
   BBTrend *bb = av.m_bb;

   TrendChange tc = rainbow.getTrendHst();
   // using fast trend signals and current trend BB positioning
   if (tc.changed == false) return;
   if (tc.current == TREND_POSITIVE &&
       stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up on oversold territory
      scalperBuy(timeframe, hmaMn.getMAPeriod1(), "rainbow");
   } else if (tc.current == TREND_NEGATIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down on overbought territory
      scalperSell(timeframe, hmaMn.getMAPeriod1(), "rainbow");
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
