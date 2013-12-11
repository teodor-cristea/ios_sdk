//
//  TMLViewController.h
//  ORMMA
//
//  Created by The Mobile Life on 19/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMLViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
{
  UITableView *adsTableView; //Ads table view
  NSMutableArray *adsArray;  //Ads array which contains URL's
}

@property (nonatomic, strong) NSURL *url;

@end
