//
//  TMLDetailController.m
//  ORMMA
//
//  Created by The Mobile Life on 19/09/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMLDetailController.h"

@implementation TMLDetailController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) 
  {
    // Custom initialization
  }
  return self;
}


- (void)loadView
{
  UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  [view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
  
  self.view = view;
  [view release];
  view = nil;
}

- (void)viewDidLoad
{
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
  self.navigationItem.rightBarButtonItem = doneButton;
  [doneButton release];
  doneButton = nil;

  adNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 100, 33)];
  [adNameLabel setBackgroundColor:[UIColor clearColor]];
  [adNameLabel setText:@"Ad Name"];
  [adNameLabel setTextColor:[UIColor grayColor]];
  [self.view addSubview:adNameLabel];
  
  adNameField = [[UITextField alloc] initWithFrame:CGRectZero];
  if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      [adNameField setFrame:CGRectMake(20, 30, 440, 33)];
    }
    else
    {
      [adNameField setFrame:CGRectMake(20, 30, 984, 33)];
    }
  }
  else
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      [adNameField setFrame:CGRectMake(20, 30, 280, 33)];
    }
    else
    {
      [adNameField setFrame:CGRectMake(20, 30, 728, 33)];
    }
  }
  [adNameField setBorderStyle:UITextBorderStyleRoundedRect];
  [adNameField setDelegate:self];
  [adNameField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
  [adNameField setAutocorrectionType:UITextAutocorrectionTypeNo];
  [adNameField setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
  [adNameField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];  
  [self.view addSubview:adNameField];
  
  baseURLLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, 100, 33)];
  [baseURLLabel setBackgroundColor:[UIColor clearColor]];
  [baseURLLabel setText:@"Base URL"];
  [baseURLLabel setTextColor:[UIColor grayColor]];
  [self.view addSubview:baseURLLabel];
  
  baseURLField = [[UITextField alloc] initWithFrame:CGRectZero];
  if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      [baseURLField setFrame:CGRectMake(20, 100, 440, 33)];
    }
    else
    {
      [baseURLField setFrame:CGRectMake(20, 100, 984, 33)];
    }
  }
  else
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      [baseURLField setFrame:CGRectMake(20, 100, 280, 33)];
    }
    else
    {
      [baseURLField setFrame:CGRectMake(20, 100, 728, 33)];
    }
  }
  [baseURLField setBorderStyle:UITextBorderStyleRoundedRect];
  [baseURLField setDelegate:self];
  [baseURLField setText:@"http://stage.emediate.eu/eas?"];
  [baseURLField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
  [baseURLField setAutocorrectionType:UITextAutocorrectionTypeNo];
  [baseURLField setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
  [baseURLField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];  
  [self.view addSubview:baseURLField];

  paramsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 140, 100, 33)];
  [paramsLabel setBackgroundColor:[UIColor clearColor]];
  [paramsLabel setText:@"Parameters"];
  [paramsLabel setTextColor:[UIColor grayColor]];
  [self.view addSubview:paramsLabel];
  
  parametersField = [[UITextField alloc] initWithFrame:CGRectZero];
  if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      [parametersField setFrame:CGRectMake(20, 170, 440, 33)];
    }
    else
    {
      [parametersField setFrame:CGRectMake(20, 170, 984, 33)];
    }
  }
  else
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      [parametersField setFrame:CGRectMake(20, 170, 280, 33)];
    }
    else
    {
      [parametersField setFrame:CGRectMake(20, 170, 728, 33)];
    }
  }
  [parametersField setBorderStyle:UITextBorderStyleRoundedRect];
  [parametersField setDelegate:self];
  [parametersField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
  [parametersField setAutocorrectionType:UITextAutocorrectionTypeNo];
  [parametersField setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
  [parametersField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];  
  [self.view addSubview:parametersField];
  
  hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 210, 280, 33)];
  [hintLabel setBackgroundColor:[UIColor clearColor]];
  [hintLabel setText:@"Eg: cu=512;cre=mu;target=_blank"];
  [hintLabel setTextColor:[UIColor grayColor]];
  [self.view addSubview:hintLabel];
  
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  //return (interfaceOrientation == UIInterfaceOrientationPortrait);
  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
}

- (void)dealloc
{
  if (baseURLField) 
  {
    [baseURLField release];
    baseURLField = nil;
  }
  if (parametersField)
  {
    [parametersField release];
    parametersField = nil;
  }
  [super dealloc];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      [adNameField setFrame:CGRectMake(20, 30, 440, 33)];
      [baseURLField setFrame:CGRectMake(20, 100, 440, 33)];
      [parametersField setFrame:CGRectMake(20, 170, 440, 33)];
      [hintLabel setFrame:CGRectMake(20, 210, 440, 33)];
    }
    else
    {
      [adNameField setFrame:CGRectMake(20, 30, 984, 33)];
      [baseURLField setFrame:CGRectMake(20, 100, 984, 33)];
      [parametersField setFrame:CGRectMake(20, 170, 984, 33)];
      [hintLabel setFrame:CGRectMake(20, 210, 984, 33)];      
    }
  }
  else
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      [adNameField setFrame:CGRectMake(20, 30, 280, 33)];
      [baseURLField setFrame:CGRectMake(20, 100, 280, 33)];
      [parametersField setFrame:CGRectMake(20, 170, 280, 33)];
      [hintLabel setFrame:CGRectMake(20, 210, 280, 33)];
    }
    else
    {
      [adNameField setFrame:CGRectMake(20, 30, 728, 33)];
      [baseURLField setFrame:CGRectMake(20, 100, 728, 33)];
      [parametersField setFrame:CGRectMake(20, 170, 728, 33)];
      [hintLabel setFrame:CGRectMake(20, 210, 728, 33)];      
    }
  }
}

- (void)done:(id)sender
{
    if(!adNameField.text){
        adNameField.text = @"";
    }
    if(!baseURLField.text){
        baseURLField.text = @"";
    }
    if(!parametersField.text){
        parametersField.text = @"";
    }
  NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:adNameField.text, @"AdName", baseURLField.text, @"BaseURL", parametersField.text, @"Params", nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ValuesEnteredNotification" object:nil userInfo:dictionary];
  [dictionary release];
  dictionary = nil;
  [self.navigationController popViewControllerAnimated:YES];
}

@end
