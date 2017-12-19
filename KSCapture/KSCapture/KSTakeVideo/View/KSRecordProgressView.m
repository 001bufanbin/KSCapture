//
//  KSRecordProgressView.m
//  CaptureVideo
//
//  Created by bufb on 2017/6/1.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSRecordProgressView.h"

CGFloat const kRecordProgressViewLayer_W = 4.0;

@interface KSRecordProgressView ()
{
    CGPoint _center;
    CGFloat _radius;
    CGFloat _startAngle;
    CGFloat _endAngle;
}

@property (nonatomic ,strong)CAShapeLayer *backGroundLayer;
@property (nonatomic ,strong)CAShapeLayer *progressLayer;

@property (nonatomic ,assign)CGFloat progress;

@end

@implementation KSRecordProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        
        self.progress = 0.0f;
        _center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        _radius = frame.size.width/2-kRecordProgressViewLayer_W/2;
        _startAngle = -M_PI_2;
        _endAngle   = -M_PI_2 + M_PI*2;
        
        //[self.layer addSublayer:self.backGroundLayer];
        [self.layer addSublayer:self.progressLayer];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (self.progress > 1) {
        return;
    }
    
    _endAngle = -M_PI_2 + M_PI*2*self.progress;
    //贝塞尔曲线
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:_center     //圆心
                                                        radius:_radius     //半径
                                                    startAngle:_startAngle //开始角度
                                                      endAngle:_endAngle   //结束角度
                                                     clockwise:YES];       //顺时针
    
    self.progressLayer.path = [path CGPath];
}

- (void)updateProgress:(CGFloat )progress
{
    self.progress = progress;
    [self setNeedsDisplay];
}

- (void)resetProgress
{
    self.progress = 0.0f;
    [self setNeedsDisplay];
}
#pragma makr - get & set
- (CAShapeLayer *)backGroundLayer
{
    if (!_backGroundLayer) {
        //贝塞尔曲线
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:_center     //圆心
                                                            radius:_radius     //半径
                                                        startAngle:_startAngle //开始角度
                                                          endAngle:_endAngle   //结束角度
                                                         clockwise:YES];       //顺时针
        //CAShapLayer
        _backGroundLayer = [CAShapeLayer layer];
        _backGroundLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        _backGroundLayer.fillColor   = [UIColor clearColor].CGColor;//填充色
        _backGroundLayer.strokeColor = [UIColor whiteColor].CGColor;//边框色
        _backGroundLayer.lineWidth = kRecordProgressViewLayer_W;//边框宽度
        _backGroundLayer.lineCap = kCALineCapRound;//线头圆形
        
        _backGroundLayer.path = [path CGPath];
    }
    return _backGroundLayer;
}

- (CAShapeLayer *)progressLayer
{
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _progressLayer.fillColor   = [UIColor clearColor].CGColor;//填充色
        _progressLayer.strokeColor = RGBVCOLOR(0x38a2e1).CGColor;//边框色
        _progressLayer.lineWidth = kRecordProgressViewLayer_W;
        _progressLayer.lineCap = kCALineCapButt;//线头无形状
    }
    return _progressLayer;
}

@end
