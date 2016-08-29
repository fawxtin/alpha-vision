//+------------------------------------------------------------------+
//|                                                       Trader.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

#include <stdlib.mqh>
#include <Arrays\Hash.mqh>

#include <Positions\Positions.mqh>


#ifndef __POSITIONS_TRADER__
#define __POSITIONS_TRADER__ true

#define EXPIRE_NEVER D'2018.01.01 23:59:59'   // 60 * 60 * 24 * 7

struct MktT {
   int vdigits;
   double vspread;
};

class Trader {
   protected:
      MktT m_mkt;
      Hash *m_longPositions;
      Hash *m_shortPositions;
      Hash *m_barLong;
      Hash *m_barShort;

      bool isCurrentBarTradedP(string longOrShort, int timeframe);
      void setCurrentBarTraded(string longOrShort, int timeframe);
      Positions *getPositions(string longOrShort, int timeframe);
      /// key helper
      string getTimeFrameKey(int timeframe) { return EnumToString((ENUM_TIMEFRAMES) timeframe); }

   public:
      Trader() {
         m_longPositions = new Hash(193, true);
         m_shortPositions = new Hash(193, true);
         m_barLong = new Hash(193, true);
         m_barShort = new Hash(193, true);
         m_mkt.vdigits = (int)MarketInfo(Symbol(), MODE_DIGITS);
         m_mkt.vspread = MarketInfo(Symbol(), MODE_SPREAD) / MathPow(10, m_mkt.vdigits);
      }
      
      void ~Trader() {
         delete m_longPositions;
         delete m_shortPositions;
         delete m_barLong;
         delete m_barShort;
      }
      
      /// positions handlers
      void loadCurrentOrders(int timeframe) {
         Positions *longPs = getPositions("LONG", timeframe);
         Positions *shortPs = getPositions("SHORT", timeframe);

         longPs.loadCurrentOrders(MAGICMA + timeframe);
         shortPs.loadCurrentOrders(MAGICMA + timeframe);
      }
      
      void cleanOrders(int timeframe) {
         Positions *longPs = getPositions("LONG", timeframe);
         if (longPs != NULL) longPs.cleanOrders();
         Positions *shortPs = getPositions("SHORT", timeframe);
         if (shortPs != NULL) shortPs.cleanOrders();
      }
      
      // position helpers
      double riskAndRewardRatio(double entry, double target, double stopLoss);
      double riskAndRewardRatioEntry(double riskAndReward, double target, double stopLoss);
      
      // trader executing orders
      void goLong(int timeframe, double signalPrice, double priceTarget=0, double stopLoss=0, string reason="");
      void goShort(int timeframe, double signalPrice, double priceTarget=0, double stopLoss=0, string reason="");
      void closeLongs(int timeframe, string reason);
      void closeShorts(int timeframe, string reason);
};

Positions *Trader::getPositions(string longOrShort, int timeframe) {
   if (longOrShort == "LONG" || longOrShort == "long") {
      Positions *longPs = m_longPositions.hGet(getTimeFrameKey(timeframe));
      if (longPs == NULL) {
         string tfStr = getTimeFrameKey(timeframe);
         longPs = new Positions("LONG", tfStr, true);
         m_longPositions.hPut(tfStr, longPs);
      }
      return longPs;
   } else {
      Positions *shortPs = m_shortPositions.hGet(getTimeFrameKey(timeframe));
      if (shortPs == NULL) {
         string tfStr = getTimeFrameKey(timeframe);
         shortPs = new Positions("SHORT", tfStr, true);
         m_shortPositions.hPut(tfStr, shortPs);
      }
      return shortPs;
   }
}

//// Entry helpers
double Trader::riskAndRewardRatio(double entry, double target, double stopLoss) {
   return MathAbs(target - entry) / MathAbs(stopLoss - entry);
}

double Trader::riskAndRewardRatioEntry(double riskAndReward, double target, double stopLoss) {
   return (target + stopLoss * riskAndReward) / (riskAndReward + 1);
}

bool Trader::isCurrentBarTradedP(string longOrShort, int timeframe) {
   Hash *bar;
   string tfStr = getTimeFrameKey(timeframe);

   if (longOrShort == "long") bar = m_barLong;
   else bar = m_barShort;

   if ((TimeCurrent() - bar.hGetDatetime(tfStr)) > timeframe) return false;
   else return true;
}

void Trader::setCurrentBarTraded(string longOrShort, int timeframe) {
   Hash *bar;
   string tfStr = getTimeFrameKey(timeframe);

   if (longOrShort == "LONG" || longOrShort == "long") bar = m_barLong;
   else bar = m_barShort;

   bar.hPutDatetime(tfStr, TimeCurrent());
}



//// Executing Orders
/*
 * Orders shall be executed on timeframe and given a reason.
 * 
 */

void Trader::goLong(int timeframe, double signalPrice, double targetPrice=0, double stopLoss=0, string reason="") {
   Positions *longPs = getPositions("LONG", timeframe);
   if (longPs.count() >= MAX_POSITIONS) return; // full

   int ticket;
   double marketPrice = Ask;
   signalPrice = NormalizeDouble(signalPrice, m_mkt.vdigits);
   
   string orderType = "market";
   if (MathAbs(marketPrice - signalPrice) < m_mkt.vspread) { // buy market
      PrintFormat("[Trader.goLong/%s] opening At market (%.4f, %.4f)", reason, signalPrice, marketPrice);
      ticket = OrderSend(Symbol(), OP_BUY, LOT_SIZE, marketPrice, 3, stopLoss, targetPrice, reason, MAGICMA, 0, clrAliceBlue);
   } else if (signalPrice < marketPrice) { // buy limit
      PrintFormat("[Trader.goLong/%s] opening Limit at %.4f", reason, signalPrice);
      ticket = OrderSend(Symbol(), OP_BUYLIMIT, LOT_SIZE, signalPrice, 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
      orderType = "limit";
   } else {// buy stop
      PrintFormat("[Trader.goLong/%s] opening Stop at %.4f", reason, signalPrice);
      ticket = OrderSend(Symbol(), OP_BUYSTOP, LOT_SIZE, signalPrice, 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
      orderType = "stop";
   }
   
   if (ticket == -1) {
      int check = GetLastError();
      Alert(StringFormat("[Trader.goLong] ERROR opening order: %d / %s", check, ErrorDescription(check)));
   } else {
      longPs.add(new Position(ticket, orderType, marketPrice, signalPrice));
      //m_longPositions.setLastBar(Bars);
   } 
}

void Trader::goShort(int timeframe, double signalPrice, double targetPrice=0, double stopLoss=0, string reason="") {
   Positions *shortPs = getPositions("SHORT", timeframe);
   if (shortPs.count() >= MAX_POSITIONS) return; // already traded?
   // short trades
   int ticket;
   double marketPrice = Bid;
   signalPrice = NormalizeDouble(signalPrice, m_mkt.vdigits);
   
   string orderType = "market";
   if (MathAbs(signalPrice - marketPrice) < m_mkt.vspread) { // sell market
      PrintFormat("[Trader.goShort/%s] opening At market (%.4f, %.4f)", reason, signalPrice, marketPrice);
      ticket = OrderSend(Symbol(), OP_SELL, LOT_SIZE, marketPrice, 3, stopLoss, targetPrice, reason, MAGICMA, 0, clrPink);
   } else if (signalPrice > marketPrice) { // sell limit
      PrintFormat("[Trader.goShort/%s] opening Limit at %.4f", reason, signalPrice);
      orderType = "limit";
      ticket = OrderSend(Symbol(), OP_SELLLIMIT, LOT_SIZE, signalPrice, 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrPink);
   } else { // sell stop
      PrintFormat("[Trader.goShort/%s opening Stop at %.4f", reason, signalPrice);
      orderType = "stop";
      ticket = OrderSend(Symbol(), OP_SELLSTOP, LOT_SIZE, signalPrice, 3,
                         stopLoss, targetPrice, reason, MAGICMA, EXPIRE_NEVER, clrAliceBlue);
   }
   
   if (ticket == -1) {
      int check = GetLastError();
      Alert(StringFormat("[Trader.goShort] ERROR opening order: %d / %s", check, ErrorDescription(check)));
   } else {
      shortPs.add(new Position(ticket, orderType, marketPrice, signalPrice));
      //shortPs.setLastBar(Bars);
   }
}

void Trader::closeLongs(int timeframe, string reason="") {
   Positions *longPs = getPositions("LONG", timeframe);
   double closePrice = Bid;
   int oCount = longPs.count();
   PositionValue fullPosition = longPs.meanPositionValue();
   
   if (reason != "") PrintFormat("[Trader.closeLongs] Closing %d longs: %s", oCount, reason);
   if (oCount > 0) 
      PrintFormat("[Trader.closeLongs] Closing %d orders (size %.2f) / (long MP %.4f -> sell at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, closePrice);

   while (longPs.count() > 0) {
      longPs.close(0, closePrice, reason);
   }   
}

void Trader::closeShorts(int timeframe, string reason="") {
   Positions *shortPs = m_shortPositions.hGet(getTimeFrameKey(timeframe));
   if (shortPs == NULL) return;
   
   double closePrice = Ask;
   int oCount = shortPs.count();
   PositionValue fullPosition = shortPs.meanPositionValue();
   
   if (reason != "") PrintFormat("[Trader.closeShorts] Closing %d shorts: %s", oCount, reason);
   if (oCount > 0)
      PrintFormat("[Trader.closeShorts] Closed %d orders (size %.2f) / (sell MP %.4f -> cover at %.4f)",
                  oCount, fullPosition.size, fullPosition.price, closePrice);
   
   while (shortPs.count() > 0) {
      shortPs.close(0, closePrice, reason);
   }
}

#endif
