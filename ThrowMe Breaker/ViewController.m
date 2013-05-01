//
//  ViewController.m
//  ThrowMe Breaker
//
//  Created by Jan Christian Brønd on 8/15/12.
//  Copyright (c) 2012 Jan Christian Brønd. All rights reserved.
//
//

#import "ViewController.h"
#import "FliteTTS.h"
#import <AudioToolbox/AudioToolbox.h>

// ivar
SystemSoundID mApplause;
SystemSoundID mSwoosh;
SystemSoundID mTada;
SystemSoundID mReloadGun;
SystemSoundID mPunch;
SystemSoundID mPunch2;
SystemSoundID mPain;
SystemSoundID mShake;
SystemSoundID mFryingPan;
SystemSoundID mPop;
SystemSoundID mJab;

SystemSoundID mNumbers[6];
int numberMap[7] = { 0, 4, 1, 0, 5, 2, 3};

#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2
#define ORIENTATION_MSG 3
#define SHAKE_MSG 4
#define HIT_MSG 5
#define THROW_MSG 6
#define BALANCE_MSG 7

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0
#define MAX_GAME_TIME 1200
#define TIME_TO_INSERT_IN_ARTEFACT 200
#define GAME_TIME_RESOLUTION 0.05
#define TIMER_FREQUENCY 20.0

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"Background.png"]];
    
    //Create the sounds that we will use in the game
    
    NSURL *tadaSound   = [[NSBundle mainBundle] URLForResource: @"tada"
                                                 withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)tadaSound, &mTada);
    
    NSURL *swooshSound   = [[NSBundle mainBundle] URLForResource: @"swoosh"
                                                   withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)swooshSound, &mSwoosh);
    
    NSURL *shotgunReloadSound   = [[NSBundle mainBundle] URLForResource: @"shotgunreload"
                                                          withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)shotgunReloadSound, &mReloadGun);
    
    NSURL *applauseSound   = [[NSBundle mainBundle] URLForResource: @"applause"
                                                     withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)applauseSound, &mApplause);
    
    AudioServicesAddSystemSoundCompletion (mApplause,NULL,NULL,
                                           completionApplauseCallback,
                                           (__bridge void*) self);
    
    NSURL *punch   = [[NSBundle mainBundle] URLForResource: @"Punch"
                                             withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)punch, &mPunch);
    
    NSURL *punch2   = [[NSBundle mainBundle] URLForResource: @"punch2"
                                              withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)punch2, &mPunch2);
    
    NSURL *pain   = [[NSBundle mainBundle] URLForResource: @"pain"
                                            withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)pain, &mPain);
    
    NSURL *fryingpan   = [[NSBundle mainBundle] URLForResource: @"fryingpan"
                                                 withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)fryingpan, &mFryingPan);
    
    NSURL *pop   = [[NSBundle mainBundle] URLForResource: @"pop"
                                           withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)pop, &mPop);
    
    NSURL *jab   = [[NSBundle mainBundle] URLForResource: @"Jab"
                                           withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)jab, &mJab);
    
    for (int i = 0; i<6; i++) {
        
        NSString * fname = [[NSString alloc] initWithFormat:@"%dda",(i+1)];
        
        NSURL *number   = [[NSBundle mainBundle] URLForResource: fname
                                                  withExtension: @"aiff"];
        
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)number, &mNumbers[i]);
        
    }
    //AudioServicesAddSystemSoundCompletion (mApplause,NULL,NULL,
    //                                       completionApplauseCallback,
    //                                       (__bridge void*) self);
    
    //AudioServicesPlaySystemSound (mTada);
    
	// Do any additional setup after loading the view, typically from a nib.
    mm = [[CMMotionManager alloc] init];
    
    if (mm.isDeviceMotionAvailable) {
        [mm setGyroUpdateInterval:1.0f/30.0f];
        [mm setDeviceMotionUpdateInterval:1.0f/30.0f];
        [mm startDeviceMotionUpdates];
    }
    
    //alloc the acceleration processing engine and call the default init constructor
    cubeAccelEngine = [[cubeAccelerationEngine alloc] init];
    
    //aloc the class engine
    cubeGyroTiltEngine = [cubeGyroEngine alloc];
    
    //Initializing the acceleration delegate
    UIAccelerometer*  theAccelerometer = [UIAccelerometer sharedAccelerometer];
    theAccelerometer.updateInterval = 1.0f / 30.0f;
    theAccelerometer.delegate = self;
    
    //Starting the device orientation notifications
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
    
    fliteEngine = [[FliteTTS alloc] init];
	[fliteEngine setPitch:125.0 variance:11.0 speed:1.1];
    
}


- (void)viewDidUnload
{
    labelGameTime = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    AudioServicesDisposeSystemSoundID(mTada);
    AudioServicesDisposeSystemSoundID(mSwoosh);
    AudioServicesDisposeSystemSoundID(mReloadGun);
    AudioServicesDisposeSystemSoundID(mApplause);
    AudioServicesDisposeSystemSoundID(mPunch);
    AudioServicesDisposeSystemSoundID(mPunch2);
    AudioServicesDisposeSystemSoundID(mPain);
    AudioServicesDisposeSystemSoundID(mFryingPan);
    AudioServicesDisposeSystemSoundID(mPop);
    AudioServicesDisposeSystemSoundID(mJab);
    //AudioServicesDisposeSystemSoundID(mApplause);
    for (int i=0;i<6;i++) {
        AudioServicesDisposeSystemSoundID(mNumbers[i]);
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(void) orientationNumbers:(int) number
{
    if (number<1 || number >6)
        return;
    
    AudioServicesPlaySystemSound (mNumbers[numberMap[number]]);
    
}

-(void) orientationChangeSound
{
    AudioServicesPlaySystemSound (mSwoosh);
}

-(void) reloadGunSound
{
    AudioServicesPlaySystemSound (mReloadGun);
}

-(void) punchSound
{
    AudioServicesPlaySystemSound (mPunch);
}

-(void) punch2Sound
{
    AudioServicesPlaySystemSound (mPunch2);
}

-(void) painSound
{
    AudioServicesPlaySystemSound (mPain);
}

-(void) popSound
{
    AudioServicesPlaySystemSound (mPop);
}

-(void) fryingpanSound
{
    AudioServicesPlaySystemSound (mFryingPan);
}

-(void) jabSound
{
    AudioServicesPlaySystemSound (mJab);
}

//Register system sound shake
-(void) registerShakeSound
{
    NSURL *shake   = [[NSBundle mainBundle] URLForResource: @"shake"
                                             withExtension: @"aiff"];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)shake, &mShake);
    
    AudioServicesPlaySystemSound (mShake);
}

-(void) unRegisterShakeSound
{
    AudioServicesDisposeSystemSoundID(mShake);
}

- (IBAction)bnStartGame:(id)sender {
    if (gameRunning)
        return;
    //Starting the game and insert into
    //Make sure to reset the
    [self resetGame];
    
    [fliteEngine speakNowText:@"10 seconds to insert me in cube "];
    //timer is 1/20 or 0.05 sec.
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/TIMER_FREQUENCY target:self selector:@selector(updateGameTimer) userInfo:nil repeats:YES];
    
}

-(void) countdownSpeak
{
    [fliteEngine speakNowText:@"3    2    1    Go"];
}

- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    NSString *msg = [NSString stringWithFormat:@"O:%d\r\n",orientation];
    
    //[self sendMessage:msg :ORIENTATION_MSG];
    NSLog(msg);
	
    //The same orientation af before??
    if (gameRunning && positionGameTime[orientation]==0 && previousOrientation != orientation) {
        //new orientation
        previousOrientation = orientation;
        //Make the sound for orientation change
        //NSString *orientationmMsg = [NSString stringWithFormat:@"test %d ",orientation];
        //[fliteEngine speakNowText:orientationmMsg];
        //[self orientationChangeSound];
        [self orientationNumbers:(int)orientation];
    }
    
    //Save the current orientation
    currentOrientation = orientation;
}

//After applause this code will be called
static void completionApplauseCallback (SystemSoundID  mySSID, void* myself) {
	//NSLog(@"completion Callback");
	//AudioServicesRemoveSystemSoundCompletion (mySSID);
	
	//[(SoundEffect*)myself release];
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration

{
    //Process acceleration
    eCubeAction cubeAction = [cubeAccelEngine process:acceleration];
    
    //eCubeAction cubeTiltAction = [cubeGyroTiltEngine process:mm.deviceMotion.attitude];
    
    //process the cube action if noAction nothing happened just yet!
    //if (cubeAction == noAction && cubeTiltAction==noAction)
    //    return;
    
    //
    //if place in the right orientation
    //and no actions from the acceleration
    //if (previousOrientation==2 && cubeTiltAction !=noAction) {
    //    cubeAction = cubeTiltAction;
    //}
    
    //any acceleration action?
    switch (cubeAction) {
        case hitAction: //[self painSound];
            break;
        case shakeAction: //[self unRegisterShakeSound];
            break;
        case throwAction: 
            if (gameRunning) {
                [self reloadGunSound];
                positionGameTime[currentOrientation] = gameTime;
            }
            break;
        case shakeStartAction: //[self registerShakeSound];
            break;
        case shakeEndAction: //[self unRegisterShakeSound];
            break;
        case tiltLeftAction: //[self popSound];
            break;
        case tiltRightAction: //[self fryingpanSound];
            break;
        case tiltShakeAction: //[self jabSound];
            break;
        default:
            break;
    }
    
    //Whats the current orientation
    
}

-(void) resetGame
{
    //rest values for game time
    for (int n = 1; n<7; n++)
        positionGameTime[n] = 0;
    
    lastGameTime = 0;
    
    gameTime = 0;
    
    //Idicating that the games is not started before 10 sec. then 1 2 3 Go ->
    gameRunning = false;

}

-(void) updateGameTimer
{
    //20Hz update meaning 0.05 sec resolution
    gameTime++;
    
    Boolean allDone = true;
    
    //rest values for game time
    for (int n = 1; n<7; n++) {
        if (positionGameTime[n] == 0) {
            allDone = false;
        }
    }
    
    float tid = 0;
    
    if (!gameRunning && gameTime>=TIME_TO_INSERT_IN_ARTEFACT) {
        [self countdownSpeak];
        gameTime = 0;
        gameRunning = true;

        //start the timer
        gettimeofday(&gameStart, NULL);

    }
    
    if (gameRunning) {
        if (gameTime>=MAX_GAME_TIME || allDone) {
            [updateTimer invalidate];
            updateTimer = nil;
            gameTime = 0;
            gameRunning = false;
            
            NSString * gameEndMessage = @"Game over     you are to slow";
            
            if (allDone) {
                
                struct timeval gameEnd;
                
                gettimeofday(&gameEnd, NULL);
                
                long elapsed_mseconds  = (gameEnd.tv_sec*1000+gameEnd.tv_usec/1000)  - (gameStart.tv_sec*1000+gameStart.tv_usec/1000);
                
                long sec = elapsed_mseconds/1000 ;
                long msec = (elapsed_mseconds - sec*1000);
                
                gameEndMessage = [NSString stringWithFormat:@"Sidste tid: %ld.%ld Sekunder",sec,msec];
                
                [labelGameTime setText:gameEndMessage];
                
                gameEndMessage = [NSString stringWithFormat:@"Game over time %ld seconds and %ld milli seconds",sec,msec];
            }
            
            [fliteEngine speakNowText:gameEndMessage];
        }
    }
    
}
/*- (IBAction)bntStartGame:(id)sender {
    
    
}*/

@end
