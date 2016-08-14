//+------------------------------------------------------------------+
//|                                            TestLoadPositions.mq4 |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Positions\Positions.mqh>

void OnStart() {
   Positions *longPos = new Positions("LONG");
   Positions *shortPos = new Positions("SHORT");
   Print("--- loading Long positions");
   longPos.loadCurrentOrders(true);
   longPos.meanPositionValue(true);
   Print("--- loading Short positions");
   shortPos.loadCurrentOrders(true);
   shortPos.meanPositionValue(true);
   
   delete shortPos;
   delete longPos;
}
