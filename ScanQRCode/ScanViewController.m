//
//  ScanViewController.m
//  SGQRCodeExample
//
//  Created by kang on 2020/7/22.
//  Copyright © 2020 Sorgle. All rights reserved.
//

#import "ScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ScanBarInfo.h"

/** 扫描内容的 W 值 */
#define scanBorderW 0.9 * self.view.frame.size.width
/** 扫描内容的 x 值 */
#define scanBorderX 0.5 * (1 - 0.9) * self.view.frame.size.width
/** 扫描内容的 Y 值 */
#define scanBorderY 0.25 * self.view.frame.size.height

@interface ScanViewController ()<AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    NSMutableDictionary *_barcodes;
    AVCaptureMetadataOutput *_metadataOutput;
    NSMutableArray <ScanBarInfo*> * _layerArr;
    UIButton *_backBtn;
}
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) UIImageView *scanningline;
@property (nonatomic, strong) NSTimer *timer;
/** 扫描线动画时间，默认 0.02s */
@property (nonatomic, assign) NSTimeInterval animationTimeInterval;
@end

@implementation ScanViewController
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self addTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeTimer];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.animationTimeInterval = 0.02;
    _barcodes = [NSMutableDictionary new];
    _layerArr = [NSMutableArray new];
    // 1、获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 2、创建摄像设备输入流
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    // 3、创建元数据输出流
    _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 设置扫描范围（每一个取值0～1，以屏幕右上角为坐标原点）
    // 注：微信二维码的扫描范围是整个屏幕，这里并没有做处理（可不用设置）;
    // 如需限制扫描框范围，打开下一句注释代码并进行相应调整
//    metadataOutput.rectOfInterest = CGRectMake(0.05, 0.2, 0.7, 0.6);
    
    // 4、创建会话对象
    _session = [[AVCaptureSession alloc] init];
    // 并设置会话采集率
    _session.sessionPreset = AVCaptureSessionPreset1920x1080;
    
    // 5、添加元数据输出流到会话对象
    [_session addOutput:_metadataOutput];

   // 创建摄像数据输出流并将其添加到会话对象上,  --> 用于识别光线强弱
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [_session addOutput:_videoDataOutput];

    // 6、添加摄像设备输入流到会话对象
    [_session addInput:deviceInput];

 // 7、设置数据输出类型(如下设置为条形码和二维码兼容)，需要将数据输出添加到会话后，才能指定元数据类型，否则会报错
    if (self.qrCode) {
        _metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,  AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    }else{
        _metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,  AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    }
    
    // 8、实例化预览图层, 用于显示会话对象
    _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    // 保持纵横比；填充层边界
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _videoPreviewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:_videoPreviewLayer atIndex:0];
    
    // 9、启动会话
    [_session startRunning];
    
//    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//    btn.frame = CGRectMake(0, self.view.bounds.size.height-100, self.view.bounds.size.width, 50);
//    btn.backgroundColor = [UIColor redColor];
//    [btn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
//    [btn addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:btn];
//    if (self.qrCode) {
//        [btn setTitle:@"二维码" forState:UIControlStateNormal];
//    }else{
//        [btn setTitle:@"一维码" forState:UIControlStateNormal];
//    }
    
    _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _backBtn.frame = CGRectMake(15, 44, 44, 44);
    [_backBtn setImage:[UIImage imageNamed:@"scan_back"] forState:UIControlStateNormal];
    
    [_backBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backBtn];
    
    [self.view addSubview:[self getPhotosButton]];
    [self.view addSubview:[self getTipsLabel]];
}
#pragma mark - action
//关闭扫描页面
- (void)close{
    [self dismissViewControllerAnimated:YES completion:nil];
}
//取消扫码结果
- (void)cancel{
    if (_session.running) {
        [_session stopRunning];
    }
    [_layerArr enumerateObjectsUsingBlock:^(ScanBarInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.codeView removeFromSuperview];
    }];
    [_layerArr removeAllObjects];
    if (!_session.running) {
        [_session startRunning];
        [self addTimer];
    }
    _backBtn.hidden = NO;
}
//点击扫描到的二维码跳转
- (void)clickCurrentCode:(UIButton *)btn{
    ScanBarInfo *barInfo = _layerArr[btn.tag];
    NSLog(@"%@",barInfo.codeString);
    [self processWithResult:barInfo.codeString];
}
//去相册
- (void)photosAction{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}
- (void)clicked:(UIButton *)btn{
    if (_session.running) {
        [_session stopRunning];
    }
    [_layerArr enumerateObjectsUsingBlock:^(ScanBarInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.codeView removeFromSuperview];
    }];
    [_layerArr removeAllObjects];
    if (!self.qrCode) {
        [btn setTitle:@"二维码" forState:UIControlStateNormal];
        _metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,  AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    }else{
        [btn setTitle:@"一维码" forState:UIControlStateNormal];
        _metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,  AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    }
    self.qrCode = !self.qrCode;
    if (!_session.running) {
        [_session startRunning];
        [self addTimer];
    }
    _backBtn.hidden = NO;
}
#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"metadataObjects - - %@", metadataObjects);
    if (metadataObjects != nil && metadataObjects.count > 0) {
        [self removeTimer];
        UIView *maskView = [self getMaskView];
        maskView.alpha = 0;
        [self.view addSubview:maskView];
        [UIView animateWithDuration:0.6 animations:^{
            maskView.alpha = 1;
        }];
        
        ScanBarInfo *barInfo = [ScanBarInfo new];
        barInfo.codeView = maskView;
        barInfo.codeString = @"";
        [_layerArr addObject:barInfo];
        
        [metadataObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            AVMetadataMachineReadableCodeObject *code = (AVMetadataMachineReadableCodeObject*)
            [_videoPreviewLayer transformedMetadataObjectForMetadataObject:obj];
            
            UIButton *codeBtn = [self getCodeButtonWith:code.bounds withIcon:metadataObjects.count > 1];
            codeBtn.tag = idx+1;
            [self.view addSubview:codeBtn];
            
            ScanBarInfo *barInfo = [ScanBarInfo new];
            barInfo.codeView = codeBtn;
            barInfo.codeString = code.stringValue;
            [_layerArr addObject:barInfo];
        }];
        [_session stopRunning];
        _backBtn.hidden = YES;
        if(metadataObjects.count == 1){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                ScanBarInfo *barInfo = self->_layerArr[1];
                NSLog(@"%@",barInfo.codeString);
                [self processWithResult:barInfo.codeString];
            });
        }
    } else {
        NSLog(@"暂未识别出扫描的二维码");
    }
}
#pragma mark - - UIImagePickerControllerDelegate 的方法
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    // 创建 CIDetector，并设定识别类型：CIDetectorTypeQRCode
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    // 获取识别结果
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    if (features.count == 0) {
        
        [self dismissViewControllerAnimated:YES completion:^{
            [self processWithResult:@""];
        }];
        return;
    } else {
//        for (int index = 0; index < [features count]; index ++) {
//            CIQRCodeFeature *feature = [features objectAtIndex:index];
//            NSString *resultStr = feature.messageString;
//            NSLog(@"相册中读取二维码数据信息 - - %@", resultStr);
//        }
        CIQRCodeFeature *feature = features.firstObject;
        NSString *resultStr = feature.messageString;
    
        [self dismissViewControllerAnimated:YES completion:^{
            [self processWithResult:resultStr];
        }];
    }
}

#pragma mark - private
- (void)processWithResult:(NSString *)resultStr{
    if (self.resultBlock) {
        self.resultBlock(resultStr);
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
- (UIButton *)getPhotosButton{
    UIButton *photosBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    photosBtn.frame = CGRectMake((self.view.bounds.size.width - 44)/2, self.view.bounds.size.height - 44 - 34 - 40, 44, 44);
    [photosBtn setImage:[UIImage imageNamed:@"photos_icon"] forState:UIControlStateNormal];
    
    [photosBtn addTarget:self action:@selector(photosAction) forControlEvents:UIControlEventTouchUpInside];
    return photosBtn;
}
- (UILabel *)getTipsLabel{
    //条形码扫码框
    UILabel *tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, self.view.bounds.size.width-40, 50)];
    tipsLabel.text = @"条形码/一维码识别区";
    tipsLabel.font  = [UIFont boldSystemFontOfSize:16];
    tipsLabel.textAlignment = NSTextAlignmentCenter;
    tipsLabel.textColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    tipsLabel.backgroundColor = [UIColor colorWithRed:54/255.0 green:85/255.0 blue:230/255.0 alpha:0.2];
    tipsLabel.center = self.view.center;
    tipsLabel.layer.borderColor = [UIColor colorWithRed:54/255.0 green:85/255.0 blue:230/255.0 alpha:0.2].CGColor;
    tipsLabel.layer.borderWidth = 3;
    return tipsLabel;
}
- (CABasicAnimation *)getAnimation{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.duration = 0.6;
    animation.repeatCount = HUGE_VALF;
    animation.autoreverses = YES;
    //removedOnCompletion为NO保证app切换到后台动画再切回来时动画依然执行
    animation.removedOnCompletion = NO;
    animation.fromValue = [NSNumber numberWithFloat:1.0]; // 开始时的倍率
    animation.toValue = [NSNumber numberWithFloat:0.8]; // 结束时的倍率
    return animation;
}
- (UIButton *)getCodeButtonWith:(CGRect)bounds withIcon:(BOOL)icon{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    btn.backgroundColor = [UIColor colorWithRed:54/255.0 green:85/255.0 blue:230/255.0 alpha:1.0];
    [btn addTarget:self action:@selector(clickCurrentCode:) forControlEvents:UIControlEventTouchUpInside];
    
    if (icon) {
        [btn setImage:[UIImage imageNamed:@"right"] forState:UIControlStateNormal];
        [btn.layer addAnimation:[self getAnimation] forKey:@"scale-layer"];
    }
    
    CGRect rect = btn.frame;
    CGPoint center = btn.center;
    rect.size.width = 40;
    rect.size.height = 40;
    btn.frame = rect;
    btn.center = center;
    btn.layer.cornerRadius = 20;
    btn.clipsToBounds = YES;
    btn.layer.borderColor = [UIColor whiteColor].CGColor;
    btn.layer.borderWidth = 3;
    return btn;
}
- (UIView *)getMaskView{
    UIView *maskView = [[UIView alloc] initWithFrame:self.view.bounds];
    maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    
    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeCustom];
    cancel.frame = CGRectMake(15, 44, 50, 44);
    [cancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancel setTitle:@"取消" forState:UIControlStateNormal];
    [cancel addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [maskView addSubview:cancel];
    return maskView;
}
#pragma mark - - - 添加定时器
- (void)addTimer {
    CGFloat scanninglineX = 0;
    CGFloat scanninglineY = 0;
    CGFloat scanninglineW = 0;
    CGFloat scanninglineH = 0;
    [self.view addSubview:self.scanningline];
    scanninglineW = scanBorderW;
    scanninglineH = 12;
    scanninglineX = scanBorderX;
    scanninglineY = scanBorderY;
    _scanningline.frame = CGRectMake(scanninglineX, scanninglineY, scanninglineW, scanninglineH);
    self.timer = [NSTimer timerWithTimeInterval:self.animationTimeInterval target:self selector:@selector(beginRefreshUI) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}
#pragma mark - - - 移除定时器
- (void)removeTimer {
    [self.timer invalidate];
    self.timer = nil;
    [_scanningline removeFromSuperview];
    _scanningline = nil;
}
#pragma mark - - - 执行定时器方法
- (void)beginRefreshUI {
    //防止还没开始执行定时器就扫描到码，导致扫描动画一直进行
    if (!_session.isRunning) {
        [self removeTimer];
    }
    __block CGRect frame = _scanningline.frame;
    static BOOL flag = YES;
    
    __weak typeof(self) weakSelf = self;

    if (flag) {
        frame.origin.y = scanBorderY;
        flag = NO;
        [UIView animateWithDuration:self.animationTimeInterval animations:^{
            frame.origin.y += 2;
            weakSelf.scanningline.frame = frame;
        } completion:nil];
    } else {
        if (_scanningline.frame.origin.y >= scanBorderY) {
            CGFloat scanContent_MaxY = self.view.frame.size.height - scanBorderY;
            if (_scanningline.frame.origin.y >= scanContent_MaxY - 10) {
                frame.origin.y = scanBorderY;
                weakSelf.scanningline.frame = frame;
                flag = YES;
            } else {
                [UIView animateWithDuration:self.animationTimeInterval animations:^{
                    frame.origin.y += 2;
                    weakSelf.scanningline.frame = frame;
                } completion:nil];
            }
        } else {
            flag = !flag;
        }
    }
}
#pragma mark - set/get
- (UIImageView *)scanningline {
    if (!_scanningline) {
        _scanningline = [[UIImageView alloc] init];
        
        UIImage *image = [UIImage imageNamed:@"QRCodeScanLine@2x"];

        _scanningline.image = image;
    }
    return _scanningline;
}

- (void)dealloc
{
    NSLog(@"释放了——————————————————————————————————————————-");
}
@end
