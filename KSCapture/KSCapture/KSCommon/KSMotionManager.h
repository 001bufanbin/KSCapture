//
//  KSMotionManager.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@protocol KSMotionManagerDelegate <NSObject>

@optional
/**
 当前设备方向（实时更新）

 @param orientation 设备方向
 */
- (void)currentDeviceOrientation:(UIDeviceOrientation)orientation;

@end

@interface KSMotionManager : NSObject

@property (nonatomic ,weak)id <KSMotionManagerDelegate>delegate;

//设备运动检测频率
@property(assign, nonatomic) NSTimeInterval deviceMotionUpdateInterval;
//当前设备方向
@property (nonatomic ,assign ,readonly)UIDeviceOrientation orientation;

+ (KSMotionManager *)shareInstance;
- (void)startDeviceMotionUpdate;
- (void)stopDeviceMotionUpdate;

@end
