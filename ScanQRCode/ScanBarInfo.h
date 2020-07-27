//
//  ScanBarInfo.h
//  SGQRCodeExample
//
//  Created by kang on 2020/7/22.
//  Copyright © 2020 Sorgle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface ScanBarInfo : NSObject
@property (nonatomic, strong)     UIView *codeView;
@property (nonatomic, copy)       NSString *codeString;
@end

NS_ASSUME_NONNULL_END
