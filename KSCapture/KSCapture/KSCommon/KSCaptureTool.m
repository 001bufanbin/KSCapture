//
//  KSCaptureTool.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSCaptureTool.h"
#import <ImageIO/ImageIO.h>

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

+ (UIImage *)fixOrientation:(UIImage *)image
{
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;

    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }

    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }

    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;

        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }

    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
