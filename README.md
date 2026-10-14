# ELIOTWAVE

Strategi **Elliott Wave ABC** untuk **MetaTrader 5** dan **TradingView (Pine Script)**.

Indikator otomatis menandai gelombang A–B–C, memproyeksikan **zona Fibonacci Wave C**, lalu EA / strategy masuk pasar hanya ketika **harga memantul di area C**.

```
        A                         SELL C
       / \                       pantulan
      /   \ B                   ↓
     /     \  /\            ───── zona C ─────
    /       \/  \ C
   /             \
  /               ── BUY C pantulan
```

---

## Isi repositori

| File | Peran |
| --- | --- |
| `MQL5/Include/EliotWaveABC.mqh` | Mesin deteksi swing, pola ABC, zona C, pantulan |
| `MQL5/Indicators/EliotWaveABC.mq5` | Indikator MT5: gelombang, Fibonacci C, panah pantulan |
| `MQL5/Experts/EliotWaveABC_EA.mq5` | Expert Advisor MT5: entri otomatis di pantulan C |
| `TradingView/EliotWaveABC_Indicator.pine` | Indikator TradingView + alert pantulan C |
| `TradingView/EliotWaveABC_Strategy.pine` | Strategy TradingView (backtest & alert) |

---

## Cara kerja strategi

Pola yang diperdagangkan adalah **zigzag korektif ABC** (bukan impulse 1–2–3–4–5).

### BUY — Wave A turun, B naik, C turun

1. **Wave A**: ayunan turun (swing high → swing low).
2. **Wave B**: retrace naik **38.2% – 88.6%** dari A, dan tidak menembus awal A.
3. **Wave C**: turun lagi dari puncak B. Proyeksi Fibonacci dari panjang A:
   - **0.886 – 1.000 – 1.272 – 1.618** × Wave A
4. **Zona C** = area antara Fibonacci min dan max (default **0.886 – 1.618**).
5. **Entri BUY** hanya jika harga **menyentuh zona C** lalu **memantul naik** (rejection / pin bar / engulfing), dengan RSI tidak panas.

Stop loss di bawah ekstrem C. Take profit default ke **awal Wave A**, atau fallback risk:reward 1:2 jika target struktural terlalu dekat.

### SELL — kebalikan

Wave A naik, B turun, C naik ke zona Fibonacci, pantulan turun → **SELL**.

### Invalidasi pola

- BUY: harga pecah di atas B, atau C menembus **2.618** × A.
- SELL: harga pecah di bawah B, atau C menembus **2.618** × A.
- Satu pola ABC = maksimal satu posisi (`InpOnePerPattern`).

Wave A dan B memakai swing yang **sudah terkonfirmasi** (kedalaman `InpDepth` bar), sehingga zona C tidak bergeser setiap tick.

---

## Instalasi di MetaTrader 5

1. Buka MT5 → **File → Open Data Folder**.
2. Masuk ke folder `MQL5`.
3. Salin file:
   - `Include/EliotWaveABC.mqh` → `MQL5/Include/`
   - `Indicators/EliotWaveABC.mq5` → `MQL5/Indicators/`
   - `Experts/EliotWaveABC_EA.mq5` → `MQL5/Experts/`
4. Buka **MetaEditor** (F4), compile ketiga file (pastikan `.mqh` sudah di `Include` sebelum compile EA/indikator).
5. Di Navigator MT5:
   - Pasang indikator **EliotWave ABC** ke chart untuk melihat gelombang dan zona C.
   - Pasang EA **EliotWaveABC_EA**, centang **Allow Algo Trading**, nyalakan tombol **Algo Trading**.

EA sudah menggambar gelombang sendiri. Indikator opsional jika Anda hanya ingin melihat pola tanpa auto-trade.

---

## Instalasi di TradingView

Dua skrip Pine v5, aturan ABC-nya sama dengan EA MT5.

### Indikator (lihat gelombang + alert)

1. Buka [TradingView](https://www.tradingview.com) → chart → **Pine Editor**.
2. Buka file `TradingView/EliotWaveABC_Indicator.pine`, salin seluruh isi.
3. Tempel di Pine Editor → **Save** → **Add to chart**.
4. Alert: klik **Alert** pada indikator, pilih *Pantulan C BUY* atau *Pantulan C SELL*, kondisi **Once Per Bar Close**.

### Strategy (backtest + entri otomatis di simulator)

1. Pine Editor → tempel `TradingView/EliotWaveABC_Strategy.pine`.
2. **Add to chart**, buka tab **Strategy Tester**.
3. Optional: buat alert dari strategy untuk webhook / notifikasi.

Jangan pasang indikator dan strategy sekaligus di chart yang sama (gambar wave dobel). Pilih salah satu.

Timeframe yang masuk akal: **15m, 1h, 4h**.

---

## Parameter penting

### Deteksi wave

| Input | Default | Arti |
| --- | --- | --- |
| Kedalaman swing | 12 | Semakin besar = swing lebih besar, sinyal lebih jarang |
| Min Wave A (x ATR) | 0.80 | Saring pola kecil / noise |
| Retrace B | 0.382 – 0.886 | Syarat zigzag yang valid |
| Zona C Fibonacci | 0.886 – 1.618 | Area pantulan entri |
| Invalid C | 2.618 | C terlalu panjang, pola dibatalkan |

### Pantulan C

| Input | Default | Arti |
| --- | --- | --- |
| Mode pantulan | ANY | Rejection sumbu, pin bar, atau engulfing |
| Filter RSI | ON | BUY jika RSI ≤ 40, SELL jika RSI ≥ 60 |
| Entri bar tertutup | ON | Sinyal di candle yang sudah close (lebih stabil) |

### Risiko

| Input | Default | Arti |
| --- | --- | --- |
| Lot dari % risiko | ON | 1% balance per trade, lot dihitung dari jarak SL |
| Mode TP | AUTO | Target awal Wave A, fallback RR 1:2 |
| Spread max | 40 poin | Blokir entri jika spread melebar |
| Trailing / breakeven | ON | BE di 1R, trail setelah 1.2R |

Timeframe yang masuk akal untuk mulai: **M15, H1, H4**. Pair likuid: EURUSD, GBPUSD, XAUUSD (naikkan `MaxSpread` untuk emas).

---

## Alur entri (ringkas)

```
Swing terkonfirmasi  →  validasi ABC  →  C mencapai zona Fib
        →  candle pantulan di zona C  →  filter RSI / spread / jam
        →  BUY atau SELL  +  SL di luar ekstrem C  +  TP struktural
```

Tidak ada entri di Wave A atau B. **Hanya area C, dan hanya setelah pantulan.**

---

## Backtest

**MetaTrader 5** — Strategy Tester:

- Model: **Every tick based on real ticks** jika tersedia, atau **1 minute OHLC**.
- Period: minimal 1 tahun.
- Optimasi yang paling berpengaruh: `InpDepth`, `InpCFibMin`, `InpCFibMax`, `InpBounceMode`, timeframe.

**TradingView** — Strategy Tester pada `EliotWaveABC_Strategy.pine`, commission sesuai broker Anda.

Hasil backtest bukan jaminan hasil live. Elliott Wave bersifat diskresioner; versi ini adalah aturan kuantitatif dari zigzag ABC.

---

## Disclaimer

Perangkat ini untuk edukasi dan otomasi aturan ABC. Trading forex/CFD berisiko tinggi. Uji di akun demo, pahami parameter, dan jangan risikokan dana yang tidak siap hilang.
