//+------------------------------------------------------------------+
//|                                        CDinamicATRMultiplier.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

class CDinamicATRMultiplier {
private:
    double m_multiplicadorBaseSL;     // Multiplicador base Stop Loss
    double m_multiplicadorBaseTP;     // Multiplicador base Take Profit
    
    // Variáveis para rastreamento de volatilidade
    double m_volatilidade;
    double m_volumeMedio;
    
    // Períodos de referência
    datetime m_horarioAbertura;
    datetime m_horarioFechamento;
    
    // Histórico de volatilidade
    double m_historicoVolatilidade[24];
    int m_indiceHistorico;

public:
    CDinamicATRMultiplier() {
        // Valores padrão iniciais
        m_multiplicadorBaseSL = 2.0;
        m_multiplicadorBaseTP = 3.0;
        m_indiceHistorico = 0;
        
        // Configurar horários de referência (adaptável conforme mercado)
        m_horarioAbertura = StringToTime("09:00");
        m_horarioFechamento = StringToTime("17:30");
    }
    
   double CalcularMultiplicadorDinamico(bool ehStopLoss,string symbol) {
        double atr = iATR(symbol, PERIOD_H1, 14);
        long volumeAtual = iVolume(symbol, PERIOD_CURRENT, 0);
        
        double high = iHigh(symbol,PERIOD_CURRENT,0);
        double low = iLow(symbol,PERIOD_CURRENT,0);
        double close = iClose(symbol,PERIOD_CURRENT,0);
        
        // Capturar volatilidade atual
        m_volatilidade = MathAbs(high - low) / close;
        m_volumeMedio = iMA(symbol, 0, 14, 0, MODE_SMA, VOLUME_TICK);
        
        // Ajuste baseado no horário do dia
        double fatorHorario = CalcularFatorHorario();
        
        // Ajuste baseado na volatilidade histórica
        double fatorVolatilidade = CalcularFatorVolatilidade();
        
        // Ajuste baseado no volume
        double fatorVolume = CalcularFatorVolume(volumeAtual, m_volumeMedio);
        
        // Cálculo do multiplicador final
        double multiplicadorFinal;
        if (ehStopLoss) {
            multiplicadorFinal = m_multiplicadorBaseSL 
                                 * fatorHorario 
                                 * fatorVolatilidade 
                                 * fatorVolume;
        } else {
            multiplicadorFinal = m_multiplicadorBaseTP 
                                 * fatorHorario 
                                 * fatorVolatilidade 
                                 * fatorVolume;
        }
        
        // Limitar variação do multiplicador
        multiplicadorFinal = MathMax(1.5, MathMin(multiplicadorFinal, 5.0));
        
        // Armazenar volatilidade no histórico
        ArmazenarVolatilidade(m_volatilidade);
        
        return multiplicadorFinal;
    }    
    
private:
    //+------------------------------------------------------------------+
    //| Fator de ajuste baseado no horário do dia                        |
    //+------------------------------------------------------------------+
    double CalcularFatorHorario() {
        
        datetime horaAtual = TimeCurrent();
        /*string   DTstr     = TimeToString(TimeCurrent(), TIME_DATE);
        datetime lstart    = StringToTime(DTstr + " " + starttime);
        datetime end       = StringToTime(DTstr + " " + endtime);*/

        
        
        // Ajuste mais conservador em horários menos líquidos
        if (horaAtual < m_horarioAbertura || horaAtual > m_horarioFechamento) {
            return 0.8;  // Reduz multiplicadores
        }
        
        // Períodos de maior liquidez/volatilidade
        if (horaAtual >= StringToTime("9:00:00") && horaAtual <= StringToTime("12:00:00")) {
            return 1.2;  // Aumenta um pouco os multiplicadores
        }
        
        return 1.0;  // Valor neutro
    }
    
    double CalcularFatorVolatilidade() {
        double volatilidadeMedia = 0;
        for (int i = 0; i < ArraySize(m_historicoVolatilidade); i++) {
            volatilidadeMedia += m_historicoVolatilidade[i];
        }
        volatilidadeMedia /= ArraySize(m_historicoVolatilidade);
        
        // Comparar volatilidade atual com média histórica
        if (m_volatilidade > volatilidadeMedia * 1.5) {
            return 0.7;  // Reduz multiplicadores em alta volatilidade
        }
        
        if (m_volatilidade < volatilidadeMedia * 0.5) {
            return 1.3;  // Aumenta um pouco em baixa volatilidade
        }
        
        return 1.0;
    }
    
     double CalcularFatorVolume(double volumeAtual, double volumeMedio) {
        if (volumeAtual > volumeMedio * 1.5) {
            return 1.2;  // Volume alto, ajusta para maior volatilidade
        }
        
        if (volumeAtual < volumeMedio * 0.5) {
            return 0.8;  // Volume baixo, mais conservador
        }
        
        return 1.0;
    }
    
    void ArmazenarVolatilidade(double volatilidade) {
        m_historicoVolatilidade[m_indiceHistorico] = volatilidade;
        m_indiceHistorico = (m_indiceHistorico + 1) % ArraySize(m_historicoVolatilidade);
    }
    
 }
    