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
      virtual void calculateBuyEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="");
      virtual void calculateSellEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="");
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
         onBuySignal(timeframe, trend, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, trend, rainbowFast.m_ma3, "macd");
      }   
   }
   
   if (m_sellSetupOk == true && (trend == TREND_NEGATIVE || trend == TREND_NEUTRAL)) {
      if (rFast.changed == true && rFast.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, trend, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, trend, rainbowFast.m_ma3, "macd");
      }
   }
}

void AlphaVisionTrendTrader::calculateBuyEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="") {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   ee.market = Ask;
   ee.limit = bb.m_bbBottom;
   ee.target = bb.m_bbTop;
   ee.stopLoss = bb3.m_bbBottom - m_mkt.vspread * 2;
   ee.algo = StringFormat("TRNT-%s-lmt", signalOrigin);
   
   //safeGoLong(timeframe, marketPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("TRNT-%s-mkt", signalOrigin));
}

void AlphaVisionTrendTrader::calculateSellEntry(EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin="") {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   BBTrend *bb = av.m_bb;
   BBTrend *bb3 = av.m_bb3;

   ee.market = Bid;
   ee.limit = bb.m_bbTop;
   ee.target = bb.m_bbBottom;
   ee.stopLoss = bb3.m_bbTop + m_mkt.vspread * 2;
   ee.algo = StringFormat("TRNT-%s-lmt", signalOrigin);

   //safeGoShort(timeframe, marketPrice, target, stopLoss, m_riskAndRewardRatio, StringFormat("TRNT-%s-mkt", signalOrigin));
}

