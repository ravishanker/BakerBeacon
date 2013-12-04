//
//  PWCViewController.h
//  BakerBeacon
//
//  Created by Ravi on 2/12/2013.
//  Copyright (c) 2013 PwC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <FacebookSDK/FacebookSDK.h>

@interface PWCViewController : UIViewController <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *offerImage;
@property (strong, nonatomic) FBSession *session;

@end
