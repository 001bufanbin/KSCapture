//
//  KSTakeVideoOperateView.h
//  KSCapture
//
//  Created by bufb on 2017/6/5.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSCaptureConfig.h"

@protocol KSTakeVideoOperateViewDelegate <NSObject>

- (void)btnDisMissClicked:(UIButton *)btn;
- (void)btnRightClicked:(UIButton *)btn;

- (void)btnRecordClicked:(UIButton *)btn;
- (void)btnFlashSwitchClicked:(UIButton *)btn;
- (void)btnCameraSwitchClicked:(UIButton *)btn;

- (void)btnGiveUpClicked:(UIButton *)btn;
- (void)btnSureClicked:(UIButton *)btn;

@end

@interface KSTakeVideoOperateView : UIView

@property (nonatomic ,weak)id <KSTakeVideoOperateViewDelegate> delegate;

- (void)setViewCamera:(KSRecordState)state;
- (void)setBtnTorchForMode:(AVCaptureTorchMode)mode;
- (void)setBtnCameraForPosition:(AVCaptureDevicePosition)position;

- (void)upDateProgress:(CGFloat)progress;
@end
