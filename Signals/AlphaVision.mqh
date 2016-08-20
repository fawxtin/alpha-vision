//+------------------------------------------------------------------+
//|                                                  AlphaVision.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Trends\trends.mqh>
#include <Trends\HMA.mqh>
#include <Trends\ATR.mqh>
#include <Trends\BB.mqh>
#include <Trends\Stochastic.mqh>

#ifndef __SIGNALS_ALPHAVISION__
#define __SIGNALS_ALPHAVISION__ 1



class AlphaVision {
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

#endif
