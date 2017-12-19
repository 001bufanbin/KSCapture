//
//  KSTakePhotoOpreateView.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSTakePhotoOperateView.h"

//顶部视图
CGFloat const kTopView_H       = 48;
static CGFloat const kBtnTop_X = 4;
static CGFloat const kBtnTop_Y = 0;
static CGFloat const kBtnTop_W = 60;
static CGFloat const kBtnTop_H = 48;

//拍摄视图
CGFloat const kViewUnder_H        = 132;
static CGFloat const kBtnRecord_W = 72;
static CGFloat const kBtnRecord_H = 72;
static CGFloat const kBtnFlash_W  = 56;
static CGFloat const kBtnFlash_H  = 56;

//中间视图
//scan frame 是相对于middleView的
#define kOCR_X  10
#define kOCR_Y  10
#define kOCR_W  590.0
#define kOCR_H  860.0

@interface KSTakePhotoOperateView ()

@property (nonatomic, assign)KSTakePhotoType type; //拍摄类型

//页面-头部
@property (nonatomic ,strong)UIView   *viewTop;     //顶部视图
@property (nonatomic ,strong)UIButton *btnDissmiss; //退出拍摄
@property (nonatomic ,strong)UILabel  *labTitle;    //标题
@property (nonatomic ,strong)UIButton *btnRight;    //右边按钮

//页面-中间
//辅助线
@property (nonatomic ,strong)UIImageView  *imgGuideLine;//辅助线
//行驶证
@property (nonatomic ,strong)UIView       *viewMiddle;//中间视图
@property (nonatomic ,strong)CAShapeLayer *cropLayer; //阴影
@property (nonatomic ,strong)UIImageView  *imgOCR;    //拍摄指示区域

//页面-底部
@property (nonatomic ,strong)UIView   *viewUnder;   //底部拍摄视图
@property (nonatomic ,strong)UIButton *btnTakePhoto;//拍摄按钮
@property (nonatomic ,strong)UIButton *btnFlash;    //闪关灯切换
@property (nonatomic ,strong)UIButton *btnCamera;   //摄像头切换

@end

@implementation KSTakePhotoOperateView

// MARK: - init
- (instancetype)init
{
    NSAssert(NO, @"请使用initWithFrame: forType:函数进行控件的初始化!");
    self = [super init];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame forType:(KSTakePhotoType)type
{
    self = [super initWithFrame:frame];
    if (self) {
        self.type = type;
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    [self initTopView];
    [self initMiddleView];
    [self initUnderView];
}

- (void)initTopView
{
    [self addSubview:self.viewTop];

    [self.viewTop addSubview:self.btnDissmiss];
    [self.viewTop addSubview:self.labTitle];
    [self.viewTop addSubview:self.btnRight];
}

- (void)initMiddleView
{
    switch (self.type) {
        case KSTakePhotoNormal:
            break;
        case KSTakePhotoScanOCR:
        {
            [self addSubview:self.viewMiddle];

            [self.viewMiddle.layer addSublayer:self.cropLayer];
            [self.viewMiddle addSubview:self.imgOCR];
        }
            break;
        case KSTakePhotoGuideLine:
            [self addSubview:self.imgGuideLine];
            break;
        default:
            break;
    }
}

- (void)initUnderView
{
    [self addSubview:self.viewUnder];

    [self.viewUnder addSubview:self.btnTakePhoto];
    [self.viewUnder addSubview:self.btnFlash];
    [self.viewUnder addSubview:self.btnCamera];
}

- (CGRect)getOCRRect
{
    //第一种情况：左右边距固定，上下边距根据比例计算；如果第一种情况下高度超出了superView，则改为第二种情况
    //第二种情况：上下边距固定，左右边距根据比例计算

    CGFloat f_X = kOCR_X;
    CGFloat f_Y = kOCR_Y;
    CGFloat f_W = kAppWidth - f_X*2;
    CGFloat f_H = f_W * (kOCR_H/kOCR_W);
    if (f_H < (kAppHeight - kTopView_H - kViewUnder_H - kOCR_X*2)) {//第一种情况
        f_Y = (kAppHeight - kTopView_H - kViewUnder_H - f_H)/2;
    } else {//第二种情况
        f_Y = kOCR_Y;
        f_H = (kAppHeight - kTopView_H - kViewUnder_H - f_Y*2);
        f_W = f_H * (kOCR_W/kOCR_H);
        f_X = (kAppWidth - f_W)/2;
    }
    CGRect rectOCR = CGRectMake(f_X, f_Y, f_W, f_H);
    return rectOCR;
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
// MARK: - Top
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
        CGRect rect = CGRectMake(kBtnTop_X, 0, kBtnTop_W, kBtnTop_H);
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
        CGRect rect = CGRectMake((kAppWidth-100)/2, kBtnTop_Y, 100, kBtnTop_H);
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

// MARK: - Middle
// MARK: 辅助线
- (UIImageView *)imgGuideLine
{
    if (!_imgGuideLine) {
        CGRect rect = CGRectMake(0, kTopView_H, kAppWidth, kAppHeight-kTopView_H-kViewUnder_H);
        _imgGuideLine = [[UIImageView alloc]initWithFrame:rect];
        [_imgGuideLine setImage:[UIImage imageNamed:@"KSCaptureGuideLine_Nor"]];
    }
    return _imgGuideLine;
}
// MARK: 扫描框
- (UIView *)viewMiddle
{
    if (!_viewMiddle) {
        CGRect rect = CGRectMake(0, kTopView_H, kAppWidth, kAppHeight-kTopView_H-kViewUnder_H);
        _viewMiddle = [[UIView alloc]initWithFrame:rect];
    }
    return _viewMiddle;
}

- (CAShapeLayer *)cropLayer
{
    if (!_cropLayer) {
        _cropLayer = [[CAShapeLayer alloc] init];

        CGRect rect = CGRectMake(0, 0, kAppWidth, kAppHeight-kTopView_H-kViewUnder_H);
        CGRect rectOCR = [self getOCRRect];

        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, nil, rectOCR);
        CGPathAddRect(path, nil, rect);
        [_cropLayer setPath:path];
        [_cropLayer setFillRule:kCAFillRuleEvenOdd];
        [_cropLayer setFillColor:[UIColor blackColor].CGColor];
        [_cropLayer setOpacity:0.5];
        [_cropLayer setNeedsDisplay];
    }
    return _cropLayer;
}

- (UIImageView *)imgOCR
{
    if (!_imgOCR) {
        CGRect rectOCR = [self getOCRRect];
        _imgOCR = [[UIImageView alloc]initWithFrame:rectOCR];
        [_imgOCR setImage:[UIImage imageNamed:@"KSCapture_OCR"]];
    }
    return _imgOCR;
}

// MARK: - Under
- (UIView *)viewUnder
{
    if (!_viewUnder) {
        CGRect rect = CGRectMake(0, kAppHeight-kViewUnder_H, kAppWidth, kViewUnder_H);
        _viewUnder = [[UIView alloc]initWithFrame:rect];
        _viewUnder.backgroundColor = RGBVACOLOR(0x000000, 0.6);
    }
    return _viewUnder;
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
        CGFloat fBtn_space = (kAppWidth-fBtnEnd_X-kBtnFlash_W*2)/3;
        CGFloat f_X = fBtnEnd_X + fBtn_space;
        CGRect rect = CGRectMake(f_X, (kViewUnder_H-kBtnFlash_H)/2, kBtnFlash_W, kBtnFlash_H);
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
        CGFloat fBtn_space = (kAppWidth-fBtnEnd_X-kBtnFlash_W*2)/3;
        CGFloat f_X = fBtnEnd_X + fBtn_space + kBtnFlash_W + fBtn_space;
        CGRect rect = CGRectMake(f_X, (kViewUnder_H-kBtnFlash_H)/2, kBtnFlash_W, kBtnFlash_H);
        _btnCamera = [[UIButton alloc]initWithFrame:rect];
        [_btnCamera setImage:[UIImage imageNamed:@"KSSwitchCamera_Nor"] forState:UIControlStateNormal];
        [_btnCamera setImage:[UIImage imageNamed:@"KSSwitchCamera_Sel"] forState:UIControlStateHighlighted];
        [_btnCamera addTarget:self action:@selector(btnCameraSwitchClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnCamera;
}

@end
