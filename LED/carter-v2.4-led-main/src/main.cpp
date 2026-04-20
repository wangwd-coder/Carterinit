
#include <Adafruit_NeoPixel.h>

#define FRONT_RIGHT_J9 4
#define BACK_RIGHT_J11 0
#define FRONT_LEFT_J10 1
#define BACK_LEFT_J12  2

#define NUM_STRIPS     4

// Number of LEDs per panel
#define LED_COUNT 14

#define HUE_NV_GREEN 14878

// Declare our NeoPixel strip object:
Adafruit_NeoPixel front_right_led(LED_COUNT, FRONT_RIGHT_J9, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel front_left_led(LED_COUNT, FRONT_LEFT_J10, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel back_right_led(LED_COUNT, BACK_RIGHT_J11, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel back_left_led(LED_COUNT, BACK_LEFT_J12, NEO_GRB + NEO_KHZ800);

Adafruit_NeoPixel leds[] = {front_left_led, front_right_led, back_right_led, back_left_led};
uint8_t led_green = 0;

static void fadeAll(uint32_t hue, uint8_t sat, uint32_t del) {  
  for(uint8_t i=0; i<255; i++) {
    uint32_t c = front_right_led.gamma32(front_right_led.ColorHSV(hue, sat, i));
    for(int s=0; s<NUM_STRIPS; s++) {
      leds[s].fill(c, 0, 0);
      leds[s].show();
    }
    delay(del);
  }

  for(uint8_t i=255; i>0; i--) {
    uint32_t c = front_right_led.gamma32(front_right_led.ColorHSV(hue, sat, i));
    for(int s=0; s<NUM_STRIPS; s++) {
      leds[s].fill(c, 0, 0);
      leds[s].show();
    }
    delay(del);
  }
}

void setup() {
  Serial.begin(115200);

  for(int i=0; i<NUM_STRIPS; i++) {
    leds[i].begin();
    leds[i].clear();
    leds[i].setBrightness(128);
    leds[i].show();
  }

  for(int j=0; j<2; j++) {
    for(int i=0; i<NUM_STRIPS; i++) {
      leds[i].fill(front_right_led.Color(0xFF, 0xFF, 0xFF), 0, 0);
      leds[i].show();
      delay(500);
      leds[i].clear();
      leds[i].show();
    }
  }
}

void loop() {
  if(!led_green) {
    fadeAll(HUE_NV_GREEN, 0, 2);
  }

  if(Serial.available()) {
    if(Serial.read() == '0') {
      led_green = 0;
    } else {
      led_green = 1;
      uint32_t c = front_right_led.gamma32(front_right_led.ColorHSV(HUE_NV_GREEN, 255U, 255));
      for(int s=0; s<NUM_STRIPS; s++) {
        leds[s].fill(c, 0, 0);
        leds[s].show();
      }
    }
  }
}