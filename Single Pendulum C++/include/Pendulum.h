#include <MLTMC.h>
#include <MLEncoder.h>
#include <MLSpeed.h>
class Pendulum {
  enum Phase {
        STANDBY = 0,
        KICK = 1,
        SWINGUP = 2,
        BALANCEUP = 3,
        BALANCEDOWN = 4,
        LOOPINGCW = 5,
        LOOPINGCCW = 6
      };
  private:
    float angleRatio = 1.0f; // Conversion factor from encoder steps to radians
    float distanceRatio = 1.0f; // Conversion factor from motor steps to meters
    float accelerationRatio = 1.0f; // Conversion factor from motor steps/s^2 to m/s^2
    float speedRatio = 1.0f; // Conversion factor from motor steps/s to m/s
    float pulleyCircumference = 0.08f; // Circumference of the pulley in meters
    uint32_t motorSteps = 200; // Number of steps per revolution for the motor
    uint16_t motorMicrosteps = 128; // Number of microsteps per step for the motor
    uint32_t encoderResolution = 10000; // Encoder resolution in steps
    float potEnergy = 0.0f; // Potential energy of the pendulum
    float m = 0.0f; // Mass of the pendulum
    float l = 0.0f; // Length of the pendulum
    float kick0 = 0.0f; //magnitude of initial kick for swing up
    float kick1 = 0.0f; //pulsation of kick for swing up
    float kickMagnitude = 0.0f; //Magnitude of kick for swing up
    float kickAcceleration = 0.0f; //Acceleration in m/s^2 of the kick for swing up
    float ea = 0.0f; //coefficient energy angle
    float ex = 0.0f; //coefficient energy position
    float exd = 0.0f; //coefficient energy velocity
    float threshold = 0.0f; // Threshold for angle in radians
    float loopingPulse = 0.0f; // Magnitude of position pulse for looping
    float balanceDownPulse = 0.0f; // Magnitude of position pulse for balance down
    float balanceDownThreshold = 0.0f; // Threshold for angle in radians to transition from balance up to down
    float kpa = 0.0f; // Proportional gain for encoder control
    float kda = 0.0f; // Derivative gain for balance control
    float kpm = 0.0f; // Proportional gain for motor
    float kdm = 0.0f; // Derivative gain for motor
    float xMax = 0.1f; // Maximum position in meters
    float vMax = 0.0f; // Maximum speed in meters per second
    float aMax = 0.0f; // Maximum acceleration in meters per second squared
    float acceleration = 0.0f; // Acceleration in meters per second squared of cart
    float origin = 0.0f; // Origin position for the pendulum in meters
    Speed encoderSpd; // Speed object for calculating angular velocity from encoder position
    Speed motorSpd; // Speed object for calculating velocity from motor position
    TMC tmc; // TMC object for controlling the motor
    Encoder encoder; // Encoder object for reading the encoder position
    Phase lastPhase = STANDBY; // Last phase of the control loop
    uint64_t lastPhaseChangeTime = 0; // Time in milliseconds of the last phase change
    float lastPosition = 0.0f; // Last position of the cart in meters for calculating velocity
    float sw[7] = {0.0f}; //Array to store the 7 parameters for the swing up controller for tuning purposes
    uint8_t phaseCounter = 0; // Counter for the number of swings during swing up phase
    void updateRatios();
    void standby();
    void kick();
    void swingUp();
    void balanceUp();
    void balanceDown();
    void resetEncoder();
    void resetTMC();
    void setAcceleration(float a);
    float getEnergyBalance();
    void looping(int direction);
    void setCurrent(float runCurrent);
  public:
    Phase phase = STANDBY; // Current phase of the control loop
    float angle = 0.0f; // Angle in radians of pendulum
    float angularVelocity = 0.0f; // Angular velocity in radians per second
    float position = 0.0f; // Position in meters of cart
    float velocity = 0.0f; // Velocity in meters per second of cart
    void begin(uint32_t encoderResolution_, uint16_t motorMicrosteps_, uint32_t motorSteps_, float pulleyCircumference_, uint16_t encoderSpeedCount_, uint16_t cartSpeedCount_);
    void updateAngle(); // Update angle and angular velocity of pendulum based on encoder readings
    void updatePosition(); // Update position and velocity of cart based on TMC readings
    void action(); // Perform control action based on current phase
    void setValue(uint8_t address, float value); // Set control parameters based on received serial commands
};