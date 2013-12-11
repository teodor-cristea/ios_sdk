/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol MRAIDAVPlayerDelegate
-(void)playerCompleted;
@end

@interface LoadingView : UIView
{
	UIActivityIndicatorView *actIndicator;
}

@end

@interface MRAIDAVPlayer : UIView {
	MPMoviePlayerViewController *avPlayer;
	MPMoviePlayerController* mraidPlayer;
	BOOL statusBarHidden;
	UIStatusBarStyle oldStyle;
	id delegate;
	BOOL exitOnComplete;
	BOOL autoPlay;
	BOOL inlinePlayer;	
	BOOL isFullScreen;
	BOOL statusBarAvailable;
	LoadingView *loadingView;
	BOOL isAudio;
}
@property(nonatomic, strong) id delegate;
@property(nonatomic, strong) MPMoviePlayerController* mraidPlayer;

-(void)playVideo:(NSURL *)videoURL attachTo:(UIView*)parentView autoPlay:(BOOL)autoplay showControls:(BOOL)showcontrols repeat:(BOOL)autorepeat fullScreenMode:(BOOL)fullScreen autoExit:(BOOL)exit;

-(void)playAudio:(NSURL *)audioURL attachTo:(UIView*)parentView autoPlay:(BOOL)autoplay showControls:(BOOL)showcontrols repeat:(BOOL)autorepeat playInline:(BOOL)Inline fullScreenMode:(BOOL)fullScreen autoExit:(BOOL)exit;

-(void)showLoadingScreen:(CGRect)frame;

@end
