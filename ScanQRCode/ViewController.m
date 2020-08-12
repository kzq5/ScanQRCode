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
{
    UILabel *_tipsLabel;
}
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
    
    UILabel *tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, btn.frame.origin.y, self.view.bounds.size.width-40, 200)];
    tipsLabel.text = @"扫码结果显示区域";
    tipsLabel.numberOfLines = 0;
    tipsLabel.font  = [UIFont boldSystemFontOfSize:16];
    tipsLabel.textAlignment = NSTextAlignmentCenter;
    tipsLabel.textColor = [UIColor colorWithRed:54/255.0 green:85/255.0 blue:230/255.0 alpha:1];
    [self.view addSubview:tipsLabel];
    _tipsLabel = tipsLabel;
}
- (void)scanQRCode{
    ScanViewController *scanVC = [ScanViewController new];
    scanVC.qrCode = YES;
    scanVC.resultBlock = ^(NSString *scanResult) {
      self->_tipsLabel.text = scanResult;
    };
    scanVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:scanVC animated:YES completion:nil];
}

@end
