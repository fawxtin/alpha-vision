//+------------------------------------------------------------------+
//|                                     AlphaVisionTraderScalper.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <Traders\AlphaVisionTrader.mqh>


class AlphaVisionTraderPivot : public AlphaVisionTrader {      
   public:
      AlphaVisionTraderPivot(AlphaVisionSignals *signals, double rr): AlphaVisionTrader(signals) {
         m_riskAndRewardRatio = rr;
         m_entries.hPut("PVT", new EntryPointsPivot(m_signals));
      }
      
      virtual void onSignalTrade(int timeframe);
};

void AlphaVisionTraderPivot::onSignalTrade(int timeframe) {
   // wont trade on high volatility
   if (m_volatility != TREND_VOLATILITY_LOW) return;
   
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   StochasticTrend *stoch = av.m_stoch;
   ATRdelta *atr = av.m_atr;
   BBTrend *bb = av.m_bb;
   MACDTrend *macd = av.m_macd;

   TrendChange tc = rainbowFast.getTrendHst();
   // using fast trend signals and current trend BB positioning
   if (m_buySetupOk == true && stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) { // BUY SETUP
      if (tc.changed == true && tc.current == TREND_POSITIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) {
         onBuySignal(timeframe, rainbowFast.m_ma3, "macd");
      }   
   }
   
   if (m_sellSetupOk == true && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (tc.changed == true && tc.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) {
         onSellSignal(timeframe, rainbowFast.m_ma3, "macd");
      }
   }
}

