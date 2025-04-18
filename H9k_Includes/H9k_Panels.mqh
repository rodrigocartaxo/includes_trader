//+------------------------------------------------------------------+
//|                                                   H9k_Panels.mqh |
//|                                              H9k Trading Systems |
//|                               https://www.youtube.com/@h9ktrades |
//+------------------------------------------------------------------+
#property copyright "H9k Trading Systems"
#property link      "https://www.youtube.com/@h9ktrades"

//+------------------------------------------------------------------+
//| Initialize MT5 Panel                                             |
//| Call it OnInit                                                   |
//+------------------------------------------------------------------+
bool createPanel(int x, int y)
{
    if(MQLInfoInteger(MQL_TESTER)) {
        return true;
    }
    
    string name = "panel_comments";

    if(ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0)) {
        ObjectSetInteger(0,name,OBJPROP_XDISTANCE,5); // Distância da borda
        ObjectSetInteger(0,name,OBJPROP_YDISTANCE,30);
        ObjectSetInteger(0,name,OBJPROP_XSIZE, x); // Tamanho das cordernadas do painel eixo X
        ObjectSetInteger(0,name,OBJPROP_YSIZE, y); // Eixo Y
        ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'22,44,44'); // Cor de fundo
        ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0,name,OBJPROP_CORNER, CORNER_LEFT_UPPER); // Referência de posicionamento (borda superior esquerda)
        ObjectSetInteger(0,name,OBJPROP_COLOR, C'22,44,44'); // Cor da borda
        ObjectSetInteger(0,name,OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0,name,OBJPROP_WIDTH, 1);
        ObjectSetInteger(0,name,OBJPROP_BACK, false); // Força painel para frente do gráfico
        ObjectSetInteger(0,name,OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0,name,OBJPROP_SELECTED, false);
        ObjectSetInteger(0,name,OBJPROP_HIDDEN, true);
        ObjectSetInteger(0,name,OBJPROP_ZORDER,0);
    } else
        return false;
    
    Sleep(200); // Pausa para processar o desenho do fundo do painel
    ChartRedraw(); // Força uma atualização do desenho, garantindo o fundo desenhado antes dos objetos
    
    return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void populatePanel(string &l_items[], string &l_values[])
{
    if(MQLInfoInteger(MQL_TESTER)) {
        return;
    }
    for(int i=0; i < ArraySize(l_items); i++) {
        string i_name = "panel_item_" + string(i);
        if(ObjectCreate(0, i_name, OBJ_LABEL, 0, 0, 0)) {
            ObjectSetInteger(0, i_name, OBJPROP_COLOR, clrSnow); // Cor do texto dos parâmetros
            ObjectSetInteger(0, i_name, OBJPROP_XDISTANCE, 15); // padding x
            ObjectSetInteger(0, i_name, OBJPROP_YDISTANCE, 35 + (i*18)); // Quebras ed linha
            ObjectSetInteger(0, i_name, OBJPROP_FONTSIZE, 12); // font size
            ObjectSetString (0, i_name, OBJPROP_FONT, "Calibri"); // font type
            ObjectSetString (0, i_name, OBJPROP_TEXT, l_items[i]); // text
            ObjectSetInteger(0, i_name, OBJPROP_HIDDEN, true);
            ObjectSetInteger(0, i_name, OBJPROP_BACK, false);
        } else
            return;

        string i_data = "panel_data_" + (string)i;

        if(ObjectCreate(0,i_data,OBJ_LABEL,0,0,0)) {
            ObjectSetInteger(0,i_data,OBJPROP_COLOR,clrGray);
            ObjectSetInteger(0,i_data,OBJPROP_XDISTANCE, 120); // Distânciando mais da borda, garantido que ficará lada a lado
            ObjectSetInteger(0,i_data,OBJPROP_YDISTANCE, 35 + (i*18)); // Pulando uma linha a cada ciclo do loop
            ObjectSetInteger(0,i_data,OBJPROP_FONTSIZE, 12);
            ObjectSetString (0, i_name, OBJPROP_FONT, "Calibri"); // font type
            ObjectSetString(0,i_data,OBJPROP_TEXT, l_values[i]);
            ObjectSetInteger(0,i_data,OBJPROP_HIDDEN,true);
            ObjectSetInteger(0,i_data,OBJPROP_BACK,false);
        } else
            return;

    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void destroyPanel(void)
{
    if(MQLInfoInteger(MQL_TESTER)) {
        return;
    }
    ObjectsDeleteAll(0,"panel_",0,-1);
}
//+------------------------------------------------------------------+
