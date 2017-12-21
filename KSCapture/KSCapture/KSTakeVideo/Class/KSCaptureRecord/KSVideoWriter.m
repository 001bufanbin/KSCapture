//
//  KSVideoWriter.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSVideoWriter.h"

#define kKSWriterQueueKey "KSWriterQueueKey"
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
@property (nonatomic ,strong)NSDictionary *dicAudioSetting;

//当前写入时长
@property (nonatomic ,assign)CGFloat fDuration;
//写入路径
@property (nonatomic ,copy)NSString *videoPath;
//对象内部使用的状态
@property (nonatomic ,assign)KSCaptureWriterStatus status;
//写入时设备方向
@property (nonatomic ,assign)UIDeviceOrientation deviceOrientation;
//视频写入方向
@property (nonatomic ,assign)AVCaptureVideoOrientation captureOrientation;

@end

@implementation KSVideoWriter

- (void)dealloc
{

}

- (instancetype)initWithVideoPath:(NSString *)videoPath currentDeviceOrientation:(UIDeviceOrientation)deviceOrientation;
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
        assetWriter.shouldOptimizeForNetworkUse = YES;
        self.assetWriter = assetWriter;

        if (error) {
            NSLog(@"assetwriter init error == %@",error);
        }

        //设置方向
        self.deviceOrientation = deviceOrientation;
        //添加输入
        [self addInputs];
    }
    return self;
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
            NSLog(@"writer duration == %0.2f",self.fDuration);
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
        [self dispatchSyncOnWriterQueue:^{
            [self.assetWriter cancelWriting];
        }];
        return YES;
    }
}

// MARK: - 安全的同步执行writerQueue,防止deadLock
- (void)dispatchSyncOnWriterQueue:(void(^)())block
{
    if ([self isOnWriterQueue]) {
        block();
    } else {
        dispatch_sync(self.writerQueue, block);
    }
}

- (BOOL)isOnWriterQueue {
    return dispatch_get_specific(kKSWriterQueueKey) != nil;
}

#pragma mark - get & set
- (void)setDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    _deviceOrientation = deviceOrientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            self.captureOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.captureOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortrait:
            self.captureOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            self.captureOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            break;
    }
}

- (AVAssetWriterInput *)assetVideoWriter
{
    if (!_assetVideoWriter) {
        _assetVideoWriter = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.dicVideoSetting];
        _assetVideoWriter.expectsMediaDataInRealTime = YES;

        switch (self.captureOrientation) {
            case AVCaptureVideoOrientationPortrait:
                break;
            case AVCaptureVideoOrientationLandscapeRight:
                _assetVideoWriter.transform = CGAffineTransformMakeRotation(M_PI/2*3);
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
                _assetVideoWriter.transform = CGAffineTransformMakeRotation(M_PI/2);
                break;
            case AVCaptureVideoOrientationPortraitUpsideDown:
                _assetVideoWriter.transform = CGAffineTransformMakeRotation(M_PI/2*2);
                break;
            default:
                break;
        }
        
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
        //给队列设置标识key
        dispatch_queue_set_specific(_writerQueue, kKSWriterQueueKey, "true", nil);
    }
    return _writerQueue;
}

- (NSDictionary *)dicAudioSetting
{
    if (!_dicAudioSetting) {
        //AVAudioSettings.h
        /*
         * AVFormatIDKey: 音频编码方式
         * AVSampleRateKey: 音频采样率HZ
         * AVNumberOfChannelsKey: 音轨数（单声道，双声道等）
         * AVEncoderBitRateKey: 编码比特率
         * AVEncoderBitRatePerChannelKey: 每个音轨的编码比特率，和AVEncoderBitRateKey只设置一个即可
         * AVEncoderBitRateStrategyKey: 编码策略
         * kAudioChannelLayoutTag: 声道设置（单声道、立体声、左环绕、右环绕等）
         */

        //音频设置
        _dicAudioSetting = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                             AVSampleRateKey:@(44100.0),
                             AVNumberOfChannelsKey:@(1),
                             AVEncoderBitRateKey:@(64000)};
    }
    return _dicAudioSetting;
}

- (NSDictionary *)dicVideoSetting
{
    if (!_dicVideoSetting) {
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

        /**
         视频相关配置：
         AVVideoAllowFrameReorderingKey:是否启用帧重新排序，关闭可提高性能，默认YES（为了在保持图像质量的同时实现最佳压缩，一些视频编码器可以对帧重新排序）
         AverageBitRate：每秒比特率bps（Bit Per Second），决定视频每秒大小（视频体积=视频码率*时间）
         AVVideoExpectedSourceFrameRateKey：每秒帧率FPS(Frames Per Second)
         AVVideoMaxKeyFrameIntervalKey:关键帧之间的最大间隔帧数（每隔几个帧设置为关键帧），越大压缩率越高
         AVVideoMaxKeyFrameIntervalDurationKey：每个关键帧之间的最大时间间隔
         上面这俩属性限制都会执行以先设置者为准，每X帧一个关键帧或者每Y秒一个关键帧
         AVVideoProfileLevelKey:Baseline-基本画质。支持I/P 帧，只支持无交错（Progressive）和CAVLC；Main-主流画质。提供I/P/B 帧，支持无交错（Progressive）和交错（Interlaced），也支持CAVLC 和CABAC 的支持；High-高级画质。在main Profile 的基础上增加了8×8内部预测、自定义量化、 无损视频编码和更多的YUV 格式；
         */

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
        _dicVideoSetting = @{ AVVideoCodecKey : AVVideoCodecH264,
                              AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
                              AVVideoWidthKey : @(width),
                              AVVideoHeightKey : @(height),
                              AVVideoCompressionPropertiesKey : compressionProperties };
    }
    return _dicVideoSetting;
}

@end
