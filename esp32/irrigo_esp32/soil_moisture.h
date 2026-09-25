#pragma once
#include <Arduino.h>

// Reads the capacitive soil sensor and converts the raw ADC value to 0-100 %.
class SoilMoistureSensor {
 public:
  SoilMoistureSensor(uint8_t pin, int rawDry, int rawWet);
  void begin();
  void read();                        // take a new averaged sample
  int raw() const { return raw_; }
  int percent() const { return percent_; }

 private:
  uint8_t pin_;
  int rawDry_, rawWet_;
  int raw_ = 0;
  int percent_ = 0;
};
