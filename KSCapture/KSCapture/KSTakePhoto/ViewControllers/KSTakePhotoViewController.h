//
//  KSTakePhotoViewController.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KSTakePhotoDelegate <NSObject>

- (void)takePhotoFinish:(UIImage *)image;

@end

@interface KSTakePhotoViewController : UIViewController

@property (nonatomic ,weak)id<KSTakePhotoDelegate> delegate;         //拍摄完成代理

@end
