//
//  TMLAdDetailViewController.h
//  ORMMA
//
//  Created by The Mobile Life on 20/09/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EmediateAdView.h"


@interface TMLAdDetailViewController : UIViewController <MRAIDViewDelegate, UITableViewDataSource, UITableViewDelegate>
{
  NSDictionary *adDetails;
  EmediateAdView *adView; //Ad view which loads MRAID script and displays ad.
  UITableView *adsTabelView;
  CGFloat expandedAdHeight;
  BOOL isAdExpanded;
  EmediateAdView *adViewInTable;
}

@property (nonatomic, retain) NSDictionary *adDetails;
@property (nonatomic) CGFloat expandedAdHeight;
@property (nonatomic) BOOL isAdExpanded;

@end
