/*
This code is made for processing https://processing.org/
*/

import processing.serial.*;     // import the Processing serial library
import themidibus.*; //Import the library
import java.lang.*;
import java.util.*;

Serial myPort;                  // The serial port
String my_port = "/dev/cu.usbmodem145101";        // choose your port
//String my_port = "/dev/tty.MIDIARM";        // choose your port
float xx, yy, zz;
float cx,cy,cz;
float qx,qy,qz,qw;
float accx,accy,accz;
float minx,maxx,miny,maxy,minz,maxz;
boolean isCal;
boolean isMap;
MidiBus myBus; // The MidiBus

int m1 = 0;
int m2 = 0;
int m3 = 0;
int ignorelines = 20;
boolean isLive = true;
boolean b_A_state = false;
boolean b_B_state = false;
boolean b_C_state = false;
boolean last_A_state = false;
boolean last_B_state = false;
boolean last_C_state = false;

boolean isConnected = false;

int lastUpdate = 0;
int lastSerial = 0;

boolean get_usbmodem_list(ArrayList<String> list)
{

  String substring = "usbmodem";
   
  try 
  {
    //printArray(Serial.list());
    int i = Serial.list().length;
    if (i != 0) 
    {
    //Buil a list of all the USB Modems
      for (int j = 0; j < i;j++) 
      {
        if (Serial.list()[j].contains(substring) == true)
        {
          list.add(Serial.list()[j]);
        }
      }
      println(list);
      return true;
    }
    else
    {
      println("No Serial Port Found");
      return false;
    }
    
  }
  catch (Exception e)
  { //Print the type of error
    println("Serial List Error:", e);
    return false;  //Tried to connect but no success... Maybe already used?
  }
}


boolean try_to_open(String comport)
{
  try
  {
    myPort = new Serial(this, comport, 115200);
    if (myPort != null)
    {
      myPort.bufferUntil('\n');
      return true;
    }
    else 
    {
      return false; //No Serial Port device detected at all...
    }
  }
  catch (Exception e)
  { //Print the type of error
    println("Serial Open Error:", e);
    return false;  //Tried to connect but no success... Maybe already used?
  }  
}



boolean ping_usbmodem(String ID)
{
  //Do query up to 10 times
    //Send Query
    
    //Wait for Answer
    
    //It timeout
      //Return false
    //else
      //Store Answer
      return true;
}


boolean try_connect_usb_modem()
{
  boolean hasList = false;
  boolean isOpen = false;
  boolean isRightModem = false;
  ArrayList<String> Seriallist = new ArrayList<String>();
  //Build a list of all USB Modems
  
  hasList = get_usbmodem_list(Seriallist);
  if (hasList == false)
    return false;
  
 //Loop Through List
 for (int ii = 0;ii < Seriallist.size();ii++)
 {
   isOpen = false;
   isRightModem=false;
   //Try to open Serial Port
   isOpen = try_to_open(Seriallist.get(ii));
   if (isOpen)
   {
     isRightModem = ping_usbmodem("BABOI");
     if (isRightModem)
       return true;
     else
       return false;
   }
 }
 return false;
}


      
void setup() {
  size(640, 480,P3D);
  
  MidiBus.list();
  myBus = new MidiBus(this, -1, "Bus 1"); // Create a new MidiBus with no input device and the default MacOS Midi Distributor as output
   
  load_settings();
  
  smooth();
}

void load_settings()
{
  JSONObject json;
  json = loadJSONObject("setup.json");
  
  if (json != null)
  {
    maxx = json.getFloat("maxx");
    minx = json.getFloat("minx");
    maxy = json.getFloat("maxy");
    miny = json.getFloat("miny");
    maxz = json.getFloat("maxz");
    minz = json.getFloat("minz");
  }
}

void save_settings()
{
  JSONObject json = new JSONObject();

  json.setFloat("maxx",maxx);
  json.setFloat("minx",minx);
  json.setFloat("maxy",maxy);
  json.setFloat("miny",miny);
  json.setFloat("maxz",maxz);
  json.setFloat("minz",minz);
  
  saveJSONObject(json,"setup.json");
  
}



  PMatrix3D toMatrix(float x,float y, float z, float w) {
    return toMatrix(new PMatrix3D(),x,y,z,w);
  }
  
 PMatrix3D toMatrix(PMatrix3D out,float x, float y, float z,float w) 
 {
    float x2 = x + x; float y2 = y + y; float z2 = z + z;
    float xsq2 = x * x2; float ysq2 = y * y2; float zsq2 = z * z2;
    float xy2 = x * y2; float xz2 = x * z2; float yz2 = y * z2;
    float wx2 = w * x2; float wy2 = w * y2; float wz2 = w * z2;
    out.set(
      1.0 - (ysq2 + zsq2), xy2 - wz2, xz2 + wy2, 0.0,
      xy2 + wz2, 1.0 - (xsq2 + zsq2), yz2 - wx2, 0.0,
      xz2 - wy2, yz2 + wx2, 1.0 - (xsq2 + ysq2), 0.0,
      0.0, 0.0, 0.0, 1.0);
    return out;
  }
  
  
void draw_labels()
{
  int offsx = -width/2;
  int offsy = -height/2;
  hint(DISABLE_DEPTH_TEST);
  if (isCal)
    fill(255,0,0);
  else if (isMap)
     fill(0,255,0);
  else  
    fill(0);
  rect(offsx,offsy,140,40);
  fill(255);
  text(cx,5+offsx,10+offsy);
  text(cy,5+offsx,20+offsy);
  text(cz,5+offsx,30+offsy);
  text(minx+"/"+maxx,50+offsx,10+offsy);
  text(miny+"/"+maxy,50+offsx,20+offsy);
  text(minz+"/"+maxz,50+offsx,30+offsy);
  
  text(m1,110+offsx,10+offsy);
  text(m2,110+offsx,20+offsy);
  text(m3,110+offsx,30+offsy);
  
  if (b_A_state)
    text("A", 5+offsx,40+offsy);
  
  if (b_B_state)
    text("B", 20+offsx,40+offsy);
    
  if (b_C_state)
    text("C", 35+offsx,40+offsy);
    
  hint(ENABLE_DEPTH_TEST);
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}

int limit(int in, int min, int max)
{
  if (in > max)
    return max;
  if (in < min)
    return min;
  
  return in;  
}

void send_midi()
{
  int channel = 0;
  int number = 0;
  
  number = 1;
  m1 =(int)map(cx,minx, maxx, 0,127);
  m1 = limit(m1,0,127);
  ControlChange change1 = new ControlChange(channel, number, m1);
  myBus.sendControllerChange(change1);
  
  number = 2;
  m2 =(int)map(cy,miny, maxy, 0,127);
  m2 = limit(m2,0,127);
  ControlChange change2 = new ControlChange(channel, number, m2);
  myBus.sendControllerChange(change2);
  
  number = 3;
  m3 =(int)map(cz,minz, maxz, 0,127);
  m3 = limit(m3,0,127);  
  ControlChange change3 = new ControlChange(channel, number, m3);  
  myBus.sendControllerChange(change3);
}


void send_buttons()
{

  if ((last_A_state == false) && (b_A_state == true))
  {
    last_A_state = b_A_state;
    ControlChange change1 = new ControlChange(0, 4, 1);
    myBus.sendControllerChange(change1);
  }

  else if ((last_A_state == true) && (b_A_state == false))
  {
    last_A_state = b_A_state;
    ControlChange change1 = new ControlChange(0, 4, 0);
    myBus.sendControllerChange(change1);
  }

  if ((last_B_state == false) && (b_B_state == true))
  {
    last_B_state = b_B_state;
    ControlChange change1 = new ControlChange(0, 5, 1);
    myBus.sendControllerChange(change1);
  }

  else if ((last_B_state == true) && (b_B_state == false))
  {
    last_B_state = b_B_state;
    ControlChange change1 = new ControlChange(0, 5, 0);
    myBus.sendControllerChange(change1);
  }
  
  if ((last_C_state == false) && (b_C_state == true))
  {
    last_C_state = b_C_state;
    ControlChange change1 = new ControlChange(0, 6, 1);
    myBus.sendControllerChange(change1);
  }

  else if ((last_C_state == true) && (b_C_state == false))
  {
    last_C_state = b_C_state;
    ControlChange change1 = new ControlChange(0, 6, 0);
    myBus.sendControllerChange(change1);
  }  
}



void draw_cube()
{
  float dirY = (((float)height/4*3) / float(height) - 0.5) * 2;
  float dirX = (((float)width/4*3) / float(width) - 0.5) * 2;
  directionalLight(204, 204, 204, -dirX, -dirY, -1); //Why is this linked to the mouse? 
  noStroke();
  translate(width/2, height/2);
  pushMatrix();
  
  /*
  PMatrix3D rm = new PMatrix3D();
  rm = toMatrix(rm,qx,qy,qz,qw);
  applyMatrix(rm);
  */

  rotateZ(yy);//roll
  rotateX(xx);//pitch
  rotateY(zz);//yaw

  box(200, 200, 200);
  
  popMatrix();
}


void update_midi()
{

  //limit update rate  
  if ((millis() - lastUpdate)>30)
  {
    lastUpdate = millis();
    send_midi();
    send_buttons();
  }
}


boolean check_timeout()
{
  int timeout = 2000;
  int current_time = millis();
  if ((current_time - lastSerial) > timeout)
  {
    // Clear the buffer, or available() will still be > 0
    myPort.clear();
    // Close the port
      myPort.stop();
    return false;
  }
  else
    return true;
}

void draw() 
{
  background(0);
  if (isConnected)
  {
    draw_cube();
    draw_labels();
  
    if (isCal)
    {
      calc_call_min_max();
    }
    else if (isMap)
    {
      //Do nothin...
    }
    else
    {
      update_midi();
    }
   
     isConnected = check_timeout();  
  }
  else
  {
    fill(255,0,0);
    stroke(255,0,0);
    line(0,0,width,height);
    line(width,0,0,height);
    text("NO CONNECTION",width/2,height/2);
    isConnected = try_connect_usb_modem();
  }
}

void clear_cal_min_max()
{
  minx = 65535;
  maxx = -65535;
  miny = 65535;
  maxy = -65535;
  minz = 65535;
  maxz = -65535;  
}

void calc_call_min_max()
{
  if (cx<minx)
    minx = cx;
  if (maxx<cx)
    maxx=cx;
  if (cy<miny)
    miny = cy;
  if (maxy<cy)
    maxy=cy;
  if (cz<minz)
    minz = cz;
  if (maxz<cz)
    maxz=cz;
    
}

void serialEvent(Serial myPort) {

  float v1,v2,v3,v4;
  String myString = myPort.readStringUntil('\n');
  if (ignorelines == 0)
  {
    myString = trim(myString);
    float sensors[] = float(split(myString, ':'));
  
    v1 = sensors[6];
    if (v1 == 0)
    {
      isLive = false;
      b_A_state = false;
      b_B_state = false;
      b_C_state = false;
    }
    else
    {
      isLive = true;
      yy = -sensors[0];
      xx = sensors[1];
      zz = -sensors[2];   
      cx = xx + 10;
      cy = yy + 10;
      cz = zz + 10;
      
      /*
      qx = sensors[3];
      qy = sensors[4];
      qz = sensors[5];
      qw = sensors[6];
      */
      
      accx = sensors[3];
      accx = sensors[4];
      accx = sensors[5];      
      
      
      v2 = sensors[7];
      v3 = sensors[8];
      v4 = sensors[9];  
      
      
      if (v2 == 0)
        b_A_state = false;
      else
        b_A_state = true;
        
      if (v3 == 0)
        b_B_state = false;
      else
        b_B_state = true;
        
      if (v4 == 0)
        b_C_state = false;
      else
        b_C_state = true;         
    }
  }
  else
  {  
    ignorelines--;
  }
  //println("roll: " + xx + " pitch: " + yy + " yaw: " + zz + "\n"); //debug
  lastSerial = millis();

}

void keyPressed() 
{
   if(isConnected)
   {
    if (key == 'm')
    {
      if (isCal == false)
        isMap = !isMap;
    }
    
    if (isMap)
    {
      if (key =='1')
      {
          ControlChange change1 = new ControlChange(0, 1, 63);
          myBus.sendControllerChange(change1);
      }
      if (key =='2')
      {
          ControlChange change1 = new ControlChange(0, 2, 63);
          myBus.sendControllerChange(change1);
      }
      if (key =='3')
      {
          ControlChange change1 = new ControlChange(0, 3, 63);
          myBus.sendControllerChange(change1);
      }   
      if (key =='4')
      {
          ControlChange change1 = new ControlChange(0, 4, 1);
          myBus.sendControllerChange(change1);
      }
      if (key =='5')
      {
          ControlChange change1 = new ControlChange(0, 5, 1);
          myBus.sendControllerChange(change1);
      }
      if (key =='6')
      {
          ControlChange change1 = new ControlChange(0, 6, 1);
          myBus.sendControllerChange(change1);
      }        
    }
    else
    {
      if (key == 'c')
      {
        if (isCal)
        {
          isCal = false;
          save_settings();
        }
        else
        {
          isCal = true;
          clear_cal_min_max();
        }
      }      
    }
   }
  }
