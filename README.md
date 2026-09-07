# MT4-5-IndicatorCollection

## Normalized close difference

[`NormalizedCloseDifference`](docs/NormalizedCloseDifference.md) compares a
second symbol's normalized completed close with the chart symbol, using a
separate-window matte dark-blue histogram. It supports current/higher
timeframes, broker day/session resets, and a bounded broker-calendar history
window (14 days by default). Its first input is an asset enum with automatic
H1-reference selection, rather than a broker-specific symbol string.

`LaguerreRsiFilterAdapter.mq5` is the stable no-space `iCustom` path for the
existing Laguerre RSI with Laguerre filter implementation. It preserves the
original inputs and buffers.

Welcome to the MT4-5-IndicatorCollection! This is a collection of indicators that I use in my MQL projects, and I'm happy to share them with you for free. Your contributions and ideas are also highly appreciated!

Here are a few important rules to keep in mind:

1. Most Important Parameter:
    - Make sure this parameter is an integer.
    - It should be the first input parameter.
    - This rule helps simplify the optimization process in the NoForexNonesense-MQL-EA.

2. *Libs* Folder:
- The *Libs* folder is where you can find third-party libraries used in the indicators.

3. MT4 Indicators:
- Please place the MT4 indicators in the *MT4-Indicators* folder.

4. MT5 Indicators:
- Please put the MT5 indicators in the *MT5-Indicators* folder.

By following these guidelines, we can maintain consistency and organization within the indicator collection. Thank you for your cooperation, and enjoy using the MT4-5-IndicatorCollection!
