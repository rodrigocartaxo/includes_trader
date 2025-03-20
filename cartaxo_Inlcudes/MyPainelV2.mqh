//+------------------------------------------------------------------+
//|                                                  MyPainelV2.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Rodrigo Cartaxo."

#include <Trade\Trade.mqh>
#include <.\H9k_Includes\H9k_YT_libs_3.mqh>
#include <CommonParams.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
#include <Controls\Button.mqh>
#include <Controls\Defines.mqh>

#ifndef CONTROLS_FONT_NAME
#ifndef CONTROLS_DIALOG_COLOR_CLIENT_BG
#define CONTROLS_FONT_NAME                "Consolas"
#define CONTROLS_DIALOG_COLOR_CLIENT_BG   C'0X20,0X20,0X20'
#endif
#endif

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== Panel Inputs ====";
static input int inPanelWidth            = 260;
static input int inPanelHeigth           = 300;  // Increased height for tabs
static input int inPanelFontSize         = 10;
static input color inPanelTxtColor       = clrBlack;
static input color inPanelTxtInfoColor   = clrBlue;

#define MAX_TABS 10

//+------------------------------------------------------------------+
//| Class MyPainel                                                   |         
//+------------------------------------------------------------------+
class MyPainel : public CAppDialog {
private:
    // Tab controls
    CButton        m_tabButtons[MAX_TABS];
    int            m_currentTab;
    int            m_numTabs;
    
    // Labels for each tab
    CLabel         m_status[MAX_TABS];
    CLabel         m_magicNumber[MAX_TABS];
    CLabel         m_open[MAX_TABS];
    CLabel         m_daily[MAX_TABS];
    CLabel         m_week[MAX_TABS];
    CLabel         m_month[MAX_TABS];
    
    // Info labels for each tab
    CLabel         info_status[MAX_TABS];
    CLabel         info_magicNumber[MAX_TABS];
    CLabel         info_open[MAX_TABS];
    CLabel         info_daily[MAX_TABS];
    CLabel         info_week[MAX_TABS];
    CLabel         info_month[MAX_TABS];
    
    // Common button
    CButton        m_bAction;   
    
    CTrade         cTrade;
    CommonParams   params;
    
    ulong          magicNumbers[MAX_TABS];
    
    bool CreateTabs();
    bool CreateTabContent();
    void UpdateTabContent(int tabIndex);
    bool CheckInputs();
    void HideAllTabContent();
    void ShowTabContent(int tabIndex);
    string GetStatusText(int tabIndex);
    
public:
                     MyPainel();
                    ~MyPainel();
    bool             OnInit(const ulong &magicNumbersArray[]);
    void             Update(string texto);
    string           getShortCurrencies();
    virtual void     PanelChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void MyPainel::MyPainel(void) {
    m_currentTab = 0;
    m_numTabs = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void MyPainel::~MyPainel(void) {
    Destroy(); // This will clean up all controls
}

//+------------------------------------------------------------------+
//| Initialize Panel                                                 |
//+------------------------------------------------------------------+
bool MyPainel::OnInit(const ulong &magicNumbersArray[]) {
    m_numTabs = ArraySize(magicNumbersArray);
    if(m_numTabs > MAX_TABS) {
        Print("Too many magic numbers. Maximum allowed: ", MAX_TABS);
        return false;
    }
    
    ArrayCopy(magicNumbers, magicNumbersArray);
    
    if(!CheckInputs()) return false;
    
    // Create main dialog
    if(!Create(NULL, MQLInfoString(MQL_PROGRAM_NAME), 0, 0, 0, inPanelWidth, inPanelHeigth))
        return false;
    
    // Create tabs and content
    if(!CreateTabs()) return false;
    if(!CreateTabContent()) return false;
    
    // Initialize common parameters
    if(!params.OnInit()) return false;
    
    // Initial update
    UpdateTabContent(0);
    
    return true;
}

//+------------------------------------------------------------------+
//| Create Tabs                                                      |
//+------------------------------------------------------------------+
bool MyPainel::CreateTabs() {
    int tabWidth = (inPanelWidth - 40) / m_numTabs;
    
    // Create tab buttons
    for(int i = 0; i < m_numTabs; i++) {
        if(!m_tabButtons[i].Create(0, "Tab" + string(i), 0, 20 + (i * tabWidth), 10, tabWidth - 5, 25)) 
            return false;
        if(!m_tabButtons[i].Text("EA " + string(i + 1))) return false;
        if(!m_tabButtons[i].Color(clrWhite)) return false;
        if(!m_tabButtons[i].ColorBackground(i == 0 ? clrBlue : clrGray)) return false;
        if(!m_tabButtons[i].FontSize(inPanelFontSize)) return false;
        if(!Add(&m_tabButtons[i])) return false;
    }
    
    // Create common action button
    if(!m_bAction.Create(0, "bAction", 0, 20, inPanelHeigth - 40, inPanelWidth - 40, 30)) return false;
    if(!m_bAction.Text("Stop")) return false;
    if(!m_bAction.Color(clrWhite)) return false;
    if(!m_bAction.ColorBackground(clrDarkGray)) return false;
    if(!m_bAction.FontSize(inPanelFontSize)) return false;
    if(!Add(&m_bAction)) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Create Tab Content                                               |
//+------------------------------------------------------------------+
bool MyPainel::CreateTabContent() {
    for(int i = 0; i < m_numTabs; i++) {
        // Create labels
        if(!m_status[i].Create(0, "status_" + string(i), 0, 20, 45, 100, 20)) return false;
        if(!m_magicNumber[i].Create(0, "magic_" + string(i), 0, 20, 65, 100, 20)) return false;
        if(!m_open[i].Create(0, "open_" + string(i), 0, 20, 85, 100, 20)) return false;
        if(!m_daily[i].Create(0, "daily_" + string(i), 0, 20, 105, 100, 20)) return false;
        if(!m_week[i].Create(0, "week_" + string(i), 0, 20, 125, 100, 20)) return false;
        if(!m_month[i].Create(0, "month_" + string(i), 0, 20, 145, 100, 20)) return false;
        
        if(!info_status[i].Create(0, "info_status_" + string(i), 0, 140, 45, 100, 20)) return false;
        if(!info_magicNumber[i].Create(0, "info_magic_" + string(i), 0, 140, 65, 100, 20)) return false;
        if(!info_open[i].Create(0, "info_open_" + string(i), 0, 140, 85, 100, 20)) return false;
        if(!info_daily[i].Create(0, "info_daily_" + string(i), 0, 140, 105, 100, 20)) return false;
        if(!info_week[i].Create(0, "info_week_" + string(i), 0, 140, 125, 100, 20)) return false;
        if(!info_month[i].Create(0, "info_month_" + string(i), 0, 140, 145, 100, 20)) return false;
        
        // Set label texts
        m_status[i].Text("Status:");
        m_magicNumber[i].Text("Magic Number:");
        m_open[i].Text("Open Result:");
        m_daily[i].Text("Daily Result:");
        m_week[i].Text("Week Result:");
        m_month[i].Text("Month Result:");
        
        // Set colors
        m_status[i].Color(inPanelTxtColor);
        m_magicNumber[i].Color(inPanelTxtColor);
        m_open[i].Color(inPanelTxtColor);
        m_daily[i].Color(inPanelTxtColor);
        m_week[i].Color(inPanelTxtColor);
        m_month[i].Color(inPanelTxtColor);
        
        info_status[i].Color(inPanelTxtInfoColor);
        info_magicNumber[i].Color(inPanelTxtInfoColor);
        info_open[i].Color(inPanelTxtInfoColor);
        info_daily[i].Color(inPanelTxtInfoColor);
        info_week[i].Color(inPanelTxtInfoColor);
        info_month[i].Color(inPanelTxtInfoColor);
        
        // Add all controls
        Add(&m_status[i]);
        Add(&m_magicNumber[i]);
        Add(&m_open[i]);
        Add(&m_daily[i]);
        Add(&m_week[i]);
        Add(&m_month[i]);
        
        Add(&info_status[i]);
        Add(&info_magicNumber[i]);
        Add(&info_open[i]);
        Add(&info_daily[i]);
        Add(&info_week[i]);
        Add(&info_month[i]);
        
        // Hide all tabs except the first one
        if(i != 0) {
            HideAllTabContent();
            ShowTabContent(0);
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Hide All Tab Content                                             |
//+------------------------------------------------------------------+
void MyPainel::HideAllTabContent() {
    for(int i = 0; i < m_numTabs; i++) {
        m_status[i].Hide();
        m_magicNumber[i].Hide();
        m_open[i].Hide();
        m_daily[i].Hide();
        m_week[i].Hide();
        m_month[i].Hide();
        
        info_status[i].Hide();
        info_magicNumber[i].Hide();
        info_open[i].Hide();
        info_daily[i].Hide();
        info_week[i].Hide();
        info_month[i].Hide();
    }
}

//+------------------------------------------------------------------+
//| Show Tab Content                                                 |
//+------------------------------------------------------------------+
void MyPainel::ShowTabContent(int tabIndex) {
    if(tabIndex >= m_numTabs) return;
    
    m_status[tabIndex].Show();
    m_magicNumber[tabIndex].Show();
    m_open[tabIndex].Show();
    m_daily[tabIndex].Show();
    m_week[tabIndex].Show();
    m_month[tabIndex].Show();
    
    info_status[tabIndex].Show();
    info_magicNumber[tabIndex].Show();
    info_open[tabIndex].Show();
    info_daily[tabIndex].Show();
    info_week[tabIndex].Show();
    info_month[tabIndex].Show();
}

//+------------------------------------------------------------------+
//| Update Tab Content                                               |
//+------------------------------------------------------------------+
void MyPainel::UpdateTabContent(int tabIndex) {
    if(tabIndex >= m_numTabs) return;
    
    cTrade.SetExpertMagicNumber(magicNumbers[tabIndex]);
    
    info_status[tabIndex].Text(GetStatusText(tabIndex));
    info_magicNumber[tabIndex].Text(string(magicNumbers[tabIndex]));
    info_open[tabIndex].Text(string(OpenResult(magicNumbers[tabIndex])));
    info_daily[tabIndex].Text(string(DailyResult(magicNumbers[tabIndex])));
    info_week[tabIndex].Text(string(weeklyResult(magicNumbers[tabIndex])));
    info_month[tabIndex].Text(string(monthlyResult(magicNumbers[tabIndex])));
}

//+------------------------------------------------------------------+
//| Get Status Text                                                  |
//+------------------------------------------------------------------+
string MyPainel::GetStatusText(int tabIndex) {
    if(!i24h && !allowed_by_hour(iHoraIni, iHoraFim)) {
        GlobalVariableSet("trade_not_available_" + string(magicNumbers[tabIndex]), true);
        return "Sleeping.....";
    }
    else if(!i24h && !allowed_by_hour(iHoraIni, iHoraClose)) {
        GlobalVariableSet("trade_not_available_" + string(magicNumbers[tabIndex]), true);
        return "Blocked Order.....";
    }
    else {
        GlobalVariableDel("trade_not_available_" + string(magicNumbers[tabIndex]));
        return "Running.....";
    }
}

//+------------------------------------------------------------------+
//| Check Inputs                                                     |
//+------------------------------------------------------------------+
bool MyPainel::CheckInputs(void) {
    if(inPanelWidth <= 0) {
        Print("Panel Width <= 0");
        return false;
    }
    if(inPanelHeigth <= 0) {
        Print("Panel Height <= 0");
        return false;
    }
    if(inPanelFontSize <= 0) {
        Print("Panel FontSize <= 0");
        return false;
    }
    return true;
}

//+------------------------------------------------------------------+
//| Event Handlers                                                   |
//+------------------------------------------------------------------+
void MyPainel::PanelChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    ChartEvent(id, lparam, dparam, sparam);
    
    if(id == CHARTEVENT_OBJECT_CLICK) {
        // Handle tab switching
        for(int i = 0; i < m_numTabs; i++) {
            if(sparam == "Tab" + string(i)) {
                HideAllTabContent();
                ShowTabContent(i);
                m_currentTab = i;
                
                // Update tab colors
                for(int j = 0; j < m_numTabs; j++) {
                    m_tabButtons[j].ColorBackground(j == i ? clrBlue : clrGray);
                }
                
                UpdateTabContent(i);
      }   
   }
  }       
                
}