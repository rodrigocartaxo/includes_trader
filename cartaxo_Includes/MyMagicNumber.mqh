//+------------------------------------------------------------------+
//|                                                MyMagicNumber.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"


class MyMagicNumber {

   public:
     ulong calculate(string strategy , string currency);
     ulong magicNumber; 

};

ulong MyMagicNumber::calculate(string strategy , string currency){

   string combined = strategy + currency;
   
    for (int i = 0; i < StringLen(combined); i++){
      int charCode = combined[i];
      magicNumber += charCode * (i + 1);
   }
   magicNumber =   MathAbs(magicNumber % 2147483647);
   return magicNumber  ; 

}