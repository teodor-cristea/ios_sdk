/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <EventKit/EventKit.h>
#import "MRAIDWebBrowserViewController.h"
#import "MRAIDAVPlayer.h"

@class MRAIDJavascriptBridge;
@class ORMMALocalServer;

@protocol MRAIDViewDelegate;
@protocol ORMMAJavascriptBridgeDelegate;

typedef enum MRAIDViewStateEnum
{
	MRAIDViewStateHidden = -1,
	MRAIDViewStateDefault = 0,
	MRAIDViewStateResized,
	MRAIDViewStateExpanded
} MRAIDViewState;



@interface MRAIDView : UIView <MFMailComposeViewControllerDelegate,
							   MFMessageComposeViewControllerDelegate,
							   MRAIDWebBrowserViewControllerDelegate,
								MRAIDAVPlayerDelegate>
{
@private
	UIDevice *m_currentDevice;
	MRAIDJavascriptBridge *m_javascriptBridge;
	id<MRAIDViewDelegate> m_mraidDelegate;
	MRAIDViewState m_currentState;
	NSError *m_lastError;
	BOOL m_adVisible;
	
	// for resize
	CGSize m_maxSize;

	UIWebView *m_webView;
	
	CGRect m_defaultFrame;
	
	CGRect m_translatedFrame;
	NSInteger m_originalTag;
	NSInteger m_parentTag;
	
	UIButton *m_blockingView;
	
	MRAIDWebBrowserViewController *m_webBrowser;
	MRAIDAVPlayer *m_moviePlayer;
	
	NSURL *m_creativeURL;
	NSString *m_creativeId;	

	BOOL m_applicationReady;
	
	BOOL m_allowLocationServices;
	
	BOOL m_isMRIADAd;
	NSURL *m_launchURL;
	BOOL m_loadingAd;
	
	NSInteger m_modalityCounter;
    
	
	NSMutableArray *m_externalProtocols;
	BOOL allowAdOrientation;
	
	EKEventStore *eventStore;
	EKEvent *event;
    
    // Save the frame that the host application wants us to apply
    // and apply it to the mraidView when it is not in expanded state
    CGRect m_originalFrame;
    CGAffineTransform m_originalTransform;
    // The MRAIDView frame in the expanded state
    CGRect m_expandedFrame;
    BOOL m_bIsDisplayed;
}
@property( nonatomic, assign ) id<MRAIDViewDelegate> mraidDelegate;
@property( nonatomic, copy ) NSString *htmlStub;
@property( nonatomic, copy ) NSURL *creativeURL;
@property( nonatomic, retain, readonly ) NSError *lastError;
@property( nonatomic, assign, readonly ) MRAIDViewState currentState;
@property( nonatomic, assign ) CGSize maxSize;
@property( nonatomic, assign ) BOOL allowLocationServices;
@property( nonatomic, assign, readonly ) BOOL isMRAIDAd;

// load creative
- (void)loadCreative:(NSURL *)url;

//Begin: Added for customization by Raju on 26-July-2012
- (void)loadCreative:(NSURL *)url 
        withUsername:(NSString *)username 
         andPassword:(NSString *)password;
//End: Added for customization by Raju on 26-July-2012         

- (void)loadHTMLCreative:(NSString *)htmlFragment
			 creativeURL:(NSURL *)url;

// registers a protocol scheme for external handling
- (void)registerProtocol:(NSString *)protocol;

// removes a protocol scheme from external handling
- (void)deregisterProtocol:(NSString *)protocol;


// used to force an ad to revert to its default state
- (void)restoreToDefaultState;


- (void)doneWithBrowser;


// Returns the html string for the current creative
- (NSString *)cachedHtmlForCreative;

// Returns the computed creative id
- (NSString *)creativeId;


// These method let the app indicate whether it considers the MRAIDView to be visible or not.
// This is useful when MRAIDView are embedded in a scrolling view and need to be loaded in advance.
// Calling these method will let the MRAIDView set the proper default ad position based on the currently displayed view.
- (void)mraidViewDisplayed:(BOOL)isDisplayed;
@end



@protocol MRAIDViewDelegate <NSObject>

@required

// retrieves the owning view controller
- (UIViewController *)mraidViewController;


@optional

// called to allow the application to inject javascript into the creative
- (NSString *)javascriptForInjection;

// notifies the consumer that it should handle the specified request
// NOTE: REQUIRED IF A PROTOCOL IS REGISTERED
- (void)handleRequest:(NSURLRequest *)request
				forAd:(MRAIDView *)adView;


// called to allow the application to execute javascript on the creative at the
// time the creative is loaded
- (NSString *)onLoadJavaScriptForAd:(MRAIDView *)adView;

// called when an ad fails to load
- (void)failureLoadingAd:(MRAIDView *)adView;

// Called before the ad is resized in place to allow the parent application to
// animate things if desired.
- (void)willResizeAd:(MRAIDView *)adView
			  toSize:(CGSize)size;

// Called after the ad is resized in place to allow the parent application to
// animate things if desired.
- (void)didResizeAd:(MRAIDView *)adView
			  toSize:(CGSize)size;



// Called just before to an ad is displayed
- (void)adWillShow:(MRAIDView *)adView;

// Called just after to an ad is displayed
- (void)adDidShow:(MRAIDView *)adView;

// Called just before to an ad is Hidden
- (void)adWillHide:(MRAIDView *)adView;

// Called just after to an ad is Hidden
- (void)adDidHide:(MRAIDView *)adView;

// Called just before an ad expands
- (void)willExpandAd:(MRAIDView *)adView
			 toFrame:(CGRect)frame;

// Called just after an ad expands
- (void)didExpandAd:(MRAIDView *)adView
			toFrame:(CGRect)frame;

// Called just before an ad closes
- (void)adWillClose:(MRAIDView *)adView;

// Called just after an ad closes
- (void)adDidClose:(MRAIDView *)adView;

// called when the ad will begin heavy content (usually when the ad goes full screen)
- (void)appShouldSuspendForAd:(MRAIDView *)adView;

// called when the ad is finished with it's heavy content (usually when the ad returns from full screen)
- (void)appShouldResumeFromAd:(MRAIDView *)adView;

/*
// allows the application to override the phone call process to, for example
// display an alert to the user before hand
- (void)placePhoneCall:(NSString *)number;

// allows the application to override the click to app store, for example
// display an alert to the user before hand
- (void)placeCallToAppStore:(NSString *)urlString;

// allows the application to override the create calendar event process to, for 
// example display an alert to the user before hand
- (void)createCalendarEntryForDate:(NSDate *)date
							 title:(NSString *)title
							  body:(NSString *)body;
*/                

// allows the application to inject itself into the full screen browser menu 
// to handle the "go" method (for example, send to safari, facebook, etc)
- (void)showURLFullScreen:(NSURL *)url
			   sourceView:(UIView *)view;

- (void)emailNotSetupForAd:(MRAIDView *)adView;


@end
