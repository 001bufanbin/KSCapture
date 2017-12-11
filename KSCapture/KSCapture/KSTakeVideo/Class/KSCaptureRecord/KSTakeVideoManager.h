//
//  KSTakeVideoManager.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSAVFoundationManager.h"

@protocol KSTakeVideoManagerDelegate <NSObject>

/**
 当前拍摄进度（实时更新）

 @param progress 当前进度（0-1）
 */
- (void)currentRecordProgress:(CGFloat )progress;

/**
 拍摄完成

 @param videoPath 视频文件地址
 */
- (void)finishRecordPath:(NSString *)videoPath error:(NSError *)error;


@end

@interface KSTakeVideoManager : KSAVFoundationManager

@property (nonatomic ,weak)id <KSTakeVideoManagerDelegate> delegate;
@property (nonatomic ,assign ,readonly)KSRecordState recordState;

/**
 开始录制
 */
- (void)startRecord;

/**
 暂停录制
 */
- (void)pauseRecord;

/**
 恢复录制
 */
- (void)resumeRecord;

/**
 停止录制
 */
- (void)stopRecord;

/**
 放弃当前拍摄的视频
 */
- (void)giveUpRecord;

@end
