//=====================================================================
//	Micro trend indicator
//=====================================================================
#property copyright		"Dima S., 2010 ã."
#property link				"dimascub@mail.ru"
#property version			"1.04"
#property description	"Micro trend indicator"
#property description	"(according to James Hyerczyk)"

//=====================================================================
//	Include files
//=====================================================================
#include	<Arrays\List.mqh>
#include	<ChartObjects\ChartObjectsLines.mqh>
#include	<ChartObjects\ChartObjectsArrows.mqh>
#include <TextDisplay.mqh>
//---------------------------------------------------------------------
#property indicator_chart_window

//=====================================================================
//	Input parameters
//=====================================================================
input int         MaxBars=1000;
input bool        IsSaveTrendParams=true;
//---------------------------------------------------------------------
input bool        ShowInfo=true;
input int         UpDownInfoShift=1;
input int         LeftRightInfoShift=1;
input color       TitlesColor=LightCyan;
input color       TopFieldsColor = LightGreen;
input color       LowFieldsColor = LightPink;
//---------------------------------------------------------------------
input color       UpTrendColor = LightGreen;
input color       DnTrendColor = LightPink;
input int         LineWidth=3;
//---------------------------------------------------------------------
input color       UpStopLossColor = LightGreen;
input color       DnStopLossColor = LightPink;
input int         StopLossWidth=1;
//---------------------------------------------------------------------

//---------------------------------------------------------------------
bool      is_first_init=true;
bool      is_object_deleted=true;
//---------------------------------------------------------------------
#define	WIDTH			128
#define	HEIGHT		128
#define	FONTSIZE	10
//---------------------------------------------------------------------

//---------------------------------------------------------------------
string         prefix="GannMicroTrend";
CList*         trend_list_Ptr = NULL;    // list of trend lines
CList*         up_list_Ptr = NULL;       // list of peaks
CList*         dn_list_Ptr = NULL;       // list of bottoms
TableDisplay   *info_display_Ptr;        // position of the last peak/bottom
//---------------------------------------------------------------------
datetime       time_prev=0;
double         price_prev;
double         high_prev;
double         low_prev;
int            trend_dir=0;    // trend direction (1 - upward, -1 - downward, 0 - undefined)
//---------------------------------------------------------------------
string         InfoTitles_Array[]={ "Last Micro Top:","Last Micro Low:" };
//---------------------------------------------------------------------
//	Custom indicator initialization function
//---------------------------------------------------------------------
int OnInit()
  {
   trend_list_Ptr=new CList();
   if(CheckPointer(trend_list_Ptr)!=POINTER_DYNAMIC)
     {
      Print("Error in creating of CList object #1");
      return(-1);
     }

   up_list_Ptr=new CList();
   if(CheckPointer(up_list_Ptr)!=POINTER_DYNAMIC)
     {
      Print("Error in creating of CList object #2");
      return(-1);
     }

   dn_list_Ptr=new CList();
   if(CheckPointer(dn_list_Ptr)!=POINTER_DYNAMIC)
     {
      Print("Error in creating of CList object #3");
      return(-1);
     }

   if(InitGraphObjects()!=0)
     {
      Print("Error in creating of TableDisplay object");
      return(-1);
     }

   return(0);
  }
//---------------------------------------------------------------------
//	Custom indicator deinitialization function
//---------------------------------------------------------------------
void OnDeinit(const int _reason)
  {
   DeleteGraphObjects();
  }
//---------------------------------------------------------------------
// Custom indicator iteration function
//---------------------------------------------------------------------
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
  {
   int start;

   if(prev_calculated==0)
     {
      if(CheckPointer(trend_list_Ptr)!=POINTER_INVALID)
        {
         trend_list_Ptr.Clear();
        }
      if(CheckPointer(up_list_Ptr)!=POINTER_INVALID)
        {
         up_list_Ptr.Clear();
        }
      if(CheckPointer(dn_list_Ptr)!=POINTER_INVALID)
        {
         dn_list_Ptr.Clear();
        }

      //	determine starting bar index
      if(MaxBars>0 && rates_total>MaxBars)
        {
         start=rates_total-MaxBars;
        }
      else
        {
         start=1;
        }
      time_prev = 0;
      trend_dir = 0;
     }
   else
     {
      start=prev_calculated-1;
     }

//	Calculation
   for(int i=start; i<rates_total; i++)
     {
      //	save the first bar
      if(time_prev==0)
        {
         time_prev = time[ i ];
         high_prev = high[ i ];
         low_prev=low[i];
         continue;
        }

      //	upward movement
      if(high[i]>high_prev && low[i]>low_prev)
        {
         if(trend_dir!=0)
           {
            CreateCut(time_prev,price_prev,time[i],high[i],UpTrendColor,LineWidth);
           }

         //	if direction has changed, plot the bottom of the middle trend
         if(trend_dir==-1)
           {
            CreateDnStopLoss(time_prev,price_prev,DnStopLossColor,StopLossWidth);
            SaveDnStopLossParams(time_prev,price_prev);
           }
         trend_dir=1;
         SaveTrendParams(trend_dir,time[i]);

         time_prev = time[ i ];
         high_prev = high[ i ];
         low_prev=low[i];
         price_prev=high[i];
        }
      //	downward movement
      else if(low[i]<low_prev && (high[i]<high_prev))
        {
         if(trend_dir!=0)
           {
            CreateCut(time_prev,price_prev,time[i],low[i],DnTrendColor,LineWidth);
           }

         //	if direction has changed, plot the peak of the middle trend
         if(trend_dir==1)
           {
            CreateUpStopLoss(time_prev,price_prev,UpStopLossColor,StopLossWidth);
            SaveUpStopLossParams(time_prev,price_prev);
           }
         trend_dir=-1;
         SaveTrendParams(trend_dir,time[i]);

         time_prev = time[ i ];
         high_prev = high[ i ];
         low_prev=low[i];
         price_prev=low[i];
        }
      //	if the outside bar
      else if(high[i]>high_prev && low[i]<low_prev)
        {
         if(close[i]>=open[i]) // up bar
           {
            CreateCut(time_prev,price_prev,time[i],low[i],DnTrendColor,LineWidth);
            CreateCut(time[i],low[i],time[i],high[i],UpTrendColor,LineWidth);

            //	if direction has changed, plot the peak of the middle trend
            if(trend_dir==1)
              {
               CreateUpStopLoss(time_prev,price_prev,UpStopLossColor,StopLossWidth);
               SaveUpStopLossParams(time_prev,price_prev);
              }

            //	plot the bottom of the middle trend
            CreateDnStopLoss(time[i],low[i],DnStopLossColor,StopLossWidth);
            SaveDnStopLossParams(time[i],low[i]);

            trend_dir=1;
            SaveTrendParams(trend_dir,time[i]);

            price_prev=high[i];
           }
         else // down bar
           {
            CreateCut(time_prev,price_prev,time[i],high[i],UpTrendColor,LineWidth);
            CreateCut(time[i],high[i],time[i],low[i],DnTrendColor,LineWidth);

            //	if direction has changed, plot the bottom of the middle trend
            if(trend_dir==-1)
              {
               CreateDnStopLoss(time_prev,price_prev,DnStopLossColor,StopLossWidth);
               SaveDnStopLossParams(time_prev,price_prev);
              }

            //	plot the peak of the middle trend
            CreateUpStopLoss(time[i],high[i],UpStopLossColor,StopLossWidth);
            SaveUpStopLossParams(time[i],high[i]);

            trend_dir=-1;
            SaveTrendParams(trend_dir,time[i]);

            price_prev=low[i];
           }

         time_prev = time[ i ];
         high_prev = high[ i ];
         low_prev=low[i];
        }
     }

// if the calculations finished, plot parameters of the last peaks/bottoms:
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
      int index;

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

      //	titles
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
   if(CheckPointer(trend_list_Ptr)==POINTER_DYNAMIC)
     {
      delete(trend_list_Ptr);
     }

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

   is_object_deleted=true;
  }
//---------------------------------------------------------------------
//	Save trend parameters to grobal variables
//---------------------------------------------------------------------
void SaveTrendParams(int _dir,datetime _dt)
  {
   if(IsSaveTrendParams==true)
     {
      string name=prefix+"_"+Symbol()+"_"+IntegerToString(PeriodSeconds()/60)+"_Dir";
      GlobalVariableSet(name,_dir);
      GlobalVariableSet(name+"_DTime",_dt);
     }
  }
//---------------------------------------------------------------------
//	Save parameters of the minor peak (SL position) to the global varables:
//---------------------------------------------------------------------
void SaveUpStopLossParams(datetime _dt,double _price)
  {
   if(IsSaveTrendParams==true)
     {
      string name=prefix+"_"+Symbol()+"_"+IntegerToString(PeriodSeconds()/60)+"_UpSL";
      GlobalVariableSet(name+"_DTime",_dt);
      GlobalVariableSet(name+"_Price",_price);
     }
  }
//---------------------------------------------------------------------
//	Save parameters of the minor bottom (SL position) to the global variables:
//---------------------------------------------------------------------
void SaveDnStopLossParams(datetime _dt,double _price)
  {
   if(IsSaveTrendParams==true)
     {
      string name=prefix+"_"+Symbol()+"_"+IntegerToString(PeriodSeconds()/60)+"_DnSL";
      GlobalVariableSet(name+"_DTime",_dt);
      GlobalVariableSet(name+"_Price",_price);
     }
  }
//---------------------------------------------------------------------
//	Drawing of minor peak parameters (SL position):
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
//	Drawing of minor bottom parameters (SL position)::
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
//	Drawing of a section
//---------------------------------------------------------------------
void CreateCut(datetime _dt1,double _prc1,datetime _dt2,double _prc2,color _clr,int _wd)
  {
   string   name=GetUniqName(prefix+" ");
   CChartObjectTrend*   trend_obj = new CChartObjectTrend( );
   if( CheckPointer( trend_obj ) != POINTER_INVALID )
     {
      trend_obj.Create( 0, name, 0, _dt1, _prc1, _dt2, _prc2 );
      trend_obj.Color( _clr );
      trend_obj.Width( _wd );
      trend_list_Ptr.Add(trend_obj);
     }
  }
//---------------------------------------------------------------------
//	Generates unique name
//---------------------------------------------------------------------
string GetUniqName(string _prefix="")
  {
   static uint prev_count=0;

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
//	Checks new bar
//---------------------------------------------------------------------
//	returns 1 in the case of a new bar 
//---------------------------------------------------------------------
int CheakNewBar(ENUM_TIMEFRAMES _timeframe)
  {
   MqlRates current_rates[1];

   ResetLastError();
   if(CopyRates(Symbol(),_timeframe,0,1,current_rates)!=1)
     {
      Print("Error in CopyRates, error code = ",GetLastError());
      return(0);
     }

   if(current_rates[0].tick_volume>1)
     {
      return(0);
     }

   return(1);
  }
//---------------------------------------------------------------------
