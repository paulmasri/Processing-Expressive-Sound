import beads.*;

AudioContext ac;
String mainSoundFile;
SamplePlayer mainSP;
Gain mainGain;
Glide mainGainGlide;

// Persistent variables for calculation
int prevTime; // ms
float prevSensorPosition = -1.0;

// Sensor velocity variables
float svDuration = 25.0; // ms
float svElapsed = 0.0; // ms
float svTarget = 0.0;
float svIncrement = 0.0;
float svValue = 0.0;

// Visual elements
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
  
  int currTime = millis();
  float dt = (float)currTime - prevTime; // seconds
  float sensorVelocity = svValue;
  if (prevSensorPosition != -1.0 && dt > 0.0)
    sensorVelocity = (sensorPosition - prevSensorPosition) / dt;

  // Update UI
  // Draw virtual sensor
  fill(0, 127, 255);
  rect((width - padWidth) / 2, height - padHeight, padWidth, padHeight);
  fill(0, 40, 192);

  // Output text values
  text("Sensor position:" , 10, 20);
  text(sensorPosition, 200, 20);
  text("Rain gain target:" , 10, 40);
  text(logGainTarget, 200, 40);
  text("Rain gain:" , 10, 60);
  text(mainGainGlide.getValue(), 200, 60);
  text("Sensor velocity:" , 310, 40);
  text(sensorVelocity * 1000.0, 400, 40);
  text("Smooth velocity:" , 310, 60);
  text(svValue * 1000.0, 400, 60);
  
  // Update Glides
  mainGainGlide.setValue(logGainTarget);
  svSetTarget(sensorVelocity);

  // Update persistent variables
  prevTime = currTime;
  prevSensorPosition = sensorPosition;
  svIterate(dt);
}

void svSetTarget(float target) {
  svTarget = target;
  svElapsed = 0.0;
  svIncrement = (target - svValue) / svDuration;
}

void svIterate(float dt) {
  if (dt <= 0.0)
    return;

  if (svElapsed + dt >= svDuration)
    svValue = svTarget;
  else
    svValue = svIncrement * dt;

  svElapsed += dt;
}
