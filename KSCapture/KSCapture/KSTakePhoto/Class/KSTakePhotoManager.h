//
//  KSTakePhotoManager.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSAVFoundationManager.h"

typedef void (^TakePhotoSuccessBlock)(UIImage *imgPhoto);
typedef void (^TakePhotoFailedBlock)(NSError *error);

@interface KSTakePhotoManager : KSAVFoundationManager

/**
 拍摄照片

 @param success 成功回调
 @param failed 失败回调
 */
- (void)takePhotoSuccess:(TakePhotoSuccessBlock)success failed:(TakePhotoFailedBlock)failed;

/**
 拍摄结果图片
 */
@property (nonatomic, strong, readonly) UIImage *imgPhoto;

@end
