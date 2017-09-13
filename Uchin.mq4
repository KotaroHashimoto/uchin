//+------------------------------------------------------------------+
//|                                                        Uchin.mq4 |
//|                           Copyright 2017, Palawan Software, Ltd. |
//|                             https://coconala.com/services/204383 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Palawan Software, Ltd."
#property link      "https://coconala.com/services/204383"
#property description "Author: Kotaro Hashimoto <hasimoto.kotaro@gmail.com>"
#property version   "1.00"
#property strict

input int Magic_Number = 1;
input double Entry_Lot = 0.1;
extern double SL_pips = 30;
extern double TP_pips = 30;
extern double Trail_pips = 30;

input int Entry_Time_H = 6;
input int Exit_Time_H = 18;

input bool Monday_Entry = False;
input bool Tuesday_Entry = True;
input bool Wednesday_Entry = True;
input bool Thursday_Entry = True;
input bool Friday_Entry = True;

bool entryDays[] = {False, True, True, True, True, True, False};


string thisSymbol;

double minSL;

bool orderSent;


int whichDirection() {

  double open = iOpen(thisSymbol, PERIOD_D1, 1);
  double close = iClose(thisSymbol, PERIOD_D1, 1);

  return (open < close) ? OP_BUY : OP_SELL;
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

  thisSymbol = Symbol();
  
  minSL = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
  
  SL_pips *= 10.0 * Point;
  TP_pips *= 10.0 * Point;  
  Trail_pips *= 10.0 * Point;

  orderSent = False;

  entryDays[1] = Monday_Entry;
  entryDays[2] = Tuesday_Entry;
  entryDays[3] = Wednesday_Entry;
  entryDays[4] = Thursday_Entry;
  entryDays[5] = Friday_Entry;  

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }


void trail() {
  
  for(int i = 0; i < OrdersTotal() && 0 < Trail_pips; i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        
        if(OrderType() == OP_BUY) {
          if(OrderOpenPrice() + TP_pips < Bid && OrderStopLoss() + Trail_pips < Bid) {
            bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Bid - Trail_pips, Digits), 0, 0);
          }
        }
          
        else if(OrderType() == OP_SELL) {
          if(Ask < OrderOpenPrice() - TP_pips && Ask < OrderStopLoss() - Trail_pips) {
            bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Ask + Trail_pips, Digits), 0, 0);
          }
        }
      }
    }
  }
}

void closeAll() {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderMagicNumber() == Magic_Number && thisSymbol == Symbol()) {
      
        if(OrderType() == OP_BUY) {
          if(OrderClose(OrderTicket(), OrderLots(), Bid, 3)) {
            i = -1;
          }
        }
        else if(OrderType() == OP_SELL) {
          if(OrderClose(OrderTicket(), OrderLots(), Ask, 3)) {
            i = -1;
          }
        }
        else if(OrderType() == OP_SELLSTOP || OrderType() == OP_BUYSTOP) {
          if(OrderDelete(OrderTicket())) {
            i = -1;
          }
        }
      }
    }
  }
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  datetime dt = TimeLocal();
  int h = TimeHour(dt);

  if(h == Exit_Time_H) {
    closeAll();
    return;
  }

  if(orderSent) {
    if(h != Entry_Time_H) {
      orderSent = False;
    }
  }
  else if(entryDays[TimeDayOfWeek(dt)]) {
    if(h == Entry_Time_H) {

      int op = whichDirection();
      int ticket = -1;

      if(op == OP_BUY) {
        ticket = OrderSend(thisSymbol, OP_BUY, Entry_Lot, NormalizeDouble(Ask, Digits), 3, 
                           NormalizeDouble(Ask - SL_pips, Digits),
	                        (0 < Trail_pips ? 0 : NormalizeDouble(Ask + TP_pips, Digits)),
		                     NULL, Magic_Number);
      }
      else if(op == OP_SELL) {
        ticket = OrderSend(thisSymbol, OP_SELL, Entry_Lot, NormalizeDouble(Bid, Digits), 3, 
                           NormalizeDouble(Bid + SL_pips, Digits),
    	                     (0 < Trail_pips ? 0 : NormalizeDouble(Bid - TP_pips, Digits)),
  		                     NULL, Magic_Number);
      }

      if(0 < ticket) {
        orderSent = True;
      }
    }
  }

  trail();
}
//+------------------------------------------------------------------+
