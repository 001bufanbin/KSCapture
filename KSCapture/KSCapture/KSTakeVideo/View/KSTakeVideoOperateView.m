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
static CGFloat const kTopView_H    = 48;
static CGFloat const kBtnTop_X     = 4;
static CGFloat const kBtnTop_Y     = 0;
static CGFloat const kBtnTop_W     = 60;
static CGFloat const kBtnTop_H     = 48;
//拍摄视图
static CGFloat const kViewRecord_H = 130;
static CGFloat const kBtnRecord_W  = 72;
static CGFloat const kBtnRecord_H  = 72;
static CGFloat const kBtnTorch_W   = 56;
static CGFloat const kBtnTorch_H   = 56;
//拍摄完成视图
static CGFloat const kViewFinish_H = 50;


@interface KSTakeVideoOperateView ()

@property (nonatomic ,strong)UIView   *viewTop;     //顶部视图
@property (nonatomic ,strong)UIButton *btnDissmiss; //退出拍摄
@property (nonatomic ,strong)UILabel  *labTitle;    //标题
@property (nonatomic ,strong)UIButton *btnRight;    //右边按钮

@property (nonatomic ,strong)UIView   *viewRecord;  //底部拍摄视图
@property (nonatomic ,strong)UIButton *btnRecord;   //拍摄按钮
@property (nonatomic ,strong)KSRecordProgressView *progressView;//进度
@property (nonatomic ,strong)UIButton *btnFlash;    //闪关灯切换
@property (nonatomic ,strong)UIButton *btnCamera;   //摄像头切换

@property (nonatomic ,strong)UIView   *viewFinish;  //拍摄完成视图
@property (nonatomic ,strong)UIButton *btnGiveUp;   //放弃按钮
@property (nonatomic ,strong)UIButton *btnSure;     //保存按钮

@property (nonatomic ,assign)CGRect rectViewRecordShow;
@property (nonatomic ,assign)CGRect rectViewRecordHidden;
@property (nonatomic ,assign)CGRect rectViewFinishShow;
@property (nonatomic ,assign)CGRect rectViewFinishHidden;

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
    [self.viewTop addSubview:self.btnRight];
    self.btnRight.hidden = YES;
}

- (void)initRecordView
{
    [self addSubview:self.viewRecord];
    
    [self.viewRecord addSubview:self.btnRecord];
    [self.viewRecord addSubview:self.progressView];
    [self.viewRecord addSubview:self.btnFlash];
    [self.viewRecord addSubview:self.btnCamera];
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
}

#pragma mark - private method
- (void)setViewRecordForState:(KSRecordState)state
{

#if kCanPause
    switch (state) {
        case KSRecordStatePrepare:
        {
            self.btnDissmiss.hidden = NO;
            self.btnRight.hidden = YES;
            //拍摄按钮
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
            self.btnDissmiss.hidden = NO;
            self.btnRight.hidden = NO;
            //拍摄按钮
            [self.btnRecord setTitle:@"暂停" forState:UIControlStateNormal];
            //拍摄页面
            self.viewRecord.frame = self.rectViewRecordShow;
            //拍摄完成页面
            self.viewFinish.frame = self.rectViewFinishHidden;
        }
            break;
        case KSRecordStatePause:
        {
            self.btnDissmiss.hidden = NO;
            self.btnRight.hidden = NO;
            //拍摄按钮
            [self.btnRecord setTitle:@"继续" forState:UIControlStateNormal];
            //拍摄页面
            self.viewRecord.frame = self.rectViewRecordShow;
            //拍摄完成页面
            self.viewFinish.frame = self.rectViewFinishHidden;
        }
            break;
        case KSRecordStateResume:
        {
            self.btnDissmiss.hidden = NO;
            self.btnRight.hidden = NO;
            //拍摄按钮
            [self.btnRecord setTitle:@"暂停" forState:UIControlStateNormal];
            //拍摄页面
            self.viewRecord.frame = self.rectViewRecordShow;
            //拍摄完成页面
            self.viewFinish.frame = self.rectViewFinishHidden;
        }
            break;
        case KSRecordStateFinish:
        {
            self.btnDissmiss.hidden = YES;
            self.btnRight.hidden = YES;
            //拍摄页面
            self.viewRecord.frame = self.rectViewRecordHidden;
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
#else
    switch (state) {
        case KSRecordStatePrepare:
        {
            self.btnDissmiss.hidden = NO;
            self.btnRight.hidden = NO;
            //拍摄按钮
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
            self.btnDissmiss.hidden = NO;
            self.btnRight.hidden = NO;
            //拍摄按钮
            [self.btnRecord setTitle:@"" forState:UIControlStateNormal];
            //拍摄页面
            self.viewRecord.frame = self.rectViewRecordShow;
            //拍摄完成页面
            self.viewFinish.frame = self.rectViewFinishHidden;
        }
            break;
        case KSRecordStateFinish:
        {
            self.btnDissmiss.hidden = YES;
            self.btnRight.hidden = YES;
            //拍摄页面
            self.viewRecord.frame = self.rectViewRecordHidden;
            //拍摄按钮
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
#endif
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
        case KSRecordStateRecording ... KSRecordStateResume:
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
            break;
        case AVCaptureDevicePositionFront:
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

- (void)btnRightClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnRightClicked:)]) {
        [self.delegate btnRightClicked:btn];
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

- (void)btnCameraSwitchClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnCameraSwitchClicked:)]) {
        [self.delegate btnCameraSwitchClicked:btn];
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


// MARK: - get & set
// MARK: 顶部视图
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
        _btnDissmiss.titleLabel.font = KSFont(16);
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

- (UIButton *)btnRight
{
    if (!_btnRight) {
        CGRect rect = CGRectMake(kAppWidth-kBtnTop_X-kBtnTop_W, kBtnTop_Y, kBtnTop_W, kBtnTop_H);
        _btnRight = [[UIButton alloc]initWithFrame:rect];
        [_btnRight setTitle:@"完成" forState:UIControlStateNormal];
        [_btnRight setTitleColor:RGBVCOLOR(0xffffff) forState:UIControlStateNormal];
        _btnRight.titleLabel.font = KSFont(16);
        [_btnRight addTarget:self action:@selector(btnRightClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnRight;
}

// MARK: 中间视图
- (UIView *)viewRecord
{
    if (!_viewRecord) {
        _viewRecord = [[UIView alloc]initWithFrame:self.rectViewRecordShow];
        _viewRecord.backgroundColor = RGBVACOLOR(0x000000, 0.6);
    }
    return _viewRecord;
}

- (UIButton *)btnRecord
{
    if (!_btnRecord) {
        CGRect rect = CGRectMake((kAppWidth-kBtnRecord_W)/2, (kViewRecord_H-kBtnRecord_H)/2, kBtnRecord_W, kBtnRecord_H);
        _btnRecord = [[UIButton alloc]initWithFrame:rect];
        [_btnRecord setTitle:@"拍摄" forState:UIControlStateNormal];
        [_btnRecord setTitleColor:RGBVCOLOR(0x666666) forState:UIControlStateNormal];
        _btnRecord.titleLabel.font = KSFont(14);
        [_btnRecord setBackgroundImage:[UIImage imageNamed:@"KSTakePhoto_Nor"] forState:UIControlStateNormal];
        [_btnRecord setBackgroundImage:[UIImage imageNamed:@"KSTakePhoto_Sel"] forState:UIControlStateHighlighted];
        [_btnRecord addTarget:self action:@selector(btnRecordClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnRecord;
}

- (KSRecordProgressView *)progressView
{
    if (!_progressView) {
        CGRect rect = CGRectMake((kAppWidth-kBtnRecord_W)/2, (kViewRecord_H-kBtnRecord_H)/2, kBtnRecord_W, kBtnRecord_H);
        _progressView = [[KSRecordProgressView alloc]initWithFrame:rect];
    }
    return _progressView;
}

- (UIButton *)btnFlash
{
    if (!_btnFlash) {
        CGFloat fBtnEnd_X = kAppWidth/2+kBtnRecord_W/2;
        CGFloat fBtn_space = (kAppWidth-fBtnEnd_X-kBtnTorch_W*2)/3;
        CGFloat f_X = fBtnEnd_X + fBtn_space;
        CGRect rect = CGRectMake(f_X, (kViewRecord_H-kBtnTorch_H)/2, kBtnTorch_W, kBtnTorch_H);
        _btnFlash = [[UIButton alloc]initWithFrame:rect];
        [_btnFlash setImage:[UIImage imageNamed:@"KSCaptureFlash_Off"] forState:UIControlStateNormal];
        [_btnFlash addTarget:self action:@selector(btnFlashSwitchClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnFlash;
}

- (UIButton *)btnCamera
{
    if (!_btnCamera) {
        CGFloat fBtnEnd_X = kAppWidth/2+kBtnRecord_W/2;
        CGFloat fBtn_space = (kAppWidth-fBtnEnd_X-kBtnTorch_W*2)/3;
        CGFloat f_X = fBtnEnd_X + fBtn_space + kBtnTorch_W + fBtn_space;
        CGRect rect = CGRectMake(f_X, (kViewRecord_H-kBtnTorch_H)/2, kBtnTorch_W, kBtnTorch_H);
        _btnCamera = [[UIButton alloc]initWithFrame:rect];
        [_btnCamera setImage:[UIImage imageNamed:@"KSSwitchCamera_Nor"] forState:UIControlStateNormal];
        [_btnCamera setImage:[UIImage imageNamed:@"KSSwitchCamera_Sel"] forState:UIControlStateHighlighted];
        [_btnCamera addTarget:self action:@selector(btnCameraSwitchClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnCamera;
}

// MARK: 完成视图
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
