//+------------------------------------------------------------------+
//|                                     AlphaVisionTraderScalper.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <Traders\AlphaVisionTrader.mqh>


class AlphaVisionTraderScalper : public AlphaVisionTrader {      
   public:
      AlphaVisionTraderScalper(AlphaVisionSignals *signals, double rr): AlphaVisionTrader(signals) {
         m_riskAndRewardRatio = rr;
         EntryPoints *entry = m_entries.hGet("PVT");
         entry.setEnabled(true);
      }
      
      virtual void onSignalTrade(int timeframe);
};

void AlphaVisionTraderScalper::onSignalTrade(int timeframe) {
   // wont trade on high volatility
   if (m_volatility != TREND_VOLATILITY_LOW) return;
   
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   RainbowTrend *rainbowSlow = av.m_rainbowSlow;
   StochasticTrend *stoch = av.m_stoch;
   MACDTrend *macd = av.m_macd;

   // using fast trend signals and current trend BB positioning
   TrendChange rFast = rainbowFast.getTrendHst();
   if (m_buySetupOk && stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) { // BUY SETUP
      if (rFast.changed == true && rFast.current == TREND_POSITIVE && 
          stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
         onBuySignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE &&
                 stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
         onBuySignal(timeframe, rainbowFast.m_ma3, "macd");
      } else if (rainbowSlow.m_cross_1_2.current == TREND_POSITIVE_FROM_NEGATIVE) {
         onBuySignal(timeframe, rainbowSlow.m_ma2, "hma12");
      } else if (rainbowSlow.m_cross_1_3.current == TREND_POSITIVE_FROM_NEGATIVE) {
         onBuySignal(timeframe, rainbowSlow.m_ma3, "hma13");
      } else if (rainbowSlow.m_cross_2_3.current == TREND_POSITIVE_FROM_NEGATIVE) {
         onBuySignal(timeframe, rainbowSlow.m_ma3, "hma23");
      }
   }
   
   if (m_sellSetupOk && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (rFast.changed == true && rFast.current == TREND_NEGATIVE && 
          stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         onSellSignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE &&
                 stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         onSellSignal(timeframe, rainbowFast.m_ma3, "macd");
      } else if (rainbowSlow.m_cross_1_2.current == TREND_NEGATIVE_FROM_POSITIVE) {
         onSellSignal(timeframe, rainbowSlow.m_ma2, "hma12");
      } else if (rainbowSlow.m_cross_1_3.current == TREND_NEGATIVE_FROM_POSITIVE) {
         onSellSignal(timeframe, rainbowSlow.m_ma3, "hma13");
      } else if (rainbowSlow.m_cross_2_3.current == TREND_NEGATIVE_FROM_POSITIVE) {
         onSellSignal(timeframe, rainbowSlow.m_ma3, "hma23");
      }
   }
}

