//
//  KSVideoPlayer.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSVideoPlayer : NSObject

- (instancetype)initWithPath:(NSString *)strPath;

- (void)showPlayerLayerInView:(UIView *)view;
- (void)removePlayerLayerInView:(UIView *)view;

- (void)startPlay;
- (void)stopPlay;

- (void)removeObsvers;

@end
