#include <CapacitiveSensor.h>
#include <Firmata.h>

CapacitiveSensor cap4_2 = CapacitiveSensor(4,2);

void setup() {
  Firmata.begin(57600);
}

void loop() {
  long sensor2 = cap4_2.capacitiveSensor(30);
  Firmata.sendAnalog(2, sensor2);
  delay(10);
}
