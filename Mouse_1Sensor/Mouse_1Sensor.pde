import processing.sound.*;

SoundFile sample;
Env env;

int currTime, prevTime; // milliseconds
int padWidth = 80;
int padHeight = 10;

void setup() {
  size(600, 400);
  background(255);
  noStroke();
  
  sample = new SoundFile(this, "Rain-loop.mp3");
  sample.loop();
  sample.amp(0.5);
  
  //env = new Env(this);
  
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
    env = new Env(this);
    env.play(sample, 1, 5, 0.2, 1);
    prevTime = currTime + 10000;
  }
}
