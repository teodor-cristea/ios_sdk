//
//  FileSystemCache.m
//  RichMediaAds
//
//  Created by Robert Hedin on 9/8/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "FileSystemCache.h"



@interface FileSystemCache ()

- (BOOL)processManifest:(NSString *)html
				baseURL:(NSURL *)baseURL;




@end




@implementation FileSystemCache


#pragma mark -
#pragma mark Constants

NSString * const kCacheDelegateKey = @"delegate";
NSString * const kRootCachePath = @"ad-cache";



#pragma mark -
#pragma mark Properties



#pragma mark -
#pragma mark Initializers / Memory Management

+ (FileSystemCache *)sharedInstance
{
	static FileSystemCache *sharedInstance = nil;
	@synchronized ( self )
	{
		if ( sharedInstance == nil )
		{
			sharedInstance = [[FileSystemCache alloc] init];
		}
	}
	return sharedInstance;
}


- (FileSystemCache *)init
{
	if ( ( self = [super init] ) )
	{
	}
	return self;
}


- (void)dealloc
{
	[super dealloc];
}



#pragma mark -
#pragma mark Properties

- (NSString *)cacheRoot
{
	// determine the root where our cache will be stored
    NSArray *systemPaths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES ); 
    NSString *basePath = [systemPaths objectAtIndex:0]; 
	
	// add the root
	NSString *path = [basePath stringByAppendingPathComponent:kRootCachePath];
	return path;
}



#pragma mark -
#pragma mark Cache Loading

- (void)cacheURL:(NSURL *)url
	withDelegate:(id<FileSystemCacheDelegate>)delegate;
{
	// setup our dictionary for the callback
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:delegate, kCacheDelegateKey,
																		nil];
	
	// this should retrieve the data from the specified URL
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	request.delegate = self;
	request.userInfo = userInfo;
	[request startAsynchronous];
	
}


- (void)cacheHTML:(NSString *)html
		  baseURL:(NSURL *)baseURL
	 withDelegate:(id<FileSystemCacheDelegate>)delegate;
{
	// determine the root where our cache will be stored
	NSString *path = [self cachePathFromURL:baseURL];
	
	// write the file to disk
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	[data writeToFile:path
		   atomically:YES];
	
	// Now, notify the delegate that we've saved the resource
	[delegate cachedBaseURL:baseURL
					 onPath:path];
}


#pragma mark -
#pragma mark ASI HTTP Request Delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	// get the HTML
	NSString *html = [request responseString];
	
	// determine the base URL to use for storage
	NSURL *baseURL = [request originalURL];

	// process any manifest file stored therein
	if ( ![self processManifest:html
					   baseURL:baseURL] )
	{
		// no manifest, just store the retrieved data
		id<FileSystemCacheDelegate> d = (id<FileSystemCacheDelegate>)[request.userInfo objectForKey:kCacheDelegateKey];
		[self cacheHTML:html
				baseURL:baseURL
		   withDelegate:d];
	}
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
	// get the error
	NSError *error = request.error;
	
	// notify the delegate that the request failed
	id<FileSystemCacheDelegate> delegate = (id<FileSystemCacheDelegate>)[request.userInfo objectForKey:kCacheDelegateKey];
	[delegate cacheFailed:[request originalURL]
				withError:error];
}



#pragma mark -
#pragma mark Process Manifest

- (BOOL)processManifest:(NSString *)html
				baseURL:(NSURL *)baseURL
{
	// TODO: actually process the manifest
	return NO;
}



#pragma mark -
#pragma mark Utility

// our actual path will be:
// ROOT/host/path1/path2/path3/resource
- (NSString *)cachePathFromURL:(NSURL *)url
{
	// add the root
	NSString *path = self.cacheRoot;
	
	// add the host
	NSString *hostName = [url host];
	path = [path stringByAppendingPathComponent:hostName];
	
	// add all but the actual resource
	NSArray *pathComponents = [url pathComponents];
	for ( NSInteger index = 0; index < ( pathComponents.count - 2 ); index++ )
	{
		NSString *component = [pathComponents objectAtIndex:index];
		path = [path stringByAppendingPathComponent:component];
	}
	
	// now make sure the path exists
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:path 
  withIntermediateDirectories:YES 
				   attributes:nil 
						error:NULL];
	
	
	// now finish off the path
	path = [path stringByAppendingPathComponent:[url lastPathComponent]];

	// done
	return path;
}

@end
