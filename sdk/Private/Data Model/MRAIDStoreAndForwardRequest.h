/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>


@interface MRAIDStoreAndForwardRequest : NSObject
{
@private
	long m_requestNumber;
	NSString *m_request;
	NSDate *m_createdOn;
}
@property( nonatomic, assign ) long requestNumber;
@property( nonatomic, copy ) NSString *request;
@property( nonatomic, copy ) NSDate *createdOn;

@end
