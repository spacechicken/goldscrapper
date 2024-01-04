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
extern double BuyTakeProfitAmount = 50.0;
extern double SellTakeProfitAmount = 50.0;
extern int OpenHourGMT = 14; // 8:30 AM NY time in GMT
extern int OpenMinuteGMT = 30;
extern int CloseHourGMT = 21; // 4:00 PM NY time in GMT
extern int CloseMinuteGMT = 0;
extern int MagicNumber = 123456; // Unique identifier for the EA's trades
extern double BuyLotSize = 1.0; // Lot size for the buy order
extern double SellLotSize = 1.0; // Lot size for the sell order

input string TRAILING_ANDD_TP_SETTINGS   = ".";
input bool   useFunction   = false;    //Use Trail Function        
input double tpPercent     = 75;       //SL Percent of TP
input double PipsToTrail   = 5;       //Pips to Trail
input double tpTrail       = 25;      //TP Trail

string   sep = "-";;
ushort   u_sep;
string   saveName[];
double   pipsRemainSell, pipsRemainBuy;


bool ordersPlacedToday = false;
int OnInit()
  {
   DeleteLines();
   pipsRemainSell = SellTakeProfitAmount * (100-tpPercent) * 0.01;
   pipsRemainBuy  = BuyTakeProfitAmount  * (100-tpPercent) * 0.01;
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
 {
   DeleteLines();
 }

int start()
{
    Trailing1();
    Trailing2();
    CheckLines();
    
    datetime time = TimeCurrent();
    if (TimeHour(time) == OpenHourGMT && TimeMinute(time) == OpenMinuteGMT && !ordersPlacedToday)
    {
        double high = High[1];
        double low = Low[1];
        double buyStopPrice = high + BuyStopAmount * Point;
        double sellStopPrice = low - SellStopAmount * Point;
        double stopLossForBuy = buyStopPrice - StopLossHigh * Point;
        double stopLossForSell = sellStopPrice + StopLossLow * Point;
        double takeProfitForBuy = buyStopPrice + BuyTakeProfitAmount * Point;
        double takeProfitForSell = sellStopPrice - SellTakeProfitAmount * Point;
        
        if(useFunction)
          {
             takeProfitForBuy  = 0;
             takeProfitForSell = 0;
          }

        int ticketBuy = OrderSend(Symbol(), OP_BUYSTOP, BuyLotSize, buyStopPrice, 3, stopLossForBuy, takeProfitForBuy, "BuyStop", MagicNumber, 0, Green);
        int ticketSell = OrderSend(Symbol(), OP_SELLSTOP, SellLotSize, sellStopPrice, 3, stopLossForSell, takeProfitForSell, "SellStop", MagicNumber, 0, Red);
        
        if(useFunction)
          {
             takeProfitForBuy = buyStopPrice + BuyTakeProfitAmount * Point;
             takeProfitForSell = sellStopPrice - SellTakeProfitAmount * Point;
             DrawLines(IntegerToString(ticketBuy)+"-Trail_ BUY TP", takeProfitForBuy, clrRed, STYLE_DASH);
             DrawLines(IntegerToString(ticketSell)+"-Trail_ SELL TP", takeProfitForSell, clrRed, STYLE_DASH);
          }
        
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
                    DeleteLines();
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
//| Create the horizontal line                                       |
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
  {
//--- if the price is not set, set it at the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- create a horizontal line
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Delete a horizontal line                                         |
//+------------------------------------------------------------------+
bool HLineDelete(const long   chart_ID=0,   // chart's ID
                 const string name="HLine") // line name
  {
//--- reset the error value
   ResetLastError();
//--- delete a horizontal line
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLines(string name, double price, color colour, ENUM_LINE_STYLE style)
  {
   if(ObjectFind(0, name)>=0)
      HLineDelete(0, name);
   HLineCreate(0, name, 0, price, colour, style, 1, false, false, false, 0);
  }
//+------------------------------------------------------------------+
//| Move horizontal line                                             |
//+------------------------------------------------------------------+
bool HLineMove(const long   chart_ID=0,   // chart's ID
       const string name="HLine", // line name
       double       price=0)      // line price
  {
//--- if the line price is not set, move it to the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move a horizontal line
   if(!ObjectMove(chart_ID,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MoveLines(double price)
{
   for(int i=ObjectsTotal()-1;i>=0;i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, "SCANNER-HL")>=0)
        {
         HLineMove(0, name, price);
        }
     }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trailing1()
{
   for(int k=OrdersTotal()-1;k>=0;k--)
     {
       if (OrderSelect(k, SELECT_BY_POS, MODE_TRADES))
       if (OrderMagicNumber()!= MagicNumber || OrderSymbol()!=Symbol()) continue;
       for(int i=ObjectsTotal()-1;i>=0;i--)
        {
         string name  = ObjectName(0, i);
         double price = ObjectGetDouble(0, name, OBJPROP_PRICE);
         
         if(StringFind(name, "Trail_")>=0)
           {
            if(name==IntegerToString(OrderTicket())+"-Trail_ BUY TP" && Bid>=price && OrderStopLoss()<OrderOpenPrice())
              {
                double newSL = OrderOpenPrice() + (price-OrderOpenPrice())*tpPercent*0.01;
                double newTP = price + (tpTrail*Point);
                int res = OrderModify(OrderTicket(), OrderClosePrice(), newSL, 0, 0);;
                HLineMove(0, IntegerToString(OrderTicket())+"-Trail_ BUY TP", newTP);
              }
            else if (name==IntegerToString(OrderTicket())+"-Trail_ SELL TP" && Ask<=price && OrderStopLoss()>OrderOpenPrice())
              {
                newSL = OrderOpenPrice() - (OrderOpenPrice()-price)*tpPercent*0.01;
                newTP = price - (tpTrail*Point);
                res = OrderModify(OrderTicket(), OrderClosePrice(), newSL, 0, 0);;
                HLineMove(0, IntegerToString(OrderTicket())+"-Trail_ SELL TP", newTP);
              }
           }
        }
     }
   
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteLines()
  {
   string name;
   for(int i = ObjectsTotal(); i >= 0; i--)
     {
      name = ObjectName(ChartID(), i);
      if(StringFind(name, "Trail_") >= 0)
        {
         ObjectDelete(0, name);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckLines()
  {
   string name;
   bool b=false;
   for(int i = ObjectsTotal(); i >= 0; i--)
     {
      name = ObjectName(ChartID(), i);
      if(StringFind(name, "Trail_") >= 0)
        {
         u_sep = StringGetCharacter(sep, 0);
         int n = StringSplit(name, u_sep, saveName);
         if(n>1)
           {
            for(int k=OrdersTotal()-1;k>=0;k--)
              {
                if (OrderSelect(k, SELECT_BY_POS, MODE_TRADES))
                if (OrderMagicNumber()!=MagicNumber || OrderSymbol()!=Symbol()) continue;
                if (StringToInteger(saveName[0])==OrderTicket())  {b=true; break;}
              }
             if (!b)  HLineDelete(0, name);
             b=false;
           } 
        }
      }
  }
//+------------------------------------------------------------------+
//|                       //TRAILING STOP FUNCTION                   |
//+------------------------------------------------------------------+
void Trailing2()
  {
      for (int i = OrdersTotal()-1; i>=0; i--)
         {
          if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
                 {
                  if (OrderMagicNumber()!=MagicNumber || OrderSymbol()!=Symbol()) continue;
                  if(useFunction)
                    {
                     if(OrderType() == 0)
                       {
                        if(OrderStopLoss()>OrderOpenPrice())
                          {
                           if(Bid >= OrderStopLoss()+(pipsRemainBuy+PipsToTrail)*Point)
                             {
                              if(!OrderModify(OrderTicket(), OrderOpenPrice()
                                              , NormalizeDouble(Bid-PipsToTrail*Point, Digits), OrderTakeProfit(), OrderExpiration()))
                                {
                                 Print("Trailing buy err ", GetLastError());
                                }
                              else
                                {
                                 double price = ObjectGetDouble(0, IntegerToString(OrderTicket())+"-Trail_ BUY TP", OBJPROP_PRICE);
                                 HLineMove(0, IntegerToString(OrderTicket())+"-Trail_ BUY TP", price+(PipsToTrail*Point));
                                }
                             }
                          }
                       }
                     if(OrderType()== 1)
                       {
                        if(OrderStopLoss()>OrderOpenPrice())
                          {
                           if(Ask <= OrderStopLoss()-(pipsRemainBuy+PipsToTrail)*Point)
                             {
                              if(!OrderModify(OrderTicket(), OrderOpenPrice()
                                              , NormalizeDouble(Ask+PipsToTrail*Point, Digits), OrderTakeProfit(), OrderExpiration()))
                                {
                                 Print("Trailing sell err ", GetLastError());
                                }
                              else
                                {
                                 price = ObjectGetDouble(0, IntegerToString(OrderTicket())+"-Trail_ SELL TP", OBJPROP_PRICE);
                                 HLineMove(0, IntegerToString(OrderTicket())+"-Trail_ SELL TP", price-(PipsToTrail*Point));
                                }
                             }
                          }
                       }
                     }
                 }
       }
  }   