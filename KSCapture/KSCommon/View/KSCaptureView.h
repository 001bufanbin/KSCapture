//
//  KSCaptureView.h
//  CaptureVideo
//
//  Created by bufb on 2017/6/15.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KSAVFoundationManager.h"

@interface KSCaptureView : UIView

@property (nonatomic ,strong)KSAVFoundationManager *recordManager;

@property (assign, nonatomic) BOOL tapToFocusEnabled;
@property (assign, nonatomic) BOOL doubleTapToResetFocusEnabled;
@property (assign, nonatomic) BOOL pinchToZoomEnabled;

@end
