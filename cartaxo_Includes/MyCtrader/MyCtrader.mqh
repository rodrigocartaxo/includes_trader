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

#define ENTRY_LINE_COLOR      clrBlue
#define TP_LINE_COLOR         clrGreen
#define SL_LINE_COLOR         clrRed

// Estilos de linha
#define ENTRY_LINE_STYLE      STYLE_SOLID
#define TP_LINE_STYLE         STYLE_DASH
#define SL_LINE_STYLE         STYLE_DASH
#define LINE_WIDTH            2

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade ctrade;
double price_step = 2.0;
class MyCtrader : public CTrade {
public:
    void sendOrder(TraderInfos &info);
    
    void closeAllPositions(TraderInfos &info);
    void closePositonByTicket(ulong param_ticket,ulong iMagicNumber);
    void MyCtrader();
private: 
   bool checkAllowedOrders(TraderInfos &info);
    
};

void MyCtrader::closePositonByTicket(ulong param_ticket,ulong iMagicNumber){
   
    ctrade.SetExpertMagicNumber(iMagicNumber);
    int total_positions = PositionsTotal();
    bool has_position = false;
    for(int i = total_positions-1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionGetInteger(POSITION_MAGIC) == iMagicNumber 
           && param_ticket == ticket ) {
            ctrade.PositionClose(param_ticket);
            has_position = true;
        }
    }
    
    if(has_position) PrintFormat("[%d] [%d]  Closing  positions by ticket",iMagicNumber,param_ticket);
   

}
void MyCtrader::MyCtrader(void){
   
   ctrade.SetDeviationInPoints(10);
   ctrade.SetTypeFilling(ORDER_FILLING_FOK);
   ctrade.LogLevel(LOG_LEVEL_ERRORS);
   

}



bool MyCtrader::checkAllowedOrders(TraderInfos &info){
   
   if (!i24h && !allowed_by_hour(iHoraIni, iHoraFim))  {
         GlobalVariableSet("trade_not_available_"+(string)info.iMagicNumber,true);
         Print("Trade blocked by hour: "+(string)info.iMagicNumber);
         closeAllPositions(info);
         return false;
    
    }else if (!i24h && !allowed_by_hour(iHoraIni, iHoraClose)){
         GlobalVariableSet("trade_not_available_"+(string)info.iMagicNumber,true);
         Print("Trade blocked by hour: "+(string)info.iMagicNumber);
         return false;    
    
    }else{
         GlobalVariableDel("trade_not_available");    
         return true;
    } 
   
    
    if (GlobalVariableCheck("trade_not_available_"+(string)info.iMagicNumber)){
        Print("Trade blocked: "+(string)info.iMagicNumber);
        return false;
    }
    if (GlobalVariableCheck("trade_not_available_daily")) {
        Print("Trade blocked by target :  "+(string)info.iMagicNumber);
        
        return false;
    }
   
   return true;   

}


void MyCtrader::closeAllPositions(TraderInfos &info) {
    ctrade.SetExpertMagicNumber(info.iMagicNumber);
    int total_positions = PositionsTotal();
    bool has_position = false;
    ctrade.SetExpertMagicNumber(info.iMagicNumber);

    for(int i = total_positions-1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionGetInteger(POSITION_MAGIC) == info.iMagicNumber 
           && PositionGetString(POSITION_SYMBOL) ==info.symbol) {
            ctrade.PositionClose(ticket);
            has_position = true;
        }
    }
    
    if(has_position) PrintFormat("[%d] Closing all positions", info.iMagicNumber);
}


void MyCtrader::sendOrder(TraderInfos &info) {
    
    
    ctrade.SetExpertMagicNumber(info.iMagicNumber);
    
    if (!checkAllowedOrders(info))return;
    
    
    double trade_lots = SymbolInfoDouble(info.symbol, SYMBOL_VOLUME_MIN)+iRangeLotes;
    string varName = "lot_size_" + info.symbol + "_" + (string)info.iMagicNumber;
    
    if (GlobalVariableCheck(varName)) {
        trade_lots = defaultLot ? SymbolInfoDouble(info.symbol, SYMBOL_VOLUME_MIN)+iRangeLotes : GlobalVariableGet(varName);
    }
    
    if (info.lot_size == NULL || info.lot_size == 0) {
        info.lot_size = trade_lots;
    }
    
    if (info.symbol == NULL || (string)info.symbol == "") {
        Print("Error ao recuperar o Symbol: ", info.message);
        return;
    }
   
   datetime dt     = TimeCurrent();
   string   DTstr  = TimeToString(TimeCurrent(), TIME_DATE);
   datetime end    = StringToTime(DTstr + " " + iHoraFim);
   
     
    bool order_sent = false;
    switch (info.order_type) {
        case ORDER_TYPE_BUY:
            switch (info.order_type_time){
               case ORDER_TIME_GTC:
                  ctrade.BuyLimit(info.lot_size, info.amount, info.symbol, info.stop_loss, info.take_profit, 
                                info.order_type_time, 0, info.message);
                  order_sent = true;
                  break;   
               default:
                  ctrade.BuyLimit(info.lot_size, info.amount, info.symbol, info.stop_loss, info.take_profit, 
                                info.order_type_time, end, info.message);
                  order_sent = true;
                  break;
               }
            break;
        case ORDER_TYPE_SELL:
           switch (info.order_type_time){
               case ORDER_TIME_GTC:
                  ctrade.SellLimit(info.lot_size, info.amount, info.symbol, info.stop_loss, info.take_profit, 
                              info.order_type_time, 0, info.message);
                  order_sent = true;
                  break;
                default:  
                  ctrade.SellLimit(info.lot_size, info.amount, info.symbol, info.stop_loss, info.take_profit, 
                              info.order_type_time, end, info.message);
                  order_sent = true;
                  break;
                }
            break;
        default:
            Print("info.order_type not available", info.order_type);
            break;
    }

    if(order_sent && !orderRejected(ctrade.ResultRetcode())) {
        while(!has_order_at(info.amount, info.iMagicNumber, 0)) {
            Print("Waiting for the order to be placed");
            Sleep(500);
            if(HasPosition(info.iMagicNumber) == 0)
                break;
        }
    }
    ulong ticket = ctrade.ResultOrder();
    
    /*CreateHLine("pos_line_tp_"+IntegerToString(ticket), 
                          info.take_profit, 
                          TP_LINE_COLOR, 
                          TP_LINE_STYLE, 
                          LINE_WIDTH, 
                          "TP #"+IntegerToString(ticket));*/
    Print("Ticket created ", ticket);
}

//+------------------------------------------------------------------+
//| Verifica se os multiplicadores ATR estão disponíveis              |
//+------------------------------------------------------------------+
bool checkATRMultipliersAvailable(string symbol) {
    string slVar = "atr_multiply_sl_" + symbol;
    string tpVar = "atr_multiply_tp_" + symbol;
    
    if(!GlobalVariableCheck(slVar)) {
        Print("Multiplicador SL não disponível para ", symbol);
        return false;
    }
    
    if(!GlobalVariableCheck(tpVar)) {
        Print("Multiplicador TP não disponível para ", symbol);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calcula Stop Loss e Take Profit baseado nos multiplicadores ATR   |
//+------------------------------------------------------------------+
void calculateStopAndTakeProfit(TraderInfos &info) {
    double ask, bid, slPoints, tpPoints;
    double _price_step = SymbolInfoDouble(info.symbol, SYMBOL_TRADE_TICK_SIZE);
    
    // Obter os valores ATR atuais para o símbolo
    getATRValues(info.symbol, slPoints, tpPoints);

    Print("Calculated values for ", info.symbol, " : ", info.message);
    
    switch(info.order_type) {
        case ORDER_TYPE_BUY:
            ask = SymbolInfoDouble(info.symbol, SYMBOL_ASK);
            info.stop_loss = roundPriceH9K(ask - slPoints, _price_step);
            info.take_profit = roundPriceH9K(ask + tpPoints, _price_step);
            
            info.amount = ask;
            Print("Value :  ", ask);
            break;
            
        case ORDER_TYPE_SELL:
            bid = SymbolInfoDouble(info.symbol, SYMBOL_BID);
            info.stop_loss = roundPriceH9K(bid + slPoints, _price_step);
            info.take_profit = roundPriceH9K(bid - tpPoints, _price_step);
            info.amount = bid;
            Print("Value :  ", bid);
            break;
            
        default:
            Print("info.order_type not available", info.order_type);
    }
    
    
    Print("Stop Loss: ", info.stop_loss, " (", slPoints, " points)");
    Print("Take Profit: ", info.take_profit, " (", tpPoints, " points)");
}

//+------------------------------------------------------------------+
//| Obtém os valores ATR para Stop Loss e Take Profit                 |
//+------------------------------------------------------------------+
void getATRValues(string symbol, double &slPoints, double &tpPoints) {
    string slVar = "atr_multiply_sl_" + symbol;
    string tpVar = "atr_multiply_tp_" + symbol;
    
    slPoints = GlobalVariableGet(slVar);
    tpPoints = GlobalVariableGet(tpVar);
    
    Print("ATR values for ", symbol, ":");
    Print("SL multiplier: ", slPoints);
    Print("TP multiplier: ", tpPoints);
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
        case TRADE_TRANSACTION_HISTORY_ADD: {
            string Exchange_ticket = "";
            if(lastOrderState == ORDER_STATE_FILLED) {
                //Print("Ordem executada");
            } else if(lastOrderState == ORDER_STATE_CANCELED) {
                //Print("Ordem cancelada");
            }
            break;
        }
        
        case TRADE_TRANSACTION_DEAL_ADD: {
            if(HistoryDealSelect(trans.deal)){
                m_deal.Ticket(trans.deal);
                ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
                ulong positionId = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
                if(dealEntry == DEAL_ENTRY_OUT || trans.deal == DEAL_ENTRY_OUT_BY){
                  Print("Posição fechada: ID=", positionId, ", Ticket=", trans.deal);
                 
                 }
            }
            
            else {
                Print(__FILE__, " ", __FUNCTION__, ", ERROR: HistoryDealSelect(", trans.deal, ")");
                return;
            }
            
            long reason = -1;
            if(!m_deal.InfoInteger(DEAL_REASON, reason)) {
                Print(__FILE__, " ", __FUNCTION__, ", ERROR: InfoInteger(DEAL_REASON,reason)");
                return;
            }
            
            break;
        }
    }
     ChartRedraw();
}

//+------------------------------------------------------------------+
//| Cria uma linha horizontal no gráfico                              |
//+------------------------------------------------------------------+
void CreateHLine(string name, double price, color clr, ENUM_LINE_STYLE style, int width, string text){
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
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
