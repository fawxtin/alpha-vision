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
#include <Trends\ATR.mqh>
#include <Trends\BB.mqh>
#include <Trends\Stochastic.mqh>
#include <Trends\MACD.mqh>

#include <Signals\Signals.mqh>


#ifndef __SIGNALS_ALPHAVISION__
#define __SIGNALS_ALPHAVISION__ 1



class AlphaVision : public HashValue {
   public:
      HMATrend *m_hmaMinor;
      HMATrend *m_hmaMajor;
      BBTrend *m_bb;
      BBTrend *m_bb3;
      StochasticTrend *m_stoch;
      MACDTrend *m_macd;
      
   
      AlphaVision(HMATrend *major, HMATrend *minor, BBTrend *bb, BBTrend *bb3, StochasticTrend *stoch, MACDTrend *macd) {
         m_hmaMajor = major;
         m_hmaMinor = minor;
         m_bb = bb;
         m_bb3 = bb3;
         m_stoch = stoch;
         m_macd = macd;
      }

      void ~AlphaVision() {
         delete m_hmaMinor;
         delete m_hmaMajor;
         delete m_bb;
         delete m_bb3;
         delete m_stoch;
         delete m_macd;
      }
      
      void calculate() {
         m_hmaMajor.calculate();
         m_hmaMinor.calculate();
         m_bb.calculate();
         m_bb3.calculate();
         m_stoch.calculate();
         m_macd.calculate();
      }
};

class AlphaVisionSignals : public Signals {
   protected:
      string getKey(int timeframe) { return EnumToString((ENUM_TIMEFRAMES) timeframe); }
      Hash *m_hash;
      SignalTimeFrames m_timeframes;
      
   public:
      AlphaVisionSignals() { m_hash = new Hash(193, true); }
      AlphaVisionSignals(SignalTimeFrames &tfs) { m_hash = new Hash(193, true); m_timeframes = tfs; }
      void ~AlphaVisionSignals() { delete m_hash; }
      
      SignalTimeFrames getTimeFrames() { return m_timeframes; }
      // TODO: from different passed config structures (HMA, ATR, BB, ...), could get different stuff
      bool initOn(int timeframe, int period1, int period2, int period3) {
         string tfKey = getKey(timeframe);
         if (! m_hash.hContainsKey(tfKey)) {
            m_hash.hPut(tfKey, new AlphaVision(new HMATrend(timeframe, period2, period3),
                                               new HMATrend(timeframe, period1, period2),
                                               new BBTrend(timeframe),
                                               new BBTrend(timeframe, 3.0),
                                               new StochasticTrend(timeframe),
                                               new MACDTrend(timeframe)));
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
