//+------------------------------------------------------------------+
//|                                              GannTrendSignal.mqh |
//|                                                 Dima S., 2010 ã. |
//|                                                 dimascub@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Dima S., 2010 ã."
#property link      "dimascub@mail.ru"
//---------------------------------------------------------------------
#include	<Expert\ExpertSignal.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signal based on swings on charts                           |
//| of the middle and main trends according to Gann (iCustom)        |
//| Type=Signal                                                      |
//| Name=TGannBreakSignal                                            |
//| Class=TGannBreakSignal                                           |
//| Page=                                                            |
//| Parameter=MinMainSwingContinuance,int,5                          |
//| Parameter=MinMainSwingSize,double,300.0                          |
//| Parameter=MinMiddleSwingContinuance,int,3                        |
//| Parameter=MaxMiddleSwingSize,double,200.0                        |
//| Parameter=OpenPriceSpace,double,5.0                              |
//| Parameter=StopLossSpace,double,5.0                               |
//+------------------------------------------------------------------+
// wizard description end
//=====================================================================
//	Generation of BUY/SELL signals when breakdown of the horizontal trend
//=====================================================================
class TGannBreakSignal : public CExpertSignal
  {
private:
   int               min_main_swing_continuance;      // minimum swing duration time of the main tren
   double            min_main_swing_size_points;      // minimum swing amplitude on the chart of the main trend
   int               min_middle_swing_continuance;    // minimum swing duration time on the chart of the middle trend
   double            max_middle_swing_size_points;    // maximum swing amplitude of the chart of the middle trend
   double            open_price_space;                // distance between the open price and peak/bottom
   double            stop_loss_space;                 // distance between the stop loss price and peak/bottom

   datetime          main_swing_lf_datetime;          // time of left point of a swing on the chart of the main trend
   double            main_swing_lf_price;             // price of left point of a swing on the chart of the main trend
   datetime          main_swing_rt_datetime;          // time of right point of a swing on the chart of the main trend
   double            main_swing_rt_price;             // price of right point of a swing on the chart of the main trend
   int               main_swing_continuance;          // swing duration time on the chart of the main trend
   double            main_swing_size_points;          // swing amplitude (in points) on the chart of the main trend

   datetime          middle_swing_lf_datetime;        // time of left point of a swing on the chart of the middle trend
   double            middle_swing_lf_price;           // price of left point of a swing on the chart of the middle trend
   datetime          middle_swing_rt_datetime;        // time of right point of a swing on the chart of the middle trend
   double            middle_swing_rt_price;           // price of right point of a swing on the chart of the middle trend
   int               middle_swing_continuance;        // swing duration time on the chart of the middle trend
   double            middle_swing_size_points;        // swing amplitude (in points) on the chart of the middle trend

   int               handle_main_swing;
   int               handle_middle_swing;
   double            main_swing_buff[];
   double            middle_swing_buff[];
   datetime          time_buff[];
   double            price_buff[];
public:
                     TGannBreakSignal();   // constuctor
                    ~TGannBreakSignal();   // destructor
   //	Settings:
   void              MinMainSwingContinuance(int _cont);
   void              MinMainSwingSize(double _size);
   void              MinMiddleSwingContinuance(int _cont);
   void              MaxMiddleSwingSize(double _size);
   void              OpenPriceSpace(double _space);
   void              StopLossSpace(double _space);

   int               GetMainSwingContinuance();      // gets swing duration time on the chart of the main trend
   double            GetMainSwingSizePoints();       // gets swing amplitude (in 4-digit points) on the chart of the main trend
   int               GetMiddleSwingContinuance();    // gets swing duration time on the chart of the middle trend
   double            GetMiddleSwingSizePoints();     // gets swing amplitude (in 4-digit points) on the chart of the middle trend
   
   // overloaded methods of the CExpertSignal class:
   virtual bool      ValidationSettings();
   virtual bool      CheckOpenLong(double &price,double &sl,double &tp,datetime &expiration);
   virtual bool      CheckOpenShort(double &price,double &sl,double &tp,datetime &expiration);
   virtual bool      InitIndicators(CIndicators *indicators);

   //	Additional methods:
protected:
   //	Sets swing parameters of the main trend
   void              SetMainSwingParameters(datetime _lf_dt,double _lf_price,datetime _rt_dt,double _rt_price);
   //	Sets swing parameters of the middle trend
   void              SetMiddleSwingParameters(datetime _lf_dt,double _lf_price,datetime _rt_dt,double _rt_price);
   // Gets swing parameters of the main trend
   int               GetMainSwing();                  
   // Gets swing parameters of the middle trend
   int               GetMiddleSwing( );                
  };
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//	Class constructor
//---------------------------------------------------------------------
TGannBreakSignal::TGannBreakSignal()
  {
   this.min_main_swing_continuance = 0;
   this.min_main_swing_size_points = 0.0;
   this.min_middle_swing_continuance = 0;
   this.max_middle_swing_size_points = 0.0;
   this.open_price_space= 0.0;
   this.stop_loss_space = 0.0;
  }
//---------------------------------------------------------------------
//	Class destructor
//---------------------------------------------------------------------
TGannBreakSignal::~TGannBreakSignal()
  {
   if(this.handle_main_swing!=INVALID_HANDLE)
     {
      IndicatorRelease(this.handle_main_swing);
     }
   if(this.handle_middle_swing!=INVALID_HANDLE)
     {
      IndicatorRelease(this.handle_middle_swing);
     }
  }
//---------------------------------------------------------------------
//	Main settings
//---------------------------------------------------------------------
void TGannBreakSignal::MinMainSwingContinuance(int _cont)
  {
   this.min_main_swing_continuance=_cont;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TGannBreakSignal::MinMainSwingSize(double _size)
  {
   this.min_main_swing_size_points=_size;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TGannBreakSignal::MinMiddleSwingContinuance(int _cont)
  {
   this.min_middle_swing_continuance=_cont;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TGannBreakSignal::MaxMiddleSwingSize(double _size)
  {
   this.max_middle_swing_size_points=_size;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TGannBreakSignal::OpenPriceSpace(double _space)
  {
   this.open_price_space=_space;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TGannBreakSignal::StopLossSpace(double _space)
  {
   this.stop_loss_space=_space;
  }
//---------------------------------------------------------------------
//	Validation of settings
//---------------------------------------------------------------------
bool TGannBreakSignal::ValidationSettings()
  {
   if(this.min_main_swing_continuance<=0)
     {
      Print("Wrong Parameter: min_main_swing_continuance = ",this.min_main_swing_continuance);
      return(false);
     }
   if(this.min_main_swing_size_points<=0.0)
     {
      Print("Wrong Parameter: min_main_swing_size_points = ",DoubleToString(this.min_main_swing_size_points,1));
      return(false);
     }
   if(this.min_middle_swing_continuance<=0)
     {
      Print("Wrong Parameter: min_middle_swing_continuance = ",this.min_middle_swing_continuance);
      return(false);
     }
   if(this.max_middle_swing_size_points<=0.0)
     {
      Print("Wrong Parameter: max_middle_swing_size_points = ",DoubleToString(this.max_middle_swing_size_points,1));
      return(false);
     }

   return(true);
  }
//---------------------------------------------------------------------
//	Checks conditions to open long position
//---------------------------------------------------------------------
bool TGannBreakSignal::CheckOpenLong(double &_price,double &_sl,double &_tp,datetime &_expiration)
  {
   if(this.GetMainSwing()==-1)
     {
      return(false);
     }

   if(this.GetMiddleSwing()==-1)
     {
      return(false);
     }

//	If the main swing upward, exit
   if(this.main_swing_rt_price>=this.main_swing_lf_price)
     {
      return(false);
     }

//	If the middle weak swing isn't formed, exit:
   if(this.middle_swing_rt_price>=this.middle_swing_lf_price)
     {
      return(false);
     }

//	Check swing parameters on the main trend chart
   if(this.main_swing_continuance<this.min_main_swing_continuance || this.main_swing_size_points<this.min_main_swing_size_points)
     {
      return(false);
     }

//	Check swing parameters on the middle trend chart
   if(this.middle_swing_continuance<this.min_middle_swing_continuance || this.middle_swing_size_points>this.max_middle_swing_size_points)
     {
      return(false);
     }

   double unit=this.PriceLevelUnit();

//	If the price has crossed the peak of the weak middle swing, set signal to open long position:
   double   delta=this.m_symbol.Bid() -(this.middle_swing_lf_price+this.open_price_space*unit);
   if(( delta>=0.0) && (delta<(10.0*unit)))
     {
      _price=0.0;
      _sl = this.m_symbol.NormalizePrice( this.middle_swing_rt_price - stop_loss_space * unit );
      _tp = 0.0;

      return(true);
     }

   return(false);
  }
//---------------------------------------------------------------------
//	Checks conditions to open short position
//---------------------------------------------------------------------
bool TGannBreakSignal::CheckOpenShort(double &_price,double &_sl,double &_tp,datetime &_expiration)
  {
   if(this.GetMainSwing()==-1)
     {
      return(false);
     }

   if(this.GetMiddleSwing()==-1)
     {
      return(false);
     }

//	If the main swing downward, exit
   if(this.main_swing_rt_price<=this.main_swing_lf_price)
     {
      return(false);
     }

//	If the middle weak swing isn't formed, exit:
   if(this.middle_swing_rt_price<=this.middle_swing_lf_price)
     {
      return(false);
     }

//	Check swing parameters on the main trend chart
   if(this.main_swing_continuance<this.min_main_swing_continuance || this.main_swing_size_points<this.min_main_swing_size_points)
     {
      return(false);
     }

//	Check swing parameters on the middle trend chart
   if(this.middle_swing_continuance<this.min_middle_swing_continuance || this.middle_swing_size_points>this.max_middle_swing_size_points)
     {
      return(false);
     }

   double unit=this.PriceLevelUnit();

//	If the price has crossed the bottom of the weak middle swing, set signal to open short position:
   double delta=(this.middle_swing_lf_price-this.open_price_space*unit)-this.m_symbol.Bid();
   if(( delta>=0.0) && (delta<(10.0*unit)))
     {
      _price=0.0;
      _sl = this.m_symbol.NormalizePrice( this.middle_swing_rt_price + stop_loss_space * unit );
      _tp = 0.0;

      return(true);
     }

   return(false);
  }
//---------------------------------------------------------------------
//	Initialization of indicators
//---------------------------------------------------------------------
bool TGannBreakSignal::InitIndicators(CIndicators *_ind)
  {
   this.handle_main_swing=iCustom(this.m_symbol.Name(),this.m_period,"GannMainTrend",1000,false,false,1,1,LightCyan,LightGreen,LightPink,LightGreen,LightPink,3);
   if(this.handle_main_swing==INVALID_HANDLE)
     {
      return(false);
     }

   this.handle_middle_swing=iCustom(this.m_symbol.Name(),this.m_period,"GannMiddleTrend",1000,false,false,1,1,LightCyan,LightGreen,LightPink,LightGreen,LightPink,3);
   if(this.handle_middle_swing==INVALID_HANDLE)
     {
      return(false);
     }

   return(true);
  }

//---------------------------------------------------------------------
//	Gets the swing parameters of the main trend 
//---------------------------------------------------------------------
#define	SIZE_MAIN		200
//---------------------------------------------------------------------
int TGannBreakSignal::GetMainSwing()
  {
   bool  is_high_found=false,is_low_found=false;
   int   bars_high=0,bars_low=0;

//	get the values from the color buffer:
   if(CopyBuffer(this.handle_main_swing,1,0,SIZE_MAIN,this.main_swing_buff)!=SIZE_MAIN)
     {
      return(-1);
     }

//	get the values from the price buffer:
   if(CopyBuffer(this.handle_main_swing,0,0,SIZE_MAIN,this.price_buff)!=SIZE_MAIN)
     {
      return(-1);
     }

//	Search for the first non-empty point on the chart:
   int    index;
   bool   is_find=false;
   for(index=SIZE_MAIN-1; index>=0; index--)
     {
      if(this.price_buff[index]>0.1)
        {
         is_find=true;
         break;
        }
     }
   if(is_find==false)
     {
      return(-1);
     }

//	Search for the last peak and bottom:
   int  color_prev=(int)(this.main_swing_buff[index]);
   for(int i=index-1; i>=0; i--)
     {
      if(is_high_found==false && this.price_buff[i]>0.1 && this.main_swing_buff[i]==0.0 && color_prev==1) // peak found
        {
         is_high_found=true;
         bars_high=i;

         //	if the peak and bottom found, break
         if(is_low_found==true)
           {
            break;
           }

         color_prev=(int)(this.main_swing_buff[i]);
        }
      else if(is_low_found==false && this.price_buff[i]>0.1 && this.main_swing_buff[i]==1.0 && color_prev==0) // bottom found
        {
         is_low_found=true;
         bars_low=i;
        }

      //	if the peak and bottom found, break
      if(is_high_found==true)
        {
         break;
        }

      if(this.price_buff[i]>0.1)
        {
         color_prev=(int)(this.main_swing_buff[i]);
        }
     }

//	if the peak and bottom found, proceed
   if(is_high_found==true && is_low_found==true)
     {
      //	get time
      if(CopyTime(this.m_symbol.Name(),this.m_period,0,SIZE_MAIN,this.time_buff)!=SIZE_MAIN)
        {
         return(-1);
        }
      //	Save peak/bottom points
      if(bars_low>bars_high)
        {
         this.main_swing_lf_datetime=this.time_buff[bars_high];  // time of left point of a swing on the chart of the main trend
         this.main_swing_lf_price=this.price_buff[bars_high];    // price of left point of a swing on the chart of the main trend
         this.main_swing_rt_datetime=this.time_buff[bars_low];   // time of right point of a swing on the chart of the main trend
         this.main_swing_rt_price=this.price_buff[bars_low];     // price of right point of a swing on the chart of the main trend
        }
      else if(bars_high>bars_low)
        {
         this.main_swing_lf_datetime=this.time_buff[bars_low];   // time of left point of a swing on the chart of the main trend
         this.main_swing_lf_price=this.price_buff[bars_low];     // price of left point of a swing on the chart of the main trend
         this.main_swing_rt_datetime=this.time_buff[bars_high];  // time of right point of a swing on the chart of the main trend
         this.main_swing_rt_price=this.price_buff[bars_high];    // price of right point of a swing on the chart of the main trend
        }
      else
        {
         return(-1);
        }

      //	set swing parameters
      this.SetMainSwingParameters(this.main_swing_lf_datetime,this.main_swing_lf_price,this.main_swing_rt_datetime,this.main_swing_rt_price);

      return(0);
     }
   else
     {
      return(-1);
     }
  }

//---------------------------------------------------------------------
//	Get swing parameters of the middle trend
//---------------------------------------------------------------------
#define	SIZE_MIDDLE		200
//---------------------------------------------------------------------
int TGannBreakSignal::GetMiddleSwing()
  {
   bool is_high_found=false,is_low_found=false;
   int  bars_high=0,bars_low=0;

// Get the values from the color buffer:
   if(CopyBuffer(this.handle_middle_swing,1,0,SIZE_MIDDLE,this.middle_swing_buff)!=SIZE_MIDDLE)
     {
      return(-1);
     }

//	Get the values from the price buffer:
   if(CopyBuffer(this.handle_middle_swing,0,0,SIZE_MIDDLE,this.price_buff)!=SIZE_MIDDLE)
     {
      return(-1);
     }

//	Search for the first non-empty point on the chart:
   int    index;
   bool   is_find=false;
   for(index=SIZE_MIDDLE-1; index>=0; index--)
     {
      if(this.price_buff[index]>0.1)
        {
         is_find=true;
         break;
        }
     }
   if(is_find==false)
     {
      return(-1);
     }

//	Search for the last peak and bottom
   int      color_prev=(int)(this.middle_swing_buff[index]);
   for(int i=index-1; i>=0; i--)
     {
      if(is_high_found==false && this.price_buff[i]>0.1 && this.middle_swing_buff[i]==0.0 && color_prev==1) // peak found
        {
         is_high_found=true;
         bars_high=i;

         //	if peak and bottom found, break
         if(is_low_found==true)
           {
            break;
           }

         color_prev=(int)(this.middle_swing_buff[i]);
        }
      else if(is_low_found==false && this.price_buff[i]>0.1 && this.middle_swing_buff[i]==1.0 && color_prev==0) // bottom found
        {
         is_low_found=true;
         bars_low=i;
        }

      //	if the peak and bottom found, break
      if(is_high_found==true)
        {
         break;
        }

      if(this.price_buff[i]>0.1)
        {
         color_prev=(int)(this.middle_swing_buff[i]);
        }
     }

//	If the peak and bottom found, get their parameters
   if(is_high_found==true && is_low_found==true)
     {
      //	Get the time
      if(CopyTime(this.m_symbol.Name(),this.m_period,0,SIZE_MIDDLE,this.time_buff)!=SIZE_MIDDLE)
        {
         return(-1);
        }

      //	Save peak/bottom points
      if(bars_low>bars_high)
        {
         this.middle_swing_lf_datetime=this.time_buff[bars_high];  // time of left point of a swing on the chart of the middle trend
         this.middle_swing_lf_price=this.price_buff[bars_high];    // price of left point of a swing on the chart of the middle trend
         this.middle_swing_rt_datetime=this.time_buff[bars_low];   // time of right point of a swing on the chart of the middle trend
         this.middle_swing_rt_price=this.price_buff[bars_low];     // price of right point of a swing on the chart of the middle trend
        }
      else if(bars_high>bars_low)
        {
         this.middle_swing_lf_datetime=this.time_buff[bars_low];   // time of left point of a swing on the chart of the middle trend
         this.middle_swing_lf_price=this.price_buff[bars_low];     // price of left point of a swing on the chart of the middle trend
         this.middle_swing_rt_datetime=this.time_buff[bars_high];  // time of right point of a swing on the chart of the middle trend
         this.middle_swing_rt_price=this.price_buff[bars_high];    // price of right point of a swing on the chart of the middle trend
        }
      else
        {
         return(-1);
        }

      //	set parameters of the middle swing
      this.SetMiddleSwingParameters(this.middle_swing_lf_datetime,this.middle_swing_lf_price,this.middle_swing_rt_datetime,this.middle_swing_rt_price);

      return(0);
     }
   else
     {
      return(-1);
     }
  }
//---------------------------------------------------------------------
//	Sets swing parameters of the main trend
//---------------------------------------------------------------------
void TGannBreakSignal::SetMainSwingParameters(datetime _lf_dt,double _lf_price,datetime _rt_dt,double _rt_price)
  {
   this.main_swing_continuance = ( int )( _rt_dt - _lf_dt ) / PeriodSeconds( this.m_period );
   this.main_swing_size_points = MathAbs( _rt_price - _lf_price ) / this.PriceLevelUnit( );
  }
//---------------------------------------------------------------------
//	Sets swing parameters of the middle trend
//---------------------------------------------------------------------
void TGannBreakSignal::SetMiddleSwingParameters(datetime _lf_dt,double _lf_price,datetime _rt_dt,double _rt_price)
  {
   this.middle_swing_continuance = ( int )( _rt_dt - _lf_dt ) / PeriodSeconds( this.m_period );
   this.middle_swing_size_points = MathAbs( _rt_price - _lf_price ) / this.PriceLevelUnit( );
  }
//---------------------------------------------------------------------
//	Gets swing duration time of the main trend:
//---------------------------------------------------------------------
int TGannBreakSignal::GetMainSwingContinuance()
  {
   return(this.main_swing_continuance);
  }
//---------------------------------------------------------------------
//	Gets swing amplitude (in 4-digit points) of the main trend:
//---------------------------------------------------------------------
double TGannBreakSignal::GetMainSwingSizePoints()
  {
   return(this.main_swing_size_points);
  }
//---------------------------------------------------------------------
//	Gets swing duration time of the middle trend
//---------------------------------------------------------------------
int TGannBreakSignal::GetMiddleSwingContinuance()
  {
   return(this.middle_swing_continuance);
  }
//---------------------------------------------------------------------
//	Gets swing amplitude (in 4-digit points) of the middle trend
//---------------------------------------------------------------------
double TGannBreakSignal::GetMiddleSwingSizePoints()
  {
   return(this.middle_swing_size_points);
  }
//---------------------------------------------------------------------
