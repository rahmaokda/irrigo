#pragma once
#include <Arduino.h>

// Drives the relay that switches the pump.
class Pump {
 public:
  Pump(uint8_t pin, bool activeHigh);
  void begin();
  void set(bool on);
  bool isOn() const { return on_; }
  unsigned long onSinceMs() const { return onSince_; }  // valid while on

 private:
  uint8_t pin_;
  bool activeHigh_;
  bool on_ = false;
  unsigned long onSince_ = 0;
};
