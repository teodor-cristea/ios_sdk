//
//  TMLViewController.m
//  ORMMA
//
//  Created by The Mobile Life on 19/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMLViewController.h"
#import "TMLDetailController.h"
#import "TMLAdDetailViewController.h"
#import "TMLDBManager.h"


@implementation TMLViewController

@synthesize url;

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
  view = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(valuesEnteredNotification:) name:@"ValuesEnteredNotification" object:nil];
    
  self.view.backgroundColor = [UIColor whiteColor];
  
  self.navigationItem.title = @"MRAID test";
  
  adsArray = [[NSMutableArray alloc] init];
  
  [adsArray addObjectsFromArray:[[TMLDBManager sharedInstance] ads]];
  
  adsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  [adsTableView setDelegate:self];
  [adsTableView setDataSource:self];  
  [self.view addSubview:adsTableView];
    
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)];
  self.navigationItem.leftBarButtonItem = addButton;
  addButton = nil;
  
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
  if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
      [adsTableView setFrame:CGRectMake(0, 0, 1024, 748)];
    }
    else
    {
      [adsTableView setFrame:CGRectMake(0, 0, 480, 270)];
    }
  }
  else
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
      [adsTableView setFrame:CGRectMake(0, 0, 768, 1004)];
    }
    else
    {
      [adsTableView setFrame:CGRectMake(0, 0, 320, 460)];
    }
  }
}

- (void)dealloc
{ 
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ValuesEnteredNotification" object:nil];
  
  if (adsTableView)
  {
    adsTableView.delegate = nil;
    adsTableView.dataSource = nil;
    adsTableView = nil;
  }  
  if (adsArray)
  {
    adsArray = nil;
  }  
}

#pragma mark 
#pragma mark EmediateAdViewDelegate method

- (void)userNameAndPasswordDidEntered:(EmediateAdView *)adView
{
  UIButton *retry = (UIButton*)[self.view viewWithTag:100];
  retry.enabled = NO;
//  [view loadCreative:[NSURL URLWithString:@"https://stage.emediate.eu/booking?wh1=camp&id1=5078"] withUsername:adView.username andPassword:adView.password];
}

- (void)userNameAndPasswordDidCancelled:(EmediateAdView *)adView
{
  NSLog(@"Authentication cancelled by user.");
  UIButton *retry =(UIButton*) [self.view viewWithTag:100];
  retry.enabled = YES;
}


- (void)viewDidAppear:(BOOL)animated
{
  NSIndexPath *selectedIndexPath = [adsTableView indexPathForSelectedRow];
  [adsTableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  NSLog(@"Editing");
  [adsTableView setEditing:editing animated:animated];
  [super setEditing:editing animated:animated];
}


- (void)showURLFullScreen:(NSURL *)aUrl
               sourceView:(UIView *)view
{
	self.url = aUrl;
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Open URL in..."
                                                     delegate:self 
                                            cancelButtonTitle:@"Cancel" 
                                       destructiveButtonTitle:nil 
                                            otherButtonTitles:@"Open in Safari", nil];
	[sheet showInView:view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet 
clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		// launch external browser
		[[UIApplication sharedApplication] openURL:self.url]; 
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    //NSLog(@"rotate...");
    return YES;
}

- (void)add:(id)sender
{
  TMLDetailController *detailViewController = [[TMLDetailController alloc] initWithNibName:nil bundle:nil];
  [self.navigationController pushViewController:detailViewController animated:YES];
  detailViewController = nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [adsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AD"];
  if (!cell)
  {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AD"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  
  NSDictionary *dictionary = [adsArray objectAtIndex:indexPath.row];
  cell.textLabel.text = [dictionary objectForKey:@"AdName"];
    
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 50.0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath 
{
  return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  // If row is deleted, remove it from the list.
  if (editingStyle == UITableViewCellEditingStyleDelete) {    
    NSDictionary *ad = [adsArray objectAtIndex:indexPath.row];
    [[TMLDBManager sharedInstance] deleteAdWithId:[[ad objectForKey:@"Key"] integerValue]];
    [adsArray removeObjectAtIndex:indexPath.row];    
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 //Ad details page where the ad is displayed on top of the screen.
  TMLAdDetailViewController *adDetailViewController = [[TMLAdDetailViewController alloc] initWithNibName:nil bundle:nil];
  adDetailViewController.adDetails = [adsArray objectAtIndex:indexPath.row];
  [self.navigationController pushViewController:adDetailViewController animated:YES];
  adDetailViewController = nil;
}


- (void)valuesEnteredNotification:(NSNotification *)aNotification
{
  NSDictionary *userInfo = [aNotification userInfo];
  [[TMLDBManager sharedInstance] insertAd:userInfo];
  [adsArray addObject:[[TMLDBManager sharedInstance] formattedDictionaryFromDictionary:userInfo]];  
  [adsTableView reloadData];
}

- (BOOL)shouldAutorotate
{
  return YES;
}

//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  if (UIInterfaceOrientationIsPortrait(fromInterfaceOrientation))
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
      [adsTableView setFrame:CGRectMake(0, 0, 1024, 748)];
    }
    else
    {
      [adsTableView setFrame:CGRectMake(0, 0, 480, 270)];
    }
  }
  else
  {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
      [adsTableView setFrame:CGRectMake(0, 0, 768, 1004)];
    }
    else
    {
      [adsTableView setFrame:CGRectMake(0, 0, 320, 460)];
    }    
  }
}

@end
