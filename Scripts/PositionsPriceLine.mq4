//+------------------------------------------------------------------+
//|                                     TestDrawMeanPositionLine.mq4 |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs

#include <Positions\Positions.mqh>

input string iPositions = "LONG&SHORT";
input double iTargetPrice = 0;
input double iFilterEntriesHigherThan = 0;
input double iFilterEntriesLowerThan = 0;
//input double iShortMaxPrice = 0;

void OnStart() {
   Positions *longPositions = new Positions("LONG", EnumToString((ENUM_TIMEFRAMES) Period()));
   Positions *shortPositions = new Positions("SHORT", EnumToString((ENUM_TIMEFRAMES) Period()));
   
   if (iPositions == "LONG&SHORT") {
      parsePositions(longPositions, "LongPositions", clrBlue);
      parsePositions(shortPositions, "ShortPositions", clrPink);
   } else if (iPositions == "LONG") {
      parsePositions(longPositions, "LongPositions", clrBlue);
      if (iTargetPrice > 0 && iTargetPrice > Ask)
         changeTargetPrice(longPositions, iTargetPrice);
   } else if (iPositions == "SHORT") {
      parsePositions(shortPositions, "ShortPositions", clrPink);
      if (iTargetPrice > 0 && iTargetPrice < Bid)
         changeTargetPrice(shortPositions, iTargetPrice);
   }
   
   delete longPositions;
   delete shortPositions;
}

void parsePositions(Positions *positions, string objName, color objColor) {
   int count = positions.loadCurrentOrders(-1);
   PrintFormat("--- loading %d %s positions", count, positions.positionType());
   if (positions.count() > 0) {
      PositionValue pv = positions.meanPositionValue(true);
      createPriceLine(pv.price, objName, objColor, StringFormat("Size: %.2f", pv.size));
   }
}

void createPriceLine(double price, string objName, color objColor, string objText="") {
   ObjectCreate(0, objName, OBJ_HLINE, 0, Time[0], price);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, objColor);
   ObjectSetString(0, objName, OBJPROP_TEXT, objText);
}

void changeTargetPrice(Positions *positions, double targetPrice) {
   if (positions.count() > 0) {
      createPriceLine(targetPrice, "TargetPrice", clrWhite);
      Alert(StringFormat("Modifying %s positions target point to %.4f", positions.positionType(), targetPrice));
      int ordersModified = 0;
      int ordersFailedTo = 0;
      for (int i = 0; i < positions.count(); i++) {
         Position *position = positions[i];
         if (iFilterEntriesHigherThan > 0 && position.m_price < iFilterEntriesHigherThan) { ordersFailedTo++; break; }
         if (iFilterEntriesLowerThan > 0 && position.m_price > iFilterEntriesLowerThan) { ordersFailedTo++; break; }
         if (OrderSelect(position.m_ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            if (OrderModify(position.m_ticket, position.m_price, 0, targetPrice, 0, clrWhite))
               ordersModified++;
            else {
               PrintFormat("Order %d not modified. (errorCode: %d)", position.m_ticket, GetLastError());
               ordersFailedTo++;
            }
         } else {
            PrintFormat("Order %d not even selected. (errorCode: %d)", position.m_ticket, GetLastError());
            ordersFailedTo++;
         }
      }
      Alert(StringFormat("Succes on changing %d positions, and failed on %d positions.", ordersModified, ordersFailedTo));
   } else
      Alert(StringFormat("%s positions not found", positions.positionType()));
}
