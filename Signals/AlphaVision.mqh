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

#ifndef __SIGNALS_ALPHAVISION__
#define __SIGNALS_ALPHAVISION__ 1



class AlphaVision : public HashValue {
   public:
      HMATrend *m_hmaMinor;
      HMATrend *m_hmaMajor;
   
      AlphaVision(HMATrend *major, HMATrend *minor) {
         m_hmaMajor = major;
         m_hmaMinor = minor;
      }
      void ~AlphaVision() {
         delete m_hmaMinor;
         delete m_hmaMajor;
      }
      
      void calculate() {
         m_hmaMajor.calculate();
         m_hmaMinor.calculate();
      }
};

class AlphaVisionSignals {
   protected:
      string getKey(int timeframe) { return EnumToString((ENUM_TIMEFRAMES) timeframe); }
      Hash *m_hash;
      
   public:
      AlphaVisionSignals() { m_hash = new Hash(193, true); }
      void ~AlphaVisionSignals() { delete m_hash; }
      
      // TODO: from different passed config structures (HMA, ATR, BB, ...), could get different stuff
      bool initOn(int timeframe, int period1, int period2, int period3) {
         string tfKey = getKey(timeframe);
         if (! m_hash.hContainsKey(tfKey)) {
            m_hash.hPut(tfKey, new AlphaVision(new HMATrend(timeframe, iPeriod2, iPeriod3),
                                               new HMATrend(timeframe, iPeriod1, iPeriod2)));
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
