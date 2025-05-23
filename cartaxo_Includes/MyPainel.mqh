//+------------------------------------------------------------------+
//|                                                     MyPainel.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Rodrigo Cartaxo."
//+------------------------------------------------------------------+
//| Includes 1                                                       |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <.\Personal\H9k_Includes\H9k_YT_libs_3.mqh>
#include <.\Personal\cartaxo_Includes\CommonParams.mqh>



//+------------------------------------------------------------------+
//| Define statements                                                |
//+------------------------------------------------------------------+
#ifndef CONTROLS_FONT_NAME
#ifndef CONTROLS_DIALOG_COLOR_CLIENT_BG
#define CONTROLS_FONT_NAME                "Consolas"
#define CONTROLS_DIALOG_COLOR_CLIENT_BG   C'0X20,0X20,0X20'
#endif
#endif
//+------------------------------------------------------------------+
//| Includes 2                                                       |
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
#include <Controls\Button.mqh>
#include <Controls\Defines.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== Panel Inputs ====";
static input int inPanelWidth            = 260;
static input int inPanelHeigth           = 260;
static input int inPanelFontSize         = 10;
static input color inPanelTxtColor       = clrBlack;
static input color inPanelTxtInfoColor   = clrBlue;

//+------------------------------------------------------------------+
//| Class MyPainel                                                   |         
//+------------------------------------------------------------------+



class MyPainel:public CAppDialog{
   
   private:
      //lables
      CLabel m_linput;
      
      CLabel m_status;
      CLabel info_status;
      
      CLabel m_magic_number;
      CLabel info_magic_number;
      
      CLabel m_open;
      CLabel info_open;
      
      CLabel m_daily;
      CLabel info_daily;
      
      CLabel m_week;
      CLabel info_week;
      
      CLabel m_moth;
      CLabel info_moth;
      
            
      //buttons
      CButton m_bAction;   
      //
      CTrade cTrade;
      CommonParams params;
      
      
      
      bool CheckInputs();
      bool CreatePanel();
      ulong magicNumber;
      
     
  
      
      
   public:
      
      
      void MyPainel();
      void ~MyPainel();
      bool OnInit(ulong magicNumber);
      void Update(string texto);
      bool OnTick();
      void OnTimer();
      void getShortCurrencies(string &shortCurrencies[]);
      
      void PanelChartEvent(const int id, const long &param,const double &dparam, const string &sparam);

};
void MyPainel::MyPainel(void){}

void MyPainel::~MyPainel(void){}

void  MyPainel::getShortCurrencies(string &shortCurrencies[]){
   
   params.getShortCurrencies(shortCurrencies);
}

bool MyPainel::OnInit(ulong magicNumberParam){

  magicNumber = magicNumberParam;
  cTrade.SetExpertMagicNumber(magicNumber);

   if(! CheckInputs()){return false;}
   
   if(! CreatePanel()){return false;}
   
   if(! params.OnInit()){return false;}
   
    if (!i24h && !allowed_by_hour(iHoraIni, iHoraFim)) {
        info_status.Text("Slepping .....");
        closeAllPositions(cTrade,  magicNumber);
        closeAllOpenOrders(cTrade,  magicNumber);
        GlobalVariableSet("trade_not_available",true);        
    }else if (!i24h && !allowed_by_hour(iHoraIni, iHoraClose))  {
         GlobalVariableSet("trade_not_available_"+(string)magicNumber,true);
         info_status.Text("Blocked Order ..... ");
    }else{
         GlobalVariableDel("trade_not_available");
         info_status.Text("Running ..... ");
    } 
    
   
    info_open.Text((string)OpenResult(magicNumber));                 
    info_daily.Text((string)DailyResult(magicNumber));
    info_week.Text((string)weeklyResult(magicNumber));
    info_moth.Text((string)monthlyResult(magicNumber));
    return true;

}
bool MyPainel::OnTick(){
    info_open.Text((string)OpenResult( magicNumber));
    info_daily.Text((string)DailyResult( magicNumber));
    info_week.Text((string)weeklyResult( magicNumber));
    info_moth.Text((string)monthlyResult( magicNumber));
    if (!i24h && !allowed_by_hour(iHoraIni, iHoraFim)) {
        info_status.Text("Slepping .....");
        closeAllPositions(cTrade,  magicNumber);
        closeAllOpenOrders(cTrade,  magicNumber);
        GlobalVariableSet("trade_not_available_"+(string)magicNumber,true);
        ChartRedraw();        
        return false;
    }else if (!i24h && !allowed_by_hour(iHoraIni, iHoraClose))  {
         GlobalVariableSet("trade_not_available_"+(string)magicNumber,true);
         info_status.Text("Blocked Order ..... ");        
         return false;
    }else{
         info_status.Text("Running .....");
         GlobalVariableDel("trade_not_available_"+(string)magicNumber);
         ChartRedraw();
         return true;
    } 
      
}
void MyPainel::OnTimer(){

   
   info_open.Text((string)OpenResult( magicNumber));
   info_daily.Text((string)DailyResult( magicNumber));
   info_week.Text((string)weeklyResult( magicNumber));
   info_moth.Text((string)monthlyResult( magicNumber));
    ChartRedraw();

}



bool MyPainel::CheckInputs(void){

   if (inPanelWidth <=0){
      Print("Panel Width <=0  ");
      return false;
   }
   if (inPanelHeigth <=0){
      Print("Panel Heigth <=0  ");
      return false;
   }
   if (inPanelFontSize <=0){
      Print("Panel FontSize <=0  ");
      return false;
   }

   return true;

}
bool MyPainel::CreatePanel(){
 
  
   Create(NULL, MQLInfoString(MQL_PROGRAM_NAME)  ,0,0,0,inPanelWidth,inPanelHeigth);
   
   m_linput.Create(NULL,"linput",0,20,10,1,1);
   m_linput.Text("=== Inptus ===");
   m_linput.Color(clrBlueViolet);
   m_linput.FontSize(inPanelFontSize);
   Add(m_linput);
   
   m_status.Create(NULL,"m_status",0,20,30,1,1);
   m_status.Text("Status.:");
   m_status.Color(inPanelTxtColor);
   m_status.FontSize(inPanelFontSize);
   Add(m_status);
   
   info_status.Create(NULL,"info_status_status",0,140,30,1,1);
   info_status.Text(" ");
   info_status.Color(inPanelTxtInfoColor);
   info_status.FontSize(inPanelFontSize);
   Add(info_status);
   
   
   m_magic_number.Create(NULL,"m_magic_number",0,20,50,1,1);
   m_magic_number.Text("Magic Number.:    ");
   m_magic_number.Color(inPanelTxtColor);
   m_magic_number.FontSize(inPanelFontSize);
    Add(m_magic_number);
      
   info_magic_number.Create(NULL,"info_magic_number",0,140,50,1,1);
   info_magic_number.Text(DoubleToString( magicNumber,0));
   info_magic_number.Color(inPanelTxtInfoColor);
   info_magic_number.FontSize(inPanelFontSize);
    Add(info_magic_number);
   
   m_open.Create(NULL,"m_open",0,20,70,1,2);
   m_open.Text("Open Result.:");
   m_open.Color(inPanelTxtColor);
   m_open.FontSize(inPanelFontSize);
    Add(m_open);
   
   info_open.Create(NULL,"info_open",0,140,70,1,1);
   info_open.Text("");
   info_open.Color(inPanelTxtInfoColor);
   info_open.FontSize(inPanelFontSize);
    Add(info_open);
   
   
   m_daily.Create(NULL,"m_daily",0,20,90,1,2);
   m_daily.Text("Daily Result.:");
   m_daily.Color(inPanelTxtColor);
   m_daily.FontSize(inPanelFontSize);
    Add(m_daily);
   
   info_daily.Create(NULL,"info_daily",0,140,90,1,1);
   info_daily.Text("");
   info_daily.Color(inPanelTxtInfoColor);
   info_daily.FontSize(inPanelFontSize);
    Add(info_daily);
   
   m_week.Create(NULL,"m_week",0,20,110,1,1);
   m_week.Text("Week Result.:");
   m_week.Color(inPanelTxtColor);
   m_week.FontSize(inPanelFontSize);
    Add(m_week);
   
   info_week.Create(NULL,"info_week",0,140,110,1,1);
   info_week.Text("ddd");
   info_week.Color(inPanelTxtInfoColor);
   info_week.FontSize(inPanelFontSize);
    Add(info_week);
   
   m_moth.Create(NULL,"m_moth",0,20,130,1,1);
   m_moth.Text("Moth Result.:");
   m_moth.Color(inPanelTxtColor);
   m_moth.FontSize(inPanelFontSize);
    Add(m_moth);
   
   info_moth.Create(NULL,"info_moth",0,140,130,1,1);
   info_moth.Text("");
   info_moth.Color(inPanelTxtInfoColor);
   info_moth.FontSize(inPanelFontSize);
    Add(info_moth);
   
   
   m_bAction.Create(NULL,"bAction",0,20,170,230,200);
   m_bAction.Text("Stop");
   m_bAction.Color(clrWhite);
   m_bAction.ColorBackground(clrDarkGray);
   m_bAction.FontSize(inPanelFontSize);
    Add(m_bAction);
   

   if(!Run()){Print("Failed to run painel"); return false; }

   ChartRedraw();
    
   return true;

}
void MyPainel::PanelChartEvent(const int id, const long &param,const double &dparam, const string &sparam){

   ChartEvent(id,param,dparam,sparam);
    
   
   if (id == CHARTEVENT_OBJECT_CLICK && sparam == "bAction" ){
         info_status.Text("Close all Postions....");
         cTrade.SetExpertMagicNumber( magicNumber);
         closeAllPositions(cTrade,  magicNumber);
   }
   
}

void MyPainel::Update(string texto){

   info_status.Text(texto);
   ChartRedraw();


}




