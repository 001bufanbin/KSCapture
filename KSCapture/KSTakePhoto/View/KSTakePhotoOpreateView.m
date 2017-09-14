//
//  KSTakePhotoOpreateView.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSTakePhotoOpreateView.h"

//顶部视图
CGFloat const kTopView_H    = 44;
static CGFloat const kBtnTop_X     = 4;
static CGFloat const kBtnTop_Y     = 0;
static CGFloat const kBtnTop_W     = 60;
static CGFloat const kBtnTop_H     = 44;
//拍摄视图
CGFloat const kViewUnder_H = 100;
static CGFloat const kBtnRecord_W  = 60;
static CGFloat const kBtnRecord_H  = 60;

@interface KSTakePhotoOpreateView ()

@property (nonatomic ,strong)UIView   *viewTop;     //顶部视图
@property (nonatomic ,strong)UILabel  *labTitle;    //标题
@property (nonatomic ,strong)UIButton *btnRight;    //右边按钮

@property (nonatomic ,strong)UIView   *viewUnder;   //底部拍摄视图
@property (nonatomic ,strong)UIButton *btnDissmiss; //退出拍摄
@property (nonatomic ,strong)UIButton *btnTakePhoto;//拍摄按钮
@property (nonatomic ,strong)UIButton *btnFlash;    //闪关灯切换
@property (nonatomic ,strong)UIButton *btnCamera;   //摄像头切换

@end

@implementation KSTakePhotoOpreateView

// MARK: - init
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
    [self initTopView];
    [self initUnderView];
}

- (void)initTopView
{
    [self addSubview:self.viewTop];

    [self.viewTop addSubview:self.labTitle];
    [self.viewTop addSubview:self.btnRight];
}

- (void)initUnderView
{
    [self addSubview:self.viewUnder];

    [self.viewUnder addSubview:self.btnDissmiss];
    [self.viewUnder addSubview:self.btnTakePhoto];
    [self.viewUnder addSubview:self.btnFlash];
    [self.viewUnder addSubview:self.btnCamera];
}

// MARK: - BtnHander
- (void)btnRightClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnRightClicked:)]) {
        [self.delegate btnRightClicked:btn];
    }
}

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

- (void)btnTakePhotoClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnTakePhotoClicked:)]) {
        [self.delegate btnTakePhotoClicked:btn];
    }
}

- (void)btnFlashSwitchClicked:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(btnFlashSwitchClicked:)]) {
        [self.delegate btnFlashSwitchClicked:btn];
    }
}


// MARK: - get & set
// MARK: Top
- (UIView *)viewTop
{
    if (!_viewTop) {
        CGRect rect = CGRectMake(0, 0, kAppWidth, kTopView_H);
        _viewTop = [[UIView alloc]initWithFrame:rect];
        _viewTop.backgroundColor = RGBVACOLOR(0x000000, 0.6);
    }
    return _viewTop;
}

- (UILabel *)labTitle
{
    if (!_labTitle) {
        CGRect rect = CGRectMake((kAppWidth-80)/2, kBtnTop_Y, 80, kBtnTop_H);
        _labTitle = [[UILabel alloc]initWithFrame:rect];
        _labTitle.textColor = RGBVCOLOR(0xffffff);
        _labTitle.font = KSBoldFont(18);
        _labTitle.text = @"拍摄照片";
    }
    return _labTitle;
}

- (UIButton *)btnRight
{
    if (!_btnRight) {
        CGRect rect = CGRectMake(kAppWidth-kBtnTop_X-kBtnTop_W, kBtnTop_Y, kBtnTop_W, kBtnTop_H);
        _btnRight = [[UIButton alloc]initWithFrame:rect];
        [_btnRight setTitle:@"示例" forState:UIControlStateNormal];
        [_btnRight setTitleColor:RGBVCOLOR(0xffffff) forState:UIControlStateNormal];
        _btnRight.titleLabel.font = KSFont(16);
        [_btnRight addTarget:self action:@selector(btnRightClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnRight;
}

// MARK: Under
- (UIView *)viewUnder
{
    if (!_viewUnder) {
        CGRect rect = CGRectMake(0, kAppHeight-kViewUnder_H, kAppWidth, kViewUnder_H);
        _viewUnder = [[UIView alloc]initWithFrame:rect];
        _viewUnder.backgroundColor = RGBVACOLOR(0x000000, 0.6);
    }
    return _viewUnder;
}

- (UIButton *)btnDissmiss
{
    if (!_btnDissmiss) {
        CGFloat f_X = ((kAppWidth-kBtnRecord_W)/2-kBtnTop_W)/2;
        CGRect rect = CGRectMake(f_X, (kViewUnder_H-kBtnRecord_H)/2, kBtnRecord_W, kBtnRecord_H);
        _btnDissmiss = [[UIButton alloc]initWithFrame:rect];
        [_btnDissmiss setTitle:@"取消" forState:UIControlStateNormal];
        [_btnDissmiss setTitleColor:RGBVCOLOR(0xffffff) forState:UIControlStateNormal];
        _btnDissmiss.titleLabel.font = KSFont(16);
        [_btnDissmiss addTarget:self action:@selector(btnDisMissClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnDissmiss;
}

- (UIButton *)btnTakePhoto
{
    if (!_btnTakePhoto) {
        CGRect rect = CGRectMake((kAppWidth-kBtnRecord_W)/2, (kViewUnder_H-kBtnRecord_H)/2, kBtnRecord_W, kBtnRecord_H);
        _btnTakePhoto = [[UIButton alloc]initWithFrame:rect];
        [_btnTakePhoto setBackgroundImage:[UIImage imageNamed:@"KSTakePhoto_Nor"] forState:UIControlStateNormal];
        [_btnTakePhoto setBackgroundImage:[UIImage imageNamed:@"KSTakePhoto_Sel"] forState:UIControlStateHighlighted];
        [_btnTakePhoto addTarget:self action:@selector(btnTakePhotoClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnTakePhoto;
}

- (UIButton *)btnFlash
{
    if (!_btnFlash) {
        CGFloat fBtnEnd_X = kAppWidth/2+kBtnRecord_W/2;
        CGFloat fBtn_space = (kAppWidth-fBtnEnd_X-kBtnRecord_W*2)/3;
        CGFloat f_X = fBtnEnd_X + fBtn_space;
        CGRect rect = CGRectMake(f_X, (kViewUnder_H-kBtnRecord_H)/2, kBtnRecord_W, kBtnRecord_H);
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
        CGFloat fBtn_space = (kAppWidth-fBtnEnd_X-kBtnRecord_W*2)/3;
        CGFloat f_X = fBtnEnd_X + fBtn_space + kBtnRecord_W + fBtn_space;
        CGRect rect = CGRectMake(f_X, (kViewUnder_H-kBtnRecord_H)/2, kBtnRecord_W, kBtnRecord_H);
        _btnCamera = [[UIButton alloc]initWithFrame:rect];
        [_btnCamera setImage:[UIImage imageNamed:@"KSSwitchCamera"] forState:UIControlStateNormal];
        [_btnCamera addTarget:self action:@selector(btnCameraSwitchClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnCamera;
}

@end
