//
//  KSTakeVideoManager.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSTakeVideoManager.h"
#import "KSVideoWriter.h"

@interface KSTakeVideoManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,KSVideoWriterDelegate>

//设备输入源
@property (nonatomic ,strong)AVCaptureDeviceInput *audioInput;
//设备输出源
@property (nonatomic ,strong)AVCaptureVideoDataOutput *videoOutPut;
@property (nonatomic ,strong)AVCaptureAudioDataOutput *audioOutPut;
//视频写入
@property (nonatomic ,strong)KSVideoWriter   *writer;
//视频存放路径
@property (nonatomic ,copy)NSString *videoPath;
//视频输出队列
@property (nonatomic ,strong)dispatch_queue_t outPutQueue;

//是否暂停->恢复
@property (nonatomic ,assign)BOOL pausedToResume;
//暂停时间偏移
@property (nonatomic ,assign)CMTime timeOffset;

@end

@implementation KSTakeVideoManager

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self deallocSession];
}

- (void)deallocSession
{
    if (self.session) {
        //移除输入
        if (self.audioInput) {
            [self.session removeInput:self.audioInput];
            self.audioInput = nil;
        }
        //移除输出
        if (self.videoOutPut) {
            [self.session removeOutput:self.videoOutPut];
            self.videoOutPut = nil;
        }
        if (self.audioOutPut) {
            [self.session removeOutput:self.audioOutPut];
            self.audioOutPut = nil;
        }
    }

    //移除写入
    self.writer = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _recordState = KSRecordStatePrepare;
        self.videoPath = [KSCaptureTool videoFilePath];
        self.pausedToResume = NO;
        self.timeOffset = kCMTimeInvalid;
        //输入-音频
        if (self.audioInput && [self.session canAddInput:self.audioInput]) {
            [self.session addInput:self.audioInput];
        }
        //输出-视频
        if ([self.session canAddOutput:self.videoOutPut]) {
            [self.session addOutput:self.videoOutPut];
        }
        //设置输出初始方向
        [self setVideoConnectionOrientationDefault:KSCaptureVideo];
        //输出-音频
        if (self.audioOutPut && [self.session canAddOutput:self.audioOutPut]) {
            [self.session addOutput:self.audioOutPut];
        }

        //监听进入后台
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillResignActive)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];

        //监听进入前台
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];

    }
    return self;
}

- (void)setOrientationForConnection
{
    if (!self.videoConnection || ![self.videoConnection isVideoOrientationSupported])
    {
        return;
    }
    AVCaptureVideoOrientation captureOrientation = AVCaptureVideoOrientationPortrait;
#if kCameraMirrored
    captureOrientation = AVCaptureVideoOrientationPortrait;
#else
    if (self.videoInput == self.videoBackInput) {
        captureOrientation = AVCaptureVideoOrientationPortrait;
    } else if (self.videoInput == self.videoFrontInput) {
        switch (self.deviceOrientation) {
            case UIDeviceOrientationPortrait:
                captureOrientation = AVCaptureVideoOrientationPortrait;
                break;
            case UIDeviceOrientationLandscapeRight:
                captureOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;

            case UIDeviceOrientationLandscapeLeft:
                captureOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                captureOrientation = AVCaptureVideoOrientationPortrait;
                break;
            default:
                captureOrientation = AVCaptureVideoOrientationPortrait;
                break;
        }
    }
#endif

    if (self.videoConnection.videoOrientation == captureOrientation) {
        return;
    }
    [self.videoConnection setVideoOrientation:captureOrientation];
}

- (void)startRecord
{
    if (![KSCaptureTool isAllowAccessCamera] || ![KSCaptureTool isAllowAccessMicrophone]) {
        NSLog(@"请打开相机、麦克风权限！");
        return;
    }
    self.pausedToResume = NO;
    self.timeOffset = kCMTimeInvalid;
    [self initAssetWriter];
    _recordState = KSRecordStateRecording;
}
- (void)pauseRecord
{
    self.pausedToResume = NO;
    _recordState = KSRecordStatePause;
}
- (void)resumeRecord
{
    self.pausedToResume = YES;
    _recordState = KSRecordStateResume;
}
- (void)stopRecord
{
#if kCanPause
    //在拍摄中、暂停、恢复拍摄，三个状态都可能停止
    if (self.recordState == KSRecordStateRecording ||
        self.recordState == KSRecordStatePause     ||
        self.recordState == KSRecordStateResume) {
        [self.writer stopWriting];
        self.pausedToResume = NO;
        self.timeOffset = kCMTimeInvalid;
        _recordState = KSRecordStateFinish;
    }
#else
    if (self.recordState == KSRecordStateRecording) {
        [self.writer stopWriting];
        _recordState = KSRecordStateFinish;
    }
#endif
}

- (void)giveUpRecord
{
#if kCanPause
    if (self.recordState == KSRecordStateRecording ||
        self.recordState == KSRecordStatePause     ||
        self.recordState == KSRecordStateResume) {
        if (![self.writer giveUpWriting]) {
            [self.writer stopWriting];
            [self deleteCurrentVideo];
        }
    } else {
        [self deleteCurrentVideo];
    }
    self.pausedToResume = NO;
    self.timeOffset = kCMTimeInvalid;
    _recordState = KSRecordStatePrepare;
#else
    if (self.recordState == KSRecordStateRecording) {
        if (![self.writer giveUpWriting]) {
            [self.writer stopWriting];
            [self deleteCurrentVideo];
        }
    } else {
        [self deleteCurrentVideo];
    }
    _recordState = KSRecordStatePrepare;
#endif
}

- (BOOL)deleteCurrentVideo
{
    return [KSCaptureTool deleteCurrentVideo:self.videoPath];
}

#pragma mark - ApplicationNotification
//如果当前未开始录制-App进入后台，啥也不用干，系统管理session的start和stop
//如果当前开始录制-App进入后台，则停止录制；进入前台之后开始回调到代理对象的完成函数，开始播放
//如果当前录制完成正在播放-啥也不用干
- (void)appWillResignActive
{
    if (_recordState == KSRecordStatePrepare) {

    } else if (_recordState == KSRecordStateRecording) {
        [self stopRecord];
    } else if (_recordState == KSRecordStateFinish) {

    }
}

- (void)appDidBecomeActive
{
    if (_recordState == KSRecordStatePrepare) {

    } else if (_recordState == KSRecordStateRecording) {

    } else if (_recordState == KSRecordStateFinish) {

    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (sampleBuffer == NULL) {
        NSLog(@"sampleBuffer == NULL");
        return;
    }

    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"sample buffer data is not ready");
        return;
    }

#if kCanPause
    //正在拍摄、恢复拍摄两个状态下才写入
    if (self.recordState != KSRecordStateRecording &&
        self.recordState != KSRecordStateResume) {
        return;
    }
#else
    if (self.recordState != KSRecordStateRecording) {
        return;
    }
#endif

    //加锁-当前状态属性改变，写完当前的buffer
    @synchronized (self) {

        @autoreleasepool {

            //防止写入过程中当前buffer被释放
            CFRetain(sampleBuffer);

            //计算暂停-恢复时间偏移；只在写入音频里面进行，防止两次计算偏移
            if (self.pausedToResume) {
                if (captureOutput == self.videoOutPut) {
                    CFRelease(sampleBuffer);
                    return;
                }
                [self calcuTimeOffsetForCurrentOutputSampleBuffer:sampleBuffer];
                self.pausedToResume = NO;
            }

            //处理最终写入文件的buffer
            CMSampleBufferRef bufferToWrite = NULL;
            if (CMTIME_IS_VALID(self.timeOffset)) {
                bufferToWrite = [KSCaptureTool createOffsetSampleBufferWithSampleBuffer:sampleBuffer withTimeOffset:self.timeOffset];
            } else {
                bufferToWrite = sampleBuffer;
                CFRetain(bufferToWrite);
            }

            //写入操作
            if (captureOutput == self.videoOutPut) {
                [self.writer startWritingSampleBuffer:bufferToWrite mediaType:AVMediaTypeVideo];
                [self.writer appendWriteSampleBuffer:bufferToWrite mediaType:AVMediaTypeVideo];
            } else if (captureOutput == self.audioOutPut) {
                [self.writer startWritingSampleBuffer:bufferToWrite mediaType:AVMediaTypeAudio];
                [self.writer appendWriteSampleBuffer:bufferToWrite mediaType:AVMediaTypeAudio];
            }

            //写入完成释放buffer
            if (bufferToWrite) {
                CFRelease(bufferToWrite);
            }
            CFRelease(sampleBuffer);
        }

    }

}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

}

- (void)calcuTimeOffsetForCurrentOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CMTime currentTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (CMTIME_IS_VALID(currentTimestamp) && CMTIME_IS_VALID(self.writer.audioTimestamp)) {
        if (CMTIME_IS_VALID(self.timeOffset)) {
            currentTimestamp = CMTimeSubtract(currentTimestamp, self.timeOffset);
        }
        CMTime offset = CMTimeSubtract(currentTimestamp, self.writer.audioTimestamp);
        self.timeOffset = CMTIME_IS_INVALID(self.timeOffset) ? offset : CMTimeAdd(self.timeOffset, offset);
        NSLog(@"audioTimestamp == %f",CMTimeGetSeconds(self.writer.audioTimestamp));
        NSLog(@"offset == %f",CMTimeGetSeconds(offset));
        NSLog(@"new calculated offset %f valid (%d)", CMTimeGetSeconds(self.timeOffset), CMTIME_IS_VALID(self.timeOffset));
    }
}

#pragma mark - KSVideoWriterDelegate
- (void)updateWriterProgress:(CGFloat)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(currentRecordProgress:)]) {
            [self.delegate currentRecordProgress:progress];
        }
    });

}

- (void)finishWritingPath:(NSString *)videoPath error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(finishRecordPath:error:)]) {
            [self.delegate finishRecordPath:self.videoPath error:error];
        }
    });

    if (error) {
        //出错重置为初始状态
        _recordState = KSRecordStatePrepare;
    } else {
        _recordState = KSRecordStateFinish;
    }
}


#pragma mark - get & set
#pragma mark Input
- (AVCaptureDeviceInput *)audioInput
{
    if (!_audioInput) {
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
        if (error) {
            NSLog(@"audioInput init error == %@",error);
        }
    }
    return _audioInput;
}

#pragma mark OutPut
- (AVCaptureVideoDataOutput *)videoOutPut
{
    if (!_videoOutPut) {
        _videoOutPut = [[AVCaptureVideoDataOutput alloc]init];
        //立即丢弃旧帧，节省内存，默认YES
        _videoOutPut.alwaysDiscardsLateVideoFrames = YES;
        [_videoOutPut setSampleBufferDelegate:self queue:self.outPutQueue];
    }
    return _videoOutPut;
}

- (AVCaptureAudioDataOutput *)audioOutPut
{
    if (!_audioOutPut) {
        _audioOutPut = [[AVCaptureAudioDataOutput alloc]init];
        [_audioOutPut setSampleBufferDelegate:self queue:self.outPutQueue];
    }
    return _audioOutPut;
}

- (AVCaptureConnection *)videoConnection
{
    return [self.videoOutPut connectionWithMediaType:AVMediaTypeVideo];
}

#pragma mark Writer
- (void)initAssetWriter
{
    self.deviceOrientation = [KSMotionManager shareInstance].orientation;
    KSVideoWriter *writer = [[KSVideoWriter alloc]initWithVideoPath:self.videoPath
                                           currentDeviceOrientation:self.deviceOrientation];
    writer.delegate = self;
    self.writer = writer;
}

#pragma mark Queue
- (dispatch_queue_t )outPutQueue
{
    if (!_outPutQueue) {
        _outPutQueue = dispatch_queue_create("com.KS.CaptureVideo.VideoOutPutQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _outPutQueue;
}

@end
