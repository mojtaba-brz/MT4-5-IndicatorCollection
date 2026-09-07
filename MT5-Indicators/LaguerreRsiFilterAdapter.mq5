// Stable no-space filename for programmatic iCustom and Strategy Tester use.
// The implementation and public input/buffer contract remain owned by the
// original indicator source.
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots 3
#property indicator_label1 "No trade zone"
#property indicator_type1 DRAW_FILLING
#property indicator_color1 C'255,238,210',C'255,238,210'
#property indicator_label2 "Laguerre RSI"
#property indicator_type2 DRAW_COLOR_LINE
#property indicator_color2 clrDarkGray,clrDodgerBlue,clrPaleVioletRed
#property indicator_width2 2
#property indicator_label3 "Laguerre filter signal"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrDimGray
#property indicator_style3 STYLE_DASHDOTDOT

#include "Laguerre RSI with Laguerre filter extended.mq5"
