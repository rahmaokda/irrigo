#include "irrigation_controller.h"

IrrigationController::IrrigationController(int hysteresis, unsigned long maxRunMs,
                                           unsigned long cooldownMs)
    : hysteresis_(hysteresis), maxRunMs_(maxRunMs), cooldownMs_(cooldownMs) {}

bool IrrigationController::update(int moisture, int threshold, bool autoMode,
                                  bool pumpCommand, bool pumpIsOn,
                                  unsigned long pumpOnSinceMs) {
  unsigned long now = millis();
  safetyTripped_ = false;

  if (inCooldown_ && now - cooldownStart_ >= cooldownMs_) inCooldown_ = false;

  // Safety limit applies in every mode.
  if (pumpIsOn && now - pumpOnSinceMs >= maxRunMs_) {
    safetyTripped_ = true;
    inCooldown_ = true;
    cooldownStart_ = now;
    return false;
  }

  if (inCooldown_) return false;
  if (!autoMode) return pumpCommand;

  if (moisture < threshold) return true;
  if (moisture > threshold + hysteresis_) return false;
  return pumpIsOn;  // inside the band: keep current state
}
