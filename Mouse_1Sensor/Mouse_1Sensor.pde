import beads.*;

AudioContext ac;
String mainSoundFile;
SamplePlayer mainSP;
Gain mainGain;
Glide mainGainGlide;

int currTime, prevTime; // milliseconds
int padWidth = 80;
int padHeight = 10;

void setup() {
  size(600, 400);
  background(255);
  noStroke();
  
  mainSoundFile = sketchPath("") + "data/Rain-loop.mp3";
  
  ac = new AudioContext();
  
  try {
    mainSP = new SamplePlayer(ac, new Sample(mainSoundFile));
  }
  catch(Exception e) {
    println("Failed to find main sound file: \"" + mainSoundFile + "\"");
    e.printStackTrace();
    exit();
  }
  
  mainGainGlide = new Glide(ac, 0.0, 100); // from 0, over 100ms
  mainGain = new Gain(ac, 1, mainGainGlide); // 1x i/o
  mainGain.addInput(mainSP);
  
  mainSP.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  mainSP.start();
  
  ac.out.addInput(mainGain);
  ac.start();
  
  prevTime = millis();
}

void draw() {
  background(255);
  
  // Draw virtual sensor
  fill(0, 127, 255);
  rect((width - padWidth) / 2, height - padHeight, padWidth, padHeight);
  text(mainGainGlide.getValue(), 10, 10);
  
  // Glide follows mouse vertical value
  mainGainGlide.setValue(mouseY / (float)height);
}
