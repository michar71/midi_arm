#include "main.h"
#include <Wire.h>
#include "GY_85.h"
#include <Arduino.h>
#include "SensorFusion.h" 
#include <FastLED.h>
#include <EEPROM.h>
#include "BluetoothSerial.h" //Header File for Serial Bluetooth, will be added by default into Arduino
#include "ButtonClass.h"

#define DEBUG

//Sensor Stuff
//------------
SF fusion_A;
SF fusion_B;

GY_85 GY85_A;     
GY_85 GY85_B;   

t_RawSensorData data_A;
t_RawSensorData data_B;

t_RawSensorData average_data_A;
t_RawSensorData average_data_B;

t_sensorFusionData fusionData_A;
t_sensorFusionData fusionData_B;


s_RawSensorData buffA[32];
s_RawSensorData buffB[32];


bool isLive = true;
int led_state = LOW;    // the current state of LED

//I2C Stuff
//---------
#define SDA_1 19
#define SCL_1 18

#define SDA_2 25
#define SCL_2 26


//LED/Button Stuff
//----------------

// How many leds in your strip?
#define NUM_LEDS 2

// For led chips like WS2812, which have a data line, ground, and power, you just
// need to define DATA_PIN.  For led chipsets that are SPI based (four wires - data, clock,
// ground, and power), like the LPD8806 define both DATA_PIN and CLOCK_PIN
// Clock pin only needed for SPI based chipsets when not using hardware SPI
#define DATA_PIN 17
// Define the array of leds
CRGB leds[NUM_LEDS];

#define TOUCH_BUTTON_1 12
#define TOUCH_BUTTON_2 14

#define STATUS_LED 16

BluetoothSerial ESP_BT; //Object for Bluetooth


setup_t settings;

ButtonClass Touch1(TOUCH_BUTTON_2,true);
ButtonClass Touch2(TOUCH_BUTTON_1,true);

void i2c_scan(TwoWire* tw)
{
  byte error, address;
  int nDevices;
 
  Serial.println("Scanning...");
 
  nDevices = 0;
  for(address = 1; address < 127; address++ )
  {
    // The i2c_scanner uses the return value of
    // the Write.endTransmisstion to see if
    // a device did acknowledge to the address.
    tw->beginTransmission(address);
    error = tw->endTransmission();
 
    if (error == 0)
    {
      Serial.print("I2C device found at address 0x");
      if (address<16)
        Serial.print("0");
      Serial.print(address,HEX);
      Serial.println("  !");
 
      nDevices++;
    }
    else if (error==4)
    {
      Serial.print("Unknown error at address 0x");
      if (address<16)
        Serial.print("0");
      Serial.println(address,HEX);
    }    
  }
  if (nDevices == 0)
    Serial.println("No I2C devices found\n");
  else
    Serial.println("done\n");
 
}

void setLED(uint8_t led,uint8_t r, uint8_t g, uint8_t b)
{
    // Turn the LED on, then pause
  leds[led].r= r;
  leds[led].g= g;
  leds[led].b= b;
  FastLED.show();
}

void cycleLED()
{
  static uint8_t col = 0;

  switch(col)
  {
    case 0:
    setLED(0,255,0,0);
    break;

    case 1:
    setLED(0,0,255,0);
    break;

    case 2:
    setLED(0,0,0,255);
    break;        
  }

  col++;
  if (col == 3)
    col = 0;
}



//---------------------------------
//--  Settings Stuff  -------------
//---------------------------------
void print_settings()
{     
    Serial.println("Settings");
    Serial.println("--------");
    Serial.print("Mode: ");
    Serial.println(settings.mode);
  
}

void init_settings()
{

}

void save_settings()
{
    uint16_t ii;
    uint8_t* pData;
    pData = (uint8_t*)&settings;

    for (ii=0;ii<sizeof(setup_t);ii++)
    {
        EEPROM.write(ii,*pData);
        pData++;
    }
    EEPROM.commit();
    print_settings();
}

void load_settings()
{
    uint16_t ii;
    uint8_t* pData;
    pData = (uint8_t*)&settings;

    for (ii=0;ii<sizeof(setup_t);ii++)
    {
        *pData = EEPROM.read(ii);
        pData++;
    }
                  
#ifndef USE_I2C    
    print_settings();    
#endif
}


void collect_data(GY_85* pSensor, t_RawSensorData* pData)
{

    pSensor->readFromAccelerometer();

    pData->accX = pSensor->accelerometer_x();
    pData->accY = pSensor->accelerometer_y();
    pData->accZ = pSensor->accelerometer_z();

    pSensor->readFromCompass();
    
    pData->magX = pSensor->compass_x();
    pData->magY = pSensor->compass_y();
    pData->magZ = pSensor->compass_z();

    pSensor->readGyro();

    pData->gyroX = pSensor->gyro_x();
    pData->gyroY = pSensor->gyro_y();
    pData->gyroZ = pSensor->gyro_z();
    pData->temp = pSensor->temp();  
}


void average_data(struct s_RawSensorData pBuff[], t_RawSensorData* pRawDataIn,t_RawSensorData* pRawDataOut,uint8_t avg_samples)
{
  
  int ii = 0;

  //Zero Out
  pRawDataOut->accX = 0;
  pRawDataOut->accY = 0;
  pRawDataOut->accZ = 0;
  pRawDataOut->gyroX = 0;
  pRawDataOut->gyroY = 0;
  pRawDataOut->gyroZ = 0;
  pRawDataOut->magX = 0;
  pRawDataOut->magY = 0;
  pRawDataOut->magZ = 0;
  pRawDataOut->temp = 0;


  //Shuffle
  for (ii=0;ii<avg_samples-1;ii++)
    pBuff[ii] = pBuff[ii+1];


  //Assign
  pBuff[avg_samples-1].accX = pRawDataIn->accX;
  pBuff[avg_samples-1].accY = pRawDataIn->accY;
  pBuff[avg_samples-1].accZ = pRawDataIn->accZ;
  pBuff[avg_samples-1].gyroX = pRawDataIn->gyroX;
  pBuff[avg_samples-1].gyroY = pRawDataIn->gyroY;
  pBuff[avg_samples-1].gyroZ = pRawDataIn->gyroZ;
  pBuff[avg_samples-1].magX = pRawDataIn->magX;
  pBuff[avg_samples-1].magY = pRawDataIn->magY;
  pBuff[avg_samples-1].magZ = pRawDataIn->magZ;
  pBuff[avg_samples-1].temp = pRawDataIn->temp;


  //Sum
  for (ii=0;ii<avg_samples;ii++)
  {
    pRawDataOut->accX = pRawDataOut->accX + pBuff[ii].accX;
    pRawDataOut->accY = pRawDataOut->accY + pBuff[ii].accY;
    pRawDataOut->accZ = pRawDataOut->accZ + pBuff[ii].accZ;
    pRawDataOut->gyroX = pRawDataOut->gyroX + pBuff[ii].gyroX;
    pRawDataOut->gyroY = pRawDataOut->gyroY + pBuff[ii].gyroY;
    pRawDataOut->gyroZ = pRawDataOut->gyroZ + pBuff[ii].gyroZ;
    pRawDataOut->magX = pRawDataOut->magX + pBuff[ii].magX;
    pRawDataOut->magY = pRawDataOut->magY + pBuff[ii].magY;
    pRawDataOut->magZ = pRawDataOut->magZ + pBuff[ii].magZ;
    pRawDataOut->temp = pRawDataOut->temp + pBuff[ii].temp;
  }


  //Divide
  pRawDataOut->accX = pRawDataOut->accX / avg_samples;
  pRawDataOut->accY = pRawDataOut->accY / avg_samples;
  pRawDataOut->accZ = pRawDataOut->accZ / avg_samples;
  pRawDataOut->gyroX = pRawDataOut->gyroX / avg_samples;
  pRawDataOut->gyroY = pRawDataOut->gyroY / avg_samples;
  pRawDataOut->gyroZ = pRawDataOut->gyroZ / avg_samples;
  pRawDataOut->magX = pRawDataOut->magX / avg_samples;
  pRawDataOut->magY = pRawDataOut->magY / avg_samples;
  pRawDataOut->magZ = pRawDataOut->magZ / avg_samples;
  pRawDataOut->temp = pRawDataOut->temp / avg_samples;

}

void fuse_data(SF* pFusion,t_RawSensorData* pRawData, t_sensorFusionData* pData)
{
  float deltat;

  deltat = pFusion->deltatUpdate(); //this have to be done before calling the fusion update

  //WHY DOES THE OVERLL DIRECTION DRIFT BACK TO STHE START POSITION EVEN IF THE COMPASS RAW DATA IS STABLE???? IF WE DON'T USE THE MAG IT WORKS BUT DRIFTS OVER TIME

  pFusion->MadgwickUpdate(pRawData->gyroX * DEG_TO_RAD, pRawData->gyroY * DEG_TO_RAD, pRawData->gyroZ * DEG_TO_RAD, pRawData->accX, pRawData->accY, pRawData->accZ,pRawData->magX,pRawData->magY,pRawData->magZ, deltat);   
   // pFusion->MadgwickUpdate(pRawData->gyroX * DEG_TO_RAD, pRawData->gyroY * DEG_TO_RAD, pRawData->gyroZ * DEG_TO_RAD, pRawData->accX, pRawData->accY, pRawData->accZ, deltat);    

  //pData->pitch = pFusion->getPitch();
  //pData->roll = pFusion->getRoll();   
  //pData->yaw = pFusion->getYaw();

  pData->roll = pFusion->getRollRadians();
  pData->pitch = pFusion->getPitchRadians();
  pData->yaw = pFusion->getYawRadians();
 
}

void send_data(String prefix, t_sensorFusionData* pFusionData)
{
  Serial.print(prefix); Serial.print(" Pitch:"); Serial.print(pFusionData->pitch); Serial.print(" Roll:"); Serial.print(pFusionData->roll); Serial.print(" Yaw:"); Serial.println(pFusionData->yaw);
  ESP_BT.print(prefix); ESP_BT.print(" Pitch:"); ESP_BT.print(pFusionData->pitch); ESP_BT.print(" Roll:"); ESP_BT.println(pFusionData->roll); ESP_BT.print(" Yaw:"); ESP_BT.print(pFusionData->yaw);
}

void send_processing_data(String prefix, t_sensorFusionData* pFusionData)
{
    //Plotting for Processing
  Serial.print(pFusionData->pitch);
  Serial.print(":");
  Serial.print(pFusionData->roll);
  Serial.print(":");
  Serial.println(pFusionData->yaw);

  //Plotting for Processing
  ESP_BT.print(pFusionData->pitch);
  ESP_BT.print(":");
  ESP_BT.print(pFusionData->roll);
  ESP_BT.print(":");
  ESP_BT.println(pFusionData->yaw);
}

void send_raw_data(String prefix, t_RawSensorData* pRawData)
{
  Serial.println(prefix); 
  Serial.print("Acc X:");
  Serial.print(pRawData->accX);
  Serial.print(" Acc Y:");
  Serial.print(pRawData->accY);
  Serial.print(" Acc Z:");
  Serial.println(pRawData->accZ);

  Serial.print("Mag X:");
  Serial.print(pRawData->magX);
  Serial.print(" Mag Y:");
  Serial.print(pRawData->magY);
  Serial.print(" Mag Z:");
  Serial.println(pRawData->magZ);  

  Serial.print("Gyro X:");
  Serial.print(pRawData->gyroX);
  Serial.print(" Gyro Y:");
  Serial.print(pRawData->gyroY);
  Serial.print(" Gyro Z:");
  Serial.println(pRawData->gyroZ);

  Serial.print("Temp:");
  Serial.println(pRawData->temp);

}



void setup() {
    Serial.begin(115200);	
    Serial.setDebugOutput(true);
  #ifdef DEBUG
    Serial.println("Startup...");
  #endif
    ESP_BT.begin("MIDI ARM"); //Name of your Bluetooth Signal
    Wire.begin(SDA_1, SCL_1);
    //Wire1.begin(SDA_2, SCL_2);
    pinMode(STATUS_LED, OUTPUT);     
    delay(10);
    
  #ifdef DEBUG
    Serial.println("Pin Setup Done...");
  #endif

    //Init and test LED's
    FastLED.addLeds<NEOPIXEL, DATA_PIN>(leds, NUM_LEDS);  // GRB ordering is assumed
    setLED(0,64,0,0);
    delay(400);
    setLED(0,0,64,0);
    delay(400);    
    setLED(0,0,0,64);
    delay(400);
    setLED(0,0,0,0);

  #ifdef DEBUG
    Serial.println("LED Setup Done...");
  #endif
    //i2c_scan(&Wire);
    
    GY85_A.init(&Wire);
    //GY85_B.init(&Wire1);
    delay(10);

    GY85_A.calibrate();

  #ifdef DEBUG
    Serial.println("Sensor Setup Done...");
  #endif


  #ifdef DEBUG
    Serial.println("Setup Done...");
  #endif    
}



void loop() {
  //Check Mode button
  mode_button_e button_res;
  button_res = Touch1.check_button();
  if (SHORT_PRESS == button_res)
  {
    isLive = !isLive;
  }  
  else if (button_res == LONG_PRESS)
  {
    setLED(1,0,0,255);
    delay(500);
    GY85_A.calibrate();
    delay(300);
  }

  EVERY_N_MILLIS(10)
  {
    //Should we do this more often and average over samples??  

    collect_data(&GY85_A, &data_A);
    //collect_data(&GY85_B, &data_B);

    average_data(buffA, &data_A, &average_data_A,5);
  }

  EVERY_N_MILLIS(33)
  {
    fuse_data(&fusion_A,&average_data_A,&fusionData_A);
    //fuse_data(&fusion_B,&data_B,&fusionData_B);

    if (isLive)
    {
      send_processing_data("Sensor A", &fusionData_A);
      //send_data("Sensor A", &fusionData_A);
      //send_data("Sensor B", &fusionData_B);
      setLED(1,0,64,0);
    }
    else
    {
      //send_raw_data("Sensor A", &data_A);
      setLED(1,64,0,0);
    }
  }

  //Heartbeat
  EVERY_N_SECONDS(1)
  {
    led_state = !led_state;
    digitalWrite(STATUS_LED, led_state);
  }
  


}

