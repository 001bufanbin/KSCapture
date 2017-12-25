//
//  KSAVFoundationManager.h
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KSCaptureTool.h"
#import "KSMotionManager.h"


//切换手电筒block回调
typedef void (^SwitchTorchSuccessBlock)(AVCaptureTorchMode currentTorchMode);
typedef void (^SwitchTorchFailedBlock)(NSError *error, AVCaptureTorchMode currentTorchMode);

//切换闪光灯block回调
typedef void (^SwitchFlashSuccessBlock)(AVCaptureFlashMode currentFlashMode);
typedef void (^SwitchFlashFailedBlock)(NSError *error, AVCaptureFlashMode currentFlashMode);

//切换摄像头block回调
typedef void (^SwitchCameraSuccessBlock)(AVCaptureDevicePosition currentPosition);
typedef void (^SwitchCameraFailedBlock)(NSError *error, AVCaptureDevicePosition currentPosition);

typedef NS_ENUM(NSInteger ,KSCaptureType)
{
    KSCapturePhoto,
    KSCaptureVideo
};

@interface KSAVFoundationManager : NSObject

//视频会话
@property (nonatomic ,strong)AVCaptureSession *session;
//设备输入源（前置或者后置摄像头）
@property (nonatomic ,strong)AVCaptureDeviceInput *videoInput;
@property (nonatomic ,strong)AVCaptureDeviceInput *videoBackInput;
@property (nonatomic ,strong)AVCaptureDeviceInput *videoFrontInput;
@property (nonatomic ,strong)AVCaptureConnection  *videoConnection;//子类按照outPut重写get方法
//视频预览
@property (nonatomic ,strong)AVCaptureVideoPreviewLayer *previewLayer;

//设置默认方向
- (void)setVideoConnectionOrientationDefault:(KSCaptureType)type;
//拍摄时设备方向
@property (nonatomic ,assign)UIDeviceOrientation deviceOrientation;


/****************初始化部分**************/

/**
 将视频预览层展示到view上

 @param view 要展示视频预览的View
 */
- (void)showPreviewLayerInView:(UIView *)view;
- (void)removePreviewLayerInView:(UIView *)view;

/*******************End*****************/


/*****************功能部分****************/

/**
 开始拍摄预览
 */
- (void)startSessionRuning;

/**
 停止拍摄预览
 */
- (void)stopSessionRuning;


/**
 切换手电筒模式(开-关)
 */
- (void)switchTorchModelSuccess:(SwitchTorchSuccessBlock)success failed:(SwitchTorchFailedBlock)failed;

/**
 切换闪光灯模式（开-关）
 */
- (void)switchFlashModelSuccess:(SwitchFlashSuccessBlock)success failed:(SwitchFlashFailedBlock)failed;

/**
 切换摄像头
 */
- (void)switchCameraSuccess:(SwitchCameraSuccessBlock)success failed:(SwitchCameraFailedBlock)failed;


//对焦、曝光、白平衡
@property (readonly, nonatomic) BOOL focusSupported;
@property (readonly, nonatomic) CGPoint focusPointOfInterest;
@property (readonly, nonatomic) BOOL exposureSupported;
@property (readonly, nonatomic) CGPoint exposurePointOfInterest;

@property (readonly, nonatomic) BOOL isAdjustingFocus;   //是否正在对焦
@property (readonly, nonatomic) BOOL isAdjustingExposure;//是否正在曝光

//坐标转换
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (CGPoint)convertPointOfInterestToViewCoordinates:(CGPoint)pointOfInterest;

//设置对焦到某个点，然后锁定当前对焦
- (void)autoFocusAtPoint:(CGPoint)point;
//自动连续对焦
- (void)continuousFocusAtPoint:(CGPoint)point;

//当前设备放大缩小比例
@property (assign, nonatomic) CGFloat videoZoomFactor;


@end
