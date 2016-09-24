//+------------------------------------------------------------------+
//|                                     AlphaVisionTraderScalper.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

/*
 * Swing Trader shall accumulate positions and do scale in and scale out
 * according to current trend.
 *
 */

#include <Traders\AlphaVisionTrader.mqh>


class AlphaVisionTraderSwing : public AlphaVisionTrader {
   public:
      AlphaVisionTraderSwing(AlphaVisionSignals *signals, double lotSize): AlphaVisionTrader(signals) {
         m_lotSize = lotSize;
         m_entries.hPut("BBSmart", new EntryPointsBBSmart(m_signals));
      }
      
      virtual void onSignalTrade(int timeframe);

};


void AlphaVisionTraderSwing::onSignalTrade(int timeframe) {
   AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
   RainbowTrend *rainbowFast = av.m_rainbowFast;
   StochasticTrend *stoch = av.m_stoch;
   ATRdelta *atr = av.m_atr;
   BBTrend *bb = av.m_bb;
   MACDTrend *macd = av.m_macd;
   
   if (m_volatility == TREND_VOLATILITY_LOW) setTradeMarket(false);
   else setTradeMarket(true);

   TrendChange tc = rainbowFast.getTrendHst();
   if (m_buySetupOk == true && stoch.m_signal < STOCH_OVERBOUGHT_THRESHOLD) { // BUY SETUP
      if (tc.changed == true && tc.current == TREND_POSITIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up on oversold territory
         onBuySignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_POSITIVE_FROM_NEGATIVE && stoch.m_signal <= STOCH_OVERSOLD_THRESHOLD) { // crossing up
         onBuySignal(timeframe, rainbowFast.m_ma3, "macd");
      }   
   }
   
   if (m_sellSetupOk == true && stoch.m_signal > STOCH_OVERSOLD_THRESHOLD) { // SELL SETUP
      if (tc.changed == true && tc.current == TREND_NEGATIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down on overbought territory
         onSellSignal(timeframe, rainbowFast.m_ma3, "rainbow");
      } else if (macd.getTrend() == TREND_NEGATIVE_FROM_POSITIVE && stoch.m_signal >= STOCH_OVERBOUGHT_THRESHOLD) { // crossing down
         onSellSignal(timeframe, rainbowFast.m_ma3, "macd");
      }
   }
}
