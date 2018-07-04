import beads.*;

AudioContext ac;
WavePlayer wp;

int currTime, prevTime; // milliseconds
int padWidth = 80;
int padHeight = 10;

void setup() {
  size(600, 400);
  background(255);
  noStroke();
  
  ac = new AudioContext();
  
  // Temporarily use a sinewave
  wp = new WavePlayer(ac, 440, Buffer.SINE);
  
  ac.out.addInput(wp);
  ac.start();
  
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
