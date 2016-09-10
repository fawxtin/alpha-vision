//+------------------------------------------------------------------+
//|                                         AlphaVisionTraderPNN.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict


#include <Traders\AlphaVisionTrader.mqh>

#define STOCH_OVERSOLD_THRESHOLD 35
#define STOCH_OVERBOUGHT_THRESHOLD 65
#define MIN_RISK_AND_REWARD_RATIO 1.8


class AlphaVisionTrendTrader : public AlphaVisionTrader {
   public:
      AlphaVisionTrendTrader(AlphaVisionSignals *signals): AlphaVisionTrader(signals) {}

      virtual void tradeOnTrends();

      virtual void onTrendSetup(int timeframe);
      virtual void onSignalValidation(int timeframe);
      virtual void onSignalTrade(int timeframe);
      void trendBuy(int timeframe, double signalPrice, string signalOrigin="");
      void trendSell(int timeframe, double signalPrice, string signalOrigin="");
};

void AlphaVisionTrendTrader::onTrendSetup(int timeframe) {
   int higherTF = m_signals.getTimeFrameAbove(timeframe);
   AlphaVision *avHi = m_signals.getAlphaVisionOn(higherTF);
   StochasticTrend *stochHi = avHi.m_stoch;

   if (stochHi.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // sell setup
      m_buySetupOk = false;
      m_sellSetupOk = true;
   } else if (stochHi.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // buy setup
      m_buySetupOk = true;
      m_sellSetupOk = false;
   } else if (m_buySetupOk == false || m_sellSetupOk == false) { // neutral setup
      m_buySetupOk = true;
      m_sellSetupOk = true;
   }
   
   onSignalValidation(timeframe);
}

void AlphaVisionTrendTrader::onSignalValidation(int timeframe) {
   int higherTF = m_signals.getTimeFrameAbove(timeframe);
   // higher timeframe
   AlphaVision *avHi = m_signals.getAlphaVisionOn(higherTF);
   RainbowTrend *rainbowHiFast = avHi.m_rainbowFast;
   // working timeframe
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   StochasticTrend *stoch = av.m_stoch;

   TrendChange rHiFast = rainbowHiFast.getTrendHst();
   if (rHiFast.current == TREND_NEUTRAL) { // Neutral trend
      onSignalTrade(timeframe);
   } else if (rHiFast.current == TREND_POSITIVE) { // Positive trend
      if (rHiFast.changed) {
         Alert(StringFormat("[Trader/%s] %s RainbowFast changed to: %s", Symbol(), m_signals.getTimeframeStr(higherTF), 
                            EnumToString((TRENDS) rHiFast.current)));
         if (stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) closeShorts(timeframe, "Trend-Positive");
         // TODO: else update current positions stoploss and sell more
      }
      if (m_sellSetupOk) m_sellSetupOk = false;
      onSignalTrade(timeframe);
   } else if (rHiFast.current == TREND_NEGATIVE) { // Negative trend
      if (rHiFast.changed) {
         Alert(StringFormat("[Trader/%s] %s RainbowFast changed to: %s", Symbol(), m_signals.getTimeframeStr(higherTF),
                            EnumToString((TRENDS) rHiFast.current)));
         if (stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) closeLongs(timeframe, "Trend-Negative");
         // TODO: else update current positions stoploss and sell more
      }
      if (m_buySetupOk) m_buySetupOk = false;
      onSignalTrade(timeframe);
   }
}

void AlphaVisionTrendTrader::onSignalTrade(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   StochasticTrend *stoch = av.m_stoch;
   MACDTrend *macd = av.m_macd;

   // using fast trend signals and current trend BB positioning
   TrendChange rFast = rainbowFast.getTrendHst();
   
   if (rFast.changed == true && m_buySetupOk && 
       rFast.current == TREND_POSITIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      trendBuy(timeframe, rainbowFast.m_ma3, "rainbow");
   } else if (m_buySetupOk && macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
              stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
      trendBuy(timeframe, rainbowFast.m_ma3, "macd");
   } else if (rFast.changed == true && m_sellSetupOk &&
              rFast.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      trendSell(timeframe, rainbowFast.m_ma3, "rainbow");
   } else if (m_sellSetupOk && macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
              stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
      trendSell(timeframe, rainbowFast.m_ma3, "macd");
   }
}

void AlphaVisionTrendTrader::trendBuy(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("long", timeframe)) return;
   else markBarTraded("long", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   double marketPrice = Ask;
   double limitPrice = bb.m_bbBottom;
   double target = bb.m_bbTop;
   double stopLoss = bb3.m_bbBottom - m_mkt.vspread;
   
   safeGoLong(timeframe, marketPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("TRNT-%s-mkt", signalOrigin));
   safeGoLong(timeframe, limitPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("TRNT-%s-lmt", signalOrigin));
}

void AlphaVisionTrendTrader::trendSell(int timeframe, double signalPrice, string signalOrigin="") {
   if (isBarMarked("short", timeframe)) return;
   else markBarTraded("short", timeframe);

   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   double marketPrice = Bid;
   double limitPrice = bb.m_bbTop;
   double target = bb.m_bbBottom;
   double stopLoss = bb3.m_bbTop + m_mkt.vspread;

   safeGoShort(timeframe, marketPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("TRNT-%s-mkt", signalOrigin));
   safeGoShort(timeframe, limitPrice, target, stopLoss, MIN_RISK_AND_REWARD_RATIO, StringFormat("TRNT-%s-lmt", signalOrigin));
}

