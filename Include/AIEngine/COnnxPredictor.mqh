//+------------------------------------------------------------------+
//| COnnxPredictor.mqh — ONNX model inference wrapper                |
//| Phase 1-3 | AIEngine Module                                      |
//|                                                                  |
//| Loads ONNX model and runs inference to get probability output.   |
//| Supports LightGBM binary classification (predict_proba[:, 1]).   |
//|                                                                  |
//| Usage:                                                           |
//|   COnnxPredictor predictor;                                      |
//|   predictor.Init("models/model_long_ABC.onnx", 80);              |
//|   float features[80];                                            |
//|   // ... fill features ...                                       |
//|   double prob = predictor.Predict(features);                     |
//+------------------------------------------------------------------+
#ifndef __CONNXPREDICTOR_MQH__
#define __CONNXPREDICTOR_MQH__

//+------------------------------------------------------------------+
//| COnnxPredictor class                                             |
//+------------------------------------------------------------------+
class COnnxPredictor
{
private:
   long           m_handle;          // ONNX session handle
   int            m_featureCount;    // Number of input features
   bool           m_ready;           // Model loaded successfully
   string         m_modelPath;       // Path for logging
   string         m_lastError;       // Last error description
   
   //--- NaN defense
   int            m_nanRejectCount;  // Consecutive NaN reject counter
   bool           m_nanAlerted;      // Alert already fired (prevent spam)
   
   static const int NAN_ALERT_THRESHOLD;  // 500봉(≈8시간) 연속 NaN 시 Alert
   
public:
                  COnnxPredictor();
                 ~COnnxPredictor();
   
   //--- Initialization
   bool           Init(string modelPath, int featureCount);
   void           Deinit();
   
   //--- Inference
   double         Predict(float &features[]);
   
   //--- Status
   bool           IsReady() const             { return m_ready; }
   int            GetFeatureCount() const      { return m_featureCount; }
   string         GetLastError() const         { return m_lastError; }
   string         GetModelPath() const         { return m_modelPath; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
const int COnnxPredictor::NAN_ALERT_THRESHOLD = 500;  // ≈8시간 (M1 기준)

COnnxPredictor::COnnxPredictor()
   : m_handle(INVALID_HANDLE), m_featureCount(0), m_ready(false),
     m_nanRejectCount(0), m_nanAlerted(false)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
COnnxPredictor::~COnnxPredictor()
{
   Deinit();
}

//+------------------------------------------------------------------+
//| Initialize: load ONNX model from file                            |
//| modelPath: relative to MQL5/Files/ (or absolute for resources)   |
//| featureCount: number of input features (must match model)        |
//+------------------------------------------------------------------+
bool COnnxPredictor::Init(string modelPath, int featureCount)
{
   m_modelPath    = modelPath;
   m_featureCount = featureCount;
   m_ready        = false;
   m_lastError    = "";
   
   if(featureCount <= 0)
   {
      m_lastError = "Invalid featureCount: " + IntegerToString(featureCount);
      Print("[COnnxPredictor] ", m_lastError);
      return false;
   }
   
   // Create ONNX session from file
   // OnnxCreate loads from MQL5/Files/ path
   m_handle = OnnxCreate(modelPath, 0);
   
   if(m_handle == INVALID_HANDLE)
   {
      m_lastError = "OnnxCreate failed, error=" + IntegerToString(GetLastError());
      Print("[COnnxPredictor] ", m_lastError, " path=", modelPath);
      return false;
   }
   
   // Set input shape: [1, featureCount] (batch_size=1, features)
   long inputShape[] = {1, 0};
   inputShape[1] = (long)featureCount;
   
   if(!OnnxSetInputShape(m_handle, 0, inputShape))
   {
      m_lastError = "OnnxSetInputShape failed, error=" + IntegerToString(GetLastError());
      Print("[COnnxPredictor] ", m_lastError);
      OnnxRelease(m_handle);
      m_handle = INVALID_HANDLE;
      return false;
   }
   
   // Set output shape for probabilities: [1, 2] (binary classification → 2 classes)
   long outputShape[] = {1, 2};
   
   if(!OnnxSetOutputShape(m_handle, 1, outputShape))
   {
      // Try alternative: some LightGBM ONNX exports have output[0]=label, output[1]=proba
      // If output index 1 fails, try without setting (let ONNX auto-detect)
      Print("[COnnxPredictor] Warning: OnnxSetOutputShape(1) failed, error=",
            GetLastError(), " — trying auto-detect");
      m_lastError = "";
   }
   
   m_ready = true;
   Print("[COnnxPredictor] Model loaded: ", modelPath,
         " | features=", featureCount);
   
   return true;
}

//+------------------------------------------------------------------+
//| Release ONNX session                                             |
//+------------------------------------------------------------------+
void COnnxPredictor::Deinit()
{
   if(m_handle != INVALID_HANDLE)
   {
      OnnxRelease(m_handle);
      m_handle = INVALID_HANDLE;
   }
   m_ready = false;
}

//+------------------------------------------------------------------+
//| Run inference and return probability for class 1 (Win)            |
//|                                                                  |
//| LightGBM ONNX binary classifier outputs:                         |
//|   output[0] = predicted label (int64)                            |
//|   output[1] = probabilities array [P(class=0), P(class=1)]       |
//|                                                                  |
//| Returns: P(class=1) ∈ [0, 1]                                     |
//|          Returns -1.0 on error                                   |
//+------------------------------------------------------------------+
double COnnxPredictor::Predict(float &features[])
{
   if(!m_ready || m_handle == INVALID_HANDLE)
   {
      m_lastError = "Model not ready";
      return -1.0;
   }
   
   int inputSize = ArraySize(features);
   if(inputSize != m_featureCount)
   {
      m_lastError = "Feature count mismatch: got " +
                    IntegerToString(inputSize) + " expected " +
                    IntegerToString(m_featureCount);
      Print("[COnnxPredictor] ", m_lastError);
      return -1.0;
   }
   
   //--- NaN/INF 방어 게이트 (전략 A: Reject) ---
   int nanCount = 0;
   for(int i = 0; i < m_featureCount; i++)
   {
      if(!MathIsValidNumber(features[i]))
      {
         nanCount++;
         if(nanCount <= 5)  // 처음 5개만 로그 (스팸 방지)
            PrintFormat("[COnnxPredictor] NaN/INF at feature[%d] model=%s",
                        i, m_modelPath);
      }
   }
   if(nanCount > 0)
   {
      m_nanRejectCount++;
      m_lastError = StringFormat("NaN in %d/%d features — prediction skipped (streak=%d)",
                                 nanCount, m_featureCount, m_nanRejectCount);
      
      // 연속 NaN이 임계치 초과 시 Alert (1회만)
      if(m_nanRejectCount >= NAN_ALERT_THRESHOLD && !m_nanAlerted)
      {
         Alert(StringFormat("[COnnxPredictor] %s: %d봉 연속 NaN 발생! 데이터 파이프라인 점검 필요",
                            m_modelPath, m_nanRejectCount));
         m_nanAlerted = true;
      }
      return -1.0;  // prob < 0.20 → 자연스럽게 진입 스킵
   }
   
   // NaN 해소 시 카운터 리셋
   if(m_nanRejectCount > 0)
   {
      PrintFormat("[COnnxPredictor] NaN resolved after %d bars — model=%s",
                  m_nanRejectCount, m_modelPath);
      m_nanRejectCount = 0;
      m_nanAlerted = false;
   }
   
   // Prepare input: vectorf (1D float vector)
   vectorf inputVec;
   inputVec.Resize(m_featureCount);
   for(int i = 0; i < m_featureCount; i++)
      inputVec[i] = features[i];
   
   // Prepare outputs
   // output[0] = label (long), output[1] = probabilities (float[2])
   long   outLabel[];
   float  outProba[];
   ArrayResize(outLabel, 1);
   ArrayResize(outProba, 2);
   
   // Run inference
   if(!OnnxRun(m_handle, ONNX_NO_CONVERSION, inputVec, outLabel, outProba))
   {
      int err = GetLastError();
      m_lastError = "OnnxRun failed, error=" + IntegerToString(err);
      
      // Retry once
      ResetLastError();
      if(!OnnxRun(m_handle, ONNX_NO_CONVERSION, inputVec, outLabel, outProba))
      {
         m_lastError = "OnnxRun retry failed, error=" + IntegerToString(GetLastError());
         Print("[COnnxPredictor] ", m_lastError);
         return -1.0;
      }
   }
   
   // Return P(class=1) — probability of Win
   double prob = (double)outProba[1];
   
   // Sanity check
   if(prob < 0.0 || prob > 1.0)
   {
      Print("[COnnxPredictor] Warning: probability out of range: ", prob);
      prob = MathMax(0.0, MathMin(1.0, prob));
   }
   
   return prob;
}

#endif // __CONNXPREDICTOR_MQH__
