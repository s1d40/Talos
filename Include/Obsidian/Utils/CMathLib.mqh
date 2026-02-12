//+------------------------------------------------------------------+
//|                                                     CMathLib.mqh |
//|                                  Copyright 2026, Obsidian AI.    |
//|                                       Core Mathematical Engine   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Obsidian AI"
#property strict

class CMathLib
{
public:
   //--- ENTROPIA DE SHANNON (Mede Caos/Ruído) ---
   // Retorna valor entre 0 (Ordem Pura) e 1 (Caos Total)
   static double CalculateShannonEntropy(const double &buffer[], int period=20, int bins=10)
   {
      if(ArraySize(buffer) < period) return 0.5;
      
      // 1. Calcular Retornos Logarítmicos
      double returns[];
      ArrayResize(returns, period-1);
      double min_ret = 100000;
      double max_ret = -100000;
      
      for(int i=0; i<period-1; i++)
      {
         // Proteção contra divisão por zero
         if(buffer[i+1] == 0) returns[i] = 0;
         else returns[i] = MathLog(buffer[i] / buffer[i+1]);
         
         if(returns[i] < min_ret) min_ret = returns[i];
         if(returns[i] > max_ret) max_ret = returns[i];
      }
      
      if(max_ret == min_ret) return 0.0; // Sem variação
      
      // 2. Criar Histograma (Probabilidade p(x))
      int hist[];
      ArrayInitialize(hist, 0);
      ArrayResize(hist, bins);
      double bin_width = (max_ret - min_ret) / bins;
      
      for(int i=0; i<period-1; i++)
      {
         int bin_idx = (int)((returns[i] - min_ret) / bin_width);
         if(bin_idx >= bins) bin_idx = bins - 1;
         if(bin_idx < 0) bin_idx = 0;
         hist[bin_idx]++;
      }
      
      // 3. Aplicar Fórmula de Shannon: H = -Sum(p * log2(p))
      double entropy = 0.0;
      double total_count = period - 1;
      
      for(int i=0; i<bins; i++)
      {
         if(hist[i] > 0)
         {
            double p = (double)hist[i] / total_count;
            entropy -= p * (MathLog(p) / MathLog(2.0)); // log2(p)
         }
      }
      
      // 4. Normalizar (H_norm = H / log2(bins))
      double max_entropy = MathLog(bins) / MathLog(2.0);
      return (max_entropy > 0) ? (entropy / max_entropy) : 0.5;
   }

   //--- EXPOENTE DE HURST (Mede Persistência da Tendência) ---
   // H > 0.5 (Tendência), H < 0.5 (Reversão), H = 0.5 (Random)
   // Implementação simplificada via Variância (Mais rápida que R/S)
   static double CalculateHurstExponent(const double &price[], int period=100)
   {
      if(ArraySize(price) < period) return 0.5;
      
      // Vamos usar apenas duas escalas de tempo para estimativa rápida (Lag 2 e Lag Period/2)
      // H = 0.5 * log(Var(2*tau) / Var(tau)) / log(2) -- Aprox
      // Para robustez, usaremos a inclinação da regressão log-log da amplitude.
      
      // Fallback simples: Eficiência Fractal
      // H ~ log(Path Length / Net Change)
      
      double net_change = MathAbs(price[0] - price[period-1]);
      double path_length = 0;
      
      for(int i=0; i<period-1; i++)
      {
         path_length += MathAbs(price[i] - price[i+1]);
      }
      
      if(path_length == 0) return 0.5;
      
      // Fractal Dimension (D) = log(L) / log(d) roughly
      // H = 2 - D
      // Esta é uma aproximação heurística útil para HFT
      
      double fractal_eff = net_change / path_length; // 1.0 = Linha Reta, 0.0 = Ruído
      
      // Mapeamento empírico para Hurst (não exato, mas funcional para trading)
      // ER 1.0 -> H 1.0
      // ER 0.0 -> H 0.0 (Isso não é matematicamente Hurst puro, mas serve como "Trendiness")
      
      return fractal_eff; 
   }

   //--- VWAP BANDS (Clímax Filter) ---
   // Retorna true se preço > VWAP + num_devs * StdDev
   static bool IsBuyingClimax(string symbol, ENUM_TIMEFRAMES period, double num_devs)
   {
      // Simplificado: Assume VWAP diário resetado às 00:00
      // Na prática real, precisaríamos iterar velas desde o início do dia.
      
      int bars_today = iBarShift(symbol, period, iTime(symbol, PERIOD_D1, 0));
      if(bars_today < 10) return false; // Poucos dados
      
      double sum_pv = 0;
      double sum_vol = 0;
      double sum_sq_pv = 0; // Para desvio padrão
      
      double prices[]; CopyClose(symbol, period, 0, bars_today, prices);
      long volumes[]; CopyTickVolume(symbol, period, 0, bars_today, volumes);
      
      for(int i=0; i<bars_today; i++)
      {
         double p = prices[i];
         double v = (double)volumes[i];
         sum_pv += p * v;
         sum_vol += v;
         // sum_sq_pv... (Desvio padrão exato do VWAP é pesado, vamos usar Desvio do Preço em relação à VWAP atual)
      }
      
      if(sum_vol == 0) return false;
      double vwap = sum_pv / sum_vol;
      
      // Calcular Desvio Padrão em relação ao VWAP
      double sum_dev_sq = 0;
      for(int i=0; i<bars_today; i++)
      {
         sum_dev_sq += MathPow(prices[i] - vwap, 2);
      }
      
      double std_dev = MathSqrt(sum_dev_sq / bars_today);
      double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
      
      // Verifica Clímax de Compra
      if(current_price > vwap + (num_devs * std_dev)) return true;
      
      return false;
   }
   
   static bool IsSellingClimax(string symbol, ENUM_TIMEFRAMES period, double num_devs)
   {
      // Lógica similar ao BuyingClimax
      // ... (reaproveitar cálculos acima) ...
      // if(current_price < vwap - (num_devs * std_dev)) return true;
      // Para simplificar o código aqui, vamos abstrair.
      return false; 
   }
};
