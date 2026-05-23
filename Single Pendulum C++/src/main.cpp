/*
* Magdi Laoun, 13.07.2025
* Balance of a bar moved by a motor with a PID controller
* Use of TMC5160 stepper motor driver
* Use of encoder to measure the position of the bar 400 lines
* Boards: ESP32-C3 super mini, TMC5160
*/
#include <Arduino.h>
#include <Pendulum.h>

union FloatBytes {
    float value;
    uint8_t bytes[4];
  };
struct MyData {
  float pendulumAngle; //sensor 1
  float pendulumSpeed; // sensor 1
  float cartPosition; //sensor 2
  float cartSpeed; // sensor 2
  float cycleTime; //time taken for one control cycle
  float phase; //phase of the control algorithm
  
};

Pendulum pendulum; // Create Pendulum object
uint64_t lastTime = 0; //Variable to store time
uint64_t lastCycleTime = 0; //Variable to store time taken for one control cycle
uint64_t cycleTime = 0; //Variable to store time taken for one control cycle
void checkSerial();
float getFloatValue(byte *input);
void transmitData();


void setup(){
  Serial.begin(115200); //Initialize serial communication at 115200 baud rate
  
  pendulum.begin( //Initialize pendulum with parameters
    10000, //Encoder resolution in steps
    200, //Motor steps per revolution
    16, //Motor microsteps per step
    0.08f, //Pulley circumference in meters
    50, //Encoder speed count for speed calculation
    50 //Cart speed count for speed calculation
  );
}
void loop(){
  cycleTime = micros() - lastCycleTime; //Calculate time taken for one control cycle
  lastCycleTime = micros(); //Update last cycle time
  checkSerial(); //Check for serial commands
  pendulum.updateAngle(); //Update angle and angular velocity of pendulum
  pendulum.updatePosition(); //Update position and velocity of cart
  if (micros() - lastTime > 100000) { //Update computer every 0.1 seconds
    transmitData(); //Transmit data to computer
    lastTime = micros();
  }
  pendulum.action(); //Perform control action based on current phase
}
void checkSerial(){
  if (Serial.available() > 0) { //If data is available on serial port
    byte *data = (byte *) malloc(5);
    Serial.readBytes(data, 5); //Read 5 bytes from serial port
    float value = getFloatValue(data); //Extract float value from received data
    pendulum.setValue(data[0], value); //Set value in pendulum object based on received data
    free(data);
  }
}
void transmitData() {
  MyData myData; //Create data structure to hold values to transmit
  myData.pendulumAngle = pendulum.angle;
  myData.pendulumSpeed = pendulum.angularVelocity;
  myData.cartPosition = pendulum.position;
  myData.cartSpeed = pendulum.velocity;
  myData.phase = float(pendulum.phase);
  myData.cycleTime = float(cycleTime); //Convert cycle time to float for transmission in microseconds
  uint8_t len = sizeof(myData);
  byte data[len + 1];
  data[0] = 0xAA; // Start byte
  for (size_t i = 0; i < len; i++) {
    data[i + 1] = *((uint8_t*)&myData + i);
  }
  Serial.write(data, len + 1); // Transmit data over Serial
  Serial.flush();
}

float getFloatValue(byte *input) {
  
  FloatBytes fb;
  for (int i = 0; i < 4; i++) {
    fb.bytes[i] = input[i+1]; //Copy bytes from input to union
  }
  float value = fb.value; //Get float value from union
  return value;
}