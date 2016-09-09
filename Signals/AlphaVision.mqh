//+------------------------------------------------------------------+
//|                                                  AlphaVision.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Arrays\Hash.mqh>

#include <Trends\trends.mqh>
#include <Trends\HMA.mqh>
#include <Trends\Rainbow.mqh>
#include <Trends\ATR.mqh>
#include <Trends\BB.mqh>
#include <Trends\Stochastic.mqh>
#include <Trends\MACD.mqh>

#include <Signals\Signals.mqh>


#ifndef __SIGNALS_ALPHAVISION__
#define __SIGNALS_ALPHAVISION__ 1



class AlphaVision : public HashValue {
   public:
      RainbowTrend *m_rainbowFast;
      RainbowTrend *m_rainbowSlow;
      BBTrend *m_bb;
      BBTrend *m_bb3;
      StochasticTrend *m_stoch;
      MACDTrend *m_macd;
      ATRdelta *m_atr;
          
   
      AlphaVision(RainbowTrend *rainbowFast, RainbowTrend *rainbowSlow, BBTrend *bb, BBTrend *bb3,
                  StochasticTrend *stoch, MACDTrend *macd, ATRdelta *atr) {
         m_rainbowFast = rainbowFast;
         m_rainbowSlow = rainbowSlow;
         m_bb = bb;
         m_bb3 = bb3;
         m_stoch = stoch;
         m_macd = macd;
         m_atr = atr;
      }

      void ~AlphaVision() {
         delete m_rainbowFast;
         delete m_rainbowSlow;
         delete m_bb;
         delete m_bb3;
         delete m_stoch;
         delete m_macd;
         delete m_atr;
      }
      
      void calculate() {
         m_rainbowFast.calculate();
         m_rainbowSlow.calculate();
         m_bb.calculate();
         m_bb3.calculate();
         m_stoch.calculate();
         m_macd.calculate();
         m_atr.calculate();
      }
};

class AlphaVisionSignals : public Signals {
   protected:
      string getKey(int timeframe) { return EnumToString((ENUM_TIMEFRAMES) timeframe); }
      Hash *m_hash;
      
   public:
      AlphaVisionSignals(SignalTimeFrames &tfs) : Signals(tfs) { m_hash = new Hash(193, true); }
      void ~AlphaVisionSignals() { delete m_hash; }
      
      // TODO: from different passed config structures (HMA, ATR, BB, ...), could get different stuff
      bool initOn(int timeframe) {
         string tfKey = getKey(timeframe);
         if (! m_hash.hContainsKey(tfKey)) {
            m_hash.hPut(tfKey, new AlphaVision(new RainbowTrend(timeframe),
                                               new RainbowTrend(timeframe, 20, 50, 200),
                                               new BBTrend(timeframe),
                                               new BBTrend(timeframe, 3.0),
                                               new StochasticTrend(timeframe),
                                               new MACDTrend(timeframe),
                                               new ATRdelta(timeframe, 14, 80)));
            return true;
         }
         else return false;
      }
      
      bool calculateOn(int timeframe) {
         string tfKey = getKey(timeframe);
         if (m_hash.hContainsKey(tfKey)) {
            AlphaVision *av = m_hash.hGet(tfKey);
            av.calculate();
            return true;
         } else
            return false;
      }
      
      AlphaVision *getAlphaVisionOn(int timeframe) {
         string tfKey = getKey(timeframe);
         if (m_hash.hContainsKey(tfKey)) return m_hash.hGet(tfKey);
         else return NULL;
      }
};


#endif
