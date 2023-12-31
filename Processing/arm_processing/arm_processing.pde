/*
This code is made for processing https://processing.org/
*/

import processing.serial.*;     // import the Processing serial library
import themidibus.*; //Import the library
import java.lang.*;
import java.util.*;
import controlP5.*;
import com.jogamp.newt.opengl.GLWindow;


ControlP5 cp5;

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
int m11 = 0;
int m22 = 0;
int m33 = 0;

int ignorelines = 0;
boolean isLive = true;
boolean b_A_state = false;
boolean b_B_state = false;
boolean b_C_state = false;
boolean last_A_state = false;
boolean last_B_state = false;
boolean last_C_state = false;

boolean isConnected = false;
boolean splitx = false;
boolean splity = false;
boolean splitz = false;

boolean crossx = false;
boolean crossy = false;
boolean crossz = false;

int lastUpdate = 0;
int lastSerial = 0;
int winx;
int winy;

int min_ver = 0;
int maj_ver = 0;
String deviceName = "UNKNOWN";
boolean isValidDevice=false;



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
    if (myPort !=null)
    {
      myPort.stop();
      myPort = null;
    }
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



boolean ping_usbmodem()
{
  
  int maxping = 20;
  isValidDevice = false;
   for(int ii=0;ii<maxping;ii++)
   {
     myPort.write('Q');
     println("Query Sent"+ii);
     //We need to figure out how to do this right
     //Need to be ablew to identify different types of BABOIs
     if (isValidDevice)
        return true;
   }
   isValidDevice = true;
   return true;
}


boolean try_connect_usb_modem()
{
  boolean hasList = false;
  boolean isOpen = false;

  ArrayList<String> Seriallist = new ArrayList<String>();
  //Build a list of all USB Modems
  
  hasList = get_usbmodem_list(Seriallist);
  if (hasList == false)
    return false;
  
 //Loop Through List
 for (int ii = 0;ii < Seriallist.size();ii++)
 {
   isOpen = false;
   //Try to open Serial Port
   isOpen = try_to_open(Seriallist.get(ii));
   if (isOpen)
   {
     return ping_usbmodem();
   }
 }
 return false;
}

void Splitx(boolean theFlag) 
{
  splitx = theFlag;
  save_settings();
}

void Splity(boolean theFlag) 
{
  splity = theFlag;
  save_settings();    
}

void Splitz(boolean theFlag) 
{
  splitz = theFlag;
  save_settings();   
}

void setup() {
  size(400, 260,P3D);
  surface.setTitle("BABOI CONTROL");
  surface.setResizable(false);
  
  
  cp5 = new ControlP5(this);
  prepareExitHandler();
 
    load_settings();
    //setLocation(winx, winy);
    
  
  // create a new button with name 'buttonA'
  cp5.addButton("Range")
     .setBroadcast(false)
     .setValue(0)
     .setPosition(width-110,10)
     .setSize(100,18)
     .setBroadcast(true)
     ;
  
  // and add another 2 buttons
  cp5.addButton("Map")
     .setBroadcast(false)
     .setValue(100)
     .setPosition(width-110,30)
     .setSize(100,18)
     .setBroadcast(true)
     ;
  
    cp5.addToggle("Splitx")
     .setBroadcast(false)
     .setValue(splitx)
     .setPosition(width-110,60)
     .setSize(18,18)
     .setLabel("Split X")
     .setBroadcast(true)
     ;
  
    cp5.addToggle("Splity")
     .setBroadcast(false)
     .setValue(splity)
     .setPosition(width-70,60)
     .setSize(18,18)
     .setLabel("Split Y")
     .setBroadcast(true)
     ;
     
    cp5.addToggle("Splitz")
     .setBroadcast(false)
     .setValue(splitz)
     .setPosition(width-30,60)
     .setSize(18,18)
     .setLabel("Split Z")
     .setBroadcast(true)
     ;     
  
  MidiBus.list();
  myBus = new MidiBus(this, -1, "Bus 1"); // Create a new MidiBus with no input device and the default MacOS Midi Distributor as output
   

  
  smooth();
}

int c;

// function colorA will receive changes from 
// controller with name colorA
public void Range(int theValue) {
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

// function colorB will receive changes from 
// controller with name colorB
public void Map(int theValue) {
        if (isCal == false)
        isMap = !isMap;
}

void load_settings()
{
  JSONObject json;
  json = loadJSONObject("setup.json");
  
  if (json != null)
  {
    try
    {
      maxx = json.getFloat("maxx");
      minx = json.getFloat("minx");
      maxy = json.getFloat("maxy");
      miny = json.getFloat("miny");
      maxz = json.getFloat("maxz");
      minz = json.getFloat("minz");
      crossx = json.getBoolean("crossx");
      crossy = json.getBoolean("crossy");
      crossz = json.getBoolean("crossz");
      splitx = json.getBoolean("splitx");
      splity = json.getBoolean("splity");
      splitz = json.getBoolean("splitz");   
      winx = json.getInt("winx");        
      winy = json.getInt("winy");      
    }
    
    catch (Exception e)
    { //Print the type of error
      println("Error loading Preset", e);
      return;  //Tried to connect but no success... Maybe already used?
    }
      
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
  json.setBoolean("crossx",crossx);
  json.setBoolean("crossy",crossy);
  json.setBoolean("crossz",crossz);
  json.setBoolean("splitx",splitx);  
  json.setBoolean("splity",splity);    
  json.setBoolean("splitz",splitz);  
  json.setInt("winx",winx);  
  json.setInt("winy",winy);  
  
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
  
  
void show_map_text()
{
  //fill(0);
  //rect(10,height-10,200,height-110);
  fill(255);
  textAlign(LEFT);
  text("Mapping Keys:",20,height-80);
  text("X-Axis=1,Y-Axis=2,Z-Axis=3",20,height-60);
  text("X-Split=4,Y-Split=5,Z-Split=6",20,height-40);
  text("Button A=7,Button B=8,Button C=9",20,height-20);
}


void show_acceleration()
{
  int r = (int)map(accx,-4,4,64,255);
  int g = (int)map(accy,-4,4,64,255);
  int b = (int)map(accz+1,-4,4,64,255);
  stroke(r,g,b);
  fill(r,g,b);
}


void draw_labels()
{

  hint(DISABLE_DEPTH_TEST);
  if (isCal)
  {
    fill(128,0,0);
    rect(0,0,160,66);
  }
  else if (isMap)
  {
    fill(0,128,0);
    rect(0,0,160,66);     
  }

  fill(255);
  
  textAlign(LEFT);
  textSize(14);
  text(nf(cx,0,2),5,10);
  text(nf(cy,0,2),5,22);
  text(nf(cz,0,2),5,34);
  text(nf(minx,0,2)+"/"+nf(maxx,0,2),50,10);
  text(nf(miny,0,2)+"/"+nf(maxy,0,2),50,22);
  text(nf(minz,0,2)+"/"+nf(maxz,0,2),50,34);
  
  if (splitx)
    text(m1+"/"+m11,120,10);
  else
    text(m1,120,10);
    
  if (splity)  
    text(m2+"/"+m22,120,22);
  else
    text(m2,120,22);
  
  if (splitz)
    text(m3+"/"+m33,120,34);  
  else
    text(m3,120,34);  
      
      
  if (b_A_state)
    text("A", 5,46);
  
  if (b_B_state)
    text("B", 20,46);
    
  if (b_C_state)
    text("C", 35,46);
    
  text(deviceName+" V"+maj_ver+"."+min_ver, 5,58);  

    
  if (isMap)
         show_map_text();
         
  show_acceleration();
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
  
  if (splitx)
  {
      float half = map(50,0,100, minx,maxx);
      if (cx < half)
      {
        m1 =(int)map(cx,minx, half, 127,0);
        m1 = limit(m1,0,127);
        m11 = 0;
      }
      else
      {
        m11 =(int)map(cx,half, maxx, 0,127);
        m11 = limit(m11,0,127);
        m1 = 0;
      }
        ControlChange change1 = new ControlChange(0, 1, m1);
        myBus.sendControllerChange(change1);
        ControlChange change2 = new ControlChange(0, 4, m11);
        myBus.sendControllerChange(change2);        
      
  }
  else
  {
    m11 = 0;
    m1 =(int)map(cx,minx, maxx, 0,127);
    m1 = limit(m1,0,127);
    ControlChange change1 = new ControlChange(0, 1, m1);
    myBus.sendControllerChange(change1);
  }
  
  
  if (splity)
  {
      float half = map(50,0,100, miny,maxy);
      if (cy < half)
      {
        m2 =(int)map(cy,miny, half, 127,0);
        m2 = limit(m2,0,127);
        m22 = 0;
      }
      else
      {
        m22 =(int)map(cy,half, maxy, 0,127);
        m22 = limit(m22,0,127);
        m2 = 0;
      }
      
        ControlChange change1 = new ControlChange(0, 2, m2);
        myBus.sendControllerChange(change1);
        ControlChange change2 = new ControlChange(0, 5, m22);
        myBus.sendControllerChange(change2);        
      
  }
  else
  {
    m22 = 0;
    m2 =(int)map(cy,miny, maxy, 0,127);
    m2 = limit(m2,0,127);
    ControlChange change1 = new ControlChange(0, 2, m2);
    myBus.sendControllerChange(change1);
  }
  
  
  if (splitz)
  {
      float half = map(50,0,100, minz,maxz);

      if (cz < half)
      {
        m3 =(int)map(cz,minz, half, 127,0);
        m3 = limit(m3,0,127);
        m33 = 0;
      }
      else
      {
        m33 =(int)map(cz,half, maxz, 0,127);
        m33 = limit(m33,0,127);
        m3 = 0;
      }
      
        ControlChange change1 = new ControlChange(0, 3, m3);
        myBus.sendControllerChange(change1);
        ControlChange change2 = new ControlChange(0, 6, m33);
        myBus.sendControllerChange(change2);        
      
  }
  else
  {
    m33= 0;
    m3 =(int)map(cz,minz, maxz, 0,127);
    m3 = limit(m3,0,127);
    ControlChange change1 = new ControlChange(0, 3, m3);
    myBus.sendControllerChange(change1);
  }
}

//Button apparently are on/off...
void send_buttons()
{
  if ((last_A_state == false) && (b_A_state == true))
  {
    ControlChange change = new ControlChange(0, 7, 127);
    myBus.sendControllerChange(change);   
    change = new ControlChange(0, 7, 0);
    myBus.sendControllerChange(change);    
  }  
  last_A_state = b_A_state;
  
  if ((last_B_state == false) && (b_B_state == true))
  {
    ControlChange change = new ControlChange(0, 8, 127);
    myBus.sendControllerChange(change);   
    change = new ControlChange(0, 8, 0);
    myBus.sendControllerChange(change);    
  }  
  last_B_state = b_B_state;
  
  if ((last_C_state == false) && (b_C_state == true))
  {
    ControlChange change = new ControlChange(0, 8, 127);
    myBus.sendControllerChange(change);   
    change = new ControlChange(0, 8, 0);
    myBus.sendControllerChange(change);    
  }  
  last_C_state = b_C_state;  
  
 /* 
  if (a_active == true)
     val = 127;
  else
     val = 0;
    
  ControlChange change = new ControlChange(0, 7, val);
  myBus.sendControllerChange(change);
  */
/*  
  if ((last_A_state == false) && (b_A_state == true))
  {
    last_A_state = b_A_state;
    ControlChange change1 = new ControlChange(0, 7, 1);
    myBus.sendControllerChange(change1);
  }

  else if ((last_A_state == true) && (b_A_state == false))
  {
    last_A_state = b_A_state;
    ControlChange change1 = new ControlChange(0, 7, 0);
    myBus.sendControllerChange(change1);
  }

  if ((last_B_state == false) && (b_B_state == true))
  {
    last_B_state = b_B_state;
    ControlChange change1 = new ControlChange(0, 8, 1);
    myBus.sendControllerChange(change1);
  }

  else if ((last_B_state == true) && (b_B_state == false))
  {
    last_B_state = b_B_state;
    ControlChange change1 = new ControlChange(0, 8, 0);
    myBus.sendControllerChange(change1);
  }
  
  if ((last_C_state == false) && (b_C_state == true))
  {
    last_C_state = b_C_state;
    ControlChange change1 = new ControlChange(0, 9, 1);
    myBus.sendControllerChange(change1);
  }

  else if ((last_C_state == true) && (b_C_state == false))
  {
    last_C_state = b_C_state;
    ControlChange change1 = new ControlChange(0, 9, 0);
    myBus.sendControllerChange(change1);
  }  
*/  
}



void draw_cube()
{

  float dirY = (((float)height/4*3) / float(height) - 0.5) * 2;
  float dirX = (((float)width/4*3) / float(width) - 0.5) * 2;
  directionalLight(204, 204, 204, -dirX, -dirY, -1); //Why is this linked to the mouse? 
  noStroke();
  pushMatrix();
  translate(width/2, height/2);
  /*
  PMatrix3D rm = new PMatrix3D();
  rm = toMatrix(rm,qx,qy,qz,qw);
  applyMatrix(rm);
  */

  rotateY(zz);//yaw
  rotateX(xx);//pitch
  rotateZ(yy);//roll



  box(100, 100, 100);
  
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
    println("TIMEOUT");
    return false;
  }
  else
    return true;
}

void draw() 
{
  if(1==frameCount) 
  {
     surface.setLocation(winx,winy-28); //That '28' is the height of the menu bar... Ugly fudge but apparently hard to fix...
  }
  
  if (isLive)
    background(0);
  else
    background(255,0,0);
  //if (isConnected)
  //  println("CONNECTED");
  //else
  //  println("NOT CONNECTED");
    
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
      if ((isConnected) && (isLive))
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
  
    GLWindow glw = (GLWindow)surface.getNative();
    winx = glw.getX();
    winy = glw.getY();
}

void clear_cal_min_max()
{
  minx = 65535;
  maxx = -65535;
  miny = 65535;
  maxy = -65535;
  minz = 65535;
  maxz = -65535;  
  crossx = false;
  crossy = false;
  crossz = false;
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
    
    
  //Zero Crossover Detection
  if (((minx <= -3.1) || (maxx >+ 3.1)) && (crossx == false))
  {
    crossx = true;
    minx = 65535;
    maxx = -65535;  
  }
  if (((miny <+ -3.1) || (maxy >= 3.1)) && (crossy == false))
  {
    crossy = true;
    miny = 65535;
    maxy = -65535;  
  }  
  if (((minz <= -3.1) || (maxz >= 3.1)) && (crossz == false))
  {
    crossz = true;
    minz = 65535;
    maxz = -65535;  
  }
    
}

void serialEvent(Serial myPort) {

  float v1,v2,v3,v4;
  String myString = myPort.readStringUntil('\n');
  //println(myString);
  if (ignorelines == 0)
  {
    myString = trim(myString);
    String[] list = split(myString, ':');
    
    if (list[0].contains("BABOI"))
    {
      
      deviceName = list[0];
      maj_ver = parseInt(list[1]);
      min_ver = parseInt(list[2]);
      println(deviceName+":"+maj_ver+"."+min_ver);
      isValidDevice = true;
      return;
    }
    
    
    float sensors[] = float(list);
  
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
      yy = sensors[0];
      xx = sensors[1];
      zz = -sensors[2];   
      cx = xx;
      cy = yy;
      cz = zz;


      if (crossx)
      {
        if (cx < 0)
          cx = cx + 2*PI;
      }   
      
      if (crossy)
      {
        if (cy < 0)
          cy = cy + 2*PI;
      }   
      
      if (crossz)
      {
        if (cz < 0)
          cz = cz + 2*PI;
      }
      
      /*
      qx = sensors[3];
      qy = sensors[4];
      qz = sensors[5];
      qw = sensors[6];
      */
      
      accx = sensors[3];
      accy = sensors[4];
      accz = sensors[5];   
      
      
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
      if (key =='7')
      {
          ControlChange change1 = new ControlChange(0, 7, 1);
          myBus.sendControllerChange(change1);
      }
      if (key =='8')
      {
          ControlChange change1 = new ControlChange(0, 8, 1);
          myBus.sendControllerChange(change1);
      }
      if (key =='9')
      {
          ControlChange change1 = new ControlChange(0, 9, 1);
          myBus.sendControllerChange(change1);
      }          
    }
    else
    {
      if (key == 'r')
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
   
private void prepareExitHandler () 
{

Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() 
{
  public void run () 
  {
    System.out.println("SHUTDOWN HOOK");
    save_settings();
  }
}));
}
