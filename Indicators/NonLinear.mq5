//+------------------------------------------------------------------+
//|                                       ^X_NonLinearRegression.mq5 |
//|                     Copyright ? 2007, Mr.WT, Senior Linux Hacker |
//|                                     http://w-tiger.narod.ru/wk2/ |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright ? 2007, Mr.WT, Senior Linux Hacker"
//---- link to the website of the author
#property link      "http://w-tiger.narod.ru/wk2/"
//---- indicator version
#property version   "2.01"
//---- drawing the indicator in the main window
#property indicator_chart_window
#property indicator_buffers  0
#property indicator_plots    0
//+-----------------------------------+
//|  Declaration of enumeration       |
//+-----------------------------------+  
enum WIDTH
  {
   Width_1=1, // 1
   Width_2,   // 2
   Width_3,   // 3
   Width_4,   // 4
   Width_5    // 5
  };
//+-----------------------------------+
//|  Declaration of enumeration       |
//+-----------------------------------+
enum STYLE
  {
   SOLID_,      // Solid line
   DASH_,       // Dashed line
   DOT_,        // Dotted line
   DASHDOT_,    // Dot-dash line
   DASHDOTDOT_  // Dot-dash line with double dots
  };
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int period=120;
input uint RegressionDegree_=5;
input double KNL_Dev=2.72;
input color RegressionColor1 = SpringGreen; // Regression color 1
input color RegressionColor2 = Red;         // Regression color 2
input color RegressionColor3 = BlueViolet;  // Regression color 3
input color RegressionColor4 = Magenta;     // Regression color 4
input STYLE  linesStyle=DASH_;              // Lines style
input WIDTH  linesWidth=Width_1;            // Lines width
//+----------------------------------------------+
//---- declaration of global variables
double fx,fx1;
double a[10][10],b[10],x[10],sx[20];
double sum,sum1,sq;
int p,nn,kt;
//----
datetime te,te1,tp,t0;
int i0,ip,pn,i0n,ipn,RegressionDegree;
string str;
//+------------------------------------------------------------------+
//| init                                                             |
//+------------------------------------------------------------------+
bool init(int RatesTotal,const datetime &Time[])
  {
//----
   p=period;

//---- too small history
   if(p>RatesTotal)
     {
      Comment("\n\n                    ERROR - TOO SMALL HISTORY, RETURN NOW!");
      return(false);
     }

//---- ar
   kt=PeriodSeconds();
   nn=RegressionDegree+1;
//----------------------
   t0=Time[0];
   i0=0;
   ip=i0+p;
   tp=Time[ip];
   pn=p;
//---- ar
   for(int j=-p/2; j<p; j++)
     {
      string sJ=str+")"+string(j);

      int r=i0+j;
      if(r<0) r=0;
      ObjectCreate(0,"_ar("+sJ,OBJ_TREND,0,Time[r+1],0,Time[r],0);
      ObjectSetInteger(0,"_ar("+sJ,OBJPROP_RAY,false);
      ObjectSetInteger(0,"_ar("+sJ,OBJPROP_STYLE,linesStyle);
      ObjectSetInteger(0,"_ar("+sJ,OBJPROP_WIDTH,linesWidth);

      ObjectCreate(0,"_arH("+sJ,OBJ_TREND,0,Time[r+1],0,Time[r],0);
      ObjectSetInteger(0,"_arH("+sJ,OBJPROP_RAY,false);
      ObjectSetInteger(0,"_arH("+sJ,OBJPROP_STYLE,linesStyle);
      ObjectSetInteger(0,"_arH("+sJ,OBJPROP_WIDTH,linesWidth);

      ObjectCreate(0,"_arL("+sJ,OBJ_TREND,0,Time[r+1],0,Time[r],0);
      ObjectSetInteger(0,"_arL("+sJ,OBJPROP_RAY,false);
      ObjectSetInteger(0,"_arL("+sJ,OBJPROP_STYLE,linesStyle);
      ObjectSetInteger(0,"_arL("+sJ,OBJPROP_WIDTH,linesWidth);
     }
//----
   return(true);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initializations of a variable for the indicator short name
   str="";
   StringConcatenate(str,period,",",RegressionDegree,",",DoubleToString(KNL_Dev,3));
   IndicatorSetString(INDICATOR_SHORTNAME,"X_NonLinearRegression_v2.0.1("+str+")");

   RegressionDegree=int(RegressionDegree_);
   if(RegressionDegree>8) RegressionDegree=8;

//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//---- creating labels for displaying in DataWindow and the name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"DinapoliTargets");
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   for(int j=p; j>=-p/2; j--)
     {
      string sJ=str+")"+string(j);
      ObjectDelete(0,"_ar("+sJ);
      ObjectDelete(0,"_arH("+sJ);
      ObjectDelete(0,"_arL("+sJ);
     }

   Comment("");
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &Time[],
                const double &Open[],
                const double& high[],     // price array of maximums of price for the calculation of indicator
                const double& low[],      // price array of minimums of price for the calculation of indicator
                const double &Close[],
                const long &Tick_volume[],
                const long &Volume[],
                const int &Spread[])
  {
//----
   if(rates_total<period+1) return(0);
   if(rates_total==prev_calculated) return(rates_total);

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(Time,true);
   ArraySetAsSeries(Close,true);

   for(int j=p; j>=-p/2; j--)
     {
      string sJ=str+")"+string(j);
      ObjectDelete(0,"_ar("+sJ);
      ObjectDelete(0,"_arH("+sJ);
      ObjectDelete(0,"_arL("+sJ);
     }

   if(!init(rates_total,Time)) return(0);

//----
   int i,j,n,k;
//----
   if(i0n!=i0 || ipn!=ip)
     {
      p=ip-i0;
      i0n=ip;
      ipn=ip;

      if(pn<p)
        {
         for(j=pn; j<=p; j++)
           {
            string sJ=str+")"+string(j);
            ObjectCreate(0,"_ar("+sJ,OBJ_TREND,0,Time[i0+1+j],0,Time[i0+j],0);
            ObjectSetInteger(0,"_ar("+sJ,OBJPROP_RAY,false);
            ObjectSetInteger(0,"_ar("+sJ,OBJPROP_STYLE,linesStyle);
            ObjectSetInteger(0,"_ar("+sJ,OBJPROP_WIDTH,linesWidth);

            ObjectCreate(0,"_arH("+sJ,OBJ_TREND,0,Time[i0+1+j],0,Time[i0+j],0);
            ObjectSetInteger(0,"_arH("+sJ,OBJPROP_RAY,false);
            ObjectSetInteger(0,"_arH("+sJ,OBJPROP_STYLE,linesStyle);
            ObjectSetInteger(0,"_arH("+sJ,OBJPROP_WIDTH,linesWidth);

            ObjectCreate(0,"_arL("+sJ,OBJ_TREND,0,Time[i0+1+j],0,Time[i0+j],0);
            ObjectSetInteger(0,"_arL("+sJ,OBJPROP_RAY,false);
            ObjectSetInteger(0,"_arL("+sJ,OBJPROP_STYLE,linesStyle);
            ObjectSetInteger(0,"_arL("+sJ,OBJPROP_WIDTH,linesWidth);
           }

         for(j=-pn/2; j>=-p/2; j--)
           {
            string sJ=str+")"+string(j);
            ObjectCreate(0,"_ar("+sJ,OBJ_TREND,0,Time[i0+1+j],0,Time[i0+j],0);
            ObjectSetInteger(0,"_ar("+sJ,OBJPROP_RAY,false);
            ObjectSetInteger(0,"_ar("+sJ,OBJPROP_STYLE,linesStyle);
            ObjectSetInteger(0,"_ar("+sJ,OBJPROP_WIDTH,linesWidth);

            ObjectCreate(0,"_arH("+sJ,OBJ_TREND,0,Time[i0+1+j],0,Time[i0+j],0);
            ObjectSetInteger(0,"_arH("+sJ,OBJPROP_RAY,false);
            ObjectSetInteger(0,"_arH("+sJ,OBJPROP_STYLE,linesStyle);
            ObjectSetInteger(0,"_arH("+sJ,OBJPROP_WIDTH,linesWidth);

            ObjectCreate(0,"_arL("+sJ,OBJ_TREND,0,Time[i0+1+j],0,Time[i0+j],0);
            ObjectSetInteger(0,"_arL("+sJ,OBJPROP_RAY,false);
            ObjectSetInteger(0,"_arL("+sJ,OBJPROP_STYLE,linesStyle);
            ObjectSetInteger(0,"_arL("+sJ,OBJPROP_WIDTH,linesWidth);
           }

         pn=p;
        }

      if(pn>p)
        {
         for(j=pn; j>=p; j--)
           {
            string sJ=str+")"+string(j);
            ObjectDelete(0,"_ar("+sJ);
            ObjectDelete(0,"_arH("+sJ);
            ObjectDelete(0,"_arL("+sJ);
           }

         for(j=-p/2; j>=-pn/2; j--)
           {
            string sJ=str+")"+string(j);
            ObjectDelete(0,"_ar("+sJ);
            ObjectDelete(0,"_arH("+sJ);
            ObjectDelete(0,"_arL("+sJ);
           }
         pn=p;
        }
     }

//---- PR
   sx[1]=p+1;

//---- sx
   for(i=1; i<=nn*2-2; i++)
     {
      sum=0.0;
      for(n=i0; n<=i0+p; n++) sum+=MathPow(n,i);
      sx[i+1]=sum;
     }

//---- syx
   for(i=1; i<=nn; i++)
     {
      sum=0.0;
      for(n=i0; n<=i0+p; n++)
        {
         if(i==1) sum+=Close[n];
         else
            sum+=Close[n]*MathPow(n,i-1);
        }
      b[i]=sum;
     }

//---- Matrix
   for(j=1; j<=nn; j++) for(i=1; i<=nn; i++) {k=i+j-1; a[i][j]=sx[k];}

//---- Gauss
   af_Gauss(nn);

//---- SQ
   sq=0.0;
   for(n=p; n>=0; n--)
     {
      sum=0.0;
      for(k=1; k<=RegressionDegree; k++)
        {
         sum+=x[k+1]*MathPow(i0+n,k);
         sum1+=x[k+1]*MathPow(i0+n+1,k);
        }

      fx=x[1]+sum;
      sq+=MathPow(Close[n+i0]-fx,2);
     }
   sq=KNL_Dev*MathSqrt(sq/(p+1));
//----

   for(n=p; n>=-p/2; n--)
     {
      sum=0.0;
      sum1=0.0;
      string sN=str+")"+string(n);

      for(k=1; k<=RegressionDegree; k++)
        {
         sum+=x[k+1]*MathPow(i0+n,k);
         sum1+=x[k+1]*MathPow(i0+n+1,k);
        }
      fx=x[1]+sum;
      fx1=x[1]+sum1;

      if(n>=0 && n<p)
        {
         ObjectMove(0,"_ar("+sN,0,Time[n+i0+1],fx1);
         ObjectMove(0,"_ar("+sN,1,Time[n+i0],fx);
         ObjectMove(0,"_arH("+sN,0,Time[n+i0+1],fx1+sq);
         ObjectMove(0,"_arH("+sN,1,Time[n+i0],fx+sq);
         ObjectMove(0,"_arL("+sN,0,Time[n+i0+1],fx1-sq);
         ObjectMove(0,"_arL("+sN,1,Time[n+i0],fx-sq);

         if(fx>fx1)
           {
            ObjectSetInteger(0,"_ar("+sN,OBJPROP_COLOR,RegressionColor1);
            ObjectSetInteger(0,"_arH("+sN,OBJPROP_COLOR,RegressionColor1);
            ObjectSetInteger(0,"_arL("+sN,OBJPROP_COLOR,RegressionColor1);
           }
         if(fx<fx1)
           {
            ObjectSetInteger(0,"_ar("+sN,OBJPROP_COLOR,RegressionColor2);
            ObjectSetInteger(0,"_arH("+sN,OBJPROP_COLOR,RegressionColor2);
            ObjectSetInteger(0,"_arL("+sN,OBJPROP_COLOR,RegressionColor2);
           }
        }

      if(n<0)
        {
         if((n+i0)>=0)
           {
            ObjectMove(0,"_ar("+sN,0,Time[n+i0+1],fx1);
            ObjectMove(0,"_ar("+sN,1,Time[n+i0],fx);
            ObjectMove(0,"_arH("+sN,0,Time[n+i0+1],fx1+sq);
            ObjectMove(0,"_arH("+sN,1,Time[n+i0],fx+sq);
            ObjectMove(0,"_arL("+sN,0,Time[n+i0+1],fx1-sq);
            ObjectMove(0,"_arL("+sN,1,Time[n+i0],fx-sq);
           }
         if((n+i0)<0)
           {
            te=Time[0]-(n+i0)*kt;
            te1=Time[0]-(n+i0+1)*kt;
            ObjectMove(0,"_ar("+sN,0,te1,fx1);
            ObjectMove(0,"_ar("+sN,1,te,fx);
            ObjectMove(0,"_arH("+sN,0,te1,fx1+sq);
            ObjectMove(0,"_arH("+sN,1,te,fx+sq);
            ObjectMove(0,"_arL("+sN,0,te1,fx1-sq);
            ObjectMove(0,"_arL("+sN,1,te,fx-sq);
           }

         if(fx>fx1)
           {
            ObjectSetInteger(0,"_ar("+sN,OBJPROP_COLOR,RegressionColor3);
            ObjectSetInteger(0,"_arH("+sN,OBJPROP_COLOR,RegressionColor3);
            ObjectSetInteger(0,"_arL("+sN,OBJPROP_COLOR,RegressionColor3);
           }
         if(fx<fx1)
           {
            ObjectSetInteger(0,"_ar("+sN,OBJPROP_COLOR,RegressionColor4);
            ObjectSetInteger(0,"_arH("+sN,OBJPROP_COLOR,RegressionColor4);
            ObjectSetInteger(0,"_arL("+sN,OBJPROP_COLOR,RegressionColor4);
           }
        }
     }
//----
   ChartRedraw(0);
//----  
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Custom indicator af_Gauss function                               |
//+------------------------------------------------------------------+    
void af_Gauss(int n)
  {
//----
   int i,j,k,l;
   double q,m,t;

   for(k=1; k<=n-1; k++)
     {
      l=0;
      m=0;
      for(i=k; i<=n; i++)
        {
         if(MathAbs(a[i][k])>m) {m=MathAbs(a[i][k]); l=i;}
        }
      if(l==0) return;

      if(l!=k)
        {
         for(j=1; j<=n; j++)
           {
            t=a[k][j];
            a[k][j]=a[l][j];
            a[l][j]=t;
           }
         t=b[k];
         b[k]=b[l];
         b[l]=t;
        }

      for(i=k+1;i<=n;i++)
        {
         q=a[i][k]/a[k][k];
         for(j=1;j<=n;j++)
           {
            if(j==k) a[i][j]=0;
            else
               a[i][j]=a[i][j]-q*a[k][j];
           }
         b[i]=b[i]-q*b[k];
        }
     }

   x[n]=b[n]/a[n][n];

   for(i=n-1;i>=1;i--)
     {
      t=0;
      for(j=1;j<=n-i;j++)
        {
         t=t+a[i][i+j]*x[i+j];
         x[i]=(1/a[i][i])*(b[i]-t);
        }
     }
//----
  }
//+--------------------