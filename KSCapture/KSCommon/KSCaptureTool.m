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

@end
