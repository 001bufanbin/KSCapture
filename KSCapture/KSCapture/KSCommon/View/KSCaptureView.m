//
//  KSCaptureView.m
//  CaptureVideo
//
//  Created by bufb on 2017/6/15.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSCaptureView.h"
#import "KSRecorderFocusTargetView.h"

#define BASE_FOCUS_TARGET_WIDTH 60
#define BASE_FOCUS_TARGET_HEIGHT 60
#define kDefaultMinZoomFactor 1
#define kDefaultMaxZoomFactor 4


@interface KSCaptureView ()
//聚焦手势-单击
@property (nonatomic ,strong)UITapGestureRecognizer *tapToFocusGesture;
//连续聚焦到中心-双击
@property (nonatomic ,strong)UITapGestureRecognizer *doubleTapToResetFocusGesture;
//放大缩小手势
@property (nonatomic ,strong)UIPinchGestureRecognizer *pinchZoomGesture;
@property (nonatomic ,assign)CGFloat zoomAtStart;
//聚焦动画展示页面
@property (nonatomic ,strong)KSRecorderFocusTargetView *focusView;

@end

@implementation KSCaptureView

static char *ContextAdjustingFocus = "AdjustingFocus";
static char *ContextAdjustingExposure = "AdjustingExposure";

- (void)dealloc {
    self.recordManager = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    [self addGestureRecognizer:self.tapToFocusGesture];
    [self addGestureRecognizer:self.doubleTapToResetFocusGesture];
    [self.tapToFocusGesture requireGestureRecognizerToFail:self.doubleTapToResetFocusGesture];
    [self addGestureRecognizer:self.pinchZoomGesture];
    
    [self addSubview:self.focusView];
    self.focusView.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self adjustFocusView];
    
    [super layoutSubviews];
}


- (void)showFocusAnimation {
    [self adjustFocusView];
    self.focusView.hidden = NO;
    [self.focusView startTargeting];
}

- (void)hideFocusAnimation {
    [self.focusView stopTargeting];
}

- (void)adjustFocusView {
    CGPoint currentFocusPoint = CGPointMake(0.5, 0.5);
    
    if (self.recordManager.focusSupported) {
        currentFocusPoint = self.recordManager.focusPointOfInterest;
    } else if (self.recordManager.exposureSupported) {
        currentFocusPoint = self.recordManager.exposurePointOfInterest;
    }
    
    CGPoint viewPoint = [self.recordManager convertPointOfInterestToViewCoordinates:currentFocusPoint];
    //viewPoint = [self convertPoint:viewPoint fromView:self.recordManager.previewView];
    if (!(isnan(viewPoint.x) || isnan(viewPoint.y))) {
        self.focusView.center = viewPoint;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == ContextAdjustingFocus) {
        if (self.recordManager.isAdjustingFocus) {
            [self showFocusAnimation];
        } else {
            [self hideFocusAnimation];
        }
    } else if (context == ContextAdjustingExposure) {
        if (!self.recordManager.focusSupported) {
            if (self.recordManager.isAdjustingExposure) {
                [self showFocusAnimation];
            } else {
                [self hideFocusAnimation];
            }
        }
    }
}


#pragma mark handler method
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint tapPoint = [gestureRecognizer locationInView:self];
    CGPoint convertedFocusPoint = [self.recordManager convertToPointOfInterestFromViewCoordinates:tapPoint];
    [self.recordManager autoFocusAtPoint:convertedFocusPoint];
    
}
- (void)tapToContinouslyAutoFocus:(UITapGestureRecognizer *)gestureRecognizer
{
    if (self.recordManager.focusSupported) {
        self.focusView.center = self.center;
        [self.recordManager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
    }
}
- (void)pinchToZoom:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        _zoomAtStart = self.recordManager.videoZoomFactor;
    }
    
    CGFloat newZoom = gestureRecognizer.scale * _zoomAtStart;
    
    if (newZoom > kDefaultMaxZoomFactor) {
        newZoom = kDefaultMaxZoomFactor;
    } else if (newZoom < kDefaultMinZoomFactor) {
        newZoom = kDefaultMinZoomFactor;
    }
    
    self.recordManager.videoZoomFactor = newZoom;
}

#pragma mark get &set
- (UITapGestureRecognizer *)tapToFocusGesture
{
    if (!_tapToFocusGesture) {
        _tapToFocusGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToAutoFocus:)];
    }
    return _tapToFocusGesture;
}

- (KSRecorderFocusTargetView *)focusView
{
    if (!_focusView) {
        CGRect rect = CGRectMake(0, 0, BASE_FOCUS_TARGET_WIDTH, BASE_FOCUS_TARGET_HEIGHT);
        _focusView = [[KSRecorderFocusTargetView alloc]initWithFrame:rect];
        _focusView.outsideFocusTargetImage = [UIImage imageNamed:@"KSCapture_scan_focus"];
    }
    return _focusView;
}

- (UITapGestureRecognizer *)doubleTapToResetFocusGesture
{
    if (!_doubleTapToResetFocusGesture) {
        _doubleTapToResetFocusGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
        _doubleTapToResetFocusGesture.numberOfTapsRequired = 2;
    }
    return _doubleTapToResetFocusGesture;
}

- (UIPinchGestureRecognizer *)pinchZoomGesture
{
    if (!_pinchZoomGesture) {
        _pinchZoomGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchToZoom:)];
    }
    return _pinchZoomGesture;
}

- (void)setTapToFocusEnabled:(BOOL)tapToFocusEnabled
{
    self.tapToFocusGesture.enabled = tapToFocusEnabled;
}
- (BOOL)tapToFocusEnabled
{
    return self.tapToFocusGesture.enabled;
}

- (void)setDoubleTapToResetFocusEnabled:(BOOL)doubleTapToResetFocusEnabled
{
    self.doubleTapToResetFocusGesture.enabled = doubleTapToResetFocusEnabled;
}
- (BOOL)doubleTapToResetFocusEnabled
{
    return self.doubleTapToResetFocusGesture.enabled;
}

- (void)setPinchToZoomEnabled:(BOOL)pinchToZoomEnabled
{
    self.pinchZoomGesture.enabled = pinchToZoomEnabled;
}
- (BOOL)pinchToZoomEnabled
{
    return self.pinchZoomGesture.enabled;
}

- (void)setRecordManager:(KSAVFoundationManager *)recordManager
{
    //移除原有监听
    KSAVFoundationManager *oldRecorder = _recordManager;

    if (oldRecorder) {
        [oldRecorder removeObserver:self forKeyPath:@"isAdjustingFocus"];
        [oldRecorder removeObserver:self forKeyPath:@"isAdjustingExposure"];
    }

    //添加新的监听
    _recordManager = recordManager;

    if (_recordManager) {
        [_recordManager addObserver:self forKeyPath:@"isAdjustingFocus" options:NSKeyValueObservingOptionNew context:ContextAdjustingFocus];
        [_recordManager addObserver:self forKeyPath:@"isAdjustingExposure" options:NSKeyValueObservingOptionNew context:ContextAdjustingExposure];
    }
}

@end
