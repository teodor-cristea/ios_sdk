/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <QuartzCore/QuartzCore.h>
#import "MRAIDView.h"
#import "UIDevice-Hardware.h"
#import "UIDevice-MRAID.h"
#import "UIWebView-MRAID.h"
#import "MRAIDJavascriptBridge.h"
#import "MRAIDLocalServer.h"
#import "MRAIDWebBrowserViewController.h"
#import "MRAIDAVPlayer.h"

#define ROTATION_ANIMATION_DURATION (0.4)

@interface MRAIDView () <UIWebViewDelegate,
						 MRAIDJavascriptBridgeDelegate,
						 MRAIDLocalServerDelegate>

@property( nonatomic, retain, readwrite ) NSError *lastError;
@property( nonatomic, assign, readwrite ) MRAIDViewState currentState;
@property( nonatomic, retain ) MRAIDWebBrowserViewController *webBrowser;
@property( nonatomic, retain ) MRAIDAVPlayer *moviePlayer;
@property( nonatomic, assign, readwrite ) BOOL isMRAIDAd;
@property( nonatomic, retain ) NSURL *launchURL;

- (void)commonInitialization;

- (NSInteger)angleFromOrientation:(UIDeviceOrientation)orientation;

+ (void)copyFile:(NSString *)file
		  ofType:(NSString *)type
	  fromBundle:(NSBundle *)bundle
		  toPath:(NSString *)path;

- (void)blockingViewTouched:(id)sender;

- (void)logFrame:(CGRect)frame
			text:(NSString *)text;

- (NSString *)usingWebView:(UIWebView *)webView
		 executeJavascript:(NSString *)javascript
			   withVarArgs:(va_list)varargs;


- (void)injectJavaScriptIntoWebView:(UIWebView *)webView;
- (void)injectMRAIDJavaScriptIntoWebView:(UIWebView *)webView;
- (void)injectMRAIDStateIntoWebView:(UIWebView *)webView;
- (void)injectJavaScriptFile:(NSString *)fileName
				 intoWebView:(UIWebView *)webView;

- (void)fireAdWillShow;
- (void)fireAdDidShow;
- (void)fireAdWillHide;
- (void)fireAdDidHide;
- (void)fireAdWillClose;
- (void)fireAdDidClose;
- (void)fireAdWillResizeToSize:(CGSize)size;
- (void)fireAdDidResizeToSize:(CGSize)size;
- (void)fireAdWillExpandToFrame:(CGRect)frame;
- (void)fireAdDidExpandToFrame:(CGRect)frame;
- (void)fireAppShouldSuspend;
- (void)fireAppShouldResume;


-(void)verifyExternalLaunchWithTitle:(NSString *)title
								 URL:(NSURL*)url;

- (void)alwaysSetFrame:(CGRect)frame;
- (CGRect)rectAccordingToOrientation:(CGRect)rect;
- (void)rotateExpandedWindowsToOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)webFrameAccordingToOrientation:(CGRect)rect;
- (void)setJavascriptDefaultFrame:(CGRect)frame;
- (CGRect)convertedRectAccordingToOrientation:(CGRect)rect;
- (CGSize)statusBarSize:(CGSize)size accordingToOrientation:(UIInterfaceOrientation)orientation;
- (void)fireViewableChange;
- (UIInterfaceOrientation)currentInterfaceOrientation;
@end


@implementation MRAIDView


#pragma mark -
#pragma mark Statics

static MRAIDLocalServer *s_localServer;
static NSBundle *s_mraidBundle;


#pragma mark -
#pragma mark Constants

NSString * const kAnimationKeyExpand = @"expand";
NSString * const kAnimationKeyCloseExpanded = @"closeExpanded";

NSString * const kInitialMRAIDPropertiesFormat = @"{ state: '%@'," \
												   " network: '%@',"\
												   " size: { width: %f, height: %f },"\
												   " maxSize: { width: %f, height: %f },"\
												   " screenSize: { width: %f, height: %f },"\
												   " defaultPosition: { x: %f, y: %f, width: %f, height: %f },"\
												   " orientation: %i,"\
												   " supports: [ 'level-1', 'level-2', 'orientation', 'network', 'heading', 'location', 'screen', 'shake', 'size', 'tilt', 'sms', 'phone', 'email', 'audio', 'video', 'map'%@ ] }";

NSString * const kDefaultPositionMRAIDPropertiesFormat = @"{ defaultPosition: { x: %f, y: %f, width: %f, height: %f }, size: { width: %f, height: %f } }";

#pragma mark -
#pragma mark Properties

@synthesize mraidDelegate = m_mraidDelegate;
@dynamic htmlStub;
@synthesize creativeURL = m_creativeURL;
@synthesize creativeBaseURL = m_creativeBaseURL;
@synthesize lastError = m_lastError;
@synthesize currentState = m_currentState;
@synthesize maxSize = m_maxSize;
@synthesize webBrowser = m_webBrowser;
@synthesize moviePlayer = m_moviePlayer;
@synthesize allowLocationServices = m_allowLocationServices;

@synthesize isMRAIDAd = m_isMRAIDAd;
@synthesize launchURL = m_launchURL;

@synthesize userLocation = m_userLocation;

#pragma mark -
#pragma mark Initializers / Memory Management

+ (void)initialize
{
	// setup autorelease pool since this will be called outside of one
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// setup our cache
	s_localServer = [MRAIDLocalServer sharedInstance];
	
	// access our bundle
	NSString *path = [[NSBundle mainBundle] pathForResource:@"MRAID"
													 ofType:@"bundle"];
	if ( path == nil )
	{
		[NSException raise:@"Invalid Build Detected"
					format:@"Unable to find MRAID.bundle. Make sure it is added to your resources!"];
	} 
	s_mraidBundle = [[NSBundle bundleWithPath:path] retain];
	
	// load the Public Javascript API
	path = [MRAIDLocalServer rootActiveDirectory];
	[self copyFile:@"mraid"
			ofType:@"js" 
		fromBundle:s_mraidBundle
			toPath:path];
	
	// load the Native Javascript API
	[self copyFile:@"mraid_bridge"
			ofType:@"js" 
		fromBundle:s_mraidBundle
			toPath:path];
	
	// done with autorelease pool
	[pool drain];
}


- (id)initWithCoder:(NSCoder *)coder
{
    if ( ( self = [super initWithCoder:coder] ) ) 
	{
		[self commonInitialization];
	}
	return self;
}


- (id)initWithFrame:(CGRect)frame 
{
    if ( ( self = [super initWithFrame:frame] ) ) 
    {
		[self commonInitialization];
    }
    return self;
}


- (void)commonInitialization
{
	// create our bridge object
	m_javascriptBridge = [[MRAIDJavascriptBridge alloc] init];
	m_javascriptBridge.bridgeDelegate = self;
	
	// set our modality
	m_modalityCounter = 0;
	
	// it's up to the client to set any resizing policy for this container
	
	// make sure our default background color is transparent,
	// the consumer can change it if need be
	self.backgroundColor = [UIColor clearColor];
	self.opaque = NO;
	
	// let's create a webview that will fill it's parent
	CGRect webViewFrame = CGRectMake( 0, 
									  0, 
									  self.frame.size.width, 
									  self.frame.size.height );
	m_webView = [[UIWebView alloc] initWithFrame:webViewFrame];
	[m_webView disableBouncesAndScrolling];
	
	// make sure the webview will expand/contract as needed
	m_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | 
								 UIViewAutoresizingFlexibleHeight;
	m_webView.clipsToBounds = YES;

	// register ourselves to recieve any delegate calls
	m_webView.delegate = self;
	
	// the web view should be transparent
	m_webView.backgroundColor = [UIColor clearColor];
	m_webView.opaque = NO;
	
	// add the web view to the main view
	[self addSubview:m_webView];
	
	// let the OS know that we care about receiving various notifications
	m_currentDevice = [UIDevice currentDevice];
	[m_currentDevice beginGeneratingDeviceOrientationNotifications];
	m_currentDevice.proximityMonitoringEnabled = NO; // enable as-needed to conserve power
	
	// setup default maximum size based on our current frame size
	self.maxSize = self.frame.size;
	
	// set our initial state
	self.currentState = MRAIDViewStateDefault;
	
	// setup special protocols
	m_externalProtocols = [[NSMutableArray alloc] init];
    
    {// location
        
        locationManager = [CLLocationManager new];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        [locationManager startUpdatingLocation];
        
    }
}


- (void)dealloc 
{
	// we're done receiving device changes
	[m_currentDevice endGeneratingDeviceOrientationNotifications];

	// free up some memory
	[m_creativeURL release], m_creativeURL = nil;
    [m_creativeBaseURL release], m_creativeBaseURL = nil;
	m_currentDevice = nil;
	[m_lastError release], m_lastError = nil;
	[m_webView release], m_webView = nil;
	[m_blockingView release], m_blockingView = nil;
	m_mraidDelegate = nil;
	[m_javascriptBridge restoreServicesToDefaultState], [m_javascriptBridge release], m_javascriptBridge = nil;
	[m_webBrowser release], m_webBrowser = nil;
	[m_launchURL release], m_launchURL = nil;
	[m_externalProtocols removeAllObjects], [m_externalProtocols release], m_externalProtocols = nil;
	[m_creativeId release];
    
    [locationManager stopUpdatingLocation];
    [locationManager release];
    
    [super dealloc];
}




#pragma mark -
#pragma mark Dynamic Properties

- (NSString *)htmlStub
{
	// delegate to cache
	MRAIDLocalServer *cache = [MRAIDLocalServer sharedInstance];
	return cache.htmlStub;
}


- (void)setHtmlStub:(NSString *)stub
{
	// delegate to cache
	MRAIDLocalServer *cache = [MRAIDLocalServer sharedInstance];
	cache.htmlStub = stub;
}
		 


#pragma mark -
#pragma mark UIWebViewDelegate Methods

- (void)webView:(UIWebView *)webView 
didFailLoadWithError:(NSError *)error
{
	NSLog( @"Failed to load URL into Web View: %@", error );
	self.lastError = error;
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(failureLoadingAd:)] ) )
	{
		[self.mraidDelegate failureLoadingAd:self];
	}
	m_loadingAd = NO;
}


- (BOOL)webView:(UIWebView *)webView 
shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = [request URL];
	NSLog( @"Verify Web View should load URL: %@", url );

	if ( [request.URL isFileURL] )
	{
		// Direct access to the file system is disallowed
		return NO;
	}
    NSString *fullUrl = [request.URL absoluteString];

	// normal ad
	if ( [m_javascriptBridge processURL:url
							 forWebView:webView] )
	{
		// the bridge processed the url, nothing else to do
		return NO;
	}
	if ( [@"about:blank" isEqualToString:fullUrl] )
	{
		// changed behavior 2014-01-03: DO load empty pages as they may in fact be redirects.
		return YES;
	}
	
	// handle mailto and tel
	NSString *scheme = url.scheme;
	if ( [@"mailto" isEqualToString:scheme] )
	{
		// handle mail to
		NSLog( @"MAILTO: %@", url );
		NSString *addr = [url.absoluteString substringFromIndex:7];
		if ( [addr hasPrefix:@"//"] )
		{
			NSString *addr = [addr substringFromIndex:2];
		}
	
    /*	
		[self sendEMailTo:addr
			  withSubject:nil
				 withBody:nil
				   isHTML:NO];
    */
		
		return NO;
	}
	else if ( [@"tel" isEqualToString:scheme] )
	{
		// handle telephone call
    /*
		UIApplication *app = [UIApplication sharedApplication];
		[app openURL:url];
    */
		return NO;
	}
	
	// not handled by MRAID, see if the delegate wants it
	if ( m_externalProtocols.count > 0 )
	{
		if ( [self.mraidDelegate respondsToSelector:@selector(handleRequest:forAd:)] )
		{
			NSLog( @"Scheme is: %@", scheme );
			for ( NSString *p in m_externalProtocols )
			{
				if ( [p isEqualToString:scheme] )
				{
					// container handles the call
					[self.mraidDelegate handleRequest:request
												forAd:self];
					NSLog( @"Container handled request for: %@", request );
					return NO;
				}
			}
		}
	}
	
	// if the user clicked a non-handled link, open it in a new browser
	if ( !m_loadingAd )
	{
		NSLog( @"Delegating Open to web browser." );

		[self fireAppShouldSuspend];
		
		if ( self.currentState == MRAIDViewStateExpanded )
		{
			self.hidden = YES;
      m_blockingView.hidden = YES;
		}
            
		MRAIDWebBrowserViewController *wbvc = [MRAIDWebBrowserViewController mraidWebBrowserViewController];
		wbvc.URL = request.URL;
		wbvc.browserDelegate = self;
		UIViewController *vc = [self.mraidDelegate mraidViewController];
		[vc presentModalViewController:wbvc
							  animated:YES];
		return NO;
	}
	
	// for all other cases, just let the web view handle it
	NSLog( @"Perform Normal process for URL." );
	return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// we've finished loading the URL
	[self injectJavaScriptIntoWebView:webView];
	[m_webView disableBouncesAndScrolling];
	m_loadingAd = NO;
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
	NSLog( @"Web View Started Loading" );
}


#pragma mark -
#pragma mark Ad Loading

//- (void)loadCreative:(NSURL *)url 
//        withUsername:(NSString *)username 
//         andPassword:(NSString *)password
//{
//	// reset our state
//	m_applicationReady = NO;
//	
//	[self restoreToDefaultState];
//	
//	// ads loaded by URL are assumed to be complete as-is, just display it
//	NSLog( @"Load Ad from URL: %@", url );
//	self.creativeURL = url;
//  
//	[s_localServer cacheURL:url userName:username password:password
//             withDelegate:self];
//}
//

- (void)loadCreative:(NSURL *)url withPreloadCount:(NSInteger)count
{
	// reset our state
	m_applicationReady = NO;
	
	[self restoreToDefaultState];
	
	// ads loaded by URL are assumed to be complete as-is, just display it
	NSLog( @"Load Ad from URL: %@", url );
	self.creativeURL = url;
  
	[s_localServer cacheURL:url
                fromCampaignURL:self.creativeBaseURL
			   withDelegate:self
            andPreloadCount:count];
}


- (void)loadHTMLCreative:(NSString *)htmlFragment
			 creativeURL:(NSURL *)url
{
	// reset our state
	m_applicationReady = NO;
	
	[self restoreToDefaultState];
	
	self.creativeURL = url;
	[s_localServer cacheHTML:htmlFragment
					 baseURL:url
                 campaignURL:self.creativeBaseURL
				withDelegate:self];
}



#pragma mark -
#pragma mark External Protocol Control

- (void)registerProtocol:(NSString *)protocol
{
	// don't allow dupes
	for ( NSString *p in m_externalProtocols )
	{
		if ( [p isEqualToString:protocol] )
		{
			// already present, ignore
			return;
		}
	}
	
	// not yet present, add it
	[m_externalProtocols addObject:protocol];
}


- (void)deregisterProtocol:(NSString *)protocol
{
	for ( NSInteger i = ( m_externalProtocols.count - 1 ); i >= 0; i-- )
	{
		NSString *p = [m_externalProtocols objectAtIndex:i];
		if ( [p isEqualToString:protocol] )
		{
			// found a match, remove it
			[m_externalProtocols removeObjectAtIndex:i];
		}
	}
}



#pragma mark -
#pragma mark External Ad Size Control

- (void)restoreToDefaultState
{
	if ( self.currentState != MRAIDViewStateDefault )
	{
		[self closeAd:m_webView];
	}
	if ( m_modalityCounter > 0 )
	{
		// force ourselves to resume the app if we're still suspended
		m_modalityCounter = 1;
		[self fireAppShouldResume];
	}
	m_modalityCounter = 0;
}



// These method let the app indicate whether it considers the MRAIDView to be visible or not.
// This is useful when MRAIDView are embedded in a scrolling view and need to be loaded in advance.
// Calling these method will let the MRAIDView set the proper default ad position based on the currently displayed view.
- (void)mraidViewDisplayed:(BOOL)isDisplayed
{
    [self setJavascriptDefaultFrame:self.frame];
    m_bIsDisplayed = isDisplayed;
    [self fireViewableChange];
}

#pragma mark -
#pragma mark Javascript Bridge Delegate
- (UIWebView *)webView
{
	return m_webView;
}


- (void)adIsMRAIDEnabledForWebView:(UIWebView *)webView
{
	self.isMRAIDAd = YES;
}


- (NSString *)usingWebView:(UIWebView *)webView
		 executeJavascript:(NSString *)javascript, ...
{
	// handle variable argument list
	va_list args;
	va_start( args, javascript );
	NSString *result = [self usingWebView:webView
						executeJavascript:javascript
							  withVarArgs:args];
	va_end( args );
	return result;
}


- (NSString *)usingWebView:(UIWebView *)webView
		 executeJavascript:(NSString *)javascript
			   withVarArgs:(va_list)args
{
	NSString *js = [[[NSString alloc] initWithFormat:javascript arguments:args] autorelease];
	NSLog( @"Executing Javascript: %@", js );
	return [webView stringByEvaluatingJavaScriptFromString:js];
}


- (void)showAd:(UIWebView *)webView
{
	// called when the ad needs to be made visible
	[self fireAdWillShow];
	
	// Nothing special to do, other than making sure the ad is visible
	NSString *newState = @"default";
	self.currentState = MRAIDViewStateDefault;
	
	// notify that we're done
	[self fireAdDidShow];
	
	// notify the ad view that the state has changed
	[self usingWebView:webView
	executeJavascript:@"window.mraidview.fireChangeEvent( { state: '%@' } );", newState];
}


- (void)hideAd:(UIWebView *)webView
{
	// make sure we're not already hidden
	if ( self.currentState == MRAIDViewStateHidden )
	{
		[self usingWebView:webView
		 executeJavascript:@"window.mraidview.fireErrorEvent( 'Cannot hide if we're already hidden.', 'hide' );" ];
		return;
	}	
	
	// called when the ad is ready to hide
	[self fireAdWillHide];
	
	// if the ad isn't in the default state, restore it first
	[self closeAd:webView];
	
	// now hide the ad
	self.hidden = YES;
	self.currentState = MRAIDViewStateHidden;

	// notify everyone that we're done
	[self fireAdDidHide];
	
	// notify the ad view that the state has changed
	[self usingWebView:webView
	 executeJavascript:@"window.mraidview.fireChangeEvent( { state: 'hidden', size: { width: 0, height: 0 } } );"];
}


- (void)closeAd:(UIWebView *)webView
{
	// reality check
	NSAssert( ( webView != nil ), @"Web View passed to close is NULL" );
	
	// if we're in the default state already, there is nothing to do
	if ( self.currentState == MRAIDViewStateDefault )
	{
		// default ad, nothing to do
		return;
	}
	else if ( self.currentState == MRAIDViewStateHidden )
	{
		// hidden ad, nothing to do
		return;
	}
	
	// Closing the ad refers to restoring the default state, whatever tasks
	// need to be taken to achieve this state
	
	// notify the app that we're starting
	[self fireAdWillClose];
	
	// closing the ad differs based on the current state
	if ( self.currentState == MRAIDViewStateExpanded )
	{
		// We know we're going to close our state from the expanded state.
		// So we basically want to reverse the steps we took to get to the
		// expanded state as follows: (note: we already know we're in a good
		// state to close)
		//
		// so... here's what we're going to do:
		// step 1: start a new animation, and change our frame
		// step 2: change our frame to the stored translated frame
		// step 3: wait for the animation to complete
		// step 4: restore our frame to the original untranslated frame
		// step 5: get a handle to the key window
		// step 6: get a handle to the previous parent view based on the tag
		// step 7: restore the parent view's original tag
		// step 8: add ourselves to the original parent window
		// step 9: remove the blocking view
		// step 10: fire the size changed MRAID event
		// step 11: update the state to default
		// step 12: fire the state changed MRAID event
		// step 13: fire the application did close delegate call
		//
		// Now, let's get started
		[self fireAppShouldResume];
		
		// step 1: start a new animation, and change our frame
		// step 2: change our frame to the stored translated frame
		[UIView beginAnimations:kAnimationKeyCloseExpanded
						context:nil];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationDelegate:self];

		// step 2: change our frame to the stored translated frame
		[self alwaysSetFrame:m_translatedFrame];
        
		// update the web view as well
		CGRect webFrame = [self webFrameAccordingToOrientation:m_translatedFrame];
		webView.frame = webFrame;
        
		[UIView commitAnimations];
        
		// step 3: wait for the animation to complete
		// (more happens after the animation completes)
    }
	else
	{
		// animations for resize are delegated to the application
		
		// notify the app that we are resizing
		[self fireAdWillResizeToSize:m_defaultFrame.size];
		
		// restore the size
		self.frame = m_defaultFrame;
		
		// update the web view as well
		CGRect webFrame = CGRectMake( 0, 0, m_defaultFrame.size.width, m_defaultFrame.size.height );
		webView.frame = webFrame;
		
		// notify the app that we are resizing
		[self fireAdDidResizeToSize:m_defaultFrame.size];
		
		// notify the app that we're done
		[self fireAdDidClose];
		
		// update our state
		self.currentState = MRAIDViewStateDefault;
		
		// notify the client
		[self usingWebView:webView
		 executeJavascript:@"window.mraidview.fireChangeEvent( { state: 'default', size: { width: %f, height: %f } } );", m_defaultFrame.size.width, m_defaultFrame.size.height ];
	}
}


- (void)expandTo:(CGRect)endingFrame
		 withURL:(NSURL *)url
	inWebView:(UIWebView *)webView
   blockingColor:(UIColor *)blockingColor
blockingOpacity:(CGFloat)blockingOpacity
lockOrientation:(BOOL)allowOrientationChange
{
	// OK, here's what we have to do when the creative want's to expand
	// Note that this is NOT the same as resize.
	// first, since we have no idea about the surrounding view hierarchy we
	// need to pull our container to the "top" of the view hierarchy. This
	// means that we need to be able to restore ourselves when we're done, so
	// we want to remember our settings from before we kick off the expand
	// function.
	//
	// so... here's what we're going to do:
	// step 0: make sure we're in a valid state to expand
	// step 1: fire the application will expand delegate call
	// step 2: get a handle to the key window
	// step 3: store the current frame for later re-use
	// step 4: create a blocking view that fills the current window
	// step 5: store the current tag for the parent view
	// step 6: pick a random unused tag
	// step 7: change the parent view's tag to the new random tag
	// step 8: create a new frame, based on the current frame but with
	//         coordinates translated to the window space
	// step 9: store this new frame for later use
	// step 10: change our frame to the new one
	// step 11: add ourselves to the key window
	// step 12: start a new animation, and change our frame
	// step 13: wait for the animation to complete
	// step 14: fire the size changed MRAID event
	// step 15: update the state to expanded
	// step 16: fire the state changed MRAID event
    // step 17: fire the application did expand delegate call
	//
	// Now, let's get started
	
	// step 0: make sure we're in a valid state to expand
	if ( self.currentState != MRAIDViewStateDefault )
	{
		// Already Expanded
		[self usingWebView:webView
		 executeJavascript:@"window.mraidview.fireErrorEvent( 'Can only expand from the default state.', 'expand' );" ];
		return;
	}	
	 
	// step 1: fire the application will expand delegate call
	[self fireAdWillExpandToFrame:endingFrame];
	[self fireAppShouldSuspend];

	allowAdOrientation = allowOrientationChange;
	// step 2: get a handle to the key window
	UIApplication *app = [UIApplication sharedApplication];
	UIWindow *keyWindow = [app keyWindow];
	
	// step 3: store the current frame for later re-use
	m_defaultFrame = self.frame;
								
	// step 4: create a blocking view that fills the current window
	// if the status bar is visible, we need to account for it
	CGRect f = keyWindow.frame;
    UIInterfaceOrientation orientation = app.statusBarOrientation;
	if ( !app.statusBarHidden )
	{
	   // status bar is visible
        endingFrame.origin.y -= [self statusBarSize:app.statusBarFrame.size accordingToOrientation:orientation].height;
	}
    m_expandedFrame = endingFrame;
   
    
    // The endingFrame is not a rotated frame. The function has to take the current rotation into consideration.
    endingFrame = [self convertedRectAccordingToOrientation:endingFrame];
    
	if ( m_blockingView != nil )
	{
		[m_blockingView removeFromSuperview], m_blockingView = nil;
	}
	m_blockingView = [[UIButton alloc] initWithFrame:f];
	m_blockingView.backgroundColor = blockingColor;
	m_blockingView.alpha = blockingOpacity;
    m_originalTransform = self.transform;
    [self rotateExpandedWindowsToOrientation:orientation];
	[keyWindow addSubview:m_blockingView];
	
	// step 5: store the current tag for the parent view
	UIView *parentView = self.superview;
	m_originalTag = parentView.tag;
	
	// step 6: pick a random unused tag
	m_parentTag = 0;
	do 
	{
		m_parentTag = arc4random() % 25000;
	} while ( [keyWindow viewWithTag:m_parentTag] != nil );
	
	// step 7: change the parent view's tag to the new random tag
	parentView.tag = m_parentTag;

	// step 8: create a new frame, based on the current frame but with
	//         coordinates translated to the window space
	// step 9: store this new frame for later use
	// convertRect should be called not by the MRAIDView but by the parent of the MRAIDView
	m_translatedFrame = [self.superview convertRect:m_defaultFrame
								   toView:keyWindow];
	
	// step 10: change our frame to the new one
	[self alwaysSetFrame:m_translatedFrame];
    
    // step 11: add ourselves to the key window
	[keyWindow addSubview:self];
	
	// step 12: start a new animation, and change our frame
	[UIView beginAnimations:kAnimationKeyExpand
					context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
	[self alwaysSetFrame:endingFrame];
    
	// Create frame for web view
    CGRect webFrame = [self webFrameAccordingToOrientation:endingFrame];
	webView.frame = webFrame;
	
//	CATransition *transition = [CATransition animation];
//	transition.duration = 0.75;
//	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//	transition.type = kCATransitionReveal;
//	transition.subtype = kCATransitionFromLeft;
//	[webFrame addAnimation:transition forKey:@"Test"];
//	[ addSubview:webFrame];	
//	[window bringSubviewToFront:webFrame];
	
	[UIView commitAnimations];
	
	// step 13: wait for the animation to complete
	// (more happens after the animation completes)
}


- (void)resizeToWidth:(CGFloat)width
			   height:(CGFloat)height
			inWebView:(UIWebView *)webView
{
	// resize must work within the view hierarchy; all the MRAID ad view does
	// is modify the frame size while leaving the containing application to 
	// determine how this should be presented (animations).
	
	// note: we can only resize if we are in the default state and only to the
	//       limit specified by the maxSize value.
	
	// verify that we can resize
	if ( m_currentState != MRAIDViewStateDefault )
	{
		// we can't resize an expanded ad
		[self usingWebView:webView
		 executeJavascript:@"window.mraidview.fireErrorEvent( 'Cannot resize an ad that is not in the default state.', 'resize' );" ];
		return;
	}
	
	// Make sure the resize honors our limits
	if ( ( height > self.maxSize.height ) ||
		 ( width > self.maxSize.width ) ) 
	{
		// we can't resize outside our limits
		[self usingWebView:webView
		 executeJavascript:@"window.mraidview.fireErrorEvent( 'Cannot resize an ad larger than allowed.', 'resize' );" ];
		return;
	}
	
	// store the original frame
	m_defaultFrame = CGRectMake( self.frame.origin.x, 
								 self.frame.origin.y,
								 self.frame.size.width,
								 self.frame.size.height );
	
	// determine the final frame
	CGSize size = { width, height };
	
	// notify the application that we are starting to resize
	[self fireAdWillResizeToSize:size];
	
	// now update the size
	CGRect newFrame = CGRectMake( self.frame.origin.x, 
								  self.frame.origin.y, 
								  width,
								  height );
	self.frame = newFrame;
	
	// resize the web view as well
	newFrame.origin.x = 0;
	newFrame.origin.y = 0;
    m_webView.frame = newFrame;
	
	// make sure we're on top of everything
	[self.superview bringSubviewToFront:self];
	
	// notify the application that we are done resizing
	[self fireAdDidResizeToSize:size];
	
	// update our state
	self.currentState = MRAIDViewStateResized;
	
	// send state changed event
	[self usingWebView:webView
	 executeJavascript:@"window.mraidview.fireChangeEvent( { state: 'resized', size: { width: %f, height: %f } } );", width, height ];
}


/*
- (void)sendEMailTo:(NSString *)to
		withSubject:(NSString *)subject
		   withBody:(NSString *)body
			 isHTML:(BOOL)html
{
	// make sure that we can send email
	if ( [MFMailComposeViewController canSendMail] )
	{
		MFMailComposeViewController *vc = [[[MFMailComposeViewController alloc] init] autorelease];
		if ( to != nil )
		{
			NSArray *recipients = [NSArray arrayWithObject:to];
			[vc setToRecipients:recipients];
		}
		if ( subject != nil )
		{
			[vc setSubject:subject];
		}
		if ( body != nil )
		{
			[vc setMessageBody:body 
						isHTML:html];
		}
		
		// if we're expanded, our view hierarchy is going to be strange
		// and the modal dialog may come up "under" the expanded web view
		// let's hide it while the modal is up
		if ( self.currentState == MRAIDViewStateExpanded )
		{
			self.hidden = YES;
			m_blockingView.hidden = YES;
		}
		
		// notify the app that it should stop work
		[self fireAppShouldSuspend];

		// display the modal dialog
		vc.mailComposeDelegate = self;
		[self.mraidDelegate.mraidViewController presentModalViewController:vc
																  animated:YES];
	}
	else
	{
		// email isn't setup, let the app decide what to do
		if ( [self.mraidDelegate respondsToSelector:@selector(emailNotSetupForAd:)] )
		{
			[self.mraidDelegate emailNotSetupForAd:self];
		}
	}	
}


- (void)sendSMSTo:(NSString *)to
		 withBody:(NSString *)body
{
	if ( NSClassFromString( @"MFMessageComposeViewController" ) != nil )
	{
		// SMS support does exist
		if ( [MFMessageComposeViewController canSendText] ) 
		{
			// device can
			MFMessageComposeViewController *vc = [[[MFMessageComposeViewController alloc] init] autorelease];
			vc.messageComposeDelegate = self;
			if ( to != nil )
			{
				NSArray *recipients = [NSArray arrayWithObject:to];
				vc.recipients = recipients;
			}
			if ( body != nil )
			{
				vc.body = body;
			}
			
			// if we're expanded, our view hierarchy is going to be strange
			// and the modal dialog may come up "under" the expanded web view
			// let's hide it while the modal is up
			if ( self.currentState == MRAIDViewStateExpanded )
			{
				self.hidden = YES;
				m_blockingView.hidden = YES;
			}
		
			// notify the app that it should stop work
			[self fireAppShouldSuspend];
			
			// now show the dialog
			[self.mraidDelegate.mraidViewController presentModalViewController:vc
																	   animated:YES];
		}
	}
}

- (void) placeClickToApp:(NSString *)urlString
{
    if ( [self.mraidDelegate respondsToSelector:@selector(placeCallToAppStore:)] )
	{
		// consumer wants to deal with it
		[self.mraidDelegate placeCallToAppStore:urlString];
	}
	else
	{
        // handle intenral iTunes requests
        NSURL *url = [NSURL URLWithString:urlString];  
        if ( ( [urlString rangeOfString:@"://itunes.apple.com/"].length > 0 ) || 
            ( [urlString rangeOfString:@"://phobos.apple.com/"].length > 0 ) )
        {
            NSLog( @"Treating URL %@ as call to app store", urlString );
            [self verifyExternalLaunchWithTitle:@"Launch AppStore"
										URL:url];
        }
    }

}


- (void)placeCallTo:(NSString *)phoneNumber
{
	if ( [self.mraidDelegate respondsToSelector:@selector(placePhoneCall:)] )
	{
		// consumer wants to deal with it
		[self.mraidDelegate placePhoneCall:phoneNumber];
	}
	else
	{
		// handle internally
		NSString *urlString = [NSString stringWithFormat:@"tel:%@", phoneNumber];
		NSURL *url = [NSURL URLWithString:urlString];
		NSLog( @"Executing: %@", url );
		[[UIApplication sharedApplication] openURL:url]; 
	}
}


- (void)addEventToCalenderForDate:(NSDate *)date
						withTitle:(NSString *)title
						 withBody:(NSString *)body
{
	if ( [self.mraidDelegate respondsToSelector:@selector(createCalendarEntryForDate:title:body:)] )
	{
		// consumer wants to deal with it
		[self.mraidDelegate createCalendarEntryForDate:date
												 title:title
												  body:body];
	}
	else
	{
		// handle internally
		eventStore = [[EKEventStore alloc] init];
		event = [[EKEvent eventWithEventStore:eventStore] retain];
		event.title = title;
		event.notes = body;
		
		event.startDate = date;
		event.endDate   = [[NSDate alloc] initWithTimeInterval:600 
													 sinceDate:event.startDate];
		[event setCalendar:[eventStore defaultCalendarForNewEvents]];
		
		UIAlertView *addEventAlert = [[UIAlertView alloc] initWithTitle:@"Event Status" 
																		 message:@"Do you wish to save calendar event?" 
																		delegate:self
															   cancelButtonTitle:@"NO" 
															   otherButtonTitles:@"YES", nil];
		addEventAlert.tag = 100;
		[addEventAlert show];
		[addEventAlert release];
	}
}
*/


- (CGRect)getAdFrameInWindowCoordinates
{
	// convertRect should be called not by the MRAIDView but by the parent of the MRAIDView
	CGRect frame = [self.superview convertRect:self.frame toView:self.window];
	return frame;
}


- (void)openBrowser:(UIWebView *)webView
	  withUrlString:(NSString *)urlString
		 enableBack:(BOOL)back
	  enableForward:(BOOL)forward
	  enableRefresh:(BOOL)refresh;
{
	// if the browser is already open, change the URL
	NSLog( @"Open Browser" );
	NSURL *url = [NSURL URLWithString:urlString];
	if ( self.webBrowser != nil )
	{
		// Redirect
		NSLog( @"Redirecting browser to new URL: %@", urlString );
		self.webBrowser.URL = url;
		return;
	}
	
	// notify the app that it should stop work
	[self fireAppShouldSuspend];
	
	// if the expanded view is on screen, hide it so we don't interfere with the full screen
	if ( self.currentState == MRAIDViewStateExpanded )
	{
	   self.hidden = YES;
	   m_blockingView.hidden = YES;
	}

	// display the web browser
	NSLog( @"Create Web Browser" );
	self.webBrowser = [MRAIDWebBrowserViewController mraidWebBrowserViewController];
	NSLog( @"Web Browser created: %@", self.webBrowser );
	self.webBrowser.browserDelegate = self;
	self.webBrowser.backButtonEnabled = back;
	self.webBrowser.forwardButtonEnabled = forward;
	self.webBrowser.refreshButtonEnabled = refresh;
	BOOL safariEnabled = [self.mraidDelegate respondsToSelector:@selector(showURLFullScreen:)];
	self.webBrowser.safariButtonEnabled = safariEnabled;
	self.webBrowser.URL = url;
	[self.mraidDelegate.mraidViewController presentModalViewController:self.webBrowser
															   animated:YES];
}


/*
- (void)openMap:(UIWebView *)webView
  withUrlString:(NSString *)urlString
  andFullScreen:(BOOL)fullscreen
{
    NSLog(@"Open map ");
 //   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
	NSLog( @"Open Browser" );
	NSURL *url = [NSURL URLWithString:urlString];
	if ( self.webBrowser != nil )
	{
		// Redirect
		NSLog( @"Redirecting browser to new URL: %@", urlString );
		self.webBrowser.URL = url;
		return;
	}
	
	// notify the app that it should stop work
	[self fireAppShouldSuspend];
	
	// if the expanded view is on screen, hide it so we don't interfere with the full screen
	if ( self.currentState == MRAIDViewStateExpanded )
	{
		self.hidden = YES;
		m_blockingView.hidden = YES;
	}
	
	// display the web browser
	NSLog( @"Create Web Browser" );
	self.webBrowser = [MRAIDWebBrowserViewController mraidWebBrowserViewController];
	NSLog( @"Web Browser created: %@", self.webBrowser );
	self.webBrowser.browserDelegate = self;
	self.webBrowser.backButtonEnabled = YES;
	self.webBrowser.forwardButtonEnabled = YES;
	self.webBrowser.refreshButtonEnabled = YES;
	BOOL safariEnabled = [self.mraidDelegate respondsToSelector:@selector(showURLFullScreen:)];
	self.webBrowser.safariButtonEnabled = safariEnabled;
	self.webBrowser.URL = url;
	[self.mraidDelegate.mraidViewController presentModalViewController:self.webBrowser
															  animated:YES];
}


- (void)playAudio:(UIWebView *)webView
    withUrlString:(NSString *)urlString
         autoPlay:(BOOL)autoplay
         controls: (BOOL)controls
             loop: (BOOL)loop
           position: (BOOL)position
       startStyle:(NSString *)startStyle
        stopStyle:(NSString *) stopStyle
{
	[self fireAppShouldSuspend];
	
	// if the expanded view is on screen, hide it so we don't interfere with the full screen
	if ( self.currentState == MRAIDViewStateExpanded )
	{
		self.hidden = YES;
		m_blockingView.hidden = YES;
	}
	
	if (position) {
		loop = NO;
		controls = NO;
		stopStyle = @"exit";
		autoplay = YES;
	}
	
	if (loop) {
		stopStyle = @"normal";
		controls = YES;
	}
    
    if (!autoplay)
        controls = YES;
    
    if (!controls)
        stopStyle = @"exit";

	
	MRAIDAVPlayer* temp = [[[MRAIDAVPlayer alloc] initWithFrame:CGRectMake(0, 0, 320, 480)] autorelease];
	temp.delegate = self;
	self.moviePlayer = temp;
	[self.moviePlayer playAudio:[NSURL URLWithString:urlString] attachTo:webView autoPlay:autoplay showControls:controls repeat:loop playInline:position fullScreenMode:[startStyle isEqualToString:@"fullscreen"] ? YES : NO autoExit:[stopStyle isEqualToString:@"normal"] ? NO : YES];
}

- (void)playVideo:(UIWebView *)webView
    withUrlString:(NSString *)urlString
       audioMuted: (BOOL)mutedAudio
         autoPlay:(BOOL)autoplay
         controls: (BOOL)controls
             loop: (BOOL)loop
       position:(int[4]) pos
       startStyle:(NSString *)startStyle
        stopStyle:(NSString *) stopStyle
{
	[self fireAppShouldSuspend];
	
	// if the expanded view is on screen, hide it so we don't interfere with the full screen
	if ( self.currentState == MRAIDViewStateExpanded )
	{
		self.hidden = YES;
		m_blockingView.hidden = YES;
	}
	
	if (loop) {
		stopStyle = @"normal";
		controls = YES;
	}
	
	CGRect position;
	if (pos[0] < 0 || pos[1] < 0 || pos[2] <= 0 || pos[3] <= 0) {
		position = [UIScreen mainScreen].bounds;
		startStyle = @"fullscreen";
	}
	else {
		position = CGRectMake(pos[0],pos[1],pos[2],pos[3]);
	}
    
    if (!autoplay)
        controls = YES;

	if (!controls) {
		stopStyle = @"exit";
	}
	MRAIDAVPlayer* temp = [[[MRAIDAVPlayer alloc] initWithFrame:position] autorelease];
	temp.delegate = self;
	self.moviePlayer = temp;
	[self.moviePlayer playVideo:[NSURL URLWithString:urlString] attachTo:webView autoPlay:autoplay showControls:controls repeat:loop fullScreenMode:[startStyle isEqualToString:@"fullscreen"] ? YES : NO autoExit:[stopStyle isEqualToString:@"normal"] ? NO : YES];
}
*/


- (void)rotateExpandedWindowsToCurrentOrientation
{
    if ( MRAIDViewStateExpanded == self.currentState )
    {
        // MRAIDView takes full screen on expansion
        
        UIApplication *app = [UIApplication sharedApplication];
        CGRect modifiedOriginalFrame = m_originalFrame;
        if(!app.statusBarHidden)
        {
            modifiedOriginalFrame.origin.y += 20; 
        }
        
        // Use device orientation not the statusBarOrientation
        UIInterfaceOrientation orientation = [self currentInterfaceOrientation];
        
        
        [UIView beginAnimations:@"rotate-expanded-ad" context:nil];
        [UIView setAnimationDuration:ROTATION_ANIMATION_DURATION];
        [self rotateExpandedWindowsToOrientation:orientation];
        [UIView commitAnimations];
        CGRect endingFrame = m_expandedFrame;
        UIWindow *keyWindow = [app keyWindow];
        CGRect screenFrame = keyWindow.frame;

        switch (orientation) 
        {
            case UIInterfaceOrientationPortraitUpsideDown:
                endingFrame = CGRectMake(screenFrame.size.width - endingFrame.size.width - endingFrame.origin.x, 
                                         screenFrame.size.height - endingFrame.size.height - endingFrame.origin.y, 
                                         endingFrame.size.width, endingFrame.size.height);
                break;
                
            case UIInterfaceOrientationLandscapeLeft:
                endingFrame = CGRectMake(endingFrame.origin.y, 
                                         screenFrame.size.height - endingFrame.size.width - endingFrame.origin.x, 
                                         endingFrame.size.height, endingFrame.size.width);
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                endingFrame = CGRectMake(screenFrame.size.width - endingFrame.size.height - endingFrame.origin.y, 
                                         endingFrame.origin.x, 
                                         endingFrame.size.height, endingFrame.size.width);
                break;
                
            default:
                endingFrame= m_expandedFrame;
        }
        
        [self alwaysSetFrame:endingFrame];
        m_webView.frame = [self webFrameAccordingToOrientation:endingFrame];
        m_translatedFrame = [self convertedRectAccordingToOrientation:modifiedOriginalFrame];
    }
}


#pragma mark -
#pragma mark Player Control

-(void)playerCompleted
{
	self.moviePlayer = nil;
	
	// if the expanded view should be visible, make it so
	if ( self.currentState == MRAIDViewStateExpanded )
	{
		self.hidden = NO;
		m_blockingView.hidden = NO;
	}

	// called when the ad needs to be made visible
	[self fireAdWillShow];
	
	// notify the app that it should start work
	[self fireAppShouldResume];
	
	// called when the ad needs to be made visible
	[self fireAdDidShow];	
}


#pragma mark -
#pragma mark Web Browser Control

- (void)doneWithBrowser
{
	NSLog( @"Dismissing Browser" );
	[self.mraidDelegate.mraidViewController dismissModalViewControllerAnimated:YES];
  
	self.webBrowser = nil;
	
	// if the expanded view should be visible, make it so
	if ( self.currentState == MRAIDViewStateExpanded )
	{
		self.hidden = NO;
		m_blockingView.hidden = NO;
	}
	
	// called when the ad needs to be made visible
	[self fireAdWillShow];
	
	// notify the app that it should start work
	[self fireAppShouldResume];
	
	// called when the ad needs to be made visible
	[self fireAdDidShow];
  
  //[m_webView reload];
}


- (void)showURLFullScreen:(NSURL *)url
			   sourceView:(UIView *)view
{
	// we want to give the user the opportunity to launch in safari
	if ([self.mraidDelegate respondsToSelector:@selector(showURLFullScreen:sourceView:)])
	{
		[self.mraidDelegate showURLFullScreen:url
								   sourceView:view];
	}
}


#pragma mark -
#pragma mark Animation View Delegate

- (void)animationDidStop:(NSString *)animationID 
				finished:(NSNumber *)finished 
				 context:(void *)context
{
	if ( [animationID isEqualToString:kAnimationKeyCloseExpanded] )
	{
		// finish the close expanded function
		// step 4: restore our frame to the original untranslated frame
		// m_originalFrame might get changed by the host application while the MRAIDView was in the expanded state.
       
        
        
		// step 5: get a handle to the key window
		UIApplication *app = [UIApplication sharedApplication];
		UIWindow *keyWindow = [app keyWindow];
		
		// step 6: get a handle to the previous parent view based on the tag
		UIView *parentView = [keyWindow viewWithTag:m_parentTag];
		
		// step 7: restore the parent view's original tag
		parentView.tag = m_originalTag;
		
		// step 8: add ourselves to the original parent window
		[parentView addSubview:self];
		
		// step 9: remove the blocking view
		[m_blockingView removeFromSuperview], m_blockingView = nil;

		// step 10: moved to after step 13 -- don't signal until after expanded has finished closing
		
		// step 11: update the state to default
		self.currentState = MRAIDViewStateDefault;
		
		// step 12: fire the state changed MRAID event
		[self usingWebView:m_webView
		 executeJavascript:@"window.mraidview.fireChangeEvent( { state: 'default' } );" ];
		
		// step 13: fire the application did close delegate call
		[self fireAdDidClose];
        self.transform = m_originalTransform;
        [self alwaysSetFrame:m_originalFrame];
        self.webView.frame = CGRectMake(0, 0, m_originalFrame.size.width, m_originalFrame.size.height);
        [self setJavascriptDefaultFrame:m_originalFrame];

        // step 10: fire the size changed MRAID event
		[self usingWebView:m_webView
         executeJavascript:@"window.mraidview.fireChangeEvent( { size: { width: %f, height: %f } } );", self.frame.size.width, self.frame.size.height ];
	}
	else
	{
		// finish the expand function
		// step 14: fire the size changed MRAID event
		[self usingWebView:m_webView
		 executeJavascript:@"window.mraidview.fireChangeEvent( { size: { width: %f, height: %f } } );", self.frame.size.width, self.frame.size.height ];
		
		// step 15: update the state to expanded
		self.currentState = MRAIDViewStateExpanded;
		
		// step 16: fire the state changed MRAID event
		[self usingWebView:m_webView
		 executeJavascript:@"window.mraidview.fireChangeEvent( { state: 'expanded' } );" ];

		// step 17: fire the application did expand delegate call
		[self fireAdDidExpandToFrame:m_webView.frame];
	}
}



#pragma mark -
#pragma mark Cache Delegate

- (void)cacheFailed:(NSURL *)baseURL
		  withError:(NSError *)error
{
}


- (void)cachedCreative:(NSURL *)creativeURL
				 onURL:(NSURL *)url
				withId:(NSString*)creativeId
{
	if ( [self.creativeURL isEqual:creativeURL] )
	{
        if (!m_creativeId || ![m_creativeId length])
        {
            // there is no creative currently being displayed (cache has been depleted)
            // force local server to pull it from cache
            [s_localServer cacheURL:creativeURL
                    fromCampaignURL:self.creativeBaseURL
                       withDelegate:self
                    andPreloadCount:0];
        }
	}
}


- (void)currentCachedCreativeChanged:(NSString *)creativeId
{
    // update creative to show
    if(m_creativeId != creativeId)
    {
        [m_creativeId release];
        m_creativeId = [creativeId retain];
    }
}


- (void)showCachedCreative:(NSURL *)creativeURL
                     onURL:(NSURL *)url
                    withId:(NSString *)creativeId
{
    if ( [self.creativeURL isEqual:creativeURL] )
	{
        // force changing current creative
        [self currentCachedCreativeChanged:creativeId];
        
        // now show the cached file
        NSLog(@"show cachedCreative url = %@", url);
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		m_loadingAd = YES;
		[m_webView loadRequest:request];
		[m_webView disableBouncesAndScrolling];
	}
}


- (void)cachedResource:(NSURL *)url
		   forCreative:(NSString*)creativeId
{
	if ( [creativeId isEqualToString:m_creativeId] )
	{
		// TODO
	}
}


- (void)cachedResourceRetired:(NSURL *)url
				  forCreative:(NSString*)creativeId
{
	// TODO
}


- (void)cachedResourceRemoved:(NSURL *)url
				  forCreative:(NSString*)creativeId
{
	// TODO
}


- (NSString *)cachedHtmlForCreative
{
    MRAIDLocalServer *cache = [MRAIDLocalServer sharedInstance];
    return [cache cachedHtmlForCreative:m_creativeId fromCampaignBaseURL:m_creativeBaseURL];
}

// Returns the computed creative id
- (NSString *)creativeId;
{
    return m_creativeId;
}

// get JS to inject
- (NSString *)javascriptForInjection
{
	NSString *js = nil;
	if ( self.mraidDelegate != nil )
	{
		if ( [self.mraidDelegate respondsToSelector:@selector(javascriptForInjection)] )
		{
			js = [self.mraidDelegate javascriptForInjection];
		}
	}
	return js;
}



#pragma mark -
#pragma mark Mail and SMS Composer Delegate

/*
- (void)mailComposeController:(MFMailComposeViewController*)controller 
		  didFinishWithResult:(MFMailComposeResult)result 
						error:(NSError*)error
{
	// notify the app that it should stop work
	[self fireAppShouldResume];
	
	// close the dialog
	[self.mraidDelegate.mraidViewController dismissModalViewControllerAnimated:YES];
	
	// redisplay the expanded view if necessary
	self.hidden = NO;
	m_blockingView.hidden = NO;
}


- (void)messageComposeViewController:(MFMessageComposeViewController *)controller 
				 didFinishWithResult:(MessageComposeResult)result
{
	// notify the app that it should stop work
	[self fireAppShouldResume];
	
	// close the dialog
	[self.mraidDelegate.mraidViewController dismissModalViewControllerAnimated:YES];
	
	// redisplay the expanded view if necessary
	self.hidden = NO;
	m_blockingView.hidden = NO;
}
*/

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
    
}

#pragma mark -
#pragma mark General Actions

- (void)blockingViewTouched:(id)sender
{
	// Restore the ad to it's default size
	[self closeAd:m_webView];
}



#pragma mark -
#pragma mark JavaScript Injection

- (void)injectJavaScriptIntoWebView:(UIWebView *)webView
{
	// notify app that the ad is preparing to show
	[self fireAdWillShow];
	
	// assume we are not an MRAID ad until told otherwise
	NSString *test = [self usingWebView:webView executeJavascript:@"typeof mraidview"];
	self.isMRAIDAd = ( [test isEqualToString:@"object"] );
	
	// always inject the MRAID code
	if ( self.isMRAIDAd )
	{
		NSLog( @"Ad requires MRAID, inject code" );
		[self injectMRAIDJavaScriptIntoWebView:webView];
		
		// now allow the app to inject it's own javascript if needed
		if ( self.mraidDelegate != nil )
		{
			if ( [self.mraidDelegate respondsToSelector:@selector(javascriptForInjection)] )
			{
				NSString *js = [self.mraidDelegate javascriptForInjection];
				[self usingWebView:webView executeJavascript:js];
			}
		}
		
		// now inject the current state
		[self injectMRAIDStateIntoWebView:webView];
		
		// notify the creative that MRAID is done
		m_applicationReady = YES;
		self.isMRAIDAd = YES;
	}
	
	// Notify app that the ad has been shown
	[self fireAdDidShow];
}


- (void)injectMRAIDJavaScriptIntoWebView:(UIWebView *)webView
{
	NSLog( @"Injecting MRAID Javascript into creative." );
//	if ( [self usingWebView:webView 
//		  executeJavascript:s_nativeAPI] == nil )
//	{
//		NSLog( @"Error injecting MRAID Bridge Javascript!" );
//	}
//	if ( [self usingWebView:webView 
//		  executeJavascript:s_publicAPI] == nil )
//	{
//		NSLog( @"Error injecting MRAID Public API Javascript!" );
//	}
}


- (void)injectJavaScriptFile:(NSString *)fileName
				 intoWebView:(UIWebView *)webView
{
	if ( [self usingWebView:webView 
		  executeJavascript:@"var mraidscr = document.createElement('script');mraidscr.src='%@';mraidscr.type='text/javascript';var mraidhd = document.getElementsByTagName('head')[0];mraidhd.appendChild(mraidscr);return 'OK';", fileName] == nil )
	{
		NSLog( @"Error injecting Javascript!" );
	}
}

- (void)injectMRAIDStateIntoWebView:(UIWebView *)webView
{
	NSLog( @"Injecting MRAID State into creative." );
	
	// setup the default state
	self.currentState = MRAIDViewStateDefault;
//	[self fireAdWillShow];
	
	// add the various features the device supports
	NSMutableString *features = [NSMutableString stringWithCapacity:100];
	if ( [MFMailComposeViewController canSendMail] )
	{
		[features appendString:@", 'email'"]; 
	}
	if ( NSClassFromString( @"MFMessageComposeViewController" ) != nil )
	{
		// SMS support does exist
		if ( [MFMessageComposeViewController canSendText] ) 
		{
			[features appendString:@", 'sms'"]; 
		}
	}
	
	// allow LBS if app allows it
	if ( self.allowLocationServices )
	{
		[features appendString:@", 'location'"]; 
	}
	
	NSInteger platformType = [m_currentDevice platformType];
	switch ( platformType )
	{
		case UIDevice1GiPhone:
			[features appendString:@", 'phone'"]; 
			//[features appendString:@", 'camera'"]; 
			break;
		case UIDevice3GiPhone:
			[features appendString:@", 'phone'"]; 
			//[features appendString:@", 'camera'"]; 
			break;
		case UIDevice3GSiPhone:
			[features appendString:@", 'phone'"]; 
			//[features appendString:@", 'camera'"]; 
			break;
		case UIDevice4iPhone:
			[features appendString:@", 'phone'"]; 
			//[features appendString:@", 'camera'"]; 
			[features appendString:@", 'heading'"]; 
			[features appendString:@", 'rotation'"]; 
			break;
		case UIDevice1GiPad:
			[features appendString:@", 'heading'"]; 
			[features appendString:@", 'rotation'"]; 
			break;
		case UIDevice4GiPod:
			//[features appendString:@", 'camera'"]; 
			[features appendString:@", 'rotation'"]; 
			break;
		default:
			break;
	}
	
	// see if calendar support is available
	Class testEventStore = NSClassFromString( @"EKEventStore" );
	if ( testEventStore != nil )
	{
		[features appendString:@", 'calendar'"]; 
	}
	
	// setup the ad size
	CGSize size = m_webView.frame.size;
	
    // setup orientation
    // TODO TBD
    // Some device orientations cannot be used to calculate screen size.
	// Use status bar orientation since it can be only portrait or landscape
    UIApplication *app = [UIApplication sharedApplication];
    UIDeviceOrientation orientation = app.statusBarOrientation;
    NSInteger angle = [self angleFromOrientation:orientation];
    /*UIDeviceOrientation orientation = m_currentDevice.orientation;
    if(UIDeviceOrientationUnknown == orientation)
    {
        orientation = app.statusBarOrientation;
        
    }*/
    
	
	// setup the screen size
    // Some device orientations cannot be used to calculate screen size.
	// Use status bar orientation since it can be only portrait or landscape
    UIInterfaceOrientation interfaceOrientation = app.statusBarOrientation;
    UIDevice *device = [UIDevice currentDevice];
	CGSize screenSize = [device screenSizeForOrientation:interfaceOrientation];	
	
	// get the key window
	UIWindow *keyWindow = [app keyWindow];
	
	// setup the default position information (translated into window coordinates)
	// convertRect should be called not by the MRAIDView but by the parent of the MRAIDView
	CGRect defaultPosition = [self.superview convertRect:self.frame
                                                  toView:keyWindow];	
	
    defaultPosition = [self rectAccordingToOrientation:defaultPosition];
	// determine our network connectivity
	NSString *network = m_javascriptBridge.networkStatus;
	
	// build the initial properties
	NSString *properties = [NSString stringWithFormat:kInitialMRAIDPropertiesFormat, @"default",
                            network,
                            size.width, size.height,
                            self.maxSize.width, self.maxSize.height,
                            screenSize.width, screenSize.height,
                            defaultPosition.origin.x, defaultPosition.origin.y, defaultPosition.size.width, defaultPosition.size.height,
                            angle,
                            features];
	[self usingWebView:webView 
	 executeJavascript:@"window.mraidview.fireChangeEvent( %@ );", properties];
    
    [self fireViewableChange];
	// make sure things are visible
    //	[self fireAdDidShow];
}


#pragma mark -
#pragma mark Delegate Helpers

- (void)fireAdWillShow
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(adWillShow:)] ) )
	{
		[self.mraidDelegate adWillShow:self];
	}
}

- (void)fireAdWillShowCalledFromChildView
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(adWillShow:)] ) )
	{
		[self.mraidDelegate adWillShow:self];
	}
}

- (void)fireAdDidShow
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(adDidShow:)] ) )
	{
		[self.mraidDelegate adDidShow:self];
	}
}


- (void)fireAdWillHide
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(adWillHide:)] ) )
	{
		[self.mraidDelegate adWillHide:self];
	}
}


- (void)fireAdDidHide
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(adDidHide:)] ) )
	{
		[self.mraidDelegate adDidHide:self];
	}
}


- (void)fireAdWillClose
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(adWillClose:)] ) )
	{
		[self.mraidDelegate adWillClose:self];
	}
}


- (void)fireAdDidClose
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(adDidClose:)] ) )
	{
		[self.mraidDelegate adDidClose:self];
	}
}


- (void)fireAdWillResizeToSize:(CGSize)size
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(willResizeAd:toSize:)] ) )
	{
		[self.mraidDelegate willResizeAd:self
								  toSize:size];
	}
}


- (void)fireAdDidResizeToSize:(CGSize)size
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(didResizeAd:toSize:)] ) )
	{
		[self.mraidDelegate didResizeAd:self
								  toSize:size];
	}
}


- (void)fireAdWillExpandToFrame:(CGRect)frame
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(willExpandAd:toFrame:)] ) )
	{
		[self.mraidDelegate willExpandAd:self
								 toFrame:frame];
	}
}


- (void)fireAdDidExpandToFrame:(CGRect)frame
{
	if ( ( self.mraidDelegate != nil ) &&
		( [self.mraidDelegate respondsToSelector:@selector(didExpandAd:toFrame:)] ) )
	{
		[self.mraidDelegate didExpandAd:self
								toFrame:frame];
	}
}


- (void)fireAppShouldSuspend
{
	m_modalityCounter++;
	NSLog( @"Suspend Called, Counter at: %i", m_modalityCounter );
	if ( m_modalityCounter == 1 )
	{
		// notify app on the first call
		NSLog( @"Created first modal view; app should suspend." );
		if ( ( self.mraidDelegate != nil ) &&
			( [self.mraidDelegate respondsToSelector:@selector(appShouldSuspendForAd:)] ) )
		{
			[self.mraidDelegate appShouldSuspendForAd:self];
		}
	}
}

- (void)fireAppShouldSuspendCalledFromChildView
{
	m_modalityCounter++;
	NSLog( @"Suspend Called, Counter at: %i", m_modalityCounter );
	if ( m_modalityCounter == 1 )
	{
		// notify app on the first call
		NSLog( @"Created first modal view; app should suspend." );
		if ( ( self.mraidDelegate != nil ) &&
			( [self.mraidDelegate respondsToSelector:@selector(appShouldSuspendForAd:)] ) )
		{
			[self.mraidDelegate appShouldSuspendForAd:self];
		}
	}
}

- (void)fireAppShouldResume
{
	m_modalityCounter--;
	NSLog( @"Resume Called, Counter at: %i", m_modalityCounter );
	if ( m_modalityCounter == 0 )
	{
		// notify app when we remove the last
		NSLog( @"Removed last modal view; safe to resume." );
		if ( ( self.mraidDelegate != nil ) &&
			( [self.mraidDelegate respondsToSelector:@selector(appShouldResumeFromAd:)] ) )
		{
			[self.mraidDelegate appShouldResumeFromAd:self];
		}
	}
}


- (void)fireAppShouldResumeCalledFromChildView
{
	m_modalityCounter--;
	NSLog( @"Resume Called, Counter at: %i", m_modalityCounter );
	if ( m_modalityCounter == 0 )
	{
		// notify app when we remove the last
		NSLog( @"Removed last modal view; safe to resume." );
		if ( ( self.mraidDelegate != nil ) &&
			( [self.mraidDelegate respondsToSelector:@selector(appShouldResumeFromAd:)] ) )
		{
			[self.mraidDelegate appShouldResumeFromAd:self];
		}
	}
}




#pragma mark -
#pragma mark Utility Methods

- (NSInteger)angleFromOrientation:(UIDeviceOrientation)orientation
{
	NSInteger orientationAngle = -1;
	switch ( orientation )
	{
		case UIDeviceOrientationPortrait:
			orientationAngle = 0;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			orientationAngle = 180;
			break;
		case UIDeviceOrientationLandscapeLeft:
			orientationAngle = 270;
			break;
		case UIDeviceOrientationLandscapeRight:
			orientationAngle = 90;
			break;
		default:
			orientationAngle = -1;
			break;
	}
	return orientationAngle;
}


- (void)callSelectorOnDelegate:(SEL)selector
{
	if ( ( self.mraidDelegate != nil ) &&
 		 ( [self.mraidDelegate respondsToSelector:selector] ) )
	{
		[self.mraidDelegate performSelector:selector
								 withObject:self];
	}
}


+ (void)copyFile:(NSString *)file
		  ofType:(NSString *)type
	  fromBundle:(NSBundle *)bundle
		  toPath:(NSString *)path
{
	NSString *sourcePath = [bundle pathForResource:file
											ofType:type];
	NSAssert( ( sourcePath != nil ), @"Source for file copy does not exist (%@)", file );
	NSString *contents = [NSString stringWithContentsOfFile:sourcePath
												   encoding:NSUTF8StringEncoding
													  error:NULL];
	
	// make sure path exists
	
	NSString *finalPath = [NSString stringWithFormat:@"%@/%@.%@", path, 
																  file, 
																  type];
	NSLog( @"Final Path to JS: %@", finalPath );
	NSError *error;
	if ( ![contents writeToFile:finalPath
					 atomically:YES
					   encoding:NSUTF8StringEncoding
						  error:&error] )
	{
		NSLog( @"Unable to write file '%@', to '%@'. Error is: %@", sourcePath, finalPath, error );
	}
}



- (void)setJavascriptDefaultFrame:(CGRect)frame
{
    if(nil != m_webView)
    {
        // get the key window
        UIApplication *app = [UIApplication sharedApplication];
        UIWindow *keyWindow = [app keyWindow];
        
        // setup the default position information (translated into window coordinates)

        UIView *superView = self.superview;
        if(nil == superView)
        {
            return;
        }
        // convertRect should be called not by the MRAIDView but by the parent of the MRAIDView
        CGRect defaultPosition = [superView convertRect:frame toView:keyWindow];	
        
        defaultPosition = [self rectAccordingToOrientation:defaultPosition];
        
        // build the default position properties
        NSString *properties = [NSString stringWithFormat:kDefaultPositionMRAIDPropertiesFormat,
                                defaultPosition.origin.x, defaultPosition.origin.y, defaultPosition.size.width, defaultPosition.size.height,
                                defaultPosition.size.width, defaultPosition.size.height];
        [self usingWebView:m_webView executeJavascript:@"window.mraidview.fireChangeEvent( %@ );", properties];
    }
}


- (void)fireViewableChange
{
    NSString *isDisplayed = @"false";
    if(m_bIsDisplayed)
    {
        isDisplayed = @"true";
    }
    [self usingWebView:m_webView executeJavascript:@"window.mraidview.fireChangeEvent({viewable:'%@'});", isDisplayed];
}

#pragma mark -
#pragma mark Launch External Locations

-(void)verifyExternalLaunchWithTitle:(NSString *)title
								 URL:(NSURL*)url 
{
	self.launchURL = url;
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title 
													message:@"Application will exit.\nDo you wish to continue?"
												   delegate:self 
										  cancelButtonTitle:@"Cancel" 
										  otherButtonTitles: @"Continue", nil];
	alert.tag = 101;									  
	[alert show];	
	[alert release];
}


- (void)alertView:(UIAlertView *)alertView 
clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView.tag == 100) 
	{
		if (buttonIndex == 1) 
		{
			NSError *err;
			BOOL status = [eventStore saveEvent:event 
										   span:EKSpanThisEvent 
										   error:&err]; 
			if (status)
			{
				UIAlertView *eventSavedSuccessfully = [[UIAlertView alloc] initWithTitle:@"Event Status" 
																				 message:@"Event successfully added." 
																				delegate:nil 
																	   cancelButtonTitle:@"Ok" 
																	   otherButtonTitles:nil];
				[eventSavedSuccessfully show];
				[eventSavedSuccessfully release];
			}
			else 
			{
				UIAlertView *eventSavedUNSuccessfully = [[UIAlertView alloc] initWithTitle:@"Event Status" 
																				   message:@"Event not added." 
																				  delegate:nil 
																		 cancelButtonTitle:@"Ok" 
																		 otherButtonTitles:nil];
				[eventSavedUNSuccessfully show];
				[eventSavedUNSuccessfully release];
			}
		}
		[event release]; event = nil;
		[eventStore release]; eventStore = nil;
	}
	else 
	{
		if ( buttonIndex != alertView.cancelButtonIndex )
		{
			[[UIApplication sharedApplication] openURL:self.launchURL];
		}
		
		self.launchURL = nil;
	}
}



- (void)logFrame:(CGRect)f
			text:(NSString *)text
{
	NSLog( @"%@ :: ( %f, %f ) and ( %f x %f )", text,
												f.origin.x,
												f.origin.y,
												f.size.width,
												f.size.height );
}


#pragma mark -
#pragma mark UIView overrides

- (void)setFrame:(CGRect)frame
{
    // Save the frame that the host application wants us to apply
    // and apply it to the mraidView when it is not in expanded state
    m_originalFrame = frame;
    if( MRAIDViewStateExpanded != self.currentState )
    {
        [super setFrame:m_originalFrame];
        [self setJavascriptDefaultFrame:m_originalFrame];
    }
}


- (void)alwaysSetFrame:(CGRect)frame
{
    [super setFrame:frame];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    
    self.userLocation = [newLocation retain];
}

#pragma mark -
#pragma mark Rotation

- (void)rotateExpandedWindowsToOrientation:(UIInterfaceOrientation)orientation
{
    CGFloat angle = 0.0;
   
    switch (orientation) { 
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI; 
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = - M_PI_2; // / 2.0f;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2; // / 2.0f;
            break;
        default: // as UIInterfaceOrientationPortrait
            angle = 0.0;
            break;
    } 
    self.transform = CGAffineTransformMakeRotation(angle);
}


- (CGRect)webFrameAccordingToOrientation:(CGRect)rect
{
    CGRect webFrame = CGRectZero;
    UIInterfaceOrientation orientation = [self currentInterfaceOrientation];
    if(UIInterfaceOrientationIsPortrait(orientation))
    {
        webFrame = CGRectMake( 0, 0, rect.size.width, rect.size.height );
    }
    else
    {
        webFrame = CGRectMake( 0, 0, rect.size.height, rect.size.width );
    }
    return webFrame;
}


- (CGRect)rectAccordingToOrientation:(CGRect)rect
{
    UIApplication *app = [UIApplication sharedApplication];
    UIWindow      *keyWindow = [app keyWindow];
	CGFloat statusBarHeight = 0;
    if ( !app.statusBarHidden )
	{
        // status bar is visible
        statusBarHeight = 20;
	}
    UIInterfaceOrientation orientation = [self currentInterfaceOrientation];
    switch (orientation) { 
        case UIInterfaceOrientationPortraitUpsideDown:
            rect.origin.y = keyWindow.frame.size.height - rect.origin.y - rect.size.height;
            rect.origin.x = keyWindow.frame.size.width - rect.origin.x - rect.size.width;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rect = CGRectMake(keyWindow.frame.size.height - rect.origin.y - rect.size.height, rect.origin.x, rect.size.height, rect.size.width);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rect = CGRectMake(rect.origin.y, keyWindow.frame.size.width - rect.origin.x - rect.size.width, rect.size.height, rect.size.width);
            break;
        default: // as UIInterfaceOrientationPortrait
            break;
    }
    return rect;
}



- (CGRect)convertedRectAccordingToOrientation:(CGRect)rect
{
    UIApplication *app = [UIApplication sharedApplication];
    UIWindow      *keyWindow = [app keyWindow];
  
    UIInterfaceOrientation orientation = [self currentInterfaceOrientation];
    switch (orientation) { 
        case UIInterfaceOrientationPortraitUpsideDown:
            rect.origin.y = keyWindow.frame.size.height - rect.origin.y - rect.size.height;
            rect.origin.x = keyWindow.frame.size.width - rect.origin.x - rect.size.width;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rect = CGRectMake(rect.origin.y, keyWindow.frame.size.height - rect.origin.x - rect.size.width, rect.size.height, rect.size.width);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rect = CGRectMake(keyWindow.frame.size.width - rect.origin.y - rect.size.height, rect.origin.x, rect.size.height, rect.size.width);
            break;
        default: // as UIInterfaceOrientationPortrait
            break;
    }
    return rect;
}


- (CGSize)statusBarSize:(CGSize)size accordingToOrientation:(UIInterfaceOrientation)orientation
{
    if(UIInterfaceOrientationIsLandscape(orientation))
    {
        size = CGSizeMake(size.height, size.width);
    }
    return size;
}


- (UIInterfaceOrientation)currentInterfaceOrientation
{
    // Use device orientation not the statusBarOrientation because the device orientation is being set more accurately.
    // Important when rapidly rotating the device.
    UIDevice *device = [UIDevice currentDevice];
    UIDeviceOrientation orientation = device.orientation;
    if((UIDeviceOrientationPortrait != orientation) &&
       (UIDeviceOrientationPortraitUpsideDown != orientation) &&
       (UIDeviceOrientationLandscapeLeft != orientation) &&
       (UIDeviceOrientationLandscapeRight != orientation))
    {
        // Orientation is not of the interface orientation.
        UIApplication *app = [UIApplication sharedApplication];
        orientation = app.statusBarOrientation;
        
    }
    return orientation;
}
@end // MRAIDView
