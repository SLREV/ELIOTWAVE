//+------------------------------------------------------------------+
//|                                            EliotWaveABC_EA.mq5   |
//|     Expert Advisor MT5 — Elliott Wave ABC, entri pantulan C      |
//+------------------------------------------------------------------+
#property copyright   "ELIOTWAVE"
#property version     "1.00"
#property description "EA Elliott Wave ABC. Entri otomatis saat harga memantul di zona Fibonacci Wave C."

#include <Trade/Trade.mqh>
#include <EliotWaveABC.mqh>

input group "=== Deteksi Wave ==="
input int              InpDepth         = 12;      // Kedalaman swing
input int              InpMaxBars       = 800;     // Bar yang dipindai
input int              InpATRPeriod     = 14;      // Periode ATR
input double           InpMinSwingATR   = 0.40;    // Min swing (x ATR)
input double           InpMinWaveATR    = 0.80;    // Min Wave A (x ATR)
input bool             InpStrictZigzag  = true;    // B tidak melewati awal A

input group "=== Aturan ABC ==="
input double           InpBRetraceMin   = 0.382;   // Retrace B minimum
input double           InpBRetraceMax   = 0.886;   // Retrace B maksimum
input double           InpCFibMin       = 0.886;   // Zona C Fibonacci min
input double           InpCFibMax       = 1.618;   // Zona C Fibonacci max
input double           InpCFibInvalid   = 2.618;   // Invalid jika C > ini

input group "=== Pantulan Wave C (entri) ==="
input ENUM_EWA_BOUNCE  InpBounceMode    = EWA_BOUNCE_ANY; // Mode pantulan
input double           InpWickRatio     = 0.50;    // Rasio sumbu rejection
input bool             InpUseRSI        = true;    // Filter RSI
input int              InpRSIPeriod     = 14;      // Periode RSI
input double           InpRSIBuyMax     = 40.0;    // RSI max untuk BUY
input double           InpRSISellMin    = 60.0;    // RSI min untuk SELL
input bool             InpClosedBar     = true;    // Entri setelah bar tertutup
input bool             InpAllowBuy      = true;    // Izinkan BUY (pantulan C turun)
input bool             InpAllowSell     = true;    // Izinkan SELL (pantulan C naik)

input group "=== Manajemen risiko ==="
input bool             InpUseRiskPct    = true;    // Lot dari % risiko
input double           InpRiskPercent   = 1.0;     // Risiko per trade (% balance)
input double           InpFixedLots     = 0.01;    // Lot tetap jika % off
input double           InpSLAtr         = 0.35;    // Buffer SL (x ATR)
input ENUM_EWA_TP      InpTPMode        = EWA_TP_AUTO; // Mode Take Profit
input double           InpTPRR          = 2.0;     // Risk:Reward
input int              InpSlippage      = 20;      // Slippage (poin)
input int              InpMaxSpread     = 40;      // Spread maksimal (poin)
input ulong            InpMagic         = 20261014;// Magic number

input group "=== Trailing & breakeven ==="
input bool             InpUseBE         = true;    // Pindah SL ke breakeven
input double           InpBETriggerR    = 1.0;     // Trigger BE (x R)
input double           InpBELockR       = 0.10;    // Kunci profit BE (x R)
input bool             InpUseTrail      = true;    // Trailing stop
input double           InpTrailTriggerR = 1.2;     // Mulai trail (x R)
input double           InpTrailAtr      = 0.80;    // Jarak trail (x ATR)

input group "=== Filter waktu & proteksi ==="
input bool             InpUseTimeFilter = false;   // Filter jam server
input int              InpStartHour     = 1;       // Jam mulai
input int              InpEndHour       = 23;      // Jam selesai
input double           InpMaxDailyLoss  = 0.0;     // Max loss harian % (0=off)
input int              InpMaxTradesDay  = 0;       // Max trade / hari (0=off)
input bool             InpOnePerPattern = true;    // Satu posisi per pola ABC

input group "=== Tampilan chart ==="
input bool             InpDrawChart     = true;    // Gambar wave ABC di chart
input bool             InpShowFibo      = true;    // Fibonacci proyeksi C
input bool             InpAlerts        = true;    // Alert saat entri

CTrade        g_trade;
CEliotWaveABC g_engine;
SEliotConfig  g_cfg;
int           g_atrHandle = INVALID_HANDLE;
datetime      g_lastPatternId = 0;
datetime      g_dayStamp = 0;
int           g_tradesToday = 0;
string        g_prefix = "EWA_EA_";

int OnInit()
  {
   EwaDefaultConfig(g_cfg);
   g_cfg.depth         = InpDepth;
   g_cfg.maxBars       = InpMaxBars;
   g_cfg.atrPeriod     = InpATRPeriod;
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
   g_cfg.slAtr         = InpSLAtr;
   g_cfg.tpRR          = InpTPRR;
   g_cfg.tpMode        = InpTPMode;

   if(!g_engine.Init(_Symbol, (ENUM_TIMEFRAMES)_Period, g_cfg))
     {
      Print("EliotWaveABC_EA: inisialisasi mesin ABC gagal");
      return INIT_FAILED;
     }

   g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   if(g_atrHandle == INVALID_HANDLE)
      return INIT_FAILED;

   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetAsyncMode(false);
   SetFilling();

   ResetDayCounter();
   Print("EliotWaveABC_EA siap | ", _Symbol, " ", EnumToString((ENUM_TIMEFRAMES)_Period),
         " | entri pantulan zona C | magic ", InpMagic);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(InpDrawChart)
      g_engine.Erase(0, g_prefix);
   g_engine.Deinit();
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
   Comment("");
  }

void OnTick()
  {
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
      return;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      return;
   const long tradeMode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED || tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY)
      return;

   ResetDayCounter();
   ManageOpenPosition();

   if(!g_engine.Update())
      return;

   if(InpDrawChart)
      g_engine.Draw(0, g_prefix, InpShowFibo);

   if(!TradingWindow())
      return;
   if(DailyLossHit())
      return;
   if(InpMaxTradesDay > 0 && g_tradesToday >= InpMaxTradesDay)
      return;
   if(CountOurPositions() > 0)
      return;
   if(SpreadPoints() > InpMaxSpread)
      return;

   SEliotSignal sig = g_engine.Signal();
   if(!sig.valid)
      return;
   if(InpOnePerPattern && sig.pattern_id == g_lastPatternId)
      return;
   if(sig.dir == EWA_BUY && (!InpAllowBuy || tradeMode == SYMBOL_TRADE_MODE_SHORTONLY))
      return;
   if(sig.dir == EWA_SELL && (!InpAllowSell || tradeMode == SYMBOL_TRADE_MODE_LONGONLY))
      return;

   OpenFromSignal(sig);
  }

void OpenFromSignal(const SEliotSignal &sig)
  {
   double sl = sig.sl;
   double tp = sig.tp;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double entry = (sig.dir == EWA_BUY ? ask : bid);

   if(!AdjustStops(sig.dir, entry, sl, tp))
     {
      Print("EliotWaveABC_EA: SL/TP tidak valid setelah penyesuaian broker");
      return;
     }

   const double lots = ComputeLots(entry, sl);
   if(lots <= 0.0)
     {
      Print("EliotWaveABC_EA: lot tidak valid");
      return;
     }

   const string cmt = StringFormat("EWA ABC C=%.0f%%", sig.c_fib * 100.0);
   bool ok = false;
   if(sig.dir == EWA_BUY)
      ok = g_trade.Buy(lots, _Symbol, entry, sl, tp, cmt);
   else
      ok = g_trade.Sell(lots, _Symbol, entry, sl, tp, cmt);

   if(ok)
     {
      g_lastPatternId = sig.pattern_id;
      g_tradesToday++;
      const string msg = StringFormat("%s %s lot=%.2f SL=%.5f TP=%.5f | %s",
                                      (sig.dir == EWA_BUY ? "BUY" : "SELL"),
                                      _Symbol, lots, sl, tp, sig.reason);
      Print("EliotWaveABC_EA ENTRI: ", msg);
      if(InpAlerts)
         Alert("ELIOTWAVE ABC  ", msg);
     }
   else
      Print("EliotWaveABC_EA: order gagal ", g_trade.ResultRetcode(), " ", g_trade.ResultRetcodeDescription());
  }

double ComputeLots(const double entry, const double sl)
  {
   double vmin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(vstep <= 0.0)
      vstep = 0.01;

   double lots = InpFixedLots;
   if(InpUseRiskPct)
     {
      const double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
      const double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      const double tickVal   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      const double dist      = MathAbs(entry - sl);
      if(tickSize <= 0.0 || tickVal <= 0.0 || dist <= 0.0)
         lots = vmin;
      else
        {
         const double ticks = dist / tickSize;
         lots = riskMoney / (ticks * tickVal);
        }
     }

   lots = MathFloor(lots / vstep) * vstep;
   if(lots < vmin)
      lots = vmin;
   if(lots > vmax)
      lots = vmax;
   return NormalizeDouble(lots, 2);
  }

bool AdjustStops(const ENUM_EWA_DIR dir, const double entry, double &sl, double &tp)
  {
   const int    stops = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   const int    freeze = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   const double point  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   const int    digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double minDist = (stops + freeze + 2) * point;

   if(dir == EWA_BUY)
     {
      if(entry - sl < minDist)
         sl = entry - minDist;
      if(tp - entry < minDist)
         tp = entry + minDist;
     }
   else
     {
      if(sl - entry < minDist)
         sl = entry + minDist;
      if(entry - tp < minDist)
         tp = entry - minDist;
     }
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);
   if(dir == EWA_BUY)
      return (sl < entry && tp > entry);
   return (sl > entry && tp < entry);
  }

void ManageOpenPosition()
  {
   if(!InpUseBE && !InpUseTrail)
      return;

   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(g_atrHandle, 0, 0, 3, atr) < 1)
      return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;

      const long   type   = PositionGetInteger(POSITION_TYPE);
      const double open   = PositionGetDouble(POSITION_PRICE_OPEN);
      const double sl     = PositionGetDouble(POSITION_SL);
      const double tp     = PositionGetDouble(POSITION_TP);
      const double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      const double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      const double price  = (type == POSITION_TYPE_BUY ? bid : ask);
      const double slDist = MathAbs(open - sl);
      if(slDist <= 0.0)
         continue;
      const double profitR = (type == POSITION_TYPE_BUY ? (price - open) : (open - price)) / slDist;

      double newSL = sl;
      if(InpUseBE && profitR >= InpBETriggerR)
        {
         const double lock = slDist * InpBELockR;
         if(type == POSITION_TYPE_BUY)
           {
            const double be = open + lock;
            if(be > newSL)
               newSL = be;
           }
         else
           {
            const double be = open - lock;
            if(newSL == 0.0 || be < newSL)
               newSL = be;
           }
        }

      if(InpUseTrail && profitR >= InpTrailTriggerR)
        {
         const double trail = atr[0] * InpTrailAtr;
         if(type == POSITION_TYPE_BUY)
           {
            const double tsl = price - trail;
            if(tsl > newSL)
               newSL = tsl;
           }
         else
           {
            const double tsl = price + trail;
            if(newSL == 0.0 || tsl < newSL)
               newSL = tsl;
           }
        }

      const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      newSL = NormalizeDouble(newSL, digits);
      if(MathAbs(newSL - sl) > SymbolInfoDouble(_Symbol, SYMBOL_POINT))
        {
         if(type == POSITION_TYPE_BUY && newSL <= sl)
            continue;
         if(type == POSITION_TYPE_SELL && sl != 0.0 && newSL >= sl)
            continue;
         g_trade.PositionModify(ticket, newSL, tp);
        }
     }
  }

int CountOurPositions()
  {
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i) == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      n++;
     }
   return n;
  }

int SpreadPoints()
  {
   return (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
  }

bool TradingWindow()
  {
   if(!InpUseTimeFilter)
      return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(InpStartHour == InpEndHour)
      return true;
   if(InpStartHour < InpEndHour)
      return (dt.hour >= InpStartHour && dt.hour < InpEndHour);
   return (dt.hour >= InpStartHour || dt.hour < InpEndHour);
  }

void ResetDayCounter()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime stamp = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(stamp != g_dayStamp)
     {
      g_dayStamp = stamp;
      g_tradesToday = 0;
     }
  }

bool DailyLossHit()
  {
   if(InpMaxDailyLoss <= 0.0)
      return false;
   if(!HistorySelect(g_dayStamp, TimeCurrent()))
      return false;
   double pnl = 0.0;
   const int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++)
     {
      const ulong d = HistoryDealGetTicket(i);
      if(d == 0)
         continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol)
         continue;
      if((ulong)HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic)
         continue;
      if(HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_OUT &&
         HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_INOUT)
         continue;
      pnl += HistoryDealGetDouble(d, DEAL_PROFIT)
             + HistoryDealGetDouble(d, DEAL_SWAP)
             + HistoryDealGetDouble(d, DEAL_COMMISSION);
     }
   const double cap = AccountInfoDouble(ACCOUNT_BALANCE) * InpMaxDailyLoss / 100.0;
   return (pnl <= -cap);
  }

void SetFilling()
  {
   const long mode = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((mode & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else if((mode & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      g_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else
      g_trade.SetTypeFilling(ORDER_FILLING_RETURN);
  }
