/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "MRAIDStoreAndForwardRequest.h"


@interface MRAIDDataAccessLayer : NSObject
{
@private
	FMDatabase *m_database;
	NSBundle *m_mraidBundle;
}

// designated accessor for the singleton instance
+ (MRAIDDataAccessLayer *)sharedInstance;


// for managing the cache
- (void)removeAllCreatives;
- (void)cacheCreative:(NSString *)creativeId
			   forURL:(NSURL *)url;
- (void)creativeAccessed:(NSString *)creativeId;
- (void)removeCreative:(NSString *)creativeId;
- (void)incrementCacheUsageForCreative:(NSString *)creativeId
									by:(unsigned long long)bytes;
- (void)decrementCacheUsageForCreative:(NSString *)creativeId
									by:(unsigned long long)bytes;
- (void)truncateCacheUsageForCreative:(NSString *)creativeId;


// for store and forward requests
- (void)storeRequest:(NSString *)request;
- (MRAIDStoreAndForwardRequest *)getNextStoreAndForwardRequest;
- (void)removeStoreAndForwardRequestWithRequestNumber:(NSNumber *)requestNumber;

@end
