import beads.*;

AudioContext ac;
WavePlayer wp;
Gain g;

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
  
  g = new Gain(ac, 1, 0.05); // 1x i/o, gain 5%
  g.addInput(wp);
  
  ac.out.addInput(g);
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
