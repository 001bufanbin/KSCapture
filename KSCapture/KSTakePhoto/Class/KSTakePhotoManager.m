//
//  KSTakePhotoManager.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSTakePhotoManager.h"

@interface KSTakePhotoManager ()

@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;   //照片输出流

@end

@implementation KSTakePhotoManager

- (instancetype)init
{
    self = [super init];
    if (self) {

        if ([self.session canAddOutput:self.stillImageOutput]) {
            [self.session addOutput:self.stillImageOutput];
        }

        //设置输出初始方向
        [self setVideoConnectionOrientationDefault:KSCapturePhoto];
    }
    return self;
}

// MARK: - 设置-Session
- (void)sessionPresetForPosition:(AVCaptureDevicePosition )position
{
    if (position == AVCaptureDevicePositionBack) {
        if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];
        }
    } else {
        if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
        }
    }
}

- (void)takePhotoSuccess:(TakePhotoSuccessBlock)success failed:(TakePhotoFailedBlock)failed
{
    AVCaptureConnection *stillImageConnection = self.videoConnection;
    if (!stillImageConnection) {
        if (failed) {
            failed(nil);
        }
        return;
    }
    //设置拍摄方向
    self.deviceOrientation = [KSMotionManager shareInstance].orientation;
    [self setOrientationForConnection];
    //拍摄图片
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                       completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                           if (!error && CMSampleBufferIsValid(imageDataSampleBuffer)) {
                                                               NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                               //将data图片数据转为image对象
                                                               UIImage *image = [UIImage imageWithData:jpegData];
                                                               _imgPhoto = image;
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   if (success) {
                                                                       success(_imgPhoto);
                                                                   }
                                                               });
                                                           }else{
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   if (failed) {
                                                                       failed(error);
                                                                   }
                                                               });
                                                           }
                                                       }];
}

#pragma mark - get & set
#pragma mark 照片输出
- (AVCaptureStillImageOutput *)stillImageOutput
{
    if (!_stillImageOutput) {
        _stillImageOutput = [[AVCaptureStillImageOutput alloc]init];
        NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
        [_stillImageOutput setOutputSettings:outputSettings];
    }
    return _stillImageOutput;
}

- (AVCaptureConnection *)videoConnection
{
    return [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
}

@end
