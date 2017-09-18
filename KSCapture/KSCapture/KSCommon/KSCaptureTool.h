//
//  KSCaptureTool.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSCaptureConfig.h"

@interface KSCaptureTool : NSObject

/**
 初始化方法

 @return KSCaptureTool对象
 */
+ (instancetype)share;


/**
 写入视频路径

 @return 视频路径
 */
+ (NSString *)videoFilePath;


/**
 删除当前视频文件

 @param videoPath 视频文件路径
 @return 是否成功
 */
+ (BOOL)deleteCurrentVideo:(NSString *)videoPath;


/**
 删除视频

 @return 是否成功
 */
+ (BOOL)deleteVideo;


/**
 麦克风权限

 @return 是否具有权限
 */
+ (BOOL)isAllowAccessMicrophone;

/**
 相机权限

 @return 是否具有权限
 */
+ (BOOL)isAllowAccessCamera;


/**
 计算偏移量之后的sampleBuffer

 @param sampleBuffer sampleBuffer
 @param timeOffset 偏移量
 @return 处理之后的sampleBuffer
 */
+ (CMSampleBufferRef)createOffsetSampleBufferWithSampleBuffer:(CMSampleBufferRef)sampleBuffer withTimeOffset:(CMTime)timeOffset;
@end
