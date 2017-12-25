//
//  KSCaptureConfig.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#ifndef KSCaptureConfig_h
#define KSCaptureConfig_h

#import <AVFoundation/AVFoundation.h>

#define RECORD_MAX_TIME        30.0            //最长录制时间
#define VIDEO_DEFAULTNAME      @"Video.mp4"    //视频文件名（放在doc根目录）

#define kAppWidth              ([UIScreen mainScreen].bounds).size.width
#define kAppHeight             ([UIScreen mainScreen].bounds).size.height
#define KSCaptureFrame         CGRectMake(0, 0, kAppWidth, kAppHeight)//拍摄区域

#define kCanPause              1//是否具有暂停功能 0-否；1-是
#define kCameraMirrored        1//是否前摄像头镜像 0-否；1-是


typedef NS_ENUM(NSInteger ,KSRecordState)
{
    KSRecordStatePrepare = 0,
    KSRecordStateRecording,
    KSRecordStatePause,
    KSRecordStateResume,
    KSRecordStateFinish,
    KSRecordStateFail,
};

//MARK: - FILEPATH
CG_INLINE NSString *docPath()
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
}

//MARK: - COLOR
CG_INLINE UIColor *RGBVCOLOR (long rgbValue)
{
    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0
                           green:((float)((rgbValue & 0xFF00) >> 8))/255.0
                            blue:((float)(rgbValue & 0xFF))/255.0
                           alpha:1.0];
}


CG_INLINE UIColor *RGBVACOLOR (long rgbValue,CGFloat alpha)
{
    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0
                           green:((float)((rgbValue & 0xFF00) >> 8))/255.0
                            blue:((float)(rgbValue & 0xFF))/255.0
                           alpha:alpha];
}

//MARK: - FONT
#define kTextFont            @"Helvetica"
#define kTextBoldFont        @"Helvetica-Bold"
#define kTextFont            @"Helvetica"
#define kTextBoldFont        @"Helvetica-Bold"

CG_INLINE UIFont *KSFont (CGFloat fontSize)
{
    return [UIFont fontWithName: kTextFont size: fontSize];
}

CG_INLINE UIFont *KSBoldFont (CGFloat fontSize)
{
    return [UIFont fontWithName: kTextBoldFont size: fontSize];
}


#endif /* KSCaptureConfig_h */
