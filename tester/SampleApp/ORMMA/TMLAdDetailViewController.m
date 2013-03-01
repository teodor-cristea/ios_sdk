//
//  TMLAdDetailViewController.m
//  ORMMA
//
//  Created by The Mobile Life on 20/09/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMLAdDetailViewController.h"

@interface TMLAdDetailViewController ()

@end

@implementation TMLAdDetailViewController

@synthesize adDetails;
@synthesize expandedAdHeight;
@synthesize isAdExpanded;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
  UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  self.view = view;
  [view release];
  view = nil;
    
    
}

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view.
  
  [self.navigationItem setTitle:[adDetails objectForKey:@"AdName"]];
  
  UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
  self.navigationItem.rightBarButtonItem = refreshButton;
  [refreshButton release];
  refreshButton = nil;
  
  //Create ad view like UIView with frame.
  adView = [[EmediateAdView alloc] initWithFrame:CGRectZero];
  if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      adView.frame = CGRectMake(0, 0, 480, 50);
    }
    else
    {
      adView.frame = CGRectMake(0, 0, 1024, 50);
    }
  }
  else
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      adView.frame = CGRectMake(0, 0, 320, 50);
    }
    else
    {
      adView.frame = CGRectMake(0, 0, 768, 50);
    }
  }
  
  [adView setBackgroundColor:[UIColor whiteColor]];
  adView.tag = 1;
  
  //adView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [adView setMraidDelegate:self]; //To recieve call backs from MRAID script for interactions by user
  [adView fetchCampaignWithRefreshRate:60]; //Rate at which ad changes...
  [adView setBaseURL:[adDetails objectForKey:@"BaseURL"]]; //Base URL.
    
  [self.view addSubview:adView];
  /*
  Pass the required parameters to baseURL to get the compaign. 
  Parametes has the form key=value.
  Eg:
  cu=512;cre=mu;target=_blank
  for the above parameters dictionary should be prepared as.
  NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"512", @"cu", @"mu", @"cre", @"_blank", @"target", nil];
  */
  [adView loadCreativeWithParameters:[adDetails objectForKey:@"Params"]];
  
  adsTabelView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      [adsTabelView setFrame:CGRectMake(0, 50, 480, 250-30)];
    }
    else
    {
      [adsTabelView setFrame:CGRectMake(0, 50, 1024, 698)];
    }
  }
  else
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      [adsTabelView setFrame:CGRectMake(0, 50, 320, 410)];
    }
    else
    {
      [adsTabelView setFrame:CGRectMake(0, 50, 768, 954)];
    }
  }
  [adsTabelView setDelegate:self];
  [adsTabelView setDataSource:self];
  [adsTabelView setClipsToBounds:YES];
  [self.view addSubview:adsTabelView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"Cell";
  UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (!cell)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
  }
  
  if (indexPath.row == 3)
  {
    if (self.isAdExpanded == NO)
    {
      if (adViewInTable == nil)
      {
        adViewInTable = [[EmediateAdView alloc] initWithFrame:CGRectZero];
        if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
        {
          if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
          {
            adViewInTable.frame = CGRectMake(0, 0, 480, 50);            
          }
          else
          {
            adViewInTable.frame = CGRectMake(0, 0, 1024, 50);
          }
        }
        else
        {
          if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
          {
            adViewInTable.frame = CGRectMake(0, 0, 320, 50);
          }
          else
          {
            adViewInTable.frame = CGRectMake(0, 0, 768, 50);
          }
        }
        [adViewInTable setBackgroundColor:[UIColor whiteColor]];
        adViewInTable.tag = 2;
        [adViewInTable setMraidDelegate:self]; //To recieve call backs from MRAID script for interactions by user
        [adViewInTable fetchCampaignWithRefreshRate:20]; //Rate at which ad changes...
        [adViewInTable setBaseURL:[adDetails objectForKey:@"BaseURL"]]; //Base URL.
        [cell.contentView addSubview:adViewInTable];
        [adViewInTable loadCreativeWithParameters:[adDetails objectForKey:@"Params"]];
      }
    }
    else
    {
        self.isAdExpanded = NO;
    }
  }
  else
  {
    cell.textLabel.text = [NSString stringWithFormat:@"Sample text %d", indexPath.row+1];
  }
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row == 3)
  {
    if (self.isAdExpanded)
    {
      return self.expandedAdHeight;
    }
    else
    {
      return 50;
    }
  }
  else
  {
    return 44;
  }
}

//Refresh ad
- (void)refresh:(id)sender 
{
  [adView refreshCreative];
}

-(void)viewDidDisappear:(BOOL)animated
{
  [adView stop];
  [adViewInTable stop];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  if (UIInterfaceOrientationIsPortrait(fromInterfaceOrientation))
  {
    CGRect frame = CGRectZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      frame = CGRectMake(0, 0, 480, 50);
      [adView setFrame:frame];
      [adViewInTable setFrame:frame];
      [adsTabelView setFrame:CGRectMake(0, 50, 480, 250-30)];
    }
    else
    {
      frame = CGRectMake(0, 0, 1024, 50);
      [adView setFrame:frame];
      [adViewInTable setFrame:frame];
      [adsTabelView setFrame:CGRectMake(0, 50, 1024, 698)];
    }
  }
  else
  {
    CGRect frame = CGRectZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      frame = CGRectMake(0, 0, 320, 50);
      [adView setFrame:frame];
      [adViewInTable setFrame:frame];
      [adsTabelView setFrame:CGRectMake(0, 50, 320, 410)];
    }
    else
    {
      frame = CGRectMake(0, 0, 768, 50);
      [adView setFrame:frame];
      [adViewInTable setFrame:frame];
      [adsTabelView setFrame:CGRectMake(0, 50, 768, 954)];
    }
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
    {
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        [adView setFrame:CGRectMake(0, 0, 480, 50)];
      }
      else
      {
        [adView setFrame:CGRectMake(0, 0, 1024, 50)];
      }
    }
    else
    {
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        [adView setFrame:CGRectMake(0, 0, 320, 50)];
      }
      else
      {
        [adView setFrame:CGRectMake(0, 0, 768, 50)];
      }
    }
    return YES;
}

- (void)dealloc
{
  if (adView)
  {
    [adView stop];
    [adView setMraidDelegate:nil];
    [adView release];
    adView = nil;
  }
  
  if (adViewInTable)
  {
    [adViewInTable stop];
    [adViewInTable setMraidDelegate:nil];
    [adViewInTable release];
    adViewInTable = nil;
  }

  if (adDetails)
  {
    [adDetails release];
    adDetails = nil;
  }
  [super dealloc];
}

- (UIViewController *)mraidViewController
{
  return self;
}


// called when an ad fails to load
- (void)failureLoadingAd:(MRAIDView *)anAdView
{
  NSLog(@"Failure loading Ad.");
}

// Called before the ad is resized in place to allow the parent application to
// animate things if desired.
- (void)willResizeAd:(MRAIDView *)anAdView
              toSize:(CGSize)size
{
  NSLog(@"willResize Ad.");
}

// Called after the ad is resized in place to allow the parent application to
// animate things if desired.
- (void)didResizeAd:(MRAIDView *)anAdView
             toSize:(CGSize)size
{
  NSLog(@"didResize Ad.");    
}


// Called just before to an ad is displayed
- (void)adWillShow:(MRAIDView *)anAdView
{
  NSLog(@"willShow Ad.");
  //[view setHidden:NO];
}

// Called just after to an ad is displayed
- (void)adDidShow:(MRAIDView *)anAdView
{
  NSLog(@"didShow Ad.");   
  UIButton *retry = (UIButton*)[self.view viewWithTag:100];
  retry.enabled = YES; 
}

// Called just before to an ad is Hidden
- (void)adWillHide:(MRAIDView *)anAdView
{
  NSLog(@"willHide Ad.");
}

// Called just after to an ad is Hidden
- (void)adDidHide:(MRAIDView *)anAdView
{
  NSLog(@"didHide Ad.");    
}

// Called just before an ad expands
- (void)willExpandAd:(MRAIDView *)anAdView
             toFrame:(CGRect)frame
{
  NSLog(@"willExpand Ad.");
  NSLog(@"Frame = (%f, %f, %f, %f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
  if (anAdView.tag == 1)
  {
    self.isAdExpanded = NO;
    if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
    {
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        [adsTabelView setFrame:CGRectMake(0, frame.origin.y+frame.size.height, 480, 250)];
      }
      else
      {
        [adsTabelView setFrame:CGRectMake(0, frame.origin.y+frame.size.height, 1024, 698)];
      }
    }
    else
    {
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        [adsTabelView setFrame:CGRectMake(0, frame.origin.y+frame.size.height, 320, 300)];
      }
      else
      {
        [adsTabelView setFrame:CGRectMake(0, frame.origin.y+frame.size.height, 768, 954)];
      }
    }
  }
  else if (anAdView.tag == 2)
  {
    self.isAdExpanded = YES;
    self.expandedAdHeight = frame.size.height;
    [adsTabelView reloadData];
  }
  else
  {
    assert(false);
  }
}

// Called just after an ad expands
- (void)didExpandAd:(MRAIDView *)anAdView
            toFrame:(CGRect)frame
{
  NSLog(@"didExpand Ad.");
  if (anAdView.tag == 1)
  {
    if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
    {
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        [adsTabelView setFrame:CGRectMake(0, frame.origin.y+frame.size.height, 480, 300)];
      }
      else
      {
        [adsTabelView setFrame:CGRectMake(0, frame.origin.y+frame.size.height, 1024, 698)];
      }
    }
    else
    {
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        [adsTabelView setFrame:CGRectMake(0, frame.origin.y+frame.size.height, 320, 300)];
      }
      else
      {
        [adsTabelView setFrame:CGRectMake(0, frame.origin.y+frame.size.height, 768, 954)];
      }
    }
  }
  else if (anAdView.tag == 2)
  {
    
  }
  else
  {
    assert(false);
  }
}

// Called just before an ad closes
- (void)adWillClose:(MRAIDView *)anAdView
{
  NSLog(@"willClose Ad.");    
}

// Called just after an ad closes
- (void)adDidClose:(MRAIDView *)anAdView
{
  NSLog(@"didClose Ad.");
  if (anAdView.tag == 1)
  {
    if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
    {
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        [adsTabelView setFrame:CGRectMake(0, 50, 480, 250)];
      }
      else
      {
        [adsTabelView setFrame:CGRectMake(0, 50, 1024, 698)];
      }
    }
    else
    {
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      {
        [adsTabelView setFrame:CGRectMake(0, 50, 320, 410)];
      }
      else
      {
        [adsTabelView setFrame:CGRectMake(0, 50, 768, 954)];
      }
    }
  }
  else if (anAdView.tag == 2)
  {
    [adsTabelView reloadData];
  }
  else
  {
    assert(false);
  }
}

// called when the ad will begin heavy content (usually when the ad goes full screen)
- (void)appShouldSuspendForAd:(MRAIDView *)anAdView
{
  NSLog(@"app suspended.");
}

// called when the ad is finished with it's heavy content (usually when the ad returns from full screen)
- (void)appShouldResumeFromAd:(MRAIDView *)anAdView
{
  NSLog(@"**************app resume.*****************");
}


@end
