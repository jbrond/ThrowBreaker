//
//  ViewController.h
//  ThrowMe Breaker
//
//  Created by Jan Christian Brønd on 8/15/12.
//  Copyright (c) 2012 Jan Christian Brønd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "cubeAccelerationEngine.h"
#import "cubeGyroEngine.h"
@class FliteTTS;

@interface ViewController : UIViewController {
    
    //The speech engine
    FliteTTS *fliteEngine;
    
    CMMotionManager *mm;
    //Boolean shake;
    double accel[3];
    double buffer[5];
    
    struct timeval gameStart;
    cubeAccelerationEngine * cubeAccelEngine;
    cubeGyroEngine * cubeGyroTiltEngine;
    
    BOOL onSetDetection;
    Boolean edgeDetected;
    long previousOffsetTime;
    int shakes;
    accelerationState accelState;
    int waitTime;
    
    __weak IBOutlet UILabel *labelGameTime;
    
    UIDeviceOrientation previousOrientation;
    UIDeviceOrientation currentOrientation;
    //int shakesTotal;
    //int shakeTime;
    
    //int hitWait;
    //long lastHit;
    
    NSTimer *updateTimer;
    int gameTime;
    int lastGameTime;
    int positionGameTime[7];
    Boolean positionGameCheck[7];
    int currentPosition;
    Boolean hit;
    Boolean countdownFinished;
    Boolean gameRunning;
}

- (IBAction)bnStartGame:(id)sender;
-(void) countdownSpeak;
@end
