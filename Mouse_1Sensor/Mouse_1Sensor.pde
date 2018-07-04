import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioPlayer mainSound;
Line mainSoundGainRamp;

int currTime, prevTime; // milliseconds
int padWidth = 80;
int padHeight = 10;

void setup() {
  size(600, 400);
  background(255);
  noStroke();
  
  minim = new Minim(this);
  mainSound = minim.loadFile("Rain-loop.mp3");
  mainSound.loop();

  prevTime = millis();
}

void draw() {
  background(255);
  
  // Draw virtual sensor
  fill(0, 127, 255);
  rect((width - padWidth) / 2, height - padHeight, padWidth, padHeight);
  
  // Apply envelope
  currTime = millis();
  if (currTime - prevTime > 2000) {
    prevTime = currTime + 10000;
  }
}
