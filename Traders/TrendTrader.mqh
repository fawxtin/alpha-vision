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
         m_entries.hPut("BB", new EntryPointsBB(m_signals));
         setTradeMarket(true);
      }

      virtual void onSignalTrade(int timeframe);
};


void AlphaVisionTrendTrader::onSignalTrade(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   StochasticTrend *stoch = av.m_stoch;
   MACDTrend *macd = av.m_macd;

   // using fast trend signals and current trend BB positioning
   TrendChange rFast = rainbowFast.getTrendHst();
   
   if (m_buySetupOk == true && (m_cTrend == TREND_POSITIVE || m_cTrend == TREND_NEUTRAL)) {
      if (rFast.changed == true && rFast.current == TREND_POSITIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, rainbowFast.m_ma3, "macd");
      }   
   }
   
   if (m_sellSetupOk == true && (m_cTrend == TREND_NEGATIVE || m_cTrend == TREND_NEUTRAL)) {
      if (rFast.changed == true && rFast.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, rainbowFast.m_ma3, "macd");
      }
   }
}

