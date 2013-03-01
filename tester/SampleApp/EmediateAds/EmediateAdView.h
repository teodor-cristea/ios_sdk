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
  NSInteger refreshRate; //Rate at which advertisement changes
  NSDictionary *parameters; //Parameters of URL to get content unit.
  NSTimer *refreshTimer; //Refresh timer which triggers at the specified refreshRate time regularly.
}

@property (nonatomic, retain) NSString *baseURL;  //base URL for ads.
@property (nonatomic, retain) NSDictionary *parameters; //parameters to load ads
@property (nonatomic) NSInteger refreshRate; //rate at which ad refreshes

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

//Refresh compaign.
- (void)refreshCreative;

- (void)stop;

@end
