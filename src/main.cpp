#include "main.h"
#include <Arduino.h>
#include <Wire.h>
#include "MPU9250.h"
#include <FastLED.h>
#include <EEPROM.h>
//#include "BluetoothSerial.h" //Header File for Serial Bluetooth, will be added by default into Arduino
#include "ButtonClass.h"

//#define DEBUG

//-------------------------------
// Add Very Long Press Mag Calib
// Store/load Mag Calib
//-------------------------------

//Sensor Stuff
//------------
MPU9250 mpu;


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

bool isLive = true;
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
  }
  else
  {
    Serial.print("0:0:0");
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
    
  #ifdef DEBUG
    Serial.println("Pin Setup Done...");
  #endif

    //Init and test LED's
    FastLED.addLeds<NEOPIXEL, DATA_PIN>(leds, NUM_LEDS);  // GRB ordering is assumed
    setLED(0,0,0,0);
    delay(200);
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
    
    if (!mpu.setup(0x68)) {  // change to your own address
        Serial.println("ERROR");
        delay(5000);
    }
    delay(10);

  #ifdef DEBUG
    Serial.println("Sensor Setup Done...");
  #endif


  #ifdef DEBUG
    Serial.println("Setup Done...");
  #endif    
}


void loop() 
{
  //Check Mode button
  mode_button_e button_res;
  button_res = but_ctrl.check_button();
  if (SHORT_PRESS == button_res)
  {
    isLive = !isLive;
  }  
  else if (button_res == LONG_PRESS)
  {
    setLED(1,0,0,255);
    delay(500);
    mpu.calibrateAccelGyro();
    delay(300);

  }
  else if (button_res == VERY_LONG_PRESS)
  {
    setLED(1,0,255,255);
    delay(1000);
    mpu.calibrateMag();
    delay(300);
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
          send_processing_data(true);
          setLED(1,0,64,0);
        }
        else
        {
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

