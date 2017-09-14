//
//  KSTakePhotoViewController.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSTakePhotoViewController.h"
#import "KSTakePhotoManager.h"
#import "KSCaptureView.h"
#import "KSTakePhotoOpreateView.h"

@interface KSTakePhotoViewController ()<KSTakePhotoOperateViewDelegate,UIAlertViewDelegate>

@property (nonatomic ,strong)KSTakePhotoManager      *takePhotoManager;//拍摄管理类
@property (nonatomic ,strong)KSCaptureView           *captureView;     //拍摄区域视图
@property (nonatomic ,strong)KSTakePhotoOpreateView  *operateView;     //拍摄界面操作视图

@end

@implementation KSTakePhotoViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self.view addSubview:self.captureView];

    [self.takePhotoManager showPreviewLayerInView:self.captureView];
    self.captureView.recordManager = self.takePhotoManager;

    [self.captureView addSubview:self.operateView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.takePhotoManager startSessionRuning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.takePhotoManager stopSessionRuning];
}

// MARK: - KSTakePhotoOperateViewDelegate
// MARK: 头部视图操作
- (void)btnRightClicked:(UIButton *)btn
{

}
// MARK: 底部视图操作
- (void)btnDisMissClicked:(UIButton *)btn
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)btnTakePhotoClicked:(UIButton *)btn
{
    NSLog(@"拍摄处理中,请稍后...");

    [self.takePhotoManager takePhotoSuccess:^(UIImage *imgPhoto) {
        //成功-更新UI
        NSLog(@"拍摄完成");
        if (self.delegate && [self.delegate respondsToSelector:@selector(takePhotoFinish:)]) {
            [self.delegate takePhotoFinish:imgPhoto];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    } failed:^(NSError *error) {
        //失败-弹出提示
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"拍摄失败"
                                                           message:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"确定"
                                                 otherButtonTitles:nil,
                                  nil];

        [alertView show];
    }];
}
- (void)btnFlashSwitchClicked:(UIButton *)btn
{
    [self.takePhotoManager switchTorchModelSuccess:^(AVCaptureTorchMode currentTorchMode) {
        switch (currentTorchMode) {
            case AVCaptureTorchModeOff:
                [btn setImage:[UIImage imageNamed:@"KSCaptureFlash_Off"] forState:UIControlStateNormal];
                break;
            case AVCaptureTorchModeOn:
                [btn setImage:[UIImage imageNamed:@"KSCaptureFlash_On"] forState:UIControlStateNormal];
                break;
            default:
                break;
        }
    } failed:^(NSError *error, AVCaptureTorchMode currentTorchMode) {

    }];
}
- (void)btnCameraSwitchClicked:(UIButton *)btn
{
    [self.takePhotoManager switchCameraSuccess:^(AVCaptureDevicePosition currentPosition) {

    } failed:^(NSError *error, AVCaptureDevicePosition currentPosition) {

    }];
}

// MARK: - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

}

#pragma mark - get & set
- (KSTakePhotoManager *)takePhotoManager
{
    if (!_takePhotoManager) {
        _takePhotoManager = [[KSTakePhotoManager alloc]init];
    }
    return _takePhotoManager;
}

- (KSCaptureView *)captureView
{
    if (!_captureView) {
        _captureView = [[KSCaptureView alloc]initWithFrame:KSCaptureFrame];
    }
    return _captureView;
}

- (KSTakePhotoOpreateView *)operateView
{
    if (!_operateView) {
        _operateView = [[KSTakePhotoOpreateView alloc]initWithFrame:KSCaptureFrame];
        _operateView.delegate = self;
    }
    return _operateView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
