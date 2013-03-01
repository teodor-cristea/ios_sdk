/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <MessageUI/MessageUI.h>
#import "MRAIDJavascriptBridge.h"
#import "Reachability.h"
#import "UIColor-Expanded.h"
#import "UIDevice-MRAID.h"



@interface MRAIDJavascriptBridge ()

@property( nonatomic, retain ) Reachability *reachability;

- (NSDictionary *)parametersFromJSCall:(NSString *)parameterString;
- (BOOL)processCommand:(NSString *)command
			parameters:(NSDictionary *)parameters
			forWebView:(UIWebView *)webView;
- (BOOL)processMRAIDEnabledCommand:(NSDictionary *)parameters
						forWebView:(UIWebView *)webView;
- (BOOL)processCloseCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView;
- (BOOL)processExpandCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView;
- (BOOL)processHideCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView;
- (BOOL)processResizeCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView;
- (BOOL)processServiceCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView;
- (BOOL)processShowCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView;
- (BOOL)processOpenCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView;
/*        
- (BOOL)processOpenMapCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView;
- (BOOL)processPlayAudioCommand:(NSDictionary *)parameters
                   forWebView:(UIWebView *)webView;
- (BOOL)processPlayVideoCommand:(NSDictionary *)parameters
                     forWebView:(UIWebView *)webView;
*/
- (BOOL)processRequestCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView;
/*           
- (BOOL)processCalendarCommand:(NSDictionary *)parameters
					forWebView:(UIWebView *)webView;
- (BOOL)processCameraCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView;
- (BOOL)processEMailCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView;
- (BOOL)processPhoneCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView;
- (BOOL)processSMSCommand:(NSDictionary *)parameters
			   forWebView:(UIWebView *)webView;
- (BOOL)processAddAssetCommand:(NSDictionary *)parameters
					forWebView:(UIWebView *)webView;
- (BOOL)processRemoveAssetCommand:(NSDictionary *)parameters
					   forWebView:(UIWebView *)webView;
- (BOOL)processRemoveAllAssetsCommand:(NSDictionary *)parameters
						   forWebView:(UIWebView *)webView;
*/

- (CGFloat)floatFromDictionary:(NSDictionary *)dictionary
						forKey:(NSString *)key;
- (int)intFromDictionary:(NSDictionary *)dictionary
						forKey:(NSString *)key;
- (CGFloat)floatFromDictionary:(NSDictionary *)dictionary
						forKey:(NSString *)key
				   withDefault:(CGFloat)defaultValue; 
- (NSString *)requiredStringFromDictionary:(NSDictionary *)dictionary
									forKey:(NSString *)key;
- (BOOL)booleanFromDictionary:(NSDictionary *)dictionary
					   forKey:(NSString *)key;

@end




@implementation MRAIDJavascriptBridge


#pragma mark -
#pragma mark Constants

// the protocol to use to identify the MRAID request
NSString * const MRAIDProtocol = @"mraid://";

NSString * const MRAIDCommandMRAIDEnabled = @"mraidenabled";

NSString * const MRAIDCommandShow = @"show";
NSString * const MRAIDCommandHide = @"hide";
NSString * const MRAIDCommandClose = @"close";

NSString * const MRAIDCommandExpand = @"expand";
NSString * const MRAIDCommandResize = @"resize";

NSString * const MRAIDCommandAddAsset = @"addasset";
NSString * const MRAIDCommandRemoveAsset = @"removeasset";
NSString * const MRAIDCommandRemoveAllAssets = @"removeallassets";

NSString * const MRAIDCommandCalendar = @"calendar";
NSString * const MRAIDCommandCamera = @"camera";
NSString * const MRAIDCommandEMail = @"email";
NSString * const MRAIDCommandPhone = @"phone";
NSString * const MRAIDCommandSMS = @"sms";

NSString * const MRAIDCommandOpen = @"open";
NSString * const MRAIDCommandOpenMap = @"openmap";
NSString * const MRAIDCommandPlayAudio = @"playaudio";
NSString * const MRAIDCommandPlayVideo = @"playvideo";
NSString * const MRAIDCommandRequest = @"request";

NSString * const MRAIDCommandService = @"service";

const CGFloat kDefaultShakeIntensity = 1.5;




#pragma mark -
#pragma mark Properties

@synthesize bridgeDelegate = m_bridgeDelegate;
@synthesize reachability = m_reachability;
@synthesize motionManager = m_motionManager;
@dynamic networkStatus;



#pragma mark -
#pragma mark Initializers / Memory Management

- (MRAIDJavascriptBridge *)init
{
	if ( ( self = [super init] ) )
	{
		// set ourselves up for location based services
		m_locationManager = [[CLLocationManager alloc] init];
        m_locationManager.delegate = self;
		m_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		
		// set the default shake intensity
		m_shakeIntensity = kDefaultShakeIntensity;
		
		// check for the availability of Core Motion
		if ( NSClassFromString( @"CMMotionManager" ) != nil )
		{
			self.motionManager = [[[CMMotionManager alloc] init] autorelease];
		}
		
		// setup our network reachability
		self.reachability = [Reachability reachabilityForInternetConnection];

		// make sure to register for the events that we care about
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self
							   selector:@selector(orientationChanged:)
								   name:UIDeviceOrientationDidChangeNotification
								 object:nil];
		[notificationCenter addObserver:self 
							   selector:@selector(keyboardWillShow:) 
								   name:UIKeyboardWillShowNotification
								 object:nil];
		[notificationCenter addObserver:self 
							   selector:@selector(keyboardWillHide:) 
								   name:UIKeyboardWillHideNotification
								 object:nil];
		[notificationCenter addObserver:self
							   selector:@selector(handleReachabilityChangedNotification:)
								   name:kReachabilityChangedNotification
								 object:nil];
	
		// start up reachability notifications
		[self.reachability startNotifier];
	}
	return self;
}


- (void)dealloc
{
	// stop listening for notifications
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
	
	[self restoreServicesToDefaultState];
	
	[m_timer invalidate], m_timer = nil;
	m_bridgeDelegate = nil;
	m_accelerometer.delegate = nil,[m_accelerometer release], m_accelerometer = nil;
	[m_locationManager release], m_locationManager = nil;
	[self.motionManager stopGyroUpdates], self.motionManager = nil;
	[super dealloc];
}



#pragma mark -
#pragma mark Dynamic Properties

- (NSString *)networkStatus
{
	NetworkStatus ns = [self.reachability currentReachabilityStatus];
	switch ( ns )
	{
		case ReachableViaWWAN:
			return @"cell";
		case ReachableViaWiFi:
			return @"wifi";
	}
	return @"offline";
}


#pragma mark -
#pragma mark Process

- (BOOL)processURL:(NSURL *)url
		forWebView:(UIWebView *)webView
{
	NSString *workingUrl = [url absoluteString];
	if ( [workingUrl hasPrefix:MRAIDProtocol] )
	{
		// the URL is intended for the bridge, so process it
		NSString *workingCall = [workingUrl substringFromIndex:MRAIDProtocol.length];
		
		// get the command
		NSRange r = [workingCall rangeOfString:@"?"];
		if ( r.location == NSNotFound )
		{
			// just a command
			return [self processCommand:workingCall 
							 parameters:nil
							 forWebView:webView];
		}
		NSString *command = [[workingCall substringToIndex:r.location] lowercaseString];
		NSString *parameterValues = [workingCall substringFromIndex:( r.location + 1 )];
		NSDictionary *parameters = [self parametersFromJSCall:parameterValues];
		NSLog( @"MRAID Command: %@, %@", command, parameters );
		
		// let the callee know
		return [self processCommand:command 
						 parameters:parameters
						 forWebView:webView];
	}
	
	// not intended for the bridge
	return NO;
}


- (NSDictionary *)parametersFromJSCall:(NSString *)parameterString
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	
	// find the start of our parameters
	NSArray *parameterList = [parameterString componentsSeparatedByString:@"&"];
	for ( NSString *parameterEntry in parameterList )
	{
		NSArray *kvp = [parameterEntry componentsSeparatedByString:@"="];
		NSString *key = [kvp objectAtIndex:0];
		NSString *encodedValue = [kvp objectAtIndex:1];
		NSString *value = [encodedValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];;
		[parameters setObject:value forKey:key];
	}
	
	return parameters;
}


- (BOOL)processCommand:(NSString *)command
			parameters:(NSDictionary *)parameters
			forWebView:(UIWebView *)webView
{
	BOOL processed = NO;
	if ( [command isEqualToString:MRAIDCommandMRAIDEnabled] )
	{
		// process close
		processed = [self processMRAIDEnabledCommand:parameters
										  forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandClose] )
	{
		// process close
		processed = [self processCloseCommand:parameters
								   forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandExpand] )
	{
		// process hide
		processed = [self processExpandCommand:parameters
									forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandHide] )
	{
		// process hide
		processed = [self processHideCommand:parameters
							 forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandResize] )
	{
		// process resize
		processed = [self processResizeCommand:parameters
							   forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandService] )
	{
		// process service
		processed = [self processServiceCommand:parameters
								forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandShow] )
	{
		// process show
		processed = [self processShowCommand:parameters
								  forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandAddAsset] )
	{
		// process show
		processed = [self processAddAssetCommand:parameters
									  forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandRemoveAsset] )
	{
		// process show
		processed = [self processRemoveAssetCommand:parameters
										 forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandRemoveAllAssets] )
	{
		// process show
		processed = [self processRemoveAllAssetsCommand:parameters
											 forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandOpen] )
	{
		// process show
		processed = [self processOpenCommand:parameters
								  forWebView:webView];
	}
/*  else if ( [command isEqualToString:MRAIDCommandOpenMap] )
	{
		// process show
		processed = [self processOpenMapCommand:parameters
								  forWebView:webView];
	}	
    else if ( [command isEqualToString:MRAIDCommandPlayAudio] )
	{
		// process show
		processed = [self processPlayAudioCommand:parameters
                                     forWebView:webView];
	}	
    else if ( [command isEqualToString:MRAIDCommandPlayVideo] )
	{
		// process show
		processed = [self processPlayVideoCommand:parameters
                                       forWebView:webView];
	}    */
    else if ( [command isEqualToString:MRAIDCommandRequest] )
	{
		// process show
		processed = [self processRequestCommand:parameters
									 forWebView:webView];
	}
/*	else if ( [command isEqualToString:MRAIDCommandCalendar] )
	{
		// process show
		processed = [self processCalendarCommand:parameters
									  forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandCamera] )
	{
		// process show
		processed = [self processCameraCommand:parameters
									forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandEMail] )
	{
		// process show
		processed = [self processEMailCommand:parameters
								   forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandPhone] )
	{
		// process show
		processed = [self processPhoneCommand:parameters
								   forWebView:webView];
	}
	else if ( [command isEqualToString:MRAIDCommandSMS] )
	{
		// process show
		processed = [self processSMSCommand:parameters
								 forWebView:webView];
	}*/
	
	if ( !processed ) 
	{
		NSLog( @"Unknown Command: %@", command );
	}

	// notify JS that we've completed the last request
	[self.bridgeDelegate usingWebView:webView
					executeJavascript:@"window.mraidview.nativeCallComplete( '%@' );", command];

	return processed;
}


- (BOOL)processMRAIDEnabledCommand:(NSDictionary *)parameters
						forWebView:(UIWebView *)webView
{
	NSLog( @"Processing MRAIDENABLED Command..." );
	[self.bridgeDelegate adIsMRAIDEnabledForWebView:webView];
	return YES;
}


- (BOOL)processShowCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView
{
	NSLog( @"Processing SHOW Command..." );
	[self.bridgeDelegate showAd:webView];
	return YES;
}


- (BOOL)processHideCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView
{
	NSLog( @"Processing HIDE Command..." );
	[self.bridgeDelegate hideAd:webView];
	return YES;
}


- (BOOL)processCloseCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView
{
	NSLog( @"Processing CLOSE Command..." );
	[self.bridgeDelegate closeAd:webView];
	return YES;
}


- (BOOL)processExpandCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView
{
	NSLog( @"Processing EXPAND Command..." );
	
	// account for status bar, if needed
	CGFloat yDelta = 0;
	UIApplication *app = [UIApplication sharedApplication];
	// Height and width must be swapped for landscape orientation
    if ( !app.statusBarHidden )
	{
        if(app.statusBarFrame.size.height < app.statusBarFrame.size.width)
        {
            yDelta = app.statusBarFrame.size.height;
        }
        else
        {
            yDelta = app.statusBarFrame.size.width;
        }
	}
	
	// ok, to make it easy on the client, we don't require them to give us all
	// the values all the time.
	// basicallly we're going to take the current real frame information from
	// the ad (translated to window space coordinates) and set the final frame
	// to this information. Then for each data point we receive from the client,
	// we override the appropriate value. this allows the client to say things
	// like "using the current ad position, expand the ad's height to 300px"
	CGRect f = [self.bridgeDelegate getAdFrameInWindowCoordinates];
    
    // Get the current ad rectangle that is actually presented to the client, regardless of the rotation,
    // since the app keyWindow does not rotate. 
    CGRect fNotRotated = [self.bridgeDelegate rectAccordingToOrientation:f];
    
	CGFloat x = fNotRotated.origin.x;
	CGFloat y = fNotRotated.origin.y;
	CGFloat w = fNotRotated.size.width;
	CGFloat h = fNotRotated.size.height;
  h = 250;

	// now get the sizes as specified by the creative
	x = [self floatFromDictionary:parameters
						   forKey:@"x"
					  withDefault:x];
	y = [self floatFromDictionary:parameters
						   forKey:@"y"
					  withDefault:y];
	w = [self floatFromDictionary:parameters
						   forKey:@"w"
					  withDefault:w];
	h = [self floatFromDictionary:parameters
						   forKey:@"h"
					  withDefault:h];
	
	BOOL useBG = [self booleanFromDictionary:parameters
									  forKey:@"useBG"];
	UIColor *blockerColor = [UIColor blackColor];
	CGFloat bgOpacity = 0.20;
	if ( useBG )
	{
		NSString *value = [parameters objectForKey:@"bgColor"];
		if ( value != nil ) 
		{
			value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ( value.length > 0 )
			{
				// we have what "should" be a color
				if ( [value hasPrefix:@"#"] ) 
				{
					// hex color
					blockerColor = [UIColor colorWithName:[value substringFromIndex:1]];
				}
				else
				{
					// assume it's a named color
					blockerColor = [UIColor colorWithName:value];
				}
			}
		}
		bgOpacity = [self floatFromDictionary:parameters
									   forKey:@"bgOpacity"
								  withDefault:1.0];
	}
	
//	NSString *urlString = [parameters valueForKey:@"url"];
	//NSURL *url = [NSURL URLWithString:urlString];
  NSURL *url = [NSURL URLWithString:@"http://www.google.com/"];
	NSLog( @"Expanding to ( %f, %f ) ( %f x %f ) showing %@", x, y, w, h, url );
    // The newFrame is the not rotated frame. The callee has to take the current rotation into consideration.
	CGRect newFrame = CGRectMake( x, ( y + yDelta ), w, h );
	BOOL allowOrientation = [self booleanFromDictionary:parameters forKey:@"lockOrientation"];
	[self.bridgeDelegate expandTo:newFrame
						  withURL:url
						inWebView:webView
					blockingColor:blockerColor
				  blockingOpacity:bgOpacity
				  lockOrientation:allowOrientation];
	return YES;
}


- (BOOL)processResizeCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView
{
	NSLog( @"Processing RESIZE Command..." );
	
	// get the new bounds
	CGFloat w = [self floatFromDictionary:parameters
								   forKey:@"w"];
	CGFloat h = [self floatFromDictionary:parameters
								   forKey:@"h"];
	[self.bridgeDelegate resizeToWidth:w
								height:h
							 inWebView:webView];
	return YES;
}


- (BOOL)processAddAssetCommand:(NSDictionary *)parameters
					forWebView:(UIWebView *)webView
{
	NSLog( @"Processing ADD ASSET Command..." );
	return YES;
}


- (BOOL)processRemoveAssetCommand:(NSDictionary *)parameters
					   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing REMOVE ASSET Command..." );
	return YES;
}


- (BOOL)processRemoveAllAssetsCommand:(NSDictionary *)parameters
						   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing REMOVE ALL ASSETS Command..." );
	return YES;
}

	
- (BOOL)processOpenCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView
{
	NSLog( @"Processing OPEN Command..." );
	NSString *url = [self requiredStringFromDictionary:parameters 
												forKey:@"url"];
	BOOL back = [self booleanFromDictionary:parameters
									 forKey:@"back"];
	BOOL forward = [self booleanFromDictionary:parameters
										forKey:@"forward"];
	BOOL refresh = [self booleanFromDictionary:parameters
										forKey:@"refresh"];
	[self.bridgeDelegate openBrowser:webView 
					   withUrlString:url 
						  enableBack:back 
					   enableForward:forward 
					   enableRefresh:refresh];
	return YES;
}

/*
- (BOOL)processOpenMapCommand:(NSDictionary *)parameters
			        	forWebView:(UIWebView *)webView
{
	NSLog( @"Processing OPEN MAP Command..." );
	NSString *url = [self requiredStringFromDictionary:parameters 
												forKey:@"url"];
	BOOL fullscreen = [self booleanFromDictionary:parameters
									 forKey:@"fullscreen"];
	
	[self.bridgeDelegate openMap:webView 
                         withUrlString:url 
                         andFullScreen:fullscreen 
                        ];
	return YES;
}


- (BOOL)processPlayAudioCommand:(NSDictionary *)parameters
                   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing OPEN MAP Command..." );
    
	NSString *url = [self requiredStringFromDictionary:parameters 
												forKey:@"url"];
    
	BOOL autoplay = [self booleanFromDictionary:parameters
                                           forKey:@"autoplay"];
    
    BOOL controls = [self booleanFromDictionary:parameters
                                         forKey:@"controls"];    
    
    BOOL loop = [self booleanFromDictionary:parameters
                                         forKey:@"loop"]; 
    
    
    BOOL position = [self booleanFromDictionary:parameters
                                        forKey:@"position"];   
    
    NSString* startStyle = [self requiredStringFromDictionary:parameters
                                       forKey:@"startStyle"];
    
    NSString* stopStyle = [self requiredStringFromDictionary:parameters
                                                       forKey:@"stopStyle"];    
	
	[self.bridgeDelegate playAudio:webView 
                   withUrlString:url 
                   autoPlay:autoplay
                   controls: controls
                   loop: loop
                   position: position
                   startStyle: startStyle
                   stopStyle: stopStyle
    ];
    
	return YES;
}

- (BOOL)processPlayVideoCommand:(NSDictionary *)parameters
                     forWebView:(UIWebView *)webView
{
	NSLog( @"Processing OPEN MAP Command..." );
    
	NSString *url = [self requiredStringFromDictionary:parameters 
												forKey:@"url"];
    
    BOOL mutedAudio = [self booleanFromDictionary:parameters
                                         forKey:@"audioMuted"];    
    
	BOOL autoplay = [self booleanFromDictionary:parameters
                                         forKey:@"autoplay"];
    
    BOOL controls = [self booleanFromDictionary:parameters
                                         forKey:@"controls"];    
    
    BOOL loop = [self booleanFromDictionary:parameters
                                     forKey:@"loop"]; 
    
    
    int position_top = [self intFromDictionary:parameters
                                       forKey:@"position_top"];  
    
    int position_left = [self intFromDictionary:parameters
                                      forKey:@"position_left"];   
    
    int position_width = [self intFromDictionary:parameters
                                       forKey:@"position_width"];
    
    int position_height = [self intFromDictionary:parameters
                                       forKey:@"position_height"];     
    
    NSString* startStyle = [self requiredStringFromDictionary:parameters
                                                       forKey:@"startStyle"];
    
    NSString* stopStyle = [self requiredStringFromDictionary:parameters
                                                      forKey:@"stopStyle"];    
	
	[self.bridgeDelegate playVideo:webView 
                     withUrlString:url 
                        audioMuted: mutedAudio
                          autoPlay:autoplay
                          controls: controls
                              loop: loop
                        position: (int[4]) {position_top, position_left, position_width, position_height}
                        startStyle: startStyle
                         stopStyle: stopStyle
     ];
    
	return YES;
}
*/

- (BOOL)processRequestCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing REQUEST Command..." );
	return YES;
}

- (BOOL)processServiceCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView
{
    return YES;
}
/*
- (BOOL)processCalendarCommand:(NSDictionary *)parameters
					forWebView:(UIWebView *)webView
{
	NSString *dateString = [self requiredStringFromDictionary:parameters 
													   forKey:@"date"];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMddHHmm"];
	NSDate *date = [formatter dateFromString:dateString];
	
	NSString *title = [self requiredStringFromDictionary:parameters 
												  forKey:@"title"];
	NSString *body = [self requiredStringFromDictionary:parameters 
												 forKey:@"body"];
	NSLog( @"Processing CALENDAR Command for %@ / %@ / %@", date, title, body );
	if ( ( date != nil ) && 
		 ( title != nil ) && 
		 ( body != nil ) )
	{
		[self.bridgeDelegate addEventToCalenderForDate:date
											 withTitle:title
											  withBody:body];
	}
	[formatter release];
	return YES;
}


- (BOOL)processCameraCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView
{
	NSLog( @"Processing CAMERA Command..." );
	
	return YES;
}


- (BOOL)processEMailCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView
{
	NSLog( @"Processing EMAIL Command..." );
	NSString *to = [self requiredStringFromDictionary:parameters 
											   forKey:@"to"];
	NSString *subject = [self requiredStringFromDictionary:parameters 
													forKey:@"subject"];
	NSString *body = [self requiredStringFromDictionary:parameters 
												 forKey:@"body"];
	BOOL html = [self booleanFromDictionary:parameters 
									 forKey:@"html"];
	if ( ( body != nil ) && 
		 ( to != nil ) && 
		 ( subject != nil ) )
	{
		[self.bridgeDelegate sendEMailTo:to
							 withSubject:subject
								withBody:body
								  isHTML:html];
	}
	return YES;
}


- (BOOL)processPhoneCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView
{
	NSString *phoneNumber = [self requiredStringFromDictionary:parameters 
														forKey:@"number"];
	NSLog( @"Processing PHONE Command for %@", phoneNumber );
	if ( ( phoneNumber != nil ) && ( phoneNumber.length > 0 ) )
	{
		[self.bridgeDelegate placeCallTo:phoneNumber];
	}
	return YES;
}


- (BOOL)processSMSCommand:(NSDictionary *)parameters
			   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing SMS Command..." );
	
	NSString *to = [self requiredStringFromDictionary:parameters 
											   forKey:@"to"];
	NSString *body = [self requiredStringFromDictionary:parameters 
												 forKey:@"body"];
	if ( ( body != nil ) && 
		 ( to != nil ) )
	{
		[self.bridgeDelegate sendSMSTo:to
							  withBody:body];
	}
	return YES;
}


- (BOOL)processServiceCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView
{
	// determine the desired service and state
	NSString *eventName = [parameters valueForKey:@"name"];
	NSString *desiredState = [parameters valueForKey:@"enabled"];
	BOOL enabled = ( [@"Y" isEqualToString:desiredState] );
	NSLog( @"Processing SERVICE Command to %@able %@ events", ( enabled ? @"en" : @"dis" ), eventName );
	
	if ( [@"tiltChange" isEqualToString:eventName] ) // accelerometer
	{
		if ( enabled )
		{
			m_accelerometerEnableCount++;
			if ( m_accelerometer == nil )
			{
				m_accelerometer = [[UIAccelerometer sharedAccelerometer] retain];
				m_accelerometer.updateInterval = .1;
				m_accelerometer.delegate = self;
			}
			m_processAccelerometer = YES;
		}
		else
		{
			if ( m_accelerometerEnableCount > 0 )
			{
				m_accelerometerEnableCount--;
				if ( m_accelerometerEnableCount == 0 )
				{
					m_accelerometer.delegate = nil, [m_accelerometer release], m_accelerometer = nil;
				}
			}
			m_processAccelerometer = NO;
		}
	}
	if ( [@"shake" isEqualToString:eventName] ) // shake
	{
		if ( enabled )
		{
			m_accelerometerEnableCount++;
			if ( m_accelerometer == nil )
			{
				m_accelerometer = [[UIAccelerometer sharedAccelerometer] retain];
				m_accelerometer.updateInterval = .1;
				m_accelerometer.delegate = self;
			}
			
			m_processShake = YES;
		}
		else
		{
			if ( m_accelerometerEnableCount > 0 )
			{
				m_accelerometerEnableCount--;
				if ( m_accelerometerEnableCount == 0 )
				{
					m_accelerometer.delegate = nil, [m_accelerometer release], m_accelerometer = nil;
				}
			}
			m_processShake = NO;
		}
	}
	else if ( [@"headingChange" isEqualToString:eventName] ) // compass
	{
		if ( [CLLocationManager headingAvailable] )
		{
			if ( enabled )
			{
				m_compassEnableCount++;
				if ( m_compassEnableCount == 1 )
				{
					[m_locationManager startUpdatingHeading];
				}
			}
			else
			{
				if ( m_compassEnableCount > 0 )
				{
					m_compassEnableCount--;
					if ( m_compassEnableCount == 0 )
					{
						[m_locationManager stopUpdatingHeading];
					}
				}
			}
		}
	}
	else if ( [@"locationChange" isEqualToString:eventName] ) // Location Based Services
	{
		if ( [CLLocationManager locationServicesEnabled] )
		{
			NSLog( @"Location Services are available;  Enable count: %i", m_locationEnableCount );
			if ( enabled )
			{
				m_locationEnableCount++;
				if ( m_locationEnableCount == 1 )
				{
					NSLog( @"Location Services Enabled." );
					[m_locationManager startUpdatingLocation];
				}
			}
			else
			{
				if ( m_locationEnableCount > 0 )
				{
					m_locationEnableCount--;
					if ( m_locationEnableCount == 0 )
					{
						NSLog( @"Location Services Disabled." );
						[m_locationManager stopUpdatingLocation];
					}
				}
			}
		}
		else {
			NSLog( @"Location Services are not available." );
		}
	}
	else if ( [@"rotationChange" isEqualToString:eventName] ) // gyroscope
	{
		if ( self.motionManager != nil )
		{
			if ( enabled )
			{
				m_gyroscopeEnableCount++;
				if ( m_timer == nil )
				{
					m_timer = [NSTimer scheduledTimerWithTimeInterval:0.1 
															   target:self
															 selector:@selector(timerFired)
															 userInfo:nil 
															  repeats:YES];
					[self.motionManager startGyroUpdates];
				}
			}
			else
			{
				if ( m_gyroscopeEnableCount > 0 )
				{
					m_gyroscopeEnableCount--;
					if ( m_gyroscopeEnableCount == 0 )
					{
						[self.motionManager stopGyroUpdates];
					}
				}
			}
		}
	}
	
	// anything else is not something that we need to enable or disable
	
	return YES;
}
*/

// restore to default state
- (void)restoreServicesToDefaultState
{
	// accelerometer monitoring
	if ( m_accelerometerEnableCount > 0 )
	{
		m_accelerometer.delegate = nil, [m_accelerometer release], m_accelerometer = nil;
		m_accelerometerEnableCount = 0;
	}
	
	// compass monitoring
	if ( m_compassEnableCount > 0 )
	{
		[m_locationManager stopUpdatingHeading];
		m_compassEnableCount = 0;
	}
	
	// gyroscope monitoring
	if ( m_gyroscopeEnableCount > 0 )
	{
		[m_timer invalidate], m_timer = nil;
		[self.motionManager stopGyroUpdates];
		m_gyroscopeEnableCount = 0;
	}
	
	// location monitoring
	if ( m_locationEnableCount > 0 )
	{
		[m_locationManager stopUpdatingLocation];
		m_locationEnableCount = 0;
	}
}


#pragma mark -
#pragma mark Notification Center Dispatch Methods

- (void)orientationChanged:(NSNotification *)notification
{
	UIDevice *device = [UIDevice currentDevice];
    UIDeviceOrientation orientation = device.orientation;
 
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
			// the device is likely flat
			// since we have no idea what the orientation is
			// don't change it
			return;
	}
	CGSize screenSize = [device screenSizeForOrientation:orientation];
	// We have to change the screenSize before the orientation -- order of listeners triggered is important for mraid.js
	[self.bridgeDelegate usingWebView:self.bridgeDelegate.webView
					executeJavascript:@"window.mraidview.fireChangeEvent( {screenSize: { width: %f, height: %f }, orientation: %i } );",
                                    screenSize.width, screenSize.height, orientationAngle];    
    [self.bridgeDelegate rotateExpandedWindowsToCurrentOrientation];
}


- (void)keyboardWillShow:(NSNotification *)notification
{
	[self.bridgeDelegate usingWebView:self.bridgeDelegate.webView
	 executeJavascript:@"window.mraidview.fireChangeEvent( { keyboardState: true } );"];
}


- (void)keyboardWillHide:(NSNotification *)notification
{
	[self.bridgeDelegate usingWebView:self.bridgeDelegate.webView
					executeJavascript:@"window.mraidview.fireChangeEvent( { keyboardState: false } );"];
}


- (void)handleReachabilityChangedNotification:(NSNotification *)notification
{
	//Reachability *r = (Reachability *)notification.object;
	NSLog( @"Network is now %@", self.networkStatus );
	[self.bridgeDelegate usingWebView:self.bridgeDelegate.webView
					executeJavascript:@"window.mraidview.fireChangeEvent( { network: '%@' } );", self.networkStatus];
}


#pragma mark -
#pragma mark Accelerometer Delegete

- (void)accelerometer:(UIAccelerometer *)accelerometer 
		didAccelerate:(UIAcceleration *)acceleration
{
	static BOOL processingShake = NO;
	BOOL shake = NO;
	
	// send accelerometer data if needed
	if ( m_processAccelerometer )
	{
	    NSLog( @"Acceleration Data Available: %f, %f, %f", acceleration.x,
														   acceleration.y,
														   acceleration.z );
		[self.bridgeDelegate usingWebView:self.bridgeDelegate.webView
						executeJavascript:@"window.mraidview.fireChangeEvent( { tilt: { x: %f, y: %f, z: %f } } );", acceleration.x,
																												acceleration.y,
																												acceleration.z];
	}
	
	// deal with shakes
	if ( m_processShake )
	{
	   if ( processingShake )
	   {
		   return;
	   }
	   if ( ( acceleration.x > m_shakeIntensity ) || ( acceleration.x < ( -1 * m_shakeIntensity ) ) )
	   {
		   shake = YES;
	   }
	   if ( ( acceleration.x > m_shakeIntensity ) || ( acceleration.x < ( -1 * m_shakeIntensity ) ) )
	   {
		  shake = YES;
  	   }
	   if ( ( acceleration.x > m_shakeIntensity ) || ( acceleration.x < ( -1 * m_shakeIntensity ) ) )
	   {
		  shake = YES;
	   }
	
	   if ( shake )
	   {
		   // Shake detected
		   NSLog( @"Shake Detected" );
		   [self.bridgeDelegate usingWebView:self.bridgeDelegate.webView
						   executeJavascript:@"window.mraidview.fireShakeEvent();"];
	   }
	   processingShake = NO;
	}
}


#pragma mark -
#pragma mark Timer Handler

- (void)timerFired
{
	// get the current gyroscope data
	CMGyroData *data = self.motionManager.gyroData;
	NSLog( @"Gyroscope Data Available: %f, %f, %f", data.rotationRate.x, 
													data.rotationRate.y, 
													data.rotationRate.z );
	[self.bridgeDelegate usingWebView:self.bridgeDelegate.webView
					executeJavascript:@"window.mraidview.fireChangeEvent( { rotation: { x: %f, y: %f, z: %f } } );", data.rotationRate.x,
																									   data.rotationRate.y, 
																									   data.rotationRate.z];
}



#pragma mark -
#pragma mark Location Manager Delegate (including Compass)

- (void)locationManager:(CLLocationManager *)manager 
	didUpdateToLocation:(CLLocation *)newLocation 
		   fromLocation:(CLLocation *)oldLocation
{
	NSLog( @"Location Data Available: (%f, %f ) acc: %f", newLocation.coordinate.latitude, 
														  newLocation.coordinate.longitude, 
														  newLocation.horizontalAccuracy );
	[self.bridgeDelegate usingWebView:self.bridgeDelegate.webView
					executeJavascript:@"window.mraidview.fireChangeEvent( { location: { lat: %f, lon: %f, acc: %f } } );", newLocation.coordinate.latitude,
																											 newLocation.coordinate.longitude, 
																											 newLocation.horizontalAccuracy];
}


- (void)locationManager:(CLLocationManager *)manager 
	   didFailWithError:(NSError *)error

{
}


- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
	// TODO: We may want to show a calibration screen based on the accuracy of 
	// the heading
	return NO;
}


- (void)locationManager:(CLLocationManager *)manager 
	   didUpdateHeading:(CLHeading *)newHeading
{ 
	NSLog( @"Heading Data Available: %f", newHeading.trueHeading );
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setTimeStyle:NSDateFormatterFullStyle];
	[formatter setDateStyle:NSDateFormatterFullStyle];
	[self.bridgeDelegate usingWebView:self.bridgeDelegate.webView
					executeJavascript:@"window.mraidview.fireChangeEvent( { heading: %f } );", newHeading.trueHeading];
}


- (void)locationManager:(CLLocationManager *)manager 
		 didEnterRegion:(CLRegion *)region
{
}


- (void)locationManager:(CLLocationManager *)manager 
		  didExitRegion:(CLRegion *)region
{
}


- (void)locationManager:(CLLocationManager *)manager 
monitoringDidFailForRegion:(CLRegion *)region 
			  withError:(NSError *)error
{
}



#pragma mark -
#pragma mark Utility

- (CGFloat)floatFromDictionary:(NSDictionary *)dictionary
						forKey:(NSString *)key
{
	return [self floatFromDictionary:dictionary
							  forKey:key
						 withDefault:0.0];
}


- (int)intFromDictionary:(NSDictionary *)dictionary
						forKey:(NSString *)key
{
	NSString *stringValue = [dictionary valueForKey:key];
	if ( stringValue == nil )
	{
		return -1;
	}
	int value = [stringValue intValue];
	return value;
}


- (CGFloat)floatFromDictionary:(NSDictionary *)dictionary
						forKey:(NSString *)key
				   withDefault:(CGFloat)defaultValue
{
	NSString *stringValue = [dictionary valueForKey:key];
	if ( stringValue == nil )
	{
		return defaultValue;
	}
	CGFloat value = [stringValue floatValue];
	return value;
}


- (BOOL)booleanFromDictionary:(NSDictionary *)dictionary
					   forKey:(NSString *)key
{
	NSString *stringValue = [dictionary valueForKey:key];
	BOOL value = [@"Y" isEqualToString:stringValue] || [@"y" isEqualToString:stringValue];
	return value;
}


- (NSString *)requiredStringFromDictionary:(NSDictionary *)dictionary
									forKey:(NSString *)key
{
	NSString *value = [dictionary objectForKey:key];
	if ( value == nil || [value isEqual:[NSNull null]] )
	{
		// error
		NSLog( @"Missing required parameter: %@", key );
		return nil;
	}
	value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSLog(@"Value is \"%@\"", value);
	if ( value.length == 0 || [value isEqual:[NSNull null]] || value == nil)
	{
		NSLog( @"Missing required parameter: %@", key );
		return nil;
	}
	return value;
}

@end
