//
//  KSVideoPlayer.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface KSVideoPlayer ()

@property (nonatomic ,strong)AVPlayer *player;
@property (nonatomic ,strong)AVPlayerLayer *playerLayer;

@property (nonatomic ,assign)CMTime timeEnterBackGround;

@end

@implementation KSVideoPlayer

- (void)dealloc
{
    [self removeObsvers];
}

- (void)removeObsvers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithPath:(NSString *)strPath
{
    self = [super init];
    if (self) {
        self.timeEnterBackGround = kCMTimeZero;

        NSURL *urlPath = [NSURL fileURLWithPath:strPath];

        AVPlayer *player = [AVPlayer playerWithURL:urlPath];
        self.player = player;

        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        playerLayer.frame = [UIScreen mainScreen].bounds;
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        playerLayer.backgroundColor = [UIColor blackColor].CGColor;
        self.playerLayer = playerLayer;

        //播放完成-监听
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(finishPlay)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];

        //将要进入后台-监听
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillResignActivePlayer)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];

        //进入前台-监听
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidBecomeActivePlayer)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - private
- (void)finishPlay
{
    //播放完程，重新开始，循环播放
    [self.player seekToTime:kCMTimeZero];
    [self startPlay];
}

- (void)appWillResignActivePlayer
{
    [self.player pause];
    self.timeEnterBackGround = self.player.currentTime;
}

- (void)appDidBecomeActivePlayer
{
    [self.player seekToTime:self.timeEnterBackGround];
    [self startPlay];
}



#pragma mark - pubLic method
- (void)showPlayerLayerInView:(UIView *)view
{
    //为闪一下黑屏添加转场动画
    CATransition *animation = [CATransition animation];
    animation.duration = 0.4;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animation.type = kCATransitionReveal;
    [self.playerLayer addAnimation:animation forKey:@"KSAVPlayerShowAnimation"];

    [view.layer addSublayer:self.playerLayer];
}

- (void)removePlayerLayerInView:(UIView *)view
{
    [self.playerLayer removeFromSuperlayer];
}

- (void)startPlay
{
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self.player play];
    }
}

- (void)stopPlay
{
    [self.player pause];
}

@end
