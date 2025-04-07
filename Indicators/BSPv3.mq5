//+------------------------------------------------------------------+
//|                                                        BSPv3.mq5 |
//|                                                     Yong-su, Kim |
//|                                         https://www.mql5.comBull |
//+------------------------------------------------------------------+
#property copyright "Yong-su, Kim"
#property link      "https://www.mql5.comBull"
#property version   "1.00"


#property indicator_separate_window
//---- one buffer is used for calculation and drawing of the indicator
#property indicator_buffers 16
//---- one plot is used
#property indicator_plots   8
//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
//---- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_HISTOGRAM
#property indicator_type6   DRAW_HISTOGRAM
#property indicator_type7   DRAW_HISTOGRAM
#property indicator_type8   DRAW_LINE


//---- Red color is used as the color of the indicator line
#property indicator_color1  clrAqua
#property indicator_color2  clrDeepPink
#property indicator_color3  clrAqua
#property indicator_color4  clrDeepPink
#property indicator_color5  clrGreen
#property indicator_color6  clrRed
#property indicator_color7  clrYellow
#property indicator_color8  clrWhite

//---- the line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID
#property indicator_style5  STYLE_SOLID
#property indicator_style6  STYLE_SOLID
#property indicator_style7  STYLE_SOLID
#property indicator_style8  STYLE_SOLID


//---- indicator 1 line width is equal to 1
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
#property indicator_width8  1

//---- displaying the indicator label
//#property indicator_label1  "Ticks"

#include <SmoothAlgorithms.mqh> 
CXMA XMA1,XMA2,XMA3, XMA4, XMA5;
CXMA::Smooth_Method XMA_Method=MODE_EMA;     // Averaging method




input ENUM_APPLIED_VOLUME  VolumeType     = VOLUME_TICK;    // Volume
input int                 BSPPeriod      = 7200;            //BSP EMA Period
input int                 NEMAPeriod     = 1440;           //EMA Period After Normalization



int                        XPhase         = 15;           // Smoothing parameter



//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double BuyPressureBuffer[], SellPressureBuffer[], BSDiffBuffer[], 
       EMABuyPressureBuffer[], EMASellPressureBuffer[], EMABSDiffBuffer[],
       NBuyPressureBuffer[], NSellPressureBuffer[], NBSDiffBuffer[],
       BSPVolumeBuffer[], EMABSPVolumeBuffer[], NBSPVolumeBuffer[],
       NBFBuffer[], NSFBuffer[], EMANBFBuffer[], EMANSFBuffer[];
//---- declaration of the integer variables for the start of data calculation
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
   SetIndexBuffer(0,EMANBFBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,EMANSFBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,NBFBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,NSFBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,NBuyPressureBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,NSellPressureBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,NBSDiffBuffer,INDICATOR_DATA);
   SetIndexBuffer(7,NBSPVolumeBuffer,INDICATOR_DATA);
   SetIndexBuffer(8,BuyPressureBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,SellPressureBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,BSDiffBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,EMABuyPressureBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,EMASellPressureBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,EMABSDiffBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,EMABSPVolumeBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(15,BSPVolumeBuffer,INDICATOR_CALCULATIONS);
   
   ArrayInitialize(EMANBFBuffer,0.);
   ArrayInitialize(EMANSFBuffer,0.);
   ArrayInitialize(NBFBuffer,0.);
   ArrayInitialize(NSFBuffer,0.);
   ArrayInitialize(NBuyPressureBuffer,0.);
   ArrayInitialize(NSellPressureBuffer,0.);
   ArrayInitialize(NBSDiffBuffer,0.);
   ArrayInitialize(NBSPVolumeBuffer,0.);
   ArrayInitialize(BuyPressureBuffer,0.);
   ArrayInitialize(SellPressureBuffer,0.);
   ArrayInitialize(BSDiffBuffer,0.);
   ArrayInitialize(EMABuyPressureBuffer,0.);
   ArrayInitialize(EMASellPressureBuffer,0.);
   ArrayInitialize(EMABSDiffBuffer,0.);
   ArrayInitialize(EMABSPVolumeBuffer,0.);
   ArrayInitialize(BSPVolumeBuffer,0.);
 
     
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of price maximums for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation

   int first, second;


//---- calculation of the 'first' starting number for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      int smallBar=iBars(_Symbol, PERIOD_M1);
      datetime smallTime = iTime(_Symbol, PERIOD_M1, smallBar-1);
      int start = iBarShift(_Symbol, _Period, smallTime);
      first = start - 1;  
      second = first + BSPPeriod;     
     }
   else 
     {
      first=rates_total-prev_calculated; // starting number for calculation of new bars
      second = rates_total - prev_calculated;
     }
      



//---- The main loop of the indicator calculation
   for(int bar=first; bar>=0; bar--)
     {
      int smallNextBar, smallCurBar;
      datetime bigCurTime, bigNextTime;
      double BuyPressure=0., SellPressure=0., BSDiff=0.;
      long tempVolume = 0;

      bigCurTime = iTime(_Symbol, _Period, bar); 
      smallCurBar = iBarShift(_Symbol, PERIOD_M1, bigCurTime);


      if(bar == 0)
        {
          smallNextBar = -1;        
        }
      else if(bar > 0)
        {
          bigNextTime = iTime(_Symbol, _Period, bar-1);
          smallNextBar = iBarShift(_Symbol, PERIOD_M1, bigNextTime);        
        } 
  

      for(int i = smallCurBar; i > smallNextBar; i--)
        {
         
           long mVolume;
           if(VolumeType == VOLUME_TICK) mVolume = iTickVolume(Symbol(),PERIOD_M1,i);
           else mVolume = iVolume(Symbol(),PERIOD_M1,i);

           double TempSellPressure =  iHigh(Symbol(),PERIOD_M1,i) - iClose(Symbol(),PERIOD_M1,i);
           double TempBuyPressure = iClose(Symbol(),PERIOD_M1,i) - iLow(Symbol(),PERIOD_M1,i);

           BuyPressure += TempBuyPressure;
           SellPressure -= TempSellPressure;
           tempVolume += mVolume;

        } 
                
       BuyPressureBuffer[(rates_total-1-bar)]=BuyPressure;
       SellPressureBuffer[(rates_total-1-bar)]=SellPressure;
       BSDiffBuffer[(rates_total-1-bar)]=BuyPressure + SellPressure;
       BSPVolumeBuffer[(rates_total-1-bar)] = (double)tempVolume;
     }
     
   for(int i=second;i<rates_total && !IsStopped();i++)
     {

      EMABuyPressureBuffer[i]=XMA1.XMASeries(second,prev_calculated,rates_total,XMA_Method,XPhase,
                                    BSPPeriod,BuyPressureBuffer[i],i,false);
      EMASellPressureBuffer[i]=XMA2.XMASeries(second,prev_calculated,rates_total,XMA_Method,XPhase,
                                    BSPPeriod,SellPressureBuffer[i],i,false);
      EMABSPVolumeBuffer[i]=XMA3.XMASeries(second,prev_calculated,rates_total,XMA_Method,XPhase,
                                    BSPPeriod,BSPVolumeBuffer[i],i,false);


      if(EMABuyPressureBuffer[i]==0.) EMABuyPressureBuffer[i]=0.00000001;
      NBuyPressureBuffer[i] = BuyPressureBuffer[i]/EMABuyPressureBuffer[i];

      if(EMASellPressureBuffer[i]==0.) EMASellPressureBuffer[i]=-0.00000001;
      NSellPressureBuffer[i] = -(SellPressureBuffer[i]/EMASellPressureBuffer[i]);
      
      NBSDiffBuffer[i] = NBuyPressureBuffer[i] + NSellPressureBuffer[i];
      
      if(EMABSPVolumeBuffer[i]==0.) EMABSPVolumeBuffer[i]=0.0001;
      NBSPVolumeBuffer[i] = BSPVolumeBuffer[i]/EMABSPVolumeBuffer[i];  
      
      NBFBuffer[i] = NBuyPressureBuffer[i] * NBSPVolumeBuffer[i];
      
      EMANBFBuffer[i]=XMA4.XMASeries(second,prev_calculated,rates_total,XMA_Method,XPhase,
                                    NEMAPeriod,NBFBuffer[i],i,false);
     
            
      NSFBuffer[i] = NSellPressureBuffer[i] * NBSPVolumeBuffer[i];
      EMANSFBuffer[i]=XMA5.XMASeries(second,prev_calculated,rates_total,XMA_Method,XPhase,
                                    NEMAPeriod,NSFBuffer[i],i,false);
            
 
     }     
     
     
//----     
   return(rates_total);
  }
//+--------------------------