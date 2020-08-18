//
//  ZbarOverlayView.h
//  MeiNianTJ
//
//  Created by limi on 15/8/12.
//  Copyright (c) 2015年 limi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZbarOverlayView : UIView{

}
/**
 *  透明扫描框的区域
 */
@property (nonatomic, assign) CGRect transparentArea;
-(void)startAnimation;
-(void)stopAnimation;
@end
