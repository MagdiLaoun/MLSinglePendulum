/*
* TMC.h - Library for controlling TMC5160 stepper motor driver via SPI.
* Created by Magdi Laoun, July 2025.
*/
#include <Arduino.h>
#define FULL_CURRENT 0.4
#define STAND_CURRENT 0.05
class TMC {
  private:
  uint8_t en; //TMC5160 Enable
  uint8_t miso; //SPI MISO -> SDO
  uint8_t mosi; //SPI MOSI -> SDI
  uint8_t sck; //SPI Clock
  uint8_t cs;  //Channel select
  uint8_t pendingRead = 0; //Variable to store the instruction of the value that is pending to be read from the TMC5160
  long position; //Variable to store the current position of the motor in TMC units
  static constexpr uint8_t WRITE = 0x80; //Bit to set for write operations
  static constexpr uint8_t GCONF = 0x00; //RW 18 , global configuration flags.    
  static constexpr uint8_t GLOBALSCALER = 0x0B; //Global scaling of Motor current
  static constexpr uint8_t CHOPCONF = 0x6C; //RW 32 Chopper and driver configuration
  static constexpr uint8_t IHOLD_IRUN = 0x10; //W 5+5+4 Setting of current, holding and running
  static constexpr uint8_t TPWMTHRS = 0x13; //W 20 upper velocity of stealthChop voltage PWM mode
  static constexpr uint8_t RAMPMODE = 0x20; //RW 2, 0 = positionning, 1, 2 = velocity, 3 = hold mode
  static constexpr uint8_t XACTUAL = 0x21; //RW 32 actual motor position (signed)
  static constexpr uint8_t VACTUAL = 0x22; //R 24 actual motor velocity from ramp generator
  static constexpr uint8_t VSTART = 0x23; //W 18 motor start velocity (unsigned)
  static constexpr uint8_t A1 = 0x24; //W 16 first acceleration between VStart and V1, unsigned
  static constexpr uint8_t V1 = 0x25; //W 20 first acceleration/deceleratuib phase threshold velocity
  static constexpr uint8_t AMAX = 0x26; //W 16 second acceleration between V1 and Vmax
  static constexpr uint8_t VMAX = 0x27; //W 23 motion ramp target velocity in positionning mode, target velocity in velocity mode.
  static constexpr uint8_t DMAX = 0x28; //W 16 deceleration between vmax and v1
  static constexpr uint8_t D1 = 0x2A; //W 16 deceleration between V1 and VStop
  static constexpr uint8_t VSTOP = 0x2B; //W 18 motor stop velocity (must not be 0)
  static constexpr uint8_t XTARGET = 0x2D; //RW 32 target position
  static constexpr uint8_t TPOWERDOWN = 0x11; //W 8, delay time after stand still of the motor to power down
  static constexpr uint8_t BUFFER_SIZE = 5; //size of buffer for SPI
  void setConfiguration(uint32_t mStep_=0); //Set configuration of TMC5160 based on microstepping mode
  void setChopConf(uint32_t mStep_=5); //Set chopper configuration based on microstepping mode
  void setTPowerDown(); //Set time after which the motor will power down when stopped
  void setGlobalConf(); //Set global configuration of TMC5160
  void setTimePwmThrs(); //Set upper velocity threshold for stealthChop voltage PWM mode
  void transferData(uint8_t instruction, uint32_t value); //Transfer data to TMC5160 via SPI
  void setAcceleration1(uint32_t value); //Set acceleration between VStart and V1
  void setDeceleration1(uint32_t value); //Set deceleration between V1 and VStop
  void setSpeedStop(); //Set speed at which the motor will stop
  
  public:
  static uint8_t statVal; //Variable to store the value of the status register for debugging
  void begin(uint8_t sck_, uint8_t  mosi_, uint8_t  miso_, uint8_t cs_, uint8_t en_); //Initialize TMC5160 with SPI pin definitions
  void setGlobalScaler(uint8_t scaler_); //Set global current scaler for the motor
  void init(float iHold_=0.05, float iRun_=0.6, float mStep_=0); //Initialize TMC5160 with current settings and microstepping mode
  void setCurrent(float iHold_=0.05, float iRun_=0.4); //Set holding and running current for the motor
  void setAccelerationMax(uint32_t value); //Set maximum acceleration for the motor
  void setDecelerationMax(uint32_t value); //Set maximum deceleration for the motor
  void setSpeedMax(uint32_t value); //Set maximum speed for the motor
  void setRampMode(uint32_t mode); //Set ramp mode for the motor (positioning: 0, velocity CCW: 1, velocity CW: 2, hold: 3)
  void targetPosition(int32_t value); //Set target position for the motor in positionning mode
  void actualPosition(int32_t value); //Set actual position of the motor (used for resetting position to zero)
  void setAcceleration(uint32_t value); //Set acceleration for the motor (sets both acceleration between VStart and V1 and acceleration between V1 and Vmax to the same value)
  void setSpeed(uint32_t value); //Set speed for the motor (sets maximum speed to the same value)
  void setSpeed1(uint32_t value); //Set acceleration between VStart and V1 to the same value as maximum speed for smoother start
  long getPosition(); //Get actual position of the motor from TMC5160 via SPI
};

