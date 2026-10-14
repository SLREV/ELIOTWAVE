//+------------------------------------------------------------------+
//|                                               EliotWaveABC.mqh   |
//|                     ELIOTWAVE - Mesin deteksi Elliott Wave ABC   |
//|          Pola ABC otomatis, zona Fibonacci C, pantulan entri     |
//+------------------------------------------------------------------+
#ifndef ELIOTWAVEABC_MQH
#define ELIOTWAVEABC_MQH

enum ENUM_EWA_DIR
  {
   EWA_NONE = 0,
   EWA_BUY  = 1,
   EWA_SELL = -1
  };

enum ENUM_EWA_BOUNCE
  {
   EWA_BOUNCE_REJECTION = 0,  // Sumbu / wick rejection di zona C
   EWA_BOUNCE_PINBAR    = 1,  // Pin bar / hammer
   EWA_BOUNCE_ENGULFING = 2,  // Engulfing
   EWA_BOUNCE_ANY       = 3   // Salah satu pola reversal
  };

enum ENUM_EWA_TP
  {
   EWA_TP_RR       = 0,  // Risk:Reward
   EWA_TP_ORIGIN_A = 1,  // Awal Wave A
   EWA_TP_C_START  = 2,  // Awal Wave C (akhir B)
   EWA_TP_AUTO     = 3   // Origin A, fallback RR jika terlalu dekat
  };

struct SEliotConfig
  {
   int              depth;           // Kedalaman swing (bar kiri/kanan)
   int              atrPeriod;
   int              rsiPeriod;
   int              maxBars;
   double           minSwingAtr;     // Minimal ukuran swing vs ATR
   double           minWaveAtr;      // Minimal Wave A vs ATR
   double           bRetraceMin;     // Retrace B minimum (0.382)
   double           bRetraceMax;     // Retrace B maksimum (0.886)
   double           cFibMin;         // Zona C bawah (0.886)
   double           cFibMax;         // Zona C atas (1.618)
   double           cFibInvalid;     // C terlalu panjang (2.618)
   bool             strictZigzag;    // B tidak boleh melewati awal A
   bool             useRsi;
   double           rsiBuyMax;       // RSI maksimal untuk BUY
   double           rsiSellMin;      // RSI minimal untuk SELL
   ENUM_EWA_BOUNCE  bounceMode;
   double           wickRatio;       // Rasio sumbu untuk rejection
   bool             closedBar;       // Sinyal di bar yang sudah tutup
   double           slAtr;           // Buffer SL dalam ATR
   double           tpRR;            // RR jika mode RR
   ENUM_EWA_TP      tpMode;
   color            colorA;
   color            colorB;
   color            colorC;
   color            colorZoneBuy;
   color            colorZoneSell;
   color            colorSignal;
  };

struct SSwing
  {
   datetime time;
   double   price;
   int      type;   // +1 high, -1 low
   int      bar;
  };

struct SEliotPattern
  {
   bool         valid;
   ENUM_EWA_DIR dir;
   datetime     id;
   datetime     a_start_time;
   datetime     a_end_time;
   datetime     b_end_time;
   double       a_start;
   double       a_end;
   double       b_end;
   int          a_start_bar;
   int          a_end_bar;
   int          b_end_bar;
   double       waveA;
   double       waveB;
   double       retraceB;
   double       zone_high;
   double       zone_low;
   double       c_100;
   double       c_127;
   double       c_162;
   double       c_618;
   double       c_extreme;
   double       c_fib;
   string       status;
  };

struct SEliotSignal
  {
   bool         valid;
   ENUM_EWA_DIR dir;
   datetime     bar_time;
   datetime     pattern_id;
   double       entry;
   double       sl;
   double       tp;
   double       zone_high;
   double       zone_low;
   double       c_fib;
   string       reason;
  };

void EwaDefaultConfig(SEliotConfig &cfg)
  {
   cfg.depth          = 12;
   cfg.atrPeriod      = 14;
   cfg.rsiPeriod      = 14;
   cfg.maxBars        = 800;
   cfg.minSwingAtr    = 0.40;
   cfg.minWaveAtr     = 0.80;
   cfg.bRetraceMin    = 0.382;
   cfg.bRetraceMax    = 0.886;
   cfg.cFibMin        = 0.886;
   cfg.cFibMax        = 1.618;
   cfg.cFibInvalid    = 2.618;
   cfg.strictZigzag   = true;
   cfg.useRsi         = true;
   cfg.rsiBuyMax      = 40.0;
   cfg.rsiSellMin     = 60.0;
   cfg.bounceMode     = EWA_BOUNCE_ANY;
   cfg.wickRatio      = 0.50;
   cfg.closedBar      = true;
   cfg.slAtr          = 0.35;
   cfg.tpRR           = 2.0;
   cfg.tpMode         = EWA_TP_AUTO;
   cfg.colorA         = clrDodgerBlue;
   cfg.colorB         = clrOrange;
   cfg.colorC         = clrGold;
   cfg.colorZoneBuy   = clrForestGreen;
   cfg.colorZoneSell  = clrFireBrick;
   cfg.colorSignal    = clrAqua;
  }

class CEliotWaveABC
  {
private:
   string         m_symbol;
   ENUM_TIMEFRAMES m_tf;
   SEliotConfig   m_cfg;
   int            m_atrHandle;
   int            m_rsiHandle;
   int            m_digits;
   double         m_point;
   int            m_copied;

   double         m_open[];
   double         m_high[];
   double         m_low[];
   double         m_close[];
   datetime       m_time[];
   double         m_atr[];
   double         m_rsi[];

   SSwing         m_swings[80];
   int            m_swingCount;

   SEliotPattern  m_pat;
   SEliotSignal   m_sig;

   bool CopySeriesData(void);
   void BuildSwings(void);
   bool IsSwingHigh(const int i);
   bool IsSwingLow(const int i);
   void AddOrMergeSwing(const int bar, const int type);
   void DetectPattern(void);
   void FillBuyPattern(const SSwing &swA, const SSwing &swAend, const SSwing &swB);
   void FillSellPattern(const SSwing &swA, const SSwing &swAend, const SSwing &swB);
   void UpdateWaveC(void);
   void DetectBounce(void);
   bool BarInZone(const int i);
   bool IsRejection(const int i, const ENUM_EWA_DIR dir);
   bool IsPinBar(const int i, const ENUM_EWA_DIR dir);
   bool IsEngulfing(const int i, const ENUM_EWA_DIR dir);
   bool RsiOk(const int i, const ENUM_EWA_DIR dir);
   bool BounceOk(const int i, const ENUM_EWA_DIR dir);
   double LowestSince(const int fromBar);
   double HighestSince(const int fromBar);
   double AtrSafe(const int i);
   double ComputeSL(const ENUM_EWA_DIR dir, const int i, const double entry);
   double ComputeTP(const ENUM_EWA_DIR dir, const double entry, const double sl);
   void   FillTradePlan(double &entry, double &sl, double &tp1, double &tp2, double &tp3);
   void   DrawRay(const long chartId, const string name, const datetime t1, const datetime t2,
                  const double price, const color clr, const string text, const int width);
   void   ClearPattern(void);
   void   DeletePrefix(const long chartId, const string prefix);

public:
   CEliotWaveABC(void);
   ~CEliotWaveABC(void);

   bool Init(const string symbol, const ENUM_TIMEFRAMES tf, const SEliotConfig &cfg);
   void Deinit(void);
   bool Update(void);

   SEliotPattern Pattern(void) const { return m_pat; }
   SEliotSignal  Signal(void)  const { return m_sig; }
   bool          HasPattern(void) const { return m_pat.valid; }
   ENUM_EWA_DIR  Direction(void) const { return m_pat.dir; }

   void Draw(const long chartId, const string prefix, const bool showFibo);
   void Erase(const long chartId, const string prefix);
  };

CEliotWaveABC::CEliotWaveABC(void)
  {
   m_symbol     = "";
   m_tf         = PERIOD_CURRENT;
   m_atrHandle  = INVALID_HANDLE;
   m_rsiHandle  = INVALID_HANDLE;
   m_digits     = 5;
   m_point      = 0.00001;
   m_copied     = 0;
   m_swingCount = 0;
   EwaDefaultConfig(m_cfg);
   ClearPattern();
   m_sig.valid = false;
  }

CEliotWaveABC::~CEliotWaveABC(void)
  {
   Deinit();
  }

bool CEliotWaveABC::Init(const string symbol, const ENUM_TIMEFRAMES tf, const SEliotConfig &cfg)
  {
   Deinit();
   m_symbol = symbol;
   m_tf     = tf;
   m_cfg    = cfg;
   if(m_cfg.depth < 2)
      m_cfg.depth = 2;
   if(m_cfg.maxBars < 200)
      m_cfg.maxBars = 200;
   m_digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   m_point  = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   m_atrHandle = iATR(m_symbol, m_tf, m_cfg.atrPeriod);
   m_rsiHandle = iRSI(m_symbol, m_tf, m_cfg.rsiPeriod, PRICE_CLOSE);
   if(m_atrHandle == INVALID_HANDLE || m_rsiHandle == INVALID_HANDLE)
     {
      Print("EliotWaveABC: gagal membuat handle ATR/RSI");
      return false;
     }
   ArraySetAsSeries(m_open, true);
   ArraySetAsSeries(m_high, true);
   ArraySetAsSeries(m_low, true);
   ArraySetAsSeries(m_close, true);
   ArraySetAsSeries(m_time, true);
   ArraySetAsSeries(m_atr, true);
   ArraySetAsSeries(m_rsi, true);
   return true;
  }

void CEliotWaveABC::Deinit(void)
  {
   if(m_atrHandle != INVALID_HANDLE)
     {
      IndicatorRelease(m_atrHandle);
      m_atrHandle = INVALID_HANDLE;
     }
   if(m_rsiHandle != INVALID_HANDLE)
     {
      IndicatorRelease(m_rsiHandle);
      m_rsiHandle = INVALID_HANDLE;
     }
  }

bool CEliotWaveABC::Update(void)
  {
   m_sig.valid = false;
   if(!CopySeriesData())
      return false;
   BuildSwings();
   DetectPattern();
   if(m_pat.valid)
     {
      UpdateWaveC();
      DetectBounce();
     }
   return true;
  }

bool CEliotWaveABC::CopySeriesData(void)
  {
   int need = m_cfg.maxBars;
   m_copied = CopyOpen(m_symbol, m_tf, 0, need, m_open);
   if(m_copied < m_cfg.depth * 4 + 50)
      return false;
   if(CopyHigh(m_symbol, m_tf, 0, m_copied, m_high) < m_copied)
      return false;
   if(CopyLow(m_symbol, m_tf, 0, m_copied, m_low) < m_copied)
      return false;
   if(CopyClose(m_symbol, m_tf, 0, m_copied, m_close) < m_copied)
      return false;
   if(CopyTime(m_symbol, m_tf, 0, m_copied, m_time) < m_copied)
      return false;
   if(CopyBuffer(m_atrHandle, 0, 0, m_copied, m_atr) < m_copied)
      return false;
   if(CopyBuffer(m_rsiHandle, 0, 0, m_copied, m_rsi) < m_copied)
      return false;
   return true;
  }

bool CEliotWaveABC::IsSwingHigh(const int i)
  {
   if(i < m_cfg.depth || i + m_cfg.depth >= m_copied)
      return false;
   const double h = m_high[i];
   for(int d = 1; d <= m_cfg.depth; d++)
     {
      if(m_high[i + d] > h)
         return false;
      if(m_high[i - d] >= h)
         return false;
     }
   return true;
  }

bool CEliotWaveABC::IsSwingLow(const int i)
  {
   if(i < m_cfg.depth || i + m_cfg.depth >= m_copied)
      return false;
   const double l = m_low[i];
   for(int d = 1; d <= m_cfg.depth; d++)
     {
      if(m_low[i + d] < l)
         return false;
      if(m_low[i - d] <= l)
         return false;
     }
   return true;
  }

void CEliotWaveABC::AddOrMergeSwing(const int bar, const int type)
  {
   const double price = (type > 0 ? m_high[bar] : m_low[bar]);
   if(m_swingCount > 0)
     {
      SSwing last = m_swings[m_swingCount - 1];
      if(last.type == type)
        {
         const bool better = (type > 0 ? price >= last.price : price <= last.price);
         if(better)
           {
            m_swings[m_swingCount - 1].time  = m_time[bar];
            m_swings[m_swingCount - 1].price = price;
            m_swings[m_swingCount - 1].bar   = bar;
           }
         return;
        }
      const double atr = AtrSafe(bar);
      if(atr > 0.0 && MathAbs(price - last.price) < atr * m_cfg.minSwingAtr)
         return;
     }
   if(m_swingCount >= 80)
     {
      for(int k = 1; k < 80; k++)
         m_swings[k - 1] = m_swings[k];
      m_swingCount = 79;
     }
   m_swings[m_swingCount].time  = m_time[bar];
   m_swings[m_swingCount].price = price;
   m_swings[m_swingCount].type  = type;
   m_swings[m_swingCount].bar   = bar;
   m_swingCount++;
  }

void CEliotWaveABC::BuildSwings(void)
  {
   m_swingCount = 0;
   const int start = m_copied - 1 - m_cfg.depth;
   const int end   = m_cfg.depth;
   for(int i = start; i >= end; i--)
     {
      const bool sh = IsSwingHigh(i);
      const bool sl = IsSwingLow(i);
      if(sh && !sl)
         AddOrMergeSwing(i, +1);
      else if(sl && !sh)
         AddOrMergeSwing(i, -1);
     }
  }

void CEliotWaveABC::ClearPattern(void)
  {
   m_pat.valid        = false;
   m_pat.dir          = EWA_NONE;
   m_pat.id           = 0;
   m_pat.a_start_time = 0;
   m_pat.a_end_time   = 0;
   m_pat.b_end_time   = 0;
   m_pat.a_start      = 0;
   m_pat.a_end        = 0;
   m_pat.b_end        = 0;
   m_pat.a_start_bar  = 0;
   m_pat.a_end_bar    = 0;
   m_pat.b_end_bar    = 0;
   m_pat.waveA        = 0;
   m_pat.waveB        = 0;
   m_pat.retraceB     = 0;
   m_pat.zone_high    = 0;
   m_pat.zone_low     = 0;
   m_pat.c_100        = 0;
   m_pat.c_127        = 0;
   m_pat.c_162        = 0;
   m_pat.c_618        = 0;
   m_pat.c_extreme    = 0;
   m_pat.c_fib        = 0;
   m_pat.status       = "Tidak ada pola ABC";
  }

void CEliotWaveABC::DetectPattern(void)
  {
   ClearPattern();
   if(m_swingCount < 3)
      return;

   const SSwing swB    = m_swings[m_swingCount - 1];
   const SSwing swAend = m_swings[m_swingCount - 2];
   const SSwing swA    = m_swings[m_swingCount - 3];

   if(swA.type > 0 && swAend.type < 0 && swB.type > 0)
      FillBuyPattern(swA, swAend, swB);
   else if(swA.type < 0 && swAend.type > 0 && swB.type < 0)
      FillSellPattern(swA, swAend, swB);
  }

void CEliotWaveABC::FillBuyPattern(const SSwing &swA, const SSwing &swAend, const SSwing &swB)
  {
   const double waveA = swA.price - swAend.price;
   const double waveB = swB.price - swAend.price;
   if(waveA <= 0.0 || waveB <= 0.0)
      return;
   const double atr = AtrSafe(swAend.bar);
   if(atr > 0.0 && waveA < atr * m_cfg.minWaveAtr)
      return;
   const double retr = waveB / waveA;
   if(retr < m_cfg.bRetraceMin || retr > m_cfg.bRetraceMax)
      return;
   if(m_cfg.strictZigzag && swB.price >= swA.price)
      return;

   m_pat.valid        = true;
   m_pat.dir          = EWA_BUY;
   m_pat.id           = swB.time;
   m_pat.a_start_time = swA.time;
   m_pat.a_end_time   = swAend.time;
   m_pat.b_end_time   = swB.time;
   m_pat.a_start      = swA.price;
   m_pat.a_end        = swAend.price;
   m_pat.b_end        = swB.price;
   m_pat.a_start_bar  = swA.bar;
   m_pat.a_end_bar    = swAend.bar;
   m_pat.b_end_bar    = swB.bar;
   m_pat.waveA        = waveA;
   m_pat.waveB        = waveB;
   m_pat.retraceB     = retr;
   m_pat.c_618        = swB.price - waveA * 0.618;
   m_pat.c_100        = swB.price - waveA * 1.000;
   m_pat.c_127        = swB.price - waveA * 1.272;
   m_pat.c_162        = swB.price - waveA * 1.618;
   const double z1    = swB.price - waveA * m_cfg.cFibMin;
   const double z2    = swB.price - waveA * m_cfg.cFibMax;
   m_pat.zone_high    = MathMax(z1, z2);
   m_pat.zone_low     = MathMin(z1, z2);
   m_pat.status       = "ABC BUY: menunggu Wave C ke zona pantulan";
  }

void CEliotWaveABC::FillSellPattern(const SSwing &swA, const SSwing &swAend, const SSwing &swB)
  {
   const double waveA = swAend.price - swA.price;
   const double waveB = swAend.price - swB.price;
   if(waveA <= 0.0 || waveB <= 0.0)
      return;
   const double atr = AtrSafe(swAend.bar);
   if(atr > 0.0 && waveA < atr * m_cfg.minWaveAtr)
      return;
   const double retr = waveB / waveA;
   if(retr < m_cfg.bRetraceMin || retr > m_cfg.bRetraceMax)
      return;
   if(m_cfg.strictZigzag && swB.price <= swA.price)
      return;

   m_pat.valid        = true;
   m_pat.dir          = EWA_SELL;
   m_pat.id           = swB.time;
   m_pat.a_start_time = swA.time;
   m_pat.a_end_time   = swAend.time;
   m_pat.b_end_time   = swB.time;
   m_pat.a_start      = swA.price;
   m_pat.a_end        = swAend.price;
   m_pat.b_end        = swB.price;
   m_pat.a_start_bar  = swA.bar;
   m_pat.a_end_bar    = swAend.bar;
   m_pat.b_end_bar    = swB.bar;
   m_pat.waveA        = waveA;
   m_pat.waveB        = waveB;
   m_pat.retraceB     = retr;
   m_pat.c_618        = swB.price + waveA * 0.618;
   m_pat.c_100        = swB.price + waveA * 1.000;
   m_pat.c_127        = swB.price + waveA * 1.272;
   m_pat.c_162        = swB.price + waveA * 1.618;
   const double z1    = swB.price + waveA * m_cfg.cFibMin;
   const double z2    = swB.price + waveA * m_cfg.cFibMax;
   m_pat.zone_high    = MathMax(z1, z2);
   m_pat.zone_low     = MathMin(z1, z2);
   m_pat.status       = "ABC SELL: menunggu Wave C ke zona pantulan";
  }

void CEliotWaveABC::UpdateWaveC(void)
  {
   if(!m_pat.valid)
      return;

   if(m_pat.dir == EWA_BUY)
     {
      if(m_high[0] > m_pat.b_end)
        {
         m_pat.valid  = false;
         m_pat.status = "ABC BUY invalid: harga pecah di atas B";
         return;
        }
      m_pat.c_extreme = LowestSince(m_pat.b_end_bar);
      if(m_pat.waveA > 0.0)
         m_pat.c_fib = (m_pat.b_end - m_pat.c_extreme) / m_pat.waveA;
      const double invalidLow = m_pat.b_end - m_pat.waveA * m_cfg.cFibInvalid;
      if(m_pat.c_extreme < invalidLow)
        {
         m_pat.valid  = false;
         m_pat.status = "ABC BUY invalid: Wave C tembus 2.618";
         return;
        }
      if(m_pat.c_extreme > m_pat.zone_high)
         m_pat.status = StringFormat("ABC BUY: C berjalan (%.0f%% A), menunggu zona C", m_pat.c_fib * 100.0);
      else
         m_pat.status = StringFormat("ABC BUY: harga di zona C (%.0f%% A) — pantauan pantulan", m_pat.c_fib * 100.0);
     }
   else if(m_pat.dir == EWA_SELL)
     {
      if(m_low[0] < m_pat.b_end)
        {
         m_pat.valid  = false;
         m_pat.status = "ABC SELL invalid: harga pecah di bawah B";
         return;
        }
      m_pat.c_extreme = HighestSince(m_pat.b_end_bar);
      if(m_pat.waveA > 0.0)
         m_pat.c_fib = (m_pat.c_extreme - m_pat.b_end) / m_pat.waveA;
      const double invalidHigh = m_pat.b_end + m_pat.waveA * m_cfg.cFibInvalid;
      if(m_pat.c_extreme > invalidHigh)
        {
         m_pat.valid  = false;
         m_pat.status = "ABC SELL invalid: Wave C tembus 2.618";
         return;
        }
      if(m_pat.c_extreme < m_pat.zone_low)
         m_pat.status = StringFormat("ABC SELL: C berjalan (%.0f%% A), menunggu zona C", m_pat.c_fib * 100.0);
      else
         m_pat.status = StringFormat("ABC SELL: harga di zona C (%.0f%% A) — pantauan pantulan", m_pat.c_fib * 100.0);
     }
  }

bool CEliotWaveABC::BarInZone(const int i)
  {
   if(i < 0 || i >= m_copied)
      return false;
   if(m_pat.dir == EWA_BUY)
      return (m_low[i] <= m_pat.zone_high && m_low[i] >= m_pat.zone_low - AtrSafe(i) * 0.15);
   return (m_high[i] >= m_pat.zone_low && m_high[i] <= m_pat.zone_high + AtrSafe(i) * 0.15);
  }

bool CEliotWaveABC::IsRejection(const int i, const ENUM_EWA_DIR dir)
  {
   const double range = m_high[i] - m_low[i];
   if(range <= 0.0)
      return false;
   const double body  = MathAbs(m_close[i] - m_open[i]);
   const double lower = MathMin(m_open[i], m_close[i]) - m_low[i];
   const double upper = m_high[i] - MathMax(m_open[i], m_close[i]);
   if(dir == EWA_BUY)
     {
      if(lower / range < m_cfg.wickRatio)
         return false;
      if(m_close[i] < m_open[i] && (m_close[i] - m_low[i]) / range < 0.50)
         return false;
      return (m_low[i] <= m_pat.zone_high);
     }
   if(upper / range < m_cfg.wickRatio)
      return false;
   if(m_close[i] > m_open[i] && (m_high[i] - m_close[i]) / range < 0.50)
      return false;
   return (m_high[i] >= m_pat.zone_low);
  }

bool CEliotWaveABC::IsPinBar(const int i, const ENUM_EWA_DIR dir)
  {
   const double range = m_high[i] - m_low[i];
   if(range <= 0.0)
      return false;
   const double body  = MathAbs(m_close[i] - m_open[i]);
   const double lower = MathMin(m_open[i], m_close[i]) - m_low[i];
   const double upper = m_high[i] - MathMax(m_open[i], m_close[i]);
   if(body / range > 0.35)
      return false;
   if(dir == EWA_BUY)
      return (lower >= range * 0.60 && m_close[i] > m_low[i] + range * 0.55);
   return (upper >= range * 0.60 && m_close[i] < m_high[i] - range * 0.55);
  }

bool CEliotWaveABC::IsEngulfing(const int i, const ENUM_EWA_DIR dir)
  {
   if(i + 1 >= m_copied)
      return false;
   const double prevBody = MathAbs(m_close[i + 1] - m_open[i + 1]);
   const double body     = MathAbs(m_close[i] - m_open[i]);
   if(body < prevBody * 0.9)
      return false;
   if(dir == EWA_BUY)
     {
      if(!(m_close[i + 1] < m_open[i + 1]))
         return false;
      if(!(m_close[i] > m_open[i]))
         return false;
      return (m_open[i] <= m_close[i + 1] && m_close[i] >= m_open[i + 1]);
     }
   if(!(m_close[i + 1] > m_open[i + 1]))
      return false;
   if(!(m_close[i] < m_open[i]))
      return false;
   return (m_open[i] >= m_close[i + 1] && m_close[i] <= m_open[i + 1]);
  }

bool CEliotWaveABC::RsiOk(const int i, const ENUM_EWA_DIR dir)
  {
   if(!m_cfg.useRsi)
      return true;
   if(i < 0 || i >= ArraySize(m_rsi))
      return false;
   if(dir == EWA_BUY)
      return (m_rsi[i] <= m_cfg.rsiBuyMax);
   return (m_rsi[i] >= m_cfg.rsiSellMin);
  }

bool CEliotWaveABC::BounceOk(const int i, const ENUM_EWA_DIR dir)
  {
   if(!BarInZone(i))
      return false;
   bool ok = false;
   switch(m_cfg.bounceMode)
     {
      case EWA_BOUNCE_REJECTION:
         ok = IsRejection(i, dir);
         break;
      case EWA_BOUNCE_PINBAR:
         ok = IsPinBar(i, dir);
         break;
      case EWA_BOUNCE_ENGULFING:
         ok = IsEngulfing(i, dir);
         break;
      default:
         ok = (IsRejection(i, dir) || IsPinBar(i, dir) || IsEngulfing(i, dir));
         if(!ok && dir == EWA_BUY)
            ok = (m_close[i] > m_open[i] && m_low[i] <= m_pat.zone_high);
         if(!ok && dir == EWA_SELL)
            ok = (m_close[i] < m_open[i] && m_high[i] >= m_pat.zone_low);
         break;
     }
   if(!ok)
      return false;
   return RsiOk(i, dir);
  }

void CEliotWaveABC::DetectBounce(void)
  {
   m_sig.valid = false;
   if(!m_pat.valid)
      return;
   if(m_pat.c_fib < m_cfg.cFibMin)
      return;

   const int i = (m_cfg.closedBar ? 1 : 0);
   if(i >= m_copied)
      return;

   if(m_pat.dir == EWA_BUY)
     {
      if(m_close[i] < m_pat.zone_low)
         return;
     }
   else
     {
      if(m_close[i] > m_pat.zone_high)
         return;
     }

   if(!BounceOk(i, m_pat.dir))
      return;

   const double entry = m_close[i];
   const double sl    = ComputeSL(m_pat.dir, i, entry);
   const double tp    = ComputeTP(m_pat.dir, entry, sl);
   if(sl <= 0.0 || tp <= 0.0)
      return;
   if(m_pat.dir == EWA_BUY && !(sl < entry && tp > entry))
      return;
   if(m_pat.dir == EWA_SELL && !(sl > entry && tp < entry))
      return;

   m_sig.valid      = true;
   m_sig.dir        = m_pat.dir;
   m_sig.bar_time   = m_time[i];
   m_sig.pattern_id = m_pat.id;
   m_sig.entry      = NormalizeDouble(entry, m_digits);
   m_sig.sl         = NormalizeDouble(sl, m_digits);
   m_sig.tp         = NormalizeDouble(tp, m_digits);
   m_sig.zone_high  = m_pat.zone_high;
   m_sig.zone_low   = m_pat.zone_low;
   m_sig.c_fib      = m_pat.c_fib;
   m_sig.reason     = (m_pat.dir == EWA_BUY
                       ? StringFormat("PANTULAN C BUY | C=%.0f%%A | B retrace=%.0f%%", m_pat.c_fib * 100.0, m_pat.retraceB * 100.0)
                       : StringFormat("PANTULAN C SELL | C=%.0f%%A | B retrace=%.0f%%", m_pat.c_fib * 100.0, m_pat.retraceB * 100.0));
   m_pat.status     = "SINYAL PANTULAN WAVE C";
  }

double CEliotWaveABC::ComputeSL(const ENUM_EWA_DIR dir, const int i, const double entry)
  {
   const double atr = AtrSafe(i);
   const double buf = atr * m_cfg.slAtr;
   if(dir == EWA_BUY)
     {
      double sl = MathMin(m_low[i], m_pat.c_extreme) - buf;
      if(sl >= entry)
         sl = entry - MathMax(buf, atr);
      return sl;
     }
   double sls = MathMax(m_high[i], m_pat.c_extreme) + buf;
   if(sls <= entry)
      sls = entry + MathMax(buf, atr);
   return sls;
  }

double CEliotWaveABC::ComputeTP(const ENUM_EWA_DIR dir, const double entry, const double sl)
  {
   const double dist = MathAbs(entry - sl);
   const double rr   = (dir == EWA_BUY ? entry + dist * m_cfg.tpRR : entry - dist * m_cfg.tpRR);
   double structural = rr;
   if(m_cfg.tpMode == EWA_TP_ORIGIN_A || m_cfg.tpMode == EWA_TP_AUTO)
      structural = m_pat.a_start;
   else if(m_cfg.tpMode == EWA_TP_C_START)
      structural = m_pat.b_end;
   else
      return rr;

   if(m_cfg.tpMode == EWA_TP_RR)
      return rr;

   if(dir == EWA_BUY)
     {
      if(structural <= entry)
         return rr;
      if(m_cfg.tpMode == EWA_TP_AUTO && (structural - entry) < dist * 1.2)
         return rr;
      return structural;
     }
   if(structural >= entry)
      return rr;
   if(m_cfg.tpMode == EWA_TP_AUTO && (entry - structural) < dist * 1.2)
      return rr;
   return structural;
  }

double CEliotWaveABC::LowestSince(const int fromBar)
  {
   double v = m_low[0];
   const int last = MathMin(fromBar, m_copied - 1);
   for(int i = 0; i <= last; i++)
      if(m_low[i] < v)
         v = m_low[i];
   return v;
  }

double CEliotWaveABC::HighestSince(const int fromBar)
  {
   double v = m_high[0];
   const int last = MathMin(fromBar, m_copied - 1);
   for(int i = 0; i <= last; i++)
      if(m_high[i] > v)
         v = m_high[i];
   return v;
  }

double CEliotWaveABC::AtrSafe(const int i)
  {
   if(i < 0 || i >= ArraySize(m_atr))
      return 0.0;
   return (m_atr[i] > 0.0 ? m_atr[i] : 0.0);
  }

void CEliotWaveABC::FillTradePlan(double &entry, double &sl, double &tp1, double &tp2, double &tp3)
  {
   entry = 0;
   sl = 0;
   tp1 = 0;
   tp2 = 0;
   tp3 = 0;
   if(!m_pat.valid)
      return;

   const double atr = AtrSafe(0);
   const double buf = (atr > 0.0 ? atr * m_cfg.slAtr : m_pat.waveA * 0.05);
   const bool   buy = (m_pat.dir == EWA_BUY);
   const bool   inZ = buy
                      ? (m_close[0] <= m_pat.zone_high && m_close[0] >= m_pat.zone_low)
                      : (m_close[0] >= m_pat.zone_low && m_close[0] <= m_pat.zone_high);

   if(m_sig.valid)
      entry = m_sig.entry;
   else if(inZ)
      entry = m_close[0];
   else
      entry = m_pat.c_100;

   double cEnd = m_pat.c_extreme;
   double cLen = buy ? (m_pat.b_end - cEnd) : (cEnd - m_pat.b_end);
   if(cLen <= 0.0)
     {
      cEnd = m_pat.c_100;
      cLen = m_pat.waveA;
     }

   if(buy)
     {
      sl  = MathMin(m_pat.c_extreme, m_pat.zone_low) - buf;
      tp1 = cEnd + cLen * 0.618;
      tp2 = m_pat.b_end;
      tp3 = m_pat.a_start;
      if(sl >= entry)
         sl = entry - buf;
     }
   else
     {
      sl  = MathMax(m_pat.c_extreme, m_pat.zone_high) + buf;
      tp1 = cEnd - cLen * 0.618;
      tp2 = m_pat.b_end;
      tp3 = m_pat.a_start;
      if(sl <= entry)
         sl = entry + buf;
     }
  }

void CEliotWaveABC::DrawRay(const long chartId, const string name, const datetime t1, const datetime t2,
                            const double price, const color clr, const string text, const int width)
  {
   ObjectCreate(chartId, name, OBJ_TREND, 0, t1, price, t2, price);
   ObjectSetInteger(chartId, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(chartId, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(chartId, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(chartId, name, OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(chartId, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, name, OBJPROP_BACK, true);
   const string tn = name + "_LBL";
   ObjectCreate(chartId, tn, OBJ_TEXT, 0, t2, price);
   ObjectSetString(chartId, tn, OBJPROP_TEXT, "  " + text);
   ObjectSetInteger(chartId, tn, OBJPROP_COLOR, clr);
   ObjectSetInteger(chartId, tn, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(chartId, tn, OBJPROP_ANCHOR, ANCHOR_LEFT);
   ObjectSetInteger(chartId, tn, OBJPROP_SELECTABLE, false);
  }

void CEliotWaveABC::DeletePrefix(const long chartId, const string prefix)
  {
   int total = ObjectsTotal(chartId, -1, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      const string name = ObjectName(chartId, i, -1, -1);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(chartId, name);
     }
  }

void CEliotWaveABC::Erase(const long chartId, const string prefix)
  {
   DeletePrefix(chartId, prefix);
  }

void CEliotWaveABC::Draw(const long chartId, const string prefix, const bool showFibo)
  {
   DeletePrefix(chartId, prefix);
   if(!m_pat.valid)
     {
      const string lab = prefix + "STATUS";
      ObjectCreate(chartId, lab, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(chartId, lab, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(chartId, lab, OBJPROP_XDISTANCE, 12);
      ObjectSetInteger(chartId, lab, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(chartId, lab, OBJPROP_COLOR, clrSilver);
      ObjectSetInteger(chartId, lab, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(chartId, lab, OBJPROP_SELECTABLE, false);
      ObjectSetString(chartId, lab, OBJPROP_TEXT, "ELIOTWAVE ABC  |  " + m_pat.status);
      ObjectSetString(chartId, lab, OBJPROP_FONT, "Consolas");
      return;
     }

   const datetime tA  = m_pat.a_start_time;
   const datetime tAe = m_pat.a_end_time;
   const datetime tB  = m_pat.b_end_time;
   const datetime tNow = m_time[0];
   const double   cNow = m_pat.c_extreme;

   string nA = prefix + "WAVE_A";
   ObjectCreate(chartId, nA, OBJ_TREND, 0, tA, m_pat.a_start, tAe, m_pat.a_end);
   ObjectSetInteger(chartId, nA, OBJPROP_COLOR, m_cfg.colorA);
   ObjectSetInteger(chartId, nA, OBJPROP_WIDTH, 3);
   ObjectSetInteger(chartId, nA, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(chartId, nA, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, nA, OBJPROP_BACK, false);

   string nB = prefix + "WAVE_B";
   ObjectCreate(chartId, nB, OBJ_TREND, 0, tAe, m_pat.a_end, tB, m_pat.b_end);
   ObjectSetInteger(chartId, nB, OBJPROP_COLOR, m_cfg.colorB);
   ObjectSetInteger(chartId, nB, OBJPROP_WIDTH, 3);
   ObjectSetInteger(chartId, nB, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(chartId, nB, OBJPROP_SELECTABLE, false);

   string nC = prefix + "WAVE_C";
   ObjectCreate(chartId, nC, OBJ_TREND, 0, tB, m_pat.b_end, tNow, cNow);
   ObjectSetInteger(chartId, nC, OBJPROP_COLOR, m_cfg.colorC);
   ObjectSetInteger(chartId, nC, OBJPROP_WIDTH, 3);
   ObjectSetInteger(chartId, nC, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(chartId, nC, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(chartId, nC, OBJPROP_SELECTABLE, false);

   const datetime tRight = tNow + PeriodSeconds(m_tf) * 12;
   const color    zCol   = (m_pat.dir == EWA_BUY ? m_cfg.colorZoneBuy : m_cfg.colorZoneSell);
   const bool     isLong = (m_pat.dir == EWA_BUY);

   string nZ = prefix + "ZONE_ENTRY";
   ObjectCreate(chartId, nZ, OBJ_RECTANGLE, 0, tB, m_pat.zone_high, tRight, m_pat.zone_low);
   ObjectSetInteger(chartId, nZ, OBJPROP_COLOR, zCol);
   ObjectSetInteger(chartId, nZ, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(chartId, nZ, OBJPROP_WIDTH, 2);
   ObjectSetInteger(chartId, nZ, OBJPROP_FILL, true);
   ObjectSetInteger(chartId, nZ, OBJPROP_BACK, true);
   ObjectSetInteger(chartId, nZ, OBJPROP_SELECTABLE, false);

   string nZlbl = prefix + "ZONE_ENTRY_LBL";
   ObjectCreate(chartId, nZlbl, OBJ_TEXT, 0, tB, (m_pat.zone_high + m_pat.zone_low) * 0.5);
   ObjectSetString(chartId, nZlbl, OBJPROP_TEXT, isLong ? "  LONG ENTRY  (zona C)" : "  SHORT ENTRY  (zona C)");
   ObjectSetInteger(chartId, nZlbl, OBJPROP_COLOR, zCol);
   ObjectSetInteger(chartId, nZlbl, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(chartId, nZlbl, OBJPROP_ANCHOR, ANCHOR_LEFT);
   ObjectSetInteger(chartId, nZlbl, OBJPROP_SELECTABLE, false);

   if(showFibo)
     {
      string nF = prefix + "FIBO_C";
      const double p2 = (isLong ? m_pat.b_end - m_pat.waveA : m_pat.b_end + m_pat.waveA);
      ObjectCreate(chartId, nF, OBJ_FIBO, 0, tB, m_pat.b_end, tNow, p2);
      ObjectSetInteger(chartId, nF, OBJPROP_COLOR, clrGoldenrod);
      ObjectSetInteger(chartId, nF, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(chartId, nF, OBJPROP_LEVELS, 6);
      ObjectSetInteger(chartId, nF, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chartId, nF, OBJPROP_BACK, true);
      const double lv[6]  = {0.0, 0.618, 1.0, 1.272, 1.618, 2.618};
      const string fl[6]  = {"C 0% (awal C)", "C 61.8%", "C 100%", "C 127.2%", "C 161.8%  zona", "C 261.8% invalid"};
      for(int k = 0; k < 6; k++)
        {
         ObjectSetDouble(chartId, nF, OBJPROP_LEVELVALUE, k, lv[k]);
         ObjectSetString(chartId, nF, OBJPROP_LEVELTEXT, k, fl[k]);
         ObjectSetInteger(chartId, nF, OBJPROP_LEVELCOLOR, k, clrGoldenrod);
         ObjectSetInteger(chartId, nF, OBJPROP_LEVELSTYLE, k, STYLE_DOT);
        }
     }

   string la = prefix + "LBL_A";
   ObjectCreate(chartId, la, OBJ_TEXT, 0, tA, m_pat.a_start);
   ObjectSetString(chartId, la, OBJPROP_TEXT, "  A");
   ObjectSetInteger(chartId, la, OBJPROP_COLOR, m_cfg.colorA);
   ObjectSetInteger(chartId, la, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(chartId, la, OBJPROP_ANCHOR, (isLong ? ANCHOR_LOWER : ANCHOR_UPPER));
   ObjectSetInteger(chartId, la, OBJPROP_SELECTABLE, false);

   string lb = prefix + "LBL_B";
   ObjectCreate(chartId, lb, OBJ_TEXT, 0, tB, m_pat.b_end);
   ObjectSetString(chartId, lb, OBJPROP_TEXT, "  B");
   ObjectSetInteger(chartId, lb, OBJPROP_COLOR, m_cfg.colorB);
   ObjectSetInteger(chartId, lb, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(chartId, lb, OBJPROP_ANCHOR, (isLong ? ANCHOR_LOWER : ANCHOR_UPPER));
   ObjectSetInteger(chartId, lb, OBJPROP_SELECTABLE, false);

   string lc = prefix + "LBL_C";
   ObjectCreate(chartId, lc, OBJ_TEXT, 0, tNow, cNow);
   ObjectSetString(chartId, lc, OBJPROP_TEXT, "  C");
   ObjectSetInteger(chartId, lc, OBJPROP_COLOR, m_cfg.colorC);
   ObjectSetInteger(chartId, lc, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(chartId, lc, OBJPROP_ANCHOR, (isLong ? ANCHOR_UPPER : ANCHOR_LOWER));
   ObjectSetInteger(chartId, lc, OBJPROP_SELECTABLE, false);

   double planE = 0, planSL = 0, tp1 = 0, tp2 = 0, tp3 = 0;
   FillTradePlan(planE, planSL, tp1, tp2, tp3);
   const double risk = MathAbs(planE - planSL);
   const bool   slOk = risk > 0.0 && (isLong ? planSL < planE : planSL > planE);
   double rr1 = 0, rr2 = 0, rr3 = 0;
   if(slOk)
     {
      rr1 = MathAbs(tp1 - planE) / risk;
      rr2 = MathAbs(tp2 - planE) / risk;
      rr3 = MathAbs(tp3 - planE) / risk;

      string nRisk = prefix + "ZONE_RISK";
      ObjectCreate(chartId, nRisk, OBJ_RECTANGLE, 0, tB, MathMax(planE, planSL), tRight, MathMin(planE, planSL));
      ObjectSetInteger(chartId, nRisk, OBJPROP_COLOR, clrTomato);
      ObjectSetInteger(chartId, nRisk, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(chartId, nRisk, OBJPROP_FILL, true);
      ObjectSetInteger(chartId, nRisk, OBJPROP_BACK, true);
      ObjectSetInteger(chartId, nRisk, OBJPROP_SELECTABLE, false);

      DrawRay(chartId, prefix + "LV_ENTRY", tB, tRight, planE, zCol,
              StringFormat("%s  C=%.0f%%A", (isLong ? "LONG ENTRY" : "SHORT ENTRY"), m_pat.c_fib * 100.0), 2);
      DrawRay(chartId, prefix + "LV_SL", tB, tRight, planSL, clrTomato, "SL", 2);
      if(isLong ? tp1 > planE : tp1 < planE)
         DrawRay(chartId, prefix + "LV_TP1", tB, tRight, tp1, clrLimeGreen,
                 StringFormat("TP1  0.618C  RR %.2f", rr1), 2);
      if(isLong ? tp2 > planE : tp2 < planE)
         DrawRay(chartId, prefix + "LV_TP2", tB, tRight, tp2, clrDeepSkyBlue,
                 StringFormat("TP2  Wave B  RR %.2f", rr2), 2);
      if(isLong ? tp3 > planE : tp3 < planE)
         DrawRay(chartId, prefix + "LV_TP3", tB, tRight, tp3, clrGold,
                 StringFormat("TP3  Wave A  RR %.2f", rr3), 2);
     }

   if(m_sig.valid)
     {
      string ar = prefix + "ARROW";
      ObjectCreate(chartId, ar, OBJ_ARROW, 0, m_sig.bar_time, (m_sig.dir == EWA_BUY ? m_low[1] : m_high[1]));
      ObjectSetInteger(chartId, ar, OBJPROP_ARROWCODE, (m_sig.dir == EWA_BUY ? 233 : 234));
      ObjectSetInteger(chartId, ar, OBJPROP_COLOR, m_cfg.colorSignal);
      ObjectSetInteger(chartId, ar, OBJPROP_WIDTH, 3);
      ObjectSetInteger(chartId, ar, OBJPROP_ANCHOR, (m_sig.dir == EWA_BUY ? ANCHOR_TOP : ANCHOR_BOTTOM));
      ObjectSetInteger(chartId, ar, OBJPROP_SELECTABLE, false);
     }

   const string dash = prefix + "DASH";
   string txt = StringFormat(
                   "ELIOTWAVE ABC  |  %s\nWave A: %s   B retrace: %.1f%%   C: %.1f%% A\n%s",
                   (isLong ? "LONG (C turun, pantul naik)" : "SHORT (C naik, pantul turun)"),
                   DoubleToString(m_pat.waveA, m_digits),
                   m_pat.retraceB * 100.0,
                   m_pat.c_fib * 100.0,
                   m_pat.status);
   if(slOk)
      txt += StringFormat(
                "\nENTRY %s   SL %s\nTP1 0.618C %s  RR %.2f\nTP2 Wave B %s  RR %.2f\nTP3 Wave A %s  RR %.2f",
                DoubleToString(planE, m_digits),
                DoubleToString(planSL, m_digits),
                DoubleToString(tp1, m_digits), rr1,
                DoubleToString(tp2, m_digits), rr2,
                DoubleToString(tp3, m_digits), rr3);
   if(m_sig.valid)
      txt += "\n>>> " + m_sig.reason;
   ObjectCreate(chartId, dash, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, dash, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, dash, OBJPROP_XDISTANCE, 12);
   ObjectSetInteger(chartId, dash, OBJPROP_YDISTANCE, 18);
   ObjectSetInteger(chartId, dash, OBJPROP_COLOR, (isLong ? clrLime : clrOrangeRed));
   ObjectSetInteger(chartId, dash, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(chartId, dash, OBJPROP_SELECTABLE, false);
   ObjectSetString(chartId, dash, OBJPROP_FONT, "Consolas");
   ObjectSetString(chartId, dash, OBJPROP_TEXT, txt);
  }

#endif // ELIOTWAVEABC_MQH
