//+------------------------------------------------------------------+
//|                                                  EntryPoints.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <Arrays\Hash.mqh>
#include <Signals\AlphaVision.mqh>

#ifndef __ENTRY_POINTS__
#define __ENTRY_POINTS__ 1

struct EntryExitSpot {
   double spread;
   double target;
   double limit;
   double market;
   double stopLoss;
   double signal;
   string algo;
};

// EntryExitSpot &ee, int timeframe, double signalPrice, string signalOrigin
class EntryPoints : public HashValue {
   protected:
      AlphaVisionSignals *m_signals;
      bool m_enabled;

   public:
      EntryPoints(AlphaVisionSignals *avSignals) {
         m_signals = avSignals;
         setEnabled(true);
      }
      
      bool isEnabled() { return m_enabled; }
      void setEnabled(bool val) { m_enabled = val; }
      
      
      virtual void calculateBuyEntry(EntryExitSpot &ee, int timeframe, string signalOrigin) {}
      virtual void calculateSellEntry(EntryExitSpot &ee, int timeframe, string signalOrigin) {}
};

class EntryPointsBB : public EntryPoints {
   public:
      EntryPointsBB(AlphaVisionSignals *avSignals) : EntryPoints(avSignals) { }
      
      virtual void calculateBuyEntry(EntryExitSpot &ee, int timeframe, string signalOrigin) {
         AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
         BBTrend *bb = av.m_bb;
         BBTrend *bb3 = av.m_bb3;

         ee.limit = bb.m_bbBottom;
         ee.target = bb.m_bbTop;
         ee.stopLoss = bb3.m_bbBottom - ee.spread;
         ee.algo = StringFormat("BB-%s-lmt", signalOrigin);
      }
      
      virtual void calculateSellEntry(EntryExitSpot &ee, int timeframe, string signalOrigin) {
         AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
         BBTrend *bb = av.m_bb;
         BBTrend *bb3 = av.m_bb3;

         ee.limit = bb.m_bbTop;
         ee.target = bb.m_bbBottom;
         ee.stopLoss = bb3.m_bbTop + ee.spread;
         ee.algo = StringFormat("BB-%s-lmt", signalOrigin);
      }
};

class EntryPointsBBSmart : public EntryPoints {
   public:
      EntryPointsBBSmart(AlphaVisionSignals *avSignals) : EntryPoints(avSignals) { }
      
      virtual void calculateBuyEntry(EntryExitSpot &ee, int timeframe, string signalOrigin) {
         AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
         BBTrend *bb = av.m_bb;
         BBTrend *bb4 = av.m_bb4;
   
         string bbType;
         double bbRelativePosition = bb.getRelativePosition();

         if (bbRelativePosition > 1) { // Higher top
            bbType = "ht";
            ee.limit = bb.m_bbMiddle;
            ee.target = bb.m_bbTop;
            ee.stopLoss = bb.m_bbBottom - ee.spread;
         } else if (bbRelativePosition > 0) { // Higher low
            bbType = "hl";
            ee.limit = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
            ee.target = bb.m_bbTop;
            ee.stopLoss = bb.m_bbBottom - ee.spread;   
         } else if (bbRelativePosition > -1) { // Lower top
            bbType = "lt";
            ee.limit = bb.m_bbBottom;
            ee.target = (bb.m_bbMiddle + bb.m_bbTop) / 2;
            ee.stopLoss = bb4.m_bbBottom - ee.spread;      
         } else { // Lower low
            bbType = "ll";
            ee.limit = bb.m_bbBottom;
            ee.target = bb.m_bbMiddle;
            ee.stopLoss = bb4.m_bbBottom - ee.spread;      
         }
         ee.algo = StringFormat("BBSM-%s-%s", signalOrigin, bbType);
      }
      
      virtual void calculateSellEntry(EntryExitSpot &ee, int timeframe, string signalOrigin) {
         AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
         BBTrend *bb = av.m_bb;
         BBTrend *bb4 = av.m_bb4;

         string bbType;
         double bbRelativePosition = bb.getRelativePosition();

         if (bbRelativePosition > 1) { // Higher top
            bbType = "ht";
            ee.limit = bb.m_bbTop;
            ee.target = bb.m_bbMiddle;
            ee.stopLoss = bb4.m_bbTop + ee.spread;      
         } else if (bbRelativePosition > 0) { // Higher low
            bbType = "hl";
            ee.limit = (bb.m_bbMiddle + bb.m_bbTop) / 2;
            ee.target = (bb.m_bbMiddle + bb.m_bbBottom) / 2;
            ee.stopLoss = bb4.m_bbTop + ee.spread;   
         } else if (bbRelativePosition > -1) { // Lower top
            bbType = "lt";
            ee.limit = bb.m_bbMiddle;
            ee.target = bb.m_bbBottom;
            ee.stopLoss = bb.m_bbTop + ee.spread;      
         } else { // Lower low
            bbType = "ll";
            ee.limit = bb.m_bbMiddle;
            ee.target = bb.m_bbBottom;
            ee.stopLoss = bb.m_bbTop + ee.spread;      
         }
         ee.algo = StringFormat("BBSM-%s-%s", signalOrigin, bbType);
      }
};

#endif
