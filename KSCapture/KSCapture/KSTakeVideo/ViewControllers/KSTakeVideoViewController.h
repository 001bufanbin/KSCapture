//
//  KSTakeVideoViewController.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSCaptureConfig.h"

@protocol KSTakeVideoDelegate <NSObject>

- (void)takeVideoFinish:(NSString *)videoPath;

@end

@interface KSTakeVideoViewController : UIViewController

@property (nonatomic ,weak)id <KSTakeVideoDelegate> delegate;

@end
