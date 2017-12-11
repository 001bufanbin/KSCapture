//
//  KSTakeVideoViewController.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSTakeVideoViewController.h"

#import "KSCaptureTool.h"
#import "KSTakeVideoManager.h"
#import "KSCaptureView.h"
#import "KSTakeVideoOperateView.h"
#import "KSVideoPlayer.h"

@interface KSTakeVideoViewController ()<KSTakeVideoOperateViewDelegate,KSTakeVideoManagerDelegate>
@property (nonatomic ,strong)KSTakeVideoManager     *recordManager;  //拍摄管理类
@property (nonatomic ,strong)KSCaptureView          *captureView;    //拍摄区域视图
@property (nonatomic ,strong)KSTakeVideoOperateView *viewOperate;    //拍摄界面操作视图
@property (nonatomic ,strong)KSVideoPlayer          *player;         //播放类
@property (nonatomic ,copy)NSString *videoPath;
@end

@implementation KSTakeVideoViewController

- (void)dealloc
{

}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES animated:NO];

    //初始化-删除目录下视频文件
    [KSCaptureTool deleteVideo];

    [self.view addSubview:self.captureView];

    [self.recordManager showPreviewLayerInView:self.captureView];
    self.captureView.recordManager = self.recordManager;

    [self.captureView addSubview:self.viewOperate];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.recordManager startSessionRuning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.recordManager stopSessionRuning];
}

#pragma mark - KSTakeVideoOperateViewDelegate
- (void)btnDisMissClicked:(UIButton *)btn
{
    switch (self.recordManager.recordState) {
        case KSRecordStatePrepare:
            break;
        case KSRecordStateRecording:
            [self.recordManager giveUpRecord];
            break;
        case KSRecordStateFinish:
            [self.recordManager giveUpRecord];
            [self.player stopPlay];
            break;

        default:
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)btnRightClicked:(UIButton *)btn
{
    [self.recordManager stopRecord];
    [self.viewOperate setViewCamera:KSRecordStateFinish];
}

- (void)btnFlashSwitchClicked:(UIButton *)btn
{
    [self.recordManager switchTorchModelSuccess:^(AVCaptureTorchMode currentTorchMode) {
        NSLog(@"torch switch sucess torch == %ld",(long)currentTorchMode);
        [self.viewOperate setBtnTorchForMode:currentTorchMode];
    } failed:^(NSError *error, AVCaptureTorchMode currentTorchMode) {
        NSLog(@"torch switch failed error == %@",error);
    }];
}

- (void)btnCameraSwitchClicked:(UIButton *)btn
{
    [self.recordManager switchCameraSuccess:^(AVCaptureDevicePosition currentPosition) {
        NSLog(@"camera switch sucess position == %ld",(long)currentPosition);
        [self.viewOperate setBtnCameraForPosition:currentPosition];
    } failed:^(NSError *error, AVCaptureDevicePosition currentPosition) {
        NSLog(@"camera switch failed error == %@",error);
    }];
}

- (void)btnRecordClicked:(UIButton *)btn
{

    if (![KSCaptureTool isAllowAccessCamera] || ![KSCaptureTool isAllowAccessMicrophone]) {
        NSLog(@"请打开相机、麦克风权限！");
        return;
    }

#if kCanPause
    //KSRecordStatePrepare->KSRecordStateRecording->KSRecordStatePause->KSRecordStateResume->KSRecordStatePause ...
    switch (self.recordManager.recordState) {
        case KSRecordStatePrepare:
            [self.recordManager startRecord];
            [self.viewOperate setViewCamera:KSRecordStateRecording];
            break;
        case KSRecordStateRecording:
            [self.recordManager pauseRecord];
            [self.viewOperate setViewCamera:KSRecordStatePause];
            break;
        case KSRecordStatePause:
            [self.recordManager resumeRecord];
            [self.viewOperate setViewCamera:KSRecordStateResume];
            break;
        case KSRecordStateResume:
            [self.recordManager pauseRecord];
            [self.viewOperate setViewCamera:KSRecordStatePause];
            break;
        default:
            break;
    }
#else
    //1.拍摄初始状态    -KSRecordStatePrepare
    //2.拍摄中状态      -KSRecordStateRecording
    //3.手动+自动结束状态-KSRecordStateFinish
    //  但是这时候拍摄按钮是隐藏的，出现的是“重拍”、“确定”俩按钮,
    //  点击“重拍”状态进入KSRecordStatePrepare，点击“确定”没有状态的相关操作
    //所以拍摄操作按钮只需要控制下面俩状态，整个流程如下
    //KSRecordStatePrepare->KSRecordStateRecording->KSRecordStateFinish 或者
    //KSRecordStatePrepare->KSRecordStateRecording-(手动或者自动)->KSRecordStateFinish-("重拍")->KSRecordStatePrepare
    switch (self.recordManager.recordState) {
        case KSRecordStatePrepare:
            [self.viewOperate setViewCamera:KSRecordStateRecording];
            [self.recordManager startRecord];
            break;
        case KSRecordStateRecording:
            [self.recordManager stopRecord];
            break;
        default:
            break;
    }
#endif
}

- (void)btnGiveUpClicked:(UIButton *)btn
{
    //放弃当前视频
    [self.recordManager giveUpRecord];
    //开始视频采集
    [self.recordManager startSessionRuning];
    //操作手势
    self.captureView.tapToFocusEnabled = YES;
    self.captureView.doubleTapToResetFocusEnabled = YES;
    self.captureView.pinchToZoomEnabled = YES;
    //停止播放
    [self.player stopPlay];
    [self.player removePlayerLayerInView:self.captureView];
    [self.player removeObsvers];
    //重置操作界面
    [self.viewOperate setViewCamera:KSRecordStatePrepare];
    [self.captureView bringSubviewToFront:self.viewOperate];
}
- (void)btnSureClicked:(UIButton *)btn
{
    //停止播放
    [self.player stopPlay];
    [self.player removeObsvers];
    if (self.delegate && [self.delegate respondsToSelector:@selector(takeVideoFinish:)]) {
        [self.delegate takeVideoFinish:self.videoPath];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KSTakeVideoManagerDelegate
- (void)currentRecordProgress:(CGFloat )progress
{
    [self.viewOperate upDateProgress:progress];
}

- (void)finishRecordPath:(NSString *)videoPath error:(NSError *)error
{
    if (error) {
        //出错提示
        NSLog(@"视频拍摄失败，请重新拍摄");
        //删除失败的视频文件
        [KSCaptureTool deleteVideo];
        //重置操作界面
        [self.viewOperate setViewCamera:KSRecordStatePrepare];
    } else {
        self.videoPath = videoPath;
        //重置操作界面
        [self.viewOperate setViewCamera:KSRecordStateFinish];
        [self.viewOperate setBtnTorchForMode:AVCaptureTorchModeOff];
        //开始播放
        [self recordFinishToPlay:videoPath];
        //停止视频采集
        [self.recordManager stopSessionRuning];
        //操作手势
        self.captureView.tapToFocusEnabled = NO;
        self.captureView.doubleTapToResetFocusEnabled = NO;
        self.captureView.pinchToZoomEnabled = NO;
    }
}

#pragma mark - player
- (void)recordFinishToPlay:(NSString *)videoPath
{
    KSVideoPlayer *player = [[KSVideoPlayer alloc]initWithPath:videoPath];
    [player showPlayerLayerInView:self.captureView];
    [player startPlay];
    self.player = player;

    [self.captureView bringSubviewToFront:self.viewOperate];
}

#pragma mark get & set
- (KSTakeVideoManager *)recordManager
{
    if (!_recordManager) {
        _recordManager = [[KSTakeVideoManager alloc]init];
        _recordManager.delegate = self;
    }
    return _recordManager;
}

- (KSCaptureView *)captureView
{
    if (!_captureView) {
        _captureView = [[KSCaptureView alloc]initWithFrame:KSCaptureFrame];
    }
    return _captureView;
}

- (KSTakeVideoOperateView *)viewOperate
{
    if (!_viewOperate) {
        _viewOperate = [[KSTakeVideoOperateView alloc]initWithFrame:KSCaptureFrame];
        _viewOperate.delegate = self;
    }
    return _viewOperate;
}

@end
