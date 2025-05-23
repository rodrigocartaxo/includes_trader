//+------------------------------------------------------------------+
//|                                                  H9k_YT_libs.mqh |
//|                                              H9k Trading Systems |
//|                               https://www.youtube.com/@h9ktrades |
//+------------------------------------------------------------------+
#property copyright "H9k Trading Systems"
#property link      "https://www.youtube.com/@h9ktrades"

#include <Trade\Trade.mqh>

ulong H9K_reject_alert_counter = 0;


//+------------------------------------------------------------------+
//| Returns true if a new bar is found                               |
//+------------------------------------------------------------------+
bool isNewBar(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT)
{

    static datetime last_time = 0; //--- memorize the time of opening of the last bar in the static variable

    datetime lastbar_time = (datetime)SeriesInfoInteger(NULL, _tf, SERIES_LASTBAR_DATE); //--- current time


    if(last_time == 0) {            //--- if it is the first call of the function
        last_time = lastbar_time;   //--- set the time and exit
        return(false);
    }

    if(last_time != lastbar_time) { //--- if the time differs
        last_time = lastbar_time;   //--- memorize the time and return true
        return(true);
    }

    return(false); //--- if we passed to this line, then the bar is not new; return false
}

//+------------------------------------------------------------------
//| Função para arredondar/corrigir o preço
//+------------------------------------------------------------------
double roundPriceH9K(double price, double l_price_step)
{
    return l_price_step * MathRound(price / l_price_step);
}

//+------------------------------------------------------------------+
//| Return true if current time between start time and end time      |
//+------------------------------------------------------------------+
bool allowed_by_hour(string starttime, string endtime)
{
    datetime dt     = TimeCurrent();
    string   DTstr  = TimeToString(TimeCurrent(), TIME_DATE);
    datetime lstart = StringToTime(DTstr + " " + starttime);
    datetime end    = StringToTime(DTstr + " " + endtime);

    if(lstart < end)
        if(dt >= lstart && dt < end)
            return(true);

    if(lstart >= end)
        if(dt >= lstart || dt < end)
            return(true);

    return(false);
}

//+------------------------------------------------------------------+
//| Close all open orders of a specific symbol                       |
//+------------------------------------------------------------------+
void closeAllOpenOrders(CTrade &ltrade, long l_magic, ENUM_ORDER_TYPE _oType = NULL)
{
    int total_orders = OrdersTotal();
    bool order_deleted = false;
    
    ltrade.SetAsyncMode(true);
    
    for(int i = total_orders - 1; i >= 0; i--) { //importante que seja decrescente

        ulong ticket = OrderGetTicket(i);
        
        if(OrderGetInteger(ORDER_MAGIC) != l_magic) continue;

        if(!_oType) {
            //PrintFormat("[%d] Deletendo ordem %I64d", l_magic, ticket);
            ltrade.OrderDelete(ticket);
            order_deleted = true;
        } else if (OrderGetInteger(ORDER_TYPE) == _oType) {
            //PrintFormat("[%d] Deletendo ordem %I64d", l_magic, ticket);
            ltrade.OrderDelete(ticket);
            order_deleted = true;
        }

    }
    
    if(order_deleted) PrintFormat("[%d] Closing all (%d) open orders", l_magic, total_orders);
    
    ltrade.SetAsyncMode(false);
    
    int maxTimeout = 0;

    while (has_open_order(l_magic, _oType) && !IsStopped()) {

        Sleep(200);
        maxTimeout++;

        if (maxTimeout > 100) {
            Alert("### closeAllOpenOrders orders fatal error: ");
            break;
        }

    }

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OpenOrdersCount(long l_magic)
{
    int total_orders = OrdersTotal();

    int count = 0;

    for(int i = 0; i < total_orders;  i++) {

        OrderGetTicket(i);        

        if(OrderGetInteger(ORDER_MAGIC) == l_magic) {
            count++;
        }

    }

    return count;
}

//+------------------------------------------------------------------+
//| Verifica se tem ordens pendentes                                 |
//+------------------------------------------------------------------+
bool has_open_order(long l_magic, ENUM_ORDER_TYPE _oType = NULL)
{
    int total_orders = OrdersTotal();

    for(int i = 0; i < total_orders;  i++) {

        OrderGetTicket(i);

        if(!_oType && OrderGetInteger(ORDER_MAGIC) == l_magic) {
            return true;
        } else if(OrderGetInteger(ORDER_MAGIC) == l_magic && OrderGetInteger(ORDER_TYPE) == _oType) {
            return true;
        }

    }

    return false;
}

//+------------------------------------------------------------------+
//| Verifica se tem posições em aberto
//+------------------------------------------------------------------+
bool has_open_position(long l_magic, ENUM_POSITION_TYPE _pType)
{
    int total_positions = PositionsTotal();

    for(int i = 0; i < total_positions;  i++) {

        PositionGetTicket(i);
        
        
        if(PositionGetInteger(POSITION_MAGIC) == l_magic && PositionGetInteger(POSITION_TYPE) == _pType) {
            return true;
        }
    }
    return false;
}




//+--------------------------------------------------------+
//| Retorna se tem ordem no papel e no preço especificado  |
//+--------------------------------------------------------+
bool has_order_at(double l_price, long l_magic, int debug = 0)
{
    int total_orders = OrdersTotal();
    int open_orders = 0;

    for(int i = 0; i < total_orders;  i++) {
        ulong ticket = OrderGetTicket(i);
        long o_magic = OrderGetInteger(ORDER_MAGIC);

        if(o_magic != l_magic)
            continue;

        double o_price = NormalizeDouble(OrderGetDouble(ORDER_PRICE_OPEN), Digits());

        if(debug == 2) printf ("o_price: %f l_price: %f (%s)", o_price, l_price, (string)((double)o_price == (double)l_price));

        if(o_price == NormalizeDouble(l_price, Digits())) {
            if(debug == 1) printf("has_order at returning true");
            return true;
        }
    }
    return false;
}

bool has_position_at(double l_price, long l_magic, int debug = 0)
{
    int total_positions = PositionsTotal();
    int open_positions = 0;

    for(int i = 0; i < open_positions;  i++) {
        ulong ticket = PositionGetTicket(i);
        long p_magic = PositionGetInteger(POSITION_MAGIC);

        if(p_magic != l_magic)
            continue;

        double p_price = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN), Digits());        

        if(p_price == NormalizeDouble(l_price, Digits())) {
            if(debug == 1) printf("has_position at returning true");
            return true;
        }
    }
    return false;
}

//+-----------------------------------------------------------------------+
//| Retorna verdadeiro se tiver ao menos uma posição comprada no ativo    |
//+-----------------------------------------------------------------------+
bool IsBought(ulong l_magic)
{
    bool _isBought = false;
    int total_positions = PositionsTotal();

    for(int i = 0; i < total_positions;  i++) {
        PositionGetTicket(i);
        if (PositionGetInteger(POSITION_MAGIC) == l_magic) {
            _isBought = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
            if (!_isBought) break;
        }
    }
    return _isBought;
}

bool checkTradePermission(bool &trade_allowed) {
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
        Print("Algotrading está desativado.");
        trade_allowed = false;
    } else if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) {      
        Print("Automação está desabilidade para estratégia ", __FILE__);
        trade_allowed = false;
    } else {
        trade_allowed = true;
    }
    return trade_allowed;
}

//+-----------------------------------------------------------------------+
//| Retorna verdadeiro se tiver ao menos uma posição vendida no ativo     |
//+-----------------------------------------------------------------------+
bool IsSold(ulong l_magic) {

    bool _isSold = false;
    int total_positions = PositionsTotal();

    for(int i = 0; i < total_positions;  i++) {
        PositionGetTicket(i);

        if (PositionGetInteger(POSITION_MAGIC) == l_magic) {
            _isSold = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL;
            if(!_isSold) break;
        }
    }
    return _isSold;
}

//Função para modificar o SL e TP de todas as posições
//Recebe como parâmetros o objeto ctrade, o magic number e o novo stop loss e novo tp
void changePositions(CTrade &l_trade, ulong l_magic, double new_sl, double new_tp)
{
    int total_positions = PositionsTotal();

    for(int i = 0; i < total_positions; i++) {
        ulong ticket = PositionGetTicket(i);

        if(PositionGetInteger(POSITION_MAGIC) == l_magic) {
            l_trade.PositionModify(ticket, new_sl, new_tp);
        }
    }

    return;
}

bool orderRejected(uint _retcode) {
    if(MathMod(H9K_reject_alert_counter, 10)) {
        if(_retcode == 10019) {
            Alert("Você quer operar sem grana?!? Ordem rejeitada.. sem margem");   
        } else if (_retcode == 10018) {
            Alert("Mercado fechado, não posso enviar ordens");            
        } else if (_retcode == 10017) {
            Alert("Trade desabilitado...");
        }
    }
    
    H9K_reject_alert_counter++;
    
   if(_retcode >= 10011 && _retcode <= 10016) return true;
   if(_retcode == 10006) return true;
   if(_retcode == 10018) return true;
   if(_retcode == 10009) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllPositions(CTrade &l_trade, ulong l_magic)
{
    int total_positions = PositionsTotal();
    bool has_position = false;
    
    l_trade.SetAsyncMode(true);
    for(int i = total_positions-1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);

        if(PositionGetInteger(POSITION_MAGIC) == l_magic) {
            l_trade.PositionClose(ticket);
            has_position = true;
        }
    }
    l_trade.SetAsyncMode(false);
    
    if(has_position) PrintFormat("[%d] Closing all positions", l_magic);
    
    return;
}
double PositionQty(ulong l_magic)
{
    int total_positions = PositionsTotal();
    double position_vol = 0;

    for(int i = 0; i < total_positions;  i++) {
        PositionGetTicket(i);

        if(PositionGetInteger(POSITION_MAGIC) == l_magic) {
            position_vol += PositionGetDouble(POSITION_VOLUME);
        }
    }

    return position_vol;
}

//Função para modificar o SL de todas as posições
//Irá manter o take profit original
//Recebe como parâmetros o objeto ctrade, o magic number e o novo stop loss
void changePositionsSL(CTrade &l_trade, ulong l_magic, double new_sl)
{
    int total_positions = PositionsTotal();

    for(int i = 0; i < total_positions; i++) {
        ulong ticket = PositionGetTicket(i);
        
        if(PositionGetInteger(POSITION_MAGIC) == l_magic && PositionGetDouble(POSITION_SL) != new_sl) {
            l_trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP));
        }
    }

    return;
}


//+------------------------------------------------------------------+
//| Retorna o resultado em aberto de múltiplas posições              |
//+------------------------------------------------------------------+
double OpenResult(ulong l_magic)
{
    double open_result = 0;

    int total_positions = PositionsTotal();

    for(int i = 0; i < total_positions;  i++) {
        PositionGetTicket(i);

        if(PositionGetInteger(POSITION_MAGIC) == l_magic) {
            open_result += PositionGetDouble(POSITION_PROFIT);
        }
    }

    return NormalizeDouble(open_result, 2);
}

//+------------------------------------------------------------------+
//| Calcula a perda máxima com base em um gradiente com distância específica
//+------------------------------------------------------------------+
double simpleCalculateMaxLoss(string l_symbol, int l_entries, double l_distance, double l_amount)
{

    double An = l_distance + (l_entries - 1) * l_distance;
    double Sn = l_entries * (l_distance + An) / 2;
    return NormalizeDouble(l_amount * Sn * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE), 2);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calculateMaxLoss(ulong l_magic)
{
    double max_loss = 0;

    int total_positions = PositionsTotal();

    for(int i = 0; i < total_positions;  i++) {
        PositionGetTicket(i);

        if(PositionGetInteger(POSITION_MAGIC) == l_magic) {
            max_loss += PositionGetDouble(POSITION_VOLUME) * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL))/SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        }
    }

    int total_orders = OrdersTotal();

    for(int i = 0; i < total_orders;  i++) {

        OrderGetTicket(i);

        if(OrderGetInteger(ORDER_MAGIC) == l_magic) {
            //Print(OrderGetInteger(ORDER_TICKET));
            max_loss += OrderGetDouble(ORDER_VOLUME_CURRENT) * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * MathAbs(OrderGetDouble(ORDER_PRICE_OPEN) - OrderGetDouble(ORDER_SL)) / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        }

    }

    return max_loss;
}


//+------------------------------------------------------------------+
//| Função para retornar o resultado fechado do mês
//+------------------------------------------------------------------+
double monthlyResult(ulong l_magic)
{
    MqlDateTime str;
    TimeToStruct(TimeCurrent(), str); // Converte o tempo atual para a estrutura MqlDateTime
    str.day = 1; // Define o dia para o primeiro do mês
    str.hour = 0;
    str.min = 0;
    str.sec = 0;
    return DailyResult(l_magic, StructToTime(str));

}

//+------------------------------------------------------------------+
//| Função para retornar o resultado fechado da semana               |
//+------------------------------------------------------------------+
double weeklyResult(ulong l_magic)
{
    MqlDateTime str;
    TimeToStruct(TimeCurrent(), str); // Converte o tempo atual para a estrutura MqlDateTime

    // Define o dia para o primeiro dia da semana (Domingo)
    str.day -= str.day_of_week; // Subtrai o número do dia da semana para obter o domingo

    if(str.day_of_week == 0) // Se hoje é domingo, subtrai 7 dias para obter o domingo anterior
        str.day -= 7;

    str.hour = 0;
    str.min = 0;
    str.sec = 0;

    return DailyResult(l_magic, StructToTime(str));
}

double NumberOfContracts(ulong l_magic, datetime l_start = NULL)
{
    double result = 0;
    datetime start;

    datetime end = TimeCurrent();

    if(!l_start) {
        string sdate = TimeToString (TimeCurrent(), TIME_DATE);
        start = StringToTime(sdate);
    } else {
        start = l_start;
    }

    HistorySelect(start, end);
    int TotalDeals = HistoryDealsTotal();

    for (int i = 0; i < TotalDeals; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT && HistoryDealGetInteger(ticket, DEAL_MAGIC) == l_magic) {
            double latest_volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
            result += latest_volume;
        }
    }
    return NormalizeDouble(result, 2);
}

//+-----------------------------------------------------------------------+
//| Função para retornar o valor do resultado diário fechado apenas       |
//+-----------------------------------------------------------------------+
double DailyResult(ulong l_magic, datetime l_start = NULL, int l_debug = 0)
{
    double result = 0;
    datetime start;

    datetime end = TimeCurrent();

    if(!l_start) {
        string sdate = TimeToString (TimeCurrent(), TIME_DATE);
        start = StringToTime(sdate);
    } else {
        start = l_start;
    }

    HistorySelect(start, end);
    int TotalDeals = HistoryDealsTotal();

    for (int i = 0; i < TotalDeals; i++) {
        ulong ticket = HistoryDealGetTicket(i);

        if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT && HistoryDealGetInteger(ticket, DEAL_MAGIC) == l_magic) {            
            double LatestProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            result += LatestProfit;
            if (l_debug > 0) PrintFormat("[%I64d] Ticket %I64d Profit %.2f Time: %s", l_magic, ticket, LatestProfit, start);
        }
    }
    return NormalizeDouble(result, 2);
}

//Retorna o preço médio atual -- ainda precisa de melhorias
double PositionsAveragePrice(ulong l_magic)
{
    double avg_price = 0;

    int total_positions = PositionsTotal();

    if (total_positions == 0) return 0;

    for(int i = 0; i < total_positions;  i++) {
        PositionGetTicket(i);

        if(PositionGetInteger(POSITION_MAGIC) == l_magic) {
            avg_price += PositionGetDouble(POSITION_PRICE_OPEN);
        }
    }

    return NormalizeDouble(avg_price/total_positions, 2);
}


//+------------------------------------------------------------------+
//| Retorna a quantidade de posições em aberto para o ativo e        |
//| magic number associado                                           |
//+------------------------------------------------------------------+
int HasPosition(ulong l_magic,string _param_symbol = NULL )
{
    int total_positions = PositionsTotal();
    int open_positions = 0;

    for(int i = 0; i < total_positions;  i++) {
        PositionGetTicket(i);       
        
        if(_param_symbol !=NULL && OrderGetInteger(ORDER_MAGIC) == l_magic && OrderGetString(ORDER_SYMBOL)== _param_symbol  ) {
            open_positions++;
        }     
        else if(PositionGetInteger(POSITION_MAGIC) == l_magic) {
            open_positions++;
        }
    }

    return open_positions;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HasAndSelectSinglePosition(ulong l_magic)
{
    int total_positions = PositionsTotal();
    int open_positions = 0;
    long last_position_ticket = 0;

    for(int i = 0; i < total_positions;  i++) {
        PositionGetTicket(i);
                
        if(PositionGetInteger(POSITION_MAGIC) == l_magic) {
            last_position_ticket = PositionGetInteger(POSITION_TICKET);
            open_positions++;
        }
    }

    if(open_positions == 1) {
        PositionSelectByTicket(last_position_ticket);
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//|  Linear Regression Helper                                        |
//+------------------------------------------------------------------+
void linear_regression(int nbars, double & l_rlBuffer[], double & l_highBuffer[], double & l_lowBuffer[]) export 
{
    ArrayResize(l_rlBuffer, nbars);
    ArrayResize(l_highBuffer, nbars);
    ArrayResize(l_lowBuffer, nbars);
    
    MqlRates lrates[];
    double sumX, sumY, sumXY, sumX2, a, b, F, S;
    int X;

  CopyRates(Symbol(), Period(), 1, nbars, lrates);

  F = 0.0;
  S = 0.0;
  sumX = 0.0;
  sumY = 0.0;
  sumXY = 0.0;
  sumX2 = 0.0;
  X = 0;

  for(int i = 0; i < nbars; i++) {
    //PrintFormat("Price[%d]: %.2f", i, lrates[i].close);
    sumX += X;
    sumY += lrates[i].close;
    sumXY += X * lrates[i].close;
    sumX2 += MathPow(X, 2);
    X++;
  }
  
  a = (sumX * sumY - nbars * sumXY) / (MathPow(sumX, 2) - nbars * sumX2);
  b = (sumY - a * sumX) / nbars;
  
//--- calculate values of main line and error F
  X = 0;
  for(int i = 0; i < nbars; i++) {    
    l_rlBuffer[i] = b + a * X;
    F += MathPow(lrates[i].close - l_rlBuffer[i], 2);
    X++;
  }
//--- calculate deviation S
  S = NormalizeDouble(MathSqrt(F / (nbars + 1)) / MathCos(MathArctan(a * M_PI / 180) * M_PI / 180), _Digits);

//--- calculate values of last buffers
  for(int i = 0; i < nbars; i++) {
    l_highBuffer[i] = l_rlBuffer[i] + 2*S;
    l_lowBuffer[i]  = l_rlBuffer[i] - 2*S;
  }
}

bool isSessionOpen(string l_symbol) {
    MqlDateTime mqt;
    
    if(TimeToStruct(TimeTradeServer(), mqt)) {
        ENUM_DAY_OF_WEEK dow = (ENUM_DAY_OF_WEEK)mqt.day_of_week;
        mqt.hour = 0;
        mqt.min  = 0;
        mqt.sec  = 0;
        
        datetime base = StructToTime(mqt);
        datetime get_from = 0; 
        datetime get_to   = 0;
  
        uint session = 0;
        
        if(SymbolInfoSessionTrade(l_symbol, dow, session, get_from, get_to)){
            
            get_from = (datetime)(base + get_from);
            get_to   = (datetime)(base + get_to);
            
            //Print("Session [ " + IntegerToString(session) + " ] (" + TimeToString(get_from,TIME_DATE|TIME_MINUTES|TIME_SECONDS) + ")->(" + TimeToString(get_to,TIME_DATE|TIME_MINUTES|TIME_SECONDS)+")");
           
            session++;
                        
            if(TimeTradeServer() >= get_from && TimeTradeServer() <= get_to) {                
                return(true);
            }
        }  
    }
    return(false);
}


double tradeAverageTicks(ulong l_magic, datetime l_start)
{

    double tVal   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double cts    = PositionQty(l_magic);
    double profit = DailyResult(l_magic, l_start) + OpenResult(l_magic);
    double tSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

    return (profit * tSize)/(tVal * cts);
}

void changePositionsTP(CTrade &l_trade, ulong l_magic, double new_tp)
{
    int total_positions = PositionsTotal();

    for(int i = 0; i < total_positions; i++) {
        ulong ticket = PositionGetTicket(i);

        if(PositionGetInteger(POSITION_MAGIC) == l_magic && PositionGetDouble(POSITION_TP) != new_tp) {
            l_trade.PositionModify(ticket, PositionGetDouble(POSITION_SL), new_tp);
        }
    }

    return;
}

int timeToClose(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) {
    // Tempo atual do servidor
    datetime currentTime = TimeCurrent();
    
    // Hora de abertura do candle atual
    datetime candleOpenTime = iTime(_Symbol, _tf, 0);
    
    // Duração do período do gráfico em segundos
    int periodSeconds = PeriodSeconds(_tf);

    // Calcula o tempo restante até o fechamento do candle
    int timeUntilClose = ((int)candleOpenTime + periodSeconds) - (int)currentTime;

    // Retorna o tempo restante em segundos
    return timeUntilClose;
}

// Função para criar ou atualizar uma linha horizontal
void SetHL(string name, double price, color lineColor = clrYellow)
{
   // Verifica se a linha já existe
   if(ObjectFind(0, name) != -1)
   {
      // Atualiza o preço da linha horizontal existente
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);      
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 1);
   }
   else
   {
      // Cria uma nova linha horizontal se ela não existir
      if(!ObjectCreate(0, name, OBJ_HLINE, 0, 0, price))
      {
         Print("Erro ao criar a linha horizontal: ", GetLastError());
         return;
      }
      
      // Define a cor da linha
      ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);

      // Define a largura da linha (opcional)
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);

      // Torna a linha visível em todas as janelas de tempo (opcional)
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 1);
   }
}

// Função para obter a hora da posição mais antiga em aberto para um Magic Number específico
datetime getOldestPositionTime(long _magic)
{
    datetime oldestTime = 0;
    int totalPositions = PositionsTotal();

    // Itera por todas as posições abertas
    for (int i = 0; i < totalPositions; i++)
    {
        if (PositionGetTicket(i))
        {
            // Verifica se a posição tem o Magic Number especificado
            if (PositionGetInteger(POSITION_MAGIC) == _magic)
            {
                // Obtém a hora de abertura da posição
                datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);

                // Verifica se esta é a posição mais antiga encontrada até agora
                if (oldestTime == 0 || openTime < oldestTime)
                {
                    oldestTime = openTime;
                }
            }
        }
    }

    return oldestTime;
}

double getHighestPositionPrice(ulong _magic) export {
    int      total_positions         = PositionsTotal();
    double   highest_price           = -1.0;
    ulong    ticket_with_highest     = 0;
            
    for(int i = 0; i < total_positions; i++) {
        CPositionInfo  _pos;
        if(_pos.SelectByIndex(i) && _pos.Magic() == _magic) {
            double _entry_price = _pos.PriceOpen();
            if(_entry_price > highest_price) {
                highest_price       = _entry_price;
                ticket_with_highest = _pos.Ticket();
            }
        }
    }
    
    return highest_price;
}

double getLowestPositionPrice(ulong _magic) export {
    int      total_positions         = PositionsTotal();
    double   lowest_price            = 0;
    ulong    ticket_with_lowest      = 0;
            
    for(int i = 0; i < total_positions; i++) {
        CPositionInfo  _pos;
        if(_pos.SelectByIndex(i) && _pos.Magic() == _magic) {
            double _entry_price = _pos.PriceOpen();
            if(_entry_price < lowest_price || lowest_price == 0) {
                lowest_price       = _entry_price;
                ticket_with_lowest = _pos.Ticket();
            }
        }
    }
    
    return lowest_price;
}

void closePositonByTicket(CTrade &l_trade, ulong _iMagicNumber,ulong param_ticket){
   
    l_trade.SetExpertMagicNumber(_iMagicNumber);
    int total_positions = PositionsTotal();
    bool has_position = false;
    for(int i = total_positions-1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(param_ticket == ticket ) {
            l_trade.PositionClose(param_ticket);
            has_position = true;
        }
    }
    
    if(has_position) PrintFormat("[%d] [%d]  Closing  positions by ticket",_iMagicNumber,param_ticket);
   

}

bool IsMarketOpen( ){
 
   return allowed_by_hour("09:00:00", "18:00:00");
   //return(SymbolInfoInteger(_param_symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_FULL);
      
      
   
}