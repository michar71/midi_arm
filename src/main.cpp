#include "main.h"
#include <Arduino.h>
#include <Wire.h>
#include "MPU9250.h"
#include <FastLED.h>
#include <EEPROM.h>
//#include "BluetoothSerial.h" //Header File for Serial Bluetooth, will be added by default into Arduino
#include "ButtonClass.h"


String devicename = "BABOI";
int maj_ver = 0;
int min_ver = 9;


//#define DEBUG

//-------------------------------
// Add Very Long Press Mag Calib
// Store/load Mag Calib
//-------------------------------

//Sensor Stuff
//------------
MPU9250 mpu;
setup_t settings;

bool challenge = false;

//I2C Stuff
//---------
#define SDA D4
#define SCL D5

#define BATT_ADC A0
#define DATA_PIN D1
#define BUT_CTRL D3
#define BUT_A D10
#define BUT_B D9
#define BUT_C D8
#define STATUS_LED LED_BUILTIN //Asuming D2 here...

bool isLive = false;
int led_state = LOW;    // the current state of LED
bool but_ctrl_state = false;
bool but_a_state = false;
bool but_b_state = false;
bool but_c_state = false;

//LED/Button Stuff
//----------------

// How many leds in your strip?
#define NUM_LEDS 2

// For led chips like WS2812, which have a data line, ground, and power, you just
// need to define DATA_PIN.  For led chipsets that are SPI based (four wires - data, clock,
// ground, and power), like the LPD8806 define both DATA_PIN and CLOCK_PIN
// Clock pin only needed for SPI based chipsets when not using hardware SPI

// Define the array of leds
CRGB leds[NUM_LEDS];


ButtonClass but_ctrl(BUT_CTRL,false);


//---------------------------------
//--  Settings Stuff  -------------
//---------------------------------
void print_settings()
{     
    Serial.println("Settings");
    Serial.println("--------");
    Serial.print(settings.magic0);
    Serial.print(settings.magic1);
    Serial.print(settings.magic2);
    Serial.print(settings.magic3);
    Serial.print(settings.magic4);  
    Serial.println("--------");              
    Serial.print("Acc Bias X: ");
    Serial.println(settings.acc_bias_x);
    Serial.print("Acc Bias Y: ");
    Serial.println(settings.acc_bias_y);
    Serial.print("Acc Bias Z: ");
    Serial.println(settings.acc_bias_z);    
    Serial.println("");
    Serial.print("Gyro Bias X: ");
    Serial.println(settings.gyro_bias_x);
    Serial.print("Gyro Bias Y: ");
    Serial.println(settings.gyro_bias_y);
    Serial.print("Gyro Bias Z: ");
    Serial.println(settings.gyro_bias_z);    
    Serial.println("");
    Serial.print("Mag Bias X: ");
    Serial.println(settings.mag_bias_x);
    Serial.print("Mag Bias Y: ");
    Serial.println(settings.mag_bias_y);
    Serial.print("Mag Bias Z: ");
    Serial.println(settings.mag_bias_z);    
    Serial.println("");
    Serial.print("Mag Scale X: ");
    Serial.println(settings.mag_scale_x);
    Serial.print("Mag Scale Y: ");
    Serial.println(settings.mag_scale_y);
    Serial.print("Mag Scale Z X: ");
    Serial.println(settings.mag_scale_z);    
    Serial.println("");    

}

void init_settings_acc_gyro()
{
  settings.magic0 = 'M';
  settings.magic1 = 'A';
  settings.magic2 = 'G';
  settings.magic3 = 'I';
  settings.magic4 = 'C';
  settings.acc_bias_x = 0;
  settings.acc_bias_y = 0;
  settings.acc_bias_z = 0;
  settings.gyro_bias_x = 0;
  settings.gyro_bias_y = 0;
  settings.gyro_bias_z = 0;
}

void init_settings_mag()
{
  settings.mag_bias_x = 0;
  settings.mag_bias_y = 0;
  settings.mag_bias_z = 0;
  settings.mag_scale_x = 1;
  settings.mag_scale_y = 1;
  settings.mag_scale_z = 1;
}

void save_settings()
{
    uint16_t ii;
    uint8_t* pData;

    settings.acc_bias_x = mpu.getAccBiasX();
    settings.acc_bias_y = mpu.getAccBiasY();
    settings.acc_bias_z = mpu.getAccBiasZ();
    settings.gyro_bias_x = mpu.getGyroBiasX();
    settings.gyro_bias_y = mpu.getGyroBiasY();
    settings.gyro_bias_z = mpu.getGyroBiasZ();
    settings.mag_bias_x = mpu.getMagBiasX();
    settings.mag_bias_y = mpu.getMagBiasY();
    settings.mag_bias_z = mpu.getMagBiasZ();
    settings.mag_scale_x = mpu.getMagScaleX();
    settings.mag_scale_y = mpu.getMagScaleY();
    settings.mag_scale_z = mpu.getMagScaleZ();

    EEPROM.put(0,settings);
    EEPROM.commit();

}

void load_settings()
{
    uint16_t ii;

    EEPROM.get(0,settings);       
#ifdef DEBUG  
    print_settings();    
#endif
  mpu.setAccBias(settings.acc_bias_x ,settings.acc_bias_y ,settings.acc_bias_z);
  mpu.setGyroBias(settings.gyro_bias_x,settings.gyro_bias_y,settings.gyro_bias_z);
  mpu.setMagBias(settings.mag_bias_x,settings.mag_bias_y,settings.mag_bias_z);
  mpu.setMagScale(settings.mag_scale_x,settings.mag_scale_y,settings.mag_scale_z);
}



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


void send_processing_data(bool senddata)
{
  //Plotting for Processing
  if (senddata)
  {
    Serial.print(mpu.getPitch()*DEG_TO_RAD);
    Serial.print(":");
    Serial.print(mpu.getRoll()*DEG_TO_RAD);
    Serial.print(":");
    Serial.print(mpu.getYaw()*DEG_TO_RAD);

/*
    Serial.print(":");
    Serial.print(mpu.getQuaternionX());
    Serial.print(":");
    Serial.print(mpu.getQuaternionY());
    Serial.print(":");
    Serial.print(mpu.getQuaternionZ());
    Serial.print(":");
    Serial.print(mpu.getQuaternionW());
*/

    Serial.print(":");
    Serial.print(mpu.getLinearAccX());
    Serial.print(":");
    Serial.print(mpu.getLinearAccY());
    Serial.print(":");
    Serial.print(mpu.getLinearAccZ());           
  }
  else
  {
    Serial.print("0:0:0:0:0:0");
  }

  if (but_ctrl_state)
  {
    Serial.print(":1");
  }
  else
  {
    Serial.print(":0");  
  }
  if (but_a_state)
  {
    Serial.print(":1");
  }
  else
  {
    Serial.print(":0");  
  }
  if (but_b_state)
  {
    Serial.print(":1");
  }
  else
  {
    Serial.print(":0");  
  }
  if (but_c_state)
  {
    Serial.println(":1");
  }
  else
  {
    Serial.println(":0");  
  }
}


void setup() 
{
    Serial.begin(115200);	
    Serial.setDebugOutput(true);
  #ifdef DEBUG
    Serial.println("Startup...");
  #endif
    Wire.begin(SDA, SCL);

    pinMode(STATUS_LED, OUTPUT);     
    pinMode(BUT_CTRL,INPUT_PULLUP);
    pinMode(BUT_A,INPUT_PULLUP);
    pinMode(BUT_B,INPUT_PULLUP);
    pinMode(BUT_C,INPUT_PULLUP);            
    delay(10);
    EEPROM.begin(1024);
    
  #ifdef DEBUG
    Serial.println("Pin Setup Done...");
  #endif

    //Init and test LED's
    FastLED.addLeds<NEOPIXEL, DATA_PIN>(leds, NUM_LEDS);  // GRB ordering is assumed

    setLED(0,64,0,0);
    delay(200);
    setLED(0,0,64,0);
    delay(200);    
    setLED(0,0,0,64);
    delay(200);
    setLED(0,0,0,0);

  #ifdef DEBUG
    Serial.println("LED Setup Done...");
  #endif
    //i2c_scan(&Wire);
    
    if (!mpu.setup(0x68)) {  // change to your own address
        Serial.println("ERROR");
        delay(5000);
    }
    delay(10);


  #ifdef DEBUG
    Serial.println("Sensor Setup Done...");
  #endif    

    load_settings();
    if ((settings.magic0 == 'M') && (settings.magic1 == 'A') && (settings.magic2 == 'G') && (settings.magic3 == 'I') && (settings.magic4 == 'C'))
    {
      delay(120);
      setLED(0,0,64,0);
      delay(120);
      setLED(0,0,0,0);

  #ifdef DEBUG
    Serial.println("Sensor Calib Load Done...");
    print_settings();
  #endif      
    }
    else
    {
      init_settings_acc_gyro();
      init_settings_mag();
      save_settings();
      delay(400);
      setLED(0,64,0,0);
      delay(400);
      setLED(0,0,0,0);

  #ifdef DEBUG
    Serial.println("Sensor Calib Load Failed...");
    print_settings();
  #endif
    }

  #ifdef DEBUG
    Serial.println("Setup Done...");
  #endif    
  setLED(0,64,64,0);
}


void serial_info_request(void)
{
  char incomingByte;

  if (Serial.available() > 0) 
  {
    // read the incoming byte:
    incomingByte = Serial.read();
    if (incomingByte == 'Q')
    {
      for (int ii=0;ii<10;ii++)
      {
        Serial.print(devicename);
        Serial.print(":");
        Serial.print(maj_ver);
        Serial.print(":");
        Serial.println(min_ver);
      }
      setLED(0,0,0,0);
      isLive = true;
      challenge = true;
    }
  } 
}

void loop() 
{
  //Check Mode button
  mode_button_e button_res;

  serial_info_request();

  button_res = but_ctrl.check_button();
  if (SHORT_PRESS == button_res)
  {
    isLive = !isLive;
  }  
  else if (button_res == LONG_PRESS)
  {
    setLED(1,0,0,255);
    delay(500);
    init_settings_acc_gyro();
    mpu.calibrateAccelGyro();
    delay(300);
    save_settings();
  #ifdef DEBUG    
    Serial.println("Sensor Calib Gyro/Acc Done...");
    print_settings();
  #endif  
  }
  else if (button_res == VERY_LONG_PRESS)
  {
    setLED(1,0,255,255);
    delay(1000);
    init_settings_mag();
    mpu.calibrateMag();
    delay(300);
    save_settings();    
  #ifdef DEBUG    
    Serial.println("Sensor Calib Mag Done...");
    print_settings();
  #endif      
  }

  but_ctrl_state = isLive;

  if (mpu.update()) 
  {
      EVERY_N_MILLIS(33)
      {
        if (digitalRead(BUT_A) == HIGH)
          but_a_state = false;
        else
          but_a_state = true; 
        if (digitalRead(BUT_B) == HIGH)
          but_b_state = false;
        else
          but_b_state = true; 
        if (digitalRead(BUT_C) == HIGH)
          but_c_state = false;
        else
          but_c_state = true;   

        if (isLive)
        {
          if (challenge)
            send_processing_data(true);
          setLED(1,0,64,0);
        }
        else
        {
          if (challenge)
            send_processing_data(false);
          setLED(1,64,0,0);
        }
      }
  }

  //Heartbeat
  EVERY_N_SECONDS(1)
  {
    led_state = !led_state;
    digitalWrite(STATUS_LED, led_state);
  }
}

