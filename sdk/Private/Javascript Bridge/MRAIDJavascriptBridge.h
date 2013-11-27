/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>



@protocol MRAIDJavascriptBridgeDelegate;

@class Reachability;

@interface MRAIDJavascriptBridge : NSObject <UIAccelerometerDelegate,
											 CLLocationManagerDelegate>
{
@private
	id<MRAIDJavascriptBridgeDelegate> __weak m_bridgeDelegate;
	
	Reachability *m_reachability;
	CLLocationManager *m_locationManager;
	CMMotionManager *m_motionManager;
    
    // suppress warning for deprecated UIAccelerometer
#       pragma clang diagnostic push
#       pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIAccelerometer *m_accelerometer;
#       pragma clang diagnostic pop

	NSTimer *m_timer;
	
	BOOL m_accelerometerEnableCount;
	BOOL m_compassEnableCount;
	BOOL m_gyroscopeEnableCount;
	BOOL m_locationEnableCount;
	
	BOOL m_processAccelerometer;
	BOOL m_processShake;
	CGFloat m_shakeIntensity;
}
@property( nonatomic, weak ) id<MRAIDJavascriptBridgeDelegate> bridgeDelegate;
@property( nonatomic, strong ) CMMotionManager *motionManager;
@property( nonatomic, copy, readonly ) NSString *networkStatus;



// parses the passed URL; if it is handleable by the bridge, it will be handled 
// otherwise no action will be taken
// returns- TRUE  if the URL was processed, FALSE otherwise
- (BOOL)processURL:(NSURL *)url
		forWebView:(UIWebView *)webView;


- (void)restoreServicesToDefaultState;

@end



@protocol MRAIDJavascriptBridgeDelegate

@required

@property( nonatomic, assign, readonly ) UIWebView *webView;

- (void)adIsMRAIDEnabledForWebView:(UIWebView *)webView;

- (NSString *)usingWebView:(UIWebView *)webView
		 executeJavascript:(NSString *)javascript, ...;

- (void)showAd:(UIWebView *)webView;
- (void)hideAd:(UIWebView *)webView;

- (void)closeAd:(UIWebView *)webView;

- (void)openBrowser:(UIWebView *)webView
	  withUrlString:(NSString *)urlString
		 enableBack:(BOOL)back
	  enableForward:(BOOL)forward
	  enableRefresh:(BOOL)refresh;

/*- (void)openMap:(UIWebView *)webView
	  withUrlString:(NSString *)urlString
		 andFullScreen:(BOOL)fullscreen;

- (void)playAudio:(UIWebView *)webView
    withUrlString:(NSString *)urlString
         autoPlay:(BOOL)autoplay
         controls: (BOOL)controls
             loop: (BOOL)loop
           position: (BOOL)position
       startStyle:(NSString *)startStyle
        stopStyle:(NSString *) stopStyle;

- (void)playVideo:(UIWebView *)webView
    withUrlString:(NSString *)urlString
       audioMuted: (BOOL)mutedAudio
         autoPlay:(BOOL)autoplay
         controls: (BOOL)controls
             loop: (BOOL)loop
       position:(int[4]) pos
       startStyle:(NSString *)startStyle
        stopStyle:(NSString *) stopStyle;
*/        

- (void)resizeToWidth:(CGFloat)width
			   height:(CGFloat)height
	   inWebView:(UIWebView *)webView;

- (void)expandTo:(CGRect)newFrame
		 withURL:(NSURL *)url
	   inWebView:(UIWebView *)webView
   blockingColor:(UIColor *)blockingColor
 blockingOpacity:(CGFloat)blockingOpacity
 lockOrientation:(BOOL)allowOrientationChange;

/*
- (void)sendEMailTo:(NSString *)to
		withSubject:(NSString *)subject
		   withBody:(NSString *)body
			 isHTML:(BOOL)html;
- (void)sendSMSTo:(NSString *)to
		 withBody:(NSString *)body;
- (void)placeCallTo:(NSString *)phoneNumber;
- (void)addEventToCalenderForDate:(NSDate *)date
						withTitle:(NSString *)title
						 withBody:(NSString *)body;
*/             

- (CGRect)getAdFrameInWindowCoordinates;

- (void)rotateExpandedWindowsToCurrentOrientation;

- (CGRect)rectAccordingToOrientation:(CGRect)rect;

@end