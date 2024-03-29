//

#property copyright   ""
#property link        ""
#property description ""

#property indicator_separate_window
#property indicator_buffers 2
//------
#property indicator_color1  clrOrangeRed  //clrRed  //clrMagenta 
#property indicator_color2  clrDodgerBlue  //clrLightCyan  //clrWhite  //clrLime
//------
#property indicator_width1  2
#property indicator_width2  2
//------
#property indicator_style1  STYLE_DOT
#property indicator_style2  STYLE_DOT
//------

extern int ZZPeriod = 54;
extern int BarN = 1000;
//string gs_84 = "2012.02.27";
//int gi_92 = 30;
double Signal[];
double BUY[];
bool gi_104;
bool gi_108;
//bool gi_112 = TRUE;

int init() {
//   gi_112 = TRUE;
   SetIndexStyle(0, DRAW_HISTOGRAM);  //, EMPTY, 3, OrangeRed);
   SetIndexBuffer(0, Signal);
   SetIndexStyle(1, DRAW_HISTOGRAM);  //, EMPTY, 3, DodgerBlue);
   SetIndexBuffer(1, BUY);
   return (0);
}

int deinit() {
   return (0);
}

int start() {
   double low_44;
   double high_52;
   double lda_92[10000][3];
   //string ls_unused_96;
//   if (!gi_112) return (0);
/*
   if (gs_84 != "") 
   {
      if (TimeCurrent() > StrToTime(gs_84) + 86400 * gi_92) 
      {
         Alert("Your version is expired!");
         Comment("Your version is expired!");
         gi_112 = FALSE;
         return (0);
      }
   }
*/
   int ind_counted_8 = IndicatorCounted();
   int li_20 = 0;
   int li_16 = 0;
   int index_24 = 0;
   double high_60 = High[BarN];
   double low_68 = Low[BarN];
   int li_32 = BarN;
   int li_36 = BarN;
   for (int li_12 = BarN; li_12 >= 0; li_12--) {
      low_44 = 10000000;
      high_52 = -100000000;
      for (int li_28 = li_12 + ZZPeriod; li_28 >= li_12 + 1; li_28--) {
         if (Low[li_28] < low_44) low_44 = Low[li_28];
         if (High[li_28] > high_52) high_52 = High[li_28];
      }
      if (Low[li_12] < low_44 && High[li_12] > high_52) {
         li_16 = 2;
         if (li_20 == 1) li_32 = li_12 + 1;
         if (li_20 == -1) li_36 = li_12 + 1;
      } else {
         if (Low[li_12] < low_44) li_16 = -1;
         if (High[li_12] > high_52) li_16 = 1;
      }
      if (li_16 != li_20 && li_20 != 0) {
         if (li_16 == 2) {
            li_16 = -li_20;
            high_60 = High[li_12];
            low_68 = Low[li_12];
            gi_104 = FALSE;
            gi_108 = FALSE;
         }
         index_24++;
         if (li_16 == 1) {
            lda_92[index_24][1] = li_36;
            lda_92[index_24][2] = low_68;
            gi_104 = FALSE;
            gi_108 = TRUE;
         }
         if (li_16 == -1) {
            lda_92[index_24][1] = li_32;
            lda_92[index_24][2] = high_60;
            gi_104 = TRUE;
            gi_108 = FALSE;
         }
         high_60 = High[li_12];
         low_68 = Low[li_12];
      }
      if (li_16 == 1) {
         if (High[li_12] >= high_60) {
            high_60 = High[li_12];
            li_32 = li_12;
         }
      }
      if (li_16 == -1) {
         if (Low[li_12] <= low_68) {
            low_68 = Low[li_12];
            li_36 = li_12;
         }
      }
      li_20 = li_16;
      if (gi_108 == TRUE) {
         BUY[li_12] = 0;
         Signal[li_12] = 1;
      }
      if (gi_104 == TRUE) {
         BUY[li_12] = 0;
         Signal[li_12] = -1;
      }
   }
   return (0);
}