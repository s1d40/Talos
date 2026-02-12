# **Manual Definitivo de Day Trading de Momentum: A Metodologia e Estratégias de Ross Cameron**

## **Introdução: O Paradigma da Volatilidade e a Microestrutura de Mercado**

No universo dos mercados financeiros, a eficiência é frequentemente o inimigo do lucro rápido. Enquanto investidores institucionais buscam valor intrínseco e estabilidade a longo prazo, o day trader de momentum opera nas franjas da ineficiência, explorando desequilíbrios momentâneos entre oferta e demanda que geram movimentos de preços parabólicos. Este relatório técnico disseca a metodologia operacional de Ross Cameron, fundador da Warrior Trading, cuja abordagem se fundamenta na identificação precisa de ações de baixa capitalização (small caps) e baixo flutuante (low float) que, catalisadas por eventos fundamentais ou técnicos, tornam-se veículos de transferência de riqueza em janelas temporais curtas.1

A premissa central desta "apostila" de estudo não é apenas apresentar regras estáticas, mas elucidar a lógica profunda por trás da volatilidade. O mercado não é um ambiente aleatório quando observado sob a ótica da liquidez e da psicologia de massa. A estratégia de momentum não busca prever o futuro distante, mas reagir a sinais presentes de agressão compradora e exaustão vendedora, utilizando ferramentas de leitura de fluxo (tape reading) e análise técnica acelerada.3

Ao longo deste documento, desconstruiremos os mecanismos de seleção de ativos, a arquitetura das estratégias "Gap and Go" e "Momentum", a ciência da gestão de risco assimétrica e a psicologia necessária para executar operações de alta pressão. O objetivo é fornecer um compêndio exaustivo que sirva como base para a formação de um operador profissional.

## ---

**Parte I: Fundamentos da Seleção de Ativos e a Anatomia do Momentum**

A primeira e mais crítica etapa na rotina de um day trader não é a execução, mas a seleção. A vasta maioria das ações na bolsa de valores (NYSE, NASDAQ, AMEX) não é adequada para o trading de momentum, pois carecem da volatilidade necessária para gerar lucros significativos em minutos. Ross Cameron foca em um nicho específico: ações que têm o potencial de mover 20%, 50% ou até 100% em um único dia. Para isolar esses ativos, utiliza-se um conjunto rigoroso de critérios de filtragem.3

### **O Conceito de "Stocks in Play" (Ações em Jogo)**

Uma ação está "em jogo" quando a atenção coletiva do mercado converge para ela. Sem volume e sem interesse, não há liquidez suficiente para entrar e sair de posições grandes sem causar derrapagens (slippage) prejudiciais, nem há a força motriz necessária para romper níveis de resistência técnica. A busca diária, portanto, é por "ilhas de liquidez" em um oceano de estagnação.

### **Critérios Técnicos de Filtragem (Scanners)**

Os scanners de mercado são a linha de frente da estratégia. Eles filtram milhares de ativos em tempo real para apresentar apenas aqueles que atendem aos pré-requisitos de volatilidade. As configurações específicas utilizadas na metodologia Warrior Trading são calibradas para encontrar desequilíbrios extremos.4

#### **Tabela 1: Parâmetros de Configuração dos Scanners de Momentum**

| Critério | Faixa / Valor Típico | Racional Econômico e Técnico |
| :---- | :---- | :---- |
| **Preço da Ação** | US$ 1,50 a US$ 20,00 (pode estender a US$ 500\) | Ações de baixo valor nominal (penny stocks e small caps) atraem maior participação de varejo, aumentando a irracionalidade e a volatilidade dos movimentos.4 |
| **Float (Ações em Circulação)** | \< 100 Milhões (Ideal \< 20 Milhões) | A escassez de oferta é o principal motor de movimentos parabólicos. Com poucas ações disponíveis para negociação, um aumento súbito na demanda causa uma reprecificação imediata e violenta.3 |
| **Volume Relativo (RVOL)** | \> 2.0x (mínimo), idealmente muito superior | O RVOL compara o volume atual com a média histórica para o mesmo horário. Um RVOL alto confirma que o movimento é anômalo e sustentado por fluxo real, não apenas ruído de mercado.3 |
| **Gap de Abertura** | \> 4% | Indica uma reprecificação overnight causada por notícias ou eventos externos, criando um desequilíbrio imediato na abertura.4 |
| **Volume Pré-Mercado** | \> 20.000 ações | Garante que há liquidez mínima para operar antes mesmo do sino tocar, validando o interesse institucional ou de varejo precoce.4 |

#### **O Fator Float e a Dinâmica de Oferta e Demanda**

O "float" refere-se ao número de ações disponíveis para negociação pública, excluindo aquelas detidas por insiders ou restritas. A analogia utilizada é a da escassez: se a demanda por um item dispara e a oferta é limitada, o preço deve subir até encontrar vendedores dispostos. Em ações com float abaixo de 10 milhões ou 20 milhões, é comum observar o fenômeno de "supply shock" (choque de oferta). Quando uma notícia positiva (catalisador) atinge o mercado, os vendedores recuam suas ofertas (ask prices), e os compradores agressivos consomem a liquidez disponível, criando velas verdes longas e rápidas.3

#### **A Importância do Catalisador Fundamental**

Embora a análise técnica guie a entrada e a saída, o catalisador fundamental fornece a "história" que atrai a massa de traders. Sem um catalisador, um movimento técnico pode ser apenas uma armadilha ("bull trap"). Os catalisadores mais potentes incluem:

* **Notícias de Earnings (Resultados):** Superação de expectativas de lucro ou receita.  
* **Contratos e Parcerias:** Anúncios de grandes contratos governamentais ou parcerias com empresas "Blue Chip".  
* **Aprovações FDA:** Para empresas de biotecnologia, a aprovação de uma droga ou fase de teste é um gatilho explosivo.  
* **Atividade de Investidores Ativistas:** Compra de participações relevantes por fundos conhecidos.  
* **Rupturas Técnicas:** Em alguns casos, o rompimento de um nível histórico (como a máxima de 52 semanas) serve como o próprio catalisador, atraindo traders puramente técnicos.3

## ---

**Parte II: Análise Técnica Avançada e Indicadores Proprietários**

Uma vez identificado o ativo "em jogo", o foco se desloca para o gráfico. A análise técnica no day trading não se preocupa com os fundamentos da empresa a longo prazo (balanço patrimonial, fluxo de caixa), mas sim com a psicologia dos participantes do mercado representada graficamente. O objetivo é identificar padrões que historicamente resultam em previsibilidade direcional.

### **Padrões de Candlestick e Sentimento de Mercado**

A leitura de velas japonesas (candlesticks) é a linguagem básica da ação do preço. Cada vela conta uma história de batalha entre compradores (touros) e vendedores (ursos) em um determinado período.1

* **Velas de Corpo Longo (Long Body Candles):** Indicam forte pressão direcional. Uma vela verde longa sem sombras superiores sugere que os compradores controlaram o período do início ao fim, sinalizando continuação.  
* **Shooting Stars (Estrelas Cadentes):** Padrão de reversão baixista. Ocorre quando o preço sobe significativamente, mas os vendedores empurram o preço de volta para a abertura, deixando uma longa sombra superior. Em um gráfico de momentum, isso frequentemente marca o topo de um movimento ou uma "exaustão".2  
* **Hammers (Martelos):** Padrão de reversão altista. Indica que vendedores tentaram derrubar o preço, mas compradores intervieram com força, fechando próximo à máxima.  
* **Dojis:** Representam indecisão. O preço de abertura e fechamento são praticamente idênticos. Em uma tendência forte, um Doji pode sinalizar uma pausa antes da continuação ou uma perda de momentum.1

### **Configuração de Gráficos e Janelas Temporais**

A clareza visual é essencial. Ross Cameron recomenda uma configuração limpa, evitando a poluição visual de dezenas de indicadores ("indicator paralysis").

#### **O Debate: 1 Minuto vs. 5 Minutos**

A escolha do tempo gráfico (time frame) é crítica para a precisão da entrada.

* **Gráfico de 1 Minuto:** É a lente de aumento utilizada para entradas cirúrgicas. Permite visualizar a formação de micro-padrões e antecipar rompimentos antes que eles sejam visíveis em tempos maiores. No entanto, é propenso a "ruído" e falsos sinais.9  
* **Gráfico de 5 Minutos:** Oferece o contexto da tendência. É utilizado para validar a sustentabilidade do movimento e filtrar a volatilidade excessiva. A transição típica envolve usar o gráfico de 1 minuto na primeira hora (09:30 \- 10:30 AM) para scalping rápido, e mudar para o de 5 minutos à medida que o volume diminui e a ação do preço se torna mais errática (choppy).3

### **Indicadores Técnicos Essenciais**

A estratégia não depende de osciladores complexos, mas de indicadores de tendência e níveis de preço ponderados pelo volume.

#### **1\. Médias Móveis Exponenciais (EMA)**

Diferente das médias simples (SMA), as EMAs dão maior peso aos preços recentes, reagindo mais rápido às mudanças de tendência, o que é vital no day trading.11

* **9 EMA:** O indicador de "ritmo" da tendência. Em uma ação de momentum forte, o preço deve se manter acima da 9 EMA. Um fechamento abaixo dela é frequentemente o primeiro sinal de fraqueza ou reversão. É usada como suporte dinâmico para entradas em pullbacks.3  
* **20 EMA:** Atua como um suporte secundário. Se a 9 EMA falha, a 20 EMA é a próxima linha de defesa. Perder a 20 EMA geralmente invalida a tendência de alta imediata no gráfico de 1 ou 5 minutos.12  
* **200 EMA:** Indicador de tendência de longo prazo no gráfico diário. Atua como uma "parede" de resistência ou suporte magnético. Ações negociando acima da 200 EMA no diário têm viés altista mais forte.12

#### **2\. VWAP (Volume Weighted Average Price)**

O VWAP é, indiscutivelmente, o indicador mais respeitado por traders institucionais e algoritmos. Ele representa o preço médio pago por todas as ações negociadas no dia, ponderado pelo volume de cada transação.13

* **Como Suporte/Resistência:** Instituições frequentemente usam o VWAP para avaliar a eficiência de suas execuções. Se o preço está acima do VWAP, compradores estão no controle; abaixo, vendedores dominam.  
* **Estratégia de Retorno à Média:** Ações que se afastam demais do VWAP (ficam "esticadas") tendem a retornar a ele. Traders de momentum evitam comprar ações excessivamente estendidas em relação ao VWAP ("extended") para não comprar no topo.13

### **Padrões Gráficos de Alta Probabilidade**

A identificação de padrões geométricos no gráfico fornece a estrutura para definir risco e recompensa.

#### **Bull Flags (Bandeiras de Alta)**

Este é o padrão "pão com manteiga" da estratégia.

1. **O Mastro:** Um movimento vertical forte e rápido com alto volume.  
2. **A Bandeira:** Um período de consolidação ou recuo (pullback) ordenado, com volume decrescente. Idealmente, 2 a 3 velas vermelhas que não devolvem mais de 30-50% do movimento do mastro.3  
3. **A Entrada:** Ocorre na primeira vela que faz uma nova máxima (rompe a máxima da vela anterior) após a consolidação, com volume retomando força.3

#### **Flat Top Breakout (Rompimento de Topo Plano)**

Caracteriza-se por um nível de resistência horizontal bem definido onde vendedores estão posicionados (uma "parede" de venda), enquanto os fundos são ascendentes, indicando que compradores estão dispostos a pagar preços cada vez maiores.

* **A Psicologia:** Quando o nível de resistência é finalmente rompido, os vendedores que apostaram na queda são forçados a cobrir suas posições (comprar), e traders de rompimento entram comprando. Essa dupla pressão de compra gera um movimento explosivo.3

## ---

**Parte III: A Arte da Leitura de Fluxo (Tape Reading e Level 2\)**

Enquanto os gráficos mostram o passado, a "Tape" (Fita) mostra o presente e o futuro imediato. Ross Cameron enfatiza que o domínio do Level 2 e do Time and Sales é o que separa traders amadores de profissionais, permitindo entradas mais precisas e saídas defensivas antes que os indicadores gráficos reajam.15

### **Componentes da Fita**

1. **Level 2 (Livro de Ofertas):** Mostra a profundidade do mercado, listando as ordens de compra (Bid) e venda (Ask) pendentes, organizadas por preço e formador de mercado (Market Maker/ECN). Permite visualizar onde está a liquidez.17  
2. **Time and Sales (T\&S):** A lista de transações executadas em tempo real. Mostra o preço, tamanho e horário de cada negócio. É a confirmação da execução das intenções mostradas no Level 2\.17

### **Dinâmica e Sinais de Tape Reading**

A leitura não é sobre números estáticos, mas sobre a velocidade e a "cor" do fluxo.

* **Impressões Verdes vs. Vermelhas:** No T\&S, transações verdes geralmente indicam execução no preço de venda (Ask), sinalizando agressão compradora. Transações vermelhas indicam execução no preço de compra (Bid), sinalizando agressão vendedora. Uma sequência rápida de verdes sugere momentum de alta.15  
* **O Spread:** A diferença entre o melhor Bid e o melhor Ask. Ações com spreads apertados (ex: 1 centavo) são mais seguras e fáceis de entrar/sair. Spreads largos indicam baixa liquidez e maior risco.15

### **O Truque de 3 Passos para Rompimentos (The 3-Step Trick)**

Esta é uma técnica específica de Ross Cameron para validar rompimentos usando o Level 2, evitando falsos rompimentos.15

1. **Identificar o Grande Vendedor (A Parede):** Localizar uma ordem de venda significativa no Level 2 em um nível de preço chave (ex: 50.000 ações a US$ 5,00). Isso atua como resistência.  
2. **Observar o Ataque:** Esperar para ver se o Time and Sales mostra compradores consumindo essa ordem (prints verdes rápidos em US$ 5,00). O volume de transações deve acelerar.  
3. **Entrada na Exaustão:** Entrar na operação no momento exato em que a quantidade de ações do vendedor está prestes a acabar (ex: caiu de 50k para 5k). A quebra da parede geralmente resulta em um salto imediato ("pop") conforme o preço busca a próxima liquidez disponível acima.

### **Compradores e Vendedores Ocultos (Hidden Orders)**

Nem todas as ordens aparecem no Level 2\. Ordens "Iceberg" ou ocultas podem absorver liquidez sem serem vistas.

* **Sinal de Comprador Oculto:** O Level 2 mostra apenas 100 ações na compra, mas o Time and Sales mostra milhares de ações sendo vendidas naquele preço sem que o preço caia (o nível de preço não "quebra"). Isso indica que alguém está recarregando a ordem ou usando uma ordem oculta para acumular, um sinal bullish muito forte.15

## ---

**Parte IV: Estratégias Operacionais (Playbook)**

As estratégias de Ross Cameron são desenhadas para diferentes momentos do dia e configurações de mercado.

### **1\. Estratégia Gap and Go (Manhã: 09:30 \- 10:00 AM)**

Esta é a estratégia principal para capturar a volatilidade de abertura.

* **Premissa:** Ações que abrem com um gap de alta devido a notícias tendem a continuar subindo se a demanda superar a realização de lucros inicial.8  
* **Setup:** Identificar ações com gap \> 4% no pré-mercado.  
* **Execução:** Monitorar o preço nos primeiros segundos/minutos. A entrada ideal ocorre:  
  1. No rompimento da máxima do pré-mercado.  
  2. No rompimento da máxima do primeiro minuto (consolidação de 1 min).  
* **Alvo:** Venda rápida na aceleração do movimento. Frequentemente dura apenas alguns minutos.  
* **Risco:** Se o preço falhar em romper a máxima e perder a mínima da abertura, a operação é abortada imediatamente.21

### **2\. Momentum Trading e Dip Buying (Manhã Tardia: 10:00 \- 11:30 AM)**

Após a volatilidade inicial, o mercado tende a formar tendências mais estruturadas.

* **Dip Buying (Compra de Recuos):** Em vez de comprar rompimentos (que podem falhar mais facilmente neste horário), a estratégia muda para comprar recuos até médias móveis (9 EMA ou VWAP).3  
* **Regra de Entrada:** Aguardar o preço tocar o suporte (ex: 9 EMA), formar um padrão de reversão (martelo ou consolidação) e entrar quando a primeira vela fizer uma nova máxima.  
* **Extensão Parabólica:** Se uma ação sobe verticalmente ("parabolic move"), Ross evita comprar o topo. Ele espera o recuo ou procura oportunidades de "scalp" curto, vendendo na força ("selling into strength").23

### **3\. Estratégia de "Halts" de Volatilidade (LULD)**

Ações que se movem muito rápido (geralmente 10% em 5 minutos) podem ser paralisadas pela bolsa (Circuit Breaker/Halt) por 5 ou 10 minutos.

* **Oportunidade:** Ações que são paralisadas na subida ("halted going up") frequentemente abrem ainda mais altas devido ao acúmulo de ordens de compra durante a paralisação.  
* **Risco Extremo:** A ação também pode reabrir muito abaixo ("gap down"), prendendo o trader em uma perda massiva. Ross recomenda extrema cautela ou evitar manter posições durante halts, a menos que se tenha uma "almofada" de lucro substancial.24

## ---

**Parte V: Gestão de Risco e Psicologia de Mercado**

A gestão de risco é o sistema imunológico do trader. Sem ela, um único erro pode ser fatal. Ross Cameron opera sob uma lógica matemática estrita para garantir longevidade.25

### **A Matemática da Assimetria (Risco/Recompensa)**

Como a taxa de acerto (win rate) em estratégias de momentum pode flutuar (tipicamente 60-70%), a rentabilidade depende de os ganhos serem maiores que as perdas.3

* **A Regra 2:1:** O alvo de lucro deve ser sempre, no mínimo, o dobro do risco assumido. Se o stop loss técnico exige um risco de 10 centavos, o potencial de alta deve ser de 20 centavos.  
* **A Regra dos 20 Centavos:** Ross frequentemente busca configurações onde o stop loss não esteja a mais de 20 centavos do ponto de entrada. Isso permite um dimensionamento de posição maior mantendo o risco financeiro controlado.3

#### **Tabela 2: Exemplo de Dimensionamento de Posição com Risco Fixo de US$ 500**

| Distância do Stop (Centavos) | Cálculo (Risco / Distância) | Tamanho da Posição (Ações) | Risco Financeiro Total |
| :---- | :---- | :---- | :---- |
| 5 centavos | 500 / 0.05 | 10.000 ações | US$ 500 |
| 10 centavos | 500 / 0.10 | 5.000 ações | US$ 500 |
| 20 centavos | 500 / 0.20 | 2.500 ações | US$ 500 |
| 50 centavos | 500 / 0.50 | 1.000 ações | US$ 500 |

*Insight:* Note que o risco financeiro é idêntico em todos os cenários, mas o tamanho da posição varia drasticamente. Traders iniciantes erram ao fixar o tamanho da posição (ex: "sempre opero 1000 ações") em vez de ajustar pelo risco técnico.3

### **Regras de Ouro de Gerenciamento e Psicologia**

Para proteger o capital emocional e financeiro, regras rígidas são impostas:

1. **Limite de Perda Diária (Max Daily Loss):** Um valor financeiro que, se atingido, obriga o trader a encerrar o dia. Para Ross, isso já foi US$ 7.500 (em contas maiores), mas para iniciantes deve ser proporcional à conta (ex: 2% do capital). Isso previne o "revenge trading" (tentar recuperar perdas de forma imprudente) que leva a desastres.27  
2. **A Regra dos Dois Trades Vermelhos:** Se o trader iniciar o dia com duas operações perdedoras consecutivas, ele deve parar ou reduzir drasticamente o tamanho da mão. Isso indica que a leitura do mercado está dessincronizada ou que o mercado não está propício para a estratégia.28  
3. **Timing é Tudo:** A janela de ouro é das 09:30 às 11:30 AM. Tentar forçar operações no horário de almoço (meio-dia de NY), onde o volume seca e os algoritmos de reversão operam, é uma das formas mais comuns de devolver lucros.3  
4. **Psicologia da "Folha em Branco":** Cada dia e cada semana começam do zero. Lucros passados não justificam riscos excessivos hoje. A meta é consistência, não "home runs" diários.29

### **Estratégia para Contas Pequenas (Small Account Challenge)**

Para traders com capital limitado (abaixo de US$ 25.000, sujeitos à regra PDT \- Pattern Day Trader), a estratégia muda:

* **Foco na Precisão:** Com limite de day trades (3 a cada 5 dias), só se deve operar setups "A+" (alta convicção).  
* **Contas Cash:** Uma alternativa é usar uma conta à vista (cash account), que não tem limite de day trades, mas exige esperar a liquidação dos fundos (T+1 ou T+2) antes de reusar o capital. Isso exige dividir o capital em "fatias" para poder operar todos os dias.24  
* **Crescimento Exponencial:** Aumentar o risco gradualmente (ex: começar arriscando 0.5% da conta, subir para 1% após lucratividade comprovada).31

## ---

**Parte VI: Infraestrutura Tecnológica e Rotina Profissional**

O day trading de alta frequência é uma corrida tecnológica. A latência (atraso) de milissegundos pode significar a diferença entre lucro e prejuízo.

### **Ferramentas e Plataformas**

* **Corretoras de Acesso Direto (Direct Access Brokers):** Ross utiliza e recomenda corretoras como a **Lightspeed**. Diferente de corretoras de varejo "grátis" que vendem o fluxo de ordens (PFOF), corretoras de acesso direto enviam as ordens diretamente para as ECNs (Electronic Communication Networks) ou Exchanges, garantindo execução ultrarrápida.32  
* **Scanners em Tempo Real:** Ferramentas como **Trade Ideas** ou o software proprietário **Day Trade Dash** da Warrior Trading são vitais para encontrar as ações antes da multidão.4

### **A Importância das Hotkeys (Teclas de Atalho)**

O uso do mouse para clicar em "comprar" e "vender" é proibitivamente lento. O trader profissional configura o teclado para enviar ordens complexas instantaneamente.35

#### **Configuração Típica de Hotkeys de Ross Cameron:**

* **Shift \+ 1:** Comprar 1.000 ações no ASK \+ 0.05 (Ordem Limitada para garantir entrada, aceitando pagar até 5 centavos acima do Ask para evitar perder o trade).  
* **Shift \+ 2:** Vender 1.000 ações no BID \- 0.05 (Ordem Limitada para garantir saída imediata, aceitando receber até 5 centavos abaixo do Bid).  
* **Panic Button (ESC):** Cancelar TODAS as ordens abertas imediatamente.

### **Rotina Diária: O Checklist de Preparação**

A consistência advém da repetição de um processo estruturado.4

1. **08:00 AM \- 08:30 AM:** Café, leitura de notícias macroeconômicas e verificação inicial dos scanners de "Top Gappers".  
2. **08:30 AM \- 09:00 AM:** Seleção da Watchlist. Filtragem dos 3 a 5 melhores candidatos. Desenho de linhas de suporte/resistência e identificação de níveis de pivô nos gráficos diários.  
3. **09:00 AM \- 09:15 AM:** Planejamento de cenários. "Se romper $5.50, eu compro com stop em $5.30". Definição mental dos pontos de entrada e saída.  
4. **09:15 AM \- 09:30 AM:** Foco total. Eliminação de distrações. Preparação das janelas de execução e verificação das hotkeys.  
5. **09:30 AM:** Abertura (The Bell). Execução do plano.

### **Conclusão**

A metodologia de Ross Cameron não é uma "fórmula mágica" de enriquecimento, mas um sistema de exploração de probabilidades estatísticas em ambientes de alta volatilidade. Ela exige uma fusão de disciplina militar, velocidade de reação de um atleta e a frieza analítica de um estatístico. Para o estudante desta "apostila", o caminho para a maestria envolve a prática incansável em simuladores, a revisão obsessiva das próprias operações e o respeito absoluto pelas regras de risco. O mercado é soberano, e a função do trader é surfar suas ondas, não tentar controlar o oceano.

#### **Referências citadas**

1. Mastering Technical Analysis \- by Warrior Trading \- Medium, acessado em fevereiro 3, 2026, [https://medium.com/@WarriorTrading/mastering-technical-analysis-379787d0a8fc](https://medium.com/@WarriorTrading/mastering-technical-analysis-379787d0a8fc)  
2. Mastering Technical Analysis \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/mastering-technical-analysis/](https://www.warriortrading.com/mastering-technical-analysis/)  
3. Momentum Day Trading Strategies for Beginners, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/momentum-day-trading-strategy/](https://www.warriortrading.com/momentum-day-trading-strategy/)  
4. Practical Guide to Building a Stock Watch-list Every Day \- Warrior ..., acessado em fevereiro 3, 2026, [https://www.warriortrading.com/practical-guide-to-building-a-stock-watch-list/](https://www.warriortrading.com/practical-guide-to-building-a-stock-watch-list/)  
5. What scanners are is Ross Cameron's software? Are they worth it : r/Daytrading \- Reddit, acessado em fevereiro 3, 2026, [https://www.reddit.com/r/Daytrading/comments/1ei5lqv/what\_scanners\_are\_is\_ross\_camerons\_software\_are/](https://www.reddit.com/r/Daytrading/comments/1ei5lqv/what_scanners_are_is_ross_camerons_software_are/)  
6. How to Use a Stock Scanner for Momentum Day Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/how-to-use-stock-scanners/](https://www.warriortrading.com/how-to-use-stock-scanners/)  
7. Relative Volume Definition: Day Trading Terminology, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/relative-volume-day-trading-terminology/](https://www.warriortrading.com/relative-volume-day-trading-terminology/)  
8. Navigating the Gap and Go Strategy | by Warrior Trading | Medium, acessado em fevereiro 3, 2026, [https://medium.com/@WarriorTrading/navigating-the-gap-and-go-strategy-b040f6b50938](https://medium.com/@WarriorTrading/navigating-the-gap-and-go-strategy-b040f6b50938)  
9. How To Choose The Right Trading Time Frame, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/choose-right-time-frame/](https://www.warriortrading.com/choose-right-time-frame/)  
10. 15s vs 1m vs 5m for scalping : r/Daytrading \- Reddit, acessado em fevereiro 3, 2026, [https://www.reddit.com/r/Daytrading/comments/1ngbe4b/15s\_vs\_1m\_vs\_5m\_for\_scalping/](https://www.reddit.com/r/Daytrading/comments/1ngbe4b/15s_vs_1m_vs_5m_for_scalping/)  
11. Exponential Moving Average Explained for Beginners \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/exponential-moving-average/](https://www.warriortrading.com/exponential-moving-average/)  
12. Beginner Trading Indicators \[Top 4 Technical Indicators\] \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/top-4-indicators-day-trading/](https://www.warriortrading.com/top-4-indicators-day-trading/)  
13. VWAP Indicator Trading Strategies, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/vwap/](https://www.warriortrading.com/vwap/)  
14. Are you using VWAP the RIGHT WAY? \- YouTube, acessado em fevereiro 3, 2026, [https://www.youtube.com/watch?v=pSTHR41o6\_k](https://www.youtube.com/watch?v=pSTHR41o6_k)  
15. Tape Reading in Trading: What It Is & How To Use It, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/what-is-tape-reading-in-trading/](https://www.warriortrading.com/what-is-tape-reading-in-trading/)  
16. The Only 2 Things Day Traders Should Focus On | by Warrior Trading | Medium, acessado em fevereiro 3, 2026, [https://medium.com/@WarriorTrading/the-only-2-things-day-traders-should-focus-on-ef590414523e](https://medium.com/@WarriorTrading/the-only-2-things-day-traders-should-focus-on-ef590414523e)  
17. Tape Reading 101 || Level 2 and Time & Sales \- YouTube, acessado em fevereiro 3, 2026, [https://www.youtube.com/watch?v=Rn5rMtwI81w](https://www.youtube.com/watch?v=Rn5rMtwI81w)  
18. Tape Reading 101 || Level 2 and Time & Sales \- YouTube, acessado em fevereiro 3, 2026, [https://www.youtube.com/live/Rn5rMtwI81w?t=54s](https://www.youtube.com/live/Rn5rMtwI81w?t=54s)  
19. Time and Sales: How to Read the Tape Like a Pro \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/time-and-sales/](https://www.warriortrading.com/time-and-sales/)  
20. Spotting Breakouts With Level 2 \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/spotting-breakouts-with-level-2/](https://www.warriortrading.com/spotting-breakouts-with-level-2/)  
21. Mastering the Gap and Go Strategy \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/mastering-the-gap-and-go-strategy/](https://www.warriortrading.com/mastering-the-gap-and-go-strategy/)  
22. What's the more "correct" gap-and-go entry? : r/Daytrading \- Reddit, acessado em fevereiro 3, 2026, [https://www.reddit.com/r/Daytrading/comments/c8tiqd/whats\_the\_more\_correct\_gapandgo\_entry/](https://www.reddit.com/r/Daytrading/comments/c8tiqd/whats_the_more_correct_gapandgo_entry/)  
23. Momentum Trading Strategies \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/momentum-trading-strategies/](https://www.warriortrading.com/momentum-trading-strategies/)  
24. Know When to Fold 'Em: Tips For Cutting Your Trading Losses, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/blog-know-when-to-fold-em-cutting-your-trading-losses/](https://www.warriortrading.com/blog-know-when-to-fold-em-cutting-your-trading-losses/)  
25. Day Trading Risk Management Strategies \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/day-trading-risk-management/](https://www.warriortrading.com/day-trading-risk-management/)  
26. How I Bounced Back After My Max Loss Red Day \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/how-i-bounced-back-after-my-max-loss-red-day/](https://www.warriortrading.com/how-i-bounced-back-after-my-max-loss-red-day/)  
27. Why I Have a Loss Limit \[How I Hit Max Loss Before 10 A.M.\] \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/loss-limit-how-i-hit-max-loss/](https://www.warriortrading.com/loss-limit-how-i-hit-max-loss/)  
28. Day Trading Rules For Beginners, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/day-trading-rules/](https://www.warriortrading.com/day-trading-rules/)  
29. 7 Rules I Learned from Making $12374892 Day Trading \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/7-day-trading-rules/](https://www.warriortrading.com/7-day-trading-rules/)  
30. How To Determine What Account Size You Should Start With \- Warrior Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/how-to-determine-what-account-size-you-should-start-with/](https://www.warriortrading.com/how-to-determine-what-account-size-you-should-start-with/)  
31. New Trader Trying the Ross Cameron Approach – Thoughts? : r/Daytrading \- Reddit, acessado em fevereiro 3, 2026, [https://www.reddit.com/r/Daytrading/comments/1jcdvl8/new\_trader\_trying\_the\_ross\_cameron\_approach/](https://www.reddit.com/r/Daytrading/comments/1jcdvl8/new_trader_trying_the_ross_cameron_approach/)  
32. What software and trading tools do you use and recommend for when I trade live?, acessado em fevereiro 3, 2026, [https://support.warriortrading.com/support/solutions/articles/19000080962-what-software-and-trading-tools-do-you-use-and-recommend-for-when-i-trade-live-](https://support.warriortrading.com/support/solutions/articles/19000080962-what-software-and-trading-tools-do-you-use-and-recommend-for-when-i-trade-live-)  
33. How to Use Lightspeed Trader for Trading Momentum \- YouTube, acessado em fevereiro 3, 2026, [https://www.youtube.com/watch?v=eHXqH\_42uOY](https://www.youtube.com/watch?v=eHXqH_42uOY)  
34. Scanners: How to Load & Use Them in the Chat Room | WT \- Warrior Trading, acessado em fevereiro 3, 2026, [https://support.warriortrading.com/support/solutions/articles/19000117763-scanners-how-to-load-use-them-in-the-chat-room-wt](https://support.warriortrading.com/support/solutions/articles/19000117763-scanners-how-to-load-use-them-in-the-chat-room-wt)  
35. Routing, Hot Keys, and Buying/Selling Process \- Warrior Trading, acessado em fevereiro 3, 2026, [https://support.warriortrading.com/support/solutions/articles/19000045007-routing-hot-keys-and-buying-selling-process](https://support.warriortrading.com/support/solutions/articles/19000045007-routing-hot-keys-and-buying-selling-process)  
36. How To Use Hotkeys for Day Trading, acessado em fevereiro 3, 2026, [https://www.warriortrading.com/hot-key-video-lesson/](https://www.warriortrading.com/hot-key-video-lesson/)