import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
int arduinoSensorPin = 2;
int minArduinoSensorValue = 30;
int maxArduinoSensorValue = 1000;

import beads.*;

AudioContext ac;
String mainSoundFile;
SamplePlayer mainSP;
Gain mainGain;
Glide mainGainGlide;
String spotSoundFile;
SamplePlayer spotSP;
Gain spotGain;

// Persistent variables for calculation
int state = 0;
int prevTime; // ms
int countdownDuration = 3000;
int calibrationDuration = 5000;
int[] calibrationData;
int calibrationIndex = 0;
float prevSensorPosition = -1.0;
int spDuration = 200;
int blockSpotRetriggerInterval = 1000;
int prevSpotTrigger;

// Sensor velocity variables
float svDuration = 100.0; // ms
float svElapsed = 0.0; // ms
float svTarget = 0.0;
float svIncrement = 0.0;
float svValue = 0.0;
float svThreshold = -0.002;

// Visual elements
int padWidth = 80;
int padHeight = 10;
float dotRadiusNew = 20;
float dotRadiusOld = 3;
int nHistoryBuffer = 100;
float[] spHistory; //NB: these are reverse buffers: add latest value at [0] and shift right
float[] spSmoothHistory;
float[] svHistory;
float[] svSmoothHistory;

void setup() {
  size(600, 400);
  background(255);
  noStroke();

  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[2], 57600);
  calibrationData = new int[3000];

  spHistory = new float[nHistoryBuffer];
  spSmoothHistory = new float[nHistoryBuffer];
  svHistory = new float[nHistoryBuffer];
  svSmoothHistory = new float[nHistoryBuffer];

  mainSoundFile = sketchPath("") + "data/Rain-loop.wav";
  spotSoundFile = sketchPath("") + "data/Thunder1.wav";

  ac = new AudioContext();

  // Main sound
  try {
    mainSP = new SamplePlayer(ac, SampleManager.sample(mainSoundFile));
  }
  catch(Exception e) {
    println("Failed to find main sound file: \"" + mainSoundFile + "\"");
    e.printStackTrace();
    exit();
  }
  mainSP.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  mainGainGlide = new Glide(ac, 0.0, spDuration);
  mainGain = new Gain(ac, 1, mainGainGlide); // 1x i/o
  mainGain.addInput(mainSP);
  ac.out.addInput(mainGain);

  // Spot sound
  try {
    spotSP = new SamplePlayer(ac, SampleManager.sample(spotSoundFile));
  }
  catch(Exception e) {
    println("Failed to find spot sound file: \"" + spotSoundFile + "\"");
    e.printStackTrace();
    exit();
  }
  spotSP.setKillOnEnd(false);
  spotGain = new Gain(ac, 1, 0.0);
  spotGain.addInput(spotSP);
  ac.out.addInput(spotGain);

  ac.start();
  mainSP.start();

  prevTime = millis();
  prevSpotTrigger = prevTime;
}

void draw() {
  background(255);
  fill(192, 192, 255);
  text("State: " + state, 10, height - 10);
  
  int nextState = state;
  switch (state) {
    case 0: nextState = stateInit(); break;
    case 1: nextState = stateCountdown(state, "Remove your hand. Calibrating minimum in..."); break;
    case 2: nextState = stateCalibrateMin(); break;
    case 3: nextState = stateCountdown(state, "Press hard on the sensor. Calibrating maximum in..."); break;
    case 4: nextState = stateCalibrateMax(); break;
    case 5: nextState = stateCountdown(state, "Remove your hand. Ready to start playing in..."); break;
    case 6: stateRun(); break;
  }
  state = nextState;    
}

int stateInit() {
  fill(0, 40, 192);
  text("Ready. Press any key to start" , 10, 20);
  return state;
}

int stateCountdown(int state, String message) {
  fill(0, 40, 192);
  text(message, 10, 20);
  
  int currTime = millis();
  if (currTime - prevTime >= countdownDuration) {
    prevTime = currTime;
    return state + 1;
  }
  else {
    int remaining = floor((countdownDuration - (currTime - prevTime)) / 1000.0) + 1;
    fill(255, 0, 0);
    text (remaining, width / 2, height / 2);
  }
  return state;
}

int stateCalibrateMin() {
  fill(0, 40, 192);
  text("Calibrating..." , 10, 20);

  int sensorRaw = arduino.analogRead(arduinoSensorPin);
  println(sensorRaw);
  calibrationData[calibrationIndex++] = sensorRaw;

  int currTime = millis();
  if (currTime - prevTime >= calibrationDuration) {
    float sum = 0;
    for (int i = 0; i < calibrationIndex; ++i)
      sum += calibrationData[i];
    minArduinoSensorValue = round(sum / calibrationIndex);
    calibrationIndex = 0;
    prevTime = currTime;
    return state + 1;
  }
  else {
    int remaining = floor((calibrationDuration - (currTime - prevTime)) / 1000.0) + 1;
    fill(0, 255, 0);
    text (remaining, width / 2, height / 2);
  }
  return state;
}

int stateCalibrateMax() {
  fill(0, 40, 192);
  text("Calibrating..." , 10, 20);

  int sensorRaw = arduino.analogRead(arduinoSensorPin);
  println(sensorRaw);
  calibrationData[calibrationIndex++] = sensorRaw;
  
  int currTime = millis();
  if (currTime - prevTime >= calibrationDuration) {
    float sum = 0;
    for (int i = 0; i < calibrationIndex; ++i)
      sum += calibrationData[i];
    maxArduinoSensorValue = round(sum / calibrationIndex);
    calibrationIndex = 0;
    prevTime = currTime;
    return state + 1;
  }
  else {
    int remaining = floor((calibrationDuration - (currTime - prevTime)) / 1000.0) + 1;
    fill(0, 255, 0);
    text (remaining, width / 2, height / 2);
  }
  return state;
}

int stateRun() {
  int sensorRaw = arduino.analogRead(arduinoSensorPin);
  println(sensorRaw);
  sensorRaw = max(min(sensorRaw, maxArduinoSensorValue), minArduinoSensorValue);
  float sensorPosition = map(sensorRaw, minArduinoSensorValue, maxArduinoSensorValue, 0.0, 1.0);
  float logGainTarget = sensorPosition;
  //float logGainTarget = (log(980 * sensorPosition) + 20) / 1000;

  int currTime = millis();
  float dt = (float)currTime - prevTime; // seconds
  float sensorVelocity = svValue;
  if (prevSensorPosition != -1.0 && dt > 0.0)
    sensorVelocity = (mainGainGlide.getValue() - prevSensorPosition) / dt;

  // Update UI
  // Draw virtual sensor
  fill(0, 127, 255);
  rect((width - padWidth) / 2, height - padHeight, padWidth, padHeight);

  // Draw visual buffers
  for (int i = 0; i < nHistoryBuffer; ++i) {
    stroke(224, 224, 224);
    line(0, height / 2, width / 2, height / 2);
    stroke(255, 192, 192);
    line(0, map(svThreshold, 0.01, -0.01, 0, height), width / 2, map(svThreshold, 0.01, -0.01, 0, height));
    noStroke();

    float x = map(i, nHistoryBuffer, 0, 0.0, width / 2.0);
    float dotSize = (i == 0)? dotRadiusNew: dotRadiusOld;
    fill(224, 255, 224);
    ellipse(x, map(spHistory[i], 0.0, 1.0, 0, height), dotSize, dotSize);
    fill(0, 224, 0);
    ellipse(x, map(spSmoothHistory[i], 0.0, 1.0, 0, height), dotSize, dotSize);
    fill(255, 192, 255);
    ellipse(x, map(svHistory[i], 0.01, -0.01, 0, height), dotSize, dotSize);
    if (svSmoothHistory[i] < svThreshold) {
      fill(224, 0, 0);
      dotSize *= 1.5;
    }
    else
      fill(224, 0, 224);
    ellipse(x, map(svSmoothHistory[i], 0.01, -0.01, 0, height), dotSize, dotSize);
  }

  // Output text values
  fill(192, 192, 255);
  text("Min: " + minArduinoSensorValue + ", Max: " + maxArduinoSensorValue, 10, height - 30);
  fill(0, 40, 192);
  text("Sensor position:" , 10, 20);
  text(sensorPosition, 200, 20);
  text("Rain gain target:" , 10, 40);
  text(logGainTarget, 200, 40);
  text("Rain gain:" , 10, 60);
  text(mainGainGlide.getValue(), 200, 60);
  text("Sensor velocity:" , 310, 40);
  text(map(sensorVelocity, 0.01, -0.01, -10, 10), 500, 40);
  text("Smooth velocity:" , 310, 60);
  text(map(svValue, 0.01, -0.01, -10, 10), 500, 60);

  // Update visual buffers
  shiftBuffer(spHistory, nHistoryBuffer);
  spHistory[0] = logGainTarget;
  shiftBuffer(spSmoothHistory, nHistoryBuffer);
  spSmoothHistory[0] = mainGainGlide.getValue();
  shiftBuffer(svHistory, nHistoryBuffer);
  svHistory[0] = sensorVelocity;
  shiftBuffer(svSmoothHistory, nHistoryBuffer);
  svSmoothHistory[0] = svValue;

  // Output spot sound if over threshold
  if (svValue < svThreshold && currTime > prevSpotTrigger + blockSpotRetriggerInterval) {
    println("Thunder!");
    spotGain.setGain(1.0);
    spotSP.reTrigger();
    prevSpotTrigger = currTime;
  }

  // Update Glides
  mainGainGlide.setValue(logGainTarget);
  svSetTarget(sensorVelocity);

  // Update persistent variables
  prevTime = currTime;
  prevSensorPosition = sensorPosition;
  svIterate(dt);
  
  return state;
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

void shiftBuffer(float[] buffer, int n) {
  for (int i = n - 1; i > 0; --i)
    buffer[i] = buffer[i - 1];
}

void keyPressed() {
  if (state == 0) {
    prevTime = millis();
    state++;
  }
}
