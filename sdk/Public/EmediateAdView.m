//
//  EmediateAdView.m
//  ORMMA
//
//  Created by Raju on 25/7/12.
//  Copyright (c) 2012 The Mobile Life. All rights reserved.
//

#import "EmediateAdView.h"
#import "TMLOpenUDID.h"

#define K_OK          1
#define K_CANCEL      0

@implementation EmediateAdView

@synthesize baseURL;
@synthesize refreshRate;
@synthesize parameters;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        parameters = nil;
        refreshRate = -1;
    }
    return self;
}

- (void)dismissAlerts
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    NSArray *subviews = [window subviews];
    if (subviews > 0)
    {
        UIAlertView *alert = [subviews objectAtIndex:0];
        if ([alert isKindOfClass:[UIAlertView class]])
        {
            [alert dismissWithClickedButtonIndex:[alert cancelButtonIndex] animated:NO];
        }
    }
}

- (void)stopRefresh
{
    if (refreshTimer && [refreshTimer isValid])
    {
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
    }
}

- (void)dealloc
{
    [self dismissAlerts];
    
    if (refreshTimer && [refreshTimer isValid])
    {
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
    }
    
    if (parameters)
    {
        [parameters release];
        parameters = nil;
    }
    
    [super dealloc];
}

- (void)fetchCampaignWithRefreshRate:(NSInteger)refresh
{
    self.refreshRate = refresh;
}

- (void)stop
{
    self.parameters = nil;
    
    if (refreshTimer && [refreshTimer isValid])
    {
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
    }
}

- (void)refreshCreative
{
    [self loadCreativeWithParameters:nil];
}

- (void)loadCreativeWithParameters:(NSDictionary *)params
{
    
    //    [self loadCreativeInternalWithParameters:params];
    
    if([CLLocationManager locationServicesEnabled] &&
       [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied){
        if(self.userLocation){ // done waiting
            //            NSLog(@"done waiting, params = %@",params);
            [self loadCreativeInternalWithParameters:params];
            
        }else{// wait for user location
            //            NSLog(@"waiting");
            [self performSelector:@selector(loadCreativeWithParameters
                                            :) withObject:params afterDelay:0.2f];
            
            if ((params != nil) && (parameters == nil)) //When loading the ad for the 1st time.
            {
                self.parameters = params;
            }
        }
    }else{
        //        NSLog(@"not wait");
        [self loadCreativeInternalWithParameters:params];
        
        
    }
    
}

- (void)loadCreativeInternalWithParameters:(NSDictionary *)params
{
    if ((params != nil) && (parameters == nil)) //When loading the ad for the 1st time.
    {
        self.parameters = params;
    }
    NSLog(@"self.parameters = %@",self.parameters);
    //Format the URL and initiate load the creative
    NSMutableString *completeURLString = nil;
    if (self.parameters != nil)
    {
        NSArray *keys = [self.parameters allKeys];
        
        if ([keys count] != 0)
        {
            completeURLString = [[NSMutableString alloc] initWithString:[baseURL hasSuffix:@"?"] ? baseURL : [baseURL stringByAppendingString:@"?"]];
            for (NSString *key in keys)
            {
                if ([self.parameters valueForKey:key]) // CTO inefficiency...
                {
                    [completeURLString appendFormat:@"%@=%@;", key, [self.parameters valueForKey:key]];
                }
            }
            
            if(self.userLocation){
                // use %lf instead of %f to ensure enough precision
                [completeURLString appendFormat:@"lat=%lf;", self.userLocation.coordinate.latitude];
                [completeURLString appendFormat:@"lng=%lf;", self.userLocation.coordinate.longitude];
            }
        }
    }
    
    if (completeURLString && [completeURLString length])
    {
        // Previously used UDID is no good for our purposes, instead use uid generation algoritm as described on
        // http://classroom.emediate.com/doku.php?id=technical:in_depth_descriptions:cookie-less_requests
        
        NSString *eas_uid = [[NSUserDefaults standardUserDefaults] objectForKey:@"EAS_UID"];
        
        if (!eas_uid) //If EAS_UID is not stored in UserDefaults before, save in UserDefaults and delete UDID if stored there
        {
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"UDID"])
            {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UDID"];
            }
            
            time_t unix_time = time(nil);
            srandom(unix_time);
            long r = (long)arc4random_uniform(999999999); // max nine digits
            
            NSMutableString *eas_uid = [[[NSMutableString alloc] init] autorelease];
            [eas_uid appendFormat:@"%lu", unix_time];
            [eas_uid appendFormat:@"%09lu", r]; // pad to nine digits
            
            [[NSUserDefaults standardUserDefaults] setObject:eas_uid forKey:@"EAS_UID"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        [completeURLString appendFormat:@"%@=%@", @"eas_uid", eas_uid];
        
        NSURL *url = [[NSURL alloc] initWithString:completeURLString];
        [self loadCreative:url];
        [url release];
        url = nil;
    }
    
    if (completeURLString)
    {
        [completeURLString release];
        completeURLString = nil;
    }
}

- (void)fireAdWillShow
{
    if (!refreshTimer)
    {
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshRate target:self selector:@selector(refreshCreative) userInfo:nil repeats:YES];
        [refreshTimer retain];
    }
    
    if([super respondsToSelector:@selector(fireAdWillShowCalledFromChildView)]){
        [super performSelector:@selector(fireAdWillShowCalledFromChildView)];
    }
}

- (void)fireAppShouldSuspend
{
    if (refreshTimer)
    {
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
    }
    if([super respondsToSelector:@selector(fireAppShouldSuspendCalledFromChildView)]){
        [super performSelector:@selector(fireAppShouldSuspendCalledFromChildView)];
    }
}


- (void)fireAppShouldResume
{
    if (refreshTimer)
    {
        [refreshTimer invalidate];
        [refreshTimer release];
        refreshTimer = nil;
    }
    
    if (self.refreshRate > 0)
    {
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshRate target:self selector:@selector(refreshCreative) userInfo:nil repeats:YES];
        [refreshTimer retain];
    }
    
    if([super respondsToSelector:@selector(fireAppShouldResumeCalledFromChildView)]){
        [super performSelector:@selector(fireAppShouldResumeCalledFromChildView)];
    }
}


@end
