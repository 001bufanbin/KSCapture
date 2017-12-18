//
//  KSVideoWriter.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KSCaptureTool.h"

@protocol KSVideoWriterDelegate <NSObject>

/**
 当前写入进度-实时更新

 @param progress 当前写入进度（0-1）
 */
- (void)updateWriterProgress:(CGFloat)progress;

/**
 写入完成

 @param videoPath 写入文件路径
 */
- (void)finishWritingPath:(NSString *)videoPath error:(NSError *)error;

@end

@interface KSVideoWriter : NSObject

@property (nonatomic ,weak)id <KSVideoWriterDelegate>delegate;

//最后写入时间-用于计算暂停偏移时间
@property (nonatomic, readonly) CMTime audioTimestamp;
@property (nonatomic, readonly) CMTime videoTimestamp;

/**
 初始化方法

 @param  videoPath 视频写入文件路径
 @param  deviceOrientation 当前设备方向
 @retutn 视频写入对象
 */
- (instancetype)initWithVideoPath:(NSString *)videoPath currentDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

//开始写入
- (void)startWritingSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(NSString *)mediaType;
//拼接写入
- (void)appendWriteSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(NSString *)mediaType;

//手动停止
- (void)stopWriting;
//放弃写入的视频
- (BOOL)giveUpWriting;

@end
