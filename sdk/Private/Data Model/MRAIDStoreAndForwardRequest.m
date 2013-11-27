/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "MRAIDStoreAndForwardRequest.h"



@interface MRAIDStoreAndForwardRequest ()


@end




@implementation MRAIDStoreAndForwardRequest


#pragma mark -
#pragma mark Constants



#pragma mark -
#pragma mark Properties

@synthesize requestNumber = m_requestNumber;
@synthesize request = m_request;
@synthesize createdOn = m_createdOn;



#pragma mark -
#pragma mark Initializers / Memory Management


- (MRAIDStoreAndForwardRequest *)init
{
	if ( ( self = [super init] ) )
	{
	}
	return self;
}


- (void)dealloc
{
	m_request = nil;
	m_createdOn = nil;
}

@end
