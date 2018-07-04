import beads.*;

AudioContext ac;
WavePlayer wp;
Gain g;
Glide gGlide;

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
  
  gGlide = new Glide(ac, 0.0, 2000); // from 0, over 2000ms
  g = new Gain(ac, 1, gGlide); // 1x i/o
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
  text(gGlide.getValue(), 10, 10);
  
  // Apply envelope
  currTime = millis();
  if (currTime - prevTime > 3000) {
    gGlide.setValue(1.0);
    prevTime = currTime + 10000;
  }
}
