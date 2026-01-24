//=====================================================================
//	Middle trend indicator
//=====================================================================
#property copyright		"Dima S., 2010 г."
#property link				"dimascub@mail.ru"
#property version			"1.06"
#property description	"Middle trend indicator"
#property description	"(according to James Hyerczyk)"
//---------------------------------------------------------------------

//=====================================================================
//	Include files
//=====================================================================
#include	<ChartObjects\ChartObjectsArrows.mqh>
#include <TextDisplay.mqh>
//---------------------------------------------------------------------

//---------------------------------------------------------------------
#property indicator_chart_window
//---------------------------------------------------------------------
#property indicator_buffers	2
#property indicator_plots		1
#property indicator_type1		DRAW_COLOR_SECTION
#property indicator_color1		LightGreen, LightPink
#property indicator_width1		4
//---------------------------------------------------------------------

//=====================================================================
//	Input parameters
//=====================================================================
input int         MaxBars=1000;
input bool        IsSaveTrendParams=true;
//---------------------------------------------------------------------
input bool        ShowInfo=true;
input int         UpDownInfoShift=10;
input int         LeftRightInfoShift=1;
input color       TitlesColor=LightCyan;
input color       TopFieldsColor = LightGreen;
input color       LowFieldsColor = LightPink;
//---------------------------------------------------------------------
input color       UpStopLossColor = LightGreen;
input color       DnStopLossColor = LightPink;
input int         StopLossWidth=1;
//---------------------------------------------------------------------

//---------------------------------------------------------------------
#define	WIDTH     128
#define	HEIGHT    128
#define	FONTSIZE   10
//---------------------------------------------------------------------

//---------------------------------------------------------------------
string         prefix="GannMiddleTrend";
CList*         up_list_Ptr = NULL;        // list of peaks
CList*         dn_list_Ptr = NULL;        // list of bottoms
TableDisplay   *info_display_Ptr;         // position of the last peak/bottom
//---------------------------------------------------------------------
int            trend_dir=0;               // trend direction (1 - upward, -1 - downward, 0 - undefined)
int            active_bar;                // index of the active bar
int            last_top_bar = -1;         // index of the last peak
int            last_low_bar = -1;         // index of the last bottom
//---------------------------------------------------------------------
string         InfoTitles_Array[]={ "Last Middle Top:","Last Middle Low:" };

//---------------------------------------------------------------------
//	Indicator buffers
//---------------------------------------------------------------------
double         DataBuffer[];
double         ColorBuffer[];
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//	Custom indicator initialization function
//---------------------------------------------------------------------
int OnInit()
  {
   up_list_Ptr=new CList();
   if(CheckPointer(up_list_Ptr)!=POINTER_DYNAMIC)
     {
      Print("Error in creating of CList object #1");
      return(-1);
     }

   dn_list_Ptr=new CList();
   if(CheckPointer(dn_list_Ptr)!=POINTER_DYNAMIC)
     {
      Print("Error in creating of CList object #2");
      return(-1);
     }

   if(InitGraphObjects()!=0)
     {
      Print("Error in creating of TableDisplay");
      return(-1);
     }

   SetIndexBuffer(0,DataBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);

   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   IndicatorSetString(INDICATOR_SHORTNAME,"GannMiddleTrend");
   PlotIndexSetString(0,PLOT_LABEL,"GannMiddleTrend");
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

   ChartRedraw();
   return(0);
  }
//---------------------------------------------------------------------
//	Custom indicator deinitialization function
//---------------------------------------------------------------------
void OnDeinit(const int _reason)
  {
   DeleteGraphObjects();
   ChartRedraw();
  }
//---------------------------------------------------------------------
//	Custom indicator iteration function
//---------------------------------------------------------------------
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
  {
   int      start;

   if(prev_calculated==0)
     {
      ArrayInitialize(DataBuffer,0.0);

      if(CheckPointer(up_list_Ptr)!=POINTER_INVALID)
        {
         up_list_Ptr.Clear();
        }
      if(CheckPointer(dn_list_Ptr)!=POINTER_INVALID)
        {
         dn_list_Ptr.Clear();
        }

      //	starting bar
      if(MaxBars>0 && rates_total>MaxBars)
        {
         start=rates_total-MaxBars+2;
        }
      else
        {
         start=2;
        }
      trend_dir=0;    // trend direction( 1 - upward, -1 - downward, 0 - undefined )
     }
   else
     {
      start=prev_calculated-1;
     }

//	Calculations
   for(int i=start; i<rates_total; i++)
     {
      // If trend direction haven't been determined, wait for the upward or downward movement
      if(trend_dir==0)
        {
         if(high[i]>high[i-1] && high[i-1]>high[i-2]/*&& low[ i ] > low[ index - 1 ] && low[ index - 1 ] > low[ index - 2 ]*/)
           {
            trend_dir=1;
            active_bar=i;
           }
         else if(/*high[ i ] < high[ i - 1 ] && high[ i - 1 ] < high[ i - 2 ] &&*/ low[i]<low[i-1] && low[i-1]<low[i-2])
           {
            trend_dir=-1;
            active_bar=i;
            last_top_bar = -1;
            last_low_bar = -1;
           }
         continue;
        }

      //---------------------------------------------------------------------
      //	upward movement
      if(trend_dir==1)
        {
         //	upward movement continue
         if(high[i]>high[active_bar])
           {
            ColorBuffer[ active_bar ]= 0;
            DataBuffer[ active_bar ] = high[ active_bar ];

            ColorBuffer[ i ]= 0;
            DataBuffer[ i ] = high[ i ];

            active_bar=i;

            continue;
           }

         //	upward movement changed to downward
         if(low[i-1]<low[active_bar] && low[i]<low[i-1])
           {
            ColorBuffer[ active_bar ]= 0;
            DataBuffer[ active_bar ] = high[ active_bar ];

            ColorBuffer[ i ]= 1;
            DataBuffer[ i ] = low[ i ];

            CreateUpStopLoss(time[active_bar],high[active_bar],UpStopLossColor,StopLossWidth);
            SaveUpStopLossParams(time[active_bar],high[active_bar]);

            trend_dir=-1;
            SaveTrendParams(trend_dir,time[i]);

            last_top_bar = active_bar;
            last_low_bar = -1;
            active_bar=i;

            continue;
           }

         //	if the minimum of the bar lower than bottom, upward movement has finished
         if(last_low_bar!=-1 && low[i]<low[last_low_bar])
           {
            ColorBuffer[ active_bar ]= 0;
            DataBuffer[ active_bar ] = high[ active_bar ];

            ColorBuffer[ i ]= 1;
            DataBuffer[ i ] = low[ i ];

            CreateUpStopLoss(time[active_bar],high[active_bar],UpStopLossColor,StopLossWidth);
            SaveUpStopLossParams(time[active_bar],high[active_bar]);

            trend_dir=-1;
            SaveTrendParams(trend_dir,time[i]);

            last_top_bar = active_bar;
            last_low_bar = -1;
            active_bar=i;

            continue;
           }
        }

      //---------------------------------------------------------------------
      //	Downward movement
      if(trend_dir==-1)
        {
         //	downward movement continue
         if(low[i]<low[active_bar])
           {
            ColorBuffer[ active_bar ]= 1;
            DataBuffer[ active_bar ] = low[ active_bar ];

            ColorBuffer[ i ]= 1;
            DataBuffer[ i ] = low[ i ];

            active_bar=i;

            continue;
           }

         //	downward movement changed to upward
         if(high[i-1]>high[active_bar] && high[i]>high[i-1])
           {
            ColorBuffer[ active_bar ]= 1;
            DataBuffer[ active_bar ] = low[ active_bar ];

            ColorBuffer[ i ]= 1;
            DataBuffer[ i ] = high[ i ];

            CreateDnStopLoss(time[active_bar],low[active_bar],DnStopLossColor,StopLossWidth);
            SaveDnStopLossParams(time[active_bar],low[active_bar]);

            trend_dir=1;
            SaveTrendParams(trend_dir,time[i]);

            last_low_bar = active_bar;
            last_top_bar = -1;
            active_bar=i;

            continue;
           }

         //	if the high of the bar is higher than last peak, downward movement has finished
         if(last_top_bar!=-1 && high[i]>high[last_top_bar])
           {
            ColorBuffer[ active_bar ]= 1;
            DataBuffer[ active_bar ] = low[ active_bar ];

            ColorBuffer[ i ]= 1;
            DataBuffer[ i ] = high[ i ];

            CreateDnStopLoss(time[active_bar],low[active_bar],DnStopLossColor,StopLossWidth);
            SaveDnStopLossParams(time[active_bar],low[active_bar]);

            trend_dir=1;
            SaveTrendParams(trend_dir,time[i]);

            last_low_bar = active_bar;
            last_top_bar = -1;
            active_bar=i;

            continue;
           }
        }
     }

//	Calculation complete, show parameters of the last bottom and peak
   if(ShowInfo==true)
     {
      if(up_list_Ptr.Total()>0)
        {
         CChartObjectArrowRightPrice   *up_obj=(CChartObjectArrowRightPrice*)(up_list_Ptr.GetLastNode());
         if(( PeriodSeconds()/60)>=1440)
           {
            info_display_Ptr.SetText(0,DoubleToString(up_obj.Price(0),Digits())+"  ( "+TimeToString(up_obj.Time(0),TIME_DATE)+" )");
           }
         else
           {
            info_display_Ptr.SetText(0,DoubleToString(up_obj.Price(0),Digits())+"  ( "+TimeToString(up_obj.Time(0))+" )");
           }
        }
      if(dn_list_Ptr.Total()>0)
        {
         CChartObjectArrowLeftPrice   *dn_obj=(CChartObjectArrowLeftPrice*)(dn_list_Ptr.GetLastNode());
         if(( PeriodSeconds()/60)>=1440)
           {
            info_display_Ptr.SetText(1,DoubleToString(dn_obj.Price(0),Digits())+"  ( "+TimeToString(dn_obj.Time(0),TIME_DATE)+" )");
           }
         else
           {
            info_display_Ptr.SetText(1,DoubleToString(dn_obj.Price(0),Digits())+"  ( "+TimeToString(dn_obj.Time(0))+" )");
           }
        }
     }

   return(rates_total);
  }
//---------------------------------------------------------------------
//	Initialization of graphic objects
//---------------------------------------------------------------------
int InitGraphObjects()
  {
   if(ShowInfo==true)
     {
      int      index;

      info_display_Ptr=new TableDisplay();
      if(CheckPointer(info_display_Ptr)!=POINTER_DYNAMIC)
        {
         return(-1);
        }
      info_display_Ptr.SetParams(0,0,CORNER_LEFT_UPPER);

      index=info_display_Ptr.AddFieldObject(WIDTH,HEIGHT,LeftRightInfoShift+10,UpDownInfoShift+0*2+8,TopFieldsColor,"Arial",FONTSIZE);
      info_display_Ptr.SetAnchor(index,ANCHOR_LEFT);
      index=info_display_Ptr.AddFieldObject(WIDTH,HEIGHT,LeftRightInfoShift+10,UpDownInfoShift+1*2+8,LowFieldsColor,"Arial",FONTSIZE);
      info_display_Ptr.SetAnchor(index,ANCHOR_LEFT);

      //	Заголовки:
      for(int k=0; k<2; k++)
        {
         index=info_display_Ptr.AddTitleObject(WIDTH,HEIGHT,LeftRightInfoShift+9,UpDownInfoShift+k*2+8,InfoTitles_Array[k],TitlesColor,"Arial",FONTSIZE);
         info_display_Ptr.SetAnchor(index,ANCHOR_RIGHT);
        }
     }

   return(0);
  }
//---------------------------------------------------------------------
//	Delete graphic objects
//---------------------------------------------------------------------
void DeleteGraphObjects()
  {
   if(CheckPointer(up_list_Ptr)==POINTER_DYNAMIC)
     {
      delete(up_list_Ptr);
     }

   if(CheckPointer(dn_list_Ptr)==POINTER_DYNAMIC)
     {
      delete(dn_list_Ptr);
     }

   if(CheckPointer(info_display_Ptr)==POINTER_DYNAMIC)
     {
      delete(info_display_Ptr);
     }
  }
//---------------------------------------------------------------------
//	Save trend parameters to the global variables
//---------------------------------------------------------------------
void SaveTrendParams(int _dir,datetime _dt)
  {
   if(IsSaveTrendParams==true)
     {
      string   name=prefix+"_"+Symbol()+"_"+IntegerToString(PeriodSeconds()/60)+"_Dir";
      GlobalVariableSet(name,_dir);
      GlobalVariableSet(name+"_DTime",_dt);
     }
  }
//---------------------------------------------------------------------
//	Save parameters of the minor peak to the global variables
//---------------------------------------------------------------------
void SaveUpStopLossParams(datetime _dt,double _price)
  {
   if(IsSaveTrendParams==true)
     {
      string   name=prefix+"_"+Symbol()+"_"+IntegerToString(PeriodSeconds()/60)+"_UpSL";
      GlobalVariableSet(name+"_DTime",_dt);
      GlobalVariableSet(name+"_Price",_price);
     }
  }
//---------------------------------------------------------------------
//	Save parameters of the minor bottom to the global variables
//---------------------------------------------------------------------
void SaveDnStopLossParams(datetime _dt,double _price)
  {
   if(IsSaveTrendParams==true)
     {
      string   name=prefix+"_"+Symbol()+"_"+IntegerToString(PeriodSeconds()/60)+"_DnSL";
      GlobalVariableSet(name+"_DTime",_dt);
      GlobalVariableSet(name+"_Price",_price);
     }
  }
//---------------------------------------------------------------------
//	Drawing of minor peak parameters (SL position)
//---------------------------------------------------------------------
void CreateUpStopLoss(datetime _dt,double _price,color _clr,int _wd)
  {
   if(ShowInfo==true)
     {
      string   name=GetUniqName(prefix+" ");
      CChartObjectArrowRightPrice   *up_obj=new CChartObjectArrowRightPrice();
      if(CheckPointer(up_obj)!=POINTER_INVALID)
        {
         up_obj.Create( 0, name, 0, _dt, _price );
         up_obj.Color( _clr );
         up_obj.Width( _wd );
         up_list_Ptr.Add(up_obj);
        }
     }
  }
//---------------------------------------------------------------------
//	Drawing of minor bottom parameters (SL position)
//---------------------------------------------------------------------
void CreateDnStopLoss(datetime _dt,double _price,color _clr,int _wd)
  {
   if(ShowInfo==true)
     {
      string   name=GetUniqName(prefix+" ");
      CChartObjectArrowLeftPrice   *dn_obj=new CChartObjectArrowLeftPrice();
      if(CheckPointer(dn_obj)!=POINTER_INVALID)
        {
         dn_obj.Create( 0, name, 0, _dt, _price );
         dn_obj.Color( _clr );
         dn_obj.Width( _wd );
         dn_list_Ptr.Add(dn_obj);
        }
     }
  }
//---------------------------------------------------------------------
//	Generates unique name
//---------------------------------------------------------------------
string GetUniqName(string _prefix="")
  {
   static uint   prev_count=0;

   uint count=GetTickCount();
   while(1)
     {
      if(prev_count==UINT_MAX)
        {
         prev_count=0;
        }
      if(count<=prev_count)
        {
         prev_count++;
         count=prev_count;
        }
      else
        {
         prev_count=count;
        }

      //	checks existance of the object
      string      name=_prefix+TimeToString(TimeGMT(),TIME_DATE|TIME_MINUTES|TIME_SECONDS)+" "+DoubleToString(count,0);
      if(ObjectFind(0,name)<0)
        {
         return(name);
        }
     }

   return(NULL);
  }
//---------------------------------------------------------------------
