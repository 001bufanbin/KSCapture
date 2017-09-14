//
//  KSTakeVideoOperateView.m
//  KSCapture
//
//  Created by bufb on 2017/6/5.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSTakeVideoOperateView.h"
#import "KSRecordProgressView.h"

//顶部视图
static CGFloat const kTopView_H    = 64;
static CGFloat const kBtnTop_X     = 4;
static CGFloat const kBtnTop_Y     = 20;
static CGFloat const kBtnTop_W     = 60;
static CGFloat const kBtnTop_H     = 44;
//拍摄视图
static CGFloat const kViewRecord_H = 130;
static CGFloat const kBtnRecord_W  = 74;
static CGFloat const kBtnRecord_H  = 74;
static CGFloat const kProgress_W   = 100;
static CGFloat const kProgress_H   = 100;
//拍摄完成视图
static CGFloat const kViewFinish_H = 50;


@interface KSTakeVideoOperateView ()

@property (nonatomic ,strong)UIView   *viewTop;     //顶部视图
@property (nonatomic ,strong)UIButton *btnDissmiss; //退出拍摄
@property (nonatomic ,strong)UILabel  *labTitle;    //标题
@property (nonatomic ,strong)UIButton *btnCamera;   //摄像头切换

@property (nonatomic ,strong)UIView   *viewRecord;  //底部拍摄视图
@property (nonatomic ,strong)UIButton *btnRecord;   //拍摄按钮
@property (nonatomic ,strong)KSRecordProgressView *progressView;//进度
@property (nonatomic ,strong)UIButton *btnFlash;    //闪关灯切换

@property (nonatomic ,strong)UIView   *viewFinish;  //拍摄完成视图
@property (nonatomic ,strong)UIButton *btnGiveUp;   //放弃按钮
@property (nonatomic ,strong)UIButton *btnSure;     //保存按钮

@property (nonatomic ,assign)CGRect rectViewRecordShow;
@property (nonatomic ,assign)CGRect rectViewRecordHidden;
@property (nonatomic ,assign)CGRect rectViewFinishShow;
@property (nonatomic ,assign)CGRect rectViewFinishHidden;
@property (nonatomic ,assign)CGRect rectBtnRecordNormal;
@property (nonatomic ,assign)CGRect rectBtnRecordRecording;

@end

@implementation KSTakeVideoOperateView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    [self initRectForState];
    
    [self initTopView];
    [self initRecordView];
    [self initFinishView];
}

- (void)initTopView
{
    [self addSubview:self.viewTop];
    
    [self.viewTop addSubview:self.btnDissmiss];
    [self.viewTop addSubview:self.labTitle];
}

- (void)initRecordView
{
    [self addSubview:self.viewRecord];
    
    [self.viewRecord addSubview:self.btnRecord];
    [self.viewRecord addSubview:self.progressView];
    [self.viewRecord addSubview:self.btnFlash];
}

- (void)initFinishView
{
    [self addSubview:self.viewFinish];
    
    [self.viewFinish addSubview:self.btnGiveUp];
    [self.viewFinish addSubview:self.btnSure];
}

- (void)initRectForState
{
    self.rectViewRecordShow   = CGRectMake(0, kAppHeight-kViewRecord_H, kAppWidth, kViewRecord_H);
    self.rectViewRecordHidden = CGRectMake(0, kAppHeight, kAppWidth, kViewRecord_H);
    self.rectViewFinishShow   = CGRectMake(0, kAppHeight-kViewFinish_H, kAppWidth, kViewFinish_H);
    self.rectViewFinishHidden = CGRectMake(0, kAppHeight, kAppWidth, kViewFinish_H);
    
    self.rectBtnRecordNormal  = CGRectMake((kAppWidth-kBtnRecord_W)/2, (kViewRecord_H-kBtnRecord_H)/2, kBtnRecord_W, kBtnRecord_H);
    self.rectBtnRecordRecording  = CGRectMake((kAppWidth-kProgress_W)/2, (kViewRecord_H-kProgress_H)/2, kProgress_W, kProgress_H);
}

#pragma mark - private method
- (void)setViewRecordForState:(KSRecordState)state
{
    switch (state) {
        case KSRecordStatePrepare:
        {
            //取消按钮
            self.btnDissmiss.hidden = NO;
            //拍摄按钮
            self.btnRecord.frame = self.rectBtnRecordNormal;
            _btnRecord.layer.cornerRadius = kBtnRecord_W/2;
            self.btnRecord.layer.borderWidth = 10.0;
            [self.btnRecord setTitle:@"拍摄" forState:UIControlStateNormal];
            //拍摄页面
            [UIView animateWithDuration:0.2 animations:^{
                self.viewRecord.frame = self.rectViewRecordShow;
            }];
            //拍摄完成页面
            self.viewFinish.frame = self.rectViewFinishHidden;
        }
            break;
        case KSRecordStateRecording:
        {
            //取消按钮
            self.btnDissmiss.hidden = NO;
            //拍摄按钮
            [self.btnRecord setTitle:@"" forState:UIControlStateNormal];
            self.btnRecord.frame = self.rectBtnRecordRecording;
            [UIView animateWithDuration:0.2 animations:^{
                _btnRecord.layer.cornerRadius = kProgress_W/2;
                self.btnRecord.layer.borderWidth = 26.0;
            }];
            //拍摄页面
            self.viewRecord.frame = self.rectViewRecordShow;
            //拍摄完成页面
            self.viewFinish.frame = self.rectViewFinishHidden;
        }
            break;
        case KSRecordStateFinish:
        {
            //取消按钮
            self.btnDissmiss.hidden = YES;
            //拍摄页面
            self.viewRecord.frame = self.rectViewRecordHidden;
            //拍摄按钮
            self.btnRecord.frame = self.rectBtnRecordRecording;
            _btnRecord.layer.cornerRadius = kBtnRecord_W/2;
            self.btnRecord.layer.borderWidth = 10.0;
            [self.btnRecord setTitle:@"" forState:UIControlStateNormal];
            //拍摄完成页面
            [UIView animateWithDuration:0.2 animations:^{
                self.viewFinish.frame = self.rectViewFinishShow;
            }];
        }
            break;
            
        default:
            break;
    }
}


#pragma mark - public method
- (void)setViewCamera:(KSRecordState)state
{
    //页面按妞
    [self setViewRecordForState:state];
    //页面进度&拍摄提示
    switch (state) {
        case KSRecordStatePrepare:
            [self.progressView resetProgress];
            break;
        case KSRecordStateRecording:
            break;
        case KSRecordStateFinish:
            [self.progressView resetProgress];
            break;
            
        default:
            break;
    }
}
- (void)setBtnTorchForMode:(AVCaptureTorchMode)mode
{
    switch (mode) {
        case AVCaptureTorchModeOff:
            [self.btnFlash setImage:[UIImage imageNamed:@"KSCaptureFlash_Off"] forState:UIControlStateNormal];
            break;
        case AVCaptureTorchModeOn:
            [self.btnFlash setImage:[UIImage imageNamed:@"KSCaptureFlash_On"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    
}
- (void)setBtnCameraForPosition:(AVCaptureDevicePosition)position
{
    switch (position) {
        case AVCaptureDevicePositionBack:
            [self.btnCamera setTitle:@"Back" forState:UIControlStateNormal];
            break;
        case AVCaptureDevicePositionFront:
            [self.btnCamera setTitle:@"Front" forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

- (void)upDateProgress:(CGFloat)progress
{
    [self.progressView updateProgress:progress];
}

#pragma mark - handler clicked method
- (void)btnDisMissClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnDisMissClicked:)]) {
        [self.delegate btnDisMissClicked:btn];
    }
}

- (void)btnCameraSwitchClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnCameraSwitchClicked:)]) {
        [self.delegate btnCameraSwitchClicked:btn];
    }
}


- (void)btnRecordClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnRecordClicked:)]) {
        [self.delegate btnRecordClicked:btn];
    }
}

- (void)btnFlashSwitchClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnFlashSwitchClicked:)]) {
        [self.delegate btnFlashSwitchClicked:btn];
    }
}


- (void)btnGiveUpClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnGiveUpClicked:)]) {
        [self.delegate btnGiveUpClicked:btn];
    }
}

- (void)btnSureClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnSureClicked:)]) {
        [self.delegate btnSureClicked:btn];
    }
}


#pragma mark - get & set
- (UIView *)viewTop
{
    if (!_viewTop) {
        CGRect rect = CGRectMake(0, 0, kAppWidth, kTopView_H);
        _viewTop = [[UIView alloc]initWithFrame:rect];
        _viewTop.backgroundColor = RGBVACOLOR(0x000000, 0.6);
    }
    return _viewTop;
}

- (UIButton *)btnDissmiss
{
    if (!_btnDissmiss) {
        CGRect rect = CGRectMake(kBtnTop_X, kBtnTop_Y, kBtnTop_W, kBtnTop_H);
        _btnDissmiss = [[UIButton alloc]initWithFrame:rect];
        [_btnDissmiss setTitle:@"取消" forState:UIControlStateNormal];
        [_btnDissmiss setTitleColor:RGBVCOLOR(0xffffff) forState:UIControlStateNormal];
        _btnDissmiss.titleLabel.font = KSFont(14);
        [_btnDissmiss addTarget:self action:@selector(btnDisMissClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnDissmiss;
}

- (UILabel *)labTitle
{
    if (!_labTitle) {
        CGRect rect = CGRectMake((kAppWidth-80)/2, kBtnTop_Y, 80, kBtnTop_H);
        _labTitle = [[UILabel alloc]initWithFrame:rect];
        _labTitle.textColor = RGBVCOLOR(0xffffff);
        _labTitle.font = KSBoldFont(18);
        _labTitle.text = @"拍摄视频";
    }
    return _labTitle;
}

- (UIButton *)btnCamera
{
    if (!_btnCamera) {
        CGRect rect = CGRectMake(kAppWidth-kBtnTop_X-kBtnTop_W, kBtnTop_Y, kBtnTop_W, kBtnTop_H);
        _btnCamera = [[UIButton alloc]initWithFrame:rect];
        [_btnCamera setTitle:@"Back" forState:UIControlStateNormal];
        _btnCamera.clipsToBounds = YES;
        _btnCamera.layer.cornerRadius = 3;
        _btnCamera.layer.borderColor = RGBVCOLOR(0xd0d0d0).CGColor;
        _btnCamera.layer.borderWidth = 0.5;
        [_btnCamera setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_btnCamera addTarget:self action:@selector(btnCameraSwitchClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnCamera;
}

- (UIView *)viewRecord
{
    if (!_viewRecord) {
        _viewRecord = [[UIView alloc]initWithFrame:self.rectViewRecordShow];
        _viewRecord.backgroundColor = RGBVACOLOR(0x000000, 0.6);
    }
    return _viewRecord;
}

- (KSRecordProgressView *)progressView
{
    if (!_progressView) {
        CGFloat fWH = kProgress_W-kRecordProgressViewLayer_W/2;
        CGRect rect = CGRectMake((kAppWidth-fWH)/2, (kViewRecord_H-fWH)/2, fWH, fWH);
        _progressView = [[KSRecordProgressView alloc]initWithFrame:rect];
    }
    return _progressView;
}

- (UIButton *)btnRecord
{
    if (!_btnRecord) {
        CGRect rect = CGRectMake((kAppWidth-kBtnRecord_W)/2, (kViewRecord_H-kBtnRecord_H)/2, kBtnRecord_W, kBtnRecord_H);
        _btnRecord = [[UIButton alloc]initWithFrame:rect];
        _btnRecord.backgroundColor = [UIColor whiteColor];
        [_btnRecord setTitle:@"拍摄" forState:UIControlStateNormal];
        [_btnRecord setTitleColor:RGBVCOLOR(0x666666) forState:UIControlStateNormal];
        _btnRecord.titleLabel.font = KSFont(14);
        _btnRecord.layer.cornerRadius = kBtnRecord_W/2;
        _btnRecord.layer.masksToBounds = YES;
        _btnRecord.layer.borderWidth = 10.0;
        _btnRecord.layer.borderColor = [UIColor lightGrayColor].CGColor;
        [_btnRecord addTarget:self action:@selector(btnRecordClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnRecord;
}

- (UIButton *)btnFlash
{
    if (!_btnFlash) {
        CGFloat fBtnEnd_X = kAppWidth/2+kBtnRecord_W/2;
        CGFloat fBtnRecordEnd_End = kAppWidth - fBtnEnd_X;
        CGFloat fBtn_space = (fBtnRecordEnd_End-kBtnTop_W)/2;
        CGFloat f_X = fBtnEnd_X + fBtn_space;
        CGRect rect = CGRectMake(f_X, (kViewRecord_H-kBtnTop_H)/2, kBtnTop_W, kBtnTop_H);
        _btnFlash = [[UIButton alloc]initWithFrame:rect];
        [_btnFlash setImage:[UIImage imageNamed:@"KSCaptureFlash_Off"] forState:UIControlStateNormal];
        [_btnFlash addTarget:self action:@selector(btnFlashSwitchClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnFlash;
}

- (UIView *)viewFinish
{
    if (!_viewFinish) {
        _viewFinish = [[UIView alloc]initWithFrame:self.rectViewFinishHidden];
        _viewFinish.backgroundColor = RGBVACOLOR(0x000000, 0.6);
    }
    return _viewFinish;
}

- (UIButton *)btnGiveUp
{
    if (!_btnGiveUp) {
        CGRect rect = CGRectMake(0, 0, kAppWidth/2, kViewFinish_H);
        _btnGiveUp = [[UIButton alloc]initWithFrame:rect];
        [_btnGiveUp setTitle:@"重拍" forState:UIControlStateNormal];
        [_btnGiveUp setTitleColor:RGBVCOLOR(0xffffff) forState:UIControlStateNormal];
        _btnGiveUp.titleLabel.font = KSFont(16);
        [_btnGiveUp addTarget:self action:@selector(btnGiveUpClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnGiveUp;
}

- (UIButton *)btnSure
{
    if (!_btnSure) {
        CGRect rect = CGRectMake(kAppWidth/2, 0, kAppWidth/2, kViewFinish_H);
        _btnSure = [[UIButton alloc]initWithFrame:rect];
        [_btnSure setTitle:@"确定" forState:UIControlStateNormal];
        [_btnSure setTitleColor:RGBVCOLOR(0xffffff) forState:UIControlStateNormal];
        _btnSure.titleLabel.font = KSFont(16);
        [_btnSure addTarget:self action:@selector(btnSureClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnSure;
}

@end
