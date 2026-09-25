#pragma once
#include <Arduino.h>

// Decides whether the pump should run. Pure logic: no I/O.
//
// AUTO mode:   ON below threshold, OFF above threshold + hysteresis (spec 7.2).
// MANUAL mode: follows pumpCommand from the app.
// Both modes:  pump is forced OFF after maxRunMs, then stays OFF for cooldownMs.
class IrrigationController {
 public:
  IrrigationController(int hysteresis, unsigned long maxRunMs, unsigned long cooldownMs);

  // Returns the desired pump state.
  bool update(int moisturePercent, int threshold, bool autoMode, bool pumpCommand,
              bool pumpIsOn, unsigned long pumpOnSinceMs);

  // True when the last update() stopped the pump because of the run-time limit.
  bool safetyTripped() const { return safetyTripped_; }

 private:
  int hysteresis_;
  unsigned long maxRunMs_, cooldownMs_;
  bool safetyTripped_ = false;
  bool inCooldown_ = false;
  unsigned long cooldownStart_ = 0;
};
