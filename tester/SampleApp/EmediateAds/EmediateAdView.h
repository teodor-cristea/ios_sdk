//
//  EmediateAdView.h
//  ORMMA
//
//  Created by Raju on 25/7/12.
//  Copyright (c) 2012 The Mobile Life. All rights reserved.
//

#import "MRAIDView.h"


@interface EmediateAdView : MRAIDView
{
  NSInteger refreshRate; //Rate at which advertisement changes. If "0" or negative, means "no refresh". Defaults to 60 sec.
  NSInteger preloadCount; //Number of ads that will be pre-loaded within a campaign. If 0 or negative, means "no preload". Defaults to 5.
  NSDictionary *parameters; //Parameters of URL to get content unit.
  NSTimer *refreshTimer; //Refresh timer which triggers at the specified refreshRate time regularly.
}

@property (nonatomic, retain) NSString *baseURL;  //base URL for ads.
@property (nonatomic, retain) NSDictionary *parameters; //parameters to load ads
@property (nonatomic) NSInteger refreshRate; //rate at which ad refreshes
@property (nonatomic) NSInteger preloadCount; //number of pre-loaded ads to increase performace when loading and displaying ad content. This will also make it possible to present ads offline.

/*
Pass the required parameters to get the ads.
Parameters dictionary contains key value pairs that are used to prepare a request.
Parametes has the form key=value.
 Eg:
 cu=512;cre=mu;target=_blank
 for the above parameters dictionary should be prepared as.
 NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"512", @"cu", @"mu", @"cre", @"_blank", @"target", nil];
 Device UDID is appended at the end of parameter list internally.
*/
- (void)loadCreativeWithParameters:(NSDictionary *)params;

//time interval at which compaign gets refreshed.
- (void)fetchCampaignWithRefreshRate:(NSInteger)refresh;

//Number of ads that will be pre-loaded (within requested campaign).
- (void)enablePreloadWithCount:(NSInteger)count;

//Refresh compaign.
- (void)refreshCreative;

- (void)stop;

@end
