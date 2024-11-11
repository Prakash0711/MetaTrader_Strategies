//+------------------------------------------------------------------+
//|                                                  SimpleMovingAverage.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

int iMA_handle;
double iMA_buf[];
double Close_buf[];

string my_symbol;
ENUM_TIMEFRAMES my_timeframe;

CTrade m_Trade;
CPositionInfo m_Position;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   my_symbol=Symbol();
   my_timeframe=PERIOD_CURRENT;
   iMA_handle=iMA(my_symbol,my_timeframe,40,0,MODE_SMA,PRICE_CLOSE);
   if(iMA_handle==INVALID_HANDLE)
         {
            Print("Failed to get the indicator handle");
            return(-1);
         }
         ChartIndicatorAdd(ChartID(),0,iMA_handle);
   ArraySetAsSeries(iMA_buf,true);
   ArraySetAsSeries(Close_buf,true);
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(iMA_handle);
   ArrayFree(iMA_buf);
   ArrayFree(Close_buf);

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int err1=0;
   int err2=0;

   err1=CopyBuffer(iMA_handle,0,1,2,iMA_buf);
   err2=CopyClose(my_symbol,my_timeframe,1,2,Close_buf);

   if(err1<0 || err2<0)
     {
      Print("Failed to copy data from the indicator buffer or price chart buffer");
      return;
     }

   if(iMA_buf[1]>Close_buf[1] && iMA_buf[0]<Close_buf[0])
   {
      if(m_Position.Select(my_symbol))
        {
         if(m_Position.PositionType()==POSITION_TYPE_SELL) m_Trade.PositionClose(my_symbol);    
         if(m_Position.PositionType()==POSITION_TYPE_BUY) return;
        }
   m_Trade.Buy(0.1,my_symbol);  
   }
   
   if(iMA_buf[1]<Close_buf[1] && iMA_buf[0]>Close_buf[0]) 
     {
      if(m_Position.Select(my_symbol))                    
        {
         if(m_Position.PositionType()==POSITION_TYPE_BUY) m_Trade.PositionClose(my_symbol);   
         if(m_Position.PositionType()==POSITION_TYPE_SELL) return;                             
        }
      m_Trade.Sell(0.1,my_symbol);                        
     }
  }
//+------------------------------------------------------------------+
