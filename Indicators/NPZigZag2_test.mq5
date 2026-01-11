//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property copyright "Author"
#property link      "https://www.mql5.com/en/users/lorio"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 1

input double retracement=23.6;//retracement amount
input double minSizeInAtrUnits=5.0;//min size of waves in atr units
input int rollingAtrPeriod=14;//rolling atr period
input color Color=clrDodgerBlue;//wave color
input int Width=3;//wave width
input ENUM_LINE_STYLE Style=STYLE_SOLID;//wave style

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
//--- up waves and the downwaves
double upWaves[],dwWaves[];

//--- keeping track of the zigzag
//--- the type of wave we have [0] none [1] up [2] down
int wave_type=0;
//--- the price from of the wave (starting price)
double wave_start_price=0.0;
//--- the price to of the wave (ending price)
double wave_end_price=0.0;
//--- the distance in bars from the start price
int wave_start_distance=0;
//--- the distance in bars from the end price
int wave_end_distance=0;
//--- high price tracking
double high_mem=0.0;
int distance_from_high=0;
//--- low price tracking
double low_mem=0.0;
int distance_from_low=0;
//--- rolling atr
double rollingAtr=0.0;
int rollingAtrs=0;

int OnInit()
  {
//--- 기존 화살표 오브젝트들 정리
   ObjectsDeleteAll(0, "MyArrow");
   
//--- indicator buffers mapping
   SetIndexBuffer(0,upWaves,INDICATOR_DATA);
   SetIndexBuffer(1,dwWaves,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_ZIGZAG);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,Color);
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,Width);
   PlotIndexSetInteger(0,PLOT_LINE_STYLE,Style);
   resetSystem();
   
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- 기존 화살표 오브젝트들 정리
   ObjectsDeleteAll(0);
  }

//+------------------------------------------------------------------+
//| reset buffers                                                    |
//+------------------------------------------------------------------+
void resetSystem()
  {
   ArrayFill(upWaves,0,ArraySize(upWaves),0.0);
   ArrayFill(dwWaves,0,ArraySize(dwWaves),0.0);
   wave_type=0;
   wave_start_price=0.0;
   wave_end_price=0.0;
   wave_start_distance=0;
   wave_end_distance=0;
   high_mem=0.0;
   low_mem=0.0;
   distance_from_high=0;
   distance_from_low=0;
   rollingAtr=0.0;
   rollingAtrs=0;
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
//---
   int barCount=rates_total-1;
   int from;
   if(prev_calculated==0)
     {
      from=1;
      resetSystem();
      //--- set the first bar high and low as high and low
      rollingAtr=(high[0]-low[0])/_Point;
      rollingAtrs=1;
     }
     else{
      from = prev_calculated - 1;
     }

//--- loop up to the last formed bar !
   for(int i=from;i<rates_total-1;i++)
     {
      if(i==1)
        {
         Comment("Atr Unit "+DoubleToString(rollingAtr,1)+" pts\nMin wave size "+DoubleToString(rollingAtr*minSizeInAtrUnits,1)+" pts");
        }
      //--- propagation : we carry over the previous
      distance_from_high++;
      distance_from_low++;
      //--- manage the atr
      rollingAtrs++;

      if(rollingAtrs>rollingAtrPeriod)
        {
         double new_portion=((high[i]-low[i])/_Point)/((double)rollingAtrPeriod);
         //--- we remove an old portion and add a new portion
         rollingAtr=(rollingAtr)-(rollingAtr/((double)rollingAtrPeriod))+new_portion;
        }
      else
         if(rollingAtrs<=rollingAtrPeriod)
           {
            rollingAtr+=(high[i]-low[i])/_Point;
            if(rollingAtrs==rollingAtrPeriod)
              {
               rollingAtr/=((double)rollingAtrs);
               //--- start the memory for highs and lows and the system
               high_mem=high[i];
               low_mem=low[i];
               distance_from_high=0;
               distance_from_low=0;
              }
           }

      //--- if we have collected the atr required
      if(rollingAtrs>rollingAtrPeriod)
        {
         //--- carry distances in bars if they are active
         if(wave_type!=0)
           {
            //--- we add a bar to the distances since a new bar formed
            wave_start_distance++;
            wave_end_distance++;
           }
         //--- if we have a wave type
         if(wave_type!=0)
           {
            //--- if we have an up wave
            if(wave_type==1)
              {
               //--- if the wave expands up
               if(high[i]>wave_end_price)
                 {
                  //--- remove the previous end price from its array position (0.0=empty)
                  upWaves[i-wave_end_distance]=0.0;
                  //--- place it on the new position
                  upWaves[i]=high[i];
                  wave_end_price=high[i];
                  wave_end_distance=0;
                  //--- change the high
                  high_mem=high[i];
                  distance_from_high=0;
                  //--- change the low
                  low_mem=low[i];
                  distance_from_low=0;
                 }
               //--- check for retracement
               if(low[i]<low_mem||distance_from_low==0)
                 {
                  low_mem=low[i];
                  distance_from_low=0;
                  double size_of_wave=(wave_end_price-wave_start_price)/_Point;
                  double size_of_retracement=(wave_end_price-low_mem)/_Point;
                  if(size_of_wave>0.0)
                    {
                     double retraced=(size_of_retracement/size_of_wave)*100.0;
                     double new_wave_size_in_atr_units=((wave_end_price-low_mem)/_Point)/rollingAtr;
                     //--- if the new wave size is valid
                     if(new_wave_size_in_atr_units>=minSizeInAtrUnits)
                       {
                        //--- if the retracement is significant , start a down wave
                        if(retraced>=retracement)
                          {
                           //--- start a new down wave
                           wave_type=-1;
                           //--- start price is the high mem
                           wave_start_price=high[i-distance_from_high];
                           wave_start_distance=distance_from_high;
                           //--- end price is the new low
                           wave_end_price=low[i];
                           wave_end_distance=0;
                           //--- draw the wave
                           upWaves[i-wave_start_distance]=high_mem;
                           dwWaves[i]=low[i];
                           //--- change the high
                           high_mem=high[i];
                           distance_from_high=0;
                           //--- change the low
                           low_mem=low[i];
                           distance_from_low=0;
                           MakeArrow((barCount-i), low_mem, wave_type, 1);
                          }
                       }
                    }
                 }
              }
            //--- if we have a down wave
            else
               if(wave_type==-1)
                 {
                  //--- if the wave expands down
                  if(low[i]<wave_end_price)
                    {
                     //--- remove the previous end price from its array position (0.0=empty)
                     dwWaves[i-wave_end_distance]=0.0;
                     //--- place it on the new position
                     dwWaves[i]=low[i];
                     wave_end_price=low[i];
                     wave_end_distance=0;
                     //--- change the high
                     high_mem=high[i];
                     distance_from_high=0;
                     //--- change the low
                     low_mem=low[i];
                     distance_from_low=0;
                    }
                  //--- check for retracement
                  if(high[i]>high_mem||distance_from_high==0)
                    {
                     high_mem=high[i];
                     distance_from_high=0;
                     double size_of_wave=(wave_start_price-wave_end_price)/_Point;
                     double size_of_retracement=(high_mem-wave_end_price)/_Point;
                     if(size_of_wave>0.0)
                       {
                        double retraced=(size_of_retracement/size_of_wave)*100.0;
                        double new_wave_size_in_atr_units=((high_mem-wave_end_price)/_Point)/rollingAtr;
                        //--- if the new wave size is valid
                        if(new_wave_size_in_atr_units>=minSizeInAtrUnits)
                          {
                           //--- if the retracement is significant , start a down wave
                           if(retraced>=retracement)
                             {
                              //--- start a new up wave
                              wave_type=1;
                              //--- start price is the low mem
                              wave_start_price=low_mem;
                              wave_start_distance=distance_from_low;
                              //--- end price is the new high
                              wave_end_price=high[i];
                              wave_end_distance=0;
                              //--- draw the wave
                              dwWaves[i-wave_start_distance]=low_mem;
                              upWaves[i]=high[i];
                              //--- change the high
                              high_mem=high[i];
                              distance_from_high=0;
                              //--- change the low
                              low_mem=low[i];
                              distance_from_low=0;
                              MakeArrow((barCount-i), high_mem, wave_type, 1);
                             }
                          }
                       }
                    }
                 }
           }
         //--- if we don't have a wave type yet
         else
           {
            //--- if we broke the high and not the low
            if(high[i]>high_mem && low[i]>=low_mem)
              {
               double new_wave_size_in_atr_units=((high[i]-low_mem)/_Point)/rollingAtr;
               //--- if the new wave size is valid
               if(new_wave_size_in_atr_units>=minSizeInAtrUnits)
                 {
                  //--- start a new up wave
                  wave_type=1;
                  //--- start price is the low mem
                  wave_start_price=low_mem;
                  wave_start_distance=distance_from_low;
                  //--- end price is the new high
                  wave_end_price=high[i];
                  wave_end_distance=0;
                  //--- draw the wave
                  dwWaves[i-wave_start_distance]=low_mem;
                  upWaves[i]=high[i];
                  //--- change the high
                  high_mem=high[i];
                  distance_from_high=0;
                  //--- change the low
                  low_mem=low[i];
                  distance_from_low=0;
                  MakeArrow((barCount-i), high_mem, wave_type, 1);
                 }
              }
            //--- if we broke the low and not the high
            else
               if(low[i]<low_mem && high[i]<=high_mem)
                 {
                  double new_wave_size_in_atr_units=((high_mem-low[i])/_Point)/rollingAtr;
                  //--- if the new wave size is valid
                  if(new_wave_size_in_atr_units>=minSizeInAtrUnits)
                    {
                     //--- start a new down wave
                     wave_type=-1;
                     //--- start price is the high mem
                     wave_start_price=high_mem;
                     wave_start_distance=distance_from_high;
                     //--- end price is the new low
                     wave_end_price=low[i];
                     wave_end_distance=0;
                     //--- draw the wave
                     upWaves[i-wave_start_distance]=high_mem;
                     dwWaves[i]=low[i];
                     //--- change the high
                     high_mem=high[i];
                     distance_from_high=0;
                     //--- change the low
                     low_mem=low[i];
                     distance_from_low=0;
                     MakeArrow((barCount-i), low_mem, wave_type, 1);
                    }
                 }
               //--- if we broke both
               else
                  if(low[i]<low_mem && high[i]>high_mem)
                    {
                     //--- change them
                     high_mem=high[i];
                     low_mem=low[i];
                     distance_from_high=0;
                     distance_from_low=0;
                    }
           }
        }
        
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
  
  // 예제: 현재 캔들 고가에 초록색 화살표 표시
void MakeArrow(int retroBar, double price, int m_WaveType, int m_WaveStep)
{
    static int WaveNumber1=0;
    static int WaveNumber2=0;
    
    string objName;
    datetime time = iTime(_Symbol, _Period, retroBar);   // 1번째(완성된) 캔들 시간으로 변경
//    datetime time = TimeCurrent();
    color clr;                                   // 화살표 색상
    ENUM_OBJECT arrowDirection;                         // 화살표 방향
    ENUM_ARROW_ANCHOR anchorPoint;

    if (m_WaveStep==1) 
       {
        clr = clrRed;
        WaveNumber1++;
        objName = "MyArrow1-"+IntegerToString(WaveNumber1);
       } 
    else 
       {
        clr = clrYellow;
        WaveNumber2++;
        objName = "MyArrow2-"+IntegerToString(WaveNumber2);
       } 
    
    if(m_WaveType==-1) 
      {
       arrowDirection = OBJ_ARROW_DOWN;
       anchorPoint = ANCHOR_BOTTOM;
      } 
    else 
      {
       arrowDirection = OBJ_ARROW_UP;
       anchorPoint = ANCHOR_TOP;
      } 
        
    // 오브젝트 생성
    if(ObjectCreate(0, objName, arrowDirection, 0, time, price))
    {
        ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);           // 색상
        ObjectSetInteger(0, objName, OBJPROP_WIDTH, 3);             // 크기(두께)
        ObjectSetInteger(0, objName, OBJPROP_ANCHOR, anchorPoint);  // 앵커 포인트
        ObjectSetInteger(0, objName, OBJPROP_BACK, false);          // 배경에 그리지 않음
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, true);     // 선택 가능
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);        // 숨기지 않음
        ObjectSetInteger(0, objName, OBJPROP_ZORDER, 0);            // Z-order 설정
                
        // 차트 리프레시
        ChartRedraw(0);
    }

}



 