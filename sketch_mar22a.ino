#include <Wire.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <Adafruit_MLX90614.h>
#include "MAX30105.h"
#include "spo2_algorithm.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "TensorFlowLite_ESP32.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/micro/micro_mutable_op_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "mlp_model.h"
#include <TinyGPS++.h>
#include <HardwareSerial.h>

#define WIFI_SSID "ISIM_ETUDIANT"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"
#define FIREBASE_HOST "pfe-cardio-iot-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "YOUR_FIREBASE_AUTH"

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define BUZZER_PIN 13

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, 16);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
MAX30105 particleSensor;
Adafruit_MLX90614 mlx = Adafruit_MLX90614();

TinyGPSPlus gps;
HardwareSerial gpsSerial(1);
float last_lat = 0.0;
float last_lng = 0.0;
bool gps_valid = false;

uint32_t irBuffer[100];
uint32_t redBuffer[100];
int32_t spo2;
int8_t validSPO2;
int32_t heartRate;
int8_t validHeartRate;


static tflite::MicroErrorReporter micro_error_reporter;
tflite::ErrorReporter* error_reporter = &micro_error_reporter;
const tflite::Model* model_tfl = nullptr;
tflite::MicroInterpreter* interpreter = nullptr;
TfLiteTensor* input_tensor = nullptr;
TfLiteTensor* output_tensor = nullptr;
constexpr int kTensorArenaSize = 10 * 1024;
static uint8_t tensor_arena[kTensorArenaSize];


float mean_vals[12] = {
  70.75, 0.78, 69.84, 71.78,
  99.17, 0.08, 99.08, 99.26,
  35.86, 0.003, 35.86, 35.87
};
float scale_vals[12] = {
  17.83, 2.15, 17.48, 18.62,
  2.79, 0.40, 2.96, 2.69,
  0.67, 0.033, 0.68, 0.67
};

float hr_buf[10], spo2_buf[10], temp_buf[10];
int buf_idx = 0;
bool buf_full = false;
bool mlp_ok = false;


int warm_up_count = 0;
bool warm_up_done = false;


int last_bpm  = 0;
int last_spo2 = 0;


String ai_result = "En attente";
float ai_prob = 0;

float normalize(float val, int idx) {
  return (val - mean_vals[idx]) / scale_vals[idx];
}


void alarme_medicale() {
  for(int i = 0; i < 3; i++) {
    tone(BUZZER_PIN, 1500);
    delay(400);
    tone(BUZZER_PIN, 2500);
    delay(400);
  }
  noTone(BUZZER_PIN);
}


void alarme_sos() {
  for(int i = 0; i < 5; i++) {
    tone(BUZZER_PIN, 2500);
    delay(200);
    noTone(BUZZER_PIN);
    delay(100);
  }
}

void compute_features(float* features) {
  float hr_mean=0, hr_std=0, hr_min=999, hr_max=-999;
  float s_mean=0,  s_std=0,  s_min=999,  s_max=-999;
  float t_mean=0,  t_std=0,  t_min=999,  t_max=-999;

  for(int i=0; i<10; i++){
    hr_mean += hr_buf[i];
    s_mean  += spo2_buf[i];
    t_mean  += temp_buf[i];
    if(hr_buf[i]   < hr_min) hr_min = hr_buf[i];
    if(hr_buf[i]   > hr_max) hr_max = hr_buf[i];
    if(spo2_buf[i] < s_min)  s_min  = spo2_buf[i];
    if(spo2_buf[i] > s_max)  s_max  = spo2_buf[i];
    if(temp_buf[i] < t_min)  t_min  = temp_buf[i];
    if(temp_buf[i] > t_max)  t_max  = temp_buf[i];
  }
  hr_mean /= 10; s_mean /= 10; t_mean /= 10;

  for(int i=0; i<10; i++){
    hr_std += pow(hr_buf[i]   - hr_mean, 2);
    s_std  += pow(spo2_buf[i] - s_mean,  2);
    t_std  += pow(temp_buf[i] - t_mean,  2);
  }
  hr_std = sqrt(hr_std/10);
  s_std  = sqrt(s_std/10);
  t_std  = sqrt(t_std/10);

  features[0]  = normalize(hr_mean, 0);
  features[1]  = normalize(hr_std,  1);
  features[2]  = normalize(hr_min,  2);
  features[3]  = normalize(hr_max,  3);
  features[4]  = normalize(s_mean,  4);
  features[5]  = normalize(s_std,   5);
  features[6]  = normalize(s_min,   6);
  features[7]  = normalize(s_max,   7);
  features[8]  = normalize(t_mean,  8);
  features[9]  = normalize(t_std,   9);
  features[10] = normalize(t_min,  10);
  features[11] = normalize(t_max,  11);
}

void readGPS() {
  unsigned long start = millis();
  while (millis() - start < 500) {
    while (gpsSerial.available())
      gps.encode(gpsSerial.read());
  }
  if (gps.location.isValid() && gps.location.age() < 2000) {
    last_lat  = gps.location.lat();
    last_lng  = gps.location.lng();
    gps_valid = true;
  }
}

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);
  delay(1000);

  
  pinMode(BUZZER_PIN, OUTPUT);
  noTone(BUZZER_PIN);

  
  gpsSerial.begin(9600, SERIAL_8N1, 34, 12);

  
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.clearDisplay();
  display.setTextColor(WHITE);
  display.setTextSize(1);
  display.setCursor(20, 25);
  display.print("Projet PFE");
  display.display();
  delay(2000);

  
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  display.clearDisplay();
  display.setCursor(0, 25);
  display.print("Connexion WiFi...");
  display.display();
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi OK !");

  
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  
  particleSensor.begin(Wire, I2C_SPEED_FAST);
  particleSensor.setup(60, 4, 2, 100, 411, 4096);

  
  mlx.begin();

  
  model_tfl = tflite::GetModel(mlp_model_data);
  if (model_tfl->version() == TFLITE_SCHEMA_VERSION) {
    static tflite::MicroMutableOpResolver<5> resolver;
    resolver.AddFullyConnected();
    resolver.AddLogistic();
    resolver.AddRelu();
    resolver.AddQuantize();
    resolver.AddDequantize();

    static tflite::MicroInterpreter static_interpreter(
      model_tfl, resolver, tensor_arena, kTensorArenaSize, error_reporter);
    interpreter = &static_interpreter;

    if (interpreter->AllocateTensors() == kTfLiteOk) {
      input_tensor  = interpreter->input(0);
      output_tensor = interpreter->output(0);
      mlp_ok = true;
      Serial.println("MLP OK ✅");
    }
  }

  Serial.println("Pret !");
}

void loop() {
  
  readGPS();

  
  for (byte i = 0; i < 100; i++) {
    while (particleSensor.available() == false)
      particleSensor.check();
    redBuffer[i] = particleSensor.getRed();
    irBuffer[i]  = particleSensor.getIR();
    particleSensor.nextSample();
  }

  maxim_heart_rate_and_oxygen_saturation(
    irBuffer, 100, redBuffer,
    &spo2, &validSPO2,
    &heartRate, &validHeartRate
  );

  float tempObj = mlx.readObjectTempC();

  
  bool doigt_present = (particleSensor.getIR() > 50000);
  bool bpm_valide    = (heartRate > 40 && heartRate < 200
                        && heartRate != -999);
  bool spo2_valide   = (spo2 > 80 && spo2 <= 100
                        && spo2 != -999);

  
  if (doigt_present && bpm_valide)  last_bpm  = heartRate;
  if (doigt_present && spo2_valide) last_spo2 = spo2;

  
  Serial.print("doigt:"); Serial.print(doigt_present);
  Serial.print(" bpm_ok:"); Serial.print(bpm_valide);
  Serial.print(" spo2_ok:"); Serial.print(spo2_valide);
  Serial.print(" buf:"); Serial.print(buf_idx);
  Serial.print("/10 full:"); Serial.println(buf_full);


static unsigned long doigt_time = 0;
static bool timer_started = false;

if (doigt_present && !warm_up_done) {
  if (!timer_started) {
    doigt_time    = millis();
    timer_started = true;
    Serial.println("Doigt détecté → attente 15s...");
  }

  
  int restant = 20 - (int)((millis() - doigt_time) / 1000);
  if (restant < 0) restant = 0;

  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(20, 0);
  display.print("== Projet PFE ==");
  display.setCursor(10, 20);
  display.print("Stabilisation...");
  display.setTextSize(2);
  display.setCursor(50, 35);
  display.print(restant);
  display.setTextSize(1);
  display.setCursor(70, 42);
  display.print("sec");
  display.display();

  
  if (millis() - doigt_time >= 20000) {
    warm_up_done  = true;
    timer_started = false;
    Serial.println("Stabilisation OK ✅ → valeurs prêtes !");
  }
  return;
}


if (!doigt_present) {
  warm_up_done  = false;
  timer_started = false;
}

  if (doigt_present && warm_up_done && bpm_valide && spo2_valide) {
    // Temp corporelle si disponible, sinon 36.5 par défaut
    float temp_pour_buffer = (tempObj > 34.0 && tempObj < 42.0)
                              ? tempObj : 36.5;
    hr_buf[buf_idx]   = heartRate;
    spo2_buf[buf_idx] = spo2;
    temp_buf[buf_idx] = temp_pour_buffer;
    buf_idx++;
    if (buf_idx >= 10) {
      buf_idx  = 0;
      buf_full = true;
    }
    Serial.print("✅ Buffer: ");
    Serial.print(buf_idx);
    Serial.println("/10");
  }

  if (buf_full && mlp_ok) {
    float features[12];
    compute_features(features);
    for (int i = 0; i < 12; i++)
      input_tensor->data.f[i] = features[i];
    interpreter->Invoke();
    ai_prob   = output_tensor->data.f[0];
    ai_result = (ai_prob > 0.5) ? "ALERTE!" : "Normal";

    Serial.print("Modele: "); Serial.print(ai_prob);
    Serial.print(" -> "); Serial.println(ai_result);

    if (ai_prob > 0.5) {
      Serial.println("🚨 ANOMALIE !");
      alarme_medicale();
    }
  }

  if (Firebase.ready()) {
    bool sos = false;
    if (Firebase.getBool(fbdo, "/sensors/vitals/sos_active"))
      sos = fbdo.boolData();
    if (sos) {
      Serial.println("🆘 SOS !");
      Firebase.setBool(fbdo, "/sensors/vitals/sos_active", false);
      delay(300);
      alarme_sos();
    }
  }

  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(20, 0);
  display.print("== Projet PFE ==");

  // BPM
  display.setCursor(0, 14);
  display.print("BPM: ");
  display.setTextSize(2);
  if (!doigt_present)
    display.print("---");
  else if (warm_up_done && bpm_valide)
    display.print(heartRate);
  else
    display.print("...");

  // SpO2
  display.setTextSize(1);
  display.setCursor(0, 33);
  display.print("SpO2: ");
  display.setTextSize(2);
  if (!doigt_present)
    display.print("---");
  else if (warm_up_done && spo2_valide) {
    display.print(spo2);
    display.print("%");
  } else
    display.print("...");

  // Temp
  display.setTextSize(1);
  display.setCursor(0, 52);
  if (tempObj > 34.0 && tempObj < 42.0) {
    display.print("T:");
    display.print(tempObj, 1);
    display.print("C");
  } else {
    display.print("T:---");
  }

  display.setCursor(68, 52);
  if (buf_full && mlp_ok) {
    if (ai_prob > 0.5)
      display.print("ALERTE!");
    else
      display.print("OK");
  }

  display.display();

  // ✅ Firebase complet
  if (Firebase.ready()) {
    if (last_bpm > 0)
      Firebase.setInt(fbdo, "/sensors/vitals/bpm", last_bpm);
    if (last_spo2 > 0)
      Firebase.setInt(fbdo, "/sensors/vitals/spo2", last_spo2);
    if (tempObj > 20.0 && tempObj < 42.0)
      Firebase.setFloat(fbdo, "/sensors/vitals/temperature", tempObj);
    if (buf_full && mlp_ok)
      Firebase.setString(fbdo, "/sensors/vitals/ai_status", ai_result);
    if (gps_valid) {
      Firebase.setFloat(fbdo, "/sensors/vitals/latitude",  last_lat);
      Firebase.setFloat(fbdo, "/sensors/vitals/longitude", last_lng);
    }
  }

  // Serial final
  Serial.print("BPM:"); Serial.print(last_bpm);
  Serial.print(" SpO2:"); Serial.print(last_spo2);
  Serial.print(" Temp:"); Serial.print(tempObj);
  Serial.print(" GPS:"); Serial.print(gps_valid ? "OK" : "...");
  Serial.print(" Modele:"); Serial.println(ai_result);
}