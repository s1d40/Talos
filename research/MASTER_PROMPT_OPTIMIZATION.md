# MASTER PROMPT: Auditoria e Evolução do Algoritmo OBS1DIAN AI

Este prompt foi desenhado para ser inserido em uma IA de Deep Research (como o próprio Deep Research do ChatGPT ou Gemini Ultra) para realizar uma **Engenharia Reversa e Otimização Estrutural** do nosso robô.

---

**Persona:** Você é um Desenvolvedor Sênior de HFT (High Frequency Trading) e Quant Researcher em um Fundo Hedge Proprietário.

**Objetivo:** Analisar a arquitetura atual do robô **OBS1DIAN AI**, identificar falhas na lógica de execução (baseado em resultados recentes) e propor melhorias de código e matemática para a versão v6.0.

## 1. Arquitetura Atual do Sistema (O "Paciente")

O OBS1DIAN AI opera em MQL5 com uma arquitetura modular. Abaixo estão os parâmetros e lógicas centrais que você deve analisar:

### A. Módulos de Entrada (Sinais)
1.  **Warrior Mode (Momentum/Scalping):**
    *   *Lógica:* Baseado em Ross Cameron. Busca rompimentos a favor da tendência acima da VWAP e EMA9.
    *   *Problema Atual:* "Liquidez de Topo". O robô entra atrasado na euforia (chasing) e toma stop no pullback imediato (Exemplo recente: prejuízo em BIIB e LLY).
    *   *Dúvida:* Como implementar um filtro de "Distância da VWAP" ou "Volume de Exaustão" para evitar comprar o topo?
2.  **KAMA Trend (Adaptive):**
    *   *Lógica:* Kaufman Adaptive Moving Average. Entra nos pullbacks a favor da inclinação da KAMA.
    *   *Problema:* "Whipsaw" (Violino). Em mercados laterais com alta volatilidade, ele é estopado antes da tendência seguir.
3.  **Mean Reversion (Contra-Tendência):**
    *   *Lógica:* RSI < 30 (ou < 15 em crash) + Toque na Banda de Bollinger.
    *   *Problema:* "Catching a Falling Knife". Entra cedo demais em dias de liquidação forçada (Ex: Cripto caindo 10%).

### B. Gestão de Risco & Segurança (O "Escudo")
1.  **Circuit Breaker (Safety Threshold):**
    *   *Regra:* Bloqueia compras se o ativo caiu > `InpSafetyThreshold` (ex: 1.5% ou 5.0%) no dia.
    *   *Falha:* O filtro fixo ignora a volatilidade implícita do ativo. 5% para Cripto é ruído; 5% para Forex é cisne negro.
2.  **Anti-Churning (Cooldown):**
    *   *Regra:* `InpCooldownSeconds` (900s). Espera 15 min após um trade fechar para abrir outro.
    *   *Status:* Implementado para evitar o desastre do USDJPY (abre/fecha em segundos).
3.  **Zombie Killer:**
    *   *Regra:* Fecha o trade se ficar aberto > 4 horas sem lucro.
4.  **Trailing Stop ATR:**
    *   *Regra:* Stop move a favor do preço baseado em `InpATRMult` (atualmente 3.5x).

### C. Alavancagem Convexa (Novo)
1.  **Pyramiding:**
    *   *Lógica:* Adiciona posições vencedoras a cada `InpPyramidStepATR` (1.5x ATR).
    *   *Risco:* Ainda não validado em conta real.

---

## 2. Histórico de Traumas (Estudos de Caso para Otimização)

Use estes eventos reais para calibrar suas sugestões:
*   **Caso BIIB (09/Fev/26):** O robô comprou a máxima do dia três vezes seguidas no Warrior Mode. *Diagnóstico:* Falta de filtro de exaustão de volume.
*   **Caso USDJPY (04/Fev/26):** O robô fez "Churning" (Overtrading), perdendo dinheiro apenas no spread. *Solução Aplicada:* Cooldown. *Dúvida:* Existe solução algorítmica melhor que apenas "esperar tempo"?
*   **Caso Oracle (ORCL):** Alta de 10%. O robô precisa de um modo "Trend Following" que não saia cedo demais (Trailing Stop muito apertado).

---

## 3. Missão de Pesquisa (O Que Eu Preciso de Você)

Pesquise e forneça soluções concretas (preferencialmente lógica de pseudocódigo ou MQL5) para:

1.  **Otimização do Warrior Mode:**
    *   Como detectar "Clímax de Compra" no M1/M5 para impedir o robô de comprar um topo óbvio? (Ex: RSI M1 > 90 + Desvio da VWAP > 3 Sigma).
    *   Pesquise: *"Algorithmic rules to filter false breakouts in momentum strategies"*.

2.  **Circuit Breaker Dinâmico (Adaptive Threshold):**
    *   Em vez de um % fixo (1.5%), como podemos usar o ATR ou a Volatilidade Histórica (HV) para definir se o movimento do dia é "Ruído" ou "Crash"?
    *   Quero uma fórmula para calcular o `InpSafetyThreshold` automaticamente na abertura do mercado.

3.  **Filtro de Tendência KAMA vs. Ruído:**
    *   A KAMA atual (9, 2, 30) é padrão. Existem parâmetros otimizados para o mercado de 2026 (Alta Volatilidade / IA Driven)?
    *   Pesquise: *"KAMA efficiency ratio filters for high volatility markets"*.

4.  **Integração Macro (Scanner The Black Mirror):**
    *   Como o robô pode usar o "RVol" (Volume Relativo) que vem do Scanner para ajustar o tamanho da mão (Lot Size)?
    *   *Hipótese:* Se RVol > 3.0x (Institucional), aumentar Take Profit para 5x ATR?

**Saída Esperada:**
Um relatório técnico com a "Blueprint v6.0" do OBS1DIAN, contendo novas regras lógicas para substituir as falhas atuais.
