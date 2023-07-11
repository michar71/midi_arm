/*
This code is made for processing https://processing.org/
*/

import processing.serial.*;     // import the Processing serial library
import themidibus.*; //Import the library


Serial myPort;                  // The serial port
String my_port = "/dev/cu.usbserial-12345678";        // choose your port
//String my_port = "/dev/tty.MIDIARM";        // choose your port
float xx, yy, zz;
float minx,maxx,miny,maxy,minz,maxz;
boolean isCal;
MidiBus myBus; // The MidiBus
int lastUpdate;
int m1 = 0;
int m2 = 0;
int m3 = 0;

void setup() {
  size(640, 480,P3D);
  
  // List all the available serial ports:
  printArray(Serial.list());
  println();
  MidiBus.list();

  myPort = new Serial(this, my_port, 115200);
  myPort.bufferUntil('\n');

  smooth();
  
   myBus = new MidiBus(this, -1, "Bus 1"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.

}


void draw_labels()
{
  int offsx = -width/2;
  int offsy = -height/2;
  hint(DISABLE_DEPTH_TEST);
  if (isCal)
    fill(255,0,0);
  else  
    fill(0);
  rect(offsx,offsy,140,30);
  fill(255);
  text(xx,5+offsx,10+offsy);
  text(yy,5+offsx,20+offsy);
  text(zz,5+offsx,30+offsy);
  text(minx+"/"+maxx,50+offsx,10+offsy);
  text(miny+"/"+maxy,50+offsx,20+offsy);
  text(minz+"/"+maxz,50+offsx,30+offsy);
  
  text(m1,110+offsx,10+offsy);
  text(m2,110+offsx,20+offsy);
  text(m3,110+offsx,30+offsy);
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
  m1 =(int)map(xx,minx, maxx, 0,255);
  m1 = limit(m1,0,255);
  ControlChange change1 = new ControlChange(channel, number, m1);
  myBus.sendControllerChange(change1);
  
  number = 2;
  m2 =(int)map(yy,miny, maxy, 0,255);
  m2 = limit(m2,0,255);
  ControlChange change2 = new ControlChange(channel, number, m2);
  myBus.sendControllerChange(change2);
  
  number = 3;
  m3 =(int)map(zz,minz, maxz, 0,255);
  m3 = limit(m3,0,255);  
  ControlChange change3 = new ControlChange(channel, number, m3);  
  myBus.sendControllerChange(change3);
}

void draw() {

  background(0);
  float dirY = (mouseY / float(height) - 0.5) * 2;
  float dirX = (mouseX / float(width) - 0.5) * 2;
  directionalLight(204, 204, 204, -dirX, -dirY, -1); 
  noStroke();
  translate(width/2, height/2);
  pushMatrix();
  rotateX(xx);//pitch
  rotateY(zz);//yaw
  rotateZ(yy);//roll
  box(100, 50, 600);
  popMatrix();
  draw_labels();
  
  if (isCal)
  {
    calc_call_min_max();
  }
  else
  {
    //limit update rate  
    if ((millis() - lastUpdate)>30)
    {
      lastUpdate = millis();
      send_midi();
    }
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
  if (xx<minx)
    minx = xx;
  if (maxx<xx)
    maxx=xx;
  if (yy<miny)
    miny = yy;
  if (maxy<yy)
    maxy=yy;
  if (zz<minz)
    minz = zz;
  if (maxz<zz)
    maxz=zz;
    
}

void serialEvent(Serial myPort) {

  String myString = myPort.readStringUntil('\n');
  myString = trim(myString);
  float sensors[] = float(split(myString, ':'));
  
  yy = sensors[0];
  xx = -sensors[1];
  zz = sensors[2];
  
  //println("roll: " + xx + " pitch: " + yy + " yaw: " + zz + "\n"); //debug

}

void keyPressed() {
  if (key == 'c')
  {
    if (isCal)
    {
      isCal = false;
    }
    else
    {
      isCal = true;
      clear_cal_min_max();
    }
  }
  }
