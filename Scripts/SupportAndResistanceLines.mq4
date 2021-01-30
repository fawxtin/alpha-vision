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

input string iPositions = "LONG&SHORT";
input int iSmoothness1 = 12;
input int iSmoothness2 = 30;
input int iSmoothness3 = 120;
input int iSmoothness4 = 300;

void OnStart() {
   int barHighW1 = iHighest(Symbol(), PERIOD_W1, MODE_HIGH, iSmoothness1, 1);
   int barHighW2 = iHighest(Symbol(), PERIOD_W1, MODE_HIGH, iSmoothness2, 1);
   int barHighW3 = iHighest(Symbol(), PERIOD_W1, MODE_HIGH, iSmoothness3, 1);
   int barHighW4 = iHighest(Symbol(), PERIOD_W1, MODE_HIGH, iSmoothness4, 1);
   int barLowW1 = iLowest(Symbol(), PERIOD_W1, MODE_LOW, iSmoothness1, 1);
   int barLowW2 = iLowest(Symbol(), PERIOD_W1, MODE_LOW, iSmoothness2, 1);
   int barLowW3 = iLowest(Symbol(), PERIOD_W1, MODE_LOW, iSmoothness3, 1);
   int barLowW4 = iLowest(Symbol(), PERIOD_W1, MODE_LOW, iSmoothness4, 1);
   double higherPriceW1 = iHigh(Symbol(), PERIOD_W1, barHighW1);
   double higherPriceW2 = iHigh(Symbol(), PERIOD_W1, barHighW2);
   double higherPriceW3 = iHigh(Symbol(), PERIOD_W1, barHighW3);
   double higherPriceW4 = iHigh(Symbol(), PERIOD_W1, barHighW4);

   double lowerPriceW1 = iLow(Symbol(), PERIOD_W1, barLowW1);
   double lowerPriceW2 = iLow(Symbol(), PERIOD_W1, barLowW2);
   double lowerPriceW3 = iLow(Symbol(), PERIOD_W1, barLowW3);
   double lowerPriceW4 = iLow(Symbol(), PERIOD_W1, barLowW4);
   
   Alert(StringFormat("Top Prices: %.4f / %.4f / %.4f / %.4f\nBottom Prices: %.4f / %.4f / %.4f / %.4f", 
      higherPriceW1, higherPriceW2, higherPriceW3, higherPriceW4, 
      lowerPriceW1, lowerPriceW2, lowerPriceW3, lowerPriceW4));
   
   createPriceLine(higherPriceW1, "TOP-W1", clrBlue, "TOP-W1");
   createPriceLine(higherPriceW2, "TOP-W2", clrAntiqueWhite, "TOP-W2");
   createPriceLine(higherPriceW3, "TOP-W3", clrBlueViolet, "TOP-W3");
   createPriceLine(higherPriceW4, "TOP-W4", clrPurple, "TOP-W4");

   createPriceLine(lowerPriceW1, "BOTTOM-W1", clrRed, "BOTTOM-W1");
   createPriceLine(lowerPriceW2, "BOTTOM-W2", clrPink, "BOTTOM-W2");
   createPriceLine(lowerPriceW3, "BOTTOM-W3", clrBrown, "BOTTOM-W3");
   createPriceLine(lowerPriceW4, "BOTTOM-W4", clrAqua, "BOTTOM-W4");
   // if (iPositions == "LONG&SHORT") {
   //    createPriceLine(higherPrice, "TOP", clrBlue, StringFormat("Size: %.2f", pv.size));
   //    createPriceLine(lowerPrice, "BOTTOM", clrRed, StringFormat("Size: %.2f", pv.size));
   // } else if (iPositions == "LONG") {
   //    parsePositions(longPositions, "LongPositions", clrBlue);
   //    if (iTargetPrice > 0 && iTargetPrice > Ask)
   //       changeTargetPrice(longPositions, iTargetPrice);
   // } else if (iPositions == "SHORT") {
   //    parsePositions(shortPositions, "ShortPositions", clrPink);
   //    if (iTargetPrice > 0 && iTargetPrice < Bid)
   //       changeTargetPrice(shortPositions, iTargetPrice);
   // }
}

void createPriceLine(double price, string objName, color objColor, string objText="") {
   ObjectCreate(0, objName, OBJ_HLINE, 0, Time[0], price);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, objColor);
   ObjectSetString(0, objName, OBJPROP_TEXT, objText);
}

