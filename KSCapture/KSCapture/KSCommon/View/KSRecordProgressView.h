//
//  KSRecordProgressView.h
//  CaptureVideo
//
//  Created by bufb on 2017/6/1.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT CGFloat const kRecordProgressViewLayer_W;

@interface KSRecordProgressView : UIView

- (void)updateProgress:(CGFloat )progress;
- (void)resetProgress;

@end
