//
//  KSVideoWriter.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSVideoWriter.h"

typedef NS_ENUM(NSInteger ,KSCaptureWriterStatus)
{
    KSCaptureWriterUnknown = AVAssetWriterStatusUnknown,
    KSCaptureWriterWriting = AVAssetWriterStatusWriting,
    KSCaptureWriterCompleted = AVAssetWriterStatusCompleted,
    KSCaptureWriterFailed = AVAssetWriterStatusFailed,
    KSCaptureWriterCancelled = AVAssetWriterStatusCancelled
};

@interface KSVideoWriter ()
//写入
@property (nonatomic ,strong)AVAssetWriter            *assetWriter;
@property (nonatomic ,strong)AVAssetWriterInput       *assetVideoWriter;
@property (nonatomic ,strong)AVAssetWriterInput       *assetAudioWriter;
//视频写入队列
@property (nonatomic ,strong)dispatch_queue_t writerQueue;

//音视频写入配置
@property (nonatomic ,strong)NSDictionary *dicVideoSetting;
@property (nonatomic ,strong)NSMutableDictionary *dicAudioSetting;

//当前写入时长
@property (nonatomic ,assign)CGFloat fDuration;

//写入路径
@property (nonatomic ,copy)NSString *videoPath;

//对象内部使用的状态
@property (nonatomic ,assign)KSCaptureWriterStatus status;

@end

@implementation KSVideoWriter

- (void)dealloc
{

}

- (instancetype)initWithVideoPath:(NSString *)videoPath
{
    self = [super init];
    if (self) {
        self.fDuration = 0.0;
        self.videoPath = videoPath;
        self.status = KSCaptureWriterUnknown;
        _audioTimestamp = kCMTimeInvalid;
        _videoTimestamp = kCMTimeInvalid;

        NSURL *writerUrl = [[NSURL alloc] initFileURLWithPath:videoPath];
        NSError *error;
        AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:writerUrl fileType:AVFileTypeMPEG4 error:&error];
        //设置为YES，将尾部视频信息放到视频头部，网络播放的时候一加载就可以播放
        //https://stackoverflow.com/questions/12980047/what-does-shouldoptimizefornetworkuse-actually-do
        assetWriter.shouldOptimizeForNetworkUse = YES;
        self.assetWriter = assetWriter;

        if (error) {
            NSLog(@"assetwriter init error == %@",error);
        }
    }
    return self;
}

- (void)setVideoWriter:(AVCaptureVideoDataOutput *)videoOutPut
{
    NSDictionary *dicNormal = [videoOutPut recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4];
    self.dicVideoSetting = [[NSDictionary alloc]initWithDictionary:dicNormal];

    //如果写入尺寸（宽或者高）不能被16整除，则解码的时候边缘会丢弃,导致一个像素的绿边
    //https://discussions.apple.com/message/8525272#8525272
    //https://stackoverflow.com/questions/29505631/crop-video-in-ios-see-weird-green-line-around-video
    //如果不能被2整除，则宽或者高+1，解决黑边或者绿边的问题
    NSInteger width = kAppWidth;
    NSInteger height = kAppHeight;
    if (width%2 != 0) {
        width += 1;
    }
    if (height%2 != 0) {
        height += 1;
    }

    //写入视频大小
    CGFloat numPixels = width * height;
    //每像素比特
    CGFloat bitsPerPixel = 6.0;
    CGFloat bitsPerSecond = numPixels * bitsPerPixel;

    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(30),
                                             AVVideoMaxKeyFrameIntervalKey : @(30),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };

    //视频属性
    self.dicVideoSetting = @{ AVVideoCodecKey : AVVideoCodecH264,
                              AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
                              AVVideoWidthKey : @(width),
                              AVVideoHeightKey : @(height),
                              AVVideoCompressionPropertiesKey : compressionProperties };

}

- (void)setAudioWriter:(AVCaptureAudioDataOutput *)audioOutPut
{
    NSDictionary *dicNormal = [audioOutPut recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4];
    self.dicAudioSetting = [[NSMutableDictionary alloc]initWithDictionary:dicNormal];
}

- (void)addInputs
{
    //写入-视频
    if (self.assetVideoWriter && [self.assetWriter canAddInput:self.assetVideoWriter]) {
        [self.assetWriter addInput:self.assetVideoWriter];
    }
    //写入-音频
    if (self.assetAudioWriter && [self.assetWriter canAddInput:self.assetAudioWriter]) {
        [self.assetWriter addInput:self.assetAudioWriter];
    }
}

#pragma mark - public method
- (void)startWritingSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(NSString *)mediaType
{
    if (self.status == KSCaptureWriterWriting) {
        return;
    }

    //开始写入-只执行一次
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        //只有当前buffer是视频的时候开始写入，防止视频一开始黑屏
        if (mediaType == AVMediaTypeVideo) {
            if ([self.assetWriter startWriting]) {
                CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                [self.assetWriter startSessionAtSourceTime:startTime];
                self.status = KSCaptureWriterWriting;
            }
        }
    }
}

- (void)appendWriteSampleBuffer:(CMSampleBufferRef)sampleBuffer mediaType:(NSString *)mediaType
{
    if (sampleBuffer == NULL){
        NSLog(@"empty sampleBuffer");
        return;
    }

    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"sample buffer data is not ready");
        return;
    }

    if (self.status != KSCaptureWriterWriting) {
        return;
    }

    if (self.assetWriter.status == AVAssetWriterStatusFailed) {
        NSLog(@"writer Failed == (%@)", self.assetWriter.error);
        return;
    }
    if (self.assetWriter.status == AVAssetWriterStatusCancelled) {
        NSLog(@"writer cancelled");
        return;
    }
    if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
        NSLog(@"writer completed");
        return;
    }

    //防止写入过程中当前buffer被释放
    CFRetain(sampleBuffer);

    dispatch_async(self.writerQueue, ^{

        @synchronized (self) {

            @autoreleasepool {

                //记录最后写入时间
                CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
                if (duration.value > 0) {
                    timestamp = CMTimeAdd(timestamp, duration);
                }

                //buffer拼接写入
                if (mediaType == AVMediaTypeVideo) {
                    if (self.assetVideoWriter.readyForMoreMediaData) {
                        if ([self.assetVideoWriter appendSampleBuffer:sampleBuffer]) {
                            _videoTimestamp = timestamp;
                        }
                    }
                } else if (mediaType == AVMediaTypeAudio) {
                    if (self.assetAudioWriter && self.assetAudioWriter.readyForMoreMediaData) {
                        if ([self.assetAudioWriter appendSampleBuffer:sampleBuffer]) {
                            _audioTimestamp = timestamp;
                        }
                    }
                }

                //计算写入进度
                [self writerProgress:sampleBuffer];

                //写入完成释放buffer
                CFRelease(sampleBuffer);

            }

        }

    });

}

- (CGFloat)writerProgress:(CMSampleBufferRef)sampleBuffer
{
    static CGFloat fProgress = 0.0;

    CMTime cmBufferDuration = CMSampleBufferGetOutputDuration(sampleBuffer);
    //是否为无效的数字
    if (isnan(CMTimeGetSeconds(cmBufferDuration))) {
        return fProgress;
    }

    //当前buff时长
    CGFloat fBufferDuration = CMTimeGetSeconds(cmBufferDuration);
    //计算总拍摄时长
    self.fDuration += fBufferDuration;
    //计算拍摄进度
    fProgress = self.fDuration/RECORD_MAX_TIME;

    //进度通知代理
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateWriterProgress:)]) {
            [self.delegate updateWriterProgress:fProgress];
            //NSLog(@"writer duration == %0.2f",self.fDuration);
        }
    });

    //超过最大拍摄时间，拍摄完成
    if (fProgress >= 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopWriting];
        });
    }

    return fProgress;
}

- (void)stopWriting
{
    if (self.status != KSCaptureWriterWriting) {
        return;
    }
    if (self.assetWriter.status != AVAssetWriterStatusWriting) {
        return;
    }

    //正在写入，主线程立即更改状态，不在执行buffer的写入操作,但是已经进入写入队列的仍在执行
    self.status = KSCaptureWriterCompleted;

    //结束代码放入串行队列，让写入队列都完成
    dispatch_async(self.writerQueue, ^{
        [self.assetVideoWriter markAsFinished];
        //修改没有音频权限的时候，不调用音频写入完成方法
        if (self.assetAudioWriter) {
            [self.assetAudioWriter markAsFinished];
        }
        [self.assetWriter finishWritingWithCompletionHandler:^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(finishWritingPath:error:)]) {
                [self.delegate finishWritingPath:self.videoPath error:self.assetWriter.error];
            }
        }];
    });

}

- (BOOL)giveUpWriting
{
    //"failed" or "completed," -cancelWriting is a no-op
    if (self.assetWriter.status == AVAssetWriterStatusFailed ||
        self.assetWriter.status == AVAssetWriterStatusCompleted) {
        return NO;
    } else {
        self.status = KSCaptureWriterCancelled;
        //cancelWriting not called concurrently with -[AVAssetWriterInput appendSampleBuffer:]
        dispatch_async(self.writerQueue, ^{
            [self.assetWriter cancelWriting];
        });
        return YES;
    }
}


#pragma mark - get & set
- (AVAssetWriterInput *)assetVideoWriter
{
    if (!_assetVideoWriter) {
        _assetVideoWriter = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.dicVideoSetting];
        _assetVideoWriter.expectsMediaDataInRealTime = YES;
        _assetVideoWriter.transform = CGAffineTransformIdentity;
    }
    return _assetVideoWriter;
}

- (AVAssetWriterInput *)assetAudioWriter
{
    if (!_assetAudioWriter) {
        _assetAudioWriter = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.dicAudioSetting];
        _assetAudioWriter.expectsMediaDataInRealTime = YES;
    }
    return _assetAudioWriter;
}

- (dispatch_queue_t )writerQueue
{
    if (!_writerQueue) {
        _writerQueue = dispatch_queue_create("com.KS.CaptureVideo.VideoWriterQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _writerQueue;
}

@end
