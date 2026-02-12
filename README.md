# **OBS1DIAN AI - Institutional Quantamental Trading**
> **A Fusão entre Inteligência Macro, Execução Algorítmica de Elite e Isolamento de Dados v6.1.**

![Version](https://img.shields.io/badge/Version-v6.1-green.svg)
![Status](https://img.shields.io/badge/Intelligence-Isolated-blue.svg)
![License](https://img.shields.io/badge/License-Proprietary-red.svg)
![Brand](https://img.shields.io/badge/Brand-S1D--Obsidian-black.svg)

## **1. Visão Geral**
O **OBS1DIAN AI** é um Expert Advisor de elite desenvolvido para o MetaTrader 5, operando sob o conceito de "Ordem através do Caos". Na versão **v6.0**, o sistema evoluiu de uma lógica puramente reativa para uma arquitetura preditiva e probabilística, integrando **Física de Mercado (Entropia)** e **Microestrutura (RVol)** para proteger o capital em regimes de alta incerteza.

## **2. Arquitetura v6.0: O "Governador"**
Diferente de robôs tradicionais que operam em qualquer condição, o OBS1DIAN v6.0 "pede permissão" matemática antes de operar.

### **A. Filtros de Regime (Safety Core)**
*   **Entropia de Shannon:** Mede o caos do mercado. Se a entropia normalizada > 0.90 (Ruído Puro), o robô entra em **Standby**, evitando overtrading em mercados laterais imprevisíveis.
*   **Expoente de Hurst:** Identifica a natureza da série temporal.
    *   `H > 0.5`: Mercado Persistente (Tendência) -> Ativa KAMA/Warrior.
    *   `H < 0.5`: Mercado Anti-Persistente (Reversão) -> Ativa Mean Reversion.
*   **Circuit Breaker Dinâmico:** Limite de segurança diário (%) calculado com base na Volatilidade Histórica (HV), substituindo limites fixos obsoletos.

### **B. Módulos de Ataque (Sinais)**
*   **Warrior Mode (v6.0):** Estratégia de Momentum (Ross Cameron). Agora inclui filtro de **Clímax de Compra** (Bandas de VWAP + 3 Sigma) para evitar a compra de topos e exige validação de Volume Relativo (RVol > 2.5x).
*   **KAMA Trend (Adaptive):** Média Móvel Adaptativa de Kaufman com filtro de eficiência (ER) para evitar "Whipsaws" (violinos) em consolidações.
*   **Mean Reversion (Sniper):** Lógica de "Faca Caindo" aprimorada. Só compra reversões se houver *Stopping Volume* confirmado, prevenindo entradas prematuras em crashes.

### **C. THE BLACK MIRROR (Scanner Tático)**
*   **App Mode Dashboard:** Interface dedicada que limpa o gráfico e transforma o MetaTrader em um terminal de varredura visual.
*   **Time-Segmented RVol:** Compara o volume atual com a média histórica *daquele horário específico*, isolando anomalias reais de fluxo institucional.
*   **Impact Override:** Detecta movimentos massivos em ativos de baixa liquidez (ex: Cripto/Exóticos).

## **3. Gestão de Risco Sniper**
*   **Anti-Churning (Cooldown):** Timer obrigatório (15min) após fechamento de trades para evitar loops de abertura/fechamento em ativos com spread baixo (ex: USDJPY).
*   **Stop Loss Adaptativo (ATR):**
    *   *Baixa Volatilidade:* 1.5x a 2.0x (Scalping).
    *   *Alta Volatilidade:* 3.5x a 4.0x (Sobrevivência).
*   **Dynamic Lot Sizing:** Cálculo de lote reverso à volatilidade (Se o risco aumenta, o lote diminui para manter o $ financeiro estável).

## **4. Instalação**
### **Estrutura de Pastas:**
```text
MQL5/
  |-- Experts/
  |     |-- OBS1DIAN.mq5 (Main Bot v6.0)
  |     |-- TheBlackMirror.mq5 (Market Scanner)
  |-- Include/
  |     |-- Obsidian/
  |           |-- Core/ (CEngine.mqh)
  |           |-- Signals/ (Warrior, KAMA, MeanRev)
  |           |-- Risk/ (CRiskManager.mqh)
  |           |-- Utils/ (CMathLib.mqh - *NOVO*, CScanner.mqh)
```

## **5. Roadmap de Desenvolvimento**
- [x] **v5.0:** Rebranding e Circuit Breaker Anti-Crash.
- [x] **v5.2:** Scanner Black Mirror e Warrior Mode.
- [x] **v6.0:** Filtros de Entropia, Hurst e RVol Segmentado.
- [ ] **v6.5:** Integração de Notificações Telegram com Screenshots.
- [ ] **v7.0:** Módulo de Machine Learning (Python/ONNX) para predição de regime.

---
**Desenvolvido por s1d & Gemini AI Engine.**
*© 2026 Project Obsidian. Todos os direitos reservados.*
