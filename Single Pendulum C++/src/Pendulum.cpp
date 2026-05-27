//#include <Arduino.h>
#include "Pendulum.h"
#define CHA GPIO_NUM_5 //Encoder channel A
#define CHB GPIO_NUM_6 //Encoder channel B
#define EN GPIO_NUM_0 //TMC5160 Enable
#define CS GPIO_NUM_4 //TMC5160 Chip select
#define MISO GPIO_NUM_1 //TMC5160 MISO
#define MOSI GPIO_NUM_2 //TMC5160 MOSI
#define SCK GPIO_NUM_3 //TMC5160 Clock
#define CW 1 //Clockwise direction
#define CCW 2 //Counter-clockwise direction
void Pendulum::begin(uint32_t encoderResolution_, uint16_t motorMicrosteps_, uint32_t motorSteps_, float pulleyCircumference_, uint16_t encoderSpeedCount_, uint16_t cartSpeedCount_) {
    encoderResolution = encoderResolution_ ;
    motorMicrosteps = motorMicrosteps_;
    motorSteps = motorSteps_;
    pulleyCircumference = pulleyCircumference_;
    motorSpd.begin(cartSpeedCount_);
    encoderSpd.begin(encoderSpeedCount_);
    encoder.begin(CHA, CHB); //Initialize encoder with pin definitions
    tmc.begin(SCK, MOSI, MISO, CS, EN); //Initialize TMC5160 with pin definitions
    updateRatios();
}
void Pendulum::updateRatios() {
  angleRatio = (2.0f * PI) / static_cast<float>(encoderResolution); // Radians per encoder step
  distanceRatio = pulleyCircumference / (static_cast<float>(motorSteps) * static_cast<float>(motorMicrosteps)); // Meters per motor step
  accelerationRatio = 0.015f / distanceRatio; //Calculate acceleration unit for the motor
  speedRatio = 1.37f / distanceRatio; //Calculate speed unit for the motor
}
void Pendulum::resetEncoder() {
  encoder.resetPosition();
}
void Pendulum::resetTMC() {
  // 0: 256, 1: 128, 2: 64, 3: 32, 4: 16, 5: 8, 6: 4, 7: 2, 8: 1
  switch (motorMicrosteps) {
    case 256: tmc.init(0.05f, 0.4f, 0); break;
    case 128: tmc.init(0.05f, 0.4f, 1); break;
    case 64: tmc.init(0.05f, 0.4f, 2); break;
    case 32: tmc.init(0.05f, 0.4f, 3); break;
    case 16: tmc.init(0.05f, 0.4f, 4); break;
    case 8: tmc.init(0.05f, 0.4f, 5); break;
    case 4: tmc.init(0.05f, 0.4f, 6); break;
    case 2: tmc.init(0.05f, 0.4f, 7); break;
    case 1: tmc.init(0.05f, 0.4f, 8); break;
    default: tmc.init(0.05f, 0.4f, 4); break; //Default to microsteps = 16
  }
}
void Pendulum::updateAngle() {
  angle = float(encoder.getPosition()) * angleRatio;
  angularVelocity = encoderSpd.update(angle);
}
void Pendulum::updatePosition() {
  long currentPosition = tmc.getPosition();
  position = float(currentPosition) * distanceRatio;
  velocity = motorSpd.update(position);
}
void Pendulum::setValue(uint8_t address, float value) {
  switch (address) {
    case 0x00: phase = (static_cast<Phase>(value)); break; //Set phase based on received value
    case 0x01: resetTMC(); break; //Reset TMC5160
    case 0x02: resetEncoder(); break; //Reset encoder position to zero
    case 0x03: setCurrent(value); break; //Set motor current
    case 0x05: xMax = value; break; //Maximum position in meters
    case 0x06: vMax = value; break; //Maximum speed in meters per second
    case 0x07: aMax = value; break; //Maximum acceleration in meters per second squared
    case 0x11: sw[0] = value; break; //position 1 for swing up controller
    case 0x12: sw[1] = value; break; //acceleration 1 for swing up controller
    case 0x13: sw[2] = value; break; //position 2 for swing up controller
    case 0x14: sw[3] = value; break; //acceleration 2 for swing up controller
    case 0x15: sw[4] = value; break; //position 3 for swing up controller
    case 0x16: sw[5] = value; break; //acceleration 3 for swing up controller
    case 0x17: sw[6] = value; break; //threshold for transition from swing up to balance up
    /*
    case 0x10: potEnergy = value; break; //initial potential energy of the pendulum
    case 0x11: kickMagnitude = value; break; //magnitude of initial kick for swing up
    case 0x12: kickAcceleration = value; break; //pulsation of kick for swing up
    case 0x13: ea = value; break; //coefficient energy angle
    case 0x14: ex = value; break; //coefficient energy position
    case 0x15: exd = value; break; //coefficient energy velocity
    case 0x16: threshold = value; break; //threshold from kick to swing up
    */
    
    case 0x20: kpa = value; break; //coefficient proportional gain for encoder
    case 0x21: kda = value; break; //coefficient derivative gain for encoder
    case 0x22: kpm = value; break; //coefficient proportional gain for motor
    case 0x23: kdm = value; break; //coefficient coefficient derivative gain for motor
    case 0x30: m = value*1.2; break; //mass of the pendulum
    case 0x31: l = value; break; //length of the pendulum
    case 0x32: loopingPulse = value; break; //magnitude of position pulse for looping
    case 0x33: balanceDownPulse = value; break; //magnitude of position pulse for balance down
    case 0x34: balanceDownThreshold = value; break; //threshold for angle in radians to transition from balance up to down
    case 0x35: origin = value; break; //origin position for the pendulum
  }
}
void Pendulum::action() {
  if (phase != lastPhase) {
    phaseCounter = 0; //Reset phase counter on phase change
    lastPhase = phase;
    lastPhaseChangeTime = millis();
    lastPosition = position; //Reset last position
  }
  switch (phase) {
    case STANDBY: standby(); break;
    case KICK: kick(); break;
    case SWINGUP: swingUp(); break;
    case BALANCEUP: balanceUp(); break;
    case BALANCEDOWN: balanceDown(); break;
    case LOOPINGCW: looping(CW); break;
    case LOOPINGCCW: looping(CCW); break;
  }
}
void Pendulum::standby() {
  tmc.setRampMode(0); //Set to position mode
  tmc.setAcceleration(aMax * accelerationRatio); //Set acceleration to maximum
  tmc.setSpeed(vMax * speedRatio); //Set speed to maximum
  tmc.targetPosition(0); //Set target position to zero
}

void Pendulum::kick() { //Apply first oscillating acceleration to swing up the pendulum
  if (millis() - lastPhaseChangeTime > 50 && abs(position - (lastPosition + kickMagnitude)) < 0.005f) {phase = SWINGUP; return;}
  //if (millis() - lastPhaseChangeTime > 100 && sin(angle)<0.0f) {phase = SWINGUP; return;}
  if (cos(angle) < cos(threshold)) { phase = BALANCEUP; return;}
  tmc.setRampMode(0); //Set to position mode
  tmc.setAcceleration(kickAcceleration * accelerationRatio); //Set acceleration for the kick
  tmc.setSpeed(vMax * speedRatio); //Set speed to maximum
  tmc.targetPosition((lastPosition + kickMagnitude)/distanceRatio); //Set target position for the kick
}

/*
void Pendulum::swingUp() {
  if (cos(angle) < -cos(threshold)) { phase = BALANCEUP; return;} //Transition to balance phase when angle exceeds threshold
  float e = getEnergyBalance();
  float signAngle = cos(angle) > 0.0f ? 1.0f : -1.0f; //Sign of the angle for energy shaping
  float signVelocity = angularVelocity < 0.0f ? 1.0f : -1.0f; //Sign of the velocity for energy shaping
  float a = ea * e * signAngle*signVelocity;// * signVelocity - ex * position - exd * velocity;
  setAcceleration(a);
}
*/
void Pendulum::swingUp() {
  if (cos(angle) < cos(sw[6])) { phase = BALANCEUP; return;} //Transition to balance phase when angle exceeds threshold
  //if (phaseCounter == 0 && abs(position - sw[0]) < 0.001f) {phaseCounter = 1; return;} //Transition to next phase of swing up controller when position reaches first threshold
  if (phaseCounter == 1 && abs(position - sw[2]) < 0.001f) {phaseCounter = 2; return;} //Transition to next phase of swing up controller when position reaches second threshold
  if (phaseCounter == 0 && sin(angle) < 0.0f && angularVelocity < 0.0f && position > sw[0]/2) {phaseCounter = 1; return;} //Transition to next phase of swing up controller when position reaches first threshold
  //if (phaseCounter == 1 && angularVelocity > 0.0f) {phaseCounter = 2; return;} //Transition to next phase of swing up controller when position reaches second threshold
  float x;
  float a;
  switch (phaseCounter) {
    case 0: x = sw[0]; a = sw[1]; break;
    case 1: x = sw[2]; a = sw[3]; break;
    case 2: x = sw[4]; a = sw[5]; break;
    default: x = 0; a = 0; break;
  }
  tmc.setRampMode(0); //Set to position mode
  tmc.setAcceleration(a * accelerationRatio); //Set acceleration for the kick
  tmc.setSpeed(vMax * speedRatio); //Set speed to maximum
  tmc.targetPosition(x/distanceRatio); //Set target position for the kick
}

void Pendulum::balanceUp() {
  float a = (kpa * sin(-angle) + kda * angularVelocity + kpm * (position-origin) + kdm * velocity);
  setAcceleration(a);
}
void Pendulum::balanceDown() {
  if (millis() - lastPhaseChangeTime > 6000.0f) { //If the pendulum has been in balance down phase for more than 5 seconds, transition to standby
    phase = STANDBY;
    return;
  }
  if ((millis() - lastPhaseChangeTime < 1000.0f) && (cos(angle) < cos(balanceDownThreshold))) {
    tmc.setRampMode(0); //Set to position mode
    tmc.setAcceleration(aMax * accelerationRatio); //Set acceleration to maximum
    tmc.setSpeed(vMax * speedRatio); //Set speed to maximum
    //tmc.targetPosition((lastPosition - balanceDownPulse)/distanceRatio); //Set target position to zero
  }else{
    float a = ((kpa * sin(-angle) )/(1+(1-cos(angle))*5) - kpm * position - kdm * velocity);
    setAcceleration(a);
  }
  
}

void Pendulum::looping(int direction) {
  tmc.setRampMode(0); //Set to position mode
  tmc.setAcceleration(aMax * accelerationRatio); //Set acceleration to maximum
  tmc.setSpeed(vMax * speedRatio); //Set speed to maximum
  if (millis() - lastPhaseChangeTime < 500) {
    if (direction == CW) {
      tmc.targetPosition((lastPosition - loopingPulse)/distanceRatio);
    } else { //CCW
      tmc.targetPosition((lastPosition + loopingPulse)/distanceRatio);
    }
  }else{
    if ((direction == CW && sin(angle)>0.0f) || (direction == CCW && sin(angle)<0.0f)) {
      tmc.targetPosition((lastPosition)/distanceRatio);
      if (cos(angle) < cos(balanceDownThreshold)) { phase = BALANCEUP; return;}
    }
  }
}

void Pendulum::setAcceleration(float a) {
  if (a > aMax) a = aMax; //Limit acceleration to maximum
  if (a < -aMax) a = -aMax; //Limit acceleration to minimum
  //If the cart is moving and will exceed the maximum position,
  //apply maximum acceleration to opposite direction
  float x = position;
  float v = velocity;
  //float vLimit = vMax * speedRatio;
  if (v>0 && (x + 0.5 * v*v/aMax > xMax)) {a = -aMax;} //{ vLimit = 0;}
  if (v<0 && (x + 0.5 * v*v/(-aMax) < -xMax)) {a = aMax;} //{ vLimit = 0;}
  //tmc.setSpeed(vLimit);
  if (a<0) tmc.setRampMode(CCW); else tmc.setRampMode(CW); //Set direction based on sign of acceleration
  tmc.setAccelerationMax(abs(a * accelerationRatio)); // set acceleration in TMC units
}

float Pendulum::getEnergyBalance() {
  float g = 9.81f; // Gravitational acceleration in m/s^2
  float Ep = -m * l * g * (1.0f + cos(angle));
  float Ek = 0.5f * m * l * l * angularVelocity * angularVelocity; // Kinetic energy of the pendulum
  return Ep + Ek; // Return the energy balance relative to the bottom position
}
void Pendulum::setCurrent(float runCurrent) {
  tmc.setCurrent(0.05f, runCurrent);
}

