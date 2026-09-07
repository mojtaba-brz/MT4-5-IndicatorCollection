# Normalized close difference

`MT5-Indicators/NormalizedCloseDifference.mq5` plots a separate-window,
sign-and-slope-colored histogram with a dotted zero line.

The plotted value is:

```text
chart_normalized  = 100 * (chart_close / chart_anchor_close - 1)
second_normalized = 100 * (second_close / second_anchor_close - 1)
raw_difference   = chart_normalized - second_normalized
histogram        = correlation_sign * raw_difference
```

Units are **percentage points**, not price points or pips. If the chart symbol
has risen 1% and the second symbol 2%, the histogram is -1. A positive value means
the chart symbol has outperformed the second symbol since the anchor.

The raw output is explicitly **sym1 minus sym2**: chart-symbol normalized close
minus second-symbol normalized close. For an inverse companion (a negative H1
reference correlation), the indicator multiplies that raw difference by `-1`.
Thus a positive histogram consistently means the chart symbol is stronger than
its correlation-adjusted companion. The numeric formula is otherwise unchanged
by the color presentation:

| Output condition | Slope versus preceding plotted bar | Color |
|---|---|---|
| `>= 0` | Flat or rising | Matte blue |
| `> 0` | Falling | Dark matte blue |
| `< 0` | Flat or falling | Matte red |
| `< 0` | Rising toward zero | Dark matte red |

The first value after a blank, reset, or gap has no prior slope, so it uses its
ordinary sign color. A repeated confirmed higher-timeframe value is flat.

## Inputs

| Input | Meaning |
|---|---|
| Second asset | Enum: automatic strongest available H1 reference (default), or one of EURUSD, USDJPY, GBPUSD, USDCHF, USDCAD, AUDUSD, NZDUSD, WTI, GOLD, SILVER or DXY. The existing `standard_symbol_to_broker_symbol` resolver supplies the broker's exact Market Watch name. |
| Timeframe | Current chart timeframe or any higher timeframe. A lower timeframe fails initialization with an explanation in the Experts log. |
| Reset point | End of day; every session start; Asia start only; London start only; New York start only. |
| History days | Number of broker-calendar days to draw, including the latest chart day; default `14`. Must be at least 1. |

End of day means the next broker midnight, 00:00. Session starts use the
existing research's **broker-clock** convention: Asia 03:00, London 10:00 and
New York 15:00. These are fixed broker times, not exchange-local schedules;
they do not separately adjust to US or UK DST. The broker chart already uses
broker time, so there is no workstation timezone conversion.

The indicator places muted, color-coded dotted vertical lines at normalization
boundaries inside the displayed history window. Asia, London, New York and
broker-day boundaries use distinct subdued colors. These chart objects have
reset-time tooltips, do not affect buffer values, and are removed on detach.

The H1 reference table is embedded in the indicator from the frozen 2024
AssetSessionCorrelation Pearson completed-log-return reports. It retains Asia,
London and New York values for every supported pair. A selected-session reset
uses that session's value; end-of-day or every-session resets use the pair's
largest absolute session value. `Auto` chooses the available non-chart asset
with the largest absolute applicable value. The short name displays the compact
exact reference, for example `NCD r=-0.945: EURUSD-DXY`; that is the platform-visible
place for a chart-dependent value because MQL5 input-enum labels cannot change
after the chart symbol is known.

The current chart and selected companion must be distinct supported assets, and
the companion must already be visible in Market Watch for the shared resolver
to find its exact broker name. Otherwise initialization fails rather than
guessing a suffix or using an unverified symbol.

The first matched completed candle after a reset anchors both symbols at zero.
The anchor therefore occurs when that candle closes, not at the exact reset
instant. Subsequent values use its two fixed closes. Selecting just London
resets once per day at London start and continues through the other sessions.
Selecting every session resets at all three starts. A candle closing exactly
at a reset boundary still finishes the preceding period; the next candle starts
the new period. Missing bars, closures or invalid quotes discard the anchors;
the next matched completed candle starts a fresh zero baseline.

## Closed-candle and higher-timeframe behavior

The currently forming chart bar is blank. For every closed chart bar, use only
source candles whose close time was reached by that chart bar's close time.
A higher-timeframe candle's final close is never painted back onto earlier
lower-timeframe bars. Between higher-timeframe closes, the last confirmed value
is repeated until a reset or until another source close is due. It is left
blank after a reset until the new baseline is available.

With coarse timeframes and frequent resets, there may be few nonzero values:
at least two matched source closes within the same reset period are necessary.
For example, H6 with resets at every session may repeatedly establish only a
zero anchor. Use a longer reset period or a shorter supported timeframe when
you want more observations between resets.

Cross-symbol matching uses identical candle-open timestamps. The buffer is
blank before the selected history window. The indicator still reads the small
pre-window reset context needed to preserve the first displayed period's true
anchor, but it never draws that context. `14` means the latest chart day plus
the preceding 13 broker-calendar days, rather than 14 trading days.

Missing history is requested asynchronously with `CopyRates`; unavailable pairs
remain blank. A two-second indicator timer repeats the bounded request so a
weekend, an inactive chart, or a freshly selected second symbol does not require
the next market tick before it can plot. The short name reports `loading
history`, `waiting for history`, `waiting; retained`, `no matching closed
candles`, or the current number of plotted bars. Each retry calculates into
temporary buffers. It replaces the visible buffers only when the candidate has
a valid latest closed value; otherwise the previous valid snapshot remains
visible. This prevents asynchronous history responses from blinking the entire
histogram. The diagnostic status does not manufacture a missing pair. Cached
matching candles can be plotted while a longer series is still synchronizing.
Loading older chart bars while scrolling does not trigger another cross-symbol
request when the bounded indicator timeline is unchanged. If scrolling extends
the requested 14-day timeline, the indicator retains its prior snapshot until
both symbol series synchronize, then publishes the completed replacement once.
The adapter owns that snapshot with its timestamps and restores it explicitly
when MT5 clears or reallocates indicator buffers, including recalculations where
the platform resets `prev_calculated` to zero.

It never substitutes zero prices or interpolates the other symbol. OHLC is
validated, but the requested formula is explicitly close-only and does not
measure intrabar body, wick, range or volatility. History reloads or broker
corrections can cause recalculation; normal live changes to forming candles
cannot change previously completed values. Only the requested history window is
replayed on a new chart bar, with reset-period context loaded before its oldest
visible point. Initially truncated broker history can affect the oldest anchor.

The retry timer is enabled only on ordinary charts. In the Strategy Tester,
`CopyBuffer` access already drives indicator calculation, so the nested timer is
disabled because it is redundant.

## Use and validation

Compile `MT5-Indicators/NormalizedCloseDifference.mq5` in MetaEditor, then attach
it to a supported chart asset. Keep the shared project layout: the indicator
includes `Libs/MQLTradingLib/ExchangeTools.mqh` for broker-symbol resolution as
well as its own `Libs/NormalizedCloseDifference.mqh` core. Select `Auto` or a
companion asset and the reset mode. For TrendTrader deployment, use
`Tools/TrendTraderTools.bat build` in the parent project: it compiles the source and
publishes its verified EX5 to the terminal root
`MQL5/Indicators/NormalizedCloseDifference.ex5`. The EA must load that root
copy, not the compiler's `Indicators/Shared Projects/...` intermediate output.

The shared core declares the stable `ENUM_NCD_SECOND_ASSET` input contract, and
`CNormalizedCloseDifference` has `SetParams`, `Init`, `Step` and `Reset`;
each instance owns its baselines. The chart adapter owns its own refresh state.
`Tests/NormalizedCloseDifferenceTests.mq5` checks normalization/sign, inverse
correlation sign adjustment, atomic snapshot publication, timestamp restoration
after buffer reallocation, zero
anchors, histogram color selection, session boundaries, day and gap resets, invalid/mismatched/forming
candles, explicit reset, calendar-month ends, bounded display, causal
higher-timeframe projection, missed-pair blanks, and recovery after a delayed
history response. It is a script: run it in MT5
and check for `NormalizedCloseDifferenceTests: 0 failures` in Experts.

Validation on 2026-09-07: both indicator and test script compile with **0 errors,
0 warnings**. The test script has not yet been executed in MT5 during this
change. The user visually confirmed that version 1.33 no longer blinks while
scrolling a USDCHF chart with EURUSD selected. Local EX5 files and compiler logs
are ignored. Version 1.34 adds visual reset boundaries without changing buffer
0; TrendTrader 2.200 consumes the same completed values.
