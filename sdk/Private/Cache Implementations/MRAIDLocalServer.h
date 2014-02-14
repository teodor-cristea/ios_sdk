/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>
#import "HTTPServer.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "MRAIDDataAccessLayer.h"



@protocol MRAIDLocalServerDelegate <NSObject>

@required

// called if a cache function fails
- (void)cacheFailed:(NSURL *)url
		  withError:(NSError *)error;

// called when a creative has been cached
- (void)cachedCreative:(NSURL *)baseURL
				 onURL:(NSURL *)url
				withId:(NSString *)creativeId;

// called when a resource has been cached
- (void)cachedResource:(NSURL *)url
		   forCreative:(NSString *)creativeId;

// called when a resource has been cached
- (void)cachedResourceRetired:(NSURL *)url
				  forCreative:(NSString *)creativeId;

// called when a resource has been cached
- (void)cachedResourceRemoved:(NSURL *)url
				  forCreative:(NSString *)creativeId;

// called to get injectable javascript
- (NSString *)javascriptForInjection;

// called when a new creative has been pulled from cache.
// can be nil which means current batch is depleted
- (void)currentCachedCreativeChanged:(NSString *)creativeId;

// called when a cached creative should be displayed
- (void)showCachedCreative:(NSURL *)baseURL
                     onURL:(NSURL *)url
                    withId:(NSString *)creativeId;

// called before a cached creative is about to be loaded from disk
- (void)willLoadCreativeWithContent:(NSString *)content;

// called just after a cached creative was loaded from disk
- (void)didLoadCreativeWithContent:(NSString *)content;

@end



@interface MRAIDLocalServer : NSObject <ASIHTTPRequestDelegate>
{
@private
	HTTPServer *m_server;
	MRAIDDataAccessLayer *m_dal;
    ASINetworkQueue *m_queue;

	NSString *m_htmlStub;
}
@property( nonatomic, copy, readonly ) NSString *cacheRoot;
@property( nonatomic, copy, readonly ) NSString *cacheActiveRoot;
@property( nonatomic, copy ) NSString *htmlStub;


// designated accessor for the singleton instance
+ (MRAIDLocalServer *)sharedInstance;

+ (NSString *)rootDirectory;
+ (NSString *)rootActiveDirectory;

// used to cache a specific URL
// optional preloading
- (void)cacheURL:(NSURL *)url
     fromCampaignURL:(NSURL *)baseURL
	withDelegate:(id<MRAIDLocalServerDelegate>)delegate
 andPreloadCount:(NSInteger)count;


// used to cache local HTML
- (void)cacheHTML:(NSString *)baseHtml
		  baseURL:(NSURL *)baseURL
      campaignURL:(NSURL *)campaignURL
	 withDelegate:(id<MRAIDLocalServerDelegate>)delegate;


// determines the path to a specific cached url
//- (NSString *)cachePathFromURL:(NSURL *)url;


// adds a new resource to the cache for the specified creative
- (void)cacheResourceForCreative:(NSString *)creativeId
						   named:(NSString *)url
					withDelegate:(id<MRAIDLocalServerDelegate>)delegate;

// removes a specific resource from the cache for the specified creative
- (void)removeCachedResourceForCreative:(NSString *)creativeId
								  named:(NSString *)url
						   withDelegate:(id<MRAIDLocalServerDelegate>)delegate;

// removes all cached resources for the specified creative
- (void)removeAllCachedResourcesForCreative:(NSString *)creativeId
							   withDelegate:(id<MRAIDLocalServerDelegate>)delegate;



// removes all currently cached resources EXCEPT those that the framework
// itself stores
+ (void)removeAllCachedResources;


- (NSString *)cachedHtmlForCreative:(NSString *)creativeId fromCampaignBaseURL:(NSURL *)url;


@end
