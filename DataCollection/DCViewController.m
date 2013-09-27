//
//  DCViewController.m
//  DataCollection
//
//  Created by CleverMiles on 03/09/2013.
//  Copyright (c) 2013 CleverMiles. All rights reserved.
//

#import "DCViewController.h"
#import <CoreMotion/CoreMotion.h>

@interface DCViewController ()

@end
NSMutableString *dataString;

/////////////////////claibration variables

//... used for calibration calculations
double avgX = 0;
double avgY = 0;
double avgZ = 0;
int counter = 0;

//... contained calibrated calculation values
double offsetX = 0;
double offsetY = 0;
double offsetZ = 0;

//... local vars to monitor status of process
bool isCalibrated;
bool isCalibratedStarted;

/// <summary>
/// Defines the amount of milliG of variance that accelerometer can have during the calibration-countdown when calibrating the phone.
/// </summary>
double stabilityAllowance = 0.5;

/// <summary>
/// Sets the amount of time in seconds the phone must be completely stable (i.e. within the movement constraints as defined by "stabilityAllowance"
/// </summary>
double stabilitySecondsRequirement = 15;

/// <summary>
/// Max amount of time the phone will auto-retry the calibration process before exiting.
/// </summary>
double stabilityRetryMax = 4;

/// <summary>
/// Current amount of times the phone has retried the calibration process.
/// </summary>
double stabilityRetryCount = 0;

/// <summary>
/// Used to monitor the duration of the calibration-countdown
/// </summary>
NSDate *start;

////////////////////////end calibration vars


@implementation DCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    dataString = [[NSMutableString alloc] init];
    _motionManager = [[CMMotionManager alloc] init];
    
    if ([NSDate date] < [[NSDate date] dateByAddingTimeInterval:stabilitySecondsRequirement]) {
        NSLog(@"less than");
    }

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStart:(id)sender {
    
    _lblCalib.text = @"Calibrating";
    isCalibratedStarted = true;
    start = [NSDate date];
    [self startAccelerometer];
    
    
    

}

- (IBAction)btnStop:(id)sender {
    [_motionManager stopAccelerometerUpdates];
    NSLog(@"%@", dataString);
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *filePath = [NSString stringWithFormat:@"%@/tripData.csv", documentsDirectory];
    NSLog(@"filePath %@", filePath);
    NSError *error;
    BOOL Success = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    if (Success) {
        NSLog(@"file created");
        [dataString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }

    
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        [mailViewController setToRecipients:[NSArray arrayWithObject:[NSString stringWithFormat:@"davinkelly@gmail.com"]]];
        [mailViewController setSubject:@"Trip Data"];
        [mailViewController setMessageBody:[NSString stringWithFormat:@"This is the data from %@", [NSDate date]] isHTML:NO];
        [mailViewController addAttachmentData:[NSData dataWithContentsOfFile:filePath] mimeType:@"text/plain" fileName:@"tripData.csv"];
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
    else {
        NSLog(@"Device is unable to send email in its current state.");
    }

}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
    NSLog(@"%@", error);
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
   
}

-(void)startAccelerometer
{
//    _locationManager = [[CLLocationManager alloc]init];
//    [_locationManager startUpdatingLocation];
//    [_locationManager setDelegate:self];
//    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
    _motionManager.accelerometerUpdateInterval = 0.5;
//    [_motionManager startGyroUpdates];
    [_motionManager startDeviceMotionUpdates];
    
    //    __block bool stabilityOK = true;
    
    if ([_motionManager isAccelerometerAvailable])
    {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [_motionManager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
         {
             dispatch_async(dispatch_get_main_queue(), ^
             {
                 bool stabilityOK = true;
                 _lblXValues.text = [NSString stringWithFormat:@"%.3f",accelerometerData.acceleration.x];
                 _lblYValues.text = [NSString stringWithFormat:@"%.3f",accelerometerData.acceleration.y];
                 _lblZValues.text = [NSString stringWithFormat:@"%.3f",accelerometerData.acceleration.z];
                 _lblLat.text = [NSString stringWithFormat:@"%.6f", _locationManager.location.coordinate.latitude];
                 _lblLong.text = [NSString stringWithFormat:@"%.6f", _locationManager.location.coordinate.longitude];
                 
                 [dataString appendString:[NSString stringWithFormat:@"%f,%f,%f,%f,%f\n", accelerometerData.acceleration.x,accelerometerData.acceleration.y, accelerometerData.acceleration.z, _locationManager.location.coordinate.latitude, _locationManager.location.coordinate.longitude]];
                 
                 
                 if (isCalibratedStarted)
                 {
                     NSLog(@"max = %f count = %f", stabilityRetryMax, stabilityRetryCount);
                     if (stabilityRetryMax > stabilityRetryCount)
                     {
                         // if the calibration period hasnt expired
                         NSDate *a = [start dateByAddingTimeInterval:stabilitySecondsRequirement];
                         NSLog(@"start = %@, a = %@", [NSDate date], a);
                         if ([NSDate date] < a)
                         {
                             // if the counter > 0 (avoid divide by zero errors and invalid values)
                             if (counter > 0)
                             {
                                 // check the phone hasnt moved too much during the clibration period so we can get good stable origion points
                                 if (((avgX / counter) + stabilityAllowance > _motionManager.accelerometerData.acceleration.x == false) || ((avgX / counter) - stabilityAllowance < _motionManager.accelerometerData.acceleration.x == false))
                                 {
                                     stabilityOK = FALSE;
                                 }
                                 if (((avgY / counter) + stabilityAllowance > _motionManager.accelerometerData.acceleration.y == false) || ((avgY / counter) - stabilityAllowance < _motionManager.accelerometerData.acceleration.y == false))
                                 {
                                     stabilityOK = false;
                                 }
                                 if (((avgZ / counter) + stabilityAllowance > _motionManager.accelerometerData.acceleration.z == false) || ((avgZ / counter) - stabilityAllowance < _motionManager.accelerometerData.acceleration.z == false))
                                 {
                                     stabilityOK = false;
                                 }
                                 
                                 //... check the phone is still inside the positional limits
                                 
                                 if (![[NSString stringWithFormat:@"%.2f", _motionManager.accelerometerData.acceleration.y] floatValue] < 0) {
                                     stabilityOK = false;
                                 }
                                 
                                 if (![[NSString stringWithFormat:@"%.2f", _motionManager.accelerometerData.acceleration.z] floatValue] < 0) {
                                     stabilityOK = FALSE;
                                 }
                                 
                                 if (![[NSString stringWithFormat:@"%.2f", _motionManager.accelerometerData.acceleration.x] floatValue] < -0.2)
                                 {
                                     stabilityOK = false;
                                 }
                                 
                                 if (![[NSString stringWithFormat:@"%.2f", _motionManager.accelerometerData.acceleration.x] floatValue] < 0.2)
                                 {
                                     stabilityOK = false;
                                 }
                                 
                                 //if the phone is not stable then restart the stability-countdown
                                 if (stabilityOK == false)
                                 {
                                     //.. CALIBRATION FAIL - PHONE UNSTABLE... RETRY
                                     
                                     //researt the timer
                                     start = [[NSDate date] dateByAddingTimeInterval:stabilitySecondsRequirement];
                                     
                                     avgX = 0;
                                     avgY = 0;
                                     avgZ = 0;
                                     
                                     counter = 0;
                                     
                                     stabilityRetryCount++;
                                     _lblCalib.text = @"retrying";
                                     
                                                                    
                                 }
                                 else
                                 {
                                     // if the phone is stable then check are all the axes within acceptable limits (i.e. is the phone in an ok position)
                                    
                                 }
                             }
                             
                             //.. keep adding up the accelerometer valuse so we can average them after the stability-countdown is over. if the phone isnt stable these
                             //.. values will be reset.
                             avgX += _motionManager.accelerometerData.acceleration.x;
                             avgY += _motionManager.accelerometerData.acceleration.y;
                             avgZ += _motionManager.accelerometerData.acceleration.z;
                             
                             counter++;
                         }
                         else
                         {
                             NSLog(@"%@, %@", [NSDate date], [start dateByAddingTimeInterval:stabilitySecondsRequirement]);
                             //.. calibration period ended. if below is true then its worked. currently if
                             if (isCalibrated == false)
                             {
                                 //.. CALIBRATION SUCCESS
                                 
                                 avgX /= counter;
                                 avgY /= counter;
                                 avgZ /= counter;
                                 
                                 offsetX = avgX;
                                 offsetY = avgY;
                                 offsetZ = avgZ;
                                 
                                 counter = -1;
                                 isCalibrated = true;
                                 NSLog(@"calibration success");
                             }
                         }
                     }
                     else
                     {
                         //.. CALIBRATION FAIL
                         
                         //.. auto-retry on calibration has maxed out.
                         //.. clear vals and set retry count to zero.
                         
                         avgX = 0;
                         avgY = 0;
                         avgZ = 0;
                         
                         counter = 0;
                         stabilityRetryCount = 0;
                         _lblCalib.text = @"Calibration failed";
                         isCalibratedStarted = false;

                     }
                 }
            });
         }];
    }
    
    else
        NSLog(@"not active");
}












@end
