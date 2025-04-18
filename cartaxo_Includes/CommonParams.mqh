//+------------------------------------------------------------------+
//|                                                 CommonParams.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Rodrigo Cartaxo."
//+------------------------------------------------------------------+
//| Includes 1                                                       |
//+------------------------------------------------------------------+
#include <.\Personal\H9k_Includes\H9k_YT_libs_3.mqh>

enum ENUM_ON_OFF {
    on  = 1,       // Ligado
    off = 0        // Desligado
};

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== Daytrade Window ===="
input bool   i24h                                = off; //Liga o modo 24h (forex)
input string iHoraIni                            = "09:05:00"; //Hora inicio
input string iHoraClose                          = "16:30:00"; //Hora Block Ordens
input string iHoraFim                            = "17:30:00"; //Hora fim
input double iRangeLotes                         = 0; // Alvancagem Qtd Contratos
input double iStopLossPercent                    = 0.5; // Percentual Stop Loss
input double iTakeProfitPercent                  = 0.2; // Percentual Take Profit
//input double iTriggerTrallingStopPercent         = 0.3; // Percentual Trigger Tralling Stop Loss
//input double iTrallingStopPercent                = 0.2; // Percentual Tralling Stop Loss
//input bool   iEnableTrallingStop                 = true; // Ativar Take Profit
input string currencies                           = "WINJ25,WDOH25"; // Ativos
input ENUM_TIMEFRAMES iTradeTimeFrame             = PERIOD_M1; // Time frame for Trader





class CommonParams {

   public:
     bool OnInit();
     void getShortCurrencies(string &shortCurrencies[]);
     

};


bool CommonParams::OnInit(){
  
    PrintFormat("Init Params");  
  
    return true;

}
string sep = ",";
string V_Currencies[];


void CommonParams::getShortCurrencies(string &shortCurrencies[]){
   ushort sep_code = StringGetCharacter(sep, 0);
   int lengthArray = StringSplit(currencies, sep_code, V_Currencies);

   ArrayResize(shortCurrencies, lengthArray); // Ajusta o tamanho do array de saída

   for (int i = 0; i < lengthArray; i++) {
       shortCurrencies[i] = StringSubstr(V_Currencies[i], 0, 3);
   }

}





