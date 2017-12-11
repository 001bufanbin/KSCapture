//
//  KSTakePhotoOpreateView.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT CGFloat const kTopView_H;  //顶部视图高度
FOUNDATION_EXPORT CGFloat const kViewUnder_H;//底部视图高度

@protocol KSTakePhotoOperateViewDelegate <NSObject>

- (void)btnRightClicked:(UIButton *)btn;

- (void)btnDisMissClicked:(UIButton *)btn;
- (void)btnTakePhotoClicked:(UIButton *)btn;
- (void)btnFlashSwitchClicked:(UIButton *)btn;
- (void)btnCameraSwitchClicked:(UIButton *)btn;

@end

@interface KSTakePhotoOpreateView : UIView

@property (nonatomic ,weak)id <KSTakePhotoOperateViewDelegate> delegate;


/**
 添加子View方法-子类按需求重写
 */
- (void)initSubViews;

@end
