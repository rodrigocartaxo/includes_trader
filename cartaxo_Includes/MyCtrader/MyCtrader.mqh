//+------------------------------------------------------------------+
//|                                                    MyCtrader.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Rodrigo Cartaxo"

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <.\Personal\H9k_Includes\H9k_YT_libs_3.mqh>
#include <.\Personal\cartaxo_Includes\MyCtrader\TraderInfos.mqh>
#include <.\Personal\cartaxo_Includes\CommonParams.mqh>

// Definições de cores e estilos
#define ENTRY_LINE_COLOR      clrBlue
#define TP_LINE_COLOR         clrGreen
#define SL_LINE_COLOR         clrRed
#define ENTRY_LINE_STYLE      STYLE_SOLID
#define TP_LINE_STYLE         STYLE_DASH
#define SL_LINE_STYLE         STYLE_DASH
#define LINE_WIDTH            2

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade ctrade;
CommonParams commonParams;
enum     enumLotType{Fixed_Lots=0, Pct_of_Balance=1, Pct_of_Equity=2, Pct_of_Free_Margin=3};

input group "====== Risk Variabels Variables ======"

input    enumLotType          LotType              =     0;                   // Type of Lotsize (Fixed or % Risk)
input    double               RiskPercent          =     1;                   //Risk in % on each trade
   

class MyCtrader : public CTrade {
private: 
    bool checkAllowedOrders(TraderInfos &info);
    bool prepareTradeParameters(TraderInfos &info);
    bool waitForOrderExecution(double amount, ulong magicNumber);
    
public:
    MyCtrader();
    void sendOrder(TraderInfos &info);
    void sendOrderAtMarket(TraderInfos &info);
    void closeAllPositions(TraderInfos &info);
    void closePositonByTicket(ulong param_ticket, ulong iMagicNumber);
    bool isOpenTrader();
    double calcLotsTrade(TraderInfos &info);
    double calcLots(double slPoints,string _param_symbol );
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
MyCtrader::MyCtrader(void) {
    ctrade.SetDeviationInPoints(10);
    ctrade.SetTypeFilling(ORDER_FILLING_RETURN);
    ctrade.LogLevel(LOG_LEVEL_ERRORS);
    ctrade.SetAsyncMode(false);
    
}

//+------------------------------------------------------------------+
//| Prepares trade parameters (lot size, symbol validation)          |
//+------------------------------------------------------------------+
bool MyCtrader::prepareTradeParameters(TraderInfos &info) {
    if (!checkAllowedOrders(info)) {
        return false;
    }
    
    // Check if symbol is valid
    if (info.symbol == NULL || (string)info.symbol == "") {
        Print("Error ao recuperar o Symbol: ", info.message);
        return false;
    }
    
    if (info.iMagicNumber == NULL ) {
        Print("Error ao recuperar o magic number: ", info.message);
        return false;
    }
    
    // Calculate lot size
    if (info.lot_size == NULL || info.lot_size == 0) {
        info.lot_size = calcLots((info.amount - info.stop_loss),info.symbol);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Wait for order execution                                         |
//+------------------------------------------------------------------+
bool MyCtrader::waitForOrderExecution(double amount, ulong magicNumber) {
    // Timeout settings
    const int MAX_WAIT_TIME_MS = 5000; // 5 seconds
    const int SLEEP_TIME_MS = 100;
    int elapsed_time = 0;
    
    while(!has_order_at(amount, magicNumber, 0)) {
        Sleep(SLEEP_TIME_MS);
        elapsed_time += SLEEP_TIME_MS;
        
        if(elapsed_time >= MAX_WAIT_TIME_MS || HasPosition(magicNumber) == 0) {
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Close position by ticket                                         |
//+------------------------------------------------------------------+
void MyCtrader::closePositonByTicket(ulong param_ticket, ulong iMagicNumber) {
    ctrade.SetExpertMagicNumber(iMagicNumber);
    
    if(PositionSelectByTicket(param_ticket)) {
        if(PositionGetInteger(POSITION_MAGIC) == iMagicNumber) {
            if(ctrade.PositionClose(param_ticket)) {
                PrintFormat("[%d] [%d] Position closed by ticket", iMagicNumber, param_ticket);
            } else {
                PrintFormat("[%d] [%d] Failed to close position: %d", iMagicNumber, param_ticket, GetLastError());
            }
        }
    } else {
        PrintFormat("[%d] [%d] Position not found", iMagicNumber, param_ticket);
    }
}

//+------------------------------------------------------------------+
//| Send order at market                                             |
//+------------------------------------------------------------------+
void MyCtrader::sendOrderAtMarket(TraderInfos &info) {
    ctrade.SetAsyncMode(false);
    ctrade.SetExpertMagicNumber(info.iMagicNumber);
    
    if (!prepareTradeParameters(info)) {
        return;
    }
    
    bool order_sent = false;
    
    switch (info.order_type) {
        case ORDER_TYPE_BUY:
            order_sent = ctrade.Buy(info.lot_size, info.symbol, 0, info.stop_loss, info.take_profit, info.message);
            break;
         
        case ORDER_TYPE_SELL:
            order_sent = ctrade.Sell(info.lot_size, info.symbol, 0, info.stop_loss, info.take_profit, info.message);
            break;
            
        default:
            Print("info.order_type not available: ", info.order_type);
            return;
    }

    if(order_sent && !orderRejected(ctrade.ResultRetcode())) {
        waitForOrderExecution(info.amount, info.iMagicNumber);
        ulong ticket = ctrade.ResultOrder();
        Print("Ticket created ", ticket, " by " + (string)info.iMagicNumber);
    } else {
        Print("Order sending failed: ", ctrade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool MyCtrader::checkAllowedOrders(TraderInfos &info) {
    // Check time restrictions
    if (!i24h) {
        if (!allowed_by_hour(iHoraIni, iHoraFim)) {
            GlobalVariableSet("trade_not_available_" + (string)info.iMagicNumber, true);
            Print("Trade blocked by hour: " + (string)info.iMagicNumber);
            closeAllPositions(info);
            return false;
        } else if (!allowed_by_hour(iHoraIni, iHoraClose)) {
            GlobalVariableSet("trade_not_available_" + (string)info.iMagicNumber, true);
            Print("Trade blocked by hour: " + (string)info.iMagicNumber);
            return false;
        } else {
            GlobalVariableDel("trade_not_available_" + (string)info.iMagicNumber);
        }
    }
    
    // Check global restrictions
    if (GlobalVariableCheck("trade_not_available_" + (string)info.iMagicNumber)) {
        Print("Trade blocked: " + (string)info.iMagicNumber);
        return false;
    }
    
    if (GlobalVariableCheck("trade_not_available_daily")) {
        Print("Trade blocked by target: " + (string)info.iMagicNumber);
        return false;
    }
   
    return true;
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void MyCtrader::closeAllPositions(TraderInfos &info) {
    ctrade.SetExpertMagicNumber(info.iMagicNumber);
    int total_positions = PositionsTotal();
    bool has_position = false;
    
    for(int i = total_positions - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket)) {
            if(PositionGetInteger(POSITION_MAGIC) == info.iMagicNumber && 
               PositionGetString(POSITION_SYMBOL) == info.symbol) {
                if(ctrade.PositionClose(ticket)) {
                    has_position = true;
                } else {
                    Print("Failed to close position: ", ctrade.ResultRetcodeDescription());
                }
            }
        }
    }
    
    if(has_position) {
        PrintFormat("[%d] Closing all positions", info.iMagicNumber);
    }
}

//+------------------------------------------------------------------+
//| Send pending order                                               |
//+------------------------------------------------------------------+
void MyCtrader::sendOrder(TraderInfos &info) {
    ctrade.SetAsyncMode(false);
    ctrade.SetExpertMagicNumber(info.iMagicNumber);
    
    if (!prepareTradeParameters(info)) {
        return;
    }
    
    datetime dt = TimeCurrent();
    string DTstr = TimeToString(TimeCurrent(), TIME_DATE);
    datetime end = StringToTime(DTstr + " " + iHoraFim);
    
    bool order_sent = false;
    datetime expiration = (info.order_type_time == ORDER_TIME_DAY) ? end : 0;
    
    switch (info.order_type) {
        case ORDER_TYPE_BUY:
            order_sent = ctrade.BuyLimit(info.lot_size, info.amount, info.symbol, 
                                        info.stop_loss, info.take_profit, 
            
                                        info.order_type_time, expiration, info.message);
           
            break;
            
        case ORDER_TYPE_SELL:
            order_sent = ctrade.SellLimit(info.lot_size, info.amount, info.symbol, 
                                         info.stop_loss, info.take_profit, 
                                         info.order_type_time, expiration, info.message);
            break;
           
        default:
            Print("info.order_type not available: ", info.order_type);
            return;
    }


    if(order_sent && !orderRejected(ctrade.ResultRetcode())) {
        waitForOrderExecution(info.amount, info.iMagicNumber);
        ulong ticket = ctrade.ResultOrder();
        Print("Ticket created ", ticket, " by " + (string)info.iMagicNumber);
    } else {
        Print("Order sending failed: ", ctrade.ResultRetcodeDescription(), " ResultRetcode", ctrade.ResultRetcode());
    }
}
//+------------------------------------------------------------------+
//| Callback de transações                                            |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                       const MqlTradeRequest &request,
                       const MqlTradeResult &result) {
    CDealInfo m_deal;
    ENUM_ORDER_STATE lastOrderState = trans.order_state;
    
    switch(trans.type) {
        case TRADE_TRANSACTION_HISTORY_ADD:
            // Nada a fazer aqui, removidas as instruções de print
            break;
        
        case TRADE_TRANSACTION_DEAL_ADD:
            if(HistoryDealSelect(trans.deal)) {
                m_deal.Ticket(trans.deal);
                
                ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
                if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY) {
                    ulong magicNumber = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
                    if(has_open_position(magicNumber,POSITION_TYPE_BUY)||has_open_position(magicNumber,POSITION_TYPE_SELL)) {
                        Print(__FILE__, " ", __FUNCTION__, " Ainda existe ordens abertas para o MagicNumber",(string) magicNumber);
                        if ("123456" != (string)magicNumber){
                           ctrade.SetExpertMagicNumber(magicNumber);
                           closeAllPositions(ctrade, magicNumber);
                        }
                    }
                    
                }
            } else {
                Print(__FILE__, " ", __FUNCTION__, ", ERROR: HistoryDealSelect(", trans.deal, ")");
            }
            break;
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Cria uma linha horizontal no gráfico                              |
//+------------------------------------------------------------------+
void CreateHLine(string name, double price, color clr, ENUM_LINE_STYLE style, int width, string text) {
    if(ObjectFind(0, name) >= 0) {
        ObjectMove(0, name, 0, 0, price);
    } else {
        ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
    }
    
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
}

bool MyCtrader::isOpenTrader(){
   
   if(!i24h && !allowed_by_hour(iHoraIni, iHoraFim))return false; 
    return true;
}

double MyCtrader::calcLotsTrade(TraderInfos &info){   
   return calcLots((info.amount - info.stop_loss),info.symbol);
}


double MyCtrader::calcLots(double slPoints,string _param_symbol ){

      double lots = SymbolInfoDouble(_param_symbol,SYMBOL_VOLUME_MIN);

      double AccountBalance   = AccountInfoDouble(ACCOUNT_BALANCE);
      double EquityBalance    = AccountInfoDouble(ACCOUNT_EQUITY);
      double FreeMargin       = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

      double risk=0;

      switch(LotType){
         case 0: lots=  SymbolInfoDouble(_param_symbol, SYMBOL_VOLUME_MIN); return lots;
         case 1: risk = (AccountBalance * RiskPercent / 100); break;
         case 2: risk = (EquityBalance * RiskPercent / 100); break;
         case 3: risk = (FreeMargin * RiskPercent / 100); break;
      }
      
      double ticksize = SymbolInfoDouble(_param_symbol,SYMBOL_TRADE_TICK_SIZE);
      double tickvalue = SymbolInfoDouble(_param_symbol,SYMBOL_TRADE_TICK_VALUE);
      double lotstep = SymbolInfoDouble(_param_symbol,SYMBOL_VOLUME_STEP);

      double moneyPerLotstep = slPoints / ticksize * tickvalue * lotstep;
             lots = MathFloor(risk / moneyPerLotstep) * lotstep;

      double minvolume=SymbolInfoDouble(_param_symbol,SYMBOL_VOLUME_MIN);
      double maxvolume=SymbolInfoDouble(_param_symbol,SYMBOL_VOLUME_MAX);
      double volumelimit = SymbolInfoDouble(_param_symbol,SYMBOL_VOLUME_LIMIT);
      
      if(volumelimit!=0) lots = MathMin(lots,volumelimit);
      if(maxvolume!=0) lots = MathMin(lots,maxvolume);
      if(minvolume!=0) lots = MathMax(lots,minvolume);
      lots = NormalizeDouble(lots,2);

      return lots;

}
