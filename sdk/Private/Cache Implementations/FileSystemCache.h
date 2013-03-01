//
//  FileSystemCache.h
//  RichMediaAds
//
//  Created by Robert Hedin on 9/8/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"



@protocol FileSystemCacheDelegate

@required

- (void)cacheFailed:(NSURL *)baseURL
		  withError:(NSError *)error;

- (void)cachedBaseURL:(NSURL *)baseURL
			   onPath:(NSString *)path;

@end




@interface FileSystemCache : NSObject <ASIHTTPRequestDelegate>
{
@private
}
@property( nonatomic, copy, readonly ) NSString *cacheRoot;


+ (FileSystemCache *)sharedInstance;


// selector should be of the form: 
- (void)cacheURL:(NSURL *)url
	withDelegate:(id<FileSystemCacheDelegate>)delegate;

- (void)cacheHTML:(NSString *)html
		  baseURL:(NSURL *)baseURL
	 withDelegate:(id<FileSystemCacheDelegate>)delegate;


- (NSString *)cachePathFromURL:(NSURL *)url;



@end
