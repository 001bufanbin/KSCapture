//
//  KSAVFoundationManager.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSAVFoundationManager.h"

@interface KSAVFoundationManager ()
{
    BOOL _adjustingFocus;
    BOOL _needsSwitchBackToContinuousFocus;
}
@end

@implementation KSAVFoundationManager

static char* SCRecorderFocusContext = "FocusContext";
static char* SCRecorderExposureContext = "ExposureContext";

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[KSMotionManager shareInstance] stopDeviceMotionUpdate];
    if (self.session) {
        //移除输入
        if (self.videoInput) {
            [self removeVideoObservers:self.videoInput.device];
            [self.session removeInput:self.videoInput];
            self.videoInput = nil;
        }
    }
    self.previewLayer = nil;
    self.session = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        [self sessionPresetForPosition:AVCaptureDevicePositionBack];

        //父类统一处理输入-后摄像头
        self.videoInput = self.videoBackInput;
        if ([self.session canAddInput:self.videoInput]) {
            [self.session addInput:self.videoInput];
        }

        //监听当前设备是否正在对焦
        [self addVideoObservers:self.videoInput.device];
        //初始对焦到屏幕中心
        [self focusCenter];
        //监听设备方向
        [[KSMotionManager shareInstance] startDeviceMotionUpdate];

        //监听相机区域较大变动消息
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(subjectAreaDidChange)
                                                     name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - captureRecord method
- (void)showPreviewLayerInView:(UIView *)view
{
    [view.layer insertSublayer:self.previewLayer atIndex:0];
}

- (void)removePreviewLayerInView:(UIView *)view
{
    [self.previewLayer removeFromSuperlayer];
}

/**
 设置session（子类按需求重写）
 */
- (void)sessionPresetForPosition:(AVCaptureDevicePosition )position
{
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }
}

- (void)startSessionRuning
{
    if ([self.session isRunning]) {
        return;
    }
    [self.session startRunning];
}
- (void)stopSessionRuning
{
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
}

- (void)switchTorchModelSuccess:(SwitchTorchSuccessBlock)success failed:(SwitchTorchFailedBlock)failed
{
    //没有手电筒
    if (![self.videoInput.device hasTorch]) {
        if (failed) {
            failed(nil,self.videoInput.device.torchMode);
        }
        return;
    }
    //手电筒不可用-例如手电筒过热
    if (![self.videoInput.device isTorchAvailable]) {
        if (failed) {
            failed(nil,self.videoInput.device.torchMode);
        }
        return;
    }

    NSError *error;
    if (self.videoInput.device.torchMode == AVCaptureTorchModeOff) {
        if ([self.videoInput.device isTorchModeSupported:AVCaptureTorchModeOn]) {
            [self.videoInput.device lockForConfiguration:&error];
            self.videoInput.device.torchMode = AVCaptureTorchModeOn;
            [self.videoInput.device unlockForConfiguration];
        }
    } else if (self.videoInput.device.torchMode == AVCaptureTorchModeOn) {
        if ([self.videoInput.device isTorchModeSupported:AVCaptureTorchModeOff]) {
            [self.videoInput.device lockForConfiguration:&error];
            self.videoInput.device.torchMode = AVCaptureTorchModeOff;
            [self.videoInput.device unlockForConfiguration];
        }
    }

    if (error) {
        if (failed) {
            NSLog(@"torch switch failed error == %@",error);
            failed(error,self.videoInput.device.torchMode);
        }
    } else {
        if (success) {
            NSLog(@"torch switch sucess torch == %ld",(long)self.videoInput.device.torchMode);
            success(self.videoInput.device.torchMode);
        }
    }
}

- (void)switchFlashModelSuccess:(SwitchFlashSuccessBlock)success failed:(SwitchFlashFailedBlock)failed
{
    //没有闪光灯
    if (![self.videoInput.device hasFlash]) {
        if (failed) {
            failed(nil,self.videoInput.device.flashMode);
        }
        return;
    }
    //闪光灯不可用-例如闪光灯过热
    if (![self.videoInput.device isFlashAvailable]) {
        if (failed) {
            failed(nil,self.videoInput.device.flashMode);
        }
        return;
    }

    NSError *error;
    if (self.videoInput.device.flashMode == AVCaptureFlashModeOff) {
        if ([self.videoInput.device isFlashModeSupported:AVCaptureFlashModeOn]) {
            [self.videoInput.device lockForConfiguration:&error];
            self.videoInput.device.flashMode = AVCaptureFlashModeOn;
            [self.videoInput.device unlockForConfiguration];
        }
    } else if (self.videoInput.device.flashMode == AVCaptureFlashModeOn) {
        if ([self.videoInput.device isFlashModeSupported:AVCaptureFlashModeOff]) {
            [self.videoInput.device lockForConfiguration:&error];
            self.videoInput.device.flashMode = AVCaptureFlashModeOff;
            [self.videoInput.device unlockForConfiguration];
        }
    }

    if (error) {
        if (failed) {
            NSLog(@"flash switch failed error == %@",error);
            failed(error,self.videoInput.device.flashMode);
        }
    } else {
        if (success) {
            NSLog(@"flash switch success flash == %ld",(long)self.videoInput.device.flashMode);
            success(self.videoInput.device.flashMode);
        }
    }
}

- (void)switchCameraSuccess:(SwitchCameraSuccessBlock)success failed:(SwitchCameraFailedBlock)failed
{
    BOOL switchSuccess = NO;
    AVCaptureDeviceInput *newInput;
    AVCaptureDeviceInput *oldInput;
    oldInput = self.videoInput;

    [self.session beginConfiguration];

    if (oldInput) {
        [self.session removeInput:oldInput];
        [self removeVideoObservers:oldInput.device];
    }

    AVCaptureDevicePosition position = self.videoInput.device.position;
    if (position == AVCaptureDevicePositionBack) {
        newInput = self.videoFrontInput;
        [self sessionPresetForPosition:AVCaptureDevicePositionFront];
    } else if (position == AVCaptureDevicePositionFront) {
        newInput = self.videoBackInput;
        [self sessionPresetForPosition:AVCaptureDevicePositionBack];
    }

    if ([self.session canAddInput:newInput]) {
        [self.session addInput:newInput];
        [self addVideoObservers:newInput.device];
        switchSuccess = YES;
    }
    //重新设置输入设备
    self.videoInput = newInput;

    //设置方向
    [self setOrientationForConnection];
#if kCameraMirrored
    //设置镜像（所见即所得，文字是翻转的）
    [self setMirroredForDeviceInput];
#endif

    [self.session commitConfiguration];

    if (switchSuccess) {
        if (success) {
            NSLog(@"camera switch sucess position == %ld",(long)self.videoInput.device.position);
            success(self.videoInput.device.position);
        }
    } else {
        if (failed) {
            NSLog(@"camera switch failed!");
            failed(nil, self.videoInput.device.position);
        }
    }
}

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position {
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {

            NSError *error;
            if ([camera lockForConfiguration:&error]) {
                //是否检测设备变化，包括光线、拍摄区域等,系统发送“AVCaptureDeviceSubjectAreaDidChangeNotification”消息
                camera.subjectAreaChangeMonitoringEnabled = YES;
                //是否支持在弱光条件下增强图像
                if (camera.isLowLightBoostSupported) {
                    camera.automaticallyEnablesLowLightBoostWhenAvailable = YES;
                }
                //丝滑对焦
                if (camera.isSmoothAutoFocusSupported) {
                    camera.smoothAutoFocusEnabled = YES;
                }
                [camera unlockForConfiguration];
            } else {
                NSLog(@"Failed to configure device: %@", error);
            }

            return camera;
        }
    }
    return nil;
}

- (void)setVideoConnectionOrientationDefault:(KSCaptureType)type
{
    if (!self.videoConnection || ![self.videoConnection isVideoOrientationSupported]) {
        return;
    }
    switch (type) {
        case KSCapturePhoto:
            [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            break;
        case KSCaptureVideo:
            [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            break;
        default:
            [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            break;
    }

}

//设置视频镜像
- (void)setMirroredForDeviceInput
{
    if (!self.videoConnection || ![self.videoConnection isVideoMirroringSupported])
    {
        return;
    }

    BOOL mirrored = (self.videoInput == self.videoFrontInput);
    self.videoConnection.videoMirrored = mirrored;
}

- (void)setOrientationForConnection
{
    if (!self.videoConnection || ![self.videoConnection isVideoOrientationSupported])
    {
        return;
    }
    AVCaptureVideoOrientation captureOrientation = AVCaptureVideoOrientationPortrait;
    if (self.videoConnection.videoOrientation == captureOrientation) {
        return;
    }
    [self.videoConnection setVideoOrientation:captureOrientation];
}

#pragma mark - FOCUS
//焦点转换
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    return [self.previewLayer captureDevicePointOfInterestForPoint:viewCoordinates];
}
- (CGPoint)convertPointOfInterestToViewCoordinates:(CGPoint)pointOfInterest
{
    return [self.previewLayer pointForCaptureDevicePointOfInterest:pointOfInterest];
}

- (BOOL)focusSupported
{
    return [self.videoInput device].isFocusPointOfInterestSupported;
}
- (CGPoint)focusPointOfInterest
{
    return [self.videoInput device].focusPointOfInterest;
}

- (BOOL)exposureSupported
{
    return [self.videoInput device].isExposurePointOfInterestSupported;
}
- (CGPoint)exposurePointOfInterest {
    return [self.videoInput device].exposurePointOfInterest;
}

- (BOOL)isAdjustingFocus {
    return _adjustingFocus;
}

- (void)setAdjustingFocus:(BOOL)adjustingFocus {
    if (_adjustingFocus != adjustingFocus) {
        [self willChangeValueForKey:@"isAdjustingFocus"];

        _adjustingFocus = adjustingFocus;

        [self didChangeValueForKey:@"isAdjustingFocus"];
    }
}

- (void)setAdjustingExposure:(BOOL)adjustingExposure {
    if (_isAdjustingExposure != adjustingExposure) {
        [self willChangeValueForKey:@"isAdjustingExposure"];

        _isAdjustingExposure = adjustingExposure;

        [self didChangeValueForKey:@"isAdjustingExposure"];
    }
}

//当相机区域较大变动-重新设置对焦、曝光、白平衡
- (void)subjectAreaDidChange
{
    [self focusCenter];
}

//自动对焦到中心点
- (void)focusCenter {
    _needsSwitchBackToContinuousFocus = YES;
    [self autoFocusAtPoint:CGPointMake(0.5, 0.5)];
}
//自动对焦到某个点
- (void)autoFocusAtPoint:(CGPoint)point
{
    [self applyPointOfInterest:point continuousMode:NO];
}

//自动连续对焦
- (void)continuousFocusAtPoint:(CGPoint)point
{
    [self applyPointOfInterest:point continuousMode:YES];
}

//自动对焦完成
- (void)focusDidComplete {
    [self setAdjustingFocus:NO];

    if (_needsSwitchBackToContinuousFocus) {
        _needsSwitchBackToContinuousFocus = NO;
        [self continuousFocusAtPoint:self.focusPointOfInterest];
    }
}

- (void)addVideoObservers:(AVCaptureDevice*)videoDevice {
    [videoDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:SCRecorderFocusContext];
    [videoDevice addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:SCRecorderExposureContext];
}

- (void)removeVideoObservers:(AVCaptureDevice*)videoDevice {
    [videoDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    [videoDevice removeObserver:self forKeyPath:@"adjustingExposure"];
}

//设置对焦、曝光、白平衡
- (void)applyPointOfInterest:(CGPoint)point continuousMode:(BOOL)continuousMode
{
    AVCaptureDevice *videoDevice = self.videoInput.device;
    AVCaptureFocusMode focusMode = continuousMode ? AVCaptureFocusModeContinuousAutoFocus : AVCaptureFocusModeAutoFocus;
    AVCaptureExposureMode exposureMode = continuousMode ? AVCaptureExposureModeContinuousAutoExposure : AVCaptureExposureModeAutoExpose;
    AVCaptureWhiteBalanceMode whiteBalanceMode = continuousMode ? AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance : AVCaptureWhiteBalanceModeAutoWhiteBalance;

    NSError *error;
    if ([videoDevice lockForConfiguration:&error]) {
        BOOL focusing = NO;
        BOOL adjustingExposure = NO;

        //对焦
        //AVCaptureFocusModeLocked-锁定当前对焦
        //AVCaptureFocusModeAutoFocus-第一次自动对焦，然后锁定对焦
        //AVCaptureFocusModeContinuousAutoFocus-自动连续对焦
        if ([videoDevice isFocusPointOfInterestSupported]) {
            videoDevice.focusPointOfInterest = point;
        }
        if ([videoDevice isFocusModeSupported:focusMode]) {
            videoDevice.focusMode = focusMode;
            focusing = YES;
        }

        //曝光
        if ([videoDevice isExposurePointOfInterestSupported]) {
            videoDevice.exposurePointOfInterest = point;
        }
        if ([videoDevice isExposureModeSupported:exposureMode]) {
            videoDevice.exposureMode = exposureMode;
            adjustingExposure = YES;
        }

        //白平衡
        if ([videoDevice isWhiteBalanceModeSupported:whiteBalanceMode]) {
            videoDevice.whiteBalanceMode = whiteBalanceMode;
        }

        [videoDevice unlockForConfiguration];


        if (focusMode != AVCaptureFocusModeContinuousAutoFocus && focusing) {
            [self setAdjustingFocus:YES];
        }

        if (exposureMode != AVCaptureExposureModeContinuousAutoExposure && adjustingExposure) {
            [self setAdjustingExposure:YES];
        }

    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object != self.videoInput.device) {
        return;
    }

    if (context == SCRecorderFocusContext) {
        BOOL isFocusing = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (isFocusing) {
            [self setAdjustingFocus:YES];
        } else {
            [self focusDidComplete];
        }
    } else if (context == SCRecorderExposureContext) {
        BOOL isAdjustingExposure = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        [self setAdjustingExposure:isAdjustingExposure];
    }
}
#pragma mark - videoZoomFactor
- (CGFloat)videoZoomFactor
{
    AVCaptureDevice *device = self.videoInput.device;
    if ([device respondsToSelector:@selector(videoZoomFactor)]) {
        return device.videoZoomFactor;
    }
    return 1;
}

- (void)setVideoZoomFactor:(CGFloat)videoZoomFactor
{
    AVCaptureDevice *device = self.videoInput.device;

    if ([device respondsToSelector:@selector(videoZoomFactor)]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            if (videoZoomFactor <= device.activeFormat.videoMaxZoomFactor) {
                device.videoZoomFactor = videoZoomFactor;
            } else {
                NSLog(@"Unable to set videoZoom: (max %f, asked %f)", device.activeFormat.videoMaxZoomFactor, videoZoomFactor);
            }

            [device unlockForConfiguration];
        } else {
            NSLog(@"Unable to set videoZoom: %@", error.localizedDescription);
        }
    }
}

#pragma mark - get & set
#pragma mark Session
- (AVCaptureSession *)session
{
    if (!_session) {
        _session = [[AVCaptureSession alloc]init];
    }
    return _session;
}

#pragma mark Input
- (AVCaptureDeviceInput *)videoBackInput
{
    if (!_videoBackInput) {
        AVCaptureDevice *videoDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
        NSError *error;
        _videoBackInput = [[AVCaptureDeviceInput alloc]initWithDevice:videoDevice error:&error];

        if (error) {
            NSLog(@"videoBackInput init error == %@",error);
        } else {
            //设置默认初始化闪光灯状态-关闭
            if ([_videoBackInput.device hasFlash] && [_videoBackInput.device isFlashAvailable]) {
                [_videoBackInput.device lockForConfiguration:nil];
                _videoBackInput.device.flashMode = AVCaptureFlashModeOff;
                [_videoBackInput.device unlockForConfiguration];
            }
        }
    }
    return _videoBackInput;
}

- (AVCaptureDeviceInput *)videoFrontInput
{
    if (!_videoFrontInput) {
        AVCaptureDevice *videoDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];
        NSError *error;
        _videoFrontInput = [[AVCaptureDeviceInput alloc]initWithDevice:videoDevice error:&error];

        if (error) {
            NSLog(@"videoFrontInput init error == %@",error);
        } else {
            //设置默认初始化闪光灯状态-关闭
            if ([_videoFrontInput.device hasFlash] && [_videoBackInput.device isFlashAvailable]) {
                [_videoFrontInput.device lockForConfiguration:nil];
                _videoFrontInput.device.flashMode = AVCaptureFlashModeOff;
                [_videoFrontInput.device unlockForConfiguration];
            }
        }
    }
    return _videoFrontInput;
}

#pragma mark PreViewLayer
- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        //AVLayerVideoGravityResizeAspect--等比，适应最大值，不会裁剪
        //AVLayerVideoGravityResizeAspectFill--等比，适应最小值，裁剪
        //AVLayerVideoGravityResize--不等比，拉伸
        _previewLayer.frame = KSCaptureFrame;
    }
    return _previewLayer;
}

@end
