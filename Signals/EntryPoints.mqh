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
         setEnabled(false);
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

enum ENUM_PIVOT_CASES {
   BREAKOUT_R3,
   BETWEEN_R2_R3,
   BETWEEN_R1_R2,
   BETWEEN_PP_R1,
   BETWEEN_S1_PP,
   BETWEEN_S2_S1,
   BETWEEN_S3_S2,
   BREAKOUT_S3
};

class EntryPointsPivot : public EntryPoints {
   private:
      int getPivotCase(double relativePosition) {
         if (relativePosition > 3) { // Broke R3
            return BREAKOUT_R3;
         } else if (relativePosition > 2) { // Broke R2
            return BETWEEN_R2_R3;
         } else if (relativePosition > 1) { // Broke R1
            return BETWEEN_R1_R2;
         } else if (relativePosition > 0) { // Above typical
            return BETWEEN_PP_R1;
         } else if (relativePosition > -1) { // Below typical
            return BETWEEN_S1_PP;
         } else if (relativePosition > -2) { // Broke S1
            return BETWEEN_S2_S1;
         } else if (relativePosition > -3) { // Broke S2
            return BETWEEN_S3_S2;
         } else {
            return BREAKOUT_S3;
         }
      }
   
      double searchBottom(int cTimeframe) {
         int nTimeframe = m_signals.getTimeFrameAbove(cTimeframe);
         AlphaVision *avN = m_signals.getAlphaVisionOn(nTimeframe);
         PivotTrend *pivot = avN.m_pivot;
         
         double bottom = 0;
         int pivotCase = getPivotCase(pivot.getRelativePosition());
         switch (pivotCase) {
            case BREAKOUT_R3:
            case BETWEEN_R2_R3:
               bottom = pivot.m_R2;
               break;
            case BETWEEN_R1_R2:
               bottom = pivot.m_R1;
               break;
            case BETWEEN_PP_R1:
            case BETWEEN_S1_PP:
               bottom = pivot.m_S1;
               break;
            case BETWEEN_S2_S1:
               bottom = pivot.m_S2;
               break;
            case BETWEEN_S3_S2:
               bottom = pivot.m_S3;
               break;
            case BREAKOUT_S3:
               if (cTimeframe < PERIOD_MN1)
                  bottom = searchBottom(nTimeframe);
               else { // No bottom! consider getting current price - atr
                  ATRdelta *atr = avN.m_atr;
                  bottom = atr.getStopLossFor("LONG", Bid);
               }
               break;
         }
         
         return bottom;
      }

      double searchTop(int cTimeframe) {
         int nTimeframe = m_signals.getTimeFrameAbove(cTimeframe);
         AlphaVision *avN = m_signals.getAlphaVisionOn(nTimeframe);
         PivotTrend *pivot = avN.m_pivot;
         
         double top = 0;
         int pivotCase = getPivotCase(pivot.getRelativePosition());
         switch (pivotCase) {
            case BREAKOUT_R3:
               if (cTimeframe < PERIOD_MN1)
                  top = searchTop(nTimeframe);
               else { // No top! consider getting current price + atr
                  ATRdelta *atr = avN.m_atr;
                  top = atr.getStopLossFor("SHORT", Ask);
               }
               break;
            case BETWEEN_R2_R3:
               top = pivot.m_R3;
               break;
            case BETWEEN_R1_R2:
               top = pivot.m_R2;
               break;
            case BETWEEN_PP_R1:
            case BETWEEN_S1_PP:
               top = pivot.m_R1;
               break;
            case BETWEEN_S2_S1:
               top = pivot.m_S1;
               break;
            case BETWEEN_S3_S2:
               top = pivot.m_S2;
               break;
            case BREAKOUT_S3:
               top = pivot.m_S3;
               break;
         }
         
         return top;
      }

   public:
      EntryPointsPivot(AlphaVisionSignals *avSignals) : EntryPoints(avSignals) { }
      
      virtual void calculateBuyEntry(EntryExitSpot &ee, int timeframe, string signalOrigin) {
         //AlphaVision *av = m_signals.getAlphaVisionOn(timeframe);
         int mjTimeframe = m_signals.getTimeFrameAbove(timeframe);
         AlphaVision *avMj = m_signals.getAlphaVisionOn(mjTimeframe);
         PivotTrend *pivot = avMj.m_pivot;
         ATRdelta *atr = avMj.m_atr;
   
         string pivotPosition;
         int pivotCase = getPivotCase(pivot.getRelativePosition());
         switch (pivotCase) {
            case BREAKOUT_R3:
            case BETWEEN_R2_R3:
               pivotPosition = "r2-bk";
               ee.limit = pivot.m_R2;
               ee.target = atr.getTargetProfitFor("LONG", Ask);
               ee.stopLoss = pivot.m_typical - ee.spread;
               break;
            case BETWEEN_R1_R2:
               pivotPosition = "r1-r2";
               ee.limit = pivot.m_R1;
               ee.target = pivot.m_R3;
               ee.stopLoss = pivot.m_S1 - ee.spread;   
               break;
            case BETWEEN_PP_R1:
               pivotPosition = "pp-r1";
               ee.limit = pivot.m_typical;
               ee.target = pivot.m_R2;
               ee.stopLoss = pivot.m_S2 - ee.spread;   
               break;
            case BETWEEN_S1_PP:
               pivotPosition = "s1-pp";
               ee.limit = pivot.m_S1;
               ee.target = pivot.m_R1;
               ee.stopLoss = pivot.m_S3 - ee.spread;      
               break;
            case BETWEEN_S2_S1:
               pivotPosition = "s1-s2";
               ee.limit = pivot.m_S2;
               ee.target = pivot.m_R1;
               ee.stopLoss = pivot.m_S3 - ee.spread;  
               break;
            case BETWEEN_S3_S2:
               pivotPosition = "s2-s3";
               ee.limit = pivot.m_S3;
               ee.target = pivot.m_S1;
               ee.stopLoss = searchBottom(mjTimeframe) - ee.spread;   
               break;
            case BREAKOUT_S3:
               pivotPosition = "s3-bk";
               ee.limit = Ask;
               ee.target = pivot.m_S2;
               ee.stopLoss = searchBottom(mjTimeframe) - ee.spread;
               break;
         }
         ee.algo = StringFormat("PVT-%s-%s", signalOrigin, pivotPosition);
      }
      
      virtual void calculateSellEntry(EntryExitSpot &ee, int timeframe, string signalOrigin) {
         int mjTimeframe = m_signals.getTimeFrameAbove(timeframe);
         AlphaVision *avMj = m_signals.getAlphaVisionOn(mjTimeframe);
         PivotTrend *pivot = avMj.m_pivot;
         ATRdelta *atr = avMj.m_atr;
   
         string pivotPosition;
         int pivotCase = getPivotCase(pivot.getRelativePosition());
         switch (pivotCase) {
            case BREAKOUT_R3:
               pivotPosition = "r3-bk";
               ee.limit = Bid;
               ee.target = pivot.m_R1;
               ee.stopLoss = searchTop(mjTimeframe) + ee.spread;
               break;
            case BETWEEN_R2_R3:
               pivotPosition = "r2-r3";
               ee.limit = pivot.m_R3;
               ee.target = pivot.m_R1;
               ee.stopLoss = searchTop(mjTimeframe) + ee.spread;
               break;
            case BETWEEN_R1_R2:
               pivotPosition = "r1-r2";
               ee.limit = pivot.m_R2;
               ee.target = pivot.m_typical;
               ee.stopLoss = pivot.m_R3 + ee.spread;   
               break;
            case BETWEEN_PP_R1:
               pivotPosition = "pp-r1";
               ee.limit = pivot.m_R1;
               ee.target = pivot.m_S1;
               ee.stopLoss = pivot.m_R3 + ee.spread;   
               break;
            case BETWEEN_S1_PP:
               pivotPosition = "s1-pp";
               ee.limit = pivot.m_typical;
               ee.target = pivot.m_S2;
               ee.stopLoss = pivot.m_R2 + ee.spread;      
               break;
            case BETWEEN_S2_S1:
               pivotPosition = "s1-s2";
               ee.limit = pivot.m_S1;
               ee.target = pivot.m_S3;
               ee.stopLoss = pivot.m_R1 + ee.spread;  
               break;
            case BETWEEN_S3_S2:
            case BREAKOUT_S3:
               pivotPosition = "s2-bk";
               ee.limit = pivot.m_S2;
               ee.target = atr.getTargetProfitFor("SHORT", Bid);
               ee.stopLoss = pivot.m_typical + ee.spread;   
               break;
         }
         ee.algo = StringFormat("PVT-%s-%s", signalOrigin, pivotPosition);
      }
};

#endif
