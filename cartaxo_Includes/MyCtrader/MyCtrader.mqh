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

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade ctrade;
input string i_percentages = "0.5,1,1.5,2"; //Percentuais para aumentar posição
string vPercentages[];
double price_step = 2.0;
class MyCtrader : public CTrade {
public:
    void sendOrder(TraderInfos &info);
    void sendRangeOrders(TraderInfos &info);
    void closeAllPositions(TraderInfos &info);
    void MyCtrader();
private: 
   bool checkAllowedOrders(TraderInfos &info);
    
};

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

void MyCtrader::sendRangeOrders(TraderInfos &info) {

    ctrade.SetExpertMagicNumber(info.iMagicNumber);
    
    double trade_lots = SymbolInfoDouble(info.symbol, SYMBOL_VOLUME_MIN)+iRangeLotes;
    
    if (!checkAllowedOrders(info))return;
    
    if (info.lot_size == NULL || info.lot_size == 0) {
        info.lot_size = trade_lots;
    }
    
    if (info.symbol == NULL || (string)info.symbol == "") {
        Print("Error ao recuperar o Symbol: ", info.message);
        return;
    }
    bool order_sent = false;
    
    int open_positions = HasPosition(info.iMagicNumber);
    int open_orders    = OpenOrdersCount(info.iMagicNumber);
    price_step = SymbolInfoDouble( info.symbol, SYMBOL_TRADE_TICK_SIZE ); //Contém o valor do tick
    
    sendOrder(info);
    
    StringSplit(i_percentages, StringGetCharacter(",", 0), vPercentages);
    
    closeAllPositions(info);
    
     
    if (IsBought(info.iMagicNumber) && (open_orders + open_positions) < ArraySize(vPercentages) + 1){
    for(int i = (open_positions - 1); i < ArraySize(vPercentages); i++) {
            double _ref = getHighestPositionPrice(info.iMagicNumber);
            double _oprice = roundPriceH9K(_ref * (100 - (double)vPercentages[i])/100, price_step);
            double sl = roundPriceH9K(_oprice - (_oprice * iStopLossPercent/100), price_step);
            double tp = roundPriceH9K(_oprice + (_oprice * iTakeProfitPercent/100), price_step);
            ctrade.BuyLimit(trade_lots, _oprice, _Symbol, sl, tp, ORDER_TIME_GTC, 0, MQLInfoString(MQL_PROGRAM_NAME) + " Entrada na compra adicional: "+ vPercentages[i]);
        }
    
    }else if (IsSold(info.iMagicNumber) && (open_orders + open_positions) < ArraySize(vPercentages) + 1) {
        for(int i = (open_positions - 1); i < ArraySize(vPercentages); i++) {
            double _ref = getLowestPositionPrice(info.iMagicNumber);
            double _oprice = roundPriceH9K(_ref * (100 + (double)vPercentages[i])/100, price_step);
            double sl = roundPriceH9K(_oprice + (_oprice * iStopLossPercent/100), price_step);
            double tp = roundPriceH9K(_oprice - (_oprice * iTakeProfitPercent/100), price_step);
            ctrade.SellLimit(trade_lots, _oprice, _Symbol, sl, tp, ORDER_TIME_GTC, 0, MQLInfoString(MQL_PROGRAM_NAME) +  "Entrada na venda adicional " + vPercentages[i]);
        }
    }


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
    
   /* if (info.stop_loss == NULL || info.stop_loss == 0 || info.take_profit == NULL || info.take_profit == 0) {
        // Verificar se os multiplicadores ATR estão disponíveis para este símbolo
        if(!checkATRMultipliersAvailable(info.symbol)) {
            Print("ATR Service não está rodando para o símbolo ", info.symbol, ". Inicie o serviço primeiro.");
            return;
        }
        
        calculateStopAndTakeProfit(info);
    }*/
    
    bool order_sent = false;
    switch (info.order_type) {
        case ORDER_TYPE_BUY:
            switch (info.order_type_time){
               case ORDER_TIME_GTC:
                  ctrade.Buy(info.lot_size, info.symbol,info.amount, info.stop_loss, info.take_profit,info.message);
                  order_sent = true;
                  break;   
               default:
                  ctrade.BuyLimit(info.lot_size, info.amount, info.symbol, info.stop_loss, info.take_profit, 
                                info.order_type_time, 0, info.message);
                  order_sent = true;
                  break;
               }
            break;
        case ORDER_TYPE_SELL:
           switch (info.order_type_time){
               case ORDER_TIME_GTC:
                  ctrade.Sell(info.lot_size, info.symbol,info.amount, info.stop_loss, info.take_profit,info.message);
                  order_sent = true;
                  break;
                default:  
                  ctrade.SellLimit(info.lot_size, info.amount, info.symbol, info.stop_loss, info.take_profit, 
                              info.order_type_time, 0, info.message);
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
    
    Print("Ticket created ", ctrade.ResultOrder());
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
            if(HistoryDealSelect(trans.deal))
                m_deal.Ticket(trans.deal);
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