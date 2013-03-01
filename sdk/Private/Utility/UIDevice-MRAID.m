/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "UIDevice-MRAID.h"



@implementation UIDevice (MRAID)


- (CGSize)screenSizeForOrientation:(UIDeviceOrientation)orientation
{
	CGSize size;
	UIScreen *screen = [UIScreen mainScreen];
	CGSize screenSize = screen.bounds.size;	
	if ( UIDeviceOrientationIsLandscape( orientation ) )
	{
		// Landscape Orientation, reverse size values
		size.width = screenSize.height;
		size.height = screenSize.width;
	}
	else
	{
		// portrait orientation, use normal size values
		size.width = screenSize.width;
		size.height = screenSize.height;
	}
	return size;
}

@end
