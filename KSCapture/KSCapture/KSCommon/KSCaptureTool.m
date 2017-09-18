//
//  KSCaptureTool.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSCaptureTool.h"

@implementation KSCaptureTool

+ (instancetype)share{
    static KSCaptureTool *tool = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        tool = [[KSCaptureTool alloc] init];
    });
    return tool;
}

//写入的视频路径
+ (NSString *)videoFilePath
{
    NSString *path = [docPath() stringByAppendingPathComponent:VIDEO_DEFAULTNAME];
    return path;
}

+ (BOOL)deleteCurrentVideo:(NSString *)videoPath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        return [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    }
    return YES;
}

+ (BOOL)deleteVideo
{
    NSString *videoPath = [self videoFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        return [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    }
    return NO;
}

+ (BOOL)isAllowAccessMicrophone
{
    BOOL isAllowAccess = NO;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:
            isAllowAccess = NO;
            break;
        case AVAuthorizationStatusRestricted:
            isAllowAccess = NO;
            break;
        case AVAuthorizationStatusDenied:
            isAllowAccess = NO;
            break;
        case AVAuthorizationStatusAuthorized:
            isAllowAccess = YES;
            break;
        default:
            break;
    }
    return isAllowAccess;
}

+ (BOOL)isAllowAccessCamera
{
    BOOL isAllowAccess = NO;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:
            isAllowAccess = NO;
            break;
        case AVAuthorizationStatusRestricted:
            isAllowAccess = NO;
            break;
        case AVAuthorizationStatusDenied:
            isAllowAccess = NO;
            break;
        case AVAuthorizationStatusAuthorized:
            isAllowAccess = YES;
            break;
        default:
            break;
    }
    return isAllowAccess;
}

+ (CMSampleBufferRef)createOffsetSampleBufferWithSampleBuffer:(CMSampleBufferRef)sampleBuffer withTimeOffset:(CMTime)timeOffset
{
    CMItemCount itemCount;

    OSStatus status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, NULL, &itemCount);
    if (status) {
        return NULL;
    }

    CMSampleTimingInfo *timingInfo = (CMSampleTimingInfo *)malloc(sizeof(CMSampleTimingInfo) * (unsigned long)itemCount);
    if (!timingInfo) {
        return NULL;
    }

    status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, itemCount, timingInfo, &itemCount);
    if (status) {
        free(timingInfo);
        timingInfo = NULL;
        return NULL;
    }

    for (CMItemCount i = 0; i < itemCount; i++) {
        timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, timeOffset);
        timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, timeOffset);
    }

    CMSampleBufferRef offsetSampleBuffer;
    CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBuffer, itemCount, timingInfo, &offsetSampleBuffer);

    if (timingInfo) {
        free(timingInfo);
        timingInfo = NULL;
    }

    return offsetSampleBuffer;
}

@end
