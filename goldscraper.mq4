//+------------------------------------------------------------------+
//|                                                      XAUUSD_EA.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

extern double BuyStopAmount = 100.0;
extern double SellStopAmount = 50.0;
extern double StopLossHigh = 100.0;
extern double StopLossLow = 50.0;
extern double TakeProfitAmount = 50.0;
extern int OpenHourGMT = 14; // 8:30 AM NY time in GMT
extern int OpenMinuteGMT = 30;
extern int CloseHourGMT = 21; // 4:00 PM NY time in GMT
extern int CloseMinuteGMT = 0;
extern int MagicNumber = 123456; // Unique identifier for the EA's trades
extern double BuyLotSize = 1.0; // Lot size for the buy order
extern double SellLotSize = 1.0; // Lot size for the sell order

bool ordersPlacedToday = false;

int start()
{
    datetime time = TimeCurrent();
    if (TimeHour(time) == OpenHourGMT && TimeMinute(time) == OpenMinuteGMT && !ordersPlacedToday)
    {
        double high = High[1];
        double low = Low[1];
        double buyStopPrice = high + BuyStopAmount * Point;
        double sellStopPrice = low - SellStopAmount * Point;
        double stopLossForBuy = buyStopPrice - StopLossHigh * Point;
        double stopLossForSell = sellStopPrice + StopLossLow * Point;
        double takeProfitForBuy = buyStopPrice + TakeProfitAmount * Point;
        double takeProfitForSell = sellStopPrice - TakeProfitAmount * Point;

        int ticketBuy = OrderSend(Symbol(), OP_BUYSTOP, BuyLotSize, buyStopPrice, 3, stopLossForBuy, takeProfitForBuy, "BuyStop", MagicNumber, 0, Green);
        int ticketSell = OrderSend(Symbol(), OP_SELLSTOP, SellLotSize, sellStopPrice, 3, stopLossForSell, takeProfitForSell, "SellStop", MagicNumber, 0, Red);

        if (ticketBuy < 0 || ticketSell < 0)
        {
            Print("OrderSend failed with error #", GetLastError());
        }
        else
        {
            ordersPlacedToday = true;
        }
    }

    if (TimeHour(time) >= CloseHourGMT && TimeMinute(time) >= CloseMinuteGMT)
    {
        for (int i = OrdersTotal() - 1; i >= 0; i--)
        {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if (OrderSymbol() == Symbol() && (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP) && OrderMagicNumber() == MagicNumber)
                {
                    bool res = OrderDelete(OrderTicket());
                    if (!res)
                    {
                        Print("OrderDelete failed with error #", GetLastError());
                    }
                }
            }
        }
        ordersPlacedToday = false;
    }

    return 0;
}
//+------------------------------------------------------------------+
