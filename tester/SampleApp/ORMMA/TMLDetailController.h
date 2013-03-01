//
//  TMLDetailController.h
//  ORMMA
//
//  Created by The Mobile Life on 19/09/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMLDetailController : UIViewController <UITextFieldDelegate>
{
  UILabel *adNameLabel;
  UITextField *adNameField;
  UILabel *baseURLLabel;
  UITextField *baseURLField;
  UILabel *paramsLabel;
  UITextField *parametersField;
  UILabel *hintLabel;
}

@end
