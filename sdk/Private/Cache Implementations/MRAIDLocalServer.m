/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "MRAIDLocalServer.h"
#import "DDData.h"


@interface MRAIDLocalServer ()

- (NSString *)resourcePathForCreative:(NSString *)creativeId
							   forURL:(NSURL *)url;
+ (unsigned long long)removeObjectsInDirectory:(NSString *)directory
								  includeFiles:(BOOL)files;

- (NSString *)processHTMLStubUsingFragment:(NSString *)fragment
								  delegate:(id<MRAIDLocalServerDelegate>)delegate;

+ (void)reapCache;

@end




@implementation MRAIDLocalServer

#pragma mark -
#pragma mark Statics

static NSString *s_standardHTMLStub;
static NSString *s_standardJSStub;
static NSTimer *s_timer;



#pragma mark -
#pragma mark Constants

const NSTimeInterval kCacheReaperTimeInterval = 3600; // every hour

NSString * const kAdContentToken    = @"<!--AD-CONTENT-->";
NSString * const kInjectedContentToken    = @"<!-- INJECTED-CONTENT -->";

NSString * const kMRAIDLocalServerWebRoot = @"mraid-web-root";
NSString * const kMRAIDLocalServerDelegateKey = @"delegate";
NSString * const kMRAIDLocalServerTypeKey = @"type";
NSString * const kMRAIDLocalServerPathKey = @"path";
NSString * const kMRAIDLocalServerCreativeIdKey = @"id";

NSString * const kMRAIDLocalServerCreativeType = @"creative";
NSString * const kMRAIDLocalServerResourceType = @"resource";



#pragma mark -
#pragma mark Properties

@dynamic cacheRoot;
@synthesize htmlStub = m_htmlStub;



#pragma mark -
#pragma mark Initializers / Memory Management


+ (MRAIDLocalServer *)sharedInstance
{
	static MRAIDLocalServer *sharedInstance = nil;

    @synchronized( self )
    {
        if ( sharedInstance == nil )
		{
			sharedInstance = [[MRAIDLocalServer alloc] init];
		}
    }
    return sharedInstance;
}


+ (void)initialize
{
	// make sure an autorelease pool is active
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// access our bundle
	NSString *path = [[NSBundle mainBundle] pathForResource:@"MRAID"
													 ofType:@"bundle"];
	if ( path == nil )
	{
		[NSException raise:@"Invalid Build Detected"
					format:@"Unable to find MRAID.bundle. Make sure it is added to your resources!"];
	}
	NSBundle *mraidBundle = [NSBundle bundleWithPath:path];

	// setup the default HTML Stub
	path = [mraidBundle pathForResource:@"MRAID_Standard_HTML_Stub"
								   ofType:@"html"];
	NSLog( @"HTML Stub Path is: %@", path );
	s_standardHTMLStub = [[NSString stringWithContentsOfFile:path
													encoding:NSUTF8StringEncoding
													   error:NULL] retain];
	
	// setup the default HTML Stub
	path = [mraidBundle pathForResource:@"MRAID_Standard_JS_Stub"
								   ofType:@"html"];
	NSLog( @"JS Stub Path is: %@", path );
	s_standardJSStub = [[NSString stringWithContentsOfFile:path
												  encoding:NSUTF8StringEncoding
													 error:NULL] retain];
	
	// perform cache cleanup
	[self reapCache];
	
	// done with pool
	[pool drain];
}


- (MRAIDLocalServer *)init
{
	if ( ( self = [super init] ) )
	{
		// Setup Access to the database
		m_dal = [MRAIDDataAccessLayer sharedInstance];
		
		// setup our Internal HTTP Server
		NSError *error = nil;
		m_server = [[HTTPServer alloc] init];
		NSURL *url = [NSURL fileURLWithPath:[self cacheRoot]];
		[m_server setDocumentRoot:url];
		[m_server start:&error];
		
		// make sure the root path exists
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm createDirectoryAtPath:self.cacheRoot 
	  withIntermediateDirectories:YES 
					   attributes:nil 
							error:NULL];
        
        // listen for device events to properly start/stop our server (socket dies when app goes inactive)
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
			   selector:@selector(handleDidBecomeActiveNotification:)
				   name:UIApplicationDidBecomeActiveNotification
				 object:nil];
		[nc addObserver:self
			   selector:@selector(handleDidResignActiveNotification:)
				   name:UIApplicationWillResignActiveNotification
				 object:nil];
	}
	return self;
}


- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];

	// release our internals
	[m_htmlStub release], m_htmlStub = nil;
	
	// shutdown our server
	[m_server stop];
	[m_server release], m_server = nil;
	[super dealloc];
}



#pragma mark -
#pragma mark Properties

- (NSString *)cacheRoot
{
	return [MRAIDLocalServer rootDirectory];
}


+ (NSString *)rootDirectory
{
	// determine the root where our cache will be stored
    NSArray *systemPaths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES ); 
    NSString *basePath = [systemPaths objectAtIndex:0]; 
	
	// add the root
	NSString *path = [basePath stringByAppendingPathComponent:kMRAIDLocalServerWebRoot];
	
	return path;
}



#pragma mark -
#pragma mark Cache Management

+ (void)removeAllCachedResources;
{
	// we've been asked to remove everything we've cached (usually for error
	// recovery) so start walking our cache directory and start to recursively
	// remove every file we find.
	//
	// NOTE: we're going to leave any files in the *root* directory as user
	//       code cannot cache files to the root.
	
	BOOL isDirectory;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *list = [fm contentsOfDirectoryAtPath:[MRAIDLocalServer rootDirectory]
											error:NULL];
	for ( NSString *path in list )
	{
		if ( [fm fileExistsAtPath:path isDirectory:&isDirectory] )
		{
			// the object exists, do we care?
			if ( isDirectory )
			{
				// it is a directory, process it
				[self removeObjectsInDirectory:path
								  includeFiles:YES];
				
				// we've processed the directory, remove it
				[fm removeItemAtPath:path
							   error:NULL];
			}
		}
	}
	
	// now remove all cache entries from our database
	MRAIDDataAccessLayer *dal = [MRAIDDataAccessLayer sharedInstance];
	[dal removeAllCreatives];
	
}


+ (unsigned long long)removeObjectsInDirectory:(NSString *)directory
								  includeFiles:(BOOL)files
{
	unsigned long long size = 0;
	BOOL isDirectory;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *list = [fm contentsOfDirectoryAtPath:directory 
											error:NULL];
	for ( NSString *path in list )
	{
		if ( [fm fileExistsAtPath:path isDirectory:&isDirectory] )
		{
			// the object exists
			if ( isDirectory )
			{
				// it is a directory, process it
				size += [self removeObjectsInDirectory:path
										  includeFiles:YES];

				// now remove the directory
				[fm removeItemAtPath:path
							   error:NULL];
			}
			else
			{
				// if it's a file, make sure we care
				if ( files )
				{
					// let's get the size
					NSDictionary *attr = [fm attributesOfItemAtPath:path
					error:NULL];
					size += [attr fileSize];
					
					// now remove the file
					[fm removeItemAtPath:path
					error:NULL];
					}
			}
			
		}
	}
	return size;
}


- (void)cacheURL:(NSURL *)url
	withDelegate:(id<MRAIDLocalServerDelegate>)delegate;
{
	// setup our dictionary for the callback
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:delegate, kMRAIDLocalServerDelegateKey,
																		kMRAIDLocalServerCreativeType, kMRAIDLocalServerTypeKey,
																		nil];
	
    NSLog(@"cacheURL url = %@",url);
	// this should retrieve the data from the specified URL
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setUserAgentString:[ASIHTTPRequest defaultUserAgentString]];
    NSLog(@"UA String set to %@",[request userAgentString]);
	request.delegate = self;
	request.userInfo = userInfo;
	[request startAsynchronous];
}


- (void)cacheHTML:(NSString *)baseHtml
		  baseURL:(NSURL *)baseURL
	 withDelegate:(id<MRAIDLocalServerDelegate>)delegate;
{
	NSLog( @"Caching HTML" );
	
	// see if this is a fragment or not
	NSString *workHtml = [baseHtml lowercaseString];
	NSString *html;
	NSRange r = [workHtml rangeOfString:@"/html>"];
	if ( r.location != NSNotFound )
	{
		// full doc, no need to wrap
		html = baseHtml;
	}
	else
	{
		html = [self processHTMLStubUsingFragment:baseHtml
										 delegate:delegate];
	}

	// determine the hash for this creative
	NSString *creativeId = [[[html dataUsingEncoding:NSUTF8StringEncoding] md5Digest] hexStringValue];
	NSString *path = [self.cacheRoot stringByAppendingPathComponent:creativeId];
	NSString *fqpn = [path stringByAppendingPathComponent:@"index.html"];
	
	// see if we already have this creative cached
	NSFileManager *fm = [NSFileManager defaultManager];
	if ( ![fm fileExistsAtPath:fqpn] )
	{
		// we don't have it yet
		// make sure the directory exists
		[fm createDirectoryAtPath:path 
	  withIntermediateDirectories:YES 
					   attributes:nil 
							error:NULL];
	}

	// update our copy on disk
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	[data writeToFile:fqpn
		   atomically:YES];
	
	// update our database
	NSLog( @"Update cache database" );
	[m_dal cacheCreative:creativeId 
				  forURL:baseURL];
	
	// Now, notify the delegate that we've saved the resource
	NSLog( @"Notify delegate that object was cached" );
	NSString *urlString = [NSString stringWithFormat:@"http://localhost:%i/%@/index.html", [m_server port], 
																						   creativeId];
	NSURL *url = [NSURL URLWithString:urlString];
	[delegate cachedCreative:baseURL
					   onURL:url
					  withId:creativeId];
	NSLog( @"Object caching complete" );
}



#pragma mark -
#pragma mark Caching Resources for a Creative

- (void)cacheResourceForCreative:(NSString *)creativeId
						   named:(NSString *)urlString
					withDelegate:(id<MRAIDLocalServerDelegate>)delegate
{
	// determine the path to the resource
	NSURL *url = [NSURL URLWithString:urlString];
	NSString *resourcePath = [self resourcePathForCreative:creativeId
													forURL:url];
	
	// setup our dictionary for the callback
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:delegate, kMRAIDLocalServerDelegateKey,
																		kMRAIDLocalServerTypeKey, kMRAIDLocalServerCreativeType,
																		kMRAIDLocalServerPathKey, resourcePath,
																		kMRAIDLocalServerCreativeIdKey, creativeId,
																		nil];
	
    NSLog(@"cacheResourceForCreative url = %@",url);
	// this should retrieve the data from the specified URL
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	request.delegate = self;
	request.userInfo = userInfo;
	[request startAsynchronous];
}


- (void)removeCachedResourceForCreative:(NSString *)creativeId
								  named:(NSString *)url
						   withDelegate:(id<MRAIDLocalServerDelegate>)delegate
{
	// build the path to the resource
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path = [self resourcePathForCreative:creativeId
											forURL:[NSURL URLWithString:url]];
	NSDictionary *attr = [fm attributesOfItemAtPath:path 
											  error:NULL];
	[fm removeItemAtPath:path
				   error:NULL];	
	
	[m_dal decrementCacheUsageForCreative:creativeId
									   by:attr.fileSize];
}


- (void)removeAllCachedResourcesForCreative:(NSString *)creativeId
							   withDelegate:(id<MRAIDLocalServerDelegate>)delegate
{
	// build the path to the creatives directory
	NSString *path = [self.cacheRoot stringByAppendingFormat:@"/%@", creativeId];
	[MRAIDLocalServer removeObjectsInDirectory:path
								  includeFiles:NO];
	
	
	// Now update our database
	[m_dal truncateCacheUsageForCreative:creativeId];
}



#pragma mark -
#pragma mark ASI HTTP Request Delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	// determine the base URL to use for storage
	NSURL *baseURL = [request originalURL];

	// determine the type and get the delegate
	NSDictionary *userInfo = request.userInfo;
	NSString *type = (NSString *)[userInfo objectForKey:kMRAIDLocalServerTypeKey];
	id<MRAIDLocalServerDelegate> d = (id<MRAIDLocalServerDelegate>)[userInfo objectForKey:kMRAIDLocalServerDelegateKey];
	
	// now process the response based on the type
	if ( [kMRAIDLocalServerCreativeType isEqualToString:type] )
	{
		// dealing with a full creative
		// get the HTML
		NSString *html = [request responseString];
    //html = [html stringByReplacingOccurrencesOfString:@"mraidOpen" withString:@"open"];
    NSLog(@"html = %@", html);
    #if 0
    html = @"<link href=\"http://stage.emediate.eu/media.98/172/13046/5078/300x50-expand.css\" rel=\"stylesheet\" type=\"text/css\"/> <script src=\"http://stage.emediate.eu/media.98/172/13046/5078/300x50-expand.js\" type=\"text/javascript\" language=\"javascript\"></script> <div id=\"adSpace\" style=\"height:250px\"> <div id=\"ad\"> <div id=\"banner\"><img src=\"http://stage.emediate.eu/media.98/172/13046/5078/300x50.png\" alt=\"banner advertisement\" onclick=\"return(expand());\"/></div> <div id=\"panel\"><img src=\"http://stage.emediate.eu/media.98/172/13046/5078/300x250.png\" alt=\"panel\" /> <div id=\"hotspot\"> <a href=\"http://stage.emediate.eu/eas/cu=512::camp=5078::no=4898::kw=link1-4898::EASLink=http://www.emediate.com/\" onclick=\"return(collapse());\"></a> </div> <div id=\"close\"><img src=\"http://stage.emediate.eu/media.98/172/13046/5078/btn_close.png\" alt=\"close\"> </div></div></div></div><div>";
  //  #else
      html =  @"<link href=\"http://stage.emediate.eu/media.98/172/13046/5078/300x50-expand.css\" rel=\"stylesheet\" type=\"text/css\"/> <script src=\"http://stage.emediate.eu/media.98/172/13046/5078/300x50-expand.js\" type=\"text/javascript\" language=\"javascript\"></script> <div id=\"adSpace\" style=\"height:250px\"> <div id=\"ad\"><div id=\"banner\"><img src=\"http://stage.emediate.eu/media.98/172/13046/5078/300x50.png\" alt=\"banner advertisement\" onclick=\"return(expand());\"/></div> <div id=\"panel\"><img src=\"http://stage.emediate.eu/media.98/172/13046/5078/300x250.png\" alt=\"panel\"> <div id=\"close\"><img src=\"http://stage.emediate.eu/media.98/172/13046/5078/btn_close.png\" alt=\"close\" onclick=\"return(collapse());\"/></div> </div> </div> </div> <div>";
      //#else
        html = @"<div id=\"fullSpace\" style=\"height:250px; background: silver;\"> <div id=\"collapsedSpace\" style=\"height:50px; background: yellow;\"><b>Simple MRAID expand / collapse test </b> <br /><a href=\"mraid://expand\" onclick=\"mraid.expand();\"> Click to expand</a> </div> <div style=\"position: absolute; top: 100px\"><a href=\"mraid://close\" onclick=\"mraid.close();\"> Click to collapse</a> <br /><br /> </div> <div>";
    #endif
    
    NSLog(@"html = %@", html);
		
		//store the retrieved data
		[self cacheHTML:html
				baseURL:baseURL
		   withDelegate:d];
	}
	else if ( [kMRAIDLocalServerResourceType isEqualToString:type] )
	{
		// we're caching a resource
		// get the raw data
		NSData *data = [request responseData];
		
		// get the path to store the resource
		NSString *path = (NSString *)[request.userInfo objectForKey:kMRAIDLocalServerPathKey];

		// now store the resource
		if ( [data writeToFile:path
					atomically:YES] )
		{
			NSString *n = [request.userInfo objectForKey:kMRAIDLocalServerCreativeIdKey];
			NSString *creativeId = n;
			
			// update our cache
			[m_dal incrementCacheUsageForCreative:creativeId
											   by:[data length]];
			
			// write was successful
			[d cachedResource:baseURL
				  forCreative:creativeId];
		}
		else
		{
			
			// write failed
			[d cacheFailed:baseURL
				 withError:NULL];
		}
	}
	else
	{
		[NSException raise:@"Invalid Value Exception"
					format:@"Unrecognized Type '%@' for request: %@", type, request];
	}
	
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
	// get the error
	NSError *error = request.error;
	
	// notify the delegate that the request failed
	id<MRAIDLocalServerDelegate> delegate = (id<MRAIDLocalServerDelegate>)[request.userInfo objectForKey:kMRAIDLocalServerDelegateKey];
	[delegate cacheFailed:[request originalURL]
				withError:error];
}



#pragma mark -
#pragma mark HTML Stub Control

- (NSString *)processHTMLStubUsingFragment:(NSString *)fragment
								  delegate:(id<MRAIDLocalServerDelegate>)delegate
{
	// select the correct stub
	NSString *stub = self.htmlStub;
	if ( stub == nil )
	{
		// determine if the fragment is JS or not
		NSString *trimmedFragment = [fragment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		BOOL isJS = [trimmedFragment hasPrefix:@"document.write"];
		
	    if ( isJS )
		{
			stub = s_standardJSStub;
		}
		else
		{
			stub = s_standardHTMLStub;
		}
	}
	
	// build the string
	NSString *output = [stub stringByReplacingOccurrencesOfString:kAdContentToken
													   withString:fragment];
	NSString *js = nil;
	if ( [delegate respondsToSelector:@selector(javascriptForInjection)] )
	{
		js = [delegate javascriptForInjection];
	}
	if ( js == nil )
	{
		js = @"";
	}
	output = [output stringByReplacingOccurrencesOfString:kInjectedContentToken
											   withString:js];
	return output;
}



#pragma mark -
#pragma mark Timer Controls

+ (void)reapCache
{
	// walk the cache directory, removing any out dated cache objects
	NSError *error = nil;
	BOOL isDirectory = NO;
	NSDate *oldest = [NSDate dateWithTimeIntervalSinceNow:( -1 * kCacheReaperTimeInterval )];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *root = [self rootDirectory];
	NSArray *cached = [fm contentsOfDirectoryAtPath:root
											  error:&error];
	NSLog( @"Reap Cache at %@", root );
	for ( NSString *entry in cached )
	{
		NSString *path = [root stringByAppendingPathComponent:entry];
		if ( [fm fileExistsAtPath:path 
					  isDirectory:&isDirectory] )
		{
			if ( isDirectory )
			{
				// this is a cache enty, see if it's old enough to delete
				NSDictionary *attr = [fm attributesOfItemAtPath:path
														  error:&error];
				NSDate *modDate = (NSDate *)[attr objectForKey:NSFileModificationDate];
				if ( [modDate compare:oldest] == NSOrderedAscending )
				{
					// needs to be removed
					NSLog( @"Removed entry: %@", path );
					[fm removeItemAtPath:path
								   error:&error];
				}
			}
		}
	}
	
	// reschedule the timer
	s_timer = [[NSTimer scheduledTimerWithTimeInterval:kCacheReaperTimeInterval
												target:self
											  selector:@selector(reapCache)
											  userInfo:nil
											   repeats:NO] retain];
}

#pragma mark -
#pragma mark Notification Handlers

- (void)handleDidBecomeActiveNotification:(NSNotification *)notification
{
	@synchronized( self )
	{
		// start server
        NSError *error = nil;
		[m_server start:&error];
        
        NSLog(@"Server started");
	}
}

- (void)handleDidResignActiveNotification:(NSNotification *)notification
{
	@synchronized( self )
	{
		// shutdown server
		[m_server stop];
        
        NSLog(@"Server stopped");
	}
}

#pragma mark -
#pragma mark Utility

// our resource path is: host + path1 + ... + pathN + resource
- (NSString *)resourcePathForCreative:(NSString *)creativeId
							   forURL:(NSURL *)url
{
	// start with the host
	NSMutableString *path = [NSMutableString stringWithCapacity:500];
	[path appendFormat:@"%@/%@/%@", self.cacheRoot, creativeId, [url host]];
	
	// add all but the actual resource
	NSArray *pathComponents = [url pathComponents];
	for ( NSInteger index = 0; index < ( pathComponents.count - 2 ); index++ )
	{
		NSString *component = [pathComponents objectAtIndex:index];
		[path appendFormat:@"/%@", component];
	}
	
	// now make sure the path exists
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:path 
  withIntermediateDirectories:YES 
				   attributes:nil 
						error:NULL];

	// now finish off the path
	[path appendFormat:@"/%@", [url lastPathComponent]];
	return path;
}



- (NSString *)cachedHtmlForCreative:(NSString *)creativeId
{
    NSString *path = [self.cacheRoot stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", creativeId]];
	NSString *fqpn = [path stringByAppendingPathComponent:@"index.html"];
    NSString *cachedHtml = [NSString stringWithContentsOfFile:fqpn encoding:NSUTF8StringEncoding error:nil];
    return cachedHtml;
}

@end
