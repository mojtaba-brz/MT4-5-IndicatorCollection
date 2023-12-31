//+------------------------------------------------------------------+
//|                               Copyright © 2017, Gehtsoft USA LLC |
//|                                            http://fxcodebase.com |
//+------------------------------------------------------------------+
//|                         Donate / Support:  https://goo.gl/9Rj74e |
//|                     BitCoin: 15VCJTLaz12Amr7adHSBtL9v8XomURo9RF  | 
//+------------------------------------------------------------------+
//|                                      Developed by : Mario Jemic  |                    
//|                                          mario.jemic@gmail.com   |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2017, Gehtsoft USA LLC"
#property link      "http://fxcodebase.com"

#property indicator_buffers 3

#property indicator_separate_window
#property indicator_width1 3
#property indicator_color1 clrGreen
#property indicator_width3 3
#property indicator_color3 clrRed
#property indicator_width2 3
#property indicator_color2 clrBlue

#property indicator_levelcolor clrYellow
#property indicator_levelwidth 1
#property indicator_levelstyle STYLE_SOLID


extern int MA_Period=14;

double Vol[];
double Up[];
double Dn[];
double VolumeBuffer[];
double MA[];
int init(){
   
   IndicatorShortName("Normalized Volume");
   IndicatorBuffers(5);   
   

   
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(1,Up);
   
   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexBuffer(2,Dn);
   
   SetIndexBuffer(0,Vol);
   SetIndexStyle(0,DRAW_LINE);
   
    SetIndexBuffer(3,VolumeBuffer);
	SetIndexBuffer(4,MA);
   
   SetLevelValue(0,0);
   return(0);
}

int start()
  {
   
   int i;
   int counted_bars=IndicatorCounted();
   int limit = Bars-counted_bars-1;
   
 

   
   for(i=limit; i>=0; i--){
   VolumeBuffer[i]=Volume[i];       
   }
    
   
   
  for(i=limit; i>=0; i--){
  
       MA[i]= iMAOnArray(VolumeBuffer,0,MA_Period,0,0,i);
  
	   if ( MA[i] != 0 ) 
	   {
				 Vol[i]=Volume[i]/MA[i]*100 - 100;   
				 
				  if (Vol[i] > 0)
				  {
					 Up[i] = Vol[i];
					 Dn[i] = EMPTY_VALUE;
				  }	 
				  else
				  {
					 Dn[i] =Vol[i];
					 Up[i]  = EMPTY_VALUE;
				   }	
       }	
       else
	   {
	     Up[i]  = EMPTY_VALUE;
		 Dn[i] = EMPTY_VALUE;
	   }
	   
 	   
   
   }
   
//----
   return(0);
}
  
