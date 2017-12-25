//
//  KSRootViewController.m
//  KSCapture
//
//  Created by bufb on 2017/9/14.
//  Copyright © 2017年 kris. All rights reserved.
//

#import "KSRootViewController.h"
#import "KSTakePhotoViewController.h"
#import "KSTakeVideoViewController.h"

@interface KSRootViewController ()<KSTakePhotoDelegate,KSTakeVideoDelegate,UIAlertViewDelegate>

@end

@implementation KSRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    //照片
    CGRect rectBtnPhoto =CGRectMake(100, 100, 100, 50);
    UIButton *btnTakePhoto = [[UIButton alloc]initWithFrame:rectBtnPhoto];
    btnTakePhoto.backgroundColor = [UIColor redColor];
    [btnTakePhoto setTitle:@"拍摄照片" forState:UIControlStateNormal];
    [btnTakePhoto addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnTakePhoto];

    //视频
    CGRect rectBtnVideo =CGRectMake(100, 200, 100, 50);
    UIButton *btnTakeVideo = [[UIButton alloc]initWithFrame:rectBtnVideo];
    btnTakeVideo.backgroundColor = [UIColor redColor];
    [btnTakeVideo setTitle:@"拍摄视频" forState:UIControlStateNormal];
    [btnTakeVideo addTarget:self action:@selector(takeVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnTakeVideo];
}

- (void)takePhoto:(UIButton *)btn
{
    KSTakePhotoViewController *takePhotoVC = [[KSTakePhotoViewController alloc]initWithType:KSTakePhotoNormal];
    takePhotoVC.delegate = self;
    [self.navigationController presentViewController:takePhotoVC animated:YES completion:nil];
}

- (void)takeVideo:(UIButton *)btn
{
    KSTakeVideoViewController *takeVideoVC = [[KSTakeVideoViewController alloc]init];
    takeVideoVC.delegate = self;
    [self.navigationController presentViewController:takeVideoVC animated:YES completion:nil];
}

// MARK: - KSTakePhotoDelegate
- (void)takePhotoFinish:(UIImage *)image
{
    UIImageWriteToSavedPhotosAlbum(image,self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *strTitie = @"保存相册成功";
    if (error) {
        strTitie = @"保存相册失败";
    }
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:strTitie
                                                       message:nil
                                                      delegate:self
                                             cancelButtonTitle:@"确定"
                                             otherButtonTitles:nil,
                              nil];

    [alertView show];
}

// MARK: - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

}

// MARK: - KSTakeVideoDelegate
- (void)takeVideoFinish:(NSString *)videoPath
{
    NSLog(@"videoPath == %@",videoPath);
    UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *strTitie = @"保存相册成功";
    if (error) {
        strTitie = @"保存相册失败";
    }
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:strTitie
                                                       message:nil
                                                      delegate:self
                                             cancelButtonTitle:@"确定"
                                             otherButtonTitles:nil,
                              nil];

    [alertView show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
