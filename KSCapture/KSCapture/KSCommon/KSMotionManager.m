//
//  KSMotionManager.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSMotionManager.h"

////每秒播放（录制）30帧-速度，总共播放（录制）6帧-路程，所以总共用时（6/30）秒-时间
static NSTimeInterval kUpdateIntervalDefault = 6.0/30.0;

@interface KSMotionManager ()

@property (nonatomic ,strong)CMMotionManager *motionManager;

@end

@implementation KSMotionManager

+ (KSMotionManager *)shareInstance
{
    static KSMotionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[KSMotionManager alloc]init];

        CMMotionManager *motionManager = [[CMMotionManager alloc]init];
        motionManager.deviceMotionUpdateInterval = kUpdateIntervalDefault;
        manager.motionManager = motionManager;
    });
    return manager;
}

- (void)startDeviceMotionUpdate
{
    if ([self.motionManager isDeviceMotionAvailable]) {
        [self.motionManager startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc]init]
                                                withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                                                    [self handleDeviceMotion:motion];
                                                }];
    }
}

- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;

    UIDeviceOrientation deviceOrientation = UIDeviceOrientationPortrait;

    if (fabs(y) >= fabs(x))
    {
        if (y >= 0){
            deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
        }else{
            deviceOrientation = UIDeviceOrientationPortrait;
        }
    }else{
        if (x >= 0){
            deviceOrientation = UIDeviceOrientationLandscapeRight;
        }else{
            deviceOrientation = UIDeviceOrientationLandscapeLeft;
        }
    }

    _orientation = deviceOrientation;

    if (self.delegate && [self.delegate respondsToSelector:@selector(currentDeviceOrientation:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate currentDeviceOrientation:deviceOrientation];
        });
    }
}

- (void)stopDeviceMotionUpdate
{
    if ([self.motionManager isDeviceMotionActive]) {
        [self.motionManager stopDeviceMotionUpdates];
    }
}

#pragma mark - get & set
- (void)setDeviceMotionUpdateInterval:(NSTimeInterval)deviceMotionUpdateInterval
{
    self.motionManager.deviceMotionUpdateInterval = deviceMotionUpdateInterval;
}

- (NSTimeInterval)deviceMotionUpdateInterval
{
    return self.motionManager.deviceMotionUpdateInterval;
}

@end
