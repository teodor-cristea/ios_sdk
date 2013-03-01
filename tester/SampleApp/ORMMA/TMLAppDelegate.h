//
//  TMLAppDelegate.h
//  ORMMA
//
//  Created by The Mobile Life on 18/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TMLViewController;

@interface TMLAppDelegate : UIResponder <UIApplicationDelegate>
{    
    TMLViewController *viewController;
    UINavigationController *navigationController;
}

@property (strong, nonatomic) UIWindow *window;

@end
