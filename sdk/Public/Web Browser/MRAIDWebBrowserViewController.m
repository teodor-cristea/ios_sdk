/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "MRAIDWebBrowserViewController.h"



@interface MRAIDWebBrowserViewController ()

- (void)updateButton:(UIButton *)button
	  withImageNamed:(NSString *)imageName
		 disableable:(BOOL)disableable;

- (UIImage *)imageForName:(NSString *)name;


@end




@implementation MRAIDWebBrowserViewController

#pragma mark -
#pragma mark Constants



#pragma mark -
#pragma mark Statics

// access to our bundle
static NSBundle *s_mraidBundle;

static NSString *s_scale = nil;


#pragma mark -
#pragma mark Properties

@synthesize webView = m_webView;
@synthesize browserNavigationBar = m_browserNavigationBar;
@synthesize addressBarBackground = m_addressBarBackground;
@synthesize backButton = m_backButton;
@synthesize forwardButton = m_forwardButton;
@synthesize refreshButton = m_refreshButton;
@synthesize safariButton = m_safariButton;
@synthesize pageLoadingIndicator = m_pageLoadingIndicator;
@synthesize closeButton = m_closeButton;
@synthesize browserDelegate = m_browserDelegate;
@dynamic URL;
@dynamic backButtonEnabled;
@dynamic forwardButtonEnabled;
@dynamic refreshButtonEnabled;
@dynamic safariButtonEnabled;
@dynamic closeButtonEnabled;



#pragma mark -
#pragma mark Initializers / Memory Management

+ (MRAIDWebBrowserViewController *)mraidWebBrowserViewController
{
	MRAIDWebBrowserViewController *c = [[[MRAIDWebBrowserViewController alloc] initWithNibName:@"MRAIDWebBrowserViewController"
																					   bundle:s_mraidBundle] autorelease];
	return c;
}


+ (void)initialize
{
	// determine the scale factor
	if ([self respondsToSelector:@selector(contentScaleFactor)])
	{
		if ( [[UIScreen mainScreen] scale] == 2.0 )
		{
			// retina display, use larger images
			s_scale = @"@2x";
		}
	}
	
	// Get a handle to our bundle
	NSString *path = [[NSBundle mainBundle] pathForResource:@"MRAID"
													 ofType:@"bundle"];
	if ( path == nil )
	{
		[NSException raise:@"Invalid Build Detected"
					format:@"Unable to find MRAID.bundle. Make sure it is added to your resources!"];
	}
	s_mraidBundle = [[NSBundle bundleWithPath:path] retain];
}


- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil 
{
    if ( ( self = [super initWithNibName:nibNameOrNil 
                                  bundle:nibBundleOrNil] ) ) 
    {
    }
    return self;
}


- (void)dealloc 
{
	[m_webView release], m_webView = nil;
	[m_browserNavigationBar release], m_browserNavigationBar = nil;
	[m_addressBarBackground release], m_addressBarBackground = nil;
	[m_backButton release], m_backButton = nil;
	[m_forwardButton release], m_forwardButton = nil;
	[m_refreshButton release], m_refreshButton = nil;
	[m_safariButton release], m_safariButton = nil;
	[m_pageLoadingIndicator release], m_pageLoadingIndicator = nil;
	[m_closeButton release], m_closeButton = nil;
	m_browserDelegate = nil;
    [super dealloc];
}


- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark -
#pragma mark Load / Unload

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	// update the address bar background using stretchable image
	UIImage *bgImage = [self imageForName:@"addressbar-background"];
	self.addressBarBackground.image = bgImage;
	
	// update the button images
	NSLog( @"Update Button Images" );
	[self updateButton:self.backButton
		withImageNamed:@"back"
		   disableable:YES];
	[self updateButton:self.forwardButton
		withImageNamed:@"forward"
		   disableable:YES];
	[self updateButton:self.refreshButton
		withImageNamed:@"refresh"
		   disableable:NO];
	[self updateButton:self.closeButton
		withImageNamed:@"close"
		   disableable:NO];
	
	// see if we need to enable the safari button or not
	[self updateButton:self.safariButton
		withImageNamed:@"openbrowser"
		   disableable:NO];
}


- (void)viewDidUnload 
{
    [super viewDidUnload];
	
	self.webView = nil;
	self.browserNavigationBar = nil;
	self.addressBarBackground = nil;
	self.backButton = nil;
	self.forwardButton = nil;
	self.refreshButton = nil;
	self.safariButton = nil;
	self.pageLoadingIndicator = nil;
	self.closeButton = nil;

}



#pragma mark -
#pragma mark View Appear / Disappear

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:m_url];
	[self.webView loadRequest:request];
}



#pragma mark -
#pragma mark Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Overriden to allow any orientation.
    return YES;
}



#pragma mark -
#pragma mark Dynamic Properties

- (NSURL *)URL
{
	return self.webView.request.URL;
}


- (void)setURL:(NSURL *)url
{
	NSLog( @"Loading URL: %@", url );
	if ( m_url != nil )
	{
		[m_url release], m_url = nil;
	}
	m_url = url;
  [m_url copy];
//	NSURLRequest *request = [NSURLRequest requestWithURL:url];
//	[self.webView loadRequest:request];
}


- (BOOL)backButtonEnabled
{
	return self.backButton.hidden;
}


- (void)setBackButtonEnabled:(BOOL)enabled
{
	self.backButton.hidden = enabled;
	if ( !enabled )
	{
		// back is not available, so forward cannot be either
		self.forwardButton.hidden = YES;
	}
}


- (BOOL)forwardButtonEnabled
{
	return self.forwardButton.hidden;
}


- (void)setForwardButtonEnabled:(BOOL)enabled
{
	self.forwardButton.hidden = !enabled;
	if ( enabled ) 
	{
		// the forward button is available so the back button must be as well
		self.backButton.hidden = NO;
	}
}


- (BOOL)refreshButtonEnabled
{
	return self.refreshButton.hidden;
}


- (void)setRefreshButtonEnabled:(BOOL)enabled
{
	self.refreshButton.hidden = enabled;
}


- (BOOL)safariButtonEnabled
{
	return self.safariButton.hidden;
}


- (void)setSafariButtonEnabled:(BOOL)enabled
{
	self.safariButton.hidden = enabled;
}


- (BOOL)closeButtonEnabled
{
	return self.closeButton.hidden;
}


- (void)setCloseButtonEnabled:(BOOL)enabled
{
	self.closeButton.hidden = enabled;
}


#pragma mark -
#pragma mark Button Actions

- (IBAction)backButtonPressed:(id)sender
{
	NSLog( @"Back Button Pressed." );
	[self.webView goBack];
}


- (IBAction)forwardButtonPressed:(id)sender
{
	NSLog( @"Forward Button Pressed." );
	[self.webView goForward];
}


- (IBAction)refreshButtonPressed:(id)sender
{
	NSLog( @"Refresh Button Pressed." );
	[self.webView reload];
}


- (IBAction)safariButtonPressed:(id)sender
{
	NSLog( @"Safari Button Pressed." );
	if ( [self.browserDelegate respondsToSelector:@selector(showURLFullScreen:sourceView:)] )
	{
		[self.browserDelegate showURLFullScreen:self.webView.request.URL
									 sourceView:self.view];
	}
}


- (IBAction)closeButtonPressed:(id)sender
{
	NSLog( @"Close Button Pressed." );
	if ( self.browserDelegate == nil )
	{
		// not assigned a delegate, just dismiss the view controller
		// (assumes that we're a modal dialog)
		NSLog( @"Auto Dismiss of Modal Browser" );
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	}
	else
	{
		NSLog( @"Use Delegate to Dismiss Browser" );
		[self.browserDelegate doneWithBrowser];
	}
}



#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webView:(UIWebView *)webView 
didFailLoadWithError:(NSError *)error
{
	NSLog( @"Error loading: %@, %@", webView.request.URL, error );
}


- (BOOL)webView:(UIWebView *)webView 
shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
	// allow the delegate first shot, if necessary
	if ( self.browserDelegate != nil )
	{
		if ( [self.browserDelegate respondsToSelector:@selector(shouldLoadRequest:forBrowser:)] )
		{
			// allow the app to take a shot at it
			return [self.browserDelegate shouldLoadRequest:request
												forBrowser:self];
		}
	}
	
	// allow everything
	NSLog( @"Allow URL: %@", request.URL );
	return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// we've finished loading the page
	NSLog( @"Web Page '%@'Finished Loading", webView.request.URL );
	[self.pageLoadingIndicator stopAnimating];
	
	// enable the back/forward buttons as needed
	self.backButton.enabled = self.webView.canGoBack;
	self.forwardButton.enabled = self.webView.canGoForward;
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// let the user know we're doing something
	NSLog( @"Web Page '%@' Started Loading", webView.request.URL );
	[self.pageLoadingIndicator startAnimating];
}


#pragma mark -
#pragma mark Utilities

- (void)updateButton:(UIButton *)button
	  withImageNamed:(NSString *)imageName
		 disableable:(BOOL)disableable
{
	UIImage *image = [self imageForName:imageName];
	[button setImage:image
			forState:UIControlStateNormal];
	if ( disableable )
	{
		NSString *disabledName = [imageName stringByAppendingString:@"-disabled"];
		UIImage *disabledImage = [self imageForName:disabledName];
		[button setImage:disabledImage
				forState:UIControlStateDisabled];
	}
}


- (UIImage *)imageForName:(NSString *)name
{
	NSString *imageName;
	if ( s_scale == nil )
	{
		imageName = name;
	}
	else
	{
		imageName = [name stringByAppendingString:s_scale];
	}
	NSString *imagePath = [s_mraidBundle pathForResource:imageName
												  ofType:@"png"];
	UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
	return image;
}

@end
