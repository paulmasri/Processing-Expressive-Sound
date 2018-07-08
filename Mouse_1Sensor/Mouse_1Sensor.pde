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
  
  mainSoundFile = sketchPath("") + "data/Rain-loop.wav";
  
  ac = new AudioContext();
  
  try {
    mainSP = new SamplePlayer(ac, SampleManager.sample(mainSoundFile));
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
  
  float sensorPosition = map(mouseY, 0, height, 0.0, 1.0);
  float logGainTarget = sensorPosition;
  //float logGainTarget = (log(980 * sensorPosition) + 20) / 1000;
  
  // Draw virtual sensor
  fill(0, 127, 255);
  rect((width - padWidth) / 2, height - padHeight, padWidth, padHeight);
  fill(0, 40, 192);
  text("Sensor position:" , 10, 20);
  text(sensorPosition, 200, 20);
  text("Rain gain target:" , 10, 40);
  text(logGainTarget, 200, 40);
  text("Rain gain:" , 10, 60);
  text(mainGainGlide.getValue(), 200, 60);
  
  // Glide follows mouse vertical value
  mainGainGlide.setValue(logGainTarget);
}
