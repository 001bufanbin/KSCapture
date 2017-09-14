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

////设备输入源
@property (nonatomic ,strong)AVCaptureDeviceInput *audioInput;
////设备输出源
@property (nonatomic ,strong)AVCaptureVideoDataOutput *videoOutPut;
@property (nonatomic ,strong)AVCaptureAudioDataOutput *audioOutPut;
//视频写入
@property (nonatomic ,strong)KSVideoWriter   *writer;
//视频存放路径
@property (nonatomic ,copy)NSString *videoPath;
//视频输出队列
@property (nonatomic ,strong)dispatch_queue_t outPutQueue;

@end

@implementation KSTakeVideoManager

- (void)dealloc
{
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

    }
    return self;
}

- (void)startRecord
{
    [self initAssetWriter];
    _recordState = KSRecordStateRecording;
}
- (void)pauseRecord
{
    _recordState = KSRecordStatePause;
}
- (void)resumeRecord
{
    _recordState = KSRecordStateResume;
}
- (void)stopRecord
{
    if (_recordState != KSRecordStateRecording) {
        return;
    }

    [self.writer stopWriting];
    _recordState = KSRecordStateFinish;
}

- (void)giveUpRecord
{
    if (self.recordState == KSRecordStateRecording) {
        if (![self.writer giveUpWriting]) {
            [self.writer stopWriting];
            [self deleteCurrentVideo];
        }
    } else {
        [self deleteCurrentVideo];
    }

    _recordState = KSRecordStatePrepare;
}

- (BOOL)deleteCurrentVideo
{
    return [KSCaptureTool deleteCurrentVideo:self.videoPath];
}

#pragma mark - ApplicationNotification
//如果当前未开始录制-App进入后台，则停止session；进入前台之后开始session
//如果当前开始录制-App进入后台，则停止录制；进入前台之后开始回调到代理对象的完成函数，开始播放
//如果当前录制完成正在播放-啥也不用干
- (void)appWillResignActive
{
    if (_recordState == KSRecordStatePrepare) {
        [self stopSessionRuning];
    } else if (_recordState == KSRecordStateRecording) {
        [self stopRecord];
    } else if (_recordState == KSRecordStateFinish) {

    }
}

- (void)appDidBecomeActive
{
    if (_recordState == KSRecordStatePrepare) {
        [self startSessionRuning];
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

    if (self.recordState != KSRecordStateRecording) {
        return;
    }

    //加锁-当前状态属性改变，写完当前的buffer
    @synchronized (self) {

        @autoreleasepool {

            //防止写入过程中当前buffer被释放
            CFRetain(sampleBuffer);

            if (captureOutput == self.videoOutPut) {
                [self.writer startWritingSampleBuffer:sampleBuffer mediaType:AVMediaTypeVideo];
                [self.writer appendWriteSampleBuffer:sampleBuffer mediaType:AVMediaTypeVideo];
            } else if (captureOutput == self.audioOutPut) {
                [self.writer startWritingSampleBuffer:sampleBuffer mediaType:AVMediaTypeAudio];
                [self.writer appendWriteSampleBuffer:sampleBuffer mediaType:AVMediaTypeAudio];
            }

            //写入完成释放buffer
            CFRelease(sampleBuffer);
        }

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
    //记录开始录制时候设备方向
    self.deviceOrientation = [KSMotionManager shareInstance].orientation;
    //设置视频方向
    [self setOrientationForConnection];

    KSVideoWriter *writer = [[KSVideoWriter alloc]initWithVideoPath:self.videoPath];
    [writer setVideoWriter:self.videoOutPut];
    if (self.audioOutPut) {
        [writer setAudioWriter:self.audioOutPut];
    }
    //writer.deviceOrientation = [KSMotionManager shareInstance].orientation;
    [writer addInputs];
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
