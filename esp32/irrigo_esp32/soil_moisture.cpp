#include "soil_moisture.h"
#include "config.h"

SoilMoistureSensor::SoilMoistureSensor(uint8_t pin, int rawDry, int rawWet)
    : pin_(pin), rawDry_(rawDry), rawWet_(rawWet) {}

void SoilMoistureSensor::begin() {
  // 11 dB attenuation -> input range up to ~3.3 V
  analogSetPinAttenuation(pin_, ADC_11db);
}

void SoilMoistureSensor::read() {
  long sum = 0;
  for (int i = 0; i < SOIL_SAMPLES; i++) {
    sum += analogRead(pin_);
    delay(2);
  }
  raw_ = sum / SOIL_SAMPLES;
  // rawDry -> 0 %, rawWet -> 100 % (works whichever of the two is larger)
  long p = map(raw_, rawDry_, rawWet_, 0, 100);
  percent_ = constrain(p, 0, 100);
}
