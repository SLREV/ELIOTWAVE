//+------------------------------------------------------------------+
//|                                               EliotWaveABC.mq5   |
//|          Indikator otomatis Elliott Wave ABC + zona pantulan C   |
//+------------------------------------------------------------------+
#property copyright   "ELIOTWAVE"
#property version     "1.00"
#property description "Deteksi otomatis pola Elliott Wave ABC. Zona Fibonacci Wave C dan sinyal pantulan harga untuk entri."
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_label1  "Pantulan C BUY"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_width1  2
#property indicator_style1  STYLE_SOLID

#property indicator_label2  "Pantulan C SELL"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrOrangeRed
#property indicator_width2  2
#property indicator_style2  STYLE_SOLID

#include <EliotWaveABC.mqh>

input group "=== Deteksi Wave ==="
input int              InpDepth         = 12;      // Kedalaman swing
input int              InpMaxBars       = 800;     // Bar yang dipindai
input double           InpMinSwingATR   = 0.40;    // Min swing (x ATR)
input double           InpMinWaveATR    = 0.80;    // Min Wave A (x ATR)
input bool             InpStrictZigzag  = true;    // B tidak melewati awal A

input group "=== Aturan ABC ==="
input double           InpBRetraceMin   = 0.382;   // Retrace B minimum
input double           InpBRetraceMax   = 0.886;   // Retrace B maksimum
input double           InpCFibMin       = 0.886;   // Zona C Fibonacci min
input double           InpCFibMax       = 1.618;   // Zona C Fibonacci max
input double           InpCFibInvalid   = 2.618;   // Invalid jika C > ini

input group "=== Pantulan Wave C ==="
input ENUM_EWA_BOUNCE  InpBounceMode    = EWA_BOUNCE_ANY; // Mode pantulan
input double           InpWickRatio     = 0.50;    // Rasio sumbu rejection
input bool             InpUseRSI        = true;    // Filter RSI
input int              InpRSIPeriod     = 14;      // Periode RSI
input double           InpRSIBuyMax     = 40.0;    // RSI max untuk BUY
input double           InpRSISellMin    = 60.0;    // RSI min untuk SELL
input bool             InpClosedBar     = true;    // Sinyal di bar tertutup

input group "=== Tampilan ==="
input bool             InpShowFibo      = true;    // Tampilkan Fibonacci C
input bool             InpAlerts        = true;    // Alert saat pantulan C
input bool             InpPush          = false;   // Notifikasi push
input color            InpColorA        = clrDodgerBlue;
input color            InpColorB        = clrOrange;
input color            InpColorC        = clrGold;
input color            InpZoneBuy       = clrForestGreen;
input color            InpZoneSell      = clrFireBrick;

double g_buy[];
double g_sell[];

CEliotWaveABC g_engine;
SEliotConfig  g_cfg;
datetime      g_lastAlert = 0;
string        g_prefix    = "EWA_IND_";

int OnInit()
  {
   SetIndexBuffer(0, g_buy, INDICATOR_DATA);
   SetIndexBuffer(1, g_sell, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_ARROW, 233);
   PlotIndexSetInteger(1, PLOT_ARROW, 234);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   ArraySetAsSeries(g_buy, true);
   ArraySetAsSeries(g_sell, true);

   EwaDefaultConfig(g_cfg);
   g_cfg.depth         = InpDepth;
   g_cfg.maxBars       = InpMaxBars;
   g_cfg.minSwingAtr   = InpMinSwingATR;
   g_cfg.minWaveAtr    = InpMinWaveATR;
   g_cfg.strictZigzag  = InpStrictZigzag;
   g_cfg.bRetraceMin   = InpBRetraceMin;
   g_cfg.bRetraceMax   = InpBRetraceMax;
   g_cfg.cFibMin       = InpCFibMin;
   g_cfg.cFibMax       = InpCFibMax;
   g_cfg.cFibInvalid   = InpCFibInvalid;
   g_cfg.bounceMode    = InpBounceMode;
   g_cfg.wickRatio     = InpWickRatio;
   g_cfg.useRsi        = InpUseRSI;
   g_cfg.rsiPeriod     = InpRSIPeriod;
   g_cfg.rsiBuyMax     = InpRSIBuyMax;
   g_cfg.rsiSellMin    = InpRSISellMin;
   g_cfg.closedBar     = InpClosedBar;
   g_cfg.colorA        = InpColorA;
   g_cfg.colorB        = InpColorB;
   g_cfg.colorC        = InpColorC;
   g_cfg.colorZoneBuy  = InpZoneBuy;
   g_cfg.colorZoneSell = InpZoneSell;

   if(!g_engine.Init(_Symbol, (ENUM_TIMEFRAMES)_Period, g_cfg))
      return INIT_FAILED;

   IndicatorSetString(INDICATOR_SHORTNAME, "EliotWave ABC");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   g_engine.Erase(0, g_prefix);
   g_engine.Deinit();
   Comment("");
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total < InpDepth * 4)
      return 0;

   if(prev_calculated == 0)
     {
      ArrayInitialize(g_buy, EMPTY_VALUE);
      ArrayInitialize(g_sell, EMPTY_VALUE);
     }
   else
     {
      g_buy[0]  = EMPTY_VALUE;
      g_sell[0] = EMPTY_VALUE;
     }

   if(!g_engine.Update())
      return prev_calculated;

   g_engine.Draw(0, g_prefix, InpShowFibo);

   SEliotSignal sig = g_engine.Signal();
   SEliotPattern pat = g_engine.Pattern();

   if(sig.valid)
     {
      const int shift = iBarShift(_Symbol, PERIOD_CURRENT, sig.bar_time, true);
      if(shift >= 0)
        {
         if(sig.dir == EWA_BUY)
            g_buy[shift] = iLow(_Symbol, PERIOD_CURRENT, shift);
         else if(sig.dir == EWA_SELL)
            g_sell[shift] = iHigh(_Symbol, PERIOD_CURRENT, shift);
        }

      if(InpAlerts && sig.bar_time != g_lastAlert)
        {
         g_lastAlert = sig.bar_time;
         const string msg = StringFormat("%s %s | %s", _Symbol, EnumToString((ENUM_TIMEFRAMES)_Period), sig.reason);
         Alert("ELIOTWAVE ABC  ", msg);
         if(InpPush)
            SendNotification(msg);
        }
     }

   return rates_total;
  }
