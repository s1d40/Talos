//+------------------------------------------------------------------+
//|                                                 OBS1DIAN.mq5     |
//|                                  Copyright 2026, Project Talos.  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Project Talos."
#property version   "6.00" // v6.0: Regime Filters (Entropy/Hurst) & Climax
#property strict

// IMPORTANTE: Apontando para a nova estrutura OBSIDIAN
#include <Obsidian\Core\CEngine.mqh>

//--- INPUTS GERAIS ---
input string   Inp_Group_Main = "=== Configurações Gerais ===";
input int      InpMagicNum    = 999001;      
input bool     InpAdaptive    = true;        // MODO ADAPTATIVO (Auto-Switch)
input ENUM_BIAS_MODE InpMacroBias = BIAS_NONE; // Viés Macro (Filtro Global)

//--- INPUTS DE REGIME (v6.0 - GOVERNOR) ---
input string   Inp_Group_Regime = "=== Filtros de Regime (v6.0) ===";
input double   InpEntropyThreshold = 0.90;   // Max Entropy (0.90 = Chaos)
input int      InpEntropyPeriod    = 20;     // Period for Entropy Calc
input bool     InpUseHurst         = false;  // Hurst Filter (Experimental)
input bool     InpUseSentiment     = false;  // Filtragem por Sentimento (Python Bridge)

//--- INPUTS DE SEGURANÇA ---
input string   Inp_Group_Safe = "=== Segurança (Circuit Breaker) ===";
input bool     InpDisableSafety = false;     // DESATIVAR TRAVA DE CRASH (Cuidado!)
input double   InpSafetyThreshold = 1.5;     // Limite de Variação Diária (%)
input int      InpCooldownSeconds = 900;     // Tempo de Espera após Fechamento (segundos)
input int      InpTimeExitHours   = 4;       // Fechar se não lucrar em X horas (0=Off)

//--- INPUTS DE ALAVANCAGEM (PYRAMIDING) ---
input string   Inp_Group_Pyr  = "=== Alavancagem Convexa (Pyramiding) ===";
input bool     InpUsePyramiding = false;     // Ativar Piramidação? (Risco Alto!)
input double   InpPyramidStepATR = 1.5;      // Adicionar a cada X ATR de lucro
input int      InpMaxLayers      = 3;        // Máximo de posições simultâneas

//--- INPUTS DE RISCO ---
input string   Inp_Group_Risk = "=== Gestão de Risco ===";
input double   InpRiskPercent = 1.0;         
input double   InpFixedLot    = 0.0;         // Lote Fixo (Sobrescreve Risk %)
input int      InpATRPeriod   = 14;          
input double   InpATRMult     = 2.5;         
input double   InpTPMultiplier= 1.8;         // Multiplicador de Take Profit (x ATR Risk)

//--- INPUTS MANUAIS (Ignorados se Adaptive=true) ---
input string   Inp_Group_Man  = "=== Seleção Manual (Se Adaptive=false) ===";
input bool     InpUseKAMA     = true;        
input bool     InpUseMeanRev  = true;        
input bool     InpUseBreakout = false;
input bool     InpUseWarrior  = false;       // WARRIOR MODE: Momentum Scalping (Ross Cameron)

//--- INPUTS TÉCNICOS ---
input string   Inp_Group_Tec  = "=== Parâmetros Técnicos ===";
input int      InpKAMA_Per    = 10;
input int      InpRSI_Per     = 14;
input int      InpBB_Per      = 20;

CEngine engine;

int OnInit()
{
   Print("Initializing OBS1DIAN AI [Genesis Protocol v6.0]...");
   
   HydraSettings settings;
   settings.magic_number = InpMagicNum;
   settings.use_adaptive = InpAdaptive; // Passa a escolha do usuário
   settings.bias         = InpMacroBias;
   
   // v6.0 Settings
   settings.entropy_threshold = InpEntropyThreshold;
   settings.entropy_period    = InpEntropyPeriod;
   settings.use_hurst         = InpUseHurst;
   settings.use_sentiment     = InpUseSentiment;
   
   settings.disable_safety = InpDisableSafety; // Passa a escolha de segurança
   settings.safety_threshold = InpSafetyThreshold; // Passa o limite do Circuit Breaker
   settings.cooldown_seconds = InpCooldownSeconds; // Passa o tempo de Cooldown
   settings.time_exit_hours  = InpTimeExitHours;   // Passa o Time Exit
   
   // Pyramiding Settings
   settings.use_pyramiding   = InpUsePyramiding;
   settings.pyramid_step_atr = InpPyramidStepATR;
   settings.max_layers       = InpMaxLayers;
   
   settings.risk_percent = InpRiskPercent;
   settings.fixed_lot    = InpFixedLot;            // Passa o Lote Fixo
   settings.atr_mult     = InpATRMult;
   settings.atr_per      = InpATRPeriod;
   settings.tp_multiplier = InpTPMultiplier; // NEW: Passa o multiplicador de TP
   
   settings.use_kama     = InpUseKAMA;
   settings.use_mean_rev = InpUseMeanRev;
   settings.use_breakout = InpUseBreakout;
   settings.use_warrior  = InpUseWarrior; // Passa Warrior Mode
   
   settings.kama_per     = InpKAMA_Per;
   settings.kama_fast    = 2;
   settings.kama_slow    = 30;
   
   settings.rsi_per      = InpRSI_Per;
   settings.rsi_up       = 70;
   settings.rsi_low      = 30;
   settings.bb_per       = InpBB_Per;
   settings.bb_dev       = 2.0;
   settings.filter_ema   = 200;
   
   settings.session_start= 0;
   settings.session_end  = 8;
   
   if(!engine.Init(settings)) 
   {
      Print("CRITICAL ERROR: Engine Init Failed!");
      return INIT_FAILED;
   }
   
   Print("OBS1DIAN AI v6.0 Initialized Successfully.");
   return INIT_SUCCEEDED;
}

void OnTick() 
{ 
   engine.OnTick(); 
}

void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result)
{
   engine.OnTradeTransaction(trans, request, result);
}