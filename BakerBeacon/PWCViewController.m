//
//  PWCViewController.m
//  BakerBeacon
//
//  Created by Ravi on 2/12/2013.
//  Copyright (c) 2013 PwC. All rights reserved.
//

#import "PWCViewController.h"


static NSString * const kSpreadsheetURL = @"https://docs.google.com/forms/d/1ctrAHWmIz-j_47LjRdWPnzHE8ELHjE_MW1X984p3csw/formResponse";
static NSString * const kUUID = @"B9407F30-F5F8-466E-AFF9-25556B57FE6D";
static NSString * const kRegionIdentifier = @"au.com.pwc.BakerBeacon";

//Green beacon  Major:40836 Minor:18108
//Purple beacon Major:29836 Minor:57466
//Blue beacon Major:394 Minor:58605

@interface PWCViewController ()

@property (nonatomic, strong) CLLocationManager * locationManager;
@property (nonatomic, strong) CLBeaconRegion *region;
@property (nonatomic, strong) CLBeacon *closestBeacon;
@property (nonatomic, strong) CLBeacon *currentBeacon;

@property BOOL isFBdataFetched;

@property (nonatomic, strong) NSMutableDictionary *userData;


@end

@implementation PWCViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self authFacebook];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    NSUUID *estimoteUUID = [[NSUUID alloc] initWithUUIDString:kUUID];
    self.region = [[CLBeaconRegion alloc] initWithProximityUUID:estimoteUUID
                                                     identifier:kRegionIdentifier];
    
    // launch app when display is turned on and inside region
    self.region.notifyEntryStateOnDisplay = YES;
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        [_locationManager startMonitoringForRegion:self.region];
        
        // get status update right away for UI
        [_locationManager requestStateForRegion:self.region];
        
        // Start ranging for beacons
        [_locationManager startRangingBeaconsInRegion:self.region];
        
    } else {
        NSLog(@"This device does not support monitoring beacon regions");
    }

}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postDataToSpreadsheetViaForm)
                                                 name:@"FBDataFetched"
                                               object:nil];
    
    self.offerImage.image = [UIImage imageNamed:@"iconBeacon"];
    self.userData = [[NSMutableDictionary alloc] init];
    
    

}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {

    NSString * relativeDistance;
    
    if (beacons.count > 0) {
        NSLog(@"Found beacons! %@", beacons);
        
        // TODO: Sort beacons by by distance
        _closestBeacon = [beacons objectAtIndex:0];
        
        relativeDistance = [self proxmityString:_closestBeacon.proximity];
        
        NSLog(@"%@, %@ • %@ • %.2fm • %li",
              _closestBeacon.major.stringValue,
              _closestBeacon.minor.stringValue, relativeDistance,
              _closestBeacon.accuracy,
              (long)_closestBeacon.rssi);
    
    
        [self setProductOffer:_closestBeacon.minor];
        
        if ([_currentBeacon.minor isEqualToNumber:_closestBeacon.minor]) {
            NSLog(@"Current Beacon %@", _currentBeacon);
//            if (_currentBeacon.proximity == CLProximityImmediate || _currentBeacon.proximity == CLProximityNear) {
//                [self setProductOffer:_currentBeacon.minor];
//
//            }

        
        } else {
            // Moving to another beacon within the region
            NSLog(@"Current Beacon %@", _currentBeacon);

            if (_isFBdataFetched) {
                [self postDataToSpreadsheetViaForm];
            }
            
            _currentBeacon = _closestBeacon;
        }
        
    } else {
        NSLog(@"No beacons found!");

    }
    
    
}

                                     
- (void)setProductOffer:(NSNumber *)minor
{
    if ([minor isEqualToNumber:@58605]) {
        self.offerImage.image = [UIImage imageNamed:@"blue_promotion"];
        
    } else if ([minor isEqualToNumber:@18108]) {
        self.offerImage.image = [UIImage imageNamed:@"green_promotion"];
        
    } else if ([minor isEqualToNumber:@57466]) {
        self.offerImage.image = [UIImage imageNamed:@"purple_promotion"];
        
    } else {
        self.offerImage.image = [UIImage imageNamed:@"purpleNotificationBig"];
    }
        
}
// relative distance string value to beacon
- (NSString *)proxmityString:(CLProximity)proximity
{
    NSString *proximityString;
    
    switch (proximity) {
        case CLProximityNear:
            proximityString = @"Near";
            break;
        case CLProximityImmediate:
            proximityString = @"Immediate";
            break;
        case CLProximityFar:
            proximityString = @"Far";
            break;
        case CLProximityUnknown:
        default:
            proximityString = @"Unknown";
            break;
    }
    
    return proximityString;
}


- (void)locationManager:(CLLocationManager *)manager
	  didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{

    NSLog(@"Beacon %@ UUID %@ major %@minor %@ identifier", self.region.proximityUUID, self.region.major, self.region.minor, self.region.identifier );
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        
        // don't send any notifications if app is open
        return;
    }
    
    // A user can transition in or out of a region while the application is not running.
    // When this happens CoreLocation will launch the application momentarily, call this delegate method
    // and we will let the user know via a local notification.
    UILocalNotification *notification = [[UILocalNotification alloc] init];

    if(state == CLRegionStateInside) {
        NSLog(@"Inside Region %@", self.region.identifier);

        notification.alertBody = @"You're inside the region";
//        notification.userInfo = @{@"beacon_minor": _closestBeacon.minor};


    } else if(state == CLRegionStateOutside) {
        NSLog(@"Outside Region %@", self.region.identifier);

        notification.alertBody = @"You're outside the region";

    } else {
        return;
    }

    // If the application is in the foreground, it will get a callback to application:didReceiveLocalNotification:.
    // If its not, iOS will display the notification to the user.
//    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];


}


////////////////////////////////////////////////////////////////////////////////
#pragma mark FacebookSDK

- (void)authFacebook
{
    // Login or get user data from Facebook
    NSArray *permissions = @[@"basic_info", @"email"];
    if (self.session.isOpen) {
        //        NSLog(@"%@ accessToken", fbTokenData);
        //        [self fetchFBUserData];
        
    } else {
        //Login with Facebook native login diaglog
        [FBSession openActiveSessionWithReadPermissions:permissions
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                          
                                          if (!error) {
                                              NSLog(@"== Login Success %@ session, %d status", session, status);
                                              self.session = session;
                                              [self fetchFBUserData];
                                              
                                          } else {
                                              NSLog(@"%@ error!", error);
                                          }
                                          
                                          
                                      }];
        
    }
}

- (void)fetchFBUserData
{
    //    [FBSettings setLoggingBehavior:[NSSet setWithObjects:
    //                                    FBLoggingBehaviorFBRequests, nil]];
    
    // Fetch user data
    [FBRequestConnection
     startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                       id<FBGraphUser> user,
                                       NSError *error) {
         if (!error) {
             NSString *userInfo = @"";
             
             self.userData[@"fb_id"] = user.id;
             // Example: typed access (name)
             // - no special permissions required
             userInfo = [userInfo
                         stringByAppendingString:
                         [NSString stringWithFormat:@"Name: %@\n\n",
                          user.name]];
             self.userData[@"name"] = user.name;
             
             // Example: typed access (name)
             // - no special permissions required
             userInfo = [userInfo
                         stringByAppendingString:
                         [NSString stringWithFormat:@"Gender: %@\n\n",
                          user[@"gender"]]];
             
             self.userData[@"gender"] = user[@"gender"];
             
             // Example: typed access (email)
             // - email permission required
             userInfo = [userInfo
                         stringByAppendingString:
                         [NSString stringWithFormat:@"Email: %@\n\n",
                          user[@"email"]]];
             
             self.userData[@"email"] = user[@"email"];
             
             NSLog(@"=== FB UserInfo === \n%@", userInfo);
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"FBDataFetched" object:nil];
             _isFBdataFetched = YES;
         }
     }];
    

}


#pragma mark - GDataAPI

// spreadsheet cells
# define EST_UUID       @"entry.1641994124"
# define MAJOR          @"entry.857825636"
# define MINOR          @"entry.1767879955"
# define RSSI           @"entry.1246457524"
# define FB_ID          @"entry.678980662"
# define FB_FULL_NAME   @"entry.1448375634"
# define FB_GENDER      @"entry.1424146187"
# define FB_EMAIL       @"entry.2006994834"


- (void)postDataToSpreadsheetViaForm
{
    NSURL *url = [[NSURL alloc] initWithString:kSpreadsheetURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSLog(@"%@ User Data", self.userData);
    NSString *relativeDistance = [self proxmityString:_closestBeacon.proximity];
    //&draftResponse=[]&pageHistory=0&fbzx=4798022380500650763
    NSString *params = [NSString stringWithFormat:@"%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@",
                        EST_UUID, _closestBeacon.proximityUUID.UUIDString, //self.userData[@"uuid"],
                        MAJOR, _closestBeacon.major.stringValue, //self.userData[@"major"],
                        MINOR, _closestBeacon.minor.stringValue, //self.userData[@"minor"],
                        RSSI, relativeDistance, //self.userData[@"rssi"],
                        FB_ID, self.userData[@"fb_id"],
                        FB_FULL_NAME, self.userData[@"name"],
                        FB_GENDER, self.userData[@"gender"],
                        FB_EMAIL, self.userData[@"email"] ];
    
    NSData *paramsData = [params dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:paramsData];
    
    //    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    //    [connection start];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               if (data.length > 0 && connectionError == nil) {
                                   //                                    NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   //                                    NSLog(@"HTML = %@", html);
                                   NSLog(@"== Successfully posted data ==");
                                   
                               } else if (data.length == 0 && connectionError == nil) {
                                   NSLog(@"No data");
                               } else if (connectionError != nil) {
                                   NSLog(@"Connection Error %@", connectionError);
                               }
                               
                           }];
    
}



@end


