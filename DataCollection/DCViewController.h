//
//  DCViewController.h
//  DataCollection
//
//  Created by CleverMiles on 03/09/2013.
//  Copyright (c) 2013 CleverMiles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface DCViewController : UIViewController<CLLocationManagerDelegate, MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *lblXValues;
@property (strong, nonatomic) IBOutlet UILabel *lblYValues;
@property (strong, nonatomic) IBOutlet UILabel *lblZValues;
@property (nonatomic, retain) CMMotionManager *motionManager;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UILabel *lblLat;
@property (strong, nonatomic) IBOutlet UILabel *lblLong;


- (IBAction)btnStart:(id)sender;
- (IBAction)btnStop:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *lblCalib;
@property (strong, nonatomic) IBOutlet UILabel *lblOldX;
@property (strong, nonatomic) IBOutlet UILabel *lblOldY;
@property (strong, nonatomic) IBOutlet UILabel *lblOldZ;

@end
