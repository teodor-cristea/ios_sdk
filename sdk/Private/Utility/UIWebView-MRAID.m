/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "UIWebView-MRAID.h"


@implementation UIWebView (MRAID)

- (void)disableBouncesAndScrolling
{
	for ( id subview in self.subviews )
	{
		if ( [[subview class] isSubclassOfClass:[UIScrollView class]] )
		{
			UIScrollView *sv = (UIScrollView *)subview;
			sv.scrollEnabled = NO;
			sv.bounces = NO;
		}
	}
}

@end
