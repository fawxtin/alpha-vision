//+------------------------------------------------------------------+
//|                                         AlphaVisionTraderPNN.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict


#include <Traders\AlphaVisionTrader.mqh>


class AlphaVisionTrendTrader : public AlphaVisionTrader {
   public:
      AlphaVisionTrendTrader(AlphaVisionSignals *signals, double rr): AlphaVisionTrader(signals) {
         m_riskAndRewardRatio = rr;
      }

      virtual void onSignalTrade(int timeframe, int trend);
      void trendBuy(int timeframe, double signalPrice, string signalOrigin="");
      void trendSell(int timeframe, double signalPrice, string signalOrigin="");
};


void AlphaVisionTrendTrader::onSignalTrade(int timeframe, int trend) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   StochasticTrend *stoch = av.m_stoch;
   MACDTrend *macd = av.m_macd;

   // using fast trend signals and current trend BB positioning
   TrendChange rFast = rainbowFast.getTrendHst();
   
   if (m_buySetupOk == true && (trend == TREND_POSITIVE || trend == TREND_NEUTRAL)) {
      if (rFast.changed == true && rFast.current == TREND_POSITIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         trendBuy(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         trendBuy(timeframe, rainbowFast.m_ma3, "macd");
      }   
   }
   
   if (m_sellSetupOk == true && (trend == TREND_NEGATIVE || trend == TREND_NEUTRAL)) {
      if (rFast.changed == true && rFast.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         trendSell(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         trendSell(timeframe, rainbowFast.m_ma3, "macd");
      }
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
   
   safeGoLong(timeframe, marketPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("TRNT-%s-mkt", signalOrigin));
   safeGoLong(timeframe, limitPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("TRNT-%s-lmt", signalOrigin));
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

   safeGoShort(timeframe, marketPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("TRNT-%s-mkt", signalOrigin));
   safeGoShort(timeframe, limitPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("TRNT-%s-lmt", signalOrigin));
}

