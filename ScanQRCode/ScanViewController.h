//
//  ScanViewController.h
//  SGQRCodeExample
//
//  Created by kang on 2020/7/22.
//  Copyright © 2020 Sorgle. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ScanResultBlock)(NSString *scanResult);

@interface ScanViewController : UIViewController
@property (nonatomic, assign)     BOOL qrCode;
@property (nonatomic, copy)       ScanResultBlock resultBlock;
@end

NS_ASSUME_NONNULL_END
