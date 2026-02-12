# **Talos Quantamental - Log de Desenvolvimento e Histórico**

## **1. O Início: Desafios Técnicos**
*   **Data:** 26-28 de Janeiro de 2026.
*   **Ambiente Original:** Linux (Ubuntu) via Wine/Bottles.
*   **Problema Inicial:** Erro "Debugger found" no MT5 devido a versões instáveis do Wine.
*   **Solução:** Downgrade para Wine 10.4 (Staging) e uso de Bottles com permissões de Algo Trading liberadas manualmente.

## **2. Arquitetura do Robô (Project Talos)**
*   **Paradigma:** Programação Orientada a Objetos (POO).
*   **Componentes:**
    *   `ISignal`: Interface para polimorfismo de sinais.
    *   `CEngine`: Orquestrador de ordens e gestão de regime.
    *   `CRiskManager`: Cálculo de lote via % de capital e Stops via ATR.
    *   `CRegimeFilter`: Sensor de ADX para troca automática entre Tendência e Reversão.

## **3. Resultados Operacionais (Validação)**
*   **XAUUSD (Ouro):** 
    *   Teste Inicial: KAMA pura (prejuízo em mercado lateral).
    *   Teste 2: Reversão à Média (Lucro de $803, Fator 1.81).
    *   **Live (Exness):** Recuperação de drawdown com trade Sniper de +$203.
*   **GBPUSD:** Operação de tendência validada.
*   **US500/USOIL:** Operações em andamento com lucro flutuante em 29/01.

## **4. Guia de Configuração (Windows Migration)**
Para rodar o Talos no Windows:
1.  Instale o MT5 da Exness.
2.  Copie a pasta `Include/Hydra` para `MQL5/Include/`.
3.  Copie `Hydra_Professional.mq5` para `MQL5/Experts/`.
4.  **Configuração Sugerida:**
    *   `InpAdaptive`: true
    *   `InpMacroBias`: BIAS_LONG (enquanto o cenário geopolítico for de crise).
    *   `InpRiskPercent`: 1.0%
    *   `InpATRMult`: 2.5 (Proteção para dias de notícias).

## **6. O Renascimento: OBS1DIAN AI**
*   **Data:** 30 de Janeiro de 2026.
*   **Evento Crítico:** Cisne Negro nos Metais (Ouro caiu -8% e Prata -15% em poucas horas).
*   **Ações Técnicas:**
    *   **Rebrand Total:** Projeto 'Hydra' renomeado para **OBS1DIAN AI**. Estrutura de pastas migrada para `Include/Obsidian`.
    *   **The Black Mirror:** Desenvolvimento de um Scanner de Mercado dedicado com Dashboard "App Mode" (tela cheia) e ordenação interativa.
    *   **Safety Circuit Breaker:** Implementação de trava de pânico que bloqueia ordens contra movimentos bruscos (ex: proíbe compras se o preço cair > 1.5% no dia).
    *   **Heartbeat:** Sistema de monitoramento de logs a cada 60 segundos.
*   **Status Financeiro:** Decisão de validar em conta Demo por uma semana enquanto o capital de $100 USD é acumulado via trabalho offline (Uber) para abertura de conta Standard Cent na Exness.

---
*Relatório gerado em 30/01/2026 - Proteção de capital priorizada.*
