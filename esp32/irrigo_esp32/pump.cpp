#include "pump.h"

Pump::Pump(uint8_t pin, bool activeHigh) : pin_(pin), activeHigh_(activeHigh) {}

void Pump::begin() {
  pinMode(pin_, OUTPUT);
  on_ = true;  // force set() to write the pin
  set(false);
}

void Pump::set(bool on) {
  if (on == on_) return;
  on_ = on;
  if (on) onSince_ = millis();
  digitalWrite(pin_, (on == activeHigh_) ? HIGH : LOW);
}
