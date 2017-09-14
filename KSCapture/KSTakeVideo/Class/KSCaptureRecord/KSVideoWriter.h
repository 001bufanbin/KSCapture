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

@property (nonatomic ,assign)id <KSVideoWriterDelegate>delegate;
@property (nonatomic ,assign)UIDeviceOrientation deviceOrientation;//写入时设备方向
//初始化方法
- (instancetype)initWithVideoPath:(NSString *)videoPath;
- (void)setVideoWriter:(AVCaptureVideoDataOutput *)videoOutPut;
- (void)setAudioWriter:(AVCaptureAudioDataOutput *)audioOutPut;
- (void)addInputs;

//开始写入
- (void)startWritingSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(NSString *)mediaType;
//拼接写入
- (void)appendWriteSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(NSString *)mediaType;

//手动停止
- (void)stopWriting;
//放弃写入的视频
- (BOOL)giveUpWriting;

@end
