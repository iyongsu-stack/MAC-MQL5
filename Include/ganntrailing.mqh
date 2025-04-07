//+------------------------------------------------------------------+
//|                                                 GannTrailing.mqh |
//|                                                   Dima S., 2011. |
//|                                                 dimascub@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Dima S., 2011 ã."
#property link      "dimascub@mail.ru"
//+------------------------------------------------------------------+
#include <Expert\ExpertTrailing.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Trailing on peaks/bottoms on the chart of the middle trend |
//| Type=Trailing                                                    |
//| Name=MiddleTrend                                                 |
//| Class=MiddleTrendTrailing                                        |
//| Page=                                                            |
//| Parameter=StopLossSpace,double,5.0                               |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
class MiddleTrendTrailing : public CExpertTrailing
  {
private:
   datetime          middle_swing_lf_datetime;  // time of left point of a swing on the chart of the main trend
   double            middle_swing_lf_price;     // price of left point of a swing on the chart of the main trend
   datetime          middle_swing_rt_datetime;  // time of right point of a swing on the chart of the main trend
   double            middle_swing_rt_price;     // price of right point of a swing on the chart of the main trend
   double            stop_loss_space;           // the distance between peak/bottom and stop loss price

   int               handle_middle_swing;
   double            middle_swing_buff[];
   datetime          time_buff[];
   double            price_buff[];

public:
                     MiddleTrendTrailing();     // constructor
                    ~MiddleTrendTrailing();     // destructor

private:
   int               GetMiddleSwing();          // get parameters of the middle swing

public:
   //	Settings:
   void              StopLossSpace(double _space);

public:
   //	Overloaded methods of CExpertTrailing class:
   virtual bool      ValidationSettings();
   virtual bool      InitIndicators(CIndicators *indicators);
   virtual bool      CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp);
   virtual bool      CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp);
  };
//---------------------------------------------------------------------
//	Class constructor
//---------------------------------------------------------------------
MiddleTrendTrailing::MiddleTrendTrailing()
  {
   this.stop_loss_space=0.0;
  }
//---------------------------------------------------------------------
//	Class destructor
//---------------------------------------------------------------------
MiddleTrendTrailing::~MiddleTrendTrailing()
  {
   if(this.handle_middle_swing!=INVALID_HANDLE)
     {
      IndicatorRelease(this.handle_middle_swing);
     }
  }
//---------------------------------------------------------------------
//	Settings
//---------------------------------------------------------------------
void MiddleTrendTrailing::StopLossSpace(double _space)
  {
   this.stop_loss_space=_space;
  }
//---------------------------------------------------------------------
//	Validation
//---------------------------------------------------------------------
bool MiddleTrendTrailing::ValidationSettings()
  {
   if(m_symbol==NULL)
     {
      Print("Wrong Parameter: m_symbol = ",this.m_symbol);
      return(false);
     }

   if(this.stop_loss_space<=0)
     {
      Print("Wrong Parameter: stop_loss_space = ",this.stop_loss_space);
      return(false);
     }

   return(true);
  }
//---------------------------------------------------------------------
//	Initialization of indicators
//---------------------------------------------------------------------
bool MiddleTrendTrailing::InitIndicators(CIndicators *_ind)
  {
   this.handle_middle_swing=iCustom(this.m_symbol.Name(),this.m_period,"GannMiddleTrend",1000,false,false,1,1,LightCyan,LightGreen,LightPink,LightGreen,LightPink,3);
   if(this.handle_middle_swing==INVALID_HANDLE)
     {
      return(false);
     }

   return(true);
  }
//---------------------------------------------------------------------
//	Checks conditions of trailing stop for long position
//---------------------------------------------------------------------
bool MiddleTrendTrailing::CheckTrailingStopLong(CPositionInfo *_position,double &_sl,double &_tp)
  {
   if(_position==NULL)
     {
      return(false);
     }

   if(this.GetMiddleSwing()==-1)
     {
      return(false);
     }

   double sl_req_price = this.m_symbol.NormalizePrice(MathMin(middle_swing_lf_price,middle_swing_rt_price ) - this.stop_loss_space * this.m_adjusted_point );
   if(_position.StopLoss() >= sl_req_price )
     {
      return(false);
     }

   _tp = EMPTY_VALUE;
   _sl = sl_req_price;

   return(true);
  }
//---------------------------------------------------------------------
//	Checks conditions of trailing stop for short position
//---------------------------------------------------------------------
bool MiddleTrendTrailing::CheckTrailingStopShort(CPositionInfo *_position,double &_sl,double &_tp)
  {
   if(_position==NULL)
     {
      return(false);
     }

   if(this.GetMiddleSwing()==-1)
     {
      return(false);
     }

   double sl_req_price = this.m_symbol.NormalizePrice(MathMax(middle_swing_lf_price,middle_swing_rt_price ) + this.stop_loss_space * this.m_adjusted_point );
   if(_position.StopLoss() <= sl_req_price )
     {
      return(false);
     }

   _tp = EMPTY_VALUE;
   _sl = sl_req_price;

   return(true);
  }

//---------------------------------------------------------------------
//	Get swing parameters of the middle trend chart
//---------------------------------------------------------------------
#define	SIZE_MIDDLE_TRAIL		200
//---------------------------------------------------------------------
int MiddleTrendTrailing::GetMiddleSwing()
  {
   bool is_high_found=false,is_low_found=false;
   int  bars_high=0,bars_low=0;

//	Get the values from the color buffer
   if(CopyBuffer(this.handle_middle_swing,1,0,SIZE_MIDDLE_TRAIL,this.middle_swing_buff)!=SIZE_MIDDLE_TRAIL)
     {
      return(-1);
     }

//	Get the values from the price buffer:
   if(CopyBuffer(this.handle_middle_swing,0,0,SIZE_MIDDLE_TRAIL,this.price_buff)!=SIZE_MIDDLE_TRAIL)
     {
      return(-1);
     }

//	Search for the first non-empty point on the chart
   int    index;
   bool   is_find=false;
   for(index=SIZE_MIDDLE_TRAIL-1; index>=0; index--)
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
   int color_prev=(int)(this.middle_swing_buff[index]);
   for(int i=index-1; i>=0; i--)
     {
      if(is_high_found==false && this.price_buff[i]>0.1 && this.middle_swing_buff[i]==0.0 && color_prev==1) // peak found
        {
         is_high_found=true;
         bars_high=i;

         //	if the peak and bottom found, break
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
      if(CopyTime(this.m_symbol.Name(),this.m_period,0,SIZE_MIDDLE_TRAIL,this.time_buff)!=SIZE_MIDDLE_TRAIL)
        {
         return(-1);
        }

      //	Save the peak/bottom points
      if(bars_low>bars_high)
        {
         this.middle_swing_lf_datetime=this.time_buff[bars_high];   // time of left point of a swing on the chart of the middle trend
         this.middle_swing_lf_price=this.price_buff[bars_high];     // price of left point of a swing on the chart of the middle trend
         this.middle_swing_rt_datetime=this.time_buff[bars_low];    // time of right point of a swing on the chart of the middle trend
         this.middle_swing_rt_price=this.price_buff[bars_low];      // price of right point of a swing on the chart of the middle trend
        }
      else if(bars_high>bars_low)
        {
         this.middle_swing_lf_datetime=this.time_buff[ bars_low ];     // time of left point of a swing on the chart of the middle trend
         this.middle_swing_lf_price = this.price_buff[ bars_low ];     // price of left point of a swing on the chart of the middle trend
         this.middle_swing_rt_datetime = this.time_buff[ bars_high ];  // time of right point of a swing on the chart of the middle trend
         this.middle_swing_rt_price= this.price_buff[ bars_high ];     // price of right point of a swing on the chart of the middle trend
        }
      else
        {
         return(-1);
        }

      return(0);
     }
   else
     {
      return(-1);
     }
  }

//---------------------------------------------------------------------