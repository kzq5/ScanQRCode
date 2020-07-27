//
//  ViewController.m
//  ScanQRCode
//
//  Created by kang on 2020/7/27.
//  Copyright © 2020 ZK. All rights reserved.
//

#import "ViewController.h"
#import "ScanViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 100, 40);
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"扫码" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(scanQRCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    btn.center = self.view.center;
}
- (void)scanQRCode{
    ScanViewController *scanVC = [ScanViewController new];
    scanVC.qrCode = YES;
    scanVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:scanVC animated:YES completion:nil];
}

@end
