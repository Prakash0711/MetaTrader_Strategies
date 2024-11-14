//+------------------------------------------------------------------+
//|                                             HeikenAshiSwitch.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

//--- Define variables
double lotSize = 0.1;
double stop_loss_pips = 10 * lotSize;
double take_profit_pips = 10 * lotSize;
int haHandle;
#include <Trade\Trade.mqh>
CTrade Trade;

string mySymbol;
ENUM_TIMEFRAMES myTimeframe;

datetime lastCandleTime = 0;
datetime lastTradeTime = 0;

//+------------------------------------------------------------------+
//| Initialization function                                          |
//+------------------------------------------------------------------+
int OnInit()
{
   mySymbol = Symbol();
   myTimeframe = PERIOD_CURRENT;
   haHandle = iCustom(mySymbol, PERIOD_CURRENT, "Examples\\Heiken_Ashi");
   
   if (haHandle == INVALID_HANDLE)
   {
      Print("Error loading HA indicator");
      return INIT_FAILED;
   }
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Check for candle direction switch (Bullish/Bearish)              |
//+------------------------------------------------------------------+
int HaSwitchDirection(double haOpenPrevious, double haClosePrevious, double haOpenBeforeLast, double haCloseBeforeLast)
{
   bool isBullishPrevious = haClosePrevious > haOpenPrevious;
   bool isBearishPrevious = haClosePrevious < haOpenPrevious;
   bool wasBullishBeforeLast = haCloseBeforeLast > haOpenBeforeLast;
   bool wasBearishBeforeLast = haCloseBeforeLast < haOpenBeforeLast;

   // Print for debugging
   Print("isBullishPrevious: ", isBullishPrevious, ", isBearishPrevious: ", isBearishPrevious);
   Print("wasBullishBeforeLast: ", wasBullishBeforeLast, ", wasBearishBeforeLast: ", wasBearishBeforeLast);

   if (isBullishPrevious && wasBearishBeforeLast)
   {
      Print("Signal to buy");
      return 1; // Buy
   }
   if (isBearishPrevious && wasBullishBeforeLast)
   {
      Print("Signal to sell");
      return 0; // Sell
   }

   Print("No Signal - Return -1");
   return -1; // Equal closes, no trade signal
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if (haHandle != INVALID_HANDLE)
   {
      IndicatorRelease(haHandle);
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentCandleTime = iTime(mySymbol, PERIOD_CURRENT, 1);  // Time of the previous closed candle
   datetime candleCloseTime = iTime(mySymbol, PERIOD_CURRENT, 0);     // Time of the current candle close

   // Ensure the trade is executed only after the candle has closed
   if (currentCandleTime != lastCandleTime && TimeCurrent() >= candleCloseTime)
   {
      lastCandleTime = currentCandleTime;
      
      // Retrieve Heiken Ashi data for previous 2 candles
      #define BAR_COUNT   3
      #define HA_OPEN     0
      #define HA_HIGH     1
      #define HA_LOW      2
      #define HA_CLOSE    3
      #define HA_COLOUR   4

      double haOpen[BAR_COUNT], haHigh[BAR_COUNT], haLow[BAR_COUNT], haClose[BAR_COUNT], haColour[BAR_COUNT];

      if (CopyBuffer(haHandle, HA_OPEN, 0, BAR_COUNT, haOpen) != BAR_COUNT
         || CopyBuffer(haHandle, HA_HIGH, 0, BAR_COUNT, haHigh) != BAR_COUNT
         || CopyBuffer(haHandle, HA_LOW, 0, BAR_COUNT, haLow) != BAR_COUNT
         || CopyBuffer(haHandle, HA_CLOSE, 0, BAR_COUNT, haClose) != BAR_COUNT
         || CopyBuffer(haHandle, HA_COLOUR, 0, BAR_COUNT, haColour) != BAR_COUNT)
      {
         Print("CopyBuffer from Heiken_Ashi failed, no data");
         return;
      }
      Print("HA_Colour[0] =" + DoubleToString(haColour[0]) + " HA_Colour[1] =" + DoubleToString(haColour[1]) + "HA_Colour[2] =" + DoubleToString(haColour[2]));
      
      // Check if the color changed between the last two candles
      if ((haColour[0] != haColour[1]))  // Color change detected
      {  
         Print("HA Switch");
         Print("HA_Colour[0] =" + DoubleToString(haColour[0]) + " HA_Colour[1] =" + DoubleToString(haColour[1]) + "HA_Colour[2] =" + DoubleToString(haColour[2]));
         if (haColour[1] == 0.0)  // Previous candle was bullish
         {
            double ask_price = SymbolInfoDouble(mySymbol, SYMBOL_ASK);
            double stop_loss = ask_price - stop_loss_pips;
            double take_profit = ask_price + take_profit_pips;
            Print("Opening Buy Position");
            Trade.Buy(lotSize, mySymbol, ask_price, stop_loss, take_profit);
            Print("Buy Placed HA_Colour[0] =" + DoubleToString(haColour[0]) + " HA_Colour[1] =" + DoubleToString(haColour[1]) + "HA_Colour[2] =" + DoubleToString(haColour[2]));
         }
         else if (haColour[1] == 1.0)  // Previous candle was bearish
         {
            double bid_price = SymbolInfoDouble(mySymbol, SYMBOL_BID);
            double stop_loss = bid_price + stop_loss_pips;
            double take_profit = bid_price - take_profit_pips;
            Print("Opening Sell Position");
            Trade.Sell(lotSize, mySymbol, bid_price, stop_loss, take_profit);
            Print("Sell Placed HA_Colour[0] =" + DoubleToString(haColour[0]) + " HA_Colour[1] =" + DoubleToString(haColour[1]) + "HA_Colour[2] =" + DoubleToString(haColour[2]));
         }
      }
   }
}
