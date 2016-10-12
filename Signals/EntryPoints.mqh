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

class EntryPointsPivot : public EntryPoints {
   public:
      EntryPointsPivot(AlphaVisionSignals *avSignals) : EntryPoints(avSignals) { }
      
      virtual void calculateBuyEntry(EntryExitSpot &ee, int timeframe, string signalOrigin) {
         //AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
         int mjTimeframe = m_signals.getTimeFrameAbove(timeframe);
         AlphaVision *avMj = m_signals.getAlphaVisionOn(mjTimeframe);
         PivotTrend *pivot = avMj.m_pivot;
   
         string pivotPosition;
         double pivotRelativePosition = pivot.getRelativePosition();

         if (pivotRelativePosition > 2) { // Broke R2
            pivotPosition = "r2-bk";
            ee.limit = pivot.m_R2;
            // TODO: maybe add more to target
            ee.target = pivot.m_R3;
            ee.stopLoss = pivot.m_typical - ee.spread;
         } else if (pivotRelativePosition > 1) { // Broke R1
            pivotPosition = "r1-r2";
            ee.limit = pivot.m_R1;
            ee.target = pivot.m_R3;
            ee.stopLoss = pivot.m_S1 - ee.spread;   
         } else if (pivotRelativePosition > 0) { // Above typical
            pivotPosition = "pp-r1";
            ee.limit = pivot.m_typical;
            ee.target = pivot.m_R2;
            ee.stopLoss = pivot.m_S2 - ee.spread;   
         } else if (pivotRelativePosition > -1) { // Below typical
            pivotPosition = "s1-pp";
            ee.limit = pivot.m_S1;
            ee.target = pivot.m_R1;
            ee.stopLoss = pivot.m_S3 - ee.spread;      
         } else if (pivotRelativePosition > -2) { // Broke S1
            pivotPosition = "s1-s2";
            ee.limit = pivot.m_S2;
            ee.target = pivot.m_R1;
            ee.stopLoss = pivot.m_S3 - ee.spread;  
         } else { // Broke S2
            pivotPosition = "s2-bk";
            ee.limit = pivot.m_S3;
            ee.target = pivot.m_S1;
            double range1 = pivot.m_typical - pivot.m_S1;
            ee.stopLoss = pivot.m_S3 - range1 - ee.spread;   
         }
         ee.algo = StringFormat("PVT-%s-%s", signalOrigin, pivotPosition);
      }
      
      virtual void calculateSellEntry(EntryExitSpot &ee, int timeframe, string signalOrigin) {
         int mjTimeframe = m_signals.getTimeFrameAbove(timeframe);
         AlphaVision *avMj = m_signals.getAlphaVisionOn(mjTimeframe);
         PivotTrend *pivot = avMj.m_pivot;
   
         string pivotPosition;
         double pivotRelativePosition = pivot.getRelativePosition();

         if (pivotRelativePosition > 2) { // Broke R2
            pivotPosition = "r2-bk";
            ee.limit = pivot.m_R3;
            ee.target = pivot.m_R1;
            double range1 = pivot.m_R1 - pivot.m_typical;
            ee.stopLoss = pivot.m_R3 + range1 + ee.spread;
         } else if (pivotRelativePosition > 1) { // Broke R1
            pivotPosition = "r1-r2";
            ee.limit = pivot.m_R2;
            ee.target = pivot.m_typical;
            ee.stopLoss = pivot.m_R3 + ee.spread;   
         } else if (pivotRelativePosition > 0) { // Above typical
            pivotPosition = "pp-r1";
            ee.limit = pivot.m_R1;
            ee.target = pivot.m_S1;
            ee.stopLoss = pivot.m_R3 + ee.spread;   
         } else if (pivotRelativePosition > -1) { // Below typical
            pivotPosition = "s1-pp";
            ee.limit = pivot.m_typical;
            ee.target = pivot.m_S2;
            ee.stopLoss = pivot.m_R2 + ee.spread;      
         } else if (pivotRelativePosition > -2) { // Broke S1
            pivotPosition = "s1-s2";
            ee.limit = pivot.m_S1;
            ee.target = pivot.m_S3;
            ee.stopLoss = pivot.m_R1 + ee.spread;  
         } else { // Broke S2
            pivotPosition = "s2-bk";
            ee.limit = pivot.m_S2;
            // TODO: maybe add more to target
            ee.target = pivot.m_S3;
            ee.stopLoss = pivot.m_R1 + ee.spread;   
         }
         ee.algo = StringFormat("PVT-%s-%s", signalOrigin, pivotPosition);
      }
};

#endif
