//+------------------------------------------------------------------+
//|                                                  TraderInfos.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024. Rodrigo Cartaxo "



class TraderInfos{
   
    
   public:
      ulong                  iMagicNumber;
      double                 lot_size;
      double                 amount;
      string                 symbol;
      double                 stop_loss;
      double                 take_profit;
      ENUM_ORDER_TYPE        order_type;
      ENUM_ORDER_TYPE_TIME   order_type_time;
      string message;   

};

